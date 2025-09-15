import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/workspace_provider.dart';
import '../../../../data/models/workspace_models.dart';
import '../channel_detail_screen.dart';

class ChannelsTab extends StatelessWidget {
  final WorkspaceDetailModel workspace;

  const ChannelsTab({
    super.key,
    required this.workspace,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkspaceProvider>(
      builder: (context, provider, child) {
        final channels = provider.channels;

        return CustomScrollView(
          slivers: [
            if (workspace.canManageChannels)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showCreateChannelDialog(context),
                          icon: const Icon(Icons.add),
                          label: const Text('채널 생성'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (channels.isEmpty)
              SliverFillRemaining(
                child: _buildEmptyState(context),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final channel = channels[index];
                    return _buildChannelTile(context, channel);
                  },
                  childCount: channels.length,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.tag_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            '아직 채널이 없습니다',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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

  Widget _buildChannelTile(BuildContext context, ChannelModel channel) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getChannelColor(channel.type),
          child: Icon(
            _getChannelIcon(channel.type),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                channel.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (channel.isPrivate)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '비공개',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.orange[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (channel.description != null) ...[
              const SizedBox(height: 4),
              Text(
                channel.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 4),
            Text(
              '${channel.typeDisplayName} • 생성자: ${channel.createdBy.name}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _navigateToChannel(context, channel),
        onLongPress: workspace.canManageChannels
            ? () => _showChannelOptions(context, channel)
            : null,
      ),
    );
  }

  Color _getChannelColor(ChannelType type) {
    switch (type) {
      case ChannelType.text:
        return Colors.blue;
      case ChannelType.voice:
        return Colors.green;
      case ChannelType.announcement:
        return Colors.red;
      case ChannelType.fileShare:
        return Colors.purple;
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

  void _navigateToChannel(BuildContext context, ChannelModel channel) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChannelDetailScreen(channel: channel),
      ),
    );
  }

  void _showChannelOptions(BuildContext context, ChannelModel channel) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${channel.name} 채널',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('채널 편집'),
              onTap: () {
                Navigator.pop(context);
                _showEditChannelDialog(context, channel);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                '채널 삭제',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteChannelDialog(context, channel);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showCreateChannelDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    ChannelType selectedType = ChannelType.text;
    bool isPrivate = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('새 채널 만들기'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '채널 이름',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 50,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: '채널 설명 (선택사항)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  maxLength: 200,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ChannelType>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: '채널 타입',
                    border: OutlineInputBorder(),
                  ),
                  items: ChannelType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          Icon(_getChannelIcon(type), size: 20),
                          const SizedBox(width: 8),
                          Text(_getChannelTypeDisplayName(type)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedType = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('비공개 채널'),
                  subtitle: const Text('특정 멤버만 접근 가능'),
                  value: isPrivate,
                  onChanged: (value) {
                    setState(() => isPrivate = value ?? false);
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('채널 이름을 입력해주세요')),
                  );
                  return;
                }

                Navigator.pop(context);

                await context.read<WorkspaceProvider>().createChannel(
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                  type: selectedType,
                  isPrivate: isPrivate,
                );
              },
              child: const Text('생성'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditChannelDialog(BuildContext context, ChannelModel channel) {
    final nameController = TextEditingController(text: channel.name);
    final descriptionController = TextEditingController(text: channel.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('채널 편집'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '채널 이름',
                  border: OutlineInputBorder(),
                ),
                maxLength: 50,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: '채널 설명',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                maxLength: 200,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('채널 이름을 입력해주세요')),
                );
                return;
              }

              Navigator.pop(context);

              // TODO: 채널 수정 기능 구현
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('채널 수정 기능 구현 예정')),
              );
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  void _showDeleteChannelDialog(BuildContext context, ChannelModel channel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('채널 삭제'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('정말로 "${channel.name}" 채널을 삭제하시겠습니까?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '채널과 모든 메시지가 영구적으로 삭제됩니다.',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              await context.read<WorkspaceProvider>().deleteChannel(channel.id);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${channel.name} 채널이 삭제되었습니다')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  String _getChannelTypeDisplayName(ChannelType type) {
    switch (type) {
      case ChannelType.text:
        return '텍스트 채널';
      case ChannelType.voice:
        return '음성 채널';
      case ChannelType.announcement:
        return '공지 채널';
      case ChannelType.fileShare:
        return '파일 공유';
    }
  }
}