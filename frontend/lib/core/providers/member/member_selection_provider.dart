/// 멤버 선택 상태 관리 Provider
///
/// Step 3 (MemberEditPage)에서 체크박스 선택 상태를 관리합니다.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 멤버 선택 상태
class MemberSelectionState {
  final Set<int> selectedMemberIds; // 선택된 멤버 ID

  MemberSelectionState({this.selectedMemberIds = const {}});

  MemberSelectionState copyWith({Set<int>? selectedMemberIds}) {
    return MemberSelectionState(
      selectedMemberIds: selectedMemberIds ?? this.selectedMemberIds,
    );
  }
}

/// 멤버 선택 상태 관리 Notifier
class MemberSelectionNotifier extends StateNotifier<MemberSelectionState> {
  MemberSelectionNotifier() : super(MemberSelectionState());

  /// 개별 멤버 토글 (선택/해제)
  void toggleMember(int memberId) {
    final updated = Set<int>.from(state.selectedMemberIds);
    if (updated.contains(memberId)) {
      updated.remove(memberId);
    } else {
      updated.add(memberId);
    }
    state = state.copyWith(selectedMemberIds: updated);
  }

  /// 현재 표시된 멤버 전체 선택
  void selectAll(List<int> memberIds) {
    final updated = Set<int>.from(state.selectedMemberIds);
    updated.addAll(memberIds);
    state = state.copyWith(selectedMemberIds: updated);
  }

  /// 현재 표시된 멤버만 선택 해제
  void deselectDisplayed(List<int> displayedIds) {
    final updated = Set<int>.from(state.selectedMemberIds);
    updated.removeAll(displayedIds);
    state = state.copyWith(selectedMemberIds: updated);
  }

  /// 초기 선택 상태 설정 (Step 2 → Step 3 전환 시)
  void initialize(List<int> memberIds) {
    state = state.copyWith(selectedMemberIds: Set.from(memberIds));
  }

  /// 선택 상태 초기화
  void clear() {
    state = state.copyWith(selectedMemberIds: {});
  }
}

/// 멤버 선택 Provider (groupId별 독립 상태)
final memberSelectionProvider = StateNotifierProvider.family
    .autoDispose<MemberSelectionNotifier, MemberSelectionState, int>(
      (ref, groupId) => MemberSelectionNotifier(),
    );
