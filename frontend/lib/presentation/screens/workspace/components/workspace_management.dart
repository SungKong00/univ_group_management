import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/workspace_provider.dart';
import '../../../providers/channel_provider.dart';
import '../../../../data/models/workspace_models.dart';
import '../utils/workspace_helpers.dart';
import '../admin_home_screen.dart';
import '../member_management_screen.dart';
import '../channel_management_screen.dart';
import '../group_info_screen.dart';

class WorkspaceManagement {
  static void showMembersSheet(BuildContext context, WorkspaceDetailModel workspace) {
    if (!context.mounted) return;
    try {
      final provider = context.read<WorkspaceProvider>();
      final members = provider.members;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '멤버 ${members.length}명',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: members.isEmpty
                      ? const Center(child: Text('등록된 멤버가 없습니다'))
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: members.length,
                          itemBuilder: (context, index) {
                            final member = members[index];
                            final roleName = member.role.name;
                            return ListTile(
                              leading: CircleAvatar(
                                radius: 18,
                                child: Text(member.user.name.isNotEmpty
                                    ? member.user.name[0]
                                    : '?'),
                              ),
                              title: Text(member.user.name),
                              subtitle: Text(roleName),
                              trailing: Text(
                                WorkspaceHelpers.formatDate(member.joinedAt),
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('멤버 목록을 불러올 수 없습니다.')),
        );
      }
    }
  }

  static void showChannelInfo(BuildContext context, ChannelModel channel) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              channel.name,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text('유형: ${channel.typeDisplayName}',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Text('생성자: ${channel.createdBy.name}',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Text('생성일: ${WorkspaceHelpers.formatDateTime(channel.createdAt)}',
                style: Theme.of(context).textTheme.bodySmall),
            if (channel.description?.isNotEmpty ?? false) ...[
              const SizedBox(height: 16),
              Text(
                channel.description!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  static void showCreateAnnouncementDialog(BuildContext context) {
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('공지사항 작성'),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: contentController,
            decoration: const InputDecoration(
              labelText: '내용',
              border: OutlineInputBorder(),
            ),
            maxLines: 6,
            maxLength: 1000,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              final content = contentController.text.trim();
              if (content.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('내용을 입력해주세요')),
                );
                return;
              }

              Navigator.pop(context);
              final workspaceProvider = context.read<WorkspaceProvider>();
              final channelProvider = context.read<ChannelProvider>();
              final announcementChannel =
                  WorkspaceHelpers.findAnnouncementChannel(workspaceProvider.channels);

              if (announcementChannel == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('공지 채널을 찾을 수 없습니다')),
                );
                return;
              }

              await channelProvider.createPost(
                channelId: announcementChannel.id,
                content: content,
                type: PostType.announcement,
              );
            },
            child: const Text('작성'),
          ),
        ],
      ),
    );
  }

  static void showManagementMenu(
    BuildContext context,
    WorkspaceDetailModel workspace,
  ) {
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
              '그룹 관리',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            if (workspace.canManageMembers) ...[
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('멤버 관리'),
                subtitle: const Text('멤버 승인/반려, 역할 변경'),
                onTap: () {
                  Navigator.pop(context);
                  showMemberManagement(context);
                },
              ),
            ],
            if (workspace.canManageChannels) ...[
              ListTile(
                leading: const Icon(Icons.tag),
                title: const Text('채널 관리'),
                subtitle: const Text('채널 생성, 수정, 삭제'),
                onTap: () {
                  Navigator.pop(context);
                  showChannelManagement(context);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('그룹 정보'),
              subtitle: const Text('그룹 설정 및 정보 수정'),
              onTap: () {
                Navigator.pop(context);
                showGroupInfo(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  static void showAdminHome(BuildContext context, WorkspaceDetailModel workspace) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AdminHomeScreen(workspace: workspace),
      ),
    );
  }

  static void showMemberManagement(BuildContext context) {
    final workspace = context.read<WorkspaceProvider>().currentWorkspace;
    if (workspace != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MemberManagementScreen(workspace: workspace),
        ),
      );
    }
  }

  static void showChannelManagement(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ChannelManagementScreen(),
      ),
    );
  }

  static void showGroupInfo(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const GroupInfoScreen(),
      ),
    );
  }
}