/// 멤버 필터링 모델
///
/// 역할, 소속 그룹, 학년, 학번(입학년도) 기준으로 멤버를 필터링하기 위한 모델
library;

class MemberFilter {
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
  Map<String, String> toQueryParameters() {
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
  MemberFilter copyWith({
    List<int>? roleIds,
    List<int>? groupIds,
    List<int>? grades,
    List<int>? years,
  }) {
    return MemberFilter(
      roleIds: roleIds ?? this.roleIds,
      groupIds: groupIds ?? this.groupIds,
      grades: grades ?? this.grades,
      years: years ?? this.years,
    );
  }

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
