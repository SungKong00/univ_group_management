/// 멤버 필터링 모델
///
/// 역할, 소속 그룹, 학년, 학번(입학년도) 기준으로 멤버를 필터링하기 위한 모델
library;

import '../providers/generic/filter_model.dart';

class MemberFilter implements FilterModel {
  final List<int>? roleIds; // 역할 ID 목록
  final List<int>? groupIds; // 소속 그룹 ID 목록
  final List<int>? grades; // 학년 목록
  final List<int>? years; // 학번(입학년도) 목록

  MemberFilter({
    this.roleIds,
    this.groupIds,
    this.grades,
    this.years,
  });

  /// API 쿼리 파라미터로 변환
  ///
  /// 예: {'roleIds': '1,2', 'grades': '2,3'}
  @override
  Map<String, dynamic> toQueryParameters() {
    final params = <String, String>{};
    if (roleIds != null && roleIds!.isNotEmpty) {
      params['roleIds'] = roleIds!.join(',');
    }
    if (groupIds != null && groupIds!.isNotEmpty) {
      params['groupIds'] = groupIds!.join(',');
    }
    if (grades != null && grades!.isNotEmpty) {
      params['grades'] = grades!.join(',');
    }
    if (years != null && years!.isNotEmpty) {
      params['years'] = years!.join(',');
    }
    return params;
  }

  /// 필터 활성 여부
  @override
  bool get isActive =>
      (roleIds?.isNotEmpty ?? false) ||
      (groupIds?.isNotEmpty ?? false) ||
      (grades?.isNotEmpty ?? false) ||
      (years?.isNotEmpty ?? false);

  /// 필터 비어있음 (반대)
  bool get isEmpty => !isActive;

  /// 역할 필터 사용 중
  bool get isRoleFilterActive => roleIds?.isNotEmpty ?? false;

  /// 소속 그룹 필터 사용 중
  bool get isGroupFilterActive => groupIds?.isNotEmpty ?? false;

  /// 학년 필터 사용 중
  bool get isGradeFilterActive => grades?.isNotEmpty ?? false;

  /// 학번 필터 사용 중
  bool get isYearFilterActive => years?.isNotEmpty ?? false;

  /// copyWith 메서드
  ///
  /// 불변 객체 패턴을 위한 복사 메서드
  ///
  /// **중요**: nullable 필드를 명시적으로 null로 설정하려면
  /// `_Wrapped<T>` 패턴을 사용합니다. 이를 통해 "파라미터 전달 안함"과
  /// "명시적 null 전달"을 구분할 수 있습니다.
  ///
  /// **사용 예시**:
  /// ```dart
  /// // 기존 값 유지 (파라미터 전달 안함)
  /// filter.copyWith(groupIds: [1, 2])
  ///
  /// // null로 초기화 (명시적 null 전달)
  /// filter.copyWith(roleIds: _Wrapped.value(null), groupIds: [1, 2])
  /// ```
  @override
  MemberFilter copyWith({
    Object? roleIds = _undefined,
    Object? groupIds = _undefined,
    Object? grades = _undefined,
    Object? years = _undefined,
  }) {
    return MemberFilter(
      roleIds: roleIds == _undefined
          ? this.roleIds
          : (roleIds as List<int>?),
      groupIds: groupIds == _undefined
          ? this.groupIds
          : (groupIds as List<int>?),
      grades: grades == _undefined
          ? this.grades
          : (grades as List<int>?),
      years: years == _undefined
          ? this.years
          : (years as List<int>?),
    );
  }

  /// undefined 센티널 값
  ///
  /// copyWith에서 "파라미터 전달 안함"을 나타내는 특수 값입니다.
  static const _undefined = Object();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MemberFilter) return false;

    return _listEquals(roleIds, other.roleIds) &&
        _listEquals(groupIds, other.groupIds) &&
        _listEquals(grades, other.grades) &&
        _listEquals(years, other.years);
  }

  @override
  int get hashCode =>
      Object.hash(
        _listHashCode(roleIds),
        _listHashCode(groupIds),
        _listHashCode(grades),
        _listHashCode(years),
      );

  /// 리스트 비교 헬퍼
  bool _listEquals(List<int>? a, List<int>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// 리스트 해시코드 헬퍼
  int _listHashCode(List<int>? list) {
    if (list == null) return 0;
    return Object.hashAll(list);
  }
}
