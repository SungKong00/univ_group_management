import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/workspace_provider.dart';
import '../../../providers/channel_provider.dart';
import '../../../providers/ui_state_provider.dart';
import '../../../../data/models/workspace_models.dart';
import '../channel_detail_screen.dart';
import '../widgets/workspace_sidebar.dart';
import '../components/workspace_management.dart';

class WorkspaceDesktopLayout extends StatelessWidget {
  final WorkspaceDetailModel workspace;

  const WorkspaceDesktopLayout({
    super.key,
    required this.workspace,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer3<WorkspaceProvider, ChannelProvider, UIStateProvider>(
      builder: (context, workspaceProvider, channelProvider, uiStateProvider, child) {
        const double workspaceSidebarWidth = 200;

        // 데스크톱 진입 시 채널 미선택 상태라면 첫 채널을 자동 선택하여 ChannelProvider와 동기화
        if (channelProvider.currentChannel == null &&
            workspaceProvider.channels.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            channelProvider.selectChannel(workspaceProvider.channels.first);
          });
        }

        final channel = channelProvider.currentChannel;

        return Row(
          children: [
            SizedBox(
              width: workspaceSidebarWidth,
              child: WorkspaceSidebar(
                workspace: workspace,
                width: workspaceSidebarWidth,
                onShowAdminHome: () => WorkspaceManagement.showAdminHome(context, workspace),
                onShowMemberManagement: () => WorkspaceManagement.showMemberManagement(context),
                onShowChannelManagement: () => WorkspaceManagement.showChannelManagement(context),
                onShowGroupInfo: () => WorkspaceManagement.showGroupInfo(context),
              ),
            ),
            Expanded(
              child: channel == null
                  ? const Center(child: Text('채널을 선택해주세요'))
                  : ChannelDetailView(
                      channel: channel,
                      autoLoad: false,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
            ),
          ],
        );
      },
    );
  }
}