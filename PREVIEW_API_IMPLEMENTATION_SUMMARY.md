# 멤버 선택 Preview API 구현 완료 (2025-10-26)

## 개요

멤버 선택 플로우 Step 2에서 DYNAMIC/STATIC 카드를 표시하기 위한 Preview API를 구현했습니다.

**목적**: 필터 조건에 해당하는 멤버 수와 샘플 목록(최대 3명)을 미리 조회하여 사용자에게 선택 옵션 제시

## 구현 내용

### 1. DTO 생성 (Phase 1)

**파일**: `/backend/src/main/kotlin/org/castlekong/backend/dto/GroupDto.kt`

```kotlin
// 멤버 선택 Preview API용 DTO
data class MemberPreviewResponse(
    val totalCount: Int,
    val samples: List<MemberPreviewDto>,
)

data class MemberPreviewDto(
    val id: Long,
    val name: String,
    val grade: Int?,
    val year: Int?,
    val roleName: String,
)
```

**특징**:
- `totalCount`: 필터 조건에 해당하는 전체 멤버 수
- `samples`: 최대 3명의 샘플 멤버 정보
- `year`: studentNo에서 자동 추출 (예: "2024001" → 24)

### 2. Mapper 확장 (Phase 1)

**파일**: `/backend/src/main/kotlin/org/castlekong/backend/service/GroupMapper.kt`

```kotlin
fun toMemberPreviewDto(groupMember: GroupMember): MemberPreviewDto {
    val user = groupMember.user
    // studentNo에서 year 추출 (예: "2024001" -> 24)
    val year = user.studentNo?.take(4)?.toIntOrNull()?.let { it % 100 }
    return MemberPreviewDto(
        id = groupMember.id,
        name = user.name,
        grade = user.academicYear,
        year = year,
        roleName = groupMember.role.name,
    )
}
```

### 3. Repository 확장 (Phase 2)

**파일**: `/backend/src/main/kotlin/org/castlekong/backend/repository/GroupRepositories.kt`

```kotlin
// 멤버 선택 Preview API용 메서드
@Query(
    """
    SELECT DISTINCT gm FROM GroupMember gm
    JOIN FETCH gm.user
    JOIN FETCH gm.role
    WHERE gm.id IN :ids
    ORDER BY gm.joinedAt DESC
""",
)
fun findByIdsWithDetailsForPreview(
    @Param("ids") ids: List<Long>,
): List<GroupMember>
```

**최적화**:
- N+1 문제 방지를 위한 JOIN FETCH 사용
- ID 기반 조회로 샘플 데이터만 효율적으로 로드

### 4. Service 레이어 구현 (Phase 3)

**파일**: `/backend/src/main/kotlin/org/castlekong/backend/service/GroupMemberService.kt`

```kotlin
fun previewMembers(
    groupId: Long,
    roleIds: String?,
    groupIds: String?,
    grades: String?,
    years: String?,
): MemberPreviewResponse {
    // 그룹 존재 여부 확인
    if (!groupRepository.existsById(groupId)) {
        throw BusinessException(ErrorCode.GROUP_NOT_FOUND)
    }

    // 파라미터 파싱
    val roleIdList = parseToLongList(roleIds)
    val groupIdList = parseToLongList(groupIds)
    val gradeList = parseToIntList(grades)
    val yearList = parseToStringList(years)

    // Specification 생성 (기존 필터 로직 재사용)
    val spec = GroupMemberSpecification.filterMembers(
        groupId = groupId,
        roleIds = roleIdList,
        groupIds = groupIdList,
        grades = gradeList,
        years = yearList,
    )

    // COUNT 쿼리 실행
    val totalCount = groupMemberRepository.count(spec).toInt()

    // 샘플 3명 조회 (ID만 먼저 조회)
    val samplePageable = PageRequest.of(0, 3)
    val sampleIds = groupMemberRepository.findAll(spec, samplePageable).map { it.id }.content

    // 샘플 데이터 JOIN FETCH로 조회
    val samples = if (sampleIds.isNotEmpty()) {
        groupMemberRepository.findByIdsWithDetailsForPreview(sampleIds)
            .map { groupMapper.toMemberPreviewDto(it) }
    } else {
        emptyList()
    }

    return MemberPreviewResponse(
        totalCount = totalCount,
        samples = samples,
    )
}
```

**특징**:
- 기존 `GroupMemberSpecification` 필터 로직 재사용
- 2단계 쿼리 최적화: COUNT → ID 조회 → 상세 조회
- 최대 3개 샘플 제한 (`PageRequest.of(0, 3)`)

### 5. Controller 엔드포인트 (Phase 4)

**파일**: `/backend/src/main/kotlin/org/castlekong/backend/controller/GroupController.kt`

```kotlin
@GetMapping("/{groupId}/members/preview")
@PreAuthorize("@security.isGroupMember(#groupId)")
@io.swagger.v3.oas.annotations.Operation(
    summary = "멤버 선택 Preview (필터 미리보기)",
    description = "필터 조건에 맞는 멤버 수와 샘플 3명을 조회합니다. 멤버 선택 플로우 Step 2에서 DYNAMIC/STATIC 카드 표시에 사용됩니다. 권한 요구사항: 그룹 멤버",
)
fun previewMembers(
    @PathVariable groupId: Long,
    @RequestParam(required = false) roleIds: String?,
    @RequestParam(required = false) groupIds: String?,
    @RequestParam(required = false) grades: String?,
    @RequestParam(required = false) years: String?,
): ApiResponse<MemberPreviewResponse> {
    val preview = groupMemberService.previewMembers(groupId, roleIds, groupIds, grades, years)
    return ApiResponse.success(preview)
}
```

**API 명세**:
- **Endpoint**: `GET /api/groups/{groupId}/members/preview`
- **권한**: 그룹 멤버 (`@security.isGroupMember`)
- **Query Parameters**: `roleIds`, `groupIds`, `grades`, `years` (모두 선택적, 콤마 구분)

### 6. 통합 테스트 (Phase 5)

**파일**: `/backend/src/test/kotlin/org/castlekong/backend/service/GroupMemberFilterIntegrationTest.kt`

**테스트 케이스** (10개):
1. ✅ 필터 없이 전체 멤버 미리보기
2. ✅ 역할 필터 - 그룹장만
3. ✅ 학년 필터 - 1학년 OR 2학년
4. ✅ 학번 필터 - 24학번
5. ✅ 소속 그룹 필터 - AI 학회
6. ✅ 복합 필터 - 소속 그룹 AND 학년
7. ✅ 결과 없음
8. ✅ 샘플 최대 3개 제한
9. ✅ year 변환 테스트 (studentNo → year)
10. ✅ 모든 기존 필터 테스트 통과

**테스트 결과**: `BUILD SUCCESSFUL` - 모든 테스트 통과

## API 사용 예시

### 요청 예시 1: 역할 필터
```
GET /api/groups/100/members/preview?roleIds=1,3
```

**응답**:
```json
{
  "totalCount": 2,
  "samples": [
    {
      "id": 1,
      "name": "홍길동",
      "grade": 4,
      "year": 22,
      "roleName": "그룹장"
    },
    {
      "id": 2,
      "name": "김교수",
      "grade": null,
      "year": null,
      "roleName": "교수"
    }
  ]
}
```

### 요청 예시 2: 복합 필터
```
GET /api/groups/100/members/preview?groupIds=10&grades=2,3&years=24
```

**응답**:
```json
{
  "totalCount": 5,
  "samples": [
    {
      "id": 10,
      "name": "김철수",
      "grade": 2,
      "year": 24,
      "roleName": "멤버"
    },
    {
      "id": 11,
      "name": "이영희",
      "grade": 3,
      "year": 23,
      "roleName": "멤버"
    },
    {
      "id": 12,
      "name": "박민수",
      "grade": 2,
      "year": 24,
      "roleName": "멤버"
    }
  ]
}
```

## 필터 조합 로직

### 역할 필터 (단독 동작)
```
roleIds=1,2  →  역할 1 OR 역할 2 (다른 필터 무시)
```

### 일반 필터 (복합)
```
groupIds=10,20   →  그룹 10 OR 그룹 20
grades=2,3       →  2학년 OR 3학년
years=24,25      →  24학번 OR 25학번

최종: (그룹 10 OR 그룹 20) AND ((2학년 OR 3학년) OR (24학번 OR 25학번))
```

**특수 규칙**: 학년과 학번은 OR 관계 (동일 범주로 취급)

## 성능 최적화

1. **2단계 쿼리 전략**:
   - Phase 1: COUNT 쿼리 (전체 개수)
   - Phase 2: ID 페이징 조회 (최대 3개)
   - Phase 3: JOIN FETCH 상세 조회 (N+1 방지)

2. **기존 로직 재사용**:
   - `GroupMemberSpecification` 필터 로직 재사용
   - 기존 필터 테스트와 일관성 유지

3. **샘플 제한**:
   - 최대 3명만 조회 (`LIMIT 3`)
   - 대량 데이터에도 빠른 응답 보장

## 프론트엔드 연동 가이드

### Provider 정의 (Riverpod)
```dart
final memberPreviewProvider = FutureProvider.family
    .autoDispose<MemberPreviewResponse, (int, MemberFilter)>(
  (ref, params) async {
    final (groupId, filter) = params;
    final queryParams = filter.toQueryParameters();

    final response = await ref.read(apiServiceProvider).get(
      '/api/groups/$groupId/members/preview',
      queryParameters: queryParams,
    );

    return MemberPreviewResponse.fromJson(response.data);
  },
);
```

### Step 2 페이지에서 사용
```dart
class Step2Page extends ConsumerWidget {
  final MemberFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewAsync = ref.watch(
      memberPreviewProvider((groupId, filter))
    );

    return previewAsync.when(
      data: (preview) => Column(
        children: [
          // DYNAMIC 카드: "필터 조건 (${preview.totalCount}명)"
          _buildDynamicCard(preview),
          // STATIC 카드: "명단 수동 편집"
          _buildStaticCard(preview),
        ],
      ),
      loading: () => CircularProgressIndicator(),
      error: (e, st) => ErrorView(error: e),
    );
  }
}
```

## 관련 문서

- **API 명세**: [docs/features/member-selection-preview-api.md](docs/features/member-selection-preview-api.md)
- **멤버 선택 플로우**: [docs/features/member-selection-flow.md](docs/features/member-selection-flow.md)
- **멤버 필터링 시스템**: [docs/concepts/member-list-system.md](docs/concepts/member-list-system.md)
- **프론트엔드 구현**: [docs/implementation/frontend/member-selection-implementation.md](docs/implementation/frontend/member-selection-implementation.md)

## 다음 단계

1. ✅ **Phase 1 완료**: Preview API 백엔드 구현
2. ⏳ **Phase 2**: 프론트엔드 Step 2 페이지 구현 (DYNAMIC/STATIC 카드)
3. ⏳ **Phase 3**: Step 3 페이지 구현 (STATIC 모드 멤버 편집)

## 체크리스트

- [x] DTO 생성 (MemberPreviewResponse, MemberPreviewDto)
- [x] Mapper 확장 (toMemberPreviewDto)
- [x] Repository 메서드 추가 (findByIdsWithDetailsForPreview)
- [x] Service 메서드 구현 (previewMembers)
- [x] Controller 엔드포인트 추가
- [x] 통합 테스트 작성 (10개 케이스)
- [x] @PreAuthorize 권한 검증 (isGroupMember)
- [x] ApiResponse<T> 래퍼 사용
- [x] N+1 문제 방지 (JOIN FETCH)
- [x] 성능 최적화 (LIMIT 3)
- [x] 기존 테스트 통과 확인
