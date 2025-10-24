import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/member_filter.dart';

/// 멤버 필터 상태 관리 Notifier (Phase 1: 드래프트 분리)
///
/// groupId별로 독립적인 필터 상태를 관리합니다.
/// 역할 필터와 다른 필터(그룹/학년/학번)는 상호 배타적으로 동작합니다.
///
/// 성능 최적화:
/// - state: 실제 적용된 필터 (API 호출 트리거)
/// - _draftFilter: UI 드래프트 (즉시 반영, API 호출 없음)
/// - 디바운싱 제거: 사용자가 "필터 적용" 버튼을 클릭할 때만 API 호출
class MemberFilterNotifier extends StateNotifier<MemberFilter> {
  /// 드래프트 필터 (UI 표시용)
  MemberFilter _draftFilter;

  MemberFilterNotifier()
      : _draftFilter = MemberFilter(),
        super(MemberFilter());

  /// 드래프트가 적용된 상태와 다른지 확인
  bool get isDraftDirty => _draftFilter != state;

  /// 현재 드래프트 노출
  MemberFilter get draftFilter => _draftFilter;

  /// 역할 필터 토글 (드래프트 전용, 다른 필터 초기화)
  ///
  /// 역할 선택 시 소속 그룹, 학년, 학번 필터가 모두 초기화됩니다.
  /// state는 변경하지 않음 → API 호출 안함
  void toggleRole(int roleId) {
    final current = _draftFilter.roleIds ?? [];
    final updated = current.contains(roleId)
        ? current.where((id) => id != roleId).toList()
        : [...current, roleId];

    _draftFilter = _draftFilter.copyWith(
      roleIds: updated.isEmpty ? null : updated,
      // 역할 선택 시 다른 필터 초기화
      groupIds: null,
      grades: null,
      years: null,
    );

    // 드래프트만 변경, state는 건드리지 않음
    state = state; // UI 리빌드를 위해 state 재설정
  }

  /// 소속 그룹 필터 토글 (드래프트 전용, 역할 필터 초기화)
  ///
  /// 소속 그룹 선택 시 역할 필터가 초기화됩니다.
  /// state는 변경하지 않음 → API 호출 안함
  void toggleGroup(int groupId) {
    final current = _draftFilter.groupIds ?? [];
    final updated = current.contains(groupId)
        ? current.where((id) => id != groupId).toList()
        : [...current, groupId];

    _draftFilter = _draftFilter.copyWith(
      roleIds: null, // 그룹 선택 시 역할 필터 초기화
      groupIds: updated.isEmpty ? null : updated,
    );

    // 드래프트만 변경, state는 건드리지 않음
    state = state; // UI 리빌드를 위해 state 재설정
  }

  /// 학년 필터 토글 (드래프트 전용, 학번과 OR 관계, 역할 필터 초기화)
  ///
  /// 학년 선택 시 역할 필터가 초기화됩니다.
  /// 학년과 학번은 OR 관계로 동시에 선택 가능합니다.
  /// state는 변경하지 않음 → API 호출 안함
  void toggleGrade(int grade) {
    final current = _draftFilter.grades ?? [];
    final updated = current.contains(grade)
        ? current.where((g) => g != grade).toList()
        : [...current, grade];

    _draftFilter = _draftFilter.copyWith(
      roleIds: null, // 학년 선택 시 역할 필터 초기화
      grades: updated.isEmpty ? null : updated,
    );

    // 드래프트만 변경, state는 건드리지 않음
    state = state; // UI 리빌드를 위해 state 재설정
  }

  /// 학번 필터 토글 (드래프트 전용, 학년과 OR 관계, 역할 필터 초기화)
  ///
  /// 학번 선택 시 역할 필터가 초기화됩니다.
  /// 학년과 학번은 OR 관계로 동시에 선택 가능합니다.
  /// state는 변경하지 않음 → API 호출 안함
  void toggleYear(int year) {
    final current = _draftFilter.years ?? [];
    final updated = current.contains(year)
        ? current.where((y) => y != year).toList()
        : [...current, year];

    _draftFilter = _draftFilter.copyWith(
      roleIds: null, // 학번 선택 시 역할 필터 초기화
      years: updated.isEmpty ? null : updated,
    );

    // 드래프트만 변경, state는 건드리지 않음
    state = state; // UI 리빌드를 위해 state 재설정
  }

  /// 적용 버튼 클릭 시 호출
  ///
  /// 드래프트 필터를 실제 상태로 복사하여 API 호출을 트리거합니다.
  void apply() {
    state = _draftFilter;
  }

  /// 취소 버튼 클릭 시 호출
  ///
  /// 드래프트를 현재 적용된 상태로 되돌립니다.
  void cancel() {
    _draftFilter = state;
    // UI 리빌드를 위해 state 재설정
    state = state;
  }

  /// 초기화 버튼 클릭 시 호출 (즉시 적용)
  ///
  /// 모든 필터를 초기화하고 즉시 API 호출을 트리거합니다.
  void reset() {
    state = MemberFilter();
    _draftFilter = MemberFilter();
  }
}

/// 멤버 필터 Provider (groupId별 독립 상태)
final memberFilterStateProvider =
    StateNotifierProvider.family<MemberFilterNotifier, MemberFilter, int>(
  (ref, groupId) => MemberFilterNotifier(),
);
