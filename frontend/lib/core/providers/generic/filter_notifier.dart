import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'filter_model.dart';

/// 범용 필터 상태 관리 Notifier
///
/// 모든 도메인의 필터링 기능에 재사용 가능한 범용 Notifier입니다.
/// FilterModel을 구현한 모델과 함께 사용됩니다.
///
/// **핵심 기능**:
/// - 드래프트 분리: UI 변경사항을 즉시 반영하되 API 호출은 지연
/// - 적용/취소: 사용자가 명시적으로 적용할 때만 API 호출
/// - 초기화: 모든 필터를 빈 상태로 되돌림
///
/// **성능 최적화**:
/// - state: 실제 적용된 필터 (API 호출 트리거)
/// - _draftFilter: UI 드래프트 (즉시 반영, API 호출 없음)
///
/// **사용 예시**:
/// ```dart
/// // 1. 필터 모델 정의
/// class MemberFilter implements FilterModel {
///   final List<int>? roleIds;
///
///   MemberFilter({this.roleIds});
///
///   @override
///   bool get isActive => roleIds?.isNotEmpty ?? false;
///
///   @override
///   Map<String, dynamic> toQueryParameters() => {...};
///
///   @override
///   MemberFilter copyWith({List<int>? roleIds}) => MemberFilter(roleIds: roleIds);
/// }
///
/// // 2. Notifier 생성 (필요 시 커스텀 로직 추가)
/// class MemberFilterNotifier extends GenericFilterNotifier<MemberFilter> {
///   MemberFilterNotifier() : super(MemberFilter());
///
///   // 도메인별 특수 로직 추가 가능
///   void toggleRole(int roleId) {
///     updateDraft((filter) {
///       final current = filter.roleIds ?? [];
///       final updated = current.contains(roleId)
///           ? current.where((id) => id != roleId).toList()
///           : [...current, roleId];
///       return filter.copyWith(roleIds: updated.isEmpty ? null : updated);
///     });
///   }
/// }
///
/// // 3. Provider 등록
/// final memberFilterProvider = StateNotifierProvider.family<
///     MemberFilterNotifier, MemberFilter, int>(
///   (ref, groupId) => MemberFilterNotifier(),
/// );
/// ```
abstract class GenericFilterNotifier<TFilter extends FilterModel>
    extends StateNotifier<TFilter> {
  /// 드래프트 필터 (UI 표시용)
  TFilter _draftFilter;

  GenericFilterNotifier(super.initialFilter)
      : _draftFilter = initialFilter;

  /// 드래프트가 적용된 상태와 다른지 확인
  ///
  /// UI에서 "변경 사항 있음" 표시에 사용됩니다.
  bool get isDraftDirty => _draftFilter != state;

  /// 현재 드래프트 노출
  ///
  /// UI에서 드래프트 필터를 표시하는 데 사용됩니다.
  TFilter get draftFilter => _draftFilter;

  /// 드래프트 필터 업데이트 (API 호출 없음)
  ///
  /// [updater] 함수를 사용하여 드래프트를 수정합니다.
  /// state는 변경하지 않으므로 API 호출이 발생하지 않습니다.
  ///
  /// **사용 예시**:
  /// ```dart
  /// filterNotifier.updateDraft((filter) {
  ///   return filter.copyWith(roleIds: [1, 2, 3]);
  /// });
  /// ```
  void updateDraft(TFilter Function(TFilter) updater) {
    _draftFilter = updater(_draftFilter);
    // UI 리빌드를 강제로 트리거
    // state를 새 인스턴스로 복사하여 Riverpod가 변경을 감지하도록 함
    state = state.copyWith() as TFilter;
  }

  /// 필터 즉시 적용 (Draft 없이)
  ///
  /// 드래프트 우회하고 state를 직접 설정합니다.
  /// 단순한 필터 선택 시나리오에서 사용됩니다.
  void setFilter(TFilter filter) {
    state = filter;
    _draftFilter = filter; // Draft도 동기화
  }

  /// 적용 버튼 클릭 시 호출
  ///
  /// 드래프트 필터를 실제 상태로 복사하여 API 호출을 트리거합니다.
  /// Provider를 watch하는 모든 위젯이 재빌드됩니다.
  void apply() {
    state = _draftFilter;
  }

  /// 취소 버튼 클릭 시 호출
  ///
  /// 드래프트를 현재 적용된 상태로 되돌립니다.
  /// UI 변경사항이 모두 취소됩니다.
  void cancel() {
    _draftFilter = state;
    // UI 리빌드를 강제로 트리거
    // state를 새 인스턴스로 복사하여 Riverpod가 변경을 감지하도록 함
    state = state.copyWith() as TFilter;
  }

  /// 초기화 버튼 클릭 시 호출 (즉시 적용)
  ///
  /// 모든 필터를 초기 상태로 되돌리고 즉시 API 호출을 트리거합니다.
  ///
  /// [initialFilter] 초기 상태 (보통 빈 필터)
  void reset(TFilter initialFilter) {
    state = initialFilter;
    _draftFilter = initialFilter;
  }
}
