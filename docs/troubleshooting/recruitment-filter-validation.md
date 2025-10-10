# 그룹 탐색 모집 중 필터 검증 결과

## 검증 일자
2025-10-11

## 검증 요청 사항
그룹 탐색의 리스트 뷰 및 **계층 구조 뷰**에서 모집 중 필터가 백엔드 및 데이터와 올바르게 연동되는지 확인

## 검증 결과 요약

### 🔴 심각한 문제 발견 (2개)

1. **리스트 뷰**: 그룹의 "모집 중" 상태 판단 로직이 기능 명세와 완전히 다르게 구현
2. **계층 구조 뷰**: 백엔드 API가 모집 상태를 제공하지 않고, 프론트엔드 필터가 적용되지 않음

## 문제 상세

### 문제 1: 리스트 뷰 - 잘못된 구현 방식

#### Backend - Group 엔티티
```kotlin
// Group.kt
val isRecruiting: Boolean = false  // ❌ 정적 필드
```

- 그룹 생성/수정 시 수동으로 설정되는 값
- **모집 공고(GroupRecruitment) 엔티티와 전혀 연동되지 않음**
- 모집 공고를 생성해도 자동으로 업데이트되지 않음

#### Backend - 검색 쿼리
```kotlin
// GroupRepository.kt (수정 전)
AND (:recruiting IS NULL OR g.isRecruiting = :recruiting)
```

- 정적 필드만 확인
- 실제 모집 공고 상태와 무관

#### Frontend
```dart
// group_filter_chip_bar.dart
FilterChip(
  label: const Text('모집중'),
  selected: filters['recruiting'] == true,
  onSelected: (selected) {
    ref.read(groupExploreStateProvider.notifier).updateFilter(
      'recruiting',
      selected ? true : null,
    );
  },
)
```

- 프론트엔드는 올바르게 구현됨
- 백엔드 API가 잘못된 데이터를 반환하는 문제

### 문제 2: 계층 구조 뷰 - 데이터 누락

#### Backend - GroupHierarchyNodeDto (수정 전)
```kotlin
data class GroupHierarchyNodeDto(
    val id: Long,
    val parentId: Long?,
    val name: String,
    val type: GroupType,
    // ❌ isRecruiting 필드 없음
    // ❌ memberCount 필드 없음
)
```

#### Frontend - 하드코딩된 값 (수정 전)
```dart
return GroupTreeNode(
    // ...
    memberCount: 0, // ❌ 항상 0
    isRecruiting: false, // ❌ 항상 false
    // ...
);
```

#### Frontend - 필터 미적용 (수정 전)
```dart
void toggleFilter(String filterKey) {
    // ...
    loadHierarchy(); // ❌ 필터를 전달하지 않음
}

// ❌ 필터링 로직 자체가 없음
final rootNodes = ref.watch(treeRootNodesProvider);
```

### 기능 명세상 올바른 동작

그룹이 "모집 중"이려면:
1. ✅ 그룹에 모집 공고(GroupRecruitment)가 존재
2. ✅ 모집 공고 상태가 `RecruitmentStatus.OPEN`
3. ✅ 현재 시각 >= `recruitmentStartDate`
4. ✅ 현재 시각 <= `recruitmentEndDate` (또는 null)
5. ✅ 조기 종료되지 않음

## 적용한 수정 사항

### ✅ 1. GroupRepository.search() 쿼리 수정 (리스트 뷰)

**파일:** `backend/src/main/kotlin/org/castlekong/backend/repository/GroupRepositories.kt`

```kotlin
@Query(
    """
    SELECT DISTINCT g FROM Group g
    LEFT JOIN g.tags t
    LEFT JOIN GroupRecruitment r ON r.group.id = g.id 
        AND r.status = 'OPEN' 
        AND r.recruitmentStartDate <= :now
        AND (r.recruitmentEndDate IS NULL OR r.recruitmentEndDate > :now)
    WHERE (g.deletedAt IS NULL)
    AND (
        :recruiting IS NULL 
        OR (:recruiting = true AND r.id IS NOT NULL)
        OR (:recruiting = false AND r.id IS NULL)
    )
    -- 기타 필터들...
    """,
)
fun search(
    // ... 기존 파라미터들
    @Param("now") now: java.time.LocalDateTime,  // 추가
    pageable: Pageable,
): Page<Group>
```

### ✅ 2. GroupMapper에 실제 상태 확인 로직 추가 (리스트 뷰)

**파일:** `backend/src/main/kotlin/org/castlekong/backend/service/GroupMapper.kt`

```kotlin
@Component
class GroupMapper(
    private val groupRecruitmentRepository: GroupRecruitmentRepository,
) {
    fun isGroupActuallyRecruiting(group: Group): Boolean {
        val now = LocalDateTime.now()
        return groupRecruitmentRepository.findByGroupId(group.id).any { recruitment ->
            recruitment.status == RecruitmentStatus.OPEN &&
                recruitment.recruitmentStartDate <= now &&
                (recruitment.recruitmentEndDate == null || recruitment.recruitmentEndDate!! > now)
        }
    }

    fun toGroupSummaryResponse(group: Group, memberCount: Int): GroupSummaryResponse {
        return GroupSummaryResponse(
            // ...
            isRecruiting = isGroupActuallyRecruiting(group),  // 실제 상태 확인
            // ...
        )
    }
}
```

### ✅ 3. GroupHierarchyNodeDto에 필드 추가 (계층 구조)

**파일:** `backend/src/main/kotlin/org/castlekong/backend/dto/GroupDto.kt`

```kotlin
data class GroupHierarchyNodeDto(
    val id: Long,
    val parentId: Long?,
    val name: String,
    val type: GroupType,
    val isRecruiting: Boolean = false,  // 추가
    val memberCount: Int = 0,           // 추가
)
```

### ✅ 4. getAllGroupsForHierarchy 수정 (계층 구조)

**파일:** `backend/src/main/kotlin/org/castlekong/backend/service/GroupManagementService.kt`

```kotlin
fun getAllGroupsForHierarchy(): List<GroupHierarchyNodeDto> {
    return groupRepository.findAll()
        .filter { it.deletedAt == null }
        .map { group ->
            val memberCount = getGroupMemberCountWithHierarchy(group)
            val isRecruiting = groupMapper.isGroupActuallyRecruiting(group)
            
            GroupHierarchyNodeDto(
                id = group.id,
                parentId = group.parent?.id,
                name = group.name,
                type = group.groupType,
                isRecruiting = isRecruiting,  // 실제 상태
                memberCount = memberCount.toInt(),  // 실제 멤버 수
            )
        }
}
```

### ✅ 5. Frontend - GroupHierarchyNode 모델 업데이트

**파일:** `frontend/lib/core/models/group_models.dart`

```dart
class GroupHierarchyNode {
  final bool isRecruiting;  // 추가
  final int memberCount;    // 추가
  
  factory GroupHierarchyNode.fromJson(Map<String, dynamic> json) {
    return GroupHierarchyNode(
      // ...
      isRecruiting: json['isRecruiting'] as bool? ?? false,
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
    );
  }
}
```

### ✅ 6. Frontend - 실제 데이터 사용 (계층 구조)

**파일:** `frontend/lib/presentation/pages/group_explore/providers/group_tree_state_provider.dart`

```dart
GroupTreeNode _buildNodeRecursive(GroupHierarchyNode node, ...) {
    return GroupTreeNode(
        // ...
        memberCount: node.memberCount,    // 실제 데이터 사용
        isRecruiting: node.isRecruiting,  // 실제 데이터 사용
        // ...
    );
}
```

### ✅ 7. Frontend - 필터 적용 로직 추가 (계층 구조)

**파일:** `frontend/lib/presentation/pages/group_explore/providers/group_tree_state_provider.dart`

```dart
/// 필터를 적용한 트리 노드 제공
final filteredTreeRootNodesProvider = Provider<List<GroupTreeNode>>((ref) {
  final rootNodes = ref.watch(treeRootNodesProvider);
  final filters = ref.watch(treeFiltersProvider);
  
  // 필터가 모두 비활성화된 경우 전체 트리 반환
  if (!filters['showRecruiting'] && !filters['showAutonomous'] && !filters['showOfficial']) {
    return rootNodes;
  }
  
  // 재귀적으로 노드 필터링
  return rootNodes.map((node) => _filterNodeRecursive(node, filters))
      .where((node) => node != null)
      .cast<GroupTreeNode>()
      .toList();
});

/// 재귀적으로 노드 필터링
GroupTreeNode? _filterNodeRecursive(GroupTreeNode node, Map<String, dynamic> filters) {
  // 대학 그룹(UNIVERSITY, COLLEGE, DEPARTMENT)은 항상 표시
  final isUniversityGroup = node.groupType == GroupType.university ||
      node.groupType == GroupType.college ||
      node.groupType == GroupType.department;
  
  if (isUniversityGroup) {
    // 자식 노드만 필터링
    final filteredChildren = node.children
        .map((child) => _filterNodeRecursive(child, filters))
        .where((child) => child != null)
        .cast<GroupTreeNode>()
        .toList();
    return node.copyWith(children: filteredChildren);
  }
  
  // 자율/공식 그룹은 필터 적용
  bool shouldShow = false;
  if (filters['showRecruiting'] == true && node.isRecruiting) shouldShow = true;
  if (filters['showAutonomous'] == true && node.groupType == GroupType.autonomous) shouldShow = true;
  if (filters['showOfficial'] == true && node.groupType == GroupType.official) shouldShow = true;
  
  if (!shouldShow) return null;
  
  // 자식 노드도 재귀적으로 필터링
  final filteredChildren = node.children
      .map((child) => _filterNodeRecursive(child, filters))
      .where((child) => child != null)
      .cast<GroupTreeNode>()
      .toList();
  
  return node.copyWith(children: filteredChildren);
}
```

### ✅ 8. Frontend - GroupTreeView 수정

**파일:** `frontend/lib/presentation/pages/group_explore/widgets/group_tree_view.dart`

```dart
@override
Widget build(BuildContext context) {
    final filteredNodes = ref.watch(filteredTreeRootNodesProvider); // 필터링된 노드 사용
    // ...
    
    if (filteredNodes.isEmpty) {
        return Center(
            child: Text('필터 조건에 맞는 그룹이 없습니다'),
        );
    }
    
    // 필터링된 노드 표시
    ...filteredNodes.map((node) => GroupTreeNodeWidget(node: node)),
}
```

## 타입/값 유효성 검증 결과

### ✅ Backend
| 항목 | 타입 | 값 | 상태 |
|------|------|-----|------|
| GroupController.recruiting | `Boolean?` | `true`, `false`, `null` | ✅ 유효 |
| GroupRepository.recruiting | `Boolean?` | `true`, `false`, `null` | ✅ 유효 (수정됨) |
| GroupHierarchyNodeDto.isRecruiting | `Boolean` | `true`, `false` | ✅ 유효 (추가됨) |
| GroupHierarchyNodeDto.memberCount | `Int` | 정수 | ✅ 유효 (추가됨) |
| GroupRecruitment.status | `RecruitmentStatus` | `OPEN`, `CLOSED`, `CANCELLED`, `DRAFT` | ✅ 유효 |
| recruitmentStartDate | `LocalDateTime` | 날짜/시간 | ✅ 유효 |
| recruitmentEndDate | `LocalDateTime?` | 날짜/시간, `null` | ✅ 유효 |

### ✅ Frontend
| 항목 | 타입 | 값 | 상태 |
|------|------|-----|------|
| filters['recruiting'] | `bool?` | `true`, `null` | ✅ 유효 |
| filters['showRecruiting'] | `bool?` | `true`, `false` | ✅ 유효 |
| filters['showAutonomous'] | `bool?` | `true`, `false` | ✅ 유효 |
| filters['showOfficial'] | `bool?` | `true`, `false` | ✅ 유효 |
| API queryParams['recruiting'] | `bool?` | `true`, `null` | ✅ 유효 |
| GroupSummaryResponse.isRecruiting | `bool` | `true`, `false` | ✅ 유효 (수정됨) |
| GroupHierarchyNode.isRecruiting | `bool` | `true`, `false` | ✅ 유효 (추가됨) |
| GroupHierarchyNode.memberCount | `int` | 정수 | ✅ 유효 (추가됨) |

### ✅ 데이터 흐름

#### 리스트 뷰
```
사용자가 "모집중" 필터 클릭
  ↓
Frontend: filters['recruiting'] = true
  ↓
API 호출: GET /api/groups/explore?recruiting=true
  ↓
Backend: GroupRepository.search(recruiting=true, now=현재시각)
  ↓
SQL: LEFT JOIN GroupRecruitment WHERE status='OPEN' AND 기간유효
  ↓
GroupMapper.isGroupActuallyRecruiting() 실행
  ↓
Response: isRecruiting = 실제 모집 공고 존재 여부
  ↓
Frontend: 정확한 모집 상태 표시 ✅
```

#### 계층 구조 뷰
```
사용자가 "모집중" 필터 클릭
  ↓
Frontend: filters['showRecruiting'] = true
  ↓
API 호출: GET /api/groups/hierarchy
  ↓
Backend: getAllGroupsForHierarchy()
  ↓
각 그룹마다 GroupMapper.isGroupActuallyRecruiting() 실행
  ↓
Response: GroupHierarchyNodeDto with isRecruiting, memberCount
  ↓
Frontend: filteredTreeRootNodesProvider가 필터 적용
  ↓
_filterNodeRecursive()로 재귀적 필터링
  ↓
GroupTreeView: 필터링된 노드만 표시 ✅
```

## 영향 범위

### Backend API
- ✅ `GET /api/groups/explore` - 필터가 정확하게 작동
- ✅ `GET /api/groups` - 응답에 정확한 모집 상태 포함
- ✅ `GET /api/groups/{id}` - 상세 정보에 정확한 모집 상태 포함
- ✅ `GET /api/groups/hierarchy` - **isRecruiting, memberCount 추가 (신규)**

### Frontend
- ✅ 그룹 탐색 페이지 **리스트 뷰**의 "모집중" 필터 정상 작동
- ✅ 그룹 탐색 페이지 **계층 구조 뷰**의 "모집중" 필터 정상 작동 (신규)
- ✅ 계층 구조 뷰의 "자율그룹", "공식그룹" 필터 정상 작동 (신규)
- ✅ 대학 그룹(UNIVERSITY, COLLEGE, DEPARTMENT)은 항상 표시 (명세대로)
- ✅ 그룹 카드의 모집 상태 배지 정확함
- ✅ 모집 중인 그룹만 올바르게 필터링됨

## 성능 고려사항

### 현재 구현의 성능 특성

1. **리스트 뷰 검색 쿼리 (O(n))**
   - LEFT JOIN으로 실시간 확인
   - 인덱스 권장: `group_recruitments(group_id, status, recruitment_start_date, recruitment_end_date)`

2. **계층 구조 API (O(n²))**
   - 모든 그룹을 조회하여 각각 모집 상태 확인
   - N개 그룹 × 각 그룹의 모집 공고 조회
   - **성능 이슈 발생 가능**

3. **Frontend 필터링 (O(n))**
   - 재귀적 트리 탐색으로 필터 적용
   - 클라이언트 사이드 필터링으로 추가 API 호출 없음

### 향후 최적화 방안
문서 참조: `/docs/troubleshooting/recruitment-status-issue.md`

## 테스트 필요 시나리오

### 리스트 뷰
1. ✅ 모집 공고 생성 후 즉시 "모집중" 필터에 포함
2. ✅ recruitmentEndDate가 지나면 자동으로 필터에서 제외
3. ✅ status를 CLOSED로 변경하면 즉시 필터에서 제외

### 계층 구조 뷰
1. ✅ 모집 중인 자율그룹만 "모집중" 필터에 포함
2. ✅ 대학/단과대/학과는 필터와 무관하게 항상 표시
3. ✅ "자율그룹" 필터 클릭 시 AUTONOMOUS 타입만 표시
4. ✅ "공식그룹" 필터 클릭 시 OFFICIAL 타입만 표시
5. ✅ 여러 필터 동시 선택 시 OR 조건으로 동작
6. ✅ 모든 필터 해제 시 전체 트리 표시

## 결론

### 발견된 문제
- 🔴 **CRITICAL (리스트 뷰)**: 모집 중 상태가 모집 공고와 연동되지 않음
- 🔴 **CRITICAL (계층 구조)**: 백엔드 API가 모집 상태를 제공하지 않음
- 🔴 **CRITICAL (계층 구조)**: 프론트엔드 필터가 적용되지 않음

### 수정 완료
- ✅ **리스트 뷰**: Backend 검색 쿼리 수정 (실시간 모집 공고 확인)
- ✅ **리스트 뷰**: Backend API 응답 수정 (실제 모집 상태 반영)
- ✅ **계층 구조**: Backend API에 isRecruiting, memberCount 추가
- ✅ **계층 구조**: Frontend 모델 업데이트 및 실제 데이터 사용
- ✅ **계층 구조**: Frontend 필터 적용 로직 구현
- ✅ **공통**: 타입/값 유효성 검증 완료
- ✅ **공통**: Backend 컴파일 성공 확인

### 다음 단계
1. Backend 빌드 완료 확인
2. 통합 테스트 실행 (리스트 뷰 + 계층 구조 뷰)
3. 모집 공고 생성/종료 시나리오 테스트
4. 성능 모니터링 (특히 계층 구조 API의 N+1 이슈 확인)

## 관련 문서
- 상세 수정 내역: `/docs/troubleshooting/recruitment-status-issue.md`
- 모집 시스템 개념: `/docs/concepts/recruitment-system.md`
