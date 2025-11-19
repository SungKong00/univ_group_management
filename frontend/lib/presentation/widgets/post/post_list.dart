import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/date_marker.dart';
import '../../../core/models/post_list_item.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/post/domain/entities/post.dart';
import '../../../features/post/presentation/providers/post_list_state.dart';
import 'date_divider.dart';
import 'post_item.dart';
import 'post_list_constants.dart';
import 'post_list_view.dart';
import 'post_sticky_header.dart';

/// 게시글 목록 위젯 (기본 조회 기능만)
///
/// 기능:
/// - 게시글 목록 렌더링 (최신 → 오래된 순)
/// - Flat List 구조 (날짜 마커 + 게시글)
/// - Sticky Header (현재 보이는 날짜)
/// - 무한 스크롤
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
  late final ScrollController _scrollController;

  List<PostListItem> _flatItems = [];
  bool _isInitialLoading = true;

  // Sticky Date Header
  DateTime? _stickyDate;
  final Map<int, GlobalKey> _keys = {};
  final Map<int, DateTime> _dates = {};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // 초기화는 _buildScrollView에서 자동으로 진행
  }


  @override
  void didUpdateWidget(PostList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.channelId != widget.channelId) {
      _resetAndLoad();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _resetAndLoad() {
    setState(() {
      _flatItems = [];
      _isInitialLoading = true;
    });
  }

  void _handlePostUpdated() {
    _resetAndLoad();
  }

  void _handlePostDeleted() {
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

    // ✅ 첫 로드 시 flat list 생성 및 초기 로딩 종료
    if (_flatItems.isEmpty && postListState.posts.isNotEmpty) {
      // PostFrameCallback: 빌드 중 setState 방지
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _flatItems = _buildFlatList(postListState.posts);
            _isInitialLoading = false;
          });
        }
      });
    }

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
                    final itemKey = _keys[index];
                    return Container(
                      key: itemKey,
                      child: Column(
                        children: [
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
