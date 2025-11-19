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
  int _unreadCount = 0;

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

    // Deterministic Initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initialize();
      }
    });
  }

  /// Deterministic Initialization Flow
  /// 1. Load Read Position (Server)
  /// 2. Load Posts (Server)
  /// 3. Calculate Unread Index
  /// 4. Render & Scroll
  Future<void> _initialize() async {
    final channelIdInt = int.tryParse(widget.channelId);
    if (channelIdInt == null) return;

    // 1. Load Read Position
    await ref.read(channelReadPositionProvider.notifier).loadReadPosition(channelIdInt);
    if (!mounted) return;

    // 2. Load Posts (Wait for AsyncNotifier)
    // Force refresh to ensure we have latest data
    // Note: In a real app, we might want to check if data is already fresh
    final postListAsync = ref.read(postListAsyncNotifierProvider(widget.channelId));
    
    // If loading, wait for it. If error, show error.
    if (postListAsync.isLoading) {
      // The provider is already loading, just wait for the next value
      // We can use a stream or just check periodically (but we want to avoid arbitrary waits)
      // Better: Use ref.listen in initState, but for now let's just wait for the future
      // Actually, AsyncNotifierProvider.future returns the future of the build method
      try {
        await ref.read(postListAsyncNotifierProvider(widget.channelId).future);
      } catch (e) {
        developer.log('[PostList] Failed to load posts: $e', name: 'PostList');
        return;
      }
    } else if (!postListAsync.hasValue) {
       // Trigger load if not loaded
       // This happens automatically by reading the provider, but we await the future to be sure
       try {
         await ref.read(postListAsyncNotifierProvider(widget.channelId).future);
       } catch (e) {
         return;
       }
    }

    if (!mounted) return;

    // 3. Get Data & Calculate
    final postListState = ref.read(postListAsyncNotifierProvider(widget.channelId)).valueOrNull;
    final readPositionState = ref.read(channelReadPositionProvider);
    final lastReadPostId = readPositionState.lastReadPostIdMap[channelIdInt];

    if (postListState == null || postListState.posts.isEmpty) {
      setState(() => _isInitialLoading = false);
      return;
    }

    // Build Flat List
    final flatItems = _buildFlatList(postListState.posts);

    // Calculate Unread
    final calculateUnreadUseCase = CalculateUnreadPositionUseCase();
    final result = calculateUnreadUseCase(postListState.posts, lastReadPostId);

    int? firstUnreadIdx;
    if (result.hasUnread && result.unreadIndex != null) {
      final unreadPost = postListState.posts[result.unreadIndex!];
      // Find index in flat list
      for (int i = 0; i < flatItems.length; i++) {
        final item = flatItems[i];
        if (item is PostWrapper && item.post.id == unreadPost.id) {
          firstUnreadIdx = i;
          break;
        }
      }
    } else if (result.hasUnread && result.unreadIndex == null) {
        // Case: Unread posts exist but are not in the loaded list (too old)
        // Fallback: Show "New Messages" banner or just scroll to bottom (latest)
        // For now, we will just show the latest posts (bottom)
        // TODO: Implement "Load Previous" or "Jump to Unread" banner
        developer.log('[PostList] Unread post not in loaded list. Showing latest.', name: 'PostList');
    }

    // 4. Update State & Scroll
    setState(() {
      _flatItems = flatItems;
      _firstUnreadPostIndex = firstUnreadIdx;
      _unreadCount = result.totalUnread;
      // Keep loading true until scroll is done
    });

    // Execute Scroll
    await _scrollToUnreadPost();
    
    if (!mounted) return;

    // ✅ Fix Badge Update: Manually mark the first unread post as visible
    // This ensures that even if the user exits quickly, we have a valid "read" position
    if (_firstUnreadPostIndex != null && _firstUnreadPostIndex! < _flatItems.length) {
       final item = _flatItems[_firstUnreadPostIndex!];
       if (item is PostWrapper) {
         ref.read(channelReadPositionProvider.notifier).updateVisibility(item.post.id, true);
       }
    } else if (_firstUnreadPostIndex == null && _flatItems.isNotEmpty) {
       // If scrolled to bottom (all read), mark the last post as visible
       final lastItem = _flatItems.last;
       if (lastItem is PostWrapper) {
          ref.read(channelReadPositionProvider.notifier).updateVisibility(lastItem.post.id, true);
       }
    }
    
    // Sticky header init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateSticky();
      }
    });
  }

  @override
  void didUpdateWidget(PostList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.channelId != widget.channelId) {
      _hasScrolledToUnread = false;
      _firstUnreadPostIndex = null;
      _unreadCount = 0;
      _resetAndLoad();
    }
  }

  @override
  void dispose() {
    // 화면 이탈 시 읽음 위치 저장
    final channelIdInt = int.tryParse(widget.channelId);
    if (channelIdInt != null) {
      // 비동기 작업을 위해 ProviderContainer를 사용하거나
      // mounted 체크 없이 fire-and-forget으로 실행
      ref.read(channelReadPositionProvider.notifier).saveReadPosition(channelIdInt);
    }

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
    _initialize();
  }

  void _handlePostUpdated() {
    _resetAndLoad();
  }

  /// ✅ Phase 3.2: Optimistic UI - 게시글 삭제 후 UnreadMessageDivider 재계산
  void _handlePostDeleted() {
    // 전체 리로드 대신 AsyncNotifier 상태만 다시 읽어서 재계산
    _resetAndLoad();
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

    if (_firstUnreadPostIndex == null) {
      developer.log(
        '[PostList] Skipping scroll - index is null',
        name: 'PostList',
      );
      // 읽지 않은 글이 없으면 최하단으로 스크롤
      if (!_hasScrolledToUnread) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
             _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
          if (mounted) {
            setState(() {
              _isInitialLoading = false;
            });
          }
        });
      }
      return;
    }

    try {
      // ScrollController가 준비될 때까지 대기
      int attempts = 0;
      while (!_scrollController.hasClients && attempts < 10) {
        await Future.delayed(const Duration(milliseconds: 50));
        attempts++;
      }

      // 여전히 준비되지 않았으면 중단
      if (!_scrollController.hasClients) {
        developer.log(
          '[PostList] ScrollController still not ready, aborting scroll',
          name: 'PostList',
        );
        if (mounted) {
          setState(() {
            _isInitialLoading = false;
          });
        }
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
        duration: const Duration(milliseconds: 100), // 약간의 지연을 주어 부드럽게
      );

      // Sticky header 높이 보정 (DateDivider 기본 높이)
      if (_scrollController.hasClients) {
        final currentOffset = _scrollController.offset;
        // 상단 여백 확보 (헤더 등에 가려지지 않도록)
        final adjustedOffset =
            (currentOffset - PostListConstants.stickyHeaderHeight).clamp(
              _scrollController.position.minScrollExtent,
              _scrollController.position.maxScrollExtent,
            );
        
        if ((currentOffset - adjustedOffset).abs() > 1.0) {
           _scrollController.jumpTo(adjustedOffset);
        }
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

      // 스크롤 실패 시 최하단으로 스크롤 (Fallback)
      if (mounted && _scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
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
