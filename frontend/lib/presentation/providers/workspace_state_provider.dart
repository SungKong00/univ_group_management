import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';
import '../../core/models/channel_models.dart';
import '../../core/services/channel_service.dart';

/// Workspace View Type
enum WorkspaceView {
  channel, // Channel content view
  groupHome, // Group home view
  calendar, // Calendar view
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
    this.isLoadingChannels = false,
    this.isLoadingWorkspace = false,
    this.errorMessage,
    this.channelPermissions,
    this.isLoadingPermissions = false,
    this.channelHistory = const [],
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
  final bool isLoadingChannels;
  final bool isLoadingWorkspace;
  final String? errorMessage;
  final ChannelPermissions? channelPermissions;
  final bool isLoadingPermissions;
  final List<String> channelHistory; // Web-only: channel navigation history

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
    bool? isLoadingChannels,
    bool? isLoadingWorkspace,
    String? errorMessage,
    ChannelPermissions? channelPermissions,
    bool? isLoadingPermissions,
    List<String>? channelHistory,
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
      hasAnyGroupPermission: hasAnyGroupPermission ?? this.hasAnyGroupPermission,
      isLoadingChannels: isLoadingChannels ?? this.isLoadingChannels,
      isLoadingWorkspace: isLoadingWorkspace ?? this.isLoadingWorkspace,
      errorMessage: errorMessage,
      channelPermissions: channelPermissions ?? this.channelPermissions,
      isLoadingPermissions: isLoadingPermissions ?? this.isLoadingPermissions,
      channelHistory: channelHistory ?? this.channelHistory,
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
        isLoadingChannels,
        isLoadingWorkspace,
        errorMessage,
        channelPermissions,
        isLoadingPermissions,
        channelHistory,
      ];
}

class WorkspaceStateNotifier extends StateNotifier<WorkspaceState> {
  WorkspaceStateNotifier() : super(const WorkspaceState());

  final ChannelService _channelService = ChannelService();

  void enterWorkspace(String groupId, {String? channelId}) {
    // 모바일 전용 상태 확인: mobileView만 체크 (웹 상태와 분리)
    final hasMobileState = state.mobileView != MobileWorkspaceView.channelList;

    // 상태 업데이트: 모바일 상태가 있으면 유지, 없으면 초기화
    state = state.copyWith(
      selectedGroupId: groupId,
      selectedChannelId: hasMobileState ? state.selectedChannelId : null,
      isCommentsVisible: hasMobileState ? state.isCommentsVisible : false,
      selectedPostId: hasMobileState ? state.selectedPostId : null,
      currentView: WorkspaceView.channel,
      mobileView: hasMobileState ? state.mobileView : MobileWorkspaceView.channelList,
      channelHistory: hasMobileState ? state.channelHistory : [],
      workspaceContext: {
        'groupId': groupId,
        if (hasMobileState && state.selectedChannelId != null)
          'channelId': state.selectedChannelId,
      },
    );

    // 최초 진입 시에만 채널 로드 (탭 전환 복귀 시에는 기존 채널 유지)
    if (!hasMobileState) {
      loadChannels(groupId, autoSelectChannelId: channelId);
    }
  }

  /// Load channels and membership information for a group
  Future<void> loadChannels(String groupId, {String? autoSelectChannelId}) async {
    try {
      final groupIdInt = int.parse(groupId);

      state = state.copyWith(isLoadingChannels: true);

      // Fetch channels and membership in parallel
      final results = await Future.wait([
        // Fetch channels directly by groupId
        _channelService.getChannels(groupIdInt),
        _channelService.getMyMembership(groupIdInt),
      ]);

      final channels = results[0] as List<Channel>;
      final membership = results[1] as MembershipInfo?;

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
        hasAnyGroupPermission: membership?.hasAnyGroupPermission ?? false,
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
      currentView: WorkspaceView.groupHome,
      isCommentsVisible: false,
      selectedPostId: null,
    );
  }

  /// Show calendar view
  void showCalendar() {
    state = state.copyWith(
      currentView: WorkspaceView.calendar,
      isCommentsVisible: false,
      selectedPostId: null,
    );
  }

  /// Show channel view
  void showChannel(String channelId) {
    selectChannel(channelId);
  }

  void showComments(String postId) {
    state = state.copyWith(
      isCommentsVisible: true,
      selectedPostId: postId,
      workspaceContext: Map.from(state.workspaceContext)
        ..['postId'] = postId
        ..['commentsVisible'] = true,
    );
  }

  void hideComments() {
    state = state.copyWith(
      isCommentsVisible: false,
      selectedPostId: null,
      workspaceContext: Map.from(state.workspaceContext)
        ..remove('postId')
        ..remove('commentsVisible'),
    );
  }

  void exitWorkspace() {
    state = const WorkspaceState();
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
    state = state.copyWith(
      errorMessage: message,
      isLoadingWorkspace: false,
    );
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

final workspaceStateProvider = StateNotifierProvider<WorkspaceStateNotifier, WorkspaceState>(
  (ref) => WorkspaceStateNotifier(),
);

// 워크스페이스 컨텍스트 관련 유틸리티 Provider들
final currentGroupIdProvider = Provider<String?>((ref) {
  return ref.watch(workspaceStateProvider.select((state) => state.selectedGroupId));
});

final currentChannelIdProvider = Provider<String?>((ref) {
  return ref.watch(workspaceStateProvider.select((state) => state.selectedChannelId));
});

final isInWorkspaceProvider = Provider<bool>((ref) {
  return ref.watch(workspaceStateProvider.select((state) => state.isInWorkspace));
});

final isCommentsVisibleProvider = Provider<bool>((ref) {
  return ref.watch(workspaceStateProvider.select((state) => state.isCommentsVisible));
});