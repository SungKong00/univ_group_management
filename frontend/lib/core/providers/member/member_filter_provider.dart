import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/member_filter.dart';
import '../generic/filter_notifier.dart';

/// 멤버 필터 상태 관리 Notifier
///
/// GenericFilterNotifier를 상속하여 멤버 도메인별 특수 로직을 추가합니다.
/// groupId별로 독립적인 필터 상태를 관리합니다.
/// 역할 필터와 다른 필터(그룹/학년/학번)는 상호 배타적으로 동작합니다.
///
/// **범용 기능 (GenericFilterNotifier 제공)**:
/// - 드래프트 분리 (updateDraft)
/// - 적용/취소/초기화 (apply/cancel/reset)
/// - 더티 체크 (isDraftDirty)
///
/// **멤버별 특수 기능 (이 클래스 제공)**:
/// - toggleRole: 역할 필터 토글 + 다른 필터 초기화
/// - toggleGroup: 그룹 필터 토글 + 역할 필터 초기화
/// - toggleGrade: 학년 필터 토글 + 역할 필터 초기화
/// - toggleYear: 학번 필터 토글 + 역할 필터 초기화
class MemberFilterNotifier extends GenericFilterNotifier<MemberFilter> {
  MemberFilterNotifier() : super(MemberFilter());

  /// 역할 필터 토글 (드래프트 전용, 다른 필터 초기화)
  ///
  /// 역할 선택 시 소속 그룹, 학년, 학번 필터가 모두 초기화됩니다.
  /// state는 변경하지 않음 → API 호출 안함
  void toggleRole(int roleId) {
    updateDraft((filter) {
      final current = filter.roleIds ?? [];
      final updated = current.contains(roleId)
          ? current.where((id) => id != roleId).toList()
          : [...current, roleId];

      return filter.copyWith(
        roleIds: updated.isEmpty ? null : updated,
        // 역할 선택 시 다른 필터 초기화
        groupIds: null,
        grades: null,
        years: null,
      );
    });
  }

  /// 소속 그룹 필터 토글 (드래프트 전용, 역할 필터 초기화)
  ///
  /// 소속 그룹 선택 시 역할 필터가 초기화됩니다.
  /// state는 변경하지 않음 → API 호출 안함
  void toggleGroup(int groupId) {
    updateDraft((filter) {
      final current = filter.groupIds ?? [];
      final updated = current.contains(groupId)
          ? current.where((id) => id != groupId).toList()
          : [...current, groupId];

      return filter.copyWith(
        roleIds: null, // 그룹 선택 시 역할 필터 초기화
        groupIds: updated.isEmpty ? null : updated,
      );
    });
  }

  /// 학년 필터 토글 (드래프트 전용, 학번과 OR 관계, 역할 필터 초기화)
  ///
  /// 학년 선택 시 역할 필터가 초기화됩니다.
  /// 학년과 학번은 OR 관계로 동시에 선택 가능합니다.
  /// state는 변경하지 않음 → API 호출 안함
  void toggleGrade(int grade) {
    updateDraft((filter) {
      final current = filter.grades ?? [];
      final updated = current.contains(grade)
          ? current.where((g) => g != grade).toList()
          : [...current, grade];

      return filter.copyWith(
        roleIds: null, // 학년 선택 시 역할 필터 초기화
        grades: updated.isEmpty ? null : updated,
      );
    });
  }

  /// 학번 필터 토글 (드래프트 전용, 학년과 OR 관계, 역할 필터 초기화)
  ///
  /// 학번 선택 시 역할 필터가 초기화됩니다.
  /// 학년과 학번은 OR 관계로 동시에 선택 가능합니다.
  /// state는 변경하지 않음 → API 호출 안함
  void toggleYear(int year) {
    updateDraft((filter) {
      final current = filter.years ?? [];
      final updated = current.contains(year)
          ? current.where((y) => y != year).toList()
          : [...current, year];

      return filter.copyWith(
        roleIds: null, // 학번 선택 시 역할 필터 초기화
        years: updated.isEmpty ? null : updated,
      );
    });
  }
}

/// 멤버 필터 Provider (groupId별 독립 상태)
final memberFilterStateProvider =
    StateNotifierProvider.family<MemberFilterNotifier, MemberFilter, int>(
      (ref, groupId) => MemberFilterNotifier(),
    );
