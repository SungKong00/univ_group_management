# API 단순화 (Minimal API Contract)

## 목적
API 엔드포인트와 응답 형식을 극도로 단순화하여 클라이언트 로직을 줄이고, 새 기능 추가 시 API 설계 결정을 하지 않도록 함.

## 현재 문제
- API 엔드포인트가 50개 이상 (각각 다른 형식)
- 응답 구조가 일관되지 않음 (일부는 ApiResponse, 일부는 직접 객체)
- 부분 조회를 위해 별도 엔드포인트 생성 (GET /posts, GET /posts/recent, GET /posts/popular)
- 클라이언트가 예측 불가능한 응답 형식에 대응해야 함

## 원칙
### 1. REST 동사를 엄격하게 제한
```kotlin
// 📌 허용되는 패턴만 사용

// ✅ READ
GET /api/v1/groups                      // 목록 조회 (페이징)
GET /api/v1/groups/{id}                 // 상세 조회
GET /api/v1/groups/{id}/members         // 관련 엔티티 목록
GET /api/v1/groups/{id}/posts           // 관련 엔티티 목록

// ✅ CREATE
POST /api/v1/groups                     // 생성

// ✅ UPDATE
PATCH /api/v1/groups/{id}               // 부분 수정

// ✅ DELETE
DELETE /api/v1/groups/{id}              // 삭제

// ❌ 금지되는 패턴
GET /api/v1/groups/recent               // ← 별도 엔드포인트 금지
GET /api/v1/groups/popular              // ← 금지
GET /api/v1/groups/search               // ← 금지
POST /api/v1/groups/{id}/invite         // ← 금지, PATCH 또는 POST를 /members로

// ✅ 대신 쿼리 파라미터 사용
GET /api/v1/groups?sort=recent&limit=10
GET /api/v1/groups?sort=popular&limit=10
GET /api/v1/groups?search=keyword
POST /api/v1/groups/{id}/members        // 멤버 추가
```

### 2. 응답은 항상 ApiResponse<T>
```kotlin
// ✅ 성공 응답
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Computer Science",
    "description": "..."
  },
  "error": null,
  "timestamp": "2025-11-20T10:30:00Z"
}

// ✅ 실패 응답
{
  "success": false,
  "data": null,
  "error": {
    "code": "GROUP_NOT_FOUND",
    "message": "그룹을 찾을 수 없습니다"
  },
  "timestamp": "2025-11-20T10:30:00Z"
}

// ❌ 금지: 직접 객체 반환
{
  "id": 1,
  "name": "Computer Science"
}

// ❌ 금지: 응답 형식 섞임
{
  "groups": [...],
  "total": 100
}
```

### 3. 부분 조회는 쿼리 파라미터로
```kotlin
// 📌 쿼리 파라미터 표준화

GET /api/v1/posts?limit=20&offset=0&sort=recent
  - limit: 개수 (기본 20)
  - offset: 시작 위치 (기본 0)
  - sort: 정렬 (recent|oldest|popular) (기본 recent)
  - filter: 필터 (comma-separated, 옵션)

// ✅ 백엔드 구현
@GetMapping("/posts")
fun listPosts(
  @RequestParam(defaultValue = "20") limit: Int,
  @RequestParam(defaultValue = "0") offset: Int,
  @RequestParam(defaultValue = "recent") sort: String,
  @RequestParam(required = false) filter: String?,
): ApiResponse<PostListDto> {
  return ApiResponse.success(postService.listPosts(limit, offset, sort, filter))
}

// ✅ 클라이언트는 단순함
final posts = await api.get(
  '/posts',
  queryParameters: {
    'limit': '20',
    'offset': '0',
    'sort': 'recent',
  }
);
```

## 구현 패턴

### Before (현재 - 다양한 엔드포인트)
```kotlin
// ❌ 문제: 엔드포인트가 많고 형식이 다름
@RestController
@RequestMapping("/api/v1/posts")
class PostController(
  private val postService: PostService,
) {
  // 1. 목록 조회
  @GetMapping
  fun listPosts(): List<PostDto> {  // ❌ ApiResponse 아님
    return postService.listPosts()
  }

  // 2. 최근 게시글 조회 (별도 엔드포인트)
  @GetMapping("/recent")  // ❌ 별도 엔드포인트
  fun getRecentPosts(): ApiResponse<List<PostDto>> {  // ✅ ApiResponse 사용
    return ApiResponse.success(postService.getRecentPosts())
  }

  // 3. 인기 게시글 조회 (또 다른 엔드포인트)
  @GetMapping("/popular")  // ❌ 또 다른 엔드포인트
  fun getPopularPosts(): ApiResponse<List<PostDto>> {
    return ApiResponse.success(postService.getPopularPosts())
  }

  // 4. 검색
  @GetMapping("/search")  // ❌ 또 다른 엔드포인트
  fun search(@RequestParam keyword: String): ApiResponse<List<PostDto>> {
    return ApiResponse.success(postService.search(keyword))
  }

  // 5. 상세 조회
  @GetMapping("/{id}")
  fun getPost(@PathVariable id: Long): PostDto {  // ❌ ApiResponse 아님
    return postService.getPost(id)
  }

  // 6. 생성
  @PostMapping
  fun createPost(@RequestBody request: CreatePostRequest): ApiResponse<PostDto> {
    return ApiResponse.success(postService.createPost(request))
  }

  // 7. 수정
  @PutMapping("/{id}")  // ❌ PUT (전체 수정) 사용
  fun updatePost(
    @PathVariable id: Long,
    @RequestBody request: UpdatePostRequest
  ): ApiResponse<PostDto> {
    return ApiResponse.success(postService.updatePost(id, request))
  }

  // 8. 부분 수정
  @PatchMapping("/{id}")  // ✅ PATCH (부분 수정) 사용
  fun patchPost(
    @PathVariable id: Long,
    @RequestBody request: PatchPostRequest
  ): ApiResponse<PostDto> {
    return ApiResponse.success(postService.patchPost(id, request))
  }

  // 9. 삭제
  @DeleteMapping("/{id}")
  fun deletePost(@PathVariable id: Long): ApiResponse<Void> {
    postService.deletePost(id)
    return ApiResponse.success(null)
  }
}

// 클라이언트 측에서 대응할 형식
// - listPosts: List<PostDto> (ApiResponse 아님)
// - getRecentPosts: ApiResponse<List<PostDto>>
// - search: ApiResponse<List<PostDto>>
// - getPost: PostDto
// - createPost: ApiResponse<PostDto>
// → 매번 다른 파싱 로직 필요 😵
```

### After (개선 - 단순하고 일관됨)
```kotlin
// ✅ 모든 엔드포인트가 동일한 형식
@RestController
@RequestMapping("/api/v1/posts")
class PostController(
  private val postService: PostService,
) {
  // 1. 목록 조회 (정렬, 필터 모두 쿼리 파라미터)
  @GetMapping
  fun listPosts(
    @RequestParam(defaultValue = "20") limit: Int,
    @RequestParam(defaultValue = "0") offset: Int,
    @RequestParam(defaultValue = "recent") sort: String,
    @RequestParam(required = false) search: String?,
  ): ApiResponse<PostListDto> {
    return ApiResponse.success(postService.listPosts(limit, offset, sort, search))
  }

  // 2. 상세 조회
  @GetMapping("/{id}")
  fun getPost(@PathVariable id: Long): ApiResponse<PostDto> {
    return ApiResponse.success(postService.getPost(id))
  }

  // 3. 생성
  @PostMapping
  fun createPost(@RequestBody request: CreatePostRequest): ApiResponse<PostDto> {
    return ApiResponse.success(postService.createPost(request))
  }

  // 4. 부분 수정 (PUT 금지, PATCH만)
  @PatchMapping("/{id}")
  fun updatePost(
    @PathVariable id: Long,
    @RequestBody request: UpdatePostRequest
  ): ApiResponse<PostDto> {
    return ApiResponse.success(postService.updatePost(id, request))
  }

  // 5. 삭제
  @DeleteMapping("/{id}")
  fun deletePost(@PathVariable id: Long): ApiResponse<Void> {
    postService.deletePost(id)
    return ApiResponse.success(null)
  }
}

// 클라이언트는 단순한 단일 형식으로 처리
// - 모든 엔드포인트: ApiResponse<T>
// - 정렬: ?sort=recent
// - 검색: ?search=keyword
// - 페이징: ?limit=20&offset=0
```

### 라우팅 규칙 (최종 엔드포인트 목록)
```kotlin
// ✅ 모든 API는 이 패턴만 사용

// 그룹
GET    /api/v1/groups?limit=20&offset=0&sort=recent
GET    /api/v1/groups/{id}
POST   /api/v1/groups
PATCH  /api/v1/groups/{id}
DELETE /api/v1/groups/{id}

// 그룹 멤버
GET    /api/v1/groups/{id}/members?limit=20&offset=0
POST   /api/v1/groups/{id}/members           // 멤버 추가
PATCH  /api/v1/groups/{id}/members/{userId}  // 멤버 권한 변경
DELETE /api/v1/groups/{id}/members/{userId}  // 멤버 제거

// 채널
GET    /api/v1/groups/{groupId}/channels
GET    /api/v1/groups/{groupId}/channels/{id}
POST   /api/v1/groups/{groupId}/channels
PATCH  /api/v1/groups/{groupId}/channels/{id}
DELETE /api/v1/groups/{groupId}/channels/{id}

// 게시글
GET    /api/v1/groups/{groupId}/channels/{channelId}/posts?limit=20&offset=0&sort=recent
GET    /api/v1/groups/{groupId}/channels/{channelId}/posts/{id}
POST   /api/v1/groups/{groupId}/channels/{channelId}/posts
PATCH  /api/v1/groups/{groupId}/channels/{channelId}/posts/{id}
DELETE /api/v1/groups/{groupId}/channels/{channelId}/posts/{id}

// 댓글
GET    /api/v1/groups/{groupId}/channels/{channelId}/posts/{postId}/comments?limit=20&offset=0
GET    /api/v1/groups/{groupId}/channels/{channelId}/posts/{postId}/comments/{id}
POST   /api/v1/groups/{groupId}/channels/{channelId}/posts/{postId}/comments
PATCH  /api/v1/groups/{groupId}/channels/{channelId}/posts/{postId}/comments/{id}
DELETE /api/v1/groups/{groupId}/channels/{channelId}/posts/{postId}/comments/{id}

// 📌 통일된 쿼리 파라미터
// - limit: 페이지 크기 (기본 20)
// - offset: 시작 위치 (기본 0)
// - sort: 정렬 기준 (recent|oldest|popular)
// - search: 검색 키워드 (선택)
```

## 검증 방법

### 체크리스트
- [ ] API가 5가지 동사만 사용하는가? (GET/POST/PATCH/DELETE + HEAD)
- [ ] 모든 응답이 ApiResponse<T> 형식인가?
- [ ] 부분 조회가 쿼리 파라미터로만 지정되는가?
- [ ] 별도 엔드포인트 (/recent, /popular, /search) 가 없는가?
- [ ] 전체 엔드포인트 수가 50개 이하인가?

### 구체적 검증
```bash
# 1. 엔드포인트 개수 확인
grep -r "@GetMapping\|@PostMapping\|@PatchMapping\|@DeleteMapping" \
  src/main/kotlin/controller/ | wc -l
# → 50개 이하 (모듈별 최대 10개)

# 2. 금지된 패턴 검사
grep -r "@RequestMapping.*recent\|@RequestMapping.*popular\|@RequestMapping.*search" \
  src/main/kotlin/controller/
# → 0개 (별도 엔드포인트 금지)

# 3. 응답 형식 검사
grep -r "return " src/main/kotlin/controller/ | grep -v "ApiResponse"
# → 0개 (모두 ApiResponse 사용)

# 4. PUT 사용 검사 (PATCH만 허용)
grep -r "@PutMapping" src/main/kotlin/controller/
# → 0개 (PUT 금지)
```

## 관련 문서
- [도메인 경계](domain-boundaries.md) - 도메인 간 API 설계
- [권한 검증 (역함수 패턴)](permission-guard.md) - API 진입점에서의 권한 검증
- [헌법 - 표준 응답 형식](../../.specify/memory/constitution.md#ii-표준-응답-형식-비협상)
