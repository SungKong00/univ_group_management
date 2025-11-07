import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'filter_model.dart';

/// 로컬 필터링 전용 Notifier
///
/// 특징:
/// - 드래프트 분리 없음 (상태 변경 = 즉시 UI 업데이트)
/// - API 호출 없음 (로컬 메모리에서만 필터링)
/// - 필터 변경 시 즉각 반응
/// - updateFilter() 메서드로 필터 상태 수정
/// - reset() 메서드로 초기 상태로 복원
///
/// ### 사용 예시
/// ```dart
/// class GroupExploreFilterNotifier
///     extends LocalFilterNotifier<GroupExploreFilter> {
///   GroupExploreFilterNotifier() : super(GroupExploreFilter());
///
///   void toggleGroupType(String type) {
///     updateFilter((filter) {
///       // 필터 로직
///       return filter.copyWith(...);
///     });
///   }
/// }
/// ```
///
/// ### 용도
/// - 로컬에서만 필터링하는 UI (그룹 탐색, 게시글 목록 등)
/// - API 호출이 불필요한 필터링
/// - 즉각 반응이 필요한 필터 UI
///
/// ### GenericFilterNotifier와의 차이
/// - **GenericFilterNotifier**: 드래프트 분리, apply/cancel, API 호출 (멤버 필터)
/// - **LocalFilterNotifier**: 드래프트 없음, 즉시 반영, 로컬 필터링만 (그룹 탐색)
abstract class LocalFilterNotifier<TFilter extends FilterModel>
    extends StateNotifier<TFilter> {
  /// 초기 필터 상태로 초기화
  LocalFilterNotifier(TFilter initialFilter) : super(initialFilter);

  /// 필터 상태를 업데이트합니다 (즉시 UI에 반영)
  ///
  /// 매개변수:
  /// - updater: 현재 필터 상태를 받아 새로운 필터 상태를 반환하는 함수
  ///
  /// ### 사용 예시
  /// ```dart
  /// updateFilter((filter) {
  ///   return filter.copyWith(groupTypes: ['AUTONOMOUS']);
  /// });
  /// ```
  void updateFilter(TFilter Function(TFilter) updater) {
    state = updater(state);
  }

  /// 필터를 초기 상태로 초기화합니다
  ///
  /// 매개변수:
  /// - initialFilter: 초기화할 필터 상태
  ///
  /// ### 사용 예시
  /// ```dart
  /// reset(GroupExploreFilter());
  /// ```
  void reset(TFilter initialFilter) {
    state = initialFilter;
  }
}
