import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../core/models/date_marker.dart';
import '../../../core/models/post_models.dart';
import '../../../core/models/post_list_item.dart';
import '../../../core/services/post_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/read_position_helper.dart';
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
  final PostService _postService = PostService();
  late final AutoScrollController _scrollController;

  // Phase 2: GlobalKey 제거 (더 이상 RenderBox 측정 불필요)

  List<Post> _posts = [];
  List<PostListItem> _flatItems = []; // Phase 2: Flat list - 타입 안전성 개선
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  String? _errorMessage;

  // Phase 2: 초기 정렬 로직 단순화
  bool _isInitialLoading = true;

  // 읽지 않은 게시글 관리 (sequential index 사용)
  int? _firstUnreadPostIndex; // _flatItems의 index (0, 1, 2, ...)

  // 가시성 추적 (Visibility Detector)
  final Set<int> _visiblePostIds = {};
  int? _highestEverVisibleId; // 지금까지 본 것 중 최댓값 (절대 감소하지 않음)
  Timer? _debounceTimer;
  bool _hasScrolledToUnread = false;

  @override
  void initState() {
    super.initState();
    _scrollController = AutoScrollController();
    _scrollController.addListener(_onScroll);
    _loadPostsAndScrollToUnread();
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
      _posts = [];
      _flatItems = [];
      _currentPage = 0;
      _hasMore = true;
      _errorMessage = null;
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
  List<PostListItem> _buildFlatList(List<Post> posts) {
    if (posts.isEmpty) return [];

    final List<PostListItem> flatItems = [];
    DateTime? currentDate;

    // 게시글이 oldest → newest로 정렬되어 있다고 가정
    for (final post in posts) {
      final postDate = DateTime(
        post.createdAt.year,
        post.createdAt.month,
        post.createdAt.day,
      );

      // 날짜가 바뀌면 DateMarker 추가
      if (currentDate != postDate) {
        flatItems.add(DateMarkerWrapper(DateMarker(date: postDate)));
        currentDate = postDate;
      }

      flatItems.add(PostWrapper(post));
    }

    return flatItems;
  }

  /// 게시글 로드 및 읽지 않은 게시글로 스크롤
  Future<void> _loadPostsAndScrollToUnread() async {
    await _loadPosts();

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

  Future<void> _loadPosts() async {
    if (_isLoading || !_hasMore) return;

    double? savedScrollOffset;
    double? savedMaxScrollExtent;
    if (_currentPage > 0 && _scrollController.hasClients) {
      savedScrollOffset = _scrollController.offset;
      savedMaxScrollExtent = _scrollController.position.maxScrollExtent;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _postService.fetchPosts(
        widget.channelId,
        page: _currentPage,
      );

      response.posts.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      final bool isFirstPageLoad = _currentPage == 0;

      if (!mounted) return;
      setState(() {
        _posts.insertAll(0, response.posts);
        // Phase 2: Flat list 생성
        _flatItems = _buildFlatList(_posts);
        _currentPage++;
        _hasMore = response.hasMore;
        _isLoading = false;

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
        _isLoading = false;
        _errorMessage = errorMessage;
        _isInitialLoading = false;
      });

      // 상세한 에러 로깅
      debugPrint('[PostList] 게시글 로드 실패');
      debugPrint('  채널 ID: ${widget.channelId}');
      debugPrint('  페이지: $_currentPage');
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

  @override
  Widget build(BuildContext context) {
    if (_posts.isEmpty && _isLoading) {
      return const PostListSkeleton();
    }

    if (_posts.isEmpty && _errorMessage != null) {
      return _buildErrorState();
    }

    if (_posts.isEmpty) {
      return _buildEmptyState();
    }

    // Phase 2: Flat list로 단일 SliverList 사용
    final scrollView = LayoutBuilder(
      builder: (context, constraints) {
        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            if (_isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            // Phase 2: 단일 SliverList로 통합 - 타입 안전성 개선
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final item = _flatItems[index];

                // Pattern matching으로 타입 안전하게 처리
                switch (item) {
                  case DateMarkerWrapper(:final marker):
                    // DateMarker: 날짜 구분선
                    return DateDivider(date: marker.date);

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

                    // AutoScrollTag의 index도 sequential index 사용
                    return AutoScrollTag(
                      key: ValueKey('post_${post.id}'),
                      controller: _scrollController,
                      index:
                          index, // SliverChildBuilderDelegate의 sequential index 사용
                      child: child,
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
    return Stack(
      children: [
        Opacity(opacity: _isInitialLoading ? 0.0 : 1.0, child: scrollView),
        if (_isInitialLoading)
          Positioned.fill(
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return AppEmptyState.noPosts();
  }

  Widget _buildErrorState() {
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
              _errorMessage ?? '알 수 없는 오류가 발생했습니다',
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
