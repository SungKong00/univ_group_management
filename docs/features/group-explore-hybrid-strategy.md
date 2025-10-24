# 그룹 탐색 하이브리드 전략 (Group Explore Hybrid Strategy)

그룹 탐색 페이지의 하이브리드 페이지네이션 전략입니다.

## 개요

서버 사이드 페이지네이션과 클라이언트 사이드 필터링을 결합한 최적화 전략:
- **초기 로드**: 서버에서 페이지 단위로 가져오기 (20개/페이지)
- **필터/검색**: 로컬 메모리에서 즉시 처리
- **추가 로드**: 무한 스크롤 또는 "더 보기" 버튼

## 전략 선택 기준

### 서버 사이드 페이지네이션

**사용 시점**:
- 전체 데이터가 많을 때 (1000개 이상)
- 초기 로딩 속도 중요
- 네트워크 대역폭 제한

**구현**: API에 `page`, `size` 파라미터 전달

### 클라이언트 사이드 필터링

**사용 시점**:
- 데이터 변경 빈도 낮음
- 실시간 검색 필요
- 서버 부하 최소화

**구현**: 로컬 메모리에서 `where()`, `contains()` 사용

## 하이브리드 구현

**파일**: `frontend/lib/core/providers/group_explore/group_explore_state_provider.dart`

### 상태 구조

```dart
class GroupExploreState {
  final List<Group> allLoadedGroups;   // 서버에서 로드한 전체 (누적)
  final List<Group> filteredGroups;    // 필터 적용 결과
  final int currentPage;               // 현재 페이지
  final bool hasMore;                  // 추가 페이지 존재 여부
  final String searchKeyword;          // 검색어
  final Set<String> selectedCategories; // 선택된 카테고리
}
```

### 초기 로드 플로우

1. API 호출: `GET /api/groups?page=0&size=20`
2. 결과 저장: `allLoadedGroups` + `filteredGroups`
3. UI 렌더링: `filteredGroups` 표시

### 필터 적용 플로우

1. 사용자 필터 선택 (카테고리, 검색어)
2. 로컬 필터링: `allLoadedGroups.where(...)`
3. 상태 업데이트: `filteredGroups` 갱신
4. **API 호출 없음** (즉시 반영)

### 추가 로드 플로우

1. 스크롤 또는 버튼 클릭
2. API 호출: `GET /api/groups?page=1&size=20`
3. 결과 누적: `allLoadedGroups += newGroups`
4. 필터 재적용: 전체 데이터에 필터 적용

## 성능 최적화

### 1. 필터 우선순위

**로컬 우선**:
- 검색어 (keyword)
- 카테고리 토글
- 정렬 기준

**서버 우선**:
- 역할 필터 (정확도 중요)
- 날짜 범위 (인덱스 활용)

### 2. 디바운싱

검색어는 300ms 디바운스 후 로컬 필터링:

**파일**: `frontend/lib/presentation/pages/group_explore/widgets/group_search_bar.dart:50-60`

### 3. 메모이제이션

동일 필터 조건 재계산 방지:

```dart
final _filterCache = <FilterCondition, List<Group>>{};

List<Group> _applyFilter(FilterCondition condition) {
  if (_filterCache.containsKey(condition)) {
    return _filterCache[condition]!;
  }
  final result = _computeFilter(condition);
  _filterCache[condition] = result;
  return result;
}
```

## UI 패턴

### 필터 칩 바

선택된 필터를 상단에 표시:

**파일**: `frontend/lib/presentation/pages/group_explore/widgets/group_filter_chip_bar.dart`

```
[카테고리: 동아리 ×] [검색: AI ×] [모두 지우기]
```

### 무한 스크롤

ListView.builder + ScrollController:

**파일**: `frontend/lib/presentation/pages/group_explore/widgets/group_explore_list.dart:80-100`

## 적용 현황

**그룹 탐색 페이지** (`group_explore_page.dart`):
- 상단: 검색 바 + 필터 칩 바
- 중앙: 그룹 목록 (무한 스크롤)
- 하단: 로딩 인디케이터

**성능 개선**:
- API 호출 감소: 80% (필터 변경 시)
- 검색 반응 속도: 즉시 (<50ms)
- 초기 로딩: 20개 제한 (빠른 FCP)

## 한계 및 주의사항

### 데이터 일관성

로컬 필터링 중 서버 데이터 변경 시 불일치 가능:
- **해결책**: 새로고침 버튼 제공 또는 일정 시간마다 자동 갱신

### 메모리 사용

누적 데이터가 많아질 경우 메모리 부담:
- **해결책**: 최대 100개 제한, 초과 시 오래된 데이터 제거

## 관련 문서

- [고급 상태 패턴](../implementation/frontend/advanced-state-patterns.md) - Unified Provider
- [멤버 필터 고급 기능](../implementation/frontend/member-filter-advanced-features.md) - 로컬 필터링
- [성능 최적화](../implementation/frontend/performance.md) - 성능 개선 전략
