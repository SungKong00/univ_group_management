# 고급 상태 패턴 (Advanced State Patterns)

Unified Provider와 LocalFilterNotifier 등 고급 상태 관리 패턴입니다.

## 개요

Phase 3에서 도입된 고급 상태 관리 패턴:
- **Unified Provider**: 여러 데이터 소스 통합 제공
- **LocalFilterNotifier**: 클라이언트 사이드 필터링
- **Generic Filtering**: 재사용 가능한 필터 로직

## Unified Provider 패턴

**파일**: `frontend/lib/core/providers/unified_group_provider.dart`

### 목적

서버 API와 로컬 상태를 하나의 Provider로 통합:
- 초기 로드: API 호출
- 이후 필터/검색: 로컬 메모리에서 처리
- 상태 변화 최소화 (불필요한 리빌드 방지)

### 구조

```dart
class UnifiedGroupState {
  final List<Group> allGroups;      // 서버에서 받은 전체 데이터
  final List<Group> filteredGroups; // 필터 적용 결과
  final FilterCondition filter;     // 현재 필터 조건
  final bool isLoading;
}

class UnifiedGroupNotifier extends StateNotifier<UnifiedGroupState> {
  Future<void> fetchAll() async {
    final groups = await api.getGroups();
    state = state.copyWith(allGroups: groups, filteredGroups: groups);
  }

  void applyFilter(FilterCondition filter) {
    final filtered = _filterLocally(state.allGroups, filter);
    state = state.copyWith(filteredGroups: filtered, filter: filter);
  }
}
```

**핵심**: API 호출 1회, 이후 로컬 필터링으로 성능 향상

## LocalFilterNotifier 패턴

**파일**: `frontend/lib/core/providers/group_explore/local_filtering_provider.dart`

### 사용 시점

- 검색어 입력 (실시간 필터링)
- 정렬 기준 변경 (재정렬)
- 카테고리 토글 (즉시 반영)

### 구현 예시

```dart
class LocalFilterNotifier extends StateNotifier<LocalFilterState> {
  final List<Group> _sourceData;

  void updateSearchKeyword(String keyword) {
    final filtered = _sourceData
        .where((g) => g.name.contains(keyword))
        .toList();
    state = state.copyWith(results: filtered, keyword: keyword);
  }

  void sortBy(SortCriteria criteria) {
    final sorted = [...state.results]..sort(criteria.comparator);
    state = state.copyWith(results: sorted, sortCriteria: criteria);
  }
}
```

**장점**:
- API 호출 없이 즉시 결과 반영
- 디바운싱 불필요 (로컬 연산 빠름)

## Generic Filtering 패턴

**파일**: `frontend/lib/core/providers/generic/generic_filter_provider.dart`

### 목적

멤버, 그룹, 모집공고 등 공통 필터 로직 재사용

### 추상화

```dart
abstract class FilterCondition<T> {
  bool matches(T item);
}

class GenericFilterNotifier<T> extends StateNotifier<List<T>> {
  final List<T> _allItems;

  void applyFilter(FilterCondition<T> condition) {
    state = _allItems.where((item) => condition.matches(item)).toList();
  }
}
```

**사용 예시**:

```dart
// 멤버 필터
class MemberRoleFilter implements FilterCondition<Member> {
  final Set<int> roleIds;

  @override
  bool matches(Member member) => roleIds.contains(member.roleId);
}

// 그룹 필터
class GroupCategoryFilter implements FilterCondition<Group> {
  final Set<String> categories;

  @override
  bool matches(Group group) => categories.contains(group.category);
}
```

## 성능 최적화

### 1. 메모이제이션

필터 결과 캐싱 (동일 조건 재계산 방지):

**파일**: `frontend/lib/core/providers/member/member_list_provider.dart:80-100`

### 2. Selector 패턴

필요한 부분만 구독:

```dart
final memberCountSelector = Provider.family<int, int>((ref, groupId) {
  return ref.watch(
    unifiedMemberProvider(groupId).select((state) => state.filteredMembers.length)
  );
});
```

**효과**: filteredMembers 개수만 변경 시에만 리빌드

## 적용 현황

### 그룹 탐색 페이지
**파일**: `frontend/lib/presentation/pages/group_explore/providers/group_explore_state_provider.dart`

- Unified Provider로 그룹 목록 관리
- LocalFilterNotifier로 검색/필터링

### 멤버 관리 페이지
**파일**: `frontend/lib/core/providers/member/member_filter_provider.dart`

- API 필터링 (역할, 그룹)
- 로컬 필터링 (검색어)

## 관련 문서

- [상태 관리 기본](state-management.md) - Riverpod 기초
- [멤버 필터 고급 기능](member-filter-advanced-features.md) - Phase 2-3 구현
- [그룹 탐색 전략](../../features/group-explore-hybrid-strategy.md) - 하이브리드 페이지네이션
