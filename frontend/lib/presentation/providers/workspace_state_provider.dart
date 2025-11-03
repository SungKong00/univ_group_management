import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../../core/models/channel_models.dart';
import '../../core/models/group_models.dart';
import '../../core/services/channel_service.dart';
import '../../core/services/local_storage.dart';
import '../../core/utils/permission_utils.dart';
import 'my_groups_provider.dart';
import 'place_calendar_provider.dart';
import 'auth_provider.dart';
import 'workspace_navigation_helper.dart';

/// Workspace View Type
enum WorkspaceView {
  channel, // Channel content view
  groupHome, // Group home view
  calendar, // Calendar view
  groupAdmin, // Group admin/management page view
  memberManagement, // Member management page view
  channelManagement, // Channel management page view
  recruitmentManagement, // Recruitment management page view
  applicationManagement, // Application management page view (모집 지원자 관리)
  placeTimeManagement, // Place time management page view (장소 시간 관리)
}

/// Navigation History Entry
/// 모든 네비게이션 이동(채널, 뷰, 그룹 전환)을 기록하기 위한 히스토리 엔트리
class NavigationHistoryEntry {
  const NavigationHistoryEntry({
    required this.groupId,
    required this.view,
    required this.mobileView,
    this.channelId,
    this.postId,
    this.isCommentsVisible = false,
    required this.timestamp,
  });

  final String groupId;
  final WorkspaceView view;
  final MobileWorkspaceView mobileView;
  final String? channelId;
  final String? postId;
  final bool isCommentsVisible;
  final DateTime timestamp;
}

/// Mobile Workspace View Type (3-step navigation flow)
enum MobileWorkspaceView {
  channelList, // Step 1: Channel list view
  channelPosts, // Step 2: Posts in selected channel
  postComments, // Step 3: Comments for selected post
}

class WorkspaceState extends Equatable {
  const WorkspaceState({
    this.selectedGroupId,
    this.selectedChannelId,
    this.isCommentsVisible = false,
    this.selectedPostId,
    this.workspaceContext = const {},
    this.channels = const [],
    this.unreadCounts = const {},
    this.currentView = WorkspaceView.groupHome,
    this.mobileView = MobileWorkspaceView.channelList,
    this.hasAnyGroupPermission = false,
    this.currentGroupRole,
    this.currentGroupPermissions,
    this.isLoadingChannels = false,
    this.isLoadingWorkspace = false,
    this.errorMessage,
    this.channelPermissions,
    this.isLoadingPermissions = false,
    this.isNarrowDesktopCommentsFullscreen =
        false, // Narrow desktop: comments fullscreen mode
    this.previousView, // Track previous view for back navigation
    this.selectedPlaceId, // Selected place ID for place time management
    this.selectedPlaceName, // Selected place name for place time management
    this.navigationHistory = const [], // Unified navigation history
    this.selectedCalendarDate, // Selected date for calendar view
    this.lastReadPostIdMap = const {}, // Read position management
    this.unreadCountMap = const {}, // Unread count management
    this.currentVisiblePostId, // Currently visible post ID
  });

  final String? selectedGroupId;
  final String? selectedChannelId;
  final bool isCommentsVisible;
  final String? selectedPostId;
  final Map<String, dynamic> workspaceContext;
  final List<Channel> channels;
  final Map<String, int> unreadCounts; // Dummy data for now
  final WorkspaceView currentView;
  final MobileWorkspaceView mobileView;
  final bool hasAnyGroupPermission;
  final String?
  currentGroupRole; // User's role in current group (e.g., "OWNER", "ADVISOR", "Custom Role")
  final List<String>?
  currentGroupPermissions; // User's permissions in current group
  final bool isLoadingChannels;
  final bool isLoadingWorkspace;
  final String? errorMessage;
  final ChannelPermissions? channelPermissions;
  final bool isLoadingPermissions;
  final bool
  isNarrowDesktopCommentsFullscreen; // Narrow desktop: when true, hide posts and show only comments
  final WorkspaceView?
  previousView; // Previous view for back navigation from special views (groupAdmin, memberManagement, etc.)
  final int? selectedPlaceId; // Selected place ID for place time management
  final String? selectedPlaceName; // Selected place name for place time management
  final List<NavigationHistoryEntry>
  navigationHistory; // Unified navigation history (channels, views, groups)
  final DateTime? selectedCalendarDate; // Selected date for calendar view
  final Map<int, int> lastReadPostIdMap; // {channelId: lastReadPostId}
  final Map<int, int> unreadCountMap; // {channelId: unreadCount}
  final int? currentVisiblePostId; // Currently visible post ID for tracking read position

  WorkspaceState copyWith({
    String? selectedGroupId,
    String? selectedChannelId,
    bool? isCommentsVisible,
    String? selectedPostId,
    Map<String, dynamic>? workspaceContext,
    List<Channel>? channels,
    Map<String, int>? unreadCounts,
    WorkspaceView? currentView,
    MobileWorkspaceView? mobileView,
    bool? hasAnyGroupPermission,
    String? currentGroupRole,
    List<String>? currentGroupPermissions,
    bool? isLoadingChannels,
    bool? isLoadingWorkspace,
    String? errorMessage,
    ChannelPermissions? channelPermissions,
    bool? isLoadingPermissions,
    bool? isNarrowDesktopCommentsFullscreen,
    WorkspaceView? previousView,
    int? selectedPlaceId,
    String? selectedPlaceName,
    List<NavigationHistoryEntry>? navigationHistory,
    DateTime? selectedCalendarDate,
    Map<int, int>? lastReadPostIdMap,
    Map<int, int>? unreadCountMap,
    int? currentVisiblePostId,
    bool clearCurrentVisiblePostId = false,
  }) {
    return WorkspaceState(
      selectedGroupId: selectedGroupId ?? this.selectedGroupId,
      selectedChannelId: selectedChannelId ?? this.selectedChannelId,
      isCommentsVisible: isCommentsVisible ?? this.isCommentsVisible,
      selectedPostId: selectedPostId ?? this.selectedPostId,
      workspaceContext: workspaceContext ?? this.workspaceContext,
      channels: channels ?? this.channels,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      currentView: currentView ?? this.currentView,
      mobileView: mobileView ?? this.mobileView,
      hasAnyGroupPermission:
          hasAnyGroupPermission ?? this.hasAnyGroupPermission,
      currentGroupRole: currentGroupRole ?? this.currentGroupRole,
      currentGroupPermissions:
          currentGroupPermissions ?? this.currentGroupPermissions,
      isLoadingChannels: isLoadingChannels ?? this.isLoadingChannels,
      isLoadingWorkspace: isLoadingWorkspace ?? this.isLoadingWorkspace,
      errorMessage: errorMessage,
      channelPermissions: channelPermissions ?? this.channelPermissions,
      isLoadingPermissions: isLoadingPermissions ?? this.isLoadingPermissions,
      isNarrowDesktopCommentsFullscreen:
          isNarrowDesktopCommentsFullscreen ??
          this.isNarrowDesktopCommentsFullscreen,
      previousView: previousView ?? this.previousView,
      selectedPlaceId: selectedPlaceId ?? this.selectedPlaceId,
      selectedPlaceName: selectedPlaceName ?? this.selectedPlaceName,
      navigationHistory: navigationHistory ?? this.navigationHistory,
      selectedCalendarDate: selectedCalendarDate ?? this.selectedCalendarDate,
      lastReadPostIdMap: lastReadPostIdMap ?? this.lastReadPostIdMap,
      unreadCountMap: unreadCountMap ?? this.unreadCountMap,
      currentVisiblePostId: clearCurrentVisiblePostId
          ? null
          : (currentVisiblePostId ?? this.currentVisiblePostId),
    );
  }

  bool get isInWorkspace => selectedGroupId != null;
  bool get hasSelectedChannel => selectedChannelId != null;
  bool get isViewingComments => isCommentsVisible && selectedPostId != null;

  @override
  List<Object?> get props => [
    selectedGroupId,
    selectedChannelId,
    isCommentsVisible,
    selectedPostId,
    workspaceContext,
    channels,
    unreadCounts,
    currentView,
    mobileView,
    hasAnyGroupPermission,
    currentGroupRole,
    currentGroupPermissions,
    isLoadingChannels,
    isLoadingWorkspace,
    errorMessage,
    channelPermissions,
    isLoadingPermissions,
    isNarrowDesktopCommentsFullscreen,
    previousView,
    selectedPlaceId,
    selectedPlaceName,
    navigationHistory,
    selectedCalendarDate,
    lastReadPostIdMap,
    unreadCountMap,
    currentVisiblePostId,
  ];
}

class WorkspaceSnapshot {
  const WorkspaceSnapshot({
    required this.view,
    required this.mobileView,
    this.selectedChannelId,
    this.selectedPostId,
    this.isCommentsVisible = false,
    this.isNarrowDesktopCommentsFullscreen = false,
    this.previousView,
  });

  final WorkspaceView view;
  final MobileWorkspaceView mobileView;
  final String? selectedChannelId;
  final String? selectedPostId;
  final bool isCommentsVisible;
  final bool isNarrowDesktopCommentsFullscreen;
  final WorkspaceView? previousView;
}

/// Internal class to hold navigation target information
class _NavigationTarget {
  const _NavigationTarget({
    required this.finalView,
    required this.finalMobileView,
    this.autoSelectChannelId,
  });

  final WorkspaceView finalView;
  final MobileWorkspaceView finalMobileView;
  final String? autoSelectChannelId;
}

/// Internal class to hold permission information
class _PermissionInfo {
  const _PermissionInfo({
    required this.hasAnyPermission,
    required this.role,
    required this.permissions,
  });

  final bool hasAnyPermission;
  final String role;
  final List<String> permissions;
}

class WorkspaceStateNotifier extends StateNotifier<WorkspaceState> {
  WorkspaceStateNotifier(this._ref) : super(const WorkspaceState());

  final Ref _ref;
  final ChannelService _channelService = ChannelService();
  final Map<String, WorkspaceSnapshot> _workspaceSnapshots = {};
  String? _lastGroupId;

  String? get lastGroupId => _lastGroupId;
  WorkspaceSnapshot? get lastSnapshot =>
      _lastGroupId != null ? _workspaceSnapshots[_lastGroupId!] : null;

  void _saveCurrentWorkspaceSnapshot() {
    // Logout Race Condition Fix:
    // Check if logout is in progress. If so, do not save the snapshot.
    final isLoggingOut = _ref.read(authProvider).isLoggingOut;
    if (isLoggingOut) return;

    if (!mounted) return; // Prevent access after dispose
    final groupId = state.selectedGroupId;
    if (groupId == null) return;

    _workspaceSnapshots[groupId] = WorkspaceSnapshot(
      view: state.currentView,
      mobileView: state.mobileView,
      selectedChannelId: state.selectedChannelId,
      selectedPostId: state.selectedPostId,
      isCommentsVisible: state.isCommentsVisible,
      isNarrowDesktopCommentsFullscreen:
          state.isNarrowDesktopCommentsFullscreen,
      previousView: state.previousView,
    );

    _lastGroupId = groupId;

    // LocalStorage에도 저장 (앱 재시작 시 복원)
    _saveToLocalStorage();
  }

  /// LocalStorage에 워크스페이스 상태 저장
  void _saveToLocalStorage() {
    LocalStorage.instance.saveLastGroupId(state.selectedGroupId);
    LocalStorage.instance.saveLastChannelId(state.selectedChannelId);
    LocalStorage.instance.saveLastViewType(state.currentView.name);
  }

  /// LocalStorage에서 워크스페이스 상태 복원
  Future<void> restoreFromLocalStorage() async {
    try {
      final lastGroupId = await LocalStorage.instance.getLastGroupId();
      final lastChannelId = await LocalStorage.instance.getLastChannelId();
      final lastViewType = await LocalStorage.instance.getLastViewType();

      if (lastGroupId != null) {
        // 복원할 뷰 타입 결정
        // 기본값: groupHome (snapshot이 없을 때 그룹홈 보장)
        WorkspaceView? restoredView;
        if (lastViewType != null) {
          try {
            restoredView = WorkspaceView.values.firstWhere(
              (v) => v.name == lastViewType,
            );
          } catch (_) {
            // Invalid view type: default to groupHome
            restoredView = WorkspaceView.groupHome;
          }
        } else {
          // No saved view type: default to groupHome
          // This ensures first-time access shows groupHome
          restoredView = WorkspaceView.groupHome;
        }

        if (kDebugMode) {
          developer.log(
            'Restoring workspace state: group=$lastGroupId, channel=$lastChannelId, view=$lastViewType (resolved: ${restoredView.name})',
            name: 'WorkspaceStateNotifier',
          );
        }

        // 뷰 타입에 따라 적절한 방식으로 워크스페이스 진입
        // Note: 채널 뷰가 아니면 채널을 자동 선택하지 않음
        if (restoredView == WorkspaceView.channel && lastChannelId != null) {
          // 채널 뷰인 경우에만 channelId 전달
          await enterWorkspace(
            lastGroupId,
            channelId: lastChannelId,
          );
        } else {
          // 다른 뷰인 경우 targetView로 뷰 타입 명시
          // 채널 자동 선택 없이 뷰만 전환
          await enterWorkspace(
            lastGroupId,
            targetView: restoredView,
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log(
          'Failed to restore workspace state from LocalStorage: $e',
          name: 'WorkspaceStateNotifier',
          level: 900,
        );
      }
    }
  }

  WorkspaceSnapshot? _getSnapshot(String groupId) {
    return _workspaceSnapshots[groupId];
  }

  void _applySnapshot(WorkspaceSnapshot snapshot) {
    final updatedContext = Map<String, dynamic>.from(state.workspaceContext);

    if (snapshot.selectedChannelId != null) {
      updatedContext['channelId'] = snapshot.selectedChannelId;
    } else {
      updatedContext.remove('channelId');
      updatedContext.remove('channelName');
    }

    if (snapshot.selectedPostId != null) {
      updatedContext['postId'] = snapshot.selectedPostId;
      updatedContext['commentsVisible'] = snapshot.isCommentsVisible;
    } else {
      updatedContext.remove('postId');
      updatedContext.remove('commentsVisible');
    }

    state = WorkspaceState(
      selectedGroupId: state.selectedGroupId,
      selectedChannelId: snapshot.selectedChannelId,
      isCommentsVisible: snapshot.isCommentsVisible,
      selectedPostId: snapshot.selectedPostId,
      workspaceContext: updatedContext,
      channels: state.channels,
      unreadCounts: state.unreadCounts,
      currentView: snapshot.view,
      mobileView: snapshot.mobileView,
      hasAnyGroupPermission: state.hasAnyGroupPermission,
      currentGroupRole: state.currentGroupRole,
      currentGroupPermissions: state.currentGroupPermissions,
      isLoadingChannels: state.isLoadingChannels,
      isLoadingWorkspace: state.isLoadingWorkspace,
      errorMessage: state.errorMessage,
      channelPermissions: state.channelPermissions,
      isLoadingPermissions: state.isLoadingPermissions,
      isNarrowDesktopCommentsFullscreen:
          snapshot.isNarrowDesktopCommentsFullscreen,
      previousView: snapshot.previousView,
    );

    _lastGroupId = state.selectedGroupId;
  }

  void cacheCurrentWorkspaceState() {
    _saveCurrentWorkspaceSnapshot();
  }

  /// Forcefully clears workspace-related caches (used during logout)
  void forceClearForLogout() {
    _workspaceSnapshots.clear();
    _lastGroupId = null;
    state = const WorkspaceState();
  }

  /// Add current state to navigation history
  void _addToNavigationHistory({
    required String groupId,
    required WorkspaceView view,
    required MobileWorkspaceView mobileView,
    String? channelId,
    String? postId,
    bool isCommentsVisible = false,
  }) {
    // Skip if the current state is identical to the last history entry
    if (state.navigationHistory.isNotEmpty) {
      final last = state.navigationHistory.last;
      if (last.groupId == groupId &&
          last.view == view &&
          last.mobileView == mobileView &&
          last.channelId == channelId &&
          last.postId == postId &&
          last.isCommentsVisible == isCommentsVisible) {
        return; // Don't add duplicate entries
      }
    }

    final newHistory = List<NavigationHistoryEntry>.from(state.navigationHistory);
    newHistory.add(NavigationHistoryEntry(
      groupId: groupId,
      view: view,
      mobileView: mobileView,
      channelId: channelId,
      postId: postId,
      isCommentsVisible: isCommentsVisible,
      timestamp: DateTime.now(),
    ));
    state = state.copyWith(navigationHistory: newHistory);
  }

  /// Pop navigation history and return to previous location
  /// Returns true if successfully navigated back, false if history is empty
  Future<bool> navigateBackInHistory() async {
    if (state.navigationHistory.isEmpty) {
      return false;
    }

    final newHistory = List<NavigationHistoryEntry>.from(state.navigationHistory);
    final previousEntry = newHistory.removeLast();

    // Update history first (prevent re-adding when navigating)
    state = state.copyWith(navigationHistory: newHistory);

    // Restore full state from history entry
    final isSameGroup = state.selectedGroupId == previousEntry.groupId;

    if (!isSameGroup) {
      // Different group: use enterWorkspace
      await enterWorkspace(
        previousEntry.groupId,
        channelId: previousEntry.channelId,
        targetView: previousEntry.view,
      );
    }

    // Restore exact state from history
    state = state.copyWith(
      selectedGroupId: previousEntry.groupId,
      selectedChannelId: previousEntry.channelId,
      currentView: previousEntry.view,
      mobileView: previousEntry.mobileView,
      selectedPostId: previousEntry.postId,
      isCommentsVisible: previousEntry.isCommentsVisible,
    );

    // Load channel permissions if needed
    if (previousEntry.channelId != null) {
      await loadChannelPermissions(previousEntry.channelId!);
    }

    return true;
  }

  /// Clear all navigation history
  void clearNavigationHistory() {
    state = state.copyWith(navigationHistory: []);
  }

  Future<void> enterWorkspace(
    String groupId, {
    String? channelId,
    GroupMembership? membership,
    WorkspaceView? targetView,
  }) async {
    final isSameGroup = state.selectedGroupId == groupId;
    _lastGroupId = groupId;

    // Step 1: Resolve membership (needed for permission check)
    final resolvedMembership =
        membership ?? await _resolveGroupMembership(groupId);

    if (resolvedMembership == null) {
      _handleMembershipResolutionFailure();
      return;
    }

    // Step 2: Save current workspace state if switching groups
    if (!isSameGroup && state.selectedGroupId != null) {
      _saveCurrentWorkspaceSnapshot();
      _ref.invalidate(placeCalendarProvider);

      // Add current state to navigation history (group switching)
      _addToNavigationHistory(
        groupId: state.selectedGroupId!,
        view: state.currentView,
        mobileView: state.mobileView,
        channelId: state.selectedChannelId,
        postId: state.selectedPostId,
        isCommentsVisible: state.isCommentsVisible,
      );
    }

    // Step 3: Determine navigation target
    final snapshot = channelId != null ? null : _getSnapshot(groupId);
    final navigationTarget = _determineNavigationTarget(
      isSameGroup: isSameGroup,
      targetView: targetView,
      channelId: channelId,
      snapshot: snapshot,
      membership: resolvedMembership,
    );

    // Step 4: Check for quick restore scenario (same group, no explicit navigation)
    if (_shouldQuickRestore(
      isSameGroup: isSameGroup,
      channelId: channelId,
      snapshot: snapshot,
    )) {
      if (snapshot != null) {
        _applySnapshot(snapshot);
      }
      return;
    }

    // Step 5: Update state with navigation target
    _updateStateForNavigation(
      groupId: groupId,
      navigationTarget: navigationTarget,
      snapshot: snapshot,
      isSameGroup: isSameGroup,
    );

    // Step 6: Load channels and finalize state
    try {
      await loadChannels(
        groupId,
        autoSelectChannelId:
            channelId ?? navigationTarget.autoSelectChannelId,
        membership: resolvedMembership,
        targetView: navigationTarget.finalView,
      );

      // Step 7: Apply snapshot for same group navigation (if applicable)
      if (isSameGroup && targetView == null && snapshot != null) {
        _applySnapshot(snapshot);
      }

      state = state.copyWith(isLoadingWorkspace: false);

      // Step 8: Load unread counts for all channels (background, no await)
      final channelIds = state.channels.map((c) => c.id).toList();
      if (channelIds.isNotEmpty) {
        loadUnreadCounts(channelIds); // Fire and forget
      }
    } catch (e) {
      _handleWorkspaceLoadFailure();
    }
  }

  /// Handle membership resolution failure
  void _handleMembershipResolutionFailure() {
    state = state.copyWith(
      isLoadingWorkspace: false,
      isLoadingChannels: false,
      channels: [],
      hasAnyGroupPermission: false,
      currentGroupPermissions: null,
      currentGroupRole: null,
      errorMessage: '그룹 정보를 불러올 수 없습니다.',
    );
  }

  /// Handle workspace load failure
  void _handleWorkspaceLoadFailure() {
    state = state.copyWith(
      isLoadingWorkspace: false,
      isLoadingChannels: false,
      channels: [],
      hasAnyGroupPermission: false,
      currentGroupPermissions: null,
      currentGroupRole: null,
      errorMessage: '워크스페이스를 불러오는 중 문제가 발생했습니다.',
    );
  }

  /// Check if we should quickly restore existing state without reloading
  bool _shouldQuickRestore({
    required bool isSameGroup,
    required String? channelId,
    required WorkspaceSnapshot? snapshot,
  }) {
    return isSameGroup &&
        channelId == null &&
        snapshot != null &&
        state.channels.isNotEmpty;
  }

  /// Determine navigation target (view, mobile view, channel selection)
  _NavigationTarget _determineNavigationTarget({
    required bool isSameGroup,
    required WorkspaceView? targetView,
    required String? channelId,
    required WorkspaceSnapshot? snapshot,
    required GroupMembership membership,
  }) {
    // Check permission for admin views
    final hasGroupAdminPermission =
        WorkspaceNavigationHelper.hasGroupAdminPermission(membership);

    // Determine final view
    final finalView = WorkspaceNavigationHelper.determineTargetView(
      isSameGroup: isSameGroup,
      currentView: state.currentView,
      targetView: targetView,
      snapshot: snapshot,
      hasChannelId: channelId != null,
      hasGroupAdminPermission: hasGroupAdminPermission,
    );

    // Determine mobile view
    final finalMobileView = WorkspaceNavigationHelper.determineMobileView(
      isSameGroup: isSameGroup,
      currentMobileView: state.mobileView,
      snapshot: snapshot,
    );

    // Determine if channel should be auto-selected
    final String? autoSelectChannelId = channelId ?? snapshot?.selectedChannelId;

    return _NavigationTarget(
      finalView: finalView,
      finalMobileView: finalMobileView,
      autoSelectChannelId: autoSelectChannelId,
    );
  }

  /// Update state with determined navigation target
  void _updateStateForNavigation({
    required String groupId,
    required _NavigationTarget navigationTarget,
    required WorkspaceSnapshot? snapshot,
    required bool isSameGroup,
  }) {
    final hasMobileState = state.mobileView != MobileWorkspaceView.channelList;

    state = state.copyWith(
      selectedGroupId: groupId,
      selectedChannelId: hasMobileState
          ? state.selectedChannelId
          : snapshot?.selectedChannelId,
      isCommentsVisible: hasMobileState
          ? state.isCommentsVisible
          : (snapshot?.isCommentsVisible ?? false),
      selectedPostId:
          hasMobileState ? state.selectedPostId : snapshot?.selectedPostId,
      currentView: navigationTarget.finalView,
      mobileView: navigationTarget.finalMobileView,
      isNarrowDesktopCommentsFullscreen: hasMobileState
          ? state.isNarrowDesktopCommentsFullscreen
          : (snapshot?.isNarrowDesktopCommentsFullscreen ?? false),
      previousView: isSameGroup ? snapshot?.previousView : null,
      workspaceContext: {
        'groupId': groupId,
        if ((hasMobileState && state.selectedChannelId != null) ||
            (!hasMobileState && snapshot?.selectedChannelId != null))
          'channelId': hasMobileState
              ? state.selectedChannelId
              : snapshot?.selectedChannelId,
      },
      isLoadingWorkspace: true,
    );
  }

  /// Load channels and membership information for a group
  Future<void> loadChannels(
    String groupId, {
    String? autoSelectChannelId,
    required GroupMembership membership,
    WorkspaceView? targetView,
  }) async {
    try {
      final groupIdInt = int.parse(groupId);
      state = state.copyWith(isLoadingChannels: true);

      // Step 1: Fetch channels
      final channels = await _channelService.getChannels(groupIdInt);

      // Step 2: Extract permissions
      final permissionInfo = _extractPermissionInfo(membership);

      // Step 3: Generate unread counts (dummy data)
      final unreadCounts = _generateUnreadCounts(channels);

      // Step 4: Validate final view with permission check
      // NOTE: Use currentView (already determined in _determineNavigationTarget)
      // instead of targetView to avoid overriding the navigation decision
      final finalView = WorkspaceNavigationHelper.validateAndFallbackView(
        targetView: state.currentView,
        hasGroupAdminPermission: permissionInfo.hasAnyPermission,
      );

      // Step 5: Determine channel selection based on finalView
      final shouldSelectChannel = WorkspaceNavigationHelper.shouldSelectChannel(
        finalView,
      );
      final selectedChannelId = shouldSelectChannel
          ? (WorkspaceNavigationHelper.selectFirstChannel(
                channels: channels,
                shouldSelectChannel: true,
              ) ??
              autoSelectChannelId)
          : autoSelectChannelId;

      // Step 6: Update state
      state = state.copyWith(
        channels: channels,
        unreadCounts: unreadCounts,
        hasAnyGroupPermission: permissionInfo.hasAnyPermission,
        currentGroupRole: permissionInfo.role,
        currentGroupPermissions: permissionInfo.permissions,
        isLoadingChannels: false,
        selectedChannelId: selectedChannelId,
        currentView: finalView,
        workspaceContext: selectedChannelId != null
            ? (Map.from(state.workspaceContext)
              ..['channelId'] = selectedChannelId)
            : state.workspaceContext,
      );

      // Step 7: Auto-load channel permissions
      if (selectedChannelId != null) {
        await loadChannelPermissions(selectedChannelId);
      }
    } catch (e) {
      state = state.copyWith(
        isLoadingChannels: false,
        channels: [],
        hasAnyGroupPermission: false,
      );
      rethrow;
    }
  }

  /// Extract permission information from membership
  _PermissionInfo _extractPermissionInfo(GroupMembership membership) {
    final permissions = membership.permissions;
    final hasAnyPermission =
        PermissionUtils.hasAnyGroupManagementPermission(permissions);
    final currentRole = membership.role;
    final currentPermissions = permissions.toList();

    return _PermissionInfo(
      hasAnyPermission: hasAnyPermission,
      role: currentRole,
      permissions: currentPermissions,
    );
  }

  /// Generate dummy unread counts for channels (for demonstration)
  Map<String, int> _generateUnreadCounts(List<Channel> channels) {
    final unreadCounts = <String, int>{};
    for (var channel in channels) {
      // Randomly assign 0-5 unread messages to some channels
      if (channel.id % 3 == 0) {
        unreadCounts[channel.id.toString()] = (channel.id % 5) + 1;
      }
    }
    return unreadCounts;
  }

  Future<GroupMembership?> _resolveGroupMembership(String groupId) async {
    try {
      final memberships = await _ref.read(myGroupsProvider.future);
      try {
        return memberships.firstWhere(
          (group) => group.id.toString() == groupId,
        );
      } catch (_) {
        return null;
      }
    } catch (_) {
      return null;
    }
  }

  void selectChannel(String channelId) async {
    // 1. Save read position for previous channel if we have a visible post
    final prevChannelId = state.selectedChannelId;
    if (prevChannelId != null && state.currentVisiblePostId != null) {
      final prevChannelIdInt = int.tryParse(prevChannelId);
      if (prevChannelIdInt != null) {
        // Best-Effort: ignore errors
        try {
          await saveReadPosition(prevChannelIdInt, state.currentVisiblePostId!);

          // ✅ 이탈 시 뱃지 업데이트 (읽지 않은 글 개수 재계산)
          await loadUnreadCount(prevChannelIdInt);
        } catch (e) {
          // Silently ignore read position save errors
          if (kDebugMode) {
            developer.log(
              'Failed to save read position for channel $prevChannelIdInt: $e',
              name: 'WorkspaceStateNotifier',
              level: 300,
            );
          }
        }
      }
    }

    // Add current state to navigation history before changing channel
    if (state.selectedGroupId != null && prevChannelId != null) {
      _addToNavigationHistory(
        groupId: state.selectedGroupId!,
        view: state.currentView,
        mobileView: state.mobileView,
        channelId: prevChannelId,
        postId: state.selectedPostId,
        isCommentsVisible: state.isCommentsVisible,
      );
    }

    // 2. Switch to new channel
    // Find channel name from channels list
    final selectedChannel = state.channels.firstWhere(
      (channel) => channel.id.toString() == channelId,
      orElse: () => state.channels.first,
    );

    state = state.copyWith(
      selectedChannelId: channelId,
      isCommentsVisible: false,
      selectedPostId: null,
      currentView: WorkspaceView.channel,
      // Reset previousView when entering channel view
      previousView: null,
      clearCurrentVisiblePostId: true, // Clear visible post when switching channels
      workspaceContext: Map.from(state.workspaceContext)
        ..['channelId'] = channelId
        ..['channelName'] = selectedChannel.name,
    );

    // LocalStorage에 저장
    _saveToLocalStorage();

    // 3. Load permissions and read position for the selected channel
    final channelIdInt = int.tryParse(channelId);
    if (channelIdInt != null) {
      await Future.wait([
        loadChannelPermissions(channelId),
        loadReadPosition(channelIdInt),
      ]);
    } else {
      await loadChannelPermissions(channelId);
    }
  }

  /// Load channel permissions for the currently selected channel
  Future<void> loadChannelPermissions(String channelId) async {
    try {
      final channelIdInt = int.parse(channelId);

      state = state.copyWith(isLoadingPermissions: true);

      final permissions = await _channelService.getMyPermissions(channelIdInt);

      state = state.copyWith(
        channelPermissions: permissions,
        isLoadingPermissions: false,
      );
    } catch (e) {
      // On error, set permissions to null (defaults to disabled)
      state = state.copyWith(
        channelPermissions: null,
        isLoadingPermissions: false,
      );
    }
  }

  // ============================================================
  // Read Position Management
  // ============================================================

  /// Load read position for a channel (called when entering channel)
  Future<void> loadReadPosition(int channelId) async {
    final position = await _channelService.getReadPosition(channelId);

    if (position != null) {
      state = state.copyWith(
        lastReadPostIdMap: {
          ...state.lastReadPostIdMap,
          channelId: position.lastReadPostId,
        },
      );
    }
  }

  /// Save read position for a channel
  /// Best-effort operation - errors are ignored
  ///
  /// Note: Badge update (unread count) is NOT performed here.
  /// It should be manually called when leaving the channel (selectChannel, exitWorkspace)
  Future<void> saveReadPosition(int channelId, int postId) async {
    // API call (Best-Effort, error ignored)
    await _channelService.updateReadPosition(channelId, postId);

    // Update local state
    state = state.copyWith(
      lastReadPostIdMap: {
        ...state.lastReadPostIdMap,
        channelId: postId,
      },
    );

    // Badge update is NOT performed here - it should be done when leaving channel
  }

  /// Update currently visible post ID (called during scrolling)
  void updateCurrentVisiblePost(int postId) {
    state = state.copyWith(currentVisiblePostId: postId);
  }

  /// Load unread count for a single channel
  Future<void> loadUnreadCount(int channelId) async {
    final count = await _channelService.getUnreadCount(channelId);

    state = state.copyWith(
      unreadCountMap: {
        ...state.unreadCountMap,
        channelId: count,
      },
    );
  }

  /// Load unread counts for multiple channels (batch query)
  Future<void> loadUnreadCounts(List<int> channelIds) async {
    final counts = await _channelService.getUnreadCounts(channelIds);

    state = state.copyWith(
      unreadCountMap: {
        ...state.unreadCountMap,
        ...counts,
      },
    );
  }

  /// Load workspace with unread counts (called when entering workspace)
  Future<void> loadWorkspaceWithUnreadCounts(
    String groupId, {
    String? channelId,
    GroupMembership? membership,
    WorkspaceView? targetView,
  }) async {
    // Load workspace first
    await enterWorkspace(
      groupId,
      channelId: channelId,
      membership: membership,
      targetView: targetView,
    );

    // Collect all channel IDs
    final channelIds = state.channels.map((c) => c.id).toList();

    // Batch load unread counts
    if (channelIds.isNotEmpty) {
      await loadUnreadCounts(channelIds);
    }
  }

  /// Show group home view
  void showGroupHome() {
    // Add current state to navigation history
    if (state.selectedGroupId != null) {
      _addToNavigationHistory(
        groupId: state.selectedGroupId!,
        view: state.currentView,
        mobileView: state.mobileView,
        channelId: state.selectedChannelId,
        postId: state.selectedPostId,
        isCommentsVisible: state.isCommentsVisible,
      );
    }

    state = state.copyWith(
      previousView: state.currentView,
      currentView: WorkspaceView.groupHome,
      selectedChannelId: null,
      isCommentsVisible: false,
      selectedPostId: null,
      isNarrowDesktopCommentsFullscreen: false,
      selectedCalendarDate: null,
    );
  }

  /// Show calendar view
  void showCalendar({DateTime? selectedDate}) {
    // Add current state to navigation history
    if (state.selectedGroupId != null) {
      _addToNavigationHistory(
        groupId: state.selectedGroupId!,
        view: state.currentView,
        mobileView: state.mobileView,
        channelId: state.selectedChannelId,
        postId: state.selectedPostId,
        isCommentsVisible: state.isCommentsVisible,
      );
    }

    state = state.copyWith(
      previousView: state.currentView,
      currentView: WorkspaceView.calendar,
      selectedChannelId: null,
      isCommentsVisible: false,
      selectedPostId: null,
      isNarrowDesktopCommentsFullscreen: false,
      selectedCalendarDate: selectedDate,
    );
  }

  /// Show group admin/management page view
  void showGroupAdminPage() {
    // Add current state to navigation history
    if (state.selectedGroupId != null) {
      _addToNavigationHistory(
        groupId: state.selectedGroupId!,
        view: state.currentView,
        mobileView: state.mobileView,
        channelId: state.selectedChannelId,
        postId: state.selectedPostId,
        isCommentsVisible: state.isCommentsVisible,
      );
    }

    state = state.copyWith(
      previousView: state.currentView,
      currentView: WorkspaceView.groupAdmin,
      selectedChannelId: null,
      isCommentsVisible: false,
      selectedPostId: null,
      isNarrowDesktopCommentsFullscreen: false,
    );
  }

  /// Show member management page view
  void showMemberManagementPage() {
    // Add current state to navigation history
    if (state.selectedGroupId != null) {
      _addToNavigationHistory(
        groupId: state.selectedGroupId!,
        view: state.currentView,
        mobileView: state.mobileView,
        channelId: state.selectedChannelId,
        postId: state.selectedPostId,
        isCommentsVisible: state.isCommentsVisible,
      );
    }

    state = state.copyWith(
      previousView: state.currentView,
      currentView: WorkspaceView.memberManagement,
      selectedChannelId: null,
      isCommentsVisible: false,
      selectedPostId: null,
      isNarrowDesktopCommentsFullscreen: false,
    );
  }

  /// Show recruitment management page view
  void showRecruitmentManagementPage() {
    // Add current state to navigation history
    if (state.selectedGroupId != null) {
      _addToNavigationHistory(
        groupId: state.selectedGroupId!,
        view: state.currentView,
        mobileView: state.mobileView,
        channelId: state.selectedChannelId,
        postId: state.selectedPostId,
        isCommentsVisible: state.isCommentsVisible,
      );
    }

    state = state.copyWith(
      previousView: state.currentView,
      currentView: WorkspaceView.recruitmentManagement,
      selectedChannelId: null,
      isCommentsVisible: false,
      selectedPostId: null,
      isNarrowDesktopCommentsFullscreen: false,
    );
  }

  /// Show application management page view (모집 지원자 관리)
  void showApplicationManagementPage() {
    // Add current state to navigation history
    if (state.selectedGroupId != null) {
      _addToNavigationHistory(
        groupId: state.selectedGroupId!,
        view: state.currentView,
        mobileView: state.mobileView,
        channelId: state.selectedChannelId,
        postId: state.selectedPostId,
        isCommentsVisible: state.isCommentsVisible,
      );
    }

    state = state.copyWith(
      previousView: state.currentView,
      currentView: WorkspaceView.applicationManagement,
      selectedChannelId: null,
      isCommentsVisible: false,
      selectedPostId: null,
      isNarrowDesktopCommentsFullscreen: false,
    );
  }

  /// Show place time management page view (장소 시간 관리)
  void showPlaceTimeManagementPage(int placeId, String placeName) {
    // Add current state to navigation history
    if (state.selectedGroupId != null) {
      _addToNavigationHistory(
        groupId: state.selectedGroupId!,
        view: state.currentView,
        mobileView: state.mobileView,
        channelId: state.selectedChannelId,
        postId: state.selectedPostId,
        isCommentsVisible: state.isCommentsVisible,
      );
    }

    state = state.copyWith(
      previousView: state.currentView,
      currentView: WorkspaceView.placeTimeManagement,
      selectedChannelId: null,
      isCommentsVisible: false,
      selectedPostId: null,
      isNarrowDesktopCommentsFullscreen: false,
      selectedPlaceId: placeId,
      selectedPlaceName: placeName,
    );
  }

  /// Show channel management page view
  void showChannelManagementPage() {
    // Add current state to navigation history
    if (state.selectedGroupId != null) {
      _addToNavigationHistory(
        groupId: state.selectedGroupId!,
        view: state.currentView,
        mobileView: state.mobileView,
        channelId: state.selectedChannelId,
        postId: state.selectedPostId,
        isCommentsVisible: state.isCommentsVisible,
      );
    }

    state = state.copyWith(
      previousView: state.currentView,
      currentView: WorkspaceView.channelManagement,
      selectedChannelId: null,
      isCommentsVisible: false,
      selectedPostId: null,
      isNarrowDesktopCommentsFullscreen: false,
    );
  }

  /// Show channel view
  void showChannel(String channelId) {
    selectChannel(channelId);
  }

  void showComments(String postId, {bool isNarrowDesktop = false}) {
    // Add current state to navigation history
    if (state.selectedGroupId != null) {
      _addToNavigationHistory(
        groupId: state.selectedGroupId!,
        view: state.currentView,
        mobileView: state.mobileView,
        channelId: state.selectedChannelId,
        postId: state.selectedPostId,
        isCommentsVisible: state.isCommentsVisible,
      );
    }

    state = state.copyWith(
      isCommentsVisible: true,
      selectedPostId: postId,
      isNarrowDesktopCommentsFullscreen: isNarrowDesktop,
      workspaceContext: Map.from(state.workspaceContext)
        ..['postId'] = postId
        ..['commentsVisible'] = true,
    );
  }

  void hideComments() {
    state = state.copyWith(
      isCommentsVisible: false,
      selectedPostId: null,
      isNarrowDesktopCommentsFullscreen: false,
      workspaceContext: Map.from(state.workspaceContext)
        ..remove('postId')
        ..remove('commentsVisible'),
    );
  }

  void exitWorkspace() async {
    // 1. Save read position for current channel if we have a visible post
    final currentChannelId = state.selectedChannelId;
    if (currentChannelId != null && state.currentVisiblePostId != null) {
      final channelIdInt = int.tryParse(currentChannelId);
      if (channelIdInt != null) {
        // Best-Effort: ignore errors
        try {
          await saveReadPosition(channelIdInt, state.currentVisiblePostId!);

          // ✅ 이탈 시 뱃지 업데이트 (읽지 않은 글 개수 재계산)
          await loadUnreadCount(channelIdInt);
        } catch (e) {
          // Silently ignore read position save errors
          if (kDebugMode) {
            developer.log(
              'Failed to save read position when exiting workspace: $e',
              name: 'WorkspaceStateNotifier',
              level: 300,
            );
          }
        }
      }
    }

    // 2. Save workspace snapshot and reset state
    _saveCurrentWorkspaceSnapshot();
    state = const WorkspaceState();
  }

  /// Update workspace state (for view switching, etc.)
  void updateState(WorkspaceState newState) {
    state = newState;
  }

  void updateContext(Map<String, dynamic> context) {
    state = state.copyWith(
      workspaceContext: Map.from(state.workspaceContext)..addAll(context),
    );
  }

  /// Set loading state for workspace initialization
  void setLoadingState(bool isLoading) {
    state = state.copyWith(isLoadingWorkspace: isLoading);
  }

  /// Set error message
  void setError(String message) {
    state = state.copyWith(errorMessage: message, isLoadingWorkspace: false);
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  // 반응형 전환을 위한 상태 복원 메서드
  void restoreFromContext(Map<String, dynamic> context) {
    final groupId = context['groupId'] as String?;
    final channelId = context['channelId'] as String?;
    final postId = context['postId'] as String?;
    final commentsVisible = context['commentsVisible'] as bool? ?? false;

    if (groupId != null) {
      state = WorkspaceState(
        selectedGroupId: groupId,
        selectedChannelId: channelId,
        isCommentsVisible: commentsVisible,
        selectedPostId: postId,
        workspaceContext: context,
      );
    }
  }

  // 모바일 → 웹 전환 시 댓글 사이드바 복원
  void restoreCommentsForWeb() {
    if (state.selectedPostId != null) {
      state = state.copyWith(isCommentsVisible: true);
    }
  }

  // 웹 → 모바일 전환 시 댓글 뷰 상태 유지
  void preserveCommentsForMobile() {
    // 모바일에서는 댓글이 전체 화면으로 표시되므로
    // isCommentsVisible 상태는 유지하되 UI 구현에서 처리
  }

  // 모바일 뷰 전환 메서드
  void setMobileView(MobileWorkspaceView view) {
    state = state.copyWith(mobileView: view);
  }

  // 모바일에서 채널 선택 시 (Step 1 → Step 2)
  void selectChannelForMobile(String channelId) async {
    // 1. Save read position for previous channel if we have a visible post
    final prevChannelId = state.selectedChannelId;
    if (prevChannelId != null && state.currentVisiblePostId != null) {
      final prevChannelIdInt = int.tryParse(prevChannelId);
      if (prevChannelIdInt != null) {
        // Best-Effort: ignore errors
        try {
          await saveReadPosition(prevChannelIdInt, state.currentVisiblePostId!);

          // ✅ 이탈 시 뱃지 업데이트 (읽지 않은 글 개수 재계산)
          await loadUnreadCount(prevChannelIdInt);
        } catch (e) {
          // Silently ignore read position save errors
          if (kDebugMode) {
            developer.log(
              'Failed to save read position for channel $prevChannelIdInt: $e',
              name: 'WorkspaceStateNotifier',
              level: 300,
            );
          }
        }
      }
    }

    // 2. Switch to new channel
    // Find channel name from channels list
    final selectedChannel = state.channels.firstWhere(
      (channel) => channel.id.toString() == channelId,
      orElse: () => state.channels.first,
    );

    state = state.copyWith(
      selectedChannelId: channelId,
      mobileView: MobileWorkspaceView.channelPosts,
      isCommentsVisible: false,
      selectedPostId: null,
      clearCurrentVisiblePostId: true, // Clear visible post when switching channels
      workspaceContext: Map.from(state.workspaceContext)
        ..['channelId'] = channelId
        ..['channelName'] = selectedChannel.name,
    );

    // 3. Load permissions and read position for the selected channel
    final channelIdInt = int.tryParse(channelId);
    if (channelIdInt != null) {
      await Future.wait([
        loadChannelPermissions(channelId),
        loadReadPosition(channelIdInt),
      ]);
    } else {
      await loadChannelPermissions(channelId);
    }
  }

  // 모바일에서 댓글 보기 시 (Step 2 → Step 3)
  void showCommentsForMobile(String postId) {
    // Add current state to navigation history
    if (state.selectedGroupId != null) {
      _addToNavigationHistory(
        groupId: state.selectedGroupId!,
        view: state.currentView,
        mobileView: state.mobileView,
        channelId: state.selectedChannelId,
        postId: state.selectedPostId,
        isCommentsVisible: state.isCommentsVisible,
      );
    }

    state = state.copyWith(
      isCommentsVisible: true,
      selectedPostId: postId,
      mobileView: MobileWorkspaceView.postComments,
      workspaceContext: Map.from(state.workspaceContext)
        ..['postId'] = postId
        ..['commentsVisible'] = true,
    );
  }

  // 모바일 뒤로가기 핸들링
  Future<bool> handleMobileBack() async {
    // Use unified navigation history
    if (state.navigationHistory.isNotEmpty) {
      return await navigateBackInHistory();
    }

    // No history - navigate to home
    return false;
  }

  /// Web back navigation handling
  /// Returns: true if handled internally, false if should navigate to home
  Future<bool> handleWebBack() async {
    // Use unified navigation history
    if (state.navigationHistory.isNotEmpty) {
      return await navigateBackInHistory();
    }

    // No history - navigate to home
    return false;
  }

  // 반응형 전환 핸들러: 웹 → 모바일
  void handleWebToMobileTransition() {
    // 현재 상태에 따라 적절한 모바일 뷰 설정
    if (state.isCommentsVisible && state.selectedPostId != null) {
      // 댓글이 열려있으면 댓글 뷰로
      state = state.copyWith(mobileView: MobileWorkspaceView.postComments);
    } else if (state.selectedChannelId != null) {
      // 채널이 선택되어 있으면 게시글 뷰로
      state = state.copyWith(mobileView: MobileWorkspaceView.channelPosts);
    } else {
      // 기본값: 채널 목록
      state = state.copyWith(mobileView: MobileWorkspaceView.channelList);
    }
  }

  // 반응형 전환 핸들러: 모바일 → 웹
  void handleMobileToWebTransition() {
    // 모바일 댓글 뷰였다면 웹 댓글 사이드바 복원
    if (state.mobileView == MobileWorkspaceView.postComments) {
      restoreCommentsForWeb();
    }
  }
}

final workspaceStateProvider =
    StateNotifierProvider<WorkspaceStateNotifier, WorkspaceState>(
      (ref) => WorkspaceStateNotifier(ref),
    );

// 워크스페이스 컨텍스트 관련 유틸리티 Provider들
final currentGroupIdProvider = Provider<String?>((ref) {
  return ref.watch(
    workspaceStateProvider.select((state) => state.selectedGroupId),
  );
});

final currentChannelIdProvider = Provider<String?>((ref) {
  return ref.watch(
    workspaceStateProvider.select((state) => state.selectedChannelId),
  );
});

final isInWorkspaceProvider = Provider<bool>((ref) {
  return ref.watch(
    workspaceStateProvider.select((state) => state.isInWorkspace),
  );
});

final isCommentsVisibleProvider = Provider<bool>((ref) {
  return ref.watch(
    workspaceStateProvider.select((state) => state.isCommentsVisible),
  );
});

final workspaceCurrentViewProvider = Provider<WorkspaceView>((ref) {
  return ref.watch(workspaceStateProvider.select((state) => state.currentView));
});

final workspaceMobileViewProvider = Provider<MobileWorkspaceView>((ref) {
  return ref.watch(workspaceStateProvider.select((state) => state.mobileView));
});

final workspaceIsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(
    workspaceStateProvider.select((state) => state.isLoadingWorkspace),
  );
});

final workspaceErrorMessageProvider = Provider<String?>((ref) {
  return ref.watch(
    workspaceStateProvider.select((state) => state.errorMessage),
  );
});

final workspaceChannelsProvider = Provider<List<Channel>>((ref) {
  return ref.watch(workspaceStateProvider.select((state) => state.channels));
});

final workspaceUnreadCountsProvider = Provider<Map<String, int>>((ref) {
  return ref.watch(
    workspaceStateProvider.select((state) => state.unreadCounts),
  );
});

final workspaceHasAnyGroupPermissionProvider = Provider<bool>((ref) {
  return ref.watch(
    workspaceStateProvider.select((state) => state.hasAnyGroupPermission),
  );
});

final workspaceChannelPermissionsProvider = Provider<ChannelPermissions?>((
  ref,
) {
  return ref.watch(
    workspaceStateProvider.select((state) => state.channelPermissions),
  );
});

final workspaceIsLoadingPermissionsProvider = Provider<bool>((ref) {
  return ref.watch(
    workspaceStateProvider.select((state) => state.isLoadingPermissions),
  );
});

final workspaceSelectedPostIdProvider = Provider<String?>((ref) {
  return ref.watch(
    workspaceStateProvider.select((state) => state.selectedPostId),
  );
});

final workspaceIsNarrowDesktopCommentsFullscreenProvider = Provider<bool>((
  ref,
) {
  return ref.watch(
    workspaceStateProvider.select(
      (state) => state.isNarrowDesktopCommentsFullscreen,
    ),
  );
});

final workspaceHasSelectedChannelProvider = Provider<bool>((ref) {
  return ref.watch(
    workspaceStateProvider.select((state) => state.hasSelectedChannel),
  );
});

final workspacePreviousViewProvider = Provider<WorkspaceView?>((ref) {
  return ref.watch(
    workspaceStateProvider.select((state) => state.previousView),
  );
});

final workspaceCurrentGroupRoleProvider = Provider<String?>((ref) {
  return ref.watch(
    workspaceStateProvider.select((state) => state.currentGroupRole),
  );
});

final workspaceCurrentGroupPermissionsProvider = Provider<List<String>?>((ref) {
  return ref.watch(
    workspaceStateProvider.select((state) => state.currentGroupPermissions),
  );
});

final workspaceNavigationHistoryProvider = Provider<List<NavigationHistoryEntry>>((ref) {
  return ref.watch(
    workspaceStateProvider.select((state) => state.navigationHistory),
  );
});
