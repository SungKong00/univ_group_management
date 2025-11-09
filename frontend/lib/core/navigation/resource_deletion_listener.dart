import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/navigation/workspace_route.dart';
import 'package:frontend/presentation/providers/navigation_state_provider.dart';

/// Listens for resource deletion events and handles navigation fallbacks
///
/// When a resource (channel, group) is deleted while user is viewing it,
/// this listener displays a notification banner and redirects to parent
/// group home after 3 seconds (FR-011).
class ResourceDeletionListener {
  final WidgetRef ref;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;

  ResourceDeletionListener({
    required this.ref,
    required this.scaffoldMessengerKey,
  });

  /// Handle channel deletion
  ///
  /// Displays banner: "채널이 삭제되었습니다. 3초 후 그룹 홈으로 이동합니다."
  void onChannelDeleted({
    required int groupId,
    required int channelId,
    String? channelName,
  }) {
    final navigationState = ref.read(navigationStateProvider);
    final currentRoute = navigationState.current;

    // Check if user is viewing the deleted channel
    bool isViewingDeletedChannel = false;
    if (currentRoute != null) {
      currentRoute.when(
        channel: (cGroupId, cChannelId) {
          if (cGroupId == groupId && cChannelId == channelId) {
            isViewingDeletedChannel = true;
          }
        },
        home: (_) {},
        calendar: (_) {},
        admin: (_) {},
        memberManagement: (_) {},
      );
    }

    if (!isViewingDeletedChannel) return;

    _showDeletionBanner(
      message: channelName != null
          ? '"$channelName" 채널이 삭제되었습니다. 3초 후 그룹 홈으로 이동합니다.'
          : '채널이 삭제되었습니다. 3초 후 그룹 홈으로 이동합니다.',
      targetGroupId: groupId,
    );
  }

  /// Handle group deletion
  ///
  /// Displays banner: "그룹이 삭제되었습니다. 3초 후 워크스페이스를 종료합니다."
  void onGroupDeleted({required int groupId, String? groupName}) {
    final navigationState = ref.read(navigationStateProvider);
    final currentRoute = navigationState.current;

    // Check if user is in the deleted group
    bool isInDeletedGroup = false;
    if (currentRoute != null) {
      final routeGroupId = currentRoute.when(
        home: (gId) => gId,
        channel: (gId, _) => gId,
        calendar: (gId) => gId,
        admin: (gId) => gId,
        memberManagement: (gId) => gId,
      );

      if (routeGroupId == groupId) {
        isInDeletedGroup = true;
      }
    }

    if (!isInDeletedGroup) return;

    _showDeletionBanner(
      message: groupName != null
          ? '"$groupName" 그룹이 삭제되었습니다. 3초 후 워크스페이스를 종료합니다.'
          : '그룹이 삭제되었습니다. 3초 후 워크스페이스를 종료합니다.',
      targetGroupId: null, // Exit workspace
    );
  }

  /// Display deletion notification banner
  void _showDeletionBanner({required String message, int? targetGroupId}) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red.shade700,
        action: SnackBarAction(
          label: '확인',
          textColor: Colors.white,
          onPressed: () {
            if (targetGroupId != null) {
              _redirectToHome(targetGroupId);
            } else {
              _exitWorkspace();
            }
            messenger.hideCurrentSnackBar();
          },
        ),
      ),
    );

    // Auto-redirect after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (targetGroupId != null) {
        _redirectToHome(targetGroupId);
      } else {
        _exitWorkspace();
      }
    });
  }

  /// Redirect to group home
  void _redirectToHome(int groupId) {
    final notifier = ref.read(navigationStateProvider.notifier);
    notifier.push(WorkspaceRoute.home(groupId: groupId));
  }

  /// Exit workspace (pop all navigation)
  void _exitWorkspace() {
    final notifier = ref.read(navigationStateProvider.notifier);
    notifier.clear();
    // In production, navigate to global home page
  }

  /// Manually check if a resource exists
  ///
  /// Used for one-time checks during navigation
  /// In production, integrate with API to verify resource existence
  Future<bool> checkResourceExists({
    required int groupId,
    int? channelId,
  }) async {
    // Placeholder: In production, call API to verify resource exists
    // Example: GET /api/groups/:groupId/channels/:channelId
    return true;
  }
}

/// Provider for ResourceDeletionListener
///
/// This is a convenience provider that creates a listener with
/// the correct scaffold messenger key.
final resourceDeletionListenerProvider =
    Provider.autoDispose<ResourceDeletionListener>((ref) {
      throw UnimplementedError(
        'resourceDeletionListenerProvider must be overridden with a valid '
        'GlobalKey<ScaffoldMessengerState> in the widget tree',
      );
    });
