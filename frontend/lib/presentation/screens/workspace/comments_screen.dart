import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/workspace_models.dart';
import '../../providers/workspace_provider.dart';

class CommentsScreen extends StatefulWidget {
  final int postId;
  final String postAuthor;

  const CommentsScreen({
    super.key,
    required this.postId,
    required this.postAuthor,
  });

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  PostModel? _post;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCommentsAndPost();
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadCommentsAndPost() {
    final provider = context.read<WorkspaceProvider>();

    // 현재 채널의 게시글에서 해당 postId 찾기
    final posts = provider.currentChannelPosts;
    _post = posts.firstWhere(
      (post) => post.id == widget.postId,
      orElse: () => posts.isNotEmpty ? posts.first : throw Exception('Post not found'),
    );

    // 댓글 로드
    provider.loadPostComments(widget.postId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Consumer<WorkspaceProvider>(
          builder: (context, provider, child) {
            final comments = provider.getCommentsForPost(widget.postId);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '댓글 ${comments.length}개',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${widget.postAuthor}님의 게시글',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            );
          },
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 1,
      ),
      body: Column(
        children: [
          // 원본 게시글 미리보기 (선택사항)
          if (_post != null) _buildPostPreview(context, _post!),
          const Divider(height: 1),
          // 댓글 목록
          Expanded(
            child: Consumer<WorkspaceProvider>(
              builder: (context, provider, child) {
                return _buildCommentsList(context, provider);
              },
            ),
          ),
          const Divider(height: 1),
          // 댓글 입력창
          _buildCommentInput(context),
        ],
      ),
    );
  }

  Widget _buildPostPreview(BuildContext context, PostModel post) {
    return Container(
      padding: const EdgeInsets.all(UIConstants.defaultPadding),
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  post.author.name.isNotEmpty ? post.author.name[0] : '?',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                post.author.name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatTimestamp(post.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            post.content,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList(BuildContext context, WorkspaceProvider provider) {
    final comments = provider.getCommentsForPost(widget.postId);

    if (comments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              '아직 댓글이 없습니다',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '첫 번째 댓글을 작성해보세요!',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(UIConstants.defaultPadding),
      itemCount: comments.length,
      itemBuilder: (context, index) {
        final comment = comments[index];
        return _buildCommentTile(context, comment, provider);
      },
    );
  }

  Widget _buildCommentTile(
    BuildContext context,
    CommentModel comment,
    WorkspaceProvider provider,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: UIConstants.commentSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 댓글 헤더
          Row(
            children: [
              CircleAvatar(
                radius: ResponsiveBreakpoints.commentAvatarSize / 2,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  comment.author.name.isNotEmpty ? comment.author.name[0] : '?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.author.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _formatTimestamp(comment.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // 댓글 액션 버튼들
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('수정'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete),
                        SizedBox(width: 8),
                        Text('삭제'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'delete') {
                    _deleteComment(context, provider, comment);
                  } else if (value == 'edit') {
                    // TODO: 댓글 수정 기능 구현
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('댓글 수정 기능은 준비 중입니다')),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 댓글 내용
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(UIConstants.commentBorderRadius),
            ),
            child: Text(
              comment.content,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: UIConstants.defaultPadding,
        right: UIConstants.defaultPadding,
        top: UIConstants.defaultPadding,
        bottom: UIConstants.defaultPadding + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: ResponsiveBreakpoints.commentInputHeight,
                  maxHeight: ResponsiveBreakpoints.commentMaxInputHeight,
                ),
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: '댓글을 입력하세요...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(UIConstants.commentBorderRadius),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendComment(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: ResponsiveBreakpoints.commentInputHeight,
              child: IconButton(
                onPressed: _sendComment,
                icon: Icon(
                  Icons.send,
                  color: Theme.of(context).colorScheme.primary,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(UIConstants.commentBorderRadius),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    _commentController.clear();

    try {
      final provider = context.read<WorkspaceProvider>();
      await provider.createComment(
        postId: widget.postId,
        content: content,
      );

      // 댓글 작성 후 스크롤을 맨 아래로
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('댓글 작성 실패: $e')),
        );
      }
    }
  }

  void _deleteComment(
    BuildContext context,
    WorkspaceProvider provider,
    CommentModel comment,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('댓글 삭제'),
        content: const Text('정말로 이 댓글을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await provider.deleteComment(comment.id, widget.postId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('댓글이 삭제되었습니다')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('댓글 삭제 실패: $e')),
                  );
                }
              }
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays > 0) {
      return '${diff.inDays}일 전';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}시간 전';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }
}