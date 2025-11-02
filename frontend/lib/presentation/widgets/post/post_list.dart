import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';

import '../../../core/models/post_models.dart';
import '../../../core/services/post_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../common/app_empty_state.dart';
import 'post_item.dart';
import 'date_divider.dart';
import 'post_skeleton.dart';

/// 게시글 목록 위젯
///
/// 채널 내 게시글 목록을 표시하고 무한 스크롤 지원
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
  final ScrollController _scrollController = ScrollController();

  // 마지막(최신) 게시물을 상단 정렬하기 위한 키
  // GlobalKey를 사용하되, channelId 기반으로 unique하게 생성하여
  // 로그아웃/재로그인 시 Duplicate GlobalKey 에러 방지
  late final GlobalKey _lastPostKey;
  // 최신 날짜의 헤더 높이를 측정하기 위한 키
  late final GlobalKey _lastDateHeaderKey;

  List<Post> _posts = [];
  Map<DateTime, List<Post>> _groupedPosts = {};
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  String? _errorMessage;

  // 최초 로드 직후 스크롤 정렬 과정에서 화면 점프가 보이지 않도록 잠시 숨김 처리
  bool _isInitialAnchoring = false;

  @override
  void initState() {
    super.initState();
    // channelId 기반으로 unique한 GlobalKey 생성
    _lastPostKey = GlobalKey(debugLabel: 'lastPost_${widget.channelId}');
    _lastDateHeaderKey = GlobalKey(debugLabel: 'lastDateHeader_${widget.channelId}');
    _loadPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(PostList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 채널이 변경되면 목록 재로드
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
      _posts = [];
      _groupedPosts = {};
      _currentPage = 0;
      _hasMore = true;
      _errorMessage = null;
      _isInitialAnchoring = false;
    });
    _loadPosts();
  }

  /// 게시글이 수정되었을 때 호출 - 전체 목록 새로고침
  void _handlePostUpdated() {
    _resetAndLoad();
  }

  /// 게시글이 삭제되었을 때 호출 - 전체 목록 새로고침
  void _handlePostDeleted() {
    _resetAndLoad();
  }

  Future<void> _loadPosts() async {
    if (_isLoading || !_hasMore) return;

    // 스크롤 위치 저장 (첫 로드가 아닐 때만)
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

      // --- Ensure deterministic ordering ---
      // Sort incoming page posts by createdAt ascending (oldest -> newest)
      response.posts.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      // 첫 페이지 로드인지 사전 체크 (증가 전 기준)
      final bool isFirstPageLoad = _currentPage == 0;

      if (!mounted) return;
      setState(() {
        // 정상 스크롤: 새로 로드되는 과거 글을 앞에 추가
        _posts.insertAll(0, response.posts);
        // 날짜별로 재그룹화
        _groupedPosts = _groupPostsByDate(_posts);
        _currentPage++;
        _hasMore = response.hasMore;
        _isLoading = false;

        // 첫 로드 직후에는 화면 점프가 보이지 않도록 잠시 숨김
        if (isFirstPageLoad) {
          _isInitialAnchoring = true;
        }
      });

      // 첫 로드 시: 최신(마지막) 게시물을 화면 상단에 정확히 정렬
      if (isFirstPageLoad) {
        _anchorLastPostAtTop();
      }
      // 추가 로드 시 스크롤 위치 유지
      else if (savedScrollOffset != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            // 새 콘텐츠 높이만큼 스크롤 위치 조정
            final delta =
                _scrollController.position.maxScrollExtent -
                (savedMaxScrollExtent ?? 0);
            _scrollController.jumpTo(savedScrollOffset! + delta);
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isInitialAnchoring = false;
      });
    }
  }

  // 최신(마지막) 게시물을 화면 상단에 정확히 오도록 스크롤하는 보조 함수
  void _anchorLastPostAtTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      try {
        final lastPostContext = _lastPostKey.currentContext;
        final lastHeaderContext = _lastDateHeaderKey.currentContext;

        if (lastPostContext != null && _scrollController.hasClients) {
          final lastPostRenderBox =
              lastPostContext.findRenderObject() as RenderBox;
          // 마지막 게시물의 전역 Y 위치 (화면 상단 기준)
          final lastPostGlobalOffset = lastPostRenderBox.localToGlobal(
            Offset.zero,
            ancestor: context.findRenderObject(),
          );
          // 현재 스크롤된 거리
          final currentScrollOffset = _scrollController.offset;

          // 헤더 높이 측정 (없으면 0)
          double headerHeight = 0;
          if (lastHeaderContext != null) {
            final headerRenderBox =
                lastHeaderContext.findRenderObject() as RenderBox;
            headerHeight = headerRenderBox.size.height;
          }

          // 목표 스크롤 위치 계산:
          // 현재 스크롤 위치 + (게시물 위치 - 헤더 높이)
          // 이렇게 하면 게시물 상단이 헤더 바로 아래에 위치하게 됨
          final targetOffset =
              currentScrollOffset + lastPostGlobalOffset.dy - headerHeight;

          final clampedOffset = targetOffset.clamp(
            _scrollController.position.minScrollExtent,
            _scrollController.position.maxScrollExtent,
          );

          _scrollController.jumpTo(clampedOffset);

          // 정렬 완료 후 다음 프레임에 화면 표시
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _isInitialAnchoring = false;
              });
            }
          });
          return;
        }
      } catch (e) {
        // RenderObject가 준비되지 않는 등 예외 발생 시 폴백 로직으로 넘어감
      }

      // 키를 아직 못 찾았거나 예외 발생 시: 일단 하단으로 점프한 뒤 한 프레임 뒤 재시도
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // 재시도 로직은 동일하게 유지
        _anchorLastPostAtTop();
      });
    });
  }

  void _onScroll() {
    // 초기 정렬 중에는 스크롤 로딩을 막아 화면 점프 및 과도한 로드를 방지
    if (_isInitialAnchoring) return;
    // 정상 스크롤: 상단에 도달하면 과거 글 로드
    if (_scrollController.position.pixels <= 200) {
      _loadPosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 로딩 중 (첫 로드)
    if (_posts.isEmpty && _isLoading) {
      return const PostListSkeleton();
    }

    // 에러 상태
    if (_posts.isEmpty && _errorMessage != null) {
      return _buildErrorState();
    }

    // 빈 상태
    if (_posts.isEmpty) {
      return _buildEmptyState();
    }

    // 게시글 목록 (날짜별 그룹화 + StickyHeader)
    final scrollView = LayoutBuilder(
      builder: (context, constraints) {
        // 날짜 키 리스트 (최신 날짜가 마지막)
        final dateKeys = _groupedPosts.keys.toList()..sort();
        final DateTime? lastDate = dateKeys.isNotEmpty ? dateKeys.last : null;

        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            // 로딩 인디케이터
            if (_isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            // 날짜별 게시글 그룹
            ...dateKeys.map((date) {
              final postsInDate = _groupedPosts[date]!;
              final bool isLastDate = lastDate != null && date == lastDate;

              return SliverStickyHeader(
                header: isLastDate
                    ? Container(
                        key: _lastDateHeaderKey,
                        child: DateDivider(date: date),
                      )
                    : DateDivider(date: date),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final post = postsInDate[index];
                    final bool isLastItem =
                        isLastDate && index == postsInDate.length - 1;

                    final child = Column(
                      children: [
                        PostItem(
                          post: post,
                          onTapComment: () =>
                              widget.onTapComment?.call(post.id),
                          onTapPost: () {
                            // TODO: 게시글 상세 보기 (나중에 구현)
                          },
                          onPostUpdated: _handlePostUpdated,
                          onPostDeleted: _handlePostDeleted,
                        ),
                        const Divider(height: 1, color: AppColors.neutral200),
                      ],
                    );

                    // 최신 날짜의 마지막 게시물에 키 부여
                    return isLastItem
                        ? Container(key: _lastPostKey, child: child)
                        : child;
                  }, childCount: postsInDate.length),
                ),
              );
            }),
            // 하단 여백을 화면 높이의 일부만큼 확보하여 마지막 아이템을 상단에 붙일 수 있도록 함
            SliverPadding(
              padding: EdgeInsets.only(bottom: constraints.maxHeight * 0.3),
            ),
          ],
        );
      },
    );

    // 초기 정렬 중에는 리스트를 투명하게 렌더링하여 점프를 숨기고, 스피너만 노출
    return Stack(
      children: [
        Opacity(opacity: _isInitialAnchoring ? 0.0 : 1.0, child: scrollView),
        if (_isInitialAnchoring)
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

  // 게시글을 날짜별로 그룹화
  Map<DateTime, List<Post>> _groupPostsByDate(List<Post> posts) {
    final Map<DateTime, List<Post>> grouped = {};

    for (final post in posts) {
      // 년-월-일만 추출 (시간 정보 제거)
      final dateKey = DateTime(
        post.createdAt.year,
        post.createdAt.month,
        post.createdAt.day,
      );

      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(post);
    }

    // Ensure each group's posts are sorted ascending by createdAt (oldest -> newest)
    for (final key in grouped.keys) {
      grouped[key]!.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    return grouped;
  }
}
