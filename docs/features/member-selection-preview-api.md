# 멤버 선택 Preview API 명세

> **문서 예외**: API 명세 참조 문서 (100줄 제한 예외)

Step 2에서 DYNAMIC/STATIC 선택 카드를 표시하기 위한 Preview API 설계입니다.

## API 개요

**목적**: 필터 조건에 해당하는 멤버 수와 샘플 목록을 미리 조회하여 사용자에게 선택 카드 표시

**Endpoint**: `GET /api/groups/{groupId}/members/preview`

**권한**: `GROUP_MEMBER_VIEW`

## 요청

### Path Parameter
- `groupId`: 그룹 ID (Long)

### Query Parameters
모든 파라미터는 선택적(Optional)이며, 제공된 조건만 AND 조합으로 필터링합니다.

| 파라미터 | 타입 | 설명 | 예시 |
|---------|------|------|------|
| `roleIds` | String | 역할 ID (콤마 구분) | `1,2,3` |
| `groupIds` | String | 하위 그룹 ID (콤마 구분) | `10,20` |
| `grades` | String | 학년 (콤마 구분) | `2,3` |
| `years` | String | 학번/입학년도 (콤마 구분) | `24,25` |

### 예시 요청
```
GET /api/groups/100/members/preview?roleIds=1,3&groupIds=10&grades=2
```

## 응답

### 성공 응답 (200 OK)

```json
{
  "totalCount": 15,
  "samples": [
    {
      "id": 1,
      "name": "홍길동",
      "grade": 2,
      "year": 24,
      "roleName": "그룹장"
    },
    {
      "id": 2,
      "name": "김철수",
      "grade": 2,
      "year": 24,
      "roleName": "멤버"
    },
    {
      "id": 3,
      "name": "이영희",
      "grade": 2,
      "year": 23,
      "roleName": "멤버"
    }
  ]
}
```

### 응답 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `totalCount` | Int | 필터 조건에 해당하는 전체 멤버 수 |
| `samples` | Array | 샘플 멤버 목록 (최대 3명) |
| `samples[].id` | Long | 멤버 ID |
| `samples[].name` | String | 멤버 이름 |
| `samples[].grade` | Int | 학년 (1~4, 졸업생=5) |
| `samples[].year` | Int | 학번 (입학년도 끝 2자리) |
| `samples[].roleName` | String | 역할 이름 |

### 에러 응답

**404 Not Found**: 그룹이 존재하지 않음
```json
{
  "error": "GROUP_NOT_FOUND",
  "message": "그룹을 찾을 수 없습니다"
}
```

**403 Forbidden**: 권한 없음
```json
{
  "error": "PERMISSION_DENIED",
  "message": "멤버 조회 권한이 없습니다"
}
```

**400 Bad Request**: 잘못된 파라미터
```json
{
  "error": "INVALID_PARAMETER",
  "message": "roleIds는 숫자만 가능합니다"
}
```

## 백엔드 구현

### Controller
```kotlin
@RestController
@RequestMapping("/api/groups")
class GroupMemberController(
    private val memberService: GroupMemberService
) {
    @GetMapping("/{groupId}/members/preview")
    fun previewMembers(
        @PathVariable groupId: Long,
        @RequestParam(required = false) roleIds: String?,
        @RequestParam(required = false) groupIds: String?,
        @RequestParam(required = false) grades: String?,
        @RequestParam(required = false) years: String?,
        @CurrentUser userId: Long
    ): MemberPreviewResponse {
        val filter = MemberFilter(
            roleIds = roleIds?.split(",")?.map { it.toLong() },
            groupIds = groupIds?.split(",")?.map { it.toLong() },
            grades = grades?.split(",")?.map { it.toInt() },
            years = years?.split(",")?.map { it.toInt() }
        )
        return memberService.previewMembers(groupId, filter, userId)
    }
}
```

### Service
```kotlin
@Service
class GroupMemberService(
    private val memberRepository: GroupMemberRepository,
    private val permissionService: PermissionService
) {
    @Transactional(readOnly = true)
    fun previewMembers(
        groupId: Long,
        filter: MemberFilter,
        userId: Long
    ): MemberPreviewResponse {
        // 권한 검증
        permissionService.checkPermission(userId, groupId, "GROUP_MEMBER_VIEW")

        // 전체 개수 조회 (COUNT 쿼리)
        val totalCount = memberRepository.countByFilter(groupId, filter)

        // 샘플 3명 조회 (LIMIT 3)
        val samples = memberRepository.findByFilter(
            groupId = groupId,
            filter = filter,
            pageable = PageRequest.of(0, 3)
        ).map { MemberPreviewDto.from(it) }

        return MemberPreviewResponse(
            totalCount = totalCount,
            samples = samples
        )
    }
}
```

### Repository
```kotlin
@Repository
interface GroupMemberRepository : JpaRepository<GroupMember, Long> {

    // COUNT 쿼리 (성능 최적화)
    @Query("""
        SELECT COUNT(DISTINCT gm.id)
        FROM GroupMember gm
        WHERE gm.group.id = :groupId
          AND (:#{#filter.roleIds} IS NULL OR gm.role.id IN :#{#filter.roleIds})
          AND (:#{#filter.grades} IS NULL OR gm.user.academicYear IN :#{#filter.grades})
          AND (:#{#filter.years} IS NULL OR gm.user.entranceYear IN :#{#filter.years})
          AND (:#{#filter.groupIds} IS NULL OR EXISTS (
              SELECT 1 FROM GroupMember gm2
              WHERE gm2.user.id = gm.user.id
                AND gm2.group.id IN :#{#filter.groupIds}
          ))
    """)
    fun countByFilter(groupId: Long, filter: MemberFilter): Int

    // 샘플 조회 (LIMIT 3)
    fun findByFilter(
        groupId: Long,
        filter: MemberFilter,
        pageable: Pageable
    ): List<GroupMember>
}
```

## 프론트엔드 사용

### Provider 정의
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

### Step 2 페이지에서 호출
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
          // DYNAMIC 카드
          _buildDynamicCard(preview),
          // STATIC 카드
          _buildStaticCard(preview),
        ],
      ),
      loading: () => CircularProgressIndicator(),
      error: (e, st) => ErrorView(error: e),
    );
  }
}
```

## 성능 최적화

### 1. COUNT 쿼리 최적화
- 인덱스: `(group_id, role_id)`, `(user_id, group_id)`
- COUNT(DISTINCT)로 중복 제거
- 서브쿼리 대신 EXISTS 사용

### 2. 샘플 조회 최적화
- LIMIT 3으로 최소 데이터만 조회
- Fetch Join으로 N+1 문제 방지
- DTO 변환으로 불필요한 필드 제거

### 3. 캐싱 (선택 사항)
- Redis에 5분간 캐싱 (필터 조건 해시 키)
- 멤버 변경 시 캐시 무효화
- 대규모 그룹(1000명+)에만 적용

## 호출 시점

**Step 1 완료 후 Step 2 진입 시 즉시 호출**
- Step 1에서 "다음" 버튼 클릭
- Step 2 페이지 로드 시 Preview API 자동 호출
- 응답 받은 후 DYNAMIC/STATIC 카드 표시

## 관련 문서

- [멤버 선택 플로우](member-selection-flow.md) - 전체 흐름
- [프론트엔드 구현](../implementation/frontend/member-selection-implementation.md) - 구현 가이드
- [멤버 필터링 시스템](../concepts/member-list-system.md) - 필터 조합 로직
