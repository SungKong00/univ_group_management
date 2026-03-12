/// 범용 필터 모델 인터페이스
///
/// 모든 필터 모델이 구현해야 하는 공통 인터페이스입니다.
/// 이 인터페이스를 구현하면 GenericFilterNotifier와 함께 사용할 수 있습니다.
///
/// **구현 예시**:
/// ```dart
/// class MemberFilter implements FilterModel {
///   final List<int>? roleIds;
///   final List<int>? subGroupIds;
///   final int? admissionYear;
///
///   const MemberFilter({
///     this.roleIds,
///     this.subGroupIds,
///     this.admissionYear,
///   });
///
///   @override
///   bool get isActive =>
///       (roleIds?.isNotEmpty ?? false) ||
///       (subGroupIds?.isNotEmpty ?? false) ||
///       admissionYear != null;
///
///   @override
///   Map<String, dynamic> toQueryParameters() {
///     final params = <String, dynamic>{};
///     if (roleIds != null && roleIds!.isNotEmpty) {
///       params['roleIds'] = roleIds!.join(',');
///     }
///     // ... 다른 필터 추가
///     return params;
///   }
///
///   // ⚠️ 중요: Sentinel Value Pattern 사용 필수!
///   // nullable 필드를 명시적으로 null로 설정 가능해야 함 (필터 해제)
///   static const _undefined = Object();
///
///   @override
///   MemberFilter copyWith({
///     Object? roleIds = _undefined,  // 기본값: 센티널
///   }) {
///     return MemberFilter(
///       roleIds: roleIds == _undefined
///           ? this.roleIds
///           : roleIds as List<int>?,
///     );
///   }
/// }
/// ```
abstract class FilterModel {
  /// 필터가 활성화되어 있는지 확인
  ///
  /// 하나 이상의 필터 조건이 설정되어 있으면 true를 반환해야 합니다.
  bool get isActive;

  /// 필터를 API 쿼리 파라미터로 변환
  ///
  /// Repository의 getList 메서드에 전달될 파라미터 맵을 반환합니다.
  /// 예: `{'roleIds': '1,2,3', 'admissionYear': '2024'}`
  Map<String, dynamic> toQueryParameters();

  /// 필터의 복사본 생성 (부분 수정 지원)
  ///
  /// 불변성을 유지하면서 일부 필드만 변경한 새 인스턴스를 반환합니다.
  FilterModel copyWith();
}
