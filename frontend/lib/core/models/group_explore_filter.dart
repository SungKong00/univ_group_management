/// 그룹 탐색 필터 모델
///
/// 그룹 목록을 필터링하기 위한 모델
/// - 그룹 타입 (자율그룹, 공식그룹, 대학, 학과 등)
/// - 모집 여부 (모집 중인 그룹만)
/// - 태그 (관심사별 필터링)
/// - 검색어 (그룹명 검색)
library;

import '../providers/generic/filter_model.dart';

class GroupExploreFilter implements FilterModel {
  final List<String>? groupTypes; // [AUTONOMOUS, OFFICIAL, UNIVERSITY, ...]
  final bool? recruiting; // true: 모집 중, false: 모집 안 함, null: 모두
  final List<String>? tags; // ["음악", "스포츠", ...]
  final String? searchQuery; // 그룹명 검색어

  GroupExploreFilter({
    this.groupTypes,
    this.recruiting,
    this.tags,
    this.searchQuery,
  });

  /// API 쿼리 파라미터로 변환 (사용 안 함, 로컬 필터링만 사용)
  @override
  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{};
    if (groupTypes?.isNotEmpty ?? false) {
      params['groupTypes'] = groupTypes;
    }
    if (recruiting != null) {
      params['recruiting'] = recruiting;
    }
    if (tags?.isNotEmpty ?? false) {
      params['tags'] = tags;
    }
    if (searchQuery?.isNotEmpty ?? false) {
      params['searchQuery'] = searchQuery;
    }
    return params;
  }

  /// 필터 활성 여부
  @override
  bool get isActive =>
      (groupTypes?.isNotEmpty ?? false) ||
      recruiting != null ||
      (tags?.isNotEmpty ?? false) ||
      (searchQuery?.isNotEmpty ?? false);

  /// 그룹 타입 필터 활성 여부
  bool get isGroupTypeFilterActive => groupTypes?.isNotEmpty ?? false;

  /// 모집 필터 활성 여부
  bool get isRecruitingFilterActive => recruiting != null;

  /// 태그 필터 활성 여부
  bool get isTagFilterActive => tags?.isNotEmpty ?? false;

  /// 검색어 활성 여부
  bool get isSearchQueryActive => searchQuery?.isNotEmpty ?? false;

  /// copyWith 메서드
  ///
  /// 불변 객체 패턴을 위한 복사 메서드
  ///
  /// **중요**: nullable 필드를 명시적으로 null로 설정하려면
  /// Sentinel Value Pattern을 사용합니다. 이를 통해 "파라미터 전달 안함"과
  /// "명시적 null 전달"을 구분할 수 있습니다.
  ///
  /// **사용 예시**:
  /// ```dart
  /// // 기존 값 유지 (파라미터 전달 안함)
  /// filter.copyWith(tags: ["음악", "스포츠"])
  ///
  /// // null로 초기화 (명시적 null 전달)
  /// filter.copyWith(groupTypes: null, recruiting: null)
  /// ```
  @override
  GroupExploreFilter copyWith({
    Object? groupTypes = _undefined,
    Object? recruiting = _undefined,
    Object? tags = _undefined,
    Object? searchQuery = _undefined,
  }) {
    return GroupExploreFilter(
      groupTypes: groupTypes == _undefined
          ? this.groupTypes
          : (groupTypes as List<String>?),
      recruiting: recruiting == _undefined
          ? this.recruiting
          : (recruiting as bool?),
      tags: tags == _undefined ? this.tags : (tags as List<String>?),
      searchQuery: searchQuery == _undefined
          ? this.searchQuery
          : (searchQuery as String?),
    );
  }

  /// undefined 센티널 값
  ///
  /// copyWith에서 "파라미터 전달 안함"을 나타내는 특수 값입니다.
  static const _undefined = Object();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! GroupExploreFilter) return false;

    return _listEquals(groupTypes, other.groupTypes) &&
        recruiting == other.recruiting &&
        _listEquals(tags, other.tags) &&
        searchQuery == other.searchQuery;
  }

  @override
  int get hashCode => Object.hash(
    _listHashCode(groupTypes),
    recruiting,
    _listHashCode(tags),
    searchQuery,
  );

  /// 리스트 비교 헬퍼
  bool _listEquals(List<String>? a, List<String>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// 리스트 해시코드 헬퍼
  int _listHashCode(List<String>? list) {
    if (list == null) return 0;
    return Object.hashAll(list);
  }
}
