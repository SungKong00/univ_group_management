import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../data/models/workspace_models.dart';
import '../../../providers/workspace_provider.dart';

class CommentsSidebar extends StatefulWidget {
  const CommentsSidebar({super.key});

  @override
  State<CommentsSidebar> createState() => _CommentsSidebarState();
}

class _CommentsSidebarState extends State<CommentsSidebar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: ResponsiveBreakpoints.sidebarAnimationDuration,
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // 사이드바가 표시될 때 애니메이션 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkspaceProvider>(
      builder: (context, provider, child) {
        final post = provider.selectedPostForComments;
        if (post == null) return const SizedBox.shrink();

        // 웹에서 안전한 사이드바 구현
        final screenSize = MediaQuery.of(context).size;
        final maxSidebarWidth = kIsWeb
            ? math.min(ResponsiveBreakpoints.commentsSidebarWidth, screenSize.width * 0.4)
            : ResponsiveBreakpoints.commentsSidebarWidth;

        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          )),
          child: SizedBox(
            width: maxSidebarWidth,
            child: Material(
              elevation: UIConstants.sidebarElevation,
              color: Theme.of(context).colorScheme.surface,
              child: SafeArea(
                child: Column(
                  children: [
                    _buildHeader(context, post, provider),
                    const Divider(height: 1),
                    Expanded(
                      child: _buildCommentsList(context, provider, post),
                    ),
                    const Divider(height: 1),
                    _buildCommentInput(context, provider, post),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, PostModel post, WorkspaceProvider provider) {
    final comments = provider.getCommentsForPost(post.id);

    return Container(
      padding: const EdgeInsets.all(ResponsiveBreakpoints.commentPadding),
      child: Row(
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '댓글 ${comments.length}개',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${post.author.name}님의 게시글',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: const Key('comments_sidebar_close_button'),
            onPressed: () => _closeSidebar(provider),
            icon: const Icon(Icons.close),
            tooltip: '',
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList(BuildContext context, WorkspaceProvider provider, PostModel post) {
    final comments = provider.getCommentsForPost(post.id);

    if (comments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              '아직 댓글이 없습니다',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
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
      padding: const EdgeInsets.all(ResponsiveBreakpoints.commentPadding),
      itemCount: comments.length,
      itemBuilder: (context, index) {
        final comment = comments[index];
        return _buildCommentTile(context, comment, provider, post);
      },
    );
  }

  Widget _buildCommentTile(
    BuildContext context,
    CommentModel comment,
    WorkspaceProvider provider,
    PostModel post,
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
                radius: ResponsiveBreakpoints.commentAvatarSize / 2 - 4,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  comment.author.name.isNotEmpty ? comment.author.name[0] : '?',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.author.name,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _formatTimestamp(comment.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // 댓글 액션 버튼들
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16),
                        SizedBox(width: 8),
                        Text('수정'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16),
                        SizedBox(width: 8),
                        Text('삭제'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'delete') {
                    _deleteComment(context, provider, comment, post);
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
          const SizedBox(height: 8),
          // 댓글 내용
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
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

  Widget _buildCommentInput(BuildContext context, WorkspaceProvider provider, PostModel post) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            key: const Key('comments_sidebar_attach_button'),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('파일 첨부 기능 구현 예정')),
              );
            },
            icon: const Icon(Icons.attach_file),
            tooltip: '',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: '댓글을 입력하세요...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendComment(provider, post),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            key: const Key('comments_sidebar_send_button'),
            onPressed: () => _sendComment(provider, post),
            icon: const Icon(Icons.send),
            tooltip: '',
          ),
        ],
      ),
    );
  }

  void _closeSidebar(WorkspaceProvider provider) async {
    await _animationController.reverse();
    provider.hideCommentsSidebar();
  }

  void _sendComment(WorkspaceProvider provider, PostModel post) async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    _commentController.clear();

    try {
      await provider.createComment(
        postId: post.id,
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
    PostModel post,
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
                await provider.deleteComment(comment.id, post.id);
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