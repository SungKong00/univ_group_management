import '../../core/models/group_models.dart';
import '../../core/utils/permission_utils.dart';
import 'workspace_state_provider.dart';

/// Workspace navigation decision helper
///
/// This class encapsulates the logic for determining which view to show
/// when navigating to a workspace or switching between groups.
class WorkspaceNavigationHelper {
  /// Determine target view when entering/switching to a workspace
  ///
  /// Priority:
  /// 1. Explicitly passed targetView (from LocalStorage restore)
  /// 2. Group switching logic (maintain view type when possible)
  /// 3. Fallback to snapshot or default (groupHome)
  static WorkspaceView determineTargetView({
    required bool isSameGroup,
    required WorkspaceView currentView,
    required WorkspaceView? targetView,
    required WorkspaceSnapshot? snapshot,
    required bool hasChannelId,
    required bool hasGroupAdminPermission,
  }) {
    // Priority 1: Explicitly passed targetView
    if (targetView != null) {
      // Verify groupAdmin permission if targeting groupAdmin view
      if (targetView == WorkspaceView.groupAdmin && !hasGroupAdminPermission) {
        return WorkspaceView.groupHome;
      }
      return targetView;
    }

    // Priority 2: Group switching logic
    if (!isSameGroup) {
      return _determineViewOnGroupSwitch(
        currentView: currentView,
        hasChannelId: hasChannelId,
        hasGroupAdminPermission: hasGroupAdminPermission,
      );
    }

    // Priority 3: Same group - use snapshot or default
    return snapshot?.view ?? WorkspaceView.groupHome;
  }

  /// Determine target view when switching between groups
  ///
  /// Rules (뷰 타입 유지):
  /// 1. groupHome → groupHome (그룹홈 유지)
  /// 2. calendar → calendar (캘린더 유지)
  /// 3. channel (any channel) → first channel (첫 번째 채널로)
  /// 4. groupAdmin → groupAdmin (권한 있으면) or groupHome (권한 없으면)
  /// 5. Other admin views → groupAdmin (권한 있으면) or groupHome (권한 없으면)
  static WorkspaceView _determineViewOnGroupSwitch({
    required WorkspaceView currentView,
    required bool hasChannelId,
    required bool hasGroupAdminPermission,
  }) {
    switch (currentView) {
      case WorkspaceView.groupHome:
        return WorkspaceView.groupHome;

      case WorkspaceView.calendar:
        return WorkspaceView.calendar;

      case WorkspaceView.channel:
        // Channel view: will select first channel in loadChannels
        return WorkspaceView.channel;

      case WorkspaceView.groupAdmin:
      case WorkspaceView.memberManagement:
      case WorkspaceView.channelManagement:
      case WorkspaceView.recruitmentManagement:
      case WorkspaceView.applicationManagement:
      case WorkspaceView.placeTimeManagement:
        // Admin views: check permission, fallback to groupHome
        return hasGroupAdminPermission
            ? WorkspaceView.groupAdmin
            : WorkspaceView.groupHome;
    }
  }

  /// Determine if channel should be auto-selected based on target view
  static bool shouldSelectChannel(WorkspaceView? targetView) {
    return targetView == null || targetView == WorkspaceView.channel;
  }

  /// Determine target mobile view when entering workspace
  ///
  /// Always returns channelList for group switching (mobile-first approach)
  static MobileWorkspaceView determineMobileView({
    required bool isSameGroup,
    required MobileWorkspaceView currentMobileView,
    required WorkspaceSnapshot? snapshot,
  }) {
    // On group switch, always go to channel list (mobile UX principle)
    if (!isSameGroup) {
      return MobileWorkspaceView.channelList;
    }

    // Same group: preserve current state or use snapshot
    final hasMobileState = currentMobileView != MobileWorkspaceView.channelList;
    if (hasMobileState) {
      return currentMobileView;
    }

    return snapshot?.mobileView ?? MobileWorkspaceView.channelList;
  }

  /// Check if user has group admin permission
  static bool hasGroupAdminPermission(GroupMembership? membership) {
    if (membership == null) return false;
    return PermissionUtils.hasAnyGroupManagementPermission(
      membership.permissions,
    );
  }

  /// Validate and fallback target view based on permission
  ///
  /// This is used in loadChannels to ensure the final view is authorized
  static WorkspaceView validateAndFallbackView({
    required WorkspaceView targetView,
    required bool hasGroupAdminPermission,
  }) {
    // Check if view requires admin permission
    const adminViews = {
      WorkspaceView.groupAdmin,
      WorkspaceView.memberManagement,
      WorkspaceView.channelManagement,
      WorkspaceView.recruitmentManagement,
      WorkspaceView.applicationManagement,
      WorkspaceView.placeTimeManagement,
    };

    if (adminViews.contains(targetView) && !hasGroupAdminPermission) {
      return WorkspaceView.groupHome;
    }

    return targetView;
  }

  /// Select first channel ID from channels list
  ///
  /// Returns null if no channels available or view doesn't require channel
  static String? selectFirstChannel({
    required List<dynamic> channels,
    required bool shouldSelectChannel,
  }) {
    if (!shouldSelectChannel || channels.isEmpty) {
      return null;
    }
    return channels.first.id.toString();
  }
}
