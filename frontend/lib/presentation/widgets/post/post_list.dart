import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      _currentPage = 0;
      _hasMore = true;
      _errorMessage = null;
    });
    _loadPosts();
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
        // reverse 모드를 위해 새로 추가되는 글을 앞에 삽입 (최신 글이 배열 끝에 유지)
        _posts.insertAll(0, response.posts);
        _currentPage++;
        _hasMore = response.hasMore;
        _isLoading = false;
      });

      // 스크롤 위치 복원 (첫 로드가 아닐 때만)
      if (savedScrollOffset != null && savedMaxScrollExtent != null) {
        final offset = savedScrollOffset;
        final maxExtent = savedMaxScrollExtent;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            final delta = _scrollController.position.maxScrollExtent - maxExtent;
            _scrollController.jumpTo(offset + delta);
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
    // reverse 모드에서는 상단(minScrollExtent)에 도달하면 이전 글 로드
    if (_scrollController.position.pixels <=
        _scrollController.position.minScrollExtent + 200) {
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

    // 게시글 목록
    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: EdgeInsets.only(
            bottom: constraints.maxHeight * 0.3,
          ),
          itemCount: _posts.length + (_isLoading ? 1 : 0),
          itemBuilder: (context, index) {
        // 로딩 인디케이터
        if (index == _posts.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final post = _posts[index];
        final showDateDivider = _shouldShowDateDivider(index);

        return Column(
          children: [
            if (showDateDivider) DateDivider(date: post.createdAt),
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
        );
      },
    );
  }

  bool _shouldShowDateDivider(int index) {
    // reverse 모드에서는 마지막 아이템(최신)이 첫 날짜 구분선을 가짐
    if (index == _posts.length - 1) return true;

    final currentPost = _posts[index];
    final nextPost = _posts[index + 1]; // reverse 모드에서는 다음 아이템과 비교

    final currentDate = DateTime(
      currentPost.createdAt.year,
      currentPost.createdAt.month,
      currentPost.createdAt.day,
    );

    final nextDate = DateTime(
      nextPost.createdAt.year,
      nextPost.createdAt.month,
      nextPost.createdAt.day,
    );

    return currentDate != nextDate;
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
