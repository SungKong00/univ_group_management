import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/workspace_state_provider.dart';
import '../helpers/workspace_view_builder.dart';
import 'workspace_state_view.dart';
import 'workspace_empty_state.dart';
import 'channel_content_view.dart';

/// Desktop main content area
///
/// Handles loading, error, and content states for desktop workspace view
class DesktopMainContent extends ConsumerWidget {
  final VoidCallback? onRetryLoadWorkspace;
  final Future<void> Function(String content)? onSubmitPost;
  final int postReloadTick;

  const DesktopMainContent({
    super.key,
    this.onRetryLoadWorkspace,
    this.onSubmitPost,
    this.postReloadTick = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoadingWorkspace = ref.watch(workspaceIsLoadingProvider);
    final errorMessage = ref.watch(workspaceErrorMessageProvider);
    final isInWorkspace = ref.watch(isInWorkspaceProvider);
    final currentView = ref.watch(workspaceCurrentViewProvider);
    final hasSelectedChannel = ref.watch(workspaceHasSelectedChannelProvider);
    final channels = ref.watch(workspaceChannelsProvider);
    final selectedChannelId = ref.watch(currentChannelIdProvider);
    final channelPermissions = ref.watch(workspaceChannelPermissionsProvider);
    final isLoadingPermissions = ref.watch(
      workspaceIsLoadingPermissionsProvider,
    );

    // Show loading state
    if (isLoadingWorkspace) {
      return const WorkspaceStateView(type: WorkspaceStateType.loading);
    }

    // Show error state
    if (errorMessage != null) {
      return WorkspaceStateView(
        type: WorkspaceStateType.error,
        errorMessage: errorMessage,
        onRetry: onRetryLoadWorkspace,
      );
    }

    if (!isInWorkspace) {
      return const WorkspaceStateView(type: WorkspaceStateType.noGroup);
    }

    // Switch view based on currentView
    final specialView = WorkspaceViewBuilder.buildSpecialView(ref, currentView);
    if (specialView != null) {
      return specialView;
    }

    // Channel view
    if (!hasSelectedChannel) {
      return const WorkspaceEmptyState(
        type: WorkspaceEmptyType.noChannelSelected,
      );
    }

    return ChannelContentView(
      channels: channels,
      selectedChannelId: selectedChannelId!,
      channelPermissions: channelPermissions,
      isLoadingPermissions: isLoadingPermissions,
      onSubmitPost: onSubmitPost ?? (_) async {},
      postReloadTick: postReloadTick,
    );
  }
}
