import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';

class WorkspaceState extends Equatable {
  const WorkspaceState({
    this.selectedGroupId,
    this.selectedChannelId,
    this.isCommentsVisible = false,
    this.selectedPostId,
    this.workspaceContext = const {},
  });

  final String? selectedGroupId;
  final String? selectedChannelId;
  final bool isCommentsVisible;
  final String? selectedPostId;
  final Map<String, dynamic> workspaceContext;

  WorkspaceState copyWith({
    String? selectedGroupId,
    String? selectedChannelId,
    bool? isCommentsVisible,
    String? selectedPostId,
    Map<String, dynamic>? workspaceContext,
  }) {
    return WorkspaceState(
      selectedGroupId: selectedGroupId ?? this.selectedGroupId,
      selectedChannelId: selectedChannelId ?? this.selectedChannelId,
      isCommentsVisible: isCommentsVisible ?? this.isCommentsVisible,
      selectedPostId: selectedPostId ?? this.selectedPostId,
      workspaceContext: workspaceContext ?? this.workspaceContext,
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
      ];
}

class WorkspaceStateNotifier extends StateNotifier<WorkspaceState> {
  WorkspaceStateNotifier() : super(const WorkspaceState());

  void enterWorkspace(String groupId, {String? channelId}) {
    state = state.copyWith(
      selectedGroupId: groupId,
      selectedChannelId: channelId,
      isCommentsVisible: false,
      selectedPostId: null,
      workspaceContext: {
        'groupId': groupId,
        if (channelId != null) 'channelId': channelId,
      },
    );
  }

  void selectChannel(String channelId) {
    state = state.copyWith(
      selectedChannelId: channelId,
      isCommentsVisible: false,
      selectedPostId: null,
      workspaceContext: Map.from(state.workspaceContext)
        ..['channelId'] = channelId,
    );
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