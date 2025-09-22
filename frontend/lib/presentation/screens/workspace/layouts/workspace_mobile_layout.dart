import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/workspace_provider.dart';
import '../../../providers/channel_provider.dart';
import '../../../providers/ui_state_provider.dart';
import '../../../../data/models/workspace_models.dart';
import '../channel_detail_screen.dart';
import '../components/workspace_mobile_navigator.dart';
import '../components/workspace_mobile_drawer.dart';
import '../components/workspace_management.dart';

class WorkspaceMobileLayout extends StatelessWidget {
  final WorkspaceDetailModel workspace;

  const WorkspaceMobileLayout({
    super.key,
    required this.workspace,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer3<WorkspaceProvider, ChannelProvider, UIStateProvider>(
      builder: (context, workspaceProvider, channelProvider, uiStateProvider, child) {
        final channel = channelProvider.currentChannel;
        final showNavigator = uiStateProvider.isMobileNavigatorVisible;

        Widget body;
        if (showNavigator) {
          body = KeyedSubtree(
            key: const ValueKey('workspace-mobile-nav'),
            child: WorkspaceMobileNavigator(
              workspace: workspace,
              onShowAdminHome: () => WorkspaceManagement.showAdminHome(context, workspace),
              onShowMemberManagement: () => WorkspaceManagement.showMemberManagement(context),
              onShowChannelManagement: () => WorkspaceManagement.showChannelManagement(context),
              onShowGroupInfo: () => WorkspaceManagement.showGroupInfo(context),
            ),
          );
        } else if (channel != null) {
          body = KeyedSubtree(
            key: ValueKey('workspace-mobile-channel-${channel.id}'),
            child: ChannelDetailView(
              channel: channel,
              autoLoad: false,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              forceMobileLayout: true,
            ),
          );
        } else {
          // Fallback to navigator if no channel is selected
          body = KeyedSubtree(
            key: const ValueKey('workspace-mobile-nav-fallback'),
            child: WorkspaceMobileNavigator(
              workspace: workspace,
              onShowAdminHome: () => WorkspaceManagement.showAdminHome(context, workspace),
              onShowMemberManagement: () => WorkspaceManagement.showMemberManagement(context),
              onShowChannelManagement: () => WorkspaceManagement.showChannelManagement(context),
              onShowGroupInfo: () => WorkspaceManagement.showGroupInfo(context),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.background,
          drawer: WorkspaceMobileDrawer(
            workspace: workspace,
            onShowMemberManagement: () => WorkspaceManagement.showMemberManagement(context),
            onShowChannelManagement: () => WorkspaceManagement.showChannelManagement(context),
            onShowGroupInfo: () => WorkspaceManagement.showGroupInfo(context),
          ),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: body,
          ),
        );
      },
    );
  }
}