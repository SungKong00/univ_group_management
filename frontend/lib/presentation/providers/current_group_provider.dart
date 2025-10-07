import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/group_models.dart';
import 'workspace_state_provider.dart';
import 'my_groups_provider.dart';

/// 현재 선택된 그룹 Provider
///
/// workspaceStateProvider의 selectedGroupId를 기반으로
/// myGroupsProvider에서 해당 그룹을 찾아 반환합니다.
final currentGroupProvider = Provider<GroupMembership?>((ref) {
  // 워크스페이스 상태에서 선택된 그룹 ID 가져오기
  final workspaceState = ref.watch(workspaceStateProvider);
  final selectedGroupId = workspaceState.selectedGroupId;

  if (selectedGroupId == null) {
    return null;
  }

  // 내 그룹 목록에서 선택된 그룹 찾기
  final groupsAsync = ref.watch(myGroupsProvider);

  return groupsAsync.maybeWhen(
    data: (groups) {
      try {
        return groups.firstWhere(
          (g) => g.id.toString() == selectedGroupId,
        );
      } catch (e) {
        // 그룹을 찾지 못한 경우 null 반환
        return null;
      }
    },
    orElse: () => null,
  );
});

/// 현재 선택된 그룹 이름 Provider
///
/// currentGroupProvider를 기반으로 그룹 이름만 반환합니다.
/// UI에서 그룹 이름만 필요한 경우 이 Provider를 사용하세요.
final currentGroupNameProvider = Provider<String?>((ref) {
  final currentGroup = ref.watch(currentGroupProvider);
  return currentGroup?.name;
});
