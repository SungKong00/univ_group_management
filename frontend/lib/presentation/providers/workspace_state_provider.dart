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

/// Workspace View Type
enum WorkspaceView {
  channel, // Channel content view
  groupHome, // Group home view
  calendar, // Calendar view
  groupAdmin, // Group admin/management page view
  memberManagement, // Member management page view
  recruitmentManagement, // Recruitment management page view
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
    this.currentView = WorkspaceView.channel,
    this.mobileView = MobileWorkspaceView.channelList,
    this.hasAnyGroupPermission = false,
    this.currentGroupRole,
    this.currentGroupPermissions,
    this.isLoadingChannels = false,
    this.isLoadingWorkspace = false,
    this.errorMessage,
    this.channelPermissions,
    this.isLoadingPermissions = false,
    this.channelHistory = const [],
    this.isNarrowDesktopCommentsFullscreen =
        false, // Narrow desktop: comments fullscreen mode
    this.previousView, // Track previous view for back navigation
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
  final List<String> channelHistory; // Web-only: channel navigation history
  final bool
  isNarrowDesktopCommentsFullscreen; // Narrow desktop: when true, hide posts and show only comments
  final WorkspaceView?
  previousView; // Previous view for back navigation from special views (groupAdmin, memberManagement, etc.)

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
    List<String>? channelHistory,
    bool? isNarrowDesktopCommentsFullscreen,
    WorkspaceView? previousView,
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
      channelHistory: channelHistory ?? this.channelHistory,
      isNarrowDesktopCommentsFullscreen:
          isNarrowDesktopCommentsFullscreen ??
          this.isNarrowDesktopCommentsFullscreen,
      previousView: previousView ?? this.previousView,
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
    channelHistory,
    isNarrowDesktopCommentsFullscreen,
    previousView,
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
    this.channelHistory = const [],
  });

  final WorkspaceView view;
  final MobileWorkspaceView mobileView;
  final String? selectedChannelId;
  final String? selectedPostId;
  final bool isCommentsVisible;
  final bool isNarrowDesktopCommentsFullscreen;
  final WorkspaceView? previousView;
  final List<String> channelHistory;
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
      channelHistory: List<String>.from(state.channelHistory),
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
        WorkspaceView? restoredView;
        if (lastViewType != null) {
          try {
            restoredView = WorkspaceView.values.firstWhere(
              (v) => v.name == lastViewType,
            );
          } catch (_) {
            restoredView = WorkspaceView.channel;
          }
        }

        if (kDebugMode) {
          developer.log(
            'Restoring workspace state: group=$lastGroupId, channel=$lastChannelId, view=$lastViewType',
            name: 'WorkspaceStateNotifier',
          );
        }

        // 워크스페이스 진입 시 저장된 채널 및 뷰 복원
        await enterWorkspace(
          lastGroupId,
          channelId: lastChannelId,
        );

        // 뷰 타입 복원
        if (restoredView != null && restoredView != WorkspaceView.channel) {
          state = state.copyWith(currentView: restoredView);
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
      channelHistory: snapshot.channelHistory,
      isNarrowDesktopCommentsFullscreen:
          snapshot.isNarrowDesktopCommentsFullscreen,
      previousView: snapshot.previousView,
    );

    _lastGroupId = state.selectedGroupId;
  }

  void cacheCurrentWorkspaceState() {
    _saveCurrentWorkspaceSnapshot();
  }

  Future<void> enterWorkspace(
    String groupId, {
    String? channelId,
    GroupMembership? membership,
  }) async {
    final isSameGroup = state.selectedGroupId == groupId;
    _lastGroupId = groupId;

    if (!isSameGroup && state.selectedGroupId != null) {
      _saveCurrentWorkspaceSnapshot();
    }

    final snapshot = channelId != null ? null : _getSnapshot(groupId);
    final shouldRestoreExistingState =
        isSameGroup && channelId == null && state.channels.isNotEmpty;

    if (shouldRestoreExistingState) {
      if (snapshot != null) {
        _applySnapshot(snapshot);
      }
      return;
    }

    final hasMobileState = state.mobileView != MobileWorkspaceView.channelList;

    state = state.copyWith(
      selectedGroupId: groupId,
      selectedChannelId: hasMobileState
          ? state.selectedChannelId
          : snapshot?.selectedChannelId,
      isCommentsVisible: hasMobileState
          ? state.isCommentsVisible
          : (snapshot?.isCommentsVisible ?? false),
      selectedPostId: hasMobileState
          ? state.selectedPostId
          : snapshot?.selectedPostId,
      currentView: snapshot?.view ?? WorkspaceView.channel,
      mobileView: hasMobileState
          ? state.mobileView
          : snapshot?.mobileView ?? MobileWorkspaceView.channelList,
      channelHistory: hasMobileState ? state.channelHistory : [],
      isNarrowDesktopCommentsFullscreen: hasMobileState
          ? state.isNarrowDesktopCommentsFullscreen
          : (snapshot?.isNarrowDesktopCommentsFullscreen ?? false),
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

    try {
      final resolvedMembership =
          membership ?? await _resolveGroupMembership(groupId);

      if (resolvedMembership == null) {
        state = state.copyWith(
          isLoadingWorkspace: false,
          isLoadingChannels: false,
          channels: [],
          hasAnyGroupPermission: false,
          currentGroupPermissions: null,
          currentGroupRole: null,
          errorMessage: '그룹 정보를 불러올 수 없습니다.',
        );
        return;
      }

      await loadChannels(
        groupId,
        autoSelectChannelId: channelId ?? snapshot?.selectedChannelId,
        membership: resolvedMembership,
      );

      final restoredSnapshot = _getSnapshot(groupId);
      if (restoredSnapshot != null) {
        _applySnapshot(restoredSnapshot);
      }

      state = state.copyWith(isLoadingWorkspace: false);
    } catch (e) {
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
  }

  /// Load channels and membership information for a group
  Future<void> loadChannels(
    String groupId, {
    String? autoSelectChannelId,
    required GroupMembership membership,
  }) async {
    try {
      final groupIdInt = int.parse(groupId);

      state = state.copyWith(isLoadingChannels: true);

      // Fetch channels
      final channels = await _channelService.getChannels(groupIdInt);

      // Extract permissions from resolved membership
      final permissions = membership.permissions;
      final hasAnyPermission =
          PermissionUtils.hasAnyGroupManagementPermission(permissions);
      final currentRole = membership.role;
      final currentPermissions = permissions.toList();

      // Generate dummy unread counts (for demonstration)
      final unreadCounts = <String, int>{};
      for (var channel in channels) {
        // Randomly assign 0-5 unread messages to some channels
        if (channel.id % 3 == 0) {
          unreadCounts[channel.id.toString()] = (channel.id % 5) + 1;
        }
      }

      // Auto-select channel: prioritize passed channelId, then first channel
      String? selectedChannelId;
      if (autoSelectChannelId != null) {
        selectedChannelId = autoSelectChannelId;
      } else if (channels.isNotEmpty) {
        selectedChannelId = channels.first.id.toString();
      }

      state = state.copyWith(
        channels: channels,
        unreadCounts: unreadCounts,
        hasAnyGroupPermission: hasAnyPermission,
        currentGroupRole: currentRole,
        currentGroupPermissions: currentPermissions,
        isLoadingChannels: false,
        selectedChannelId: selectedChannelId,
        workspaceContext: Map.from(state.workspaceContext)
          ..['channelId'] = selectedChannelId,
      );

      // Auto-load permissions for the selected channel
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

  void selectChannel(String channelId) {
    // Record current channel in history (web-only)
    final newHistory = List<String>.from(state.channelHistory);

    // Add current channel to history if it exists and is different from new channel
    if (state.selectedChannelId != null &&
        state.selectedChannelId != channelId) {
      // Remove if already exists (prevent duplicates)
      newHistory.remove(state.selectedChannelId);
      // Add to end of history
      newHistory.add(state.selectedChannelId!);
    }

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
      channelHistory: newHistory,
      workspaceContext: Map.from(state.workspaceContext)
        ..['channelId'] = channelId
        ..['channelName'] = selectedChannel.name,
    );

    // LocalStorage에 저장
    _saveToLocalStorage();

    // Load permissions for the selected channel
    loadChannelPermissions(channelId);
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

  /// Show group home view
  void showGroupHome() {
    state = state.copyWith(
      previousView: state.currentView,
      currentView: WorkspaceView.groupHome,
      selectedChannelId: null,
      isCommentsVisible: false,
      selectedPostId: null,
      isNarrowDesktopCommentsFullscreen: false,
    );
  }

  /// Show calendar view
  void showCalendar() {
    state = state.copyWith(
      previousView: state.currentView,
      currentView: WorkspaceView.calendar,
      selectedChannelId: null,
      isCommentsVisible: false,
      selectedPostId: null,
      isNarrowDesktopCommentsFullscreen: false,
    );
  }

  /// Show group admin/management page view
  void showGroupAdminPage() {
    state = state.copyWith(
      previousView: state.currentView,
      currentView: WorkspaceView.groupAdmin,
      selectedChannelId: null,
      isCommentsVisible: false,
      selectedPostId: null,
      isNarrowDesktopCommentsFullscreen: false,
    );
  }

  /// Show recruitment management page view
  void showRecruitmentManagementPage() {
    state = state.copyWith(
      previousView: state.currentView,
      currentView: WorkspaceView.recruitmentManagement,
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

  void exitWorkspace() {
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
  void selectChannelForMobile(String channelId) {
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
      workspaceContext: Map.from(state.workspaceContext)
        ..['channelId'] = channelId
        ..['channelName'] = selectedChannel.name,
    );

    // Load permissions for the selected channel
    loadChannelPermissions(channelId);
  }

  // 모바일에서 댓글 보기 시 (Step 2 → Step 3)
  void showCommentsForMobile(String postId) {
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
  bool handleMobileBack() {
    // 1) 특수 뷰(그룹 관리자/멤버관리/그룹 홈/캘린더 등)에서 이전 뷰가 기록되어 있으면 우선 복원
    if (state.currentView != WorkspaceView.channel &&
        state.previousView != null) {
      final prev = state.previousView!;
      // memberManagement → groupAdmin → channel 순으로 복원되도록 previousView를 보정
      final nextPrev = prev == WorkspaceView.groupAdmin
          ? WorkspaceView.channel
          : null;
      state = state.copyWith(currentView: prev, previousView: nextPrev);
      return true;
    }

    // 2) 모바일 3단계 플로우 처리
    switch (state.mobileView) {
      case MobileWorkspaceView.postComments:
        // Step 3 → Step 2: 댓글에서 게시글 목록으로
        state = state.copyWith(
          mobileView: MobileWorkspaceView.channelPosts,
          isCommentsVisible: false,
          selectedPostId: null,
          workspaceContext: Map.from(state.workspaceContext)
            ..remove('postId')
            ..remove('commentsVisible'),
        );
        return true;
      case MobileWorkspaceView.channelPosts:
        // Step 2 → Step 1: 게시글 목록에서 채널 목록으로
        state = state.copyWith(
          mobileView: MobileWorkspaceView.channelList,
          selectedChannelId: null,
          workspaceContext: Map.from(state.workspaceContext)
            ..remove('channelId'),
        );
        return true;
      case MobileWorkspaceView.channelList:
        // Step 1: 채널 목록에서는 뒤로가기 허용 (홈으로 이동)
        return false;
    }
  }

  /// Web back navigation handling
  /// Returns: true if handled internally, false if should navigate to home
  bool handleWebBack() {
    // If in a special view (groupAdmin, memberManagement, etc.), return to previous view
    if (state.currentView != WorkspaceView.channel &&
        state.previousView != null) {
      final prev = state.previousView!;
      final nextPrev = prev == WorkspaceView.groupAdmin
          ? WorkspaceView.channel
          : null;
      state = state.copyWith(currentView: prev, previousView: nextPrev);
      return true;
    }

    // If comments are visible, close them first
    if (state.isCommentsVisible) {
      hideComments();
      return true;
    }

    // If channel history exists, go to previous channel
    if (state.channelHistory.isNotEmpty) {
      final newHistory = List<String>.from(state.channelHistory);
      final previousChannelId = newHistory.removeLast();

      state = state.copyWith(
        selectedChannelId: previousChannelId,
        channelHistory: newHistory,
        workspaceContext: Map.from(state.workspaceContext)
          ..['channelId'] = previousChannelId,
      );

      loadChannelPermissions(previousChannelId);
      return true;
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

final workspaceChannelHistoryProvider = Provider<List<String>>((ref) {
  return ref.watch(
    workspaceStateProvider.select((state) => state.channelHistory),
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
