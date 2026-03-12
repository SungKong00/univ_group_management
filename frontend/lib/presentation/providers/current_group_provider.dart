import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/group_models.dart';
import 'workspace_state_provider.dart';

/// 현재 선택된 그룹 Provider
///
/// workspaceStateProvider의 selectedGroup을 직접 반환합니다.
///
/// **세션 기반 상태 유지:**
/// - WorkspaceState에 selectedGroup이 직접 저장되므로 myGroupsProvider
///   rebuild 시에도 안정적으로 유지됩니다.
/// - 글로벌 네비게이션으로 탭 전환 시 그룹 선택 상태가 메모리에 유지됩니다.
/// - 그룹 정보 변경 시 자동으로 동기화됩니다 (WorkspaceStateNotifier의 ref.listen).
///
/// **이전 구현과의 차이:**
/// - 이전: selectedGroupId → myGroupsProvider에서 검색 (불안정)
/// - 현재: selectedGroup 직접 읽기 (안정적)
final currentGroupProvider = Provider<GroupMembership?>((ref) {
  return ref.watch(
    workspaceStateProvider.select((state) => state.selectedGroup),
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
