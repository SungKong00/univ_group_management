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
    this.hasAnyGroupPermission = false,
    this.isLoadingChannels = false,
    this.isLoadingWorkspace = false,
    this.errorMessage,
  });

  final String? selectedGroupId;
  final String? selectedChannelId;
  final bool isCommentsVisible;
  final String? selectedPostId;
  final Map<String, dynamic> workspaceContext;
  final List<Channel> channels;
  final Map<String, int> unreadCounts; // Dummy data for now
  final WorkspaceView currentView;
  final bool hasAnyGroupPermission;
  final bool isLoadingChannels;
  final bool isLoadingWorkspace;
  final String? errorMessage;

  WorkspaceState copyWith({
    String? selectedGroupId,
    String? selectedChannelId,
    bool? isCommentsVisible,
    String? selectedPostId,
    Map<String, dynamic>? workspaceContext,
    List<Channel>? channels,
    Map<String, int>? unreadCounts,
    WorkspaceView? currentView,
    bool? hasAnyGroupPermission,
    bool? isLoadingChannels,
    bool? isLoadingWorkspace,
    String? errorMessage,
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
      hasAnyGroupPermission: hasAnyGroupPermission ?? this.hasAnyGroupPermission,
      isLoadingChannels: isLoadingChannels ?? this.isLoadingChannels,
      isLoadingWorkspace: isLoadingWorkspace ?? this.isLoadingWorkspace,
      errorMessage: errorMessage,
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
        hasAnyGroupPermission,
        isLoadingChannels,
        isLoadingWorkspace,
        errorMessage,
      ];
}

class WorkspaceStateNotifier extends StateNotifier<WorkspaceState> {
  WorkspaceStateNotifier() : super(const WorkspaceState());

  final ChannelService _channelService = ChannelService();

  void enterWorkspace(String groupId, {String? channelId}) {
    // Reset state when entering a new workspace
    state = state.copyWith(
      selectedGroupId: groupId,
      selectedChannelId: null, // Will be set after channels load
      isCommentsVisible: false,
      selectedPostId: null,
      currentView: WorkspaceView.channel,
      workspaceContext: {
        'groupId': groupId,
      },
    );

    // Load channels and membership info
    // channelId will be auto-selected in loadChannels if not provided
    loadChannels(groupId, autoSelectChannelId: channelId);
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
    } catch (e) {
      state = state.copyWith(
        isLoadingChannels: false,
        channels: [],
        hasAnyGroupPermission: false,
      );
    }
  }

  void selectChannel(String channelId) {
    state = state.copyWith(
      selectedChannelId: channelId,
      isCommentsVisible: false,
      selectedPostId: null,
      currentView: WorkspaceView.channel,
      workspaceContext: Map.from(state.workspaceContext)
        ..['channelId'] = channelId,
    );
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