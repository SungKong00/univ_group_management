import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/navigation/view_context.dart';
import 'package:frontend/core/navigation/workspace_route.dart';
import 'package:frontend/core/navigation/permission_context.dart';
import 'package:frontend/core/services/channel_service.dart';

/// Service to resolve target routes based on ViewContext during group switching
///
/// This service implements the context-aware group switching logic:
/// - Maintains view type when switching groups (e.g., channel → channel)
/// - Handles permission-based fallbacks (e.g., admin → home if no permission)
/// - Selects appropriate channels based on creation date and permissions
class ViewContextResolver {
  final Ref ref;
  final ChannelService _channelService;

  ViewContextResolver(this.ref) : _channelService = ChannelService();

  /// Resolve the target route for a new group based on the current ViewContext
  ///
  /// Logic:
  /// - home → home (in target group)
  /// - channel → first accessible channel (by creation date) or home
  /// - calendar → calendar (in target group)
  /// - admin → admin (if permitted) or home
  /// - memberManagement → memberManagement (if permitted) or home
  Future<WorkspaceRoute> resolveTargetRoute(
    ViewContext context,
    int targetGroupId,
    PermissionContext permissions,
  ) async {
    switch (context.type) {
      case ViewType.home:
        return _resolveHomeRoute(targetGroupId);

      case ViewType.channel:
        final channelRoute = await _resolveChannelRoute(
          targetGroupId,
          permissions,
        );
        return channelRoute ?? _resolveHomeRoute(targetGroupId);

      case ViewType.calendar:
        return _resolveCalendarRoute(targetGroupId);

      case ViewType.admin:
        final adminRoute = await _resolveAdminRoute(targetGroupId, permissions);
        return adminRoute ?? _resolveHomeRoute(targetGroupId);

      case ViewType.memberManagement:
        final memberRoute = await _resolveMemberManagementRoute(
          targetGroupId,
          permissions,
        );
        return memberRoute ?? _resolveHomeRoute(targetGroupId);
    }
  }

  /// Resolve home route (always accessible)
  WorkspaceRoute _resolveHomeRoute(int groupId) {
    return WorkspaceRoute.home(groupId: groupId);
  }

  /// Resolve channel route: Find first accessible channel by creation date
  ///
  /// Returns null if no accessible channels exist (caller should fallback to home)
  Future<WorkspaceRoute?> _resolveChannelRoute(
    int groupId,
    PermissionContext permissions,
  ) async {
    try {
      // Fetch accessible channels for the group
      // getChannels() already filters by VIEW/POST_READ permission
      final channels = await _channelService.getChannels(groupId);

      if (channels.isEmpty) {
        return null; // No accessible channels, fallback to home
      }

      // Sort channels by creation date (earliest first)
      // Use id as fallback if createdAt is null (lower id = created earlier)
      final sortedChannels = List.from(channels)
        ..sort((a, b) {
          if (a.createdAt != null && b.createdAt != null) {
            return a.createdAt!.compareTo(b.createdAt!);
          }
          if (a.createdAt != null) return -1; // a has createdAt, b doesn't
          if (b.createdAt != null) return 1; // b has createdAt, a doesn't
          return a.id.compareTo(b.id); // Both null, use id
        });

      // Return the first (oldest) channel
      final firstChannel = sortedChannels.first;
      return WorkspaceRoute.channel(
        groupId: groupId,
        channelId: firstChannel.id,
      );
    } catch (e) {
      // On error, return null to trigger fallback to home
      return null;
    }
  }

  /// Resolve calendar route (always accessible to group members)
  WorkspaceRoute _resolveCalendarRoute(int groupId) {
    return WorkspaceRoute.calendar(groupId: groupId);
  }

  /// Resolve admin route with permission check
  ///
  /// Returns null if user lacks admin permissions (caller should fallback to home)
  Future<WorkspaceRoute?> _resolveAdminRoute(
    int groupId,
    PermissionContext permissions,
  ) async {
    if (permissions.canAccessAdmin()) {
      return WorkspaceRoute.admin(groupId: groupId);
    }
    return null; // Fallback to home
  }

  /// Resolve member management route with permission check
  ///
  /// Returns null if user lacks permissions (caller should fallback to home)
  Future<WorkspaceRoute?> _resolveMemberManagementRoute(
    int groupId,
    PermissionContext permissions,
  ) async {
    // Check if user has member management permission
    if (permissions.hasPermission('MEMBER_MANAGE') || permissions.isAdmin) {
      return WorkspaceRoute.memberManagement(groupId: groupId);
    }
    return null; // Fallback to home
  }
}

/// Provider for ViewContextResolver
final viewContextResolverProvider = Provider<ViewContextResolver>((ref) {
  return ViewContextResolver(ref);
});
