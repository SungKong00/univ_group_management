# 그룹 탐색 로컬 필터링 시스템 설계

## 목표

그룹 탐색 페이지에서 **로컬 필터링** 방식을 도입하여:
- ✅ 즉각 반응형 UX (필터 선택 시 즉시 결과 반영)
- ✅ 성능 최적화 (API 호출 1회만 수행)
- ✅ 타입 안전성 (Map → 강타입 클래스)
- ✅ 재사용 가능한 패턴 (LocalFilterNotifier)

---

## 아키텍처

### 데이터 흐름

```
[페이지 진입]
    ↓
[initialize() 호출]
    ↓
[getAllGroups() API 호출 (1회)]
    ↓
[allGroups 메모리에 캐시]
    ↓
[필터 선택]
    ↓
[로컬 필터링 (_filterGroups)]
    ↓
[groups 업데이트 (UI 반영)]
```

### 주요 컴포넌트

#### 1. LocalFilterNotifier<T> (추상 클래스)
**파일**: `lib/core/providers/generic/local_filter_notifier.dart`

로컬 필터링만 하는 범용 Notifier

```dart
abstract class LocalFilterNotifier<TFilter extends FilterModel>
    extends StateNotifier<TFilter> {
  void updateFilter(TFilter Function(TFilter) updater);
  void reset(TFilter initialFilter);
}
```

**특징**:
- 드래프트 분리 없음 (상태 변경 = 즉시 UI 업데이트)
- API 호출 없음
- 간단하고 직관적

---

#### 2. GroupExploreFilter (모델)
**파일**: `lib/core/models/group_explore_filter.dart`

필터링 조건을 정의하는 모델

```dart
class GroupExploreFilter implements FilterModel {
  final List<String>? groupTypes;     // [AUTONOMOUS, OFFICIAL, ...]
  final bool? recruiting;              // true/false/null
  final List<String>? tags;           // ["음악", "스포츠", ...]
  final String? searchQuery;          // 검색어
}
```

**메서드**:
- `toQueryParameters()`: API 쿼리 파라미터 변환
- `isActive`: 필터 활성화 여부
- `copyWith()`: 부분 수정을 위한 복사 메서드

---

#### 3. GroupExploreFilterNotifier (구현)
**파일**: `lib/core/providers/group_explore/group_explore_filter_provider.dart`

GroupExploreFilter를 관리하는 Notifier

```dart
class GroupExploreFilterNotifier
    extends LocalFilterNotifier<GroupExploreFilter> {
  void toggleGroupType(String type);
  void toggleRecruiting();
  void toggleTag(String tag);
  void setSearchQuery(String query);
}
```

---

#### 4. GroupExploreStateNotifier (리팩터링)
**파일**: `lib/presentation/pages/group_explore/providers/group_explore_state_provider.dart`

로컬 필터링을 수행하는 Notifier

```dart
class GroupExploreStateNotifier extends StateNotifier<GroupExploreState> {
  // 초기화: 모든 그룹을 한 번만 로드
  Future<void> initialize();

  // 로컬 필터링
  void applyFilter(GroupExploreFilter filter);

  // 필터링 함수
  List<GroupSummaryResponse> _filterGroups(
    List<GroupSummaryResponse> allGroups,
    GroupExploreFilter filter,
  );
}
```

**핵심 로직**:
- `allGroups`: 초기 로드된 모든 그룹 (캐시)
- `groups`: 필터링된 결과 (UI 표시)
- 필터 변경 시 `_filterGroups()` 호출 → `groups` 업데이트

---

#### 5. GroupExploreService.getAllGroups()
**파일**: `lib/core/services/group_explore_service.dart`

모든 그룹을 페이징 없이 조회

```dart
Future<List<GroupSummaryResponse>> getAllGroups() async;
```

**특징**:
- API: `GET /api/groups/all`
- 페이징 없음 (한 번에 모든 데이터)
- 초기 로딩 시에만 호출

---

### State 구조

**GroupExploreState**:
```dart
class GroupExploreState {
  final List<GroupSummaryResponse> allGroups;  // 전체 그룹 (캐시)
  final List<GroupSummaryResponse> groups;     // 필터링된 그룹
  final bool isLoading;                        // 초기 로딩 상태
  final String? errorMessage;                  // 에러 메시지
}
```

---

## 필터링 로직

### 지원하는 필터

1. **그룹 타입** (AUTONOMOUS, OFFICIAL, UNIVERSITY, COLLEGE, DEPARTMENT)
2. **모집 여부** (true/false/null)
3. **태그** (다중 선택)
4. **검색어** (그룹명 검색)

### 필터링 함수 (_filterGroups)

```dart
List<GroupSummaryResponse> _filterGroups(
  List<GroupSummaryResponse> allGroups,
  GroupExploreFilter filter,
) {
  return allGroups.where((group) {
    // groupType 필터
    if (filter.groupTypes?.isNotEmpty ?? false) {
      final groupTypeStr = group.groupType.toString().split('.').last;
      if (!filter.groupTypes!.contains(groupTypeStr)) return false;
    }

    // recruiting 필터
    if (filter.recruiting != null) {
      if (group.isRecruiting != filter.recruiting) return false;
    }

    // tags 필터
    if (filter.tags?.isNotEmpty ?? false) {
      final hasAllTags = filter.tags!
          .every((tag) => group.tags.contains(tag));
      if (!hasAllTags) return false;
    }

    // searchQuery 필터
    if (filter.searchQuery?.isNotEmpty ?? false) {
      if (!group.name
          .toLowerCase()
          .contains(filter.searchQuery!.toLowerCase())) {
        return false;
      }
    }

    return true;
  }).toList();
}
```

---

## UI 통합

### 필터 변경 감지 및 자동 로컬 필터링

**파일**: `lib/presentation/pages/group_explore/providers/group_explore_state_provider.dart:156`

```dart
final _filterApplicationProvider = Provider((ref) {
  final filter = ref.watch(groupExploreFilterProvider);
  final notifier = ref.watch(groupExploreStateProvider.notifier);
  notifier.applyFilter(filter);  // 필터 변경 시 자동으로 로컬 필터링
});
```

### 수정된 UI 컴포넌트

1. **GroupFilterChipBar**: 필터 칩 바
   - `toggleGroupType()` → groupExploreFilterProvider 호출
   - 즉시 필터 업데이트

2. **GroupSearchBar**: 검색창
   - 500ms 디바운싱
   - `setSearchQuery()` → groupExploreFilterProvider 호출

3. **GroupExploreList**: 그룹 목록
   - 무한 스크롤 제거 (모든 데이터 이미 메모리에)
   - 필터링된 groups만 표시

---

## 성능 효과

### API 호출 비교

| 상황 | Before | After | 개선 |
|------|--------|-------|------|
| 필터 선택 (3개) | 3회 | 1회 | -66% |
| 필터 변경 | 매번 호출 | 없음 | 로컬 처리 |
| 서버 부하 | 높음 | 낮음 | 초기 1회만 |

### 메모리 사용

- **전체 그룹**: ~300개 × 1KB ≈ 300KB (gzip 압축 후 ~100KB)
- **메모리 영향**: 무시할 수준
- **사용자 경험**: 초기 로드 후 완벽한 즉각 반응

---

## 재사용 가능한 패턴

### LocalFilterNotifier 패턴

다른 도메인에서도 동일하게 사용 가능:

```dart
// 예시: 게시글 필터
class PostFilter implements FilterModel {
  final List<String>? categories;
  final bool? hasComments;
  // ...
}

class PostFilterNotifier extends LocalFilterNotifier<PostFilter> {
  // 도메인별 필터링 메서드
}
```

---

## 향후 확장 가능성

1. **필터 저장**: 자주 사용하는 필터 저장
2. **필터 프리셋**: "모집중인 자율그룹" 등 프리셋 제공
3. **고급 필터**: 회원 수, 활동도 등 추가 필터
4. **검색 하이라이트**: 검색어 하이라이트 표시

---

## 요약

- ✅ **즉각 반응**: 필터 선택 시 밀리초 단위 반응
- ✅ **성능**: API 호출 1회 (초기 로드만)
- ✅ **타입 안전**: Map → 강타입 클래스
- ✅ **재사용성**: LocalFilterNotifier 패턴
- ✅ **유지보수**: 단순하고 명확한 코드 구조
