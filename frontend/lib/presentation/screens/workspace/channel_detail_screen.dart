import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../providers/workspace_provider.dart';
import '../../../data/models/workspace_models.dart';
import '../../widgets/loading_overlay.dart';
import 'widgets/comments_sidebar.dart';
import 'comments_screen.dart';

class ChannelDetailScreen extends StatelessWidget {
  final ChannelModel channel;

  const ChannelDetailScreen({
    super.key,
    required this.channel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
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
        ),
        actions: [
          // 개발/테스트용 권한 토글 버튼
          Consumer<WorkspaceProvider>(
            builder: (context, provider, child) {
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
            },
          ),
        ],
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

        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= ResponsiveBreakpoints.mobile;

            if (isDesktop) {
              return _buildDesktopLayout(context, provider, posts);
            } else {
              return _buildMobileLayout(context, provider, posts);
            }
          },
        );
      },
    );
  }

  Widget _buildDesktopLayout(BuildContext context, WorkspaceProvider provider, List<PostModel> posts) {
    final content = Row(
      children: [
        // 메인 콘텐츠 영역
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: posts.isEmpty
                    ? _buildEmptyState(context)
                    : _buildPostsList(context, posts, provider, isDesktop: true),
              ),
              _buildMessageComposer(context, provider),
            ],
          ),
        ),
        // 댓글 사이드바
        if (provider.isCommentsSidebarVisible)
          const CommentsSidebar(),
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

  Widget _buildMobileLayout(BuildContext context, WorkspaceProvider provider, List<PostModel> posts) {
    final content = Column(
      children: [
        Expanded(
          child: posts.isEmpty
              ? _buildEmptyState(context)
              : _buildPostsList(context, posts, provider, isDesktop: false),
        ),
        _buildMessageComposer(context, provider),
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
    WorkspaceProvider provider, {
    required bool isDesktop,
  }) {
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
                onTap: () => _handleCommentsAction(context, post, provider, isDesktop),
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

  Widget _buildMessageComposer(BuildContext context, WorkspaceProvider provider) {
    final canWrite = provider.canWriteInCurrentChannel;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: canWrite
            ? Theme.of(context).colorScheme.surface
            : Theme.of(context).colorScheme.surfaceVariant,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: canWrite
          ? _buildActiveComposer(context, provider)
          : _buildDisabledComposer(context),
    );
  }

  Widget _buildActiveComposer(BuildContext context, WorkspaceProvider provider) {
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
              hintText: '메시지를 입력하세요...',
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
            onSubmitted: (_) => _sendMessage(provider),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => _sendMessage(provider),
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
    // 권한 확인
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

  void _selectAttachment() {
    // 권한 확인
    final provider = context.read<WorkspaceProvider>();
    if (!provider.canWriteInCurrentChannel) {
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
    bool isDesktop,
  ) {
    if (isDesktop) {
      // 데스크톱: 사이드바 토글
      provider.toggleCommentsSidebar(post);
    } else {
      // 모바일: 댓글 페이지로 이동
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CommentsScreen(
            postId: post.id,
            postAuthor: post.author.name,
          ),
        ),
      );
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

  Widget _buildPostsList(BuildContext context, List<PostModel> posts, WorkspaceProvider provider, {required bool isDesktop}) {
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
            ...group.posts.map((post) => _buildMessageBubble(context, post, provider, isDesktop: isDesktop)),
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
