/// FilterModel copyWith() Pattern Tests
///
/// 이 테스트는 FilterModel 구현체들이 올바른 copyWith() 패턴을 따르는지 검증합니다.
/// 특히 Sentinel Value Pattern을 사용하여 nullable 필드를 null로 설정할 수 있는지 확인합니다.
///
/// **핵심 검증 항목**:
/// 1. nullable 필드를 명시적으로 null로 설정 가능 (필터 해제)
/// 2. 파라미터 생략 시 기존 값 유지 (부분 업데이트)
/// 3. 여러 필드 동시 변경 지원
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/models/member_filter.dart';
import 'package:frontend/core/models/group_explore_filter.dart';

void main() {
  group('MemberFilter copyWith() Pattern Tests', () {
    test('nullable 필드를 null로 설정 가능 - roleIds', () {
      // Given: roleIds가 설정된 필터
      final filter = MemberFilter(roleIds: [1, 2, 3]);
      expect(filter.roleIds, [1, 2, 3]);

      // When: roleIds를 명시적으로 null로 전달
      final result = filter.copyWith(roleIds: null);

      // Then: roleIds가 null로 설정되어야 함
      expect(result.roleIds, isNull);
      expect(result.isRoleFilterActive, isFalse);
    });

    test('nullable 필드를 null로 설정 가능 - groupIds', () {
      // Given
      final filter = MemberFilter(groupIds: [4, 5, 6]);
      expect(filter.groupIds, [4, 5, 6]);

      // When
      final result = filter.copyWith(groupIds: null);

      // Then
      expect(result.groupIds, isNull);
      expect(result.isGroupFilterActive, isFalse);
    });

    test('nullable 필드를 null로 설정 가능 - grades', () {
      // Given
      final filter = MemberFilter(grades: [2, 3, 4]);
      expect(filter.grades, [2, 3, 4]);

      // When
      final result = filter.copyWith(grades: null);

      // Then
      expect(result.grades, isNull);
      expect(result.isGradeFilterActive, isFalse);
    });

    test('nullable 필드를 null로 설정 가능 - years', () {
      // Given
      final filter = MemberFilter(years: [2024, 2023]);
      expect(filter.years, [2024, 2023]);

      // When
      final result = filter.copyWith(years: null);

      // Then
      expect(result.years, isNull);
      expect(result.isYearFilterActive, isFalse);
    });

    test('파라미터 생략 시 기존 값 유지', () {
      // Given: 모든 필터가 설정된 상태
      final filter = MemberFilter(
        roleIds: [1, 2, 3],
        groupIds: [4, 5, 6],
        grades: [2, 3],
        years: [2024],
      );

      // When: roleIds만 변경하고 나머지는 생략
      final result = filter.copyWith(roleIds: [7, 8]);

      // Then: roleIds는 변경되고 나머지는 유지
      expect(result.roleIds, [7, 8]);
      expect(result.groupIds, [4, 5, 6]); // 유지됨
      expect(result.grades, [2, 3]); // 유지됨
      expect(result.years, [2024]); // 유지됨
    });

    test('여러 필드 동시 변경 - 일부는 null, 일부는 값', () {
      // Given
      final filter = MemberFilter(
        roleIds: [1, 2],
        groupIds: [3, 4],
        grades: [2],
        years: [2024],
      );

      // When: roleIds는 null로, groupIds는 새 값으로 변경
      final result = filter.copyWith(roleIds: null, groupIds: [10, 20]);

      // Then
      expect(result.roleIds, isNull); // null로 설정됨
      expect(result.groupIds, [10, 20]); // 새 값으로 변경됨
      expect(result.grades, [2]); // 유지됨
      expect(result.years, [2024]); // 유지됨
    });

    test('모든 필터를 null로 초기화', () {
      // Given: 모든 필터가 설정된 상태
      final filter = MemberFilter(
        roleIds: [1, 2],
        groupIds: [3, 4],
        grades: [2, 3],
        years: [2024],
      );
      expect(filter.isActive, isTrue);

      // When: 모든 필터를 null로 설정
      final result = filter.copyWith(
        roleIds: null,
        groupIds: null,
        grades: null,
        years: null,
      );

      // Then: 모든 필터가 비활성화됨
      expect(result.roleIds, isNull);
      expect(result.groupIds, isNull);
      expect(result.grades, isNull);
      expect(result.years, isNull);
      expect(result.isActive, isFalse);
      expect(result.isEmpty, isTrue);
    });

    test('빈 리스트 vs null 구분', () {
      // Given
      final filter = MemberFilter(roleIds: []);

      // When: null로 변경
      final result = filter.copyWith(roleIds: null);

      // Then
      expect(filter.roleIds, isEmpty); // 빈 리스트
      expect(result.roleIds, isNull); // null
      expect(filter.isRoleFilterActive, isFalse); // 빈 리스트도 비활성
      expect(result.isRoleFilterActive, isFalse); // null도 비활성
    });
  });

  group('GroupExploreFilter copyWith() Pattern Tests', () {
    test('nullable 필드를 null로 설정 가능 - groupTypes', () {
      // Given
      final filter = GroupExploreFilter(groupTypes: ['자율그룹', '공식그룹']);
      expect(filter.groupTypes, ['자율그룹', '공식그룹']);

      // When
      final result = filter.copyWith(groupTypes: null);

      // Then
      expect(result.groupTypes, isNull);
      expect(result.isGroupTypeFilterActive, isFalse);
    });

    test('nullable 필드를 null로 설정 가능 - recruiting', () {
      // Given
      final filter = GroupExploreFilter(recruiting: true);
      expect(filter.recruiting, isTrue);

      // When
      final result = filter.copyWith(recruiting: null);

      // Then
      expect(result.recruiting, isNull);
      expect(result.isRecruitingFilterActive, isFalse);
    });

    test('nullable 필드를 null로 설정 가능 - tags', () {
      // Given
      final filter = GroupExploreFilter(tags: ['음악', '스포츠']);
      expect(filter.tags, ['음악', '스포츠']);

      // When
      final result = filter.copyWith(tags: null);

      // Then
      expect(result.tags, isNull);
      expect(result.isTagFilterActive, isFalse);
    });

    test('nullable 필드를 null로 설정 가능 - searchQuery', () {
      // Given
      final filter = GroupExploreFilter(searchQuery: '축구');
      expect(filter.searchQuery, '축구');

      // When
      final result = filter.copyWith(searchQuery: null);

      // Then
      expect(result.searchQuery, isNull);
      expect(result.isSearchQueryActive, isFalse);
    });

    test('파라미터 생략 시 기존 값 유지', () {
      // Given
      final filter = GroupExploreFilter(
        groupTypes: ['자율그룹'],
        recruiting: true,
        tags: ['음악'],
        searchQuery: '밴드',
      );

      // When: tags만 변경하고 나머지는 생략
      final result = filter.copyWith(tags: ['스포츠']);

      // Then
      expect(result.groupTypes, ['자율그룹']); // 유지됨
      expect(result.recruiting, isTrue); // 유지됨
      expect(result.tags, ['스포츠']); // 변경됨
      expect(result.searchQuery, '밴드'); // 유지됨
    });

    test('여러 필드 동시 변경 - 일부는 null, 일부는 값', () {
      // Given
      final filter = GroupExploreFilter(
        groupTypes: ['자율그룹'],
        recruiting: true,
        tags: ['음악'],
        searchQuery: '밴드',
      );

      // When
      final result = filter.copyWith(
        groupTypes: null,
        recruiting: false,
        tags: null,
      );

      // Then
      expect(result.groupTypes, isNull); // null로 설정됨
      expect(result.recruiting, isFalse); // 새 값으로 변경됨
      expect(result.tags, isNull); // null로 설정됨
      expect(result.searchQuery, '밴드'); // 유지됨
    });

    test('모든 필터를 null로 초기화', () {
      // Given
      final filter = GroupExploreFilter(
        groupTypes: ['자율그룹'],
        recruiting: true,
        tags: ['음악'],
        searchQuery: '밴드',
      );
      expect(filter.isActive, isTrue);

      // When
      final result = filter.copyWith(
        groupTypes: null,
        recruiting: null,
        tags: null,
        searchQuery: null,
      );

      // Then
      expect(result.groupTypes, isNull);
      expect(result.recruiting, isNull);
      expect(result.tags, isNull);
      expect(result.searchQuery, isNull);
      expect(result.isActive, isFalse);
    });

    test('Boolean 필드 - true/false/null 구분', () {
      // Given
      final filter = GroupExploreFilter(recruiting: true);

      // When/Then: true → false
      final toFalse = filter.copyWith(recruiting: false);
      expect(toFalse.recruiting, isFalse);
      expect(toFalse.isRecruitingFilterActive, isTrue); // false도 활성 상태

      // When/Then: false → null
      final toNull = toFalse.copyWith(recruiting: null);
      expect(toNull.recruiting, isNull);
      expect(toNull.isRecruitingFilterActive, isFalse); // null만 비활성

      // When/Then: null → true
      final toTrue = toNull.copyWith(recruiting: true);
      expect(toTrue.recruiting, isTrue);
      expect(toTrue.isRecruitingFilterActive, isTrue);
    });
  });

  group('FilterModel Common Behavior Tests', () {
    test('isActive는 하나 이상의 필터 설정 시 true', () {
      // MemberFilter
      expect(MemberFilter().isActive, isFalse);
      expect(MemberFilter(roleIds: [1]).isActive, isTrue);
      expect(MemberFilter(groupIds: [1]).isActive, isTrue);
      expect(MemberFilter(grades: [1]).isActive, isTrue);
      expect(MemberFilter(years: [2024]).isActive, isTrue);

      // GroupExploreFilter
      expect(GroupExploreFilter().isActive, isFalse);
      expect(GroupExploreFilter(groupTypes: ['자율그룹']).isActive, isTrue);
      expect(GroupExploreFilter(recruiting: true).isActive, isTrue);
      expect(GroupExploreFilter(tags: ['음악']).isActive, isTrue);
      expect(GroupExploreFilter(searchQuery: '축구').isActive, isTrue);
    });

    test('toQueryParameters는 설정된 필터만 포함', () {
      // MemberFilter
      final memberFilter = MemberFilter(
        roleIds: [1, 2],
        groupIds: null,
        grades: [3],
        years: null,
      );
      final memberParams = memberFilter.toQueryParameters();
      expect(memberParams.containsKey('roleIds'), isTrue);
      expect(memberParams.containsKey('groupIds'), isFalse);
      expect(memberParams.containsKey('grades'), isTrue);
      expect(memberParams.containsKey('years'), isFalse);

      // GroupExploreFilter
      final groupFilter = GroupExploreFilter(
        groupTypes: ['자율그룹'],
        recruiting: null,
        tags: null,
        searchQuery: '축구',
      );
      final groupParams = groupFilter.toQueryParameters();
      expect(groupParams.containsKey('groupTypes'), isTrue);
      expect(groupParams.containsKey('recruiting'), isFalse);
      expect(groupParams.containsKey('tags'), isFalse);
      expect(groupParams.containsKey('searchQuery'), isTrue);
    });
  });
}
