import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../core/models/date_marker.dart';
import '../../../core/models/post_list_item.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/channel/domain/usecases/calculate_unread_position_usecase.dart';
import '../../../features/channel/presentation/providers/channel_read_position_notifier.dart';
import '../../../features/post/domain/entities/post.dart';
import '../../../features/post/presentation/providers/post_list_notifier.dart';
import '../../../features/post/presentation/providers/post_list_state.dart';
import 'date_divider.dart';
import 'post_item.dart';
import 'post_list_constants.dart';
import 'post_list_view.dart';
import 'post_sticky_header.dart';
import 'unread_message_divider.dart';

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

  // 가시성 추적은 ChannelReadPositionNotifier에 위임됨
  bool _hasScrolledToUnread = false;

  // Sticky Date Header
  DateTime? _stickyDate;
  final Map<int, GlobalKey> _keys = {};
  final Map<int, DateTime> _dates = {};

  @override
  void initState() {
    super.initState();
    _scrollController = AutoScrollController();
    _scrollController.addListener(_onScroll);

    // AsyncNotifier 패턴: 스크롤 위치만 복원 (Provider가 데이터 로딩)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _restoreScrollPosition();
      }
    });
  }

  /// 스크롤 위치 복원 (AsyncNotifier 패턴용)
  Future<void> _restoreScrollPosition() async {
    final channelIdInt = int.tryParse(widget.channelId);
    if (channelIdInt == null) return;

    // ✅ Phase 3.3: Race Condition 방지 - 시작 시점의 channelId 저장
    final originalChannelId = widget.channelId;

    // 🔴 개선: AsyncNotifier 데이터 로딩 완료 대기 (최대 5초)
    int dataWaitAttempts = 0;
    const maxDataWaitAttempts = 50; // 100ms * 50 = 5초
    while (dataWaitAttempts < maxDataWaitAttempts) {
      // ✅ Phase 3.3: 채널 변경 감지
      if (!mounted || widget.channelId != originalChannelId) return;

      final postListAsync = ref.read(
        postListAsyncNotifierProvider(widget.channelId),
      );

      // 데이터가 로드되었는지 확인
      if (postListAsync.hasValue && postListAsync.valueOrNull != null) {
        developer.log(
          '[PostList] AsyncNotifier data loaded after ${dataWaitAttempts * 100}ms',
          name: 'PostList',
        );
        break;
      }

      // 에러가 발생한 경우 중단
      if (postListAsync.hasError) {
        developer.log(
          '[PostList] AsyncNotifier loading failed with error: ${postListAsync.error}',
          name: 'PostList',
          error: postListAsync.error,
          level: 900,
        );
        return;
      }

      await Future.delayed(const Duration(milliseconds: 100));
      dataWaitAttempts++;
    }

    if (dataWaitAttempts >= maxDataWaitAttempts) {
      developer.log(
        '[PostList] AsyncNotifier data loading timeout after 5 seconds',
        name: 'PostList',
        level: 900,
      );
      return;
    }

    // 읽음 위치 데이터 대기
    await _waitForReadPositionData(channelIdInt);
    // ✅ Phase 3.3: 채널 변경 감지
    if (!mounted || widget.channelId != originalChannelId) return;

    // 게시글 목록 가져오기 (이제 확실히 데이터가 있음)
    final postListAsync = ref.read(
      postListAsyncNotifierProvider(widget.channelId),
    );
    final postListState = postListAsync.valueOrNull;
    if (postListState == null || postListState.posts.isEmpty) {
      developer.log(
        '[PostList] No posts available even after waiting',
        name: 'PostList',
        level: 900,
      );
      return;
    }

    // Flat List 생성
    final flatItems = _buildFlatList(postListState.posts);
    // ✅ Phase 3.3: 채널 변경 감지
    if (!mounted || widget.channelId != originalChannelId) return;

    // ✅ Phase 3.1: CalculateUnreadPositionUseCase 사용
    final readPositionState = ref.read(channelReadPositionProvider);
    final lastReadPostId = readPositionState.lastReadPostIdMap[channelIdInt];

    // UseCase로 읽지 않은 위치 계산
    final calculateUnreadUseCase = CalculateUnreadPositionUseCase();
    final result = calculateUnreadUseCase(postListState.posts, lastReadPostId);

    // FlatList에서 해당 게시글의 인덱스 찾기
    int? firstUnreadIdx;
    if (result.hasUnread && result.unreadIndex != null) {
      final unreadPost = postListState.posts[result.unreadIndex!];
      for (int i = 0; i < flatItems.length; i++) {
        final item = flatItems[i];
        if (item is PostWrapper && item.post.id == unreadPost.id) {
          firstUnreadIdx = i;
          developer.log(
            '[PostList] Found first unread post at flatList index $i (postId: ${unreadPost.id}, totalUnread: ${result.totalUnread})',
            name: 'PostList',
          );
          break;
        }
      }
    }

    setState(() {
      _flatItems = flatItems;
      _firstUnreadPostIndex = firstUnreadIdx;
      _isInitialLoading = false;
    });

    developer.log(
      '[PostList] _firstUnreadPostIndex set to: $_firstUnreadPostIndex (lastReadPostId: $lastReadPostId)',
      name: 'PostList',
    );

    // 읽음 위치 계산 및 스크롤
    _scrollToUnreadPost();

    // Sticky header 초기화
    if (_firstUnreadPostIndex == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateSticky());
    }
  }

  @override
  void didUpdateWidget(PostList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.channelId != widget.channelId) {
      _hasScrolledToUnread = false;
      _firstUnreadPostIndex = null;
      _resetAndLoad();
    }
  }

  @override
  void dispose() {
    // ✅ ChannelReadPositionNotifier가 읽음 위치를 관리하므로
    // dispose에서 별도로 처리할 필요가 없습니다.

    _scrollController.dispose();
    super.dispose();
  }

  void _resetAndLoad() {
    setState(() {
      _flatItems = [];
      _isInitialLoading = true;
      _firstUnreadPostIndex = null;
      _hasScrolledToUnread = false;
    });
    _restoreScrollPosition();
  }

  void _handlePostUpdated() {
    _resetAndLoad();
  }

  /// ✅ Phase 3.2: Optimistic UI - 게시글 삭제 후 UnreadMessageDivider 재계산
  void _handlePostDeleted() {
    // 전체 리로드 대신 AsyncNotifier 상태만 다시 읽어서 재계산
    _resetAndLoad();
  }

  /// 읽음 위치 데이터가 준비될 때까지 대기
  Future<void> _waitForReadPositionData(int channelId) async {
    await Future.delayed(PostListConstants.readPositionRetryDelay);

    for (
      int attempt = 0;
      attempt < PostListConstants.readPositionMaxRetries;
      attempt++
    ) {
      if (!mounted) return; // ✅ dispose 후 실행 방지
      final readPositionState = ref.read(channelReadPositionProvider);

      if (readPositionState.lastReadPostIdMap.containsKey(channelId)) {
        return;
      }

      if (attempt < PostListConstants.readPositionMaxRetries - 1) {
        await Future.delayed(PostListConstants.readPositionRetryDelay);
      }
    }
  }

  /// Phase 2: Flat List 생성 (날짜 마커와 게시글을 번갈아 배치)
  ///
  /// **구조**: [DateMarkerWrapper, PostWrapper, PostWrapper, DateMarkerWrapper, PostWrapper, ...]
  ///
  /// **정렬**: oldest → newest (최신글이 리스트 마지막)
  List<PostListItem> _buildFlatList(List<Post> posts) {
    if (posts.isEmpty) {
      _keys.clear();
      _dates.clear();
      return [];
    }

    final List<PostListItem> flatItems = [];
    DateTime? currentDate;

    _keys.clear();
    _dates.clear();

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
        _keys[dateMarkerIndex] = GlobalKey();
        _dates[dateMarkerIndex] = postDate;
        currentDate = postDate;
      }

      final postIndex = flatItems.length;
      flatItems.add(PostWrapper(post));
      _keys[postIndex] = GlobalKey();
      _dates[postIndex] = currentDate!;
    }

    return flatItems;
  }

  /// 읽지 않은 게시글로 스크롤
  Future<void> _scrollToUnreadPost() async {
    developer.log(
      '[PostList] _scrollToUnreadPost called - index: $_firstUnreadPostIndex, hasScrolled: $_hasScrolledToUnread',
      name: 'PostList',
    );

    if (_firstUnreadPostIndex == null || _hasScrolledToUnread) {
      developer.log(
        '[PostList] Skipping scroll - index is null or already scrolled',
        name: 'PostList',
      );
      return;
    }

    try {
      // ScrollController가 준비될 때까지 대기
      if (!_scrollController.hasClients) {
        developer.log(
          '[PostList] ScrollController not ready, waiting...',
          name: 'PostList',
        );
        await Future.delayed(PostListConstants.scrollControllerWaitTime);
      }

      // 여전히 준비되지 않았으면 최하단으로 스크롤
      if (!_scrollController.hasClients) {
        developer.log(
          '[PostList] ScrollController still not ready, aborting scroll',
          name: 'PostList',
        );
        setState(() {
          _isInitialLoading = false;
        });
        return;
      }

      developer.log(
        '[PostList] Scrolling to index $_firstUnreadPostIndex',
        name: 'PostList',
      );
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
            (currentOffset - PostListConstants.stickyHeaderHeight).clamp(
              _scrollController.position.minScrollExtent,
              _scrollController.position.maxScrollExtent,
            );
        developer.log(
          '[PostList] Adjusting scroll offset from $currentOffset to $adjustedOffset',
          name: 'PostList',
        );
        _scrollController.jumpTo(adjustedOffset);
      }

      _hasScrolledToUnread = true;
      developer.log(
        '[PostList] Scroll to unread completed successfully',
        name: 'PostList',
      );

      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _updateSticky());
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
      developer.log(
        '[PostList] 읽지 않은 글 스크롤 실패 - 채널 ID: ${widget.channelId}, 대상 index: $_firstUnreadPostIndex',
        name: 'PostList',
        error: e,
        level: 900,
      );
      if (e is! StateError) {
        // StateError(Bad state)가 아닌 경우에만 스택 추적 출력
        developer.log('스택 추적: $stackTrace', name: 'PostList', level: 900);
      }
    }
  }

  void _onScroll() {
    if (_isInitialLoading) return;

    // ✨ PostFrameCallback: 렌더링 완료 후 sticky header 업데이트
    // 마우스 휠 스크롤 시 RenderBox가 아직 렌더링되지 않은 문제 해결
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateSticky();
      }
    });
  }

  void _updateSticky() {
    if (!_scrollController.hasClients || _flatItems.isEmpty) return;

    int? firstVisibleIndex;

    for (final entry in _keys.entries) {
      final index = entry.key;
      final key = entry.value;

      final box = key.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) continue;

      try {
        final pos = box.localToGlobal(Offset.zero);

        // TopNavigation + ChannelHeader 아래에서 조금이라도 보이는 항목
        if (pos.dy + box.size.height > PostListConstants.stickyThreshold) {
          firstVisibleIndex = index;
          break; // 첫 번째 발견 시 중단
        }
      } catch (e) {
        continue;
      }
    }

    if (firstVisibleIndex != null) {
      final newDate = _dates[firstVisibleIndex];
      if (newDate != _stickyDate) {
        setState(() => _stickyDate = newDate);
      }
    }
  }

  // 가시성 추적은 ChannelReadPositionNotifier에 위임됨
  // 더 이상 로컬 상태를 관리하지 않습니다.

  @override
  Widget build(BuildContext context) {
    // AsyncNotifier 패턴 사용 (Feature Flag 통해 제어)
    return PostListView(
      channelId: widget.channelId,
      buildScrollView: _buildScrollView,
    );
  }

  /// 공통: ScrollView 렌더링 로직
  Widget _buildScrollView(dynamic data) {
    final postListState = data as PostListState;
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
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final item = _flatItems[index];

                // Pattern matching으로 타입 안전하게 처리
                switch (item) {
                  case DateMarkerWrapper(:final marker):
                    // DateMarker: 날짜 구분선
                    final itemKey = _keys[index];
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
                        // Widget dispose 후 콜백 실행 방지
                        if (!mounted) return;

                        // 50% 이상 보이면 읽음 처리 (ChannelReadPositionNotifier에 위임)
                        if (info.visibleFraction >
                            PostListConstants.readVisibilityThreshold) {
                          ref
                              .read(channelReadPositionProvider.notifier)
                              .updateVisibility(post.id, true);
                        } else {
                          ref
                              .read(channelReadPositionProvider.notifier)
                              .updateVisibility(post.id, false);
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

                    final itemKey = _keys[index];
                    return Container(
                      key: itemKey,
                      child: AutoScrollTag(
                        key: ValueKey('post_${post.id}'),
                        controller: _scrollController,
                        index: index,
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
    return Stack(
      children: [
        Opacity(opacity: _isInitialLoading ? 0.0 : 1.0, child: scrollView),
        if (_isInitialLoading)
          const Positioned.fill(
            child: Center(child: CircularProgressIndicator()),
          ),
        if (!_isInitialLoading)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: PostStickyHeader(stickyDate: _stickyDate),
          ),
      ],
    );
  }
}
