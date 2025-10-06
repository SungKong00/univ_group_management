import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import '../../../core/models/post_models.dart';
import '../../../core/services/post_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
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

  List<Post> _posts = [];
  Map<DateTime, List<Post>> _groupedPosts = {};
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
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
    });
    _loadPosts();
  }

  /// 게시글을 날짜별로 그룹화
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

    return grouped;
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

      setState(() {
        // 정상 스크롤: 새로 로드되는 과거 글을 앞에 추가
        _posts.insertAll(0, response.posts);
        // 날짜별로 재그룹화
        _groupedPosts = _groupPostsByDate(_posts);
        _currentPage++;
        _hasMore = response.hasMore;
        _isLoading = false;
      });

      // 첫 로드 시 스크롤을 최하단으로 즉시 이동 (애니메이션 없음)
      // _currentPage++가 위에서 실행된 후이므로 첫 로드는 _currentPage == 1
      // SliverPadding 레이아웃이 완전히 완료될 때까지 충분한 시간 대기
      if (_currentPage == 1) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _scrollController.hasClients) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
      }
      // 추가 로드 시 스크롤 위치 유지
      else if (savedScrollOffset != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            // 새 콘텐츠 높이만큼 스크롤 위치 조정
            final delta = _scrollController.position.maxScrollExtent - (savedMaxScrollExtent ?? 0);
            _scrollController.jumpTo(savedScrollOffset! + delta);
          }
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _onScroll() {
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
    return LayoutBuilder(
      builder: (context, constraints) {
        // 날짜 키 리스트 (최신 날짜가 마지막)
        final dateKeys = _groupedPosts.keys.toList()..sort();

        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            // 로딩 인디케이터
            if (_isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            // 날짜별 게시글 그룹
            ...dateKeys.map((date) {
              final postsInDate = _groupedPosts[date]!;

              return SliverStickyHeader(
                header: DateDivider(date: date),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final post = postsInDate[index];
                      return Column(
                        children: [
                          PostItem(
                            post: post,
                            onTapComment: () => widget.onTapComment?.call(post.id),
                            onTapPost: () {
                              // TODO: 게시글 상세 보기 (나중에 구현)
                            },
                          ),
                          const Divider(height: 1, color: AppColors.neutral200),
                        ],
                      );
                    },
                    childCount: postsInDate.length,
                  ),
                ),
              );
            }),
            // 하단 여백 (마지막 게시글이 화면 상단에 오고, 그 아래 추가 공백까지 보이도록 설정)
            SliverPadding(
              padding: EdgeInsets.only(bottom: constraints.maxHeight * 0.3),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: AppColors.neutral400,
            ),
            const SizedBox(height: 16),
            Text(
              '게시글이 없습니다',
              style: AppTheme.headlineMedium.copyWith(
                color: AppColors.neutral700,
              ),
            ),
            const SizedBox(height: 8),
            if (widget.canWrite) ...[
              Text(
                '첫 글을 작성해보세요',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppColors.neutral600,
                ),
              ),
            ] else ...[
              Text(
                '아직 작성된 글이 없습니다',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppColors.neutral600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
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
              style: AppTheme.bodyMedium.copyWith(
                color: AppColors.neutral600,
              ),
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
                style: AppTheme.titleMedium.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}