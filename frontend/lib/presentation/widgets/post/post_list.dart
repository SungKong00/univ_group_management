import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/models/date_marker.dart';
import '../../../core/models/post_list_item.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/read_position_helper.dart';
import '../../../features/post/domain/entities/post.dart';
import '../../../features/post/presentation/providers/post_list_notifier.dart';
import '../../../features/post/presentation/providers/post_list_state.dart';
import '../common/app_empty_state.dart';
import 'post_item.dart';
import 'date_divider.dart';
import 'post_skeleton.dart';
import 'unread_message_divider.dart';
import '../../providers/workspace_state_provider.dart';

// ✅ WorkspaceStateProvider가 JS 캐시를 관리하므로
// PostList에서는 더 이상 dart:js, dart:html 불필요

// 상수 정의 - 설정 변경이 쉽도록 중앙화
class _PostListConstants {
  /// 무한 스크롤 트리거 임계값 (상단으로부터의 거리)
  static const double infiniteScrollThreshold = 200.0;

  /// 읽음 처리를 위한 가시성 임계값 (50% 이상 보여야 읽음 처리)
  static const double readVisibilityThreshold = 0.5;

  /// 읽은 위치 업데이트 디바운스 지연 시간
  static const Duration debounceDelay = Duration(milliseconds: 200);

  /// ScrollController 준비 대기 시간
  static const Duration scrollControllerWaitTime = Duration(milliseconds: 300);

  /// 읽은 위치 데이터 재시도 대기 시간
  static const Duration readPositionRetryDelay = Duration(milliseconds: 100);

  /// 읽은 위치 데이터 최대 재시도 횟수
  static const int readPositionMaxRetries = 3;

  /// Sticky header 높이 (날짜 구분선)
  static const double stickyHeaderHeight = 24.0;

  /// ✨ Sticky header viewport 감지 범위 (정확도 개선)
  /// 화면 상단 기준 -stickyHeaderHeight ~ stickyHeaderHeight*2 범위에서 감지
  /// (DateDivider가 화면 상단 근처에 있을 때 감지)
  static const double viewportTopMin = -stickyHeaderHeight;
  static const double viewportTopMax = stickyHeaderHeight * 2;

  /// 평균 아이템 높이 (가시 범위 계산용 추정값)
  static const double estimatedItemHeight = 80.0;
}

/// 게시글 목록 위젯
///
/// Phase 2: Flat List 구조로 전환
/// - `List<dynamic>` [DateMarker, Post, ...] 단일 리스트
/// - 단일 SliverList로 단순화
/// - Sticky Header 개선 (sliver_sticky_header 제거)
///
/// Phase 4: 읽음 추적 정확도 개선
/// - 30% → 50% 가시성 임계값 상향
/// - 500ms 지속 시간 조건 제거 (즉시 처리)
/// - 빠른 스크롤 시 부정확한 읽음 처리 방지
class PostList extends ConsumerStatefulWidget {
  final String channelId;
  final bool canWrite;
  final Function(int postId)? onTapComment;

  const PostList({
    super.key,
    required this.channelId,
    this.canWrite = false,
    this.onTapComment,
  });

  @override
  ConsumerState<PostList> createState() => _PostListState();
}

class _PostListState extends ConsumerState<PostList> {
  late final AutoScrollController _scrollController;

  // Phase 2: GlobalKey 제거 (더 이상 RenderBox 측정 불필요)
  // Phase 3: PostListNotifier를 통해 데이터 관리

  List<PostListItem> _flatItems = []; // Phase 2: Flat list - 타입 안전성 개선

  // Phase 2: 초기 정렬 로직 단순화
  bool _isInitialLoading = true;

  // 읽지 않은 게시글 관리 (sequential index 사용)
  int? _firstUnreadPostIndex; // _flatItems의 index (0, 1, 2, ...)

  // 가시성 추적 (Visibility Detector)
  final Set<int> _visiblePostIds = {};
  int? _highestEverVisibleId; // 지금까지 본 것 중 최댓값 (절대 감소하지 않음)
  Timer? _debounceTimer;
  bool _hasScrolledToUnread = false;

  // ✨ Sticky Date Header 추적 (Phase: Sticky Header)
  DateTime? _currentStickyDate; // 현재 상단에 고정된 날짜
  final Map<int, DateTime> _indexToDateMap = {}; // index → 날짜 매핑
  final Map<int, GlobalKey> _itemKeys = {}; // index → GlobalKey 매핑 (정밀 추적)

  @override
  void initState() {
    super.initState();
    _scrollController = AutoScrollController();
    _scrollController.addListener(_onScroll);

    // Feature Flag: AsyncNotifier 패턴에서는 Provider가 자동 로딩
    if (!FeatureFlags.useAsyncNotifierPattern) {
      // ✅ 구 방식: 이벤트 루프 완료 후 데이터 로드 (Provider 초기화 대기)
      Future.microtask(() {
        if (mounted) {
          _loadPostsAndScrollToUnread();
        }
      });
    } else {
      // ✅ 신 방식: 스크롤 위치만 복원 (Provider가 데이터 로딩)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _restoreScrollPosition();
        }
      });
    }
  }

  /// 스크롤 위치 복원 (AsyncNotifier 패턴용)
  Future<void> _restoreScrollPosition() async {
    final channelIdInt = int.tryParse(widget.channelId);
    if (channelIdInt == null) return;

    // 데이터 로딩 대기 (AsyncNotifier의 build() 완료 대기)
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    // 읽음 위치 데이터 대기
    await _waitForReadPositionData(channelIdInt);
    if (!mounted) return;

    // 게시글 목록 가져오기
    final postListAsync =
        ref.read(postListAsyncNotifierProvider(widget.channelId));
    final postListState = postListAsync.valueOrNull;
    if (postListState == null || postListState.posts.isEmpty) return;

    // Flat List 생성
    final flatItems = _buildFlatList(postListState.posts);
    if (!mounted) return;

    setState(() {
      _flatItems = flatItems;
      _isInitialLoading = false;
    });

    // 읽음 위치 계산 및 스크롤
    _scrollToUnreadPost();
  }

  @override
  void didUpdateWidget(PostList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.channelId != widget.channelId) {
      _hasScrolledToUnread = false;
      _firstUnreadPostIndex = null;
      _highestEverVisibleId = null;
      _resetAndLoad();
    }
  }

  @override
  void dispose() {
    // ✅ WorkspaceStateProvider가 스크롤 시 실시간으로 JS 캐시를 동기 업데이트하므로
    // dispose에서 별도로 JS 캐시를 업데이트할 필요가 없습니다.
    // beforeunload 이벤트는 항상 최신 JS 캐시를 사용하여 서버에 전송합니다.

    _debounceTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _resetAndLoad() {
    setState(() {
      _flatItems = [];
      _isInitialLoading = true;
      _visiblePostIds.clear();
      _firstUnreadPostIndex = null;
      _hasScrolledToUnread = false;
      _highestEverVisibleId = null;
    });
    _loadPostsAndScrollToUnread();
  }

  void _handlePostUpdated() {
    _resetAndLoad();
  }

  void _handlePostDeleted() {
    _resetAndLoad();
  }

  /// 읽음 위치 데이터가 준비될 때까지 대기
  Future<void> _waitForReadPositionData(int channelId) async {
    await Future.delayed(_PostListConstants.readPositionRetryDelay);

    for (
      int attempt = 0;
      attempt < _PostListConstants.readPositionMaxRetries;
      attempt++
    ) {
      if (!mounted) return; // ✅ dispose 후 실행 방지
      final workspaceState = ref.read(workspaceStateProvider);

      if (workspaceState.lastReadPostIdMap.containsKey(channelId)) {
        return;
      }

      if (attempt < _PostListConstants.readPositionMaxRetries - 1) {
        await Future.delayed(_PostListConstants.readPositionRetryDelay);
      }
    }
  }

  /// Phase 2: Flat List 생성 (날짜 마커와 게시글을 번갈아 배치)
  ///
  /// **구조**: [DateMarkerWrapper, PostWrapper, PostWrapper, DateMarkerWrapper, PostWrapper, ...]
  ///
  /// **정렬**: oldest → newest (최신글이 리스트 마지막)
  ///
  /// ✨ Sticky Header Phase: index → 날짜 매핑 생성
  List<PostListItem> _buildFlatList(List<Post> posts) {
    if (posts.isEmpty) {
      _indexToDateMap.clear();
      _itemKeys.clear();
      return [];
    }

    final List<PostListItem> flatItems = [];
    DateTime? currentDate;

    // ✨ 매핑 초기화
    _indexToDateMap.clear();
    _itemKeys.clear();

    // 게시글이 oldest → newest로 정렬되어 있다고 가정
    for (final post in posts) {
      final postDate = DateTime(
        post.createdAt.year,
        post.createdAt.month,
        post.createdAt.day,
      );

      // 날짜가 바뀌면 DateMarker 추가
      if (currentDate != postDate) {
        final dateMarkerIndex = flatItems.length;
        flatItems.add(DateMarkerWrapper(DateMarker(date: postDate)));

        // ✨ DateMarker의 index와 날짜 매핑
        _indexToDateMap[dateMarkerIndex] = postDate;
        _itemKeys[dateMarkerIndex] = GlobalKey();

        currentDate = postDate;
      }

      // ✨ Post의 index도 현재 날짜로 매핑
      final postIndex = flatItems.length;
      flatItems.add(PostWrapper(post));
      _indexToDateMap[postIndex] = currentDate!;
      _itemKeys[postIndex] = GlobalKey();
    }

    return flatItems;
  }

  /// 게시글 로드 및 읽지 않은 게시글로 스크롤
  Future<void> _loadPostsAndScrollToUnread() async {
    await _loadPosts(refresh: true);

    final channelIdInt = int.tryParse(widget.channelId);
    if (channelIdInt != null) {
      await _waitForReadPositionData(channelIdInt);

      if (!mounted) return; // ✅ 비동기 작업 후 dispose 체크
      final workspaceState = ref.read(workspaceStateProvider);
      final lastReadPostId = ReadPositionHelper.getLastReadPostId(
        workspaceState.lastReadPostIdMap,
        channelIdInt,
      );

      // Phase 2: Flat list에서 찾기 (sequential index 반환)
      _firstUnreadPostIndex = _findFirstUnreadPostIndexInFlatList(
        lastReadPostId,
      );

      if (_firstUnreadPostIndex != null && !_hasScrolledToUnread) {
        // 읽지 않은 글이 있으면 해당 위치로 스크롤
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await _scrollToUnreadPost();
          // 읽음 처리는 VisibilityDetector가 자동으로 처리
          // ✨ Phase 2: sticky header 초기 상태 설정
          _updateStickyDate();
        });
      } else {
        // 읽지 않은 글이 없으면 최하단으로 스크롤
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(
              _scrollController.position.maxScrollExtent,
            );
          }
          setState(() {
            _isInitialLoading = false;
          });
          // ✨ Phase 2: sticky header 초기 상태 설정
          _updateStickyDate();
        });
      }
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
        setState(() {
          _isInitialLoading = false;
        });
        // ✨ Phase 2: sticky header 초기 상태 설정
        _updateStickyDate();
      });
    }
  }

  /// Phase 2: Flat list에서 첫 번째 읽지 않은 게시글의 sequential index 찾기
  int? _findFirstUnreadPostIndexInFlatList(int? lastReadPostId) {
    if (lastReadPostId == null || lastReadPostId == -1) {
      // 읽음 이력 없으면 첫 번째 게시글의 index (-1은 신규 채널)
      for (int i = 0; i < _flatItems.length; i++) {
        if (_flatItems[i] case PostWrapper()) {
          return i; // sequential index 반환
        }
      }
      return null;
    }

    // lastReadPostId 다음 게시글 찾기
    bool foundLastRead = false;
    for (int i = 0; i < _flatItems.length; i++) {
      if (_flatItems[i] case PostWrapper(:final post)) {
        if (foundLastRead) {
          return i; // sequential index 반환
        }
        if (post.id == lastReadPostId) {
          foundLastRead = true;
        }
      }
    }

    // 모두 읽음
    return null;
  }

  /// 읽지 않은 게시글로 스크롤
  Future<void> _scrollToUnreadPost() async {
    if (_firstUnreadPostIndex == null || _hasScrolledToUnread) {
      return;
    }

    try {
      // ScrollController가 준비될 때까지 대기
      if (!_scrollController.hasClients) {
        await Future.delayed(_PostListConstants.scrollControllerWaitTime);
      }

      // 여전히 준비되지 않았으면 최하단으로 스크롤
      if (!_scrollController.hasClients) {
        setState(() {
          _isInitialLoading = false;
        });
        return;
      }

      // AutoScrollController를 사용한 sequential index 기반 스크롤
      await _scrollController.scrollToIndex(
        _firstUnreadPostIndex!,
        preferPosition: AutoScrollPosition.begin,
        duration: const Duration(milliseconds: 1), // Duration.zero는 허용 안 됨
      );

      // Sticky header 높이 보정 (DateDivider 기본 높이)
      if (_scrollController.hasClients) {
        final currentOffset = _scrollController.offset;
        final adjustedOffset =
            (currentOffset - _PostListConstants.stickyHeaderHeight).clamp(
              _scrollController.position.minScrollExtent,
              _scrollController.position.maxScrollExtent,
            );
        _scrollController.jumpTo(adjustedOffset);
      }

      _hasScrolledToUnread = true;

      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    } catch (e, stackTrace) {
      developer.log(
        '❌ 스크롤 실패 - 예외 발생: $e',
        name: 'PostList.ScrollDebug',
        error: e,
        level: 900,
      );

      // 스크롤 실패 시 최하단으로 스크롤
      if (mounted && _scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }

      // 에러 로깅 개선 - 더 상세한 정보 포함
      debugPrint('[PostList] 읽지 않은 글 스크롤 실패');
      debugPrint('  채널 ID: ${widget.channelId}');
      debugPrint('  대상 index: $_firstUnreadPostIndex');
      debugPrint('  에러: $e');
      if (e is! StateError) {
        // StateError(Bad state)가 아닌 경우에만 스택 추적 출력
        debugPrint('  스택 추적:\n$stackTrace');
      }
    }
  }

  Future<void> _loadPosts({bool refresh = false}) async {
    final notifier = ref.read(
      postListNotifierProvider(widget.channelId).notifier,
    );
    final state = ref.read(postListNotifierProvider(widget.channelId));

    if (!refresh && (state.isLoading || !state.hasMore)) return;

    double? savedScrollOffset;
    double? savedMaxScrollExtent;
    if (!refresh && state.currentPage > 0 && _scrollController.hasClients) {
      savedScrollOffset = _scrollController.offset;
      savedMaxScrollExtent = _scrollController.position.maxScrollExtent;
    }

    try {
      await notifier.loadPosts(widget.channelId, refresh: refresh);

      final newState = ref.read(postListNotifierProvider(widget.channelId));
      final bool isFirstPageLoad = newState.currentPage == 1;

      if (!mounted) return;
      setState(() {
        // Phase 2: Flat list 생성
        _flatItems = _buildFlatList(newState.posts);

        if (isFirstPageLoad) {
          _isInitialLoading = true;
        }

        // 무한 스크롤 시 읽지 않은 글 위치는 재계산하지 않음
        // 이미 설정된 _firstUnreadPostId를 유지하여 UI 깜빡임 방지
      });

      if (savedScrollOffset != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            final delta =
                _scrollController.position.maxScrollExtent -
                (savedMaxScrollExtent ?? 0);
            _scrollController.jumpTo(savedScrollOffset! + delta);
          }
        });
      }
    } catch (e, stackTrace) {
      if (!mounted) return;

      // 에러 메시지 정제 및 로깅
      final errorMessage = e.toString().replaceAll('Exception: ', '');

      setState(() {
        _isInitialLoading = false;
      });

      // 상세한 에러 로깅
      debugPrint('[PostList] 게시글 로드 실패');
      debugPrint('  채널 ID: ${widget.channelId}');
      debugPrint('  에러 메시지: $errorMessage');
      debugPrint('  원본 에러: $e');
      if (e is! FormatException && e is! TypeError) {
        debugPrint('  스택 추적:\n$stackTrace');
      }
    }
  }

  void _onScroll() {
    if (_isInitialLoading) return;
    if (_scrollController.position.pixels <=
        _PostListConstants.infiniteScrollThreshold) {
      _loadPosts();
    }

    // ✨ Sticky date 업데이트
    _updateStickyDate();
  }

  /// ✨ Sticky Header: 가시 범위 내 DateMarker index 계산 (성능 최적화)
  ///
  /// **개선 사항**:
  /// - 모든 GlobalKey 순회 대신 스크롤 offset 기반으로 가시 범위만 탐색
  /// - O(n) → O(1) 성능 향상
  List<int> _calculateVisibleDateMarkerIndices() {
    if (!_scrollController.hasClients || _flatItems.isEmpty) return [];

    final scrollOffset = _scrollController.offset;
    final viewportHeight = _scrollController.position.viewportDimension;

    // 스크롤 offset 기반으로 가시 범위의 대략적인 index 추정
    final estimatedStartIndex =
        (scrollOffset / _PostListConstants.estimatedItemHeight).floor().clamp(
          0,
          _flatItems.length - 1,
        );
    final estimatedEndIndex =
        ((scrollOffset + viewportHeight) /
                _PostListConstants.estimatedItemHeight)
            .ceil()
            .clamp(0, _flatItems.length - 1);

    // 가시 범위 내 DateMarker만 필터링
    final List<int> dateMarkerIndices = [];
    for (int i = estimatedStartIndex; i <= estimatedEndIndex; i++) {
      // ✨ DateMarkerWrapper만 필터링 (Post는 제외)
      if (_flatItems[i] case DateMarkerWrapper()) {
        dateMarkerIndices.add(i);
      }
    }

    return dateMarkerIndices;
  }

  /// ✨ Sticky Header: 최상단에 보이는 날짜 추적 (정확도 + 성능 개선)
  ///
  /// **개선 사항**:
  /// 1. DateMarkerWrapper만 감지 (Post 제외)
  /// 2. 정확한 viewport 범위 (0 ~ -stickyHeaderHeight)
  /// 3. 가시 범위 내 아이템만 탐색 (성능 최적화)
  void _updateStickyDate() {
    if (!_scrollController.hasClients || _flatItems.isEmpty) return;

    // ✨ Phase 2: 가시 범위 내 DateMarker index만 가져오기
    final visibleDateMarkerIndices = _calculateVisibleDateMarkerIndices();
    if (visibleDateMarkerIndices.isEmpty) return;

    DateTime? newStickyDate;

    // ✨ Phase 1 + Phase 2: DateMarker만 정확하게 감지
    for (final index in visibleDateMarkerIndices) {
      final key = _itemKeys[index];
      if (key == null) continue;

      final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) {
        try {
          final position = renderBox.localToGlobal(Offset.zero);

          // ✨ Phase 1: 정확한 viewport 상단 범위 (-stickyHeaderHeight ~ 0)
          if (position.dy >= _PostListConstants.viewportTopMin &&
              position.dy <= _PostListConstants.viewportTopMax) {
            newStickyDate = _indexToDateMap[index];
            break; // 첫 번째 DateMarker 사용
          }
        } catch (e) {
          // RenderBox가 dispose되었을 경우 무시
          continue;
        }
      }
    }

    // ✨ Phase 3: 날짜가 변경되었을 때만 setState 호출
    if (newStickyDate != null && newStickyDate != _currentStickyDate) {
      setState(() {
        _currentStickyDate = newStickyDate;
      });
    }
  }

  void _onPostVisible(int postId) {
    _visiblePostIds.add(postId);
    _scheduleUpdateMaxVisibleId();
  }

  void _onPostInvisible(int postId) {
    _visiblePostIds.remove(postId);
    _scheduleUpdateMaxVisibleId();
  }

  void _scheduleUpdateMaxVisibleId() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_PostListConstants.debounceDelay, () {
      _updateMaxVisibleId();
    });
  }

  void _updateMaxVisibleId() {
    if (_visiblePostIds.isEmpty) return;

    final maxId = _visiblePostIds.reduce((a, b) => a > b ? a : b);

    // 지금까지 본 것 중 최댓값 업데이트 (절대 감소하지 않음)
    if (_highestEverVisibleId == null || maxId > _highestEverVisibleId!) {
      _highestEverVisibleId = maxId;

      // 워크스페이스 상태 업데이트 (저장할 값)
      ref.read(workspaceStateProvider.notifier).updateCurrentVisiblePost(maxId);

      // 읽음 위치 업데이트 로깅
      developer.log(
        '읽음 위치 업데이트 - 채널: ${widget.channelId}, 게시글: $maxId (highest: $_highestEverVisibleId), 보이는 게시글 수: ${_visiblePostIds.length}',
        name: 'PostList',
      );
    }
  }

  /// ✨ Sticky Header: 고급 애니메이션 sticky header 위젯
  ///
  /// **애니메이션 효과**:
  /// - 이전 헤더: 위로 SlideOut (fadeOut 포함)
  /// - 새 헤더: 아래에서 SlideIn (fadeIn 포함)
  /// - Duration: 250ms (부드러운 전환)
  ///
  /// **Material elevation**: 헤더가 컨텐츠 위에 떠있는 느낌
  Widget _buildStickyHeader() {
    if (_currentStickyDate == null) {
      return const SizedBox.shrink(); // 날짜가 없으면 빈 위젯
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (Widget child, Animation<double> animation) {
        // ✨ 고급 애니메이션: 이전 헤더는 위로, 새 헤더는 아래에서
        final offsetAnimation =
            Tween<Offset>(
              begin: const Offset(0, 1), // 아래에서 시작
              end: Offset.zero, // 제자리
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic, // 부드러운 곡선
              ),
            );

        final fadeAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeIn,
        );

        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(opacity: fadeAnimation, child: child),
        );
      },
      // ✨ ValueKey로 날짜 변경 감지 → 애니메이션 트리거
      child: Material(
        key: ValueKey(_currentStickyDate),
        elevation: 4, // 살짝 그림자 추가 (depth 표현)
        color: Colors.white,
        child: DateDivider(date: _currentStickyDate!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Feature Flag: AsyncNotifier 패턴 사용 여부
    if (FeatureFlags.useAsyncNotifierPattern) {
      return _buildWithAsyncNotifier(context);
    } else {
      return _buildWithStateNotifier(context);
    }
  }

  /// 신 방식: AsyncNotifier 패턴 (Provider가 데이터 로딩 제어)
  Widget _buildWithAsyncNotifier(BuildContext context) {
    final postListAsync =
        ref.watch(postListAsyncNotifierProvider(widget.channelId));

    return postListAsync.when(
      loading: () => const PostListSkeleton(),
      error: (error, stack) => _buildErrorState(error.toString()),
      data: (postListState) {
        // 빈 상태 처리
        if (postListState.posts.isEmpty) {
          return _buildEmptyState();
        }

        // 데이터가 있으면 스크롤뷰 렌더링
        return _buildScrollView(postListState);
      },
    );
  }

  /// 구 방식: StateNotifier 패턴 (Widget이 데이터 로딩 제어)
  Widget _buildWithStateNotifier(BuildContext context) {
    final postListState = ref.watch(postListNotifierProvider(widget.channelId));

    if (postListState.posts.isEmpty && postListState.isLoading) {
      return const PostListSkeleton();
    }

    if (postListState.posts.isEmpty && postListState.errorMessage != null) {
      return _buildErrorState(postListState.errorMessage!);
    }

    if (postListState.posts.isEmpty) {
      return _buildEmptyState();
    }

    return _buildScrollView(postListState);
  }

  /// 공통: ScrollView 렌더링 로직
  Widget _buildScrollView(PostListState postListState) {

    // Phase 2: Flat list로 단일 SliverList 사용
    final scrollView = LayoutBuilder(
      builder: (context, constraints) {
        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            if (postListState.isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            // Phase 2: 단일 SliverList로 통합 - 타입 안전성 개선
            // ✨ Sticky Header Phase: GlobalKey를 각 아이템에 추가
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final item = _flatItems[index];
                final itemKey = _itemKeys[index]; // ✨ GlobalKey 가져오기

                // Pattern matching으로 타입 안전하게 처리
                switch (item) {
                  case DateMarkerWrapper(:final marker):
                    // DateMarker: 날짜 구분선
                    // ✨ Container로 감싸서 GlobalKey 부착
                    return Container(
                      key: itemKey,
                      child: DateDivider(date: marker.date),
                    );

                  case PostWrapper(:final post):
                    // Post: 게시글 아이템
                    // sequential index 기반으로 읽지 않은 글 표시 판단
                    final bool shouldShowDivider =
                        _firstUnreadPostIndex == index;

                    final child = VisibilityDetector(
                      key: Key('post_visibility_${post.id}'),
                      onVisibilityChanged: (info) {
                        // 50% 이상 보이면 읽음 처리
                        if (info.visibleFraction >
                            _PostListConstants.readVisibilityThreshold) {
                          _onPostVisible(post.id);
                        } else {
                          _onPostInvisible(post.id);
                        }
                      },
                      child: Column(
                        children: [
                          if (shouldShowDivider) const UnreadMessageDivider(),
                          PostItem(
                            post: post,
                            onTapComment: () =>
                                widget.onTapComment?.call(post.id),
                            onTapPost: () {},
                            onPostUpdated: _handlePostUpdated,
                            onPostDeleted: _handlePostDeleted,
                          ),
                          const Divider(height: 1, color: AppColors.neutral200),
                        ],
                      ),
                    );

                    // ✨ Container로 감싸서 GlobalKey 부착
                    return Container(
                      key: itemKey, // GlobalKey 부착
                      child: AutoScrollTag(
                        key: ValueKey('post_${post.id}'),
                        controller: _scrollController,
                        index:
                            index, // SliverChildBuilderDelegate의 sequential index 사용
                        child: child,
                      ),
                    );
                }
              }, childCount: _flatItems.length),
            ),
            // 하단 여백
            SliverPadding(
              padding: EdgeInsets.only(bottom: constraints.maxHeight * 0.3),
            ),
          ],
        );
      },
    );

    // Phase 2: 단순화 - 초기 로딩 시에만 스피너 표시
    // ✨ Sticky Header Phase: sticky header 추가
    return Stack(
      children: [
        Opacity(opacity: _isInitialLoading ? 0.0 : 1.0, child: scrollView),
        if (_isInitialLoading)
          Positioned.fill(
            child: const Center(child: CircularProgressIndicator()),
          ),

        // ✨ Sticky Header: 상단에 고정
        if (!_isInitialLoading && _currentStickyDate != null)
          Positioned(top: 0, left: 0, right: 0, child: _buildStickyHeader()),
      ],
    );
  }

  Widget _buildEmptyState() {
    return AppEmptyState.noPosts();
  }

  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              '게시글을 불러올 수 없습니다',
              style: AppTheme.headlineMedium.copyWith(
                color: AppColors.neutral900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: AppTheme.bodyMedium.copyWith(color: AppColors.neutral600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _resetAndLoad,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.action,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text(
                '다시 시도',
                style: AppTheme.titleMedium.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
