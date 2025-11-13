import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../../core/models/channel_models.dart';
import '../../core/models/group_models.dart';
import '../../core/services/channel_service.dart';
import '../../core/services/local_storage.dart';
import '../../core/utils/permission_utils.dart';
import '../../core/navigation/navigation_controller.dart';
import 'my_groups_provider.dart';
import 'place_calendar_provider.dart';
import 'auth_provider.dart';
import 'workspace_navigation_helper.dart';
import 'navigation_state_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// 웹 플랫폼에서만 JS interop 및 HTML API 사용 (조건부 import)
// ignore: uri_does_not_exist
import 'workspace_state_provider_stub.dart'
    if (dart.library.html) 'workspace_state_provider_web.dart'
    as web_utils;

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
    this.selectedGroup,
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
  final GroupMembership? selectedGroup;
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
  final String?
  selectedPlaceName; // Selected place name for place time management
  final List<NavigationHistoryEntry>
  navigationHistory; // Unified navigation history (channels, views, groups)
  final DateTime? selectedCalendarDate; // Selected date for calendar view
  final Map<int, int> lastReadPostIdMap; // {channelId: lastReadPostId}
  final Map<int, int> unreadCountMap; // {channelId: unreadCount}
  final int?
  currentVisiblePostId; // Currently visible post ID for tracking read position

  WorkspaceState copyWith({
    String? selectedGroupId,
    GroupMembership? selectedGroup,
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
      selectedGroup: selectedGroup ?? this.selectedGroup,
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
    selectedGroup,
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
  WorkspaceStateNotifier(this._ref) : super(const WorkspaceState()) {
    // myGroupsProvider 변경 감지 리스너 추가
    // 그룹 정보가 업데이트되면 (예: 그룹 이름 변경) selectedGroup도 자동 동기화
    _ref.listen<AsyncValue<List<GroupMembership>>>(myGroupsProvider, (
      prev,
      next,
    ) {
      // 그룹 리스트가 업데이트되고, 현재 선택된 그룹이 있으면
      if (next.hasValue && state.selectedGroupId != null) {
        try {
          final updatedGroup = next.value!.firstWhere(
            (g) => g.id.toString() == state.selectedGroupId,
          );
          // 변경된 그룹 정보로 state 업데이트
          if (mounted) {
            state = state.copyWith(selectedGroup: updatedGroup);
          }
        } catch (_) {
          // 그룹을 찾을 수 없으면 null로 설정 (예: 그룹에서 제명됨)
          if (mounted) {
            state = state.copyWith(selectedGroup: null);
          }
        }
      }
    });
  }

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
        // ✅ Priority 1: 채널 ID가 있으면 채널 뷰
        // ✅ Priority 2: 저장된 뷰 타입이 있으면 복원
        // ✅ Priority 3: 없으면 기본값 (웹: groupHome, 모바일: channel)

        WorkspaceView? restoredView;
        bool shouldUseChannelView = false;

        // 채널 ID가 있으면 무조건 채널 뷰로 진입
        if (lastChannelId != null) {
          shouldUseChannelView = true;
        } else if (lastViewType != null) {
          // 채널 ID가 없을 때 저장된 뷰 타입 복원
          try {
            restoredView = WorkspaceView.values.firstWhere(
              (v) => v.name == lastViewType,
            );
            // 저장된 뷰가 groupHome/calendar 등 특수 뷰인 경우만 복원
            if (restoredView != WorkspaceView.channel) {
              shouldUseChannelView = false;
            } else {
              // 저장된 뷰가 channel인데 channelId가 없으면 첫 채널로
              shouldUseChannelView = true;
            }
          } catch (_) {
            // Invalid view type: 플랫폼별 기본 동작
            shouldUseChannelView =
                !kIsWeb; // 웹: false (groupHome), 모바일: true (channel)
          }
        } else {
          // No saved view type: 플랫폼별 기본 동작
          // 웹: groupHome으로 진입 (UX 명세 준수)
          // 모바일: 채널 뷰로 진입 (모바일 UX: 채널 리스트가 홈)
          shouldUseChannelView = !kIsWeb;
        }

        if (kDebugMode) {
          developer.log(
            'Restoring workspace state: group=$lastGroupId, channel=$lastChannelId, view=$lastViewType, shouldUseChannelView=$shouldUseChannelView, kIsWeb=$kIsWeb',
            name: 'WorkspaceStateNotifier',
          );
        }

        // 뷰 타입에 따라 적절한 방식으로 워크스페이스 진입
        if (shouldUseChannelView) {
          // 채널 뷰: channelId 전달 (있으면) 또는 첫 번째 채널 자동 선택
          await enterWorkspace(lastGroupId, channelId: lastChannelId);
        } else if (restoredView != null) {
          // 특수 뷰 (groupHome, calendar 등): targetView로 뷰 타입 명시
          await enterWorkspace(lastGroupId, targetView: restoredView);
        } else {
          // Fallback: groupHome으로 진입 (웹 기본값)
          await enterWorkspace(
            lastGroupId,
            targetView: WorkspaceView.groupHome,
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

  /// Check if a session snapshot exists for the given group
  ///
  /// Returns true if a snapshot exists (not first-time access),
  /// false otherwise (first-time access or cleared after global home return)
  bool hasSnapshot(String groupId) {
    return _workspaceSnapshots.containsKey(groupId);
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

    final newHistory = List<NavigationHistoryEntry>.from(
      state.navigationHistory,
    );
    newHistory.add(
      NavigationHistoryEntry(
        groupId: groupId,
        view: view,
        mobileView: mobileView,
        channelId: channelId,
        postId: postId,
        isCommentsVisible: isCommentsVisible,
        timestamp: DateTime.now(),
      ),
    );
    state = state.copyWith(navigationHistory: newHistory);
  }

  /// Pop navigation history and return to previous location
  /// Returns true if successfully navigated back, false if history is empty
  Future<bool> navigateBackInHistory() async {
    if (state.navigationHistory.isEmpty) {
      return false;
    }

    final newHistory = List<NavigationHistoryEntry>.from(
      state.navigationHistory,
    );
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
      membership: resolvedMembership,
      navigationTarget: navigationTarget,
      snapshot: snapshot,
      isSameGroup: isSameGroup,
    );

    // Step 6: Load channels and finalize state
    try {
      await loadChannels(
        groupId,
        autoSelectChannelId: channelId ?? navigationTarget.autoSelectChannelId,
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

  /// Switch group with integrated navigation and workspace state update
  ///
  /// Combines navigationStateProvider.switchGroup() and workspaceStateProvider.enterWorkspace()
  /// into a single operation for group switching from UI components like GroupDropdown.
  ///
  /// **Usage:**
  /// ```dart
  /// await ref.read(workspaceStateProvider.notifier).switchGroupWithNavigation(
  ///   groupId: group.id,
  ///   membership: group,
  /// );
  /// ```
  ///
  /// **Benefits:**
  /// - Ensures consistent state across navigation and workspace
  /// - Simplifies group switching logic in UI components
  /// - Provides single point of failure handling
  Future<void> switchGroupWithNavigation({
    required int groupId,
    required GroupMembership membership,
  }) async {
    // 1. Update navigation state (declarative routing with context-aware switching)
    await _ref.read(navigationStateProvider.notifier).switchGroup(groupId);

    // 2. Update workspace state (compatibility with existing workspace logic)
    await enterWorkspace(groupId.toString(), membership: membership);
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

    // ✅ 모바일 UX 조정: 그룹 전환 시 mobileView가 channelList이면 currentView를 channel로 설정
    // ⚠️ FIX: 모바일에서만 적용 (데스크톱은 groupHome 유지)
    WorkspaceView adjustedView = finalView;
    if (!kIsWeb &&
        !isSameGroup &&
        finalMobileView == MobileWorkspaceView.channelList) {
      // 그룹 전환 시 모바일의 기본 뷰는 채널 리스트
      // 특수 뷰(calendar, admin 등)가 아니면 channel 뷰로 강제
      if (targetView == null || targetView == WorkspaceView.groupHome) {
        adjustedView = WorkspaceView.channel;
      }
    }

    // Determine if channel should be auto-selected
    final String? autoSelectChannelId =
        channelId ?? snapshot?.selectedChannelId;

    return _NavigationTarget(
      finalView: adjustedView,
      finalMobileView: finalMobileView,
      autoSelectChannelId: autoSelectChannelId,
    );
  }

  /// Update state with determined navigation target
  void _updateStateForNavigation({
    required String groupId,
    required GroupMembership membership,
    required _NavigationTarget navigationTarget,
    required WorkspaceSnapshot? snapshot,
    required bool isSameGroup,
  }) {
    final hasMobileState = state.mobileView != MobileWorkspaceView.channelList;

    state = state.copyWith(
      selectedGroupId: groupId,
      selectedGroup: membership,
      selectedChannelId: hasMobileState
          ? state.selectedChannelId
          : snapshot?.selectedChannelId,
      isCommentsVisible: hasMobileState
          ? state.isCommentsVisible
          : (snapshot?.isCommentsVisible ?? false),
      selectedPostId: hasMobileState
          ? state.selectedPostId
          : snapshot?.selectedPostId,
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
    final hasAnyPermission = PermissionUtils.hasAnyGroupManagementPermission(
      permissions,
    );
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

    // 2. Load permissions and read position BEFORE updating state
    // This ensures PostList has read position data when it initializes
    final channelIdInt = int.tryParse(channelId);
    if (channelIdInt != null) {
      await Future.wait([
        loadChannelPermissions(channelId),
        loadReadPosition(channelIdInt),
      ]);
    } else {
      await loadChannelPermissions(channelId);
    }

    // 3. NOW update state (after data is loaded)
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
      clearCurrentVisiblePostId:
          true, // Clear visible post when switching channels
      workspaceContext: Map.from(state.workspaceContext)
        ..['channelId'] = channelId
        ..['channelName'] = selectedChannel.name,
    );

    // LocalStorage에 저장
    _saveToLocalStorage();
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

    // ✅ Always update state, even if position is null (marks channel as "loaded")
    // This prevents PostList from waiting with timeout when entering a new channel
    state = state.copyWith(
      lastReadPostIdMap: {
        ...state.lastReadPostIdMap,
        channelId:
            position?.lastReadPostId ??
            -1, // -1 = new channel or no read history
      },
    );
  }

  /// Save read position for a channel
  /// Best-effort operation - errors are ignored
  ///
  /// Note: Badge update (unread count) is NOT performed here.
  /// It should be manually called when leaving the channel (selectChannel, exitWorkspace)
  Future<void> saveReadPosition(int channelId, int postId) async {
    // 안전장치: 로그아웃 중에는 저장하지 않음
    final isLoggingOut = _ref.read(authProvider).isLoggingOut;
    if (isLoggingOut) {
      if (kDebugMode) {
        developer.log(
          '읽음 위치 저장 스킵 (로그아웃 중) - 채널: $channelId',
          name: 'WorkspaceState',
        );
      }
      return;
    }

    // API call (Best-Effort, error ignored)
    try {
      await _channelService.updateReadPosition(channelId, postId);

      if (kDebugMode) {
        developer.log(
          '✅ 읽음 위치 저장 완료 - 채널: $channelId, 게시글: $postId',
          name: 'WorkspaceState',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log(
          '⚠️ 읽음 위치 저장 실패 (무시) - 채널: $channelId, 에러: $e',
          name: 'WorkspaceState',
        );
      }
      // Best-Effort: 에러 무시
    }

    // Update local state
    state = state.copyWith(
      lastReadPostIdMap: {...state.lastReadPostIdMap, channelId: postId},
    );

    // Badge update is NOT performed here - it should be done when leaving channel
  }

  /// Update currently visible post ID (called during scrolling)
  void updateCurrentVisiblePost(int postId) {
    state = state.copyWith(currentVisiblePostId: postId);

    // ✅ 웹 환경에서 즉시 동기 업데이트 (beforeunload 타이밍 보장)
    if (kIsWeb) {
      _updateJsReadPositionCacheSync(postId);
    }
  }

  /// 웹 전용: JS 캐시를 동기적으로 업데이트 (beforeunload 타이밍 보장)
  ///
  /// 스크롤 시 즉시 호출되어 JS 전역 변수를 업데이트합니다.
  /// 브라우저 닫기/새로고침 시 beforeunload 이벤트가 이 캐시를 읽어
  /// sendBeacon으로 서버에 전송합니다.
  void _updateJsReadPositionCacheSync(int postId) {
    if (!kIsWeb) return;

    try {
      final channelId = state.selectedChannelId;
      if (channelId == null) {
        if (kDebugMode) {
          developer.log(
            '⚠️ JS 캐시 업데이트 스킵 - channelId null',
            name: 'WorkspaceState',
          );
        }
        return;
      }

      // API base URL
      final apiBaseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8080';

      // ✅ 웹 유틸리티를 통해 JS 캐시 업데이트 (조건부 import)
      web_utils.updateReadPositionCache(
        channelId: channelId,
        postId: postId,
        apiBaseUrl: apiBaseUrl,
      );

      if (kDebugMode) {
        developer.log(
          '🔄 JS 캐시 동기 업데이트 - 채널: $channelId, 게시글: $postId',
          name: 'WorkspaceState',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('⚠️ JS 캐시 동기 업데이트 실패 - $e', name: 'WorkspaceState');
      }
    }
  }

  /// Load unread count for a single channel
  Future<void> loadUnreadCount(int channelId) async {
    final count = await _channelService.getUnreadCount(channelId);

    state = state.copyWith(
      unreadCountMap: {...state.unreadCountMap, channelId: count},
    );
  }

  /// Load unread counts for multiple channels (batch query)
  Future<void> loadUnreadCounts(List<int> channelIds) async {
    final counts = await _channelService.getUnreadCounts(channelIds);

    state = state.copyWith(
      unreadCountMap: {...state.unreadCountMap, ...counts},
    );
  }

  /// Helper: Save read position for current channel before leaving
  ///
  /// 채널 이탈 시 읽음 위치 저장 + 배지 업데이트를 수행합니다.
  /// Best-Effort 방식으로 에러는 무시됩니다.
  Future<void> _saveReadPositionForCurrentChannel() async {
    final currentChannelId = state.selectedChannelId;
    if (currentChannelId != null && state.currentVisiblePostId != null) {
      final channelIdInt = int.tryParse(currentChannelId);
      if (channelIdInt != null) {
        try {
          await saveReadPosition(channelIdInt, state.currentVisiblePostId!);

          // ✅ 이탈 시 배지 업데이트 (읽지 않은 글 개수 재계산)
          await loadUnreadCount(channelIdInt);
        } catch (e) {
          // Best-Effort: ignore errors
          if (kDebugMode) {
            developer.log(
              'Failed to save read position when leaving channel: $e',
              name: 'WorkspaceStateNotifier',
              level: 300,
            );
          }
        }
      }
    }
  }

  /// Universal view transition handler (Template Method Pattern)
  ///
  /// Automatically handles:
  /// - Read position save (best-effort)
  /// - Navigation history update
  /// - State synchronization
  ///
  /// Usage:
  /// ```dart
  /// await _transitionToView(
  ///   targetView: WorkspaceView.groupHome,
  ///   stateUpdates: {'selectedChannelId': null},
  /// );
  /// ```
  Future<void> _transitionToView({
    required WorkspaceView targetView,
    Map<String, dynamic>? stateUpdates,
  }) async {
    // Step 1: Save read position (Best-Effort)
    // MUST complete before state update to ensure data consistency
    await _saveReadPositionForCurrentChannel();

    // Step 2: Add to navigation history
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

    // Step 3: Update state
    state = _applyStateUpdates(targetView, stateUpdates);
  }

  /// Helper: Apply state updates for view transition
  WorkspaceState _applyStateUpdates(
    WorkspaceView targetView,
    Map<String, dynamic>? updates,
  ) {
    return state.copyWith(
      previousView: state.currentView,
      currentView: targetView,
      selectedChannelId: updates?['selectedChannelId'] as String?,
      isCommentsVisible: updates?['isCommentsVisible'] as bool? ?? false,
      selectedPostId: updates?['selectedPostId'] as String?,
      isNarrowDesktopCommentsFullscreen:
          updates?['isNarrowDesktopCommentsFullscreen'] as bool? ?? false,
      selectedCalendarDate: updates?['selectedCalendarDate'] as DateTime?,
      selectedPlaceId: updates?['selectedPlaceId'] as int?,
      selectedPlaceName: updates?['selectedPlaceName'] as String?,
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
  Future<void> showGroupHome() => _transitionToView(
    targetView: WorkspaceView.groupHome,
    stateUpdates: {
      'selectedChannelId': null,
      'isCommentsVisible': false,
      'selectedPostId': null,
      'isNarrowDesktopCommentsFullscreen': false,
      'selectedCalendarDate': null,
    },
  );

  /// Show calendar view
  Future<void> showCalendar({DateTime? selectedDate}) => _transitionToView(
    targetView: WorkspaceView.calendar,
    stateUpdates: {
      'selectedChannelId': null,
      'isCommentsVisible': false,
      'selectedPostId': null,
      'isNarrowDesktopCommentsFullscreen': false,
      'selectedCalendarDate': selectedDate,
    },
  );

  /// Show group admin/management page view
  Future<void> showGroupAdminPage() => _transitionToView(
    targetView: WorkspaceView.groupAdmin,
    stateUpdates: {
      'selectedChannelId': null,
      'isCommentsVisible': false,
      'selectedPostId': null,
      'isNarrowDesktopCommentsFullscreen': false,
    },
  );

  /// Show member management page view
  Future<void> showMemberManagementPage() => _transitionToView(
    targetView: WorkspaceView.memberManagement,
    stateUpdates: {
      'selectedChannelId': null,
      'isCommentsVisible': false,
      'selectedPostId': null,
      'isNarrowDesktopCommentsFullscreen': false,
    },
  );

  /// Show recruitment management page view
  Future<void> showRecruitmentManagementPage() => _transitionToView(
    targetView: WorkspaceView.recruitmentManagement,
    stateUpdates: {
      'selectedChannelId': null,
      'isCommentsVisible': false,
      'selectedPostId': null,
      'isNarrowDesktopCommentsFullscreen': false,
    },
  );

  /// Show application management page view (모집 지원자 관리)
  Future<void> showApplicationManagementPage() => _transitionToView(
    targetView: WorkspaceView.applicationManagement,
    stateUpdates: {
      'selectedChannelId': null,
      'isCommentsVisible': false,
      'selectedPostId': null,
      'isNarrowDesktopCommentsFullscreen': false,
    },
  );

  /// Show place time management page view (장소 시간 관리)
  Future<void> showPlaceTimeManagementPage(int placeId, String placeName) =>
      _transitionToView(
        targetView: WorkspaceView.placeTimeManagement,
        stateUpdates: {
          'selectedChannelId': null,
          'isCommentsVisible': false,
          'selectedPostId': null,
          'isNarrowDesktopCommentsFullscreen': false,
          'selectedPlaceId': placeId,
          'selectedPlaceName': placeName,
        },
      );

  /// Show channel management page view (채널 관리)
  Future<void> showChannelManagementPage() => _transitionToView(
    targetView: WorkspaceView.channelManagement,
    stateUpdates: {
      'selectedChannelId': null,
      'isCommentsVisible': false,
      'selectedPostId': null,
      'isNarrowDesktopCommentsFullscreen': false,
    },
  );

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

  /// 읽은 위치만 저장 (상태는 유지)
  ///
  /// 앱이 일시적으로 백그라운드로 가거나 웹 탭이 숨겨질 때 사용.
  /// 현재 보고 있던 채널 정보는 유지하면서 읽은 위치만 서버에 저장.
  Future<void> saveReadPositionOnly() async {
    final currentChannelId = state.selectedChannelId;
    if (currentChannelId != null && state.currentVisiblePostId != null) {
      final channelIdInt = int.tryParse(currentChannelId);
      if (channelIdInt != null) {
        try {
          await saveReadPosition(channelIdInt, state.currentVisiblePostId!);
          await loadUnreadCount(channelIdInt);

          if (kDebugMode) {
            developer.log(
              'Read position saved (state preserved)',
              name: 'WorkspaceStateNotifier',
            );
          }
        } catch (e) {
          if (kDebugMode) {
            developer.log(
              'Failed to save read position: $e',
              name: 'WorkspaceStateNotifier',
              level: 300,
            );
          }
        }
      }
    }
  }

  /// 워크스페이스 완전 종료 (상태 초기화)
  ///
  /// 앱이 완전히 종료되거나 사용자가 명시적으로 워크스페이스를 나갈 때 사용.
  /// 읽은 위치 저장 + 상태 초기화를 수행.
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

    // 2. Check if user returned to global home via back navigation
    // If so, clear all workspace snapshots (next workspace entry will be "first-time")
    final navigationController = _ref.read(
      navigationControllerProvider.notifier,
    );
    final isReturnToGlobalHome = navigationController.state.isAtGlobalHome;

    if (isReturnToGlobalHome) {
      // Clear all workspace snapshots - user wants fresh start
      _workspaceSnapshots.clear();

      // ✅ FIX: Keep _lastGroupId for tab restoration
      // _lastGroupId is used by sidebar/bottom navigation to restore the last visited group
      // when switching tabs (e.g., Home → Workspace). Only forceClearForLogout() should
      // clear it completely.
      // _lastGroupId = null;  // ← Removed: caused "한신대학교" reset bug on tab switch

      if (kDebugMode) {
        developer.log(
          'Cleared workspace snapshots (returned to global home), but kept _lastGroupId for tab restoration',
          name: 'WorkspaceStateNotifier',
        );
      }
    } else {
      // Normal exit: save current snapshot for later restoration
      _saveCurrentWorkspaceSnapshot();
    }

    // 3. Reset state
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

    // 2. Load permissions and read position BEFORE updating state
    // This ensures PostList has read position data when it initializes
    final channelIdInt = int.tryParse(channelId);
    if (channelIdInt != null) {
      await Future.wait([
        loadChannelPermissions(channelId),
        loadReadPosition(channelIdInt),
      ]);
    } else {
      await loadChannelPermissions(channelId);
    }

    // ✅ 2.5. Save current state (channelList) to navigation history BEFORE changing mobileView
    // This ensures back button will restore channelList step
    if (state.selectedGroupId != null) {
      _addToNavigationHistory(
        groupId: state.selectedGroupId!,
        view: state.currentView,
        mobileView: state.mobileView, // ✅ 현재 mobileView = channelList 저장
        channelId: state.selectedChannelId,
        postId: state.selectedPostId,
        isCommentsVisible: state.isCommentsVisible,
      );
    }

    // 3. NOW update state (after data is loaded)
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
      clearCurrentVisiblePostId:
          true, // Clear visible post when switching channels
      workspaceContext: Map.from(state.workspaceContext)
        ..['channelId'] = channelId
        ..['channelName'] = selectedChannel.name,
    );
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

final workspaceNavigationHistoryProvider =
    Provider<List<NavigationHistoryEntry>>((ref) {
      return ref.watch(
        workspaceStateProvider.select((state) => state.navigationHistory),
      );
    });
