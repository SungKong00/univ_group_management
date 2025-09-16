import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/workspace_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_button.dart';
import '../../widgets/loading_overlay.dart';
import '../../../data/models/workspace_models.dart';

class ChannelManagementScreen extends StatefulWidget {
  const ChannelManagementScreen({super.key});

  @override
  State<ChannelManagementScreen> createState() => _ChannelManagementScreenState();
}

class _ChannelManagementScreenState extends State<ChannelManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('채널 관리'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: Consumer<WorkspaceProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const LoadingOverlay(
              isLoading: true,
              child: SizedBox.shrink(),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '채널 정보를 불러올 수 없습니다',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.error!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  CommonButton(
                    onPressed: () => provider.clearError(),
                    text: '다시 시도',
                    type: ButtonType.text,
                  ),
                ],
              ),
            );
          }

          final channels = provider.channels;
          final canManageChannels = provider.canManageChannels;

          return Column(
            children: [
              // 헤더 섹션
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.tag,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '채널 ${channels.length}개',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (canManageChannels) ...[
                          CommonButton(
                            onPressed: () => _showCreateChannelDialog(context, provider),
                            text: '채널 생성',
                            type: ButtonType.primary,
                            icon: Icons.add,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      canManageChannels
                          ? '채널을 생성하거나 기존 채널을 관리할 수 있습니다.'
                          : '현재 워크스페이스의 채널 목록입니다.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // 채널 목록
              Expanded(
                child: channels.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: channels.length,
                      itemBuilder: (context, index) {
                        final channel = channels[index];
                        return _buildChannelItem(context, provider, channel, canManageChannels);
                      },
                    ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.tag,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '아직 생성된 채널이 없습니다',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '첫 번째 채널을 생성해보세요',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelItem(
    BuildContext context,
    WorkspaceProvider provider,
    ChannelModel channel,
    bool canManage,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getChannelTypeColor(context, channel.type),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getChannelTypeIcon(channel.type),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                channel.name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (channel.isPrivate) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '비공개',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    channel.typeDisplayName,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontSize: 10,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '순서: ${channel.displayOrder}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            if (channel.description?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(
                channel.description!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 4),
            Text(
              '생성: ${channel.createdBy.name} • ${_formatDate(channel.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
        trailing: canManage ? PopupMenuButton<String>(
          onSelected: (action) {
            switch (action) {
              case 'edit':
                _showEditChannelDialog(context, provider, channel);
                break;
              case 'delete':
                _showDeleteChannelDialog(context, provider, channel);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit, size: 20),
                title: Text('수정'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, size: 20),
                title: Text('삭제'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ) : null,
      ),
    );
  }

  Color _getChannelTypeColor(BuildContext context, ChannelType type) {
    switch (type) {
      case ChannelType.text:
        return Theme.of(context).colorScheme.primary;
      case ChannelType.voice:
        return Colors.green;
      case ChannelType.announcement:
        return Colors.orange;
      case ChannelType.fileShare:
        return Colors.purple;
    }
  }

  IconData _getChannelTypeIcon(ChannelType type) {
    switch (type) {
      case ChannelType.text:
        return Icons.tag;
      case ChannelType.voice:
        return Icons.volume_up;
      case ChannelType.announcement:
        return Icons.campaign;
      case ChannelType.fileShare:
        return Icons.folder;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  void _showCreateChannelDialog(BuildContext context, WorkspaceProvider provider) {
    showDialog(
      context: context,
      builder: (context) => _ChannelCreateDialog(
        onConfirm: (name, description, type, isPrivate) async {
          final success = await provider.createChannel(
            name: name,
            description: description,
            type: type,
            isPrivate: isPrivate,
          );

          if (success && context.mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('채널이 생성되었습니다')),
            );
          } else if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('채널 생성에 실패했습니다: ${provider.error}'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
      ),
    );
  }

  void _showEditChannelDialog(BuildContext context, WorkspaceProvider provider, ChannelModel channel) {
    showDialog(
      context: context,
      builder: (context) => _ChannelEditDialog(
        channel: channel,
        onConfirm: (name, description, type, isPrivate) async {
          // Note: 현재 workspace_provider에는 updateChannel 메서드가 없어서
          // 여기서는 UI만 구현하고 추후 API 구현시 연결 예정
          if (context.mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('채널 수정 기능은 추후 구현 예정입니다')),
            );
          }
        },
      ),
    );
  }

  void _showDeleteChannelDialog(BuildContext context, WorkspaceProvider provider, ChannelModel channel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('채널 삭제'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('정말로 "${channel.name}" 채널을 삭제하시겠습니까?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning,
                        size: 16,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '주의사항',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• 채널의 모든 게시글과 댓글이 함께 삭제됩니다\n• 이 작업은 되돌릴 수 없습니다',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();

              final success = await provider.deleteChannel(channel.id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('채널이 삭제되었습니다')),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('채널 삭제에 실패했습니다: ${provider.error}'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}

class _ChannelCreateDialog extends StatefulWidget {
  final Function(String name, String? description, ChannelType type, bool isPrivate) onConfirm;

  const _ChannelCreateDialog({required this.onConfirm});

  @override
  State<_ChannelCreateDialog> createState() => _ChannelCreateDialogState();
}

class _ChannelCreateDialogState extends State<_ChannelCreateDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  ChannelType _selectedType = ChannelType.text;
  bool _isPrivate = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('새 채널 생성'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '채널 이름',
                hintText: '채널 이름을 입력하세요',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value?.trim().isEmpty == true) {
                  return '채널 이름은 필수입니다';
                }
                if (value!.length > 50) {
                  return '채널 이름은 50자를 초과할 수 없습니다';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '채널 설명 (선택)',
                hintText: '채널에 대한 간단한 설명을 입력하세요',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value != null && value.length > 200) {
                  return '채널 설명은 200자를 초과할 수 없습니다';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ChannelType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: '채널 타입',
                border: OutlineInputBorder(),
              ),
              items: ChannelType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(
                        _getChannelTypeIcon(type),
                        size: 20,
                        color: _getChannelTypeColor(context, type),
                      ),
                      const SizedBox(width: 8),
                      Text(_getChannelTypeDisplayName(type)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _isPrivate,
              onChanged: (value) {
                setState(() {
                  _isPrivate = value ?? false;
                });
              },
              title: const Text('비공개 채널'),
              subtitle: const Text('초대받은 멤버만 접근할 수 있습니다'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onConfirm(
                _nameController.text.trim(),
                _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
                _selectedType,
                _isPrivate,
              );
            }
          },
          child: const Text('생성'),
        ),
      ],
    );
  }

  Color _getChannelTypeColor(BuildContext context, ChannelType type) {
    switch (type) {
      case ChannelType.text:
        return Theme.of(context).colorScheme.primary;
      case ChannelType.voice:
        return Colors.green;
      case ChannelType.announcement:
        return Colors.orange;
      case ChannelType.fileShare:
        return Colors.purple;
    }
  }

  IconData _getChannelTypeIcon(ChannelType type) {
    switch (type) {
      case ChannelType.text:
        return Icons.tag;
      case ChannelType.voice:
        return Icons.volume_up;
      case ChannelType.announcement:
        return Icons.campaign;
      case ChannelType.fileShare:
        return Icons.folder;
    }
  }

  String _getChannelTypeDisplayName(ChannelType type) {
    switch (type) {
      case ChannelType.text:
        return '텍스트';
      case ChannelType.voice:
        return '음성';
      case ChannelType.announcement:
        return '공지';
      case ChannelType.fileShare:
        return '파일공유';
    }
  }
}

class _ChannelEditDialog extends StatefulWidget {
  final ChannelModel channel;
  final Function(String name, String? description, ChannelType type, bool isPrivate) onConfirm;

  const _ChannelEditDialog({
    required this.channel,
    required this.onConfirm,
  });

  @override
  State<_ChannelEditDialog> createState() => _ChannelEditDialogState();
}

class _ChannelEditDialogState extends State<_ChannelEditDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late ChannelType _selectedType;
  late bool _isPrivate;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.channel.name);
    _descriptionController = TextEditingController(text: widget.channel.description ?? '');
    _selectedType = widget.channel.type;
    _isPrivate = widget.channel.isPrivate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('채널 수정'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '채널 이름',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value?.trim().isEmpty == true) {
                  return '채널 이름은 필수입니다';
                }
                if (value!.length > 50) {
                  return '채널 이름은 50자를 초과할 수 없습니다';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '채널 설명 (선택)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value != null && value.length > 200) {
                  return '채널 설명은 200자를 초과할 수 없습니다';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ChannelType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: '채널 타입',
                border: OutlineInputBorder(),
              ),
              items: ChannelType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(
                        _getChannelTypeIcon(type),
                        size: 20,
                        color: _getChannelTypeColor(context, type),
                      ),
                      const SizedBox(width: 8),
                      Text(_getChannelTypeDisplayName(type)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _isPrivate,
              onChanged: (value) {
                setState(() {
                  _isPrivate = value ?? false;
                });
              },
              title: const Text('비공개 채널'),
              subtitle: const Text('초대받은 멤버만 접근할 수 있습니다'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onConfirm(
                _nameController.text.trim(),
                _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
                _selectedType,
                _isPrivate,
              );
            }
          },
          child: const Text('수정'),
        ),
      ],
    );
  }

  Color _getChannelTypeColor(BuildContext context, ChannelType type) {
    switch (type) {
      case ChannelType.text:
        return Theme.of(context).colorScheme.primary;
      case ChannelType.voice:
        return Colors.green;
      case ChannelType.announcement:
        return Colors.orange;
      case ChannelType.fileShare:
        return Colors.purple;
    }
  }

  IconData _getChannelTypeIcon(ChannelType type) {
    switch (type) {
      case ChannelType.text:
        return Icons.tag;
      case ChannelType.voice:
        return Icons.volume_up;
      case ChannelType.announcement:
        return Icons.campaign;
      case ChannelType.fileShare:
        return Icons.folder;
    }
  }

  String _getChannelTypeDisplayName(ChannelType type) {
    switch (type) {
      case ChannelType.text:
        return '텍스트';
      case ChannelType.voice:
        return '음성';
      case ChannelType.announcement:
        return '공지';
      case ChannelType.fileShare:
        return '파일공유';
    }
  }
}