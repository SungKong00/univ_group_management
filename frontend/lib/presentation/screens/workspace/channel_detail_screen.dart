import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../providers/workspace_provider.dart';
import '../../../data/models/workspace_models.dart';
import '../../widgets/loading_overlay.dart';

import 'widgets/comments_sidebar.dart';

class ChannelDetailScreen extends StatelessWidget {
  final ChannelModel channel;

  const ChannelDetailScreen({
    super.key,
    required this.channel,
  });

  @override
  Widget build(BuildContext context) {
    // The AppBar is now built with a Consumer to react to state changes
    return Consumer<WorkspaceProvider>(
      builder: (context, provider, child) {
        final isCommentView = provider.selectedPostForComments != null;
        final isDesktop = MediaQuery.of(context).size.width >= ResponsiveBreakpoints.mobile;

        return Scaffold(
          appBar: AppBar(
            // Back button logic for mobile comment view
            leading: !isDesktop && isCommentView
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    tooltip: '게시글 목록으로 돌아가기',
                    onPressed: () => provider.hideCommentsSidebar(),
                  )
                : null,
            title: isCommentView
                ? _buildCommentsAppBarTitle(context, provider)
                : _buildChannelAppBarTitle(context, provider),
            actions: isCommentView
                ? null // No actions in comment view for now
                : [_buildChannelActions(context, provider)],
            backgroundColor: Theme.of(context).colorScheme.surface,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            elevation: 1,
          ),
          body: ChannelDetailView(
            channel: channel,
            autoLoad: true,
            showLoadingOverlay: true,
          ),
        );
      },
    );
  }

  Widget _buildChannelAppBarTitle(BuildContext context, WorkspaceProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              _getChannelIcon(channel.type),
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                channel.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        if (channel.description != null)
          Text(
            channel.description!,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  Widget _buildCommentsAppBarTitle(BuildContext context, WorkspaceProvider provider) {
    final groupName = provider.currentWorkspace?.group.name ?? '그룹';
    final channelName = provider.currentChannel?.name ?? '채널';
    final comments = provider.getCommentsForPost(provider.selectedPostForComments!.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$groupName > $channelName',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.normal,
          ),
        ),
        Text(
          '댓글 ${comments.length}개',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildChannelActions(BuildContext context, WorkspaceProvider provider) {
    // 개발/테스트용 권한 토글 버튼
    final canWrite = provider.canWriteInCurrentChannel;
    return IconButton(
      onPressed: () {
        provider.toggleChannelWritePermission(channel.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              canWrite
                  ? '글 작성 권한이 제거되었습니다 (데모용)'
                  : '글 작성 권한이 부여되었습니다 (데모용)',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      icon: Icon(
        canWrite ? Icons.lock_open : Icons.lock,
        color: canWrite ? Colors.green : Colors.red,
      ),
      tooltip: canWrite ? '권한 제거 (테스트)' : '권한 부여 (테스트)',
    );
  }
}

class ChannelDetailView extends StatefulWidget {
  final ChannelModel channel;
  final bool autoLoad;
  final EdgeInsets contentPadding;
  final bool showLoadingOverlay;

  const ChannelDetailView({
    super.key,
    required this.channel,
    this.autoLoad = false,
    this.contentPadding = const EdgeInsets.all(16),
    this.showLoadingOverlay = false,
  });

  @override
  State<ChannelDetailView> createState() => _ChannelDetailViewState();
}

class _ChannelDetailViewState extends State<ChannelDetailView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.autoLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<WorkspaceProvider>().selectChannel(widget.channel);
      });
    }
  }

  @override
  void didUpdateWidget(covariant ChannelDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoLoad && widget.channel.id != oldWidget.channel.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<WorkspaceProvider>().selectChannel(widget.channel);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkspaceProvider>(
      builder: (context, provider, child) {
        final posts = provider.currentChannelPosts;
        final isCommentView = provider.selectedPostForComments != null;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= ResponsiveBreakpoints.mobile;

            // On desktop, the sidebar logic is separate
            if (isDesktop) {
              return _buildDesktopLayout(context, provider, posts);
            }

            // On mobile, the main view switches
            if (isCommentView) {
              return _buildMobileCommentLayout(context, provider);
            } else {
              return _buildMobilePostLayout(context, provider, posts);
            }
          },
        );
      },
    );
  }

  Widget _buildDesktopLayout(BuildContext context, WorkspaceProvider provider, List<PostModel> posts) {
    final isCommentsSidebarVisible = provider.isCommentsSidebarVisible;

    final mainContent = Column(
      children: [
        Expanded(
          child: posts.isEmpty
              ? _buildEmptyState(context)
              : _buildPostsList(context, posts, provider),
        ),
        _buildMessageComposer(context, provider, isCommentComposer: false),
      ],
    );

    Widget content;
    if (isCommentsSidebarVisible) {
      content = Row(
        children: [
          Expanded(child: mainContent),
          TapRegion(
            onTapOutside: (_) => provider.hideCommentsSidebar(),
            child: const CommentsSidebar(),
          ),
        ],
      );
    } else {
      content = mainContent;
    }

    if (widget.showLoadingOverlay) {
      return LoadingOverlay(
        isLoading: provider.isLoading,
        child: content,
      );
    }
    return content;
  }

  Widget _buildMobilePostLayout(BuildContext context, WorkspaceProvider provider, List<PostModel> posts) {
    final content = Column(
      children: [
        Expanded(
          child: posts.isEmpty
              ? _buildEmptyState(context)
              : _buildPostsList(context, posts, provider),
        ),
        _buildMessageComposer(context, provider, isCommentComposer: false),
      ],
    );

    if (widget.showLoadingOverlay) {
      return LoadingOverlay(
        isLoading: provider.isLoading,
        child: content,
      );
    }
    return content;
  }

  Widget _buildMobileCommentLayout(BuildContext context, WorkspaceProvider provider) {
    final content = Column(
      children: [
        Expanded(
          child: _buildCommentsView(context, provider),
        ),
        _buildMessageComposer(context, provider, isCommentComposer: true),
      ],
    );

    if (widget.showLoadingOverlay) {
      return LoadingOverlay(
        isLoading: provider.isLoading,
        child: content,
      );
    }
    return content;
  }

  Widget _buildCommentsView(BuildContext context, WorkspaceProvider provider) {
    final post = provider.selectedPostForComments!;
    final comments = provider.getCommentsForPost(post.id);

    // Ensure comments are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (comments.isEmpty) {
        provider.loadPostComments(post.id);
      }
    });

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverToBoxAdapter(child: _buildPostPreview(context, post)),
        const SliverToBoxAdapter(child: Divider(height: 1)),
        if (comments.isEmpty)
          SliverFillRemaining(child: _buildEmptyCommentsState(context))
        else
          _buildSliverCommentsList(context, comments, provider),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getChannelIcon(widget.channel.type),
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            '아직 메시지가 없습니다',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '첫 번째 메시지를 남겨보세요',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    PostModel post,
    WorkspaceProvider provider,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              const Spacer(),
              if (post.isPinned)
                Icon(
                  Icons.push_pin,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              post.content,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (post.attachments.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: post.attachments.map((attachment) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.attachment,
                        size: 16,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'File',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              if (post.likeCount > 0) ...[
                InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.thumb_up,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${post.likeCount}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              InkWell(
                onTap: () => _handleCommentsAction(context, post, provider),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '댓글',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageComposer(BuildContext context, WorkspaceProvider provider, {required bool isCommentComposer}) {
    final canWrite = provider.canWriteInCurrentChannel;

    // For comments, we assume if you can see the post, you can comment.
    // A more granular permission could be added later.
    final isEnabled = isCommentComposer || canWrite;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: isEnabled
            ? Theme.of(context).colorScheme.surface
            : Theme.of(context).colorScheme.surfaceVariant,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: isEnabled
            ? _buildActiveComposer(context, provider, isCommentComposer: isCommentComposer)
            : _buildDisabledComposer(context),
      ),
    );
  }

  Widget _buildActiveComposer(BuildContext context, WorkspaceProvider provider, {required bool isCommentComposer}) {
    return Row(
      children: [
        IconButton(
          onPressed: _selectAttachment,
          icon: const Icon(Icons.attach_file),
          tooltip: '파일 첨부',
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _messageController,
            focusNode: _messageFocusNode,
            decoration: InputDecoration(
              hintText: isCommentComposer ? '댓글을 입력하세요...' : '메시지를 입력하세요...',
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
            onSubmitted: (_) => isCommentComposer ? _sendComment(provider) : _sendMessage(provider),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => isCommentComposer ? _sendComment(provider) : _sendMessage(provider),
          icon: const Icon(Icons.send),
          tooltip: '전송',
        ),
      ],
    );
  }

  Widget _buildDisabledComposer(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _showPermissionInfoDialog(context);
      },
      child: Row(
        children: [
          Icon(
            Icons.lock_outline,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '이 채널에서 메시지를 작성할 권한이 없습니다',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                          ),
                    ),
                  ),
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: null,
            icon: Icon(
              Icons.send,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
            ),
            tooltip: '전송 권한 없음',
          ),
        ],
      ),
    );
  }

  void _showPermissionInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.lock_outline,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('채널 권한'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '현재 이 채널에서 다음 작업을 수행할 권한이 없습니다:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.edit,
                  size: 16,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(
                  '메시지 작성',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.attach_file,
                  size: 16,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(
                  '파일 첨부',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '채널 관리자에게 권한 요청을 문의하세요.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _sendMessage(WorkspaceProvider provider) async {
    if (!provider.canWriteInCurrentChannel) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이 채널에서 메시지를 작성할 권한이 없습니다')),
        );
      }
      return;
    }

    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();

    try {
      await provider.createPost(
        channelId: widget.channel.id,
        content: message,
        type: PostType.general,
      );

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
          SnackBar(content: Text('메시지 전송 실패: $e')),
        );
      }
    }
  }

  void _sendComment(WorkspaceProvider provider) async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final postId = provider.selectedPostForComments?.id;
    if (postId == null) return;

    _messageController.clear();

    try {
      await provider.createComment(
        postId: postId,
        content: content,
      );

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

  void _selectAttachment() {
    final provider = context.read<WorkspaceProvider>();
    final isCommentComposer = provider.selectedPostForComments != null;
    if (!isCommentComposer && !provider.canWriteInCurrentChannel) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이 채널에서 파일을 첨부할 권한이 없습니다')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('파일 첨부 기능 구현 예정')),
    );
  }

  void _handleCommentsAction(
    BuildContext context,
    PostModel post,
    WorkspaceProvider provider,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final useSidebar = screenWidth >= ResponsiveBreakpoints.mobile;

    if (useSidebar) {
      provider.showCommentsSidebar(post);
    } else {
      // On mobile, just update the state
      provider.showCommentsSidebar(post);
    }
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

  Widget _buildPostsList(BuildContext context, List<PostModel> posts, WorkspaceProvider provider) {
    final groupedPosts = _groupPostsByDate(posts);

    return ListView.builder(
      controller: _scrollController,
      padding: widget.contentPadding,
      itemCount: groupedPosts.length,
      itemBuilder: (context, index) {
        final group = groupedPosts[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateHeader(context, group.date),
            ...group.posts.map((post) => _buildMessageBubble(context, post, provider)),
          ],
        );
      },
    );
  }

  List<PostGroup> _groupPostsByDate(List<PostModel> posts) {
    final Map<String, List<PostModel>> groups = {};

    for (final post in posts) {
      final dateKey = _formatDateKey(post.createdAt);
      groups.putIfAbsent(dateKey, () => []).add(post);
    }

    return groups.entries.map((entry) =>
      PostGroup(date: entry.key, posts: entry.value)
    ).toList();
  }

  String _formatDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final postDate = DateTime(date.year, date.month, date.day);

    if (postDate == today) {
      return '오늘';
    } else if (postDate == yesterday) {
      return '어제';
    } else {
      return '${date.year}년 ${date.month}월 ${date.day}일';
    }
  }

  Widget _buildDateHeader(BuildContext context, String dateLabel) {
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              dateLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  // --- Widgets for Comment View (ported from comments_screen.dart) ---

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

  Widget _buildSliverCommentsList(BuildContext context, List<CommentModel> comments, WorkspaceProvider provider) {
    return SliverPadding(
      padding: const EdgeInsets.all(UIConstants.defaultPadding),
      sliver: SliverList( 
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final comment = comments[index];
            return _buildCommentTile(context, comment, provider);
          },
          childCount: comments.length,
        ),
      ),
    );
  }

  Widget _buildEmptyCommentsState(BuildContext context) {
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('댓글 수정 기능은 준비 중입니다')),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
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
              final postId = provider.selectedPostForComments?.id;
              if (postId == null) return;
              try {
                await provider.deleteComment(comment.id, postId);
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
}
IconData _getChannelIcon(ChannelType type) {
  switch (type) {
    case ChannelType.text:
      return Icons.chat;
    case ChannelType.voice:
      return Icons.mic;
    case ChannelType.announcement:
      return Icons.campaign;
    case ChannelType.fileShare:
      return Icons.folder_shared;
  }
}

class PostGroup {
  final String date;
  final List<PostModel> posts;

  PostGroup({required this.date, required this.posts});
}
