import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../data/models/workspace_models.dart';
import '../../../providers/workspace_provider.dart';
import '../../../providers/channel_provider.dart';
import '../../../providers/ui_state_provider.dart';
import 'composer_permission_dialog.dart';

class MessageComposer extends StatefulWidget {
  final ChannelModel channel;
  final WorkspaceProvider workspaceProvider;
  final ChannelProvider channelProvider;
  final UIStateProvider uiStateProvider;
  final ScrollController scrollController;
  final bool isCommentComposer;

  const MessageComposer({
    super.key,
    required this.channel,
    required this.workspaceProvider,
    required this.channelProvider,
    required this.uiStateProvider,
    required this.scrollController,
    this.isCommentComposer = false,
  });

  @override
  State<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<MessageComposer> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  bool _pendingEnterSend = false;

  @override
  void dispose() {
    _messageController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canWrite = widget.channelProvider.canWriteInCurrentChannel;
    final isEnabled = widget.isCommentComposer || canWrite;

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
            ? _buildActiveComposer(context)
            : _buildDisabledComposer(context),
      ),
    );
  }

  Widget _buildActiveComposer(BuildContext context) {
    return Row(
      children: [
        IconButton(
          key: Key(
              'attach_file_button_${widget.isCommentComposer ? 'comment' : 'post'}'),
          onPressed: _selectAttachment,
          icon: const Icon(Icons.attach_file),
          tooltip: '',
        ),
        const SizedBox(width: 8),
        Expanded(
          child: KeyboardListener(
            focusNode: FocusNode(),
            onKeyEvent: (KeyEvent event) {
              if (event is KeyDownEvent) {
                if (event.logicalKey == LogicalKeyboardKey.enter &&
                    event.physicalKey == PhysicalKeyboardKey.enter &&
                    HardwareKeyboard.instance.isShiftPressed) {
                  return;
                } else if (event.logicalKey == LogicalKeyboardKey.enter &&
                           event.physicalKey == PhysicalKeyboardKey.enter &&
                           !HardwareKeyboard.instance.isShiftPressed) {
                  _pendingEnterSend = true;
                  widget.isCommentComposer
                      ? _sendComment()
                      : _sendMessage();
                  return;
                }
              }
            },
            child: TextField(
              controller: _messageController,
              focusNode: _messageFocusNode,
              onChanged: _handleComposerChanged,
              decoration: InputDecoration(
                hintText: widget.isCommentComposer
                    ? '댓글을 입력하세요... (Shift+Enter로 줄바꿈)'
                    : '메시지를 입력하세요... (Shift+Enter로 줄바꿈)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          key: Key('send_button_${widget.isCommentComposer ? 'comment' : 'post'}'),
          onPressed: () => widget.isCommentComposer
              ? _sendComment()
              : _sendMessage(),
          icon: const Icon(Icons.send),
          tooltip: '',
        ),
      ],
    );
  }

  Widget _buildDisabledComposer(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ComposerPermissionDialog.show(context);
      },
      child: Row(
        children: [
          Icon(
            Icons.lock_outline,
            color:
                Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceVariant
                    .withOpacity(0.5),
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
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withOpacity(0.7),
                          ),
                    ),
                  ),
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.7),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            key: const Key('send_button_disabled'),
            onPressed: null,
            icon: Icon(
              Icons.send,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withOpacity(0.4),
            ),
            tooltip: '',
          ),
        ],
      ),
    );
  }

  void _handleComposerChanged(String value) {
    if (_pendingEnterSend) {
      _messageController.clear();
      _pendingEnterSend = false;
    }
  }

  void _sendMessage() async {
    if (!widget.channelProvider.canWriteInCurrentChannel) {
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
      await widget.channelProvider.createPost(
        channelId: widget.channel.id,
        content: message,
        type: PostType.general,
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.scrollController.hasClients) {
          widget.scrollController.animateTo(
            widget.scrollController.position.maxScrollExtent,
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

  void _sendComment() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final postId = widget.uiStateProvider.selectedPostForComments?.id;
    if (postId == null) return;

    _messageController.clear();

    try {
      await widget.channelProvider.createComment(
        postId: postId,
        content: content,
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.scrollController.hasClients) {
          widget.scrollController.animateTo(
            widget.scrollController.position.maxScrollExtent,
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
    final isCommentComposer = widget.uiStateProvider.selectedPostForComments != null;
    if (!isCommentComposer && !widget.channelProvider.canWriteInCurrentChannel) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이 채널에서 파일을 첨부할 권한이 없습니다')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('파일 첨부 기능 구현 예정')),
    );
  }
}