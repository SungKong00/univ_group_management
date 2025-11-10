import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/navigation/permission_context.dart';
import 'package:frontend/core/navigation/workspace_route.dart';
import 'package:frontend/presentation/providers/navigation_state_provider.dart';
import 'package:frontend/presentation/providers/permission_context_provider.dart';

/// Listens for permission changes and handles navigation fallbacks
///
/// When user permissions are revoked while viewing a protected resource,
/// this listener displays a notification banner and redirects to group home
/// after 3 seconds (FR-008).
class PermissionChangeListener {
  final WidgetRef ref;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;

  PermissionChangeListener({
    required this.ref,
    required this.scaffoldMessengerKey,
  });

  /// Check if current route is accessible with current permissions
  bool _isCurrentRouteAccessible() {
    final navigationState = ref.read(navigationStateProvider);
    final currentRoute = navigationState.current;

    if (currentRoute == null) return true;

    return currentRoute.when(
      home: (_) => true, // Home is always accessible
      channel: (groupId, channelId) {
        // Channel access requires VIEW permission (simplified check)
        // In production, check channel-specific permissions
        return true; // Assume accessible for now
      },
      calendar: (_) => true, // Calendar is accessible to all members
      admin: (groupId) {
        final permissions = ref.read(permissionContextProvider);
        return permissions.canAccessAdmin();
      },
      memberManagement: (groupId) {
        final permissions = ref.read(permissionContextProvider);
        return permissions.hasPermission('MEMBER_MANAGE') ||
            permissions.isAdmin;
      },
    );
  }

  /// Display permission revocation banner and redirect after 3 seconds
  void _showPermissionRevokedBanner(int groupId) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;

    messenger.showSnackBar(
      SnackBar(
        content: const Text('권한이 변경되었습니다. 3초 후 그룹 홈으로 이동합니다.'),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.orange.shade700,
        action: SnackBarAction(
          label: '지금 이동',
          textColor: Colors.white,
          onPressed: () {
            _redirectToHome(groupId);
            messenger.hideCurrentSnackBar();
          },
        ),
      ),
    );

    // Auto-redirect after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      _redirectToHome(groupId);
    });
  }

  /// Redirect to group home
  void _redirectToHome(int groupId) {
    final notifier = ref.read(navigationStateProvider.notifier);
    notifier.push(WorkspaceRoute.home(groupId: groupId));
  }

  /// Start listening for permission changes
  ///
  /// Call this when entering workspace or when group changes
  void startListening() {
    // Listen to permission context changes
    ref.listen(permissionContextProvider, (
      PermissionContext? previous,
      PermissionContext next,
    ) {
      // Skip initial load
      if (previous == null || previous.isLoading || next.isLoading) {
        return;
      }

      // Skip if permissions haven't changed
      if (previous.permissions == next.permissions &&
          previous.isAdmin == next.isAdmin) {
        return;
      }

      // Check if current route is still accessible
      if (!_isCurrentRouteAccessible()) {
        _showPermissionRevokedBanner(next.groupId);
      }
    });
  }

  /// Manually check permission accessibility for current route
  ///
  /// Used for one-time checks during navigation
  Future<bool> checkAccessibility() async {
    return _isCurrentRouteAccessible();
  }
}

/// Provider for PermissionChangeListener
///
/// This is a convenience provider that creates a listener with
/// the correct scaffold messenger key.
final permissionChangeListenerProvider =
    Provider.autoDispose<PermissionChangeListener>((ref) {
      throw UnimplementedError(
        'permissionChangeListenerProvider must be overridden with a valid '
        'GlobalKey<ScaffoldMessengerState> in the widget tree',
      );
    });
