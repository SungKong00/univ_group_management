# 모집 중 상태 판단 로직 수정

> **⚠️ DEPRECATED (2025-10-11)**: 이 문서에서 설명하는 `is_recruiting` / `isRecruiting` 필드는 프로젝트에서 완전히 제거되었습니다.
> 모집 상태는 이제 `GroupRecruitment` 엔티티의 상태만으로 판단합니다.
> 이 문서는 과거 문제 해결 기록으로만 보관됩니다.

## 날짜
2025-10-11

## 발견된 문제

### 심각도: 🔴 CRITICAL

그룹의 "모집 중" 상태 판단 로직이 기능 명세와 완전히 다르게 구현되어 있었습니다.

### 잘못된 구현

#### 1. Group 엔티티의 정적 필드 사용
```kotlin
// Group.kt
val isRecruiting: Boolean = false  // ❌ 단순 Boolean 필드
```

**문제점:**
- 그룹 생성/수정 시 수동으로 설정되는 정적 값
- 모집 공고(GroupRecruitment)와 전혀 연동되지 않음
- 모집 공고를 만들어도 `isRecruiting`을 수동 업데이트하지 않으면 false로 유지

#### 2. 검색 쿼리가 정적 필드만 확인
```kotlin
// GroupRepository.kt (수정 전)
AND (:recruiting IS NULL OR g.isRecruiting = :recruiting)
```

## 올바른 기능 명세

그룹이 "모집 중"인 상태는 다음 조건을 **모두** 만족해야 함:

1. ✅ 그룹에 모집 공고(GroupRecruitment)가 존재
2. ✅ 모집 공고 상태가 `OPEN`
3. ✅ 현재 시각 >= `recruitmentStartDate`
4. ✅ 현재 시각 <= `recruitmentEndDate` (또는 `endDate`가 null)
5. ✅ 조기 종료되지 않음 (status != CLOSED, CANCELLED)

## 적용된 수정 사항

### 1. GroupRepository 검색 쿼리 수정

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
    -- 기타 필터 조건들...
    """,
)
fun search(
    @Param("recruiting") recruiting: Boolean?,
    @Param("groupTypes") groupTypes: List<GroupType>,
    @Param("groupTypesSize") groupTypesSize: Int,
    @Param("university") university: String?,
    @Param("college") college: String?,
    @Param("department") department: String?,
    @Param("q") q: String?,
    @Param("tags") tags: Set<String>,
    @Param("tagsSize") tagsSize: Int,
    @Param("now") now: java.time.LocalDateTime,  // 🆕 현재 시각 파라미터 추가
    pageable: Pageable,
): Page<Group>
```

**주요 변경점:**
- `GroupRecruitment` 테이블과 LEFT JOIN 추가
- JOIN 조건에 모집 공고의 활성 상태 검증 로직 포함:
  - `status = 'OPEN'`
  - `recruitmentStartDate <= :now`
  - `recruitmentEndDate IS NULL OR recruitmentEndDate > :now`
- `recruiting` 필터 조건 수정:
  - `recruiting = true`: 활성 모집 공고가 있는 그룹 (`r.id IS NOT NULL`)
  - `recruiting = false`: 활성 모집 공고가 없는 그룹 (`r.id IS NULL`)

### 2. GroupMapper에 실제 상태 확인 로직 추가

**파일:** `backend/src/main/kotlin/org/castlekong/backend/service/GroupMapper.kt`

```kotlin
@Component
class GroupMapper(
    private val groupRecruitmentRepository: GroupRecruitmentRepository,  // 🆕 의존성 추가
) {
    /**
     * 그룹의 실제 모집 중 상태를 확인
     * - 활성 모집 공고가 존재하는지 확인
     * - 모집 공고 상태가 OPEN
     * - 현재 시각이 모집 기간 내
     */
    private fun isGroupActuallyRecruiting(group: Group): Boolean {
        val now = LocalDateTime.now()
        return groupRecruitmentRepository.findByGroupId(group.id).any { recruitment ->
            recruitment.status == RecruitmentStatus.OPEN &&
                recruitment.recruitmentStartDate <= now &&
                (recruitment.recruitmentEndDate == null || recruitment.recruitmentEndDate!! > now)
        }
    }

    fun toGroupResponse(group: Group): GroupResponse {
        return GroupResponse(
            // ...
            isRecruiting = isGroupActuallyRecruiting(group),  // 🆕 실제 상태 확인
            // ...
        )
    }

    fun toGroupSummaryResponse(
        group: Group,
        memberCount: Int,
    ): GroupSummaryResponse {
        return GroupSummaryResponse(
            // ...
            isRecruiting = isGroupActuallyRecruiting(group),  // 🆕 실제 상태 확인
            // ...
        )
    }
}
```

**주요 변경점:**
- `GroupRecruitmentRepository` 의존성 주입
- `isGroupActuallyRecruiting()` 헬퍼 메서드 추가
- API 응답 DTO에서 실제 모집 공고 상태를 확인하여 `isRecruiting` 값 설정

### 3. GroupManagementService 수정

**파일:** `backend/src/main/kotlin/org/castlekong/backend/service/GroupManagementService.kt`

```kotlin
fun searchGroups(
    pageable: Pageable,
    recruiting: Boolean?,
    groupTypes: List<GroupType>,
    university: String?,
    college: String?,
    department: String?,
    q: String?,
    tags: Set<String>,
): Page<GroupSummaryResponse> {
    return groupRepository.search(
        recruiting,
        groupTypes,
        groupTypes.size,
        university,
        college,
        department,
        q,
        tags,
        tags.size,
        LocalDateTime.now(),  // 🆕 현재 시각 전달
        pageable,
    ).map { g ->
        val memberCount = getGroupMemberCountWithHierarchy(g)
        groupMapper.toGroupSummaryResponse(g, memberCount.toInt())
    }
}
```

## 영향 범위

### 백엔드 API
- ✅ `GET /api/groups/explore` - 검색 쿼리가 실제 모집 상태 반영
- ✅ `GET /api/groups` - 그룹 목록 응답에서 정확한 모집 상태 제공
- ✅ `GET /api/groups/{id}` - 그룹 상세 응답에서 정확한 모집 상태 제공

### 프론트엔드
- ✅ 그룹 탐색 페이지의 "모집중" 필터가 정확하게 작동
- ✅ 그룹 카드에 표시되는 모집 상태 배지가 정확함
- ✅ 그룹 목록/상세 페이지의 모집 상태 정보가 정확함

## 테스트 시나리오

### 1. 모집 공고 생성 후 즉시 반영
```
1. 그룹 A 생성 (isRecruiting = false in DB)
2. 그룹 A에 모집 공고 생성 (상태: OPEN, 기간: 현재~미래)
3. GET /api/groups/explore?recruiting=true 호출
4. ✅ 그룹 A가 결과에 포함되어야 함
```

### 2. 모집 기간 만료 시 자동 제외
```
1. 그룹 B에 모집 공고 생성 (기간: 과거~현재-1일)
2. GET /api/groups/explore?recruiting=true 호출
3. ✅ 그룹 B가 결과에 포함되지 않아야 함
```

### 3. 모집 조기 종료 시 즉시 반영
```
1. 그룹 C에 활성 모집 공고 존재
2. 모집 공고 상태를 CLOSED로 변경
3. GET /api/groups/explore?recruiting=true 호출
4. ✅ 그룹 C가 결과에서 제외되어야 함
```

## 주의사항

### 성능 고려사항

현재 구현은 다음과 같은 성능 특성을 가집니다:

1. **검색 쿼리 (GroupRepository.search)**
   - LEFT JOIN으로 실시간 확인
   - 인덱스 필요: `group_recruitments(group_id, status, recruitment_start_date, recruitment_end_date)`

2. **GroupMapper.isGroupActuallyRecruiting**
   - 각 그룹마다 모집 공고 조회 (N+1 가능성)
   - 대량 조회 시 성능 이슈 가능

### 향후 개선 방안

성능 최적화가 필요한 경우:

#### 방안 1: 배치 페치 조인
```kotlin
// GroupRepository에서 모집 공고를 함께 조회
@Query("""
    SELECT DISTINCT g FROM Group g
    LEFT JOIN FETCH g.recruitments r
    WHERE g.id IN :groupIds
""")
fun findWithRecruitments(groupIds: List<Long>): List<Group>
```

#### 방안 2: 스케줄러 기반 동기화
```kotlin
@Scheduled(fixedRate = 60000) // 1분마다
fun updateRecruitingStatus() {
    // 활성 모집 공고 있는 그룹 찾기
    val activeGroupIds = recruitmentRepository.findActiveRecruitments()
        .map { it.group.id }
        .toSet()
    
    // Group.isRecruiting 업데이트
    groupRepository.findAll().forEach { group ->
        val shouldBeRecruiting = group.id in activeGroupIds
        if (group.isRecruiting != shouldBeRecruiting) {
            groupRepository.save(group.copy(isRecruiting = shouldBeRecruiting))
        }
    }
}
```

## 관련 이슈
- 기능 명세: `/docs/concepts/recruitment-system.md`
- 그룹 탐색 가이드: `/docs/implementation/frontend-guide.md`

## 작성자
GitHub Copilot (AI Assistant)
