# 백엔드 구현 가이드 (Backend Implementation Guide)

## 3레이어 아키텍처

```
Controller Layer (HTTP 처리)
    ↓
Service Layer (비즈니스 로직)
    ↓
Repository Layer (데이터 접근)
```

### Controller Layer
```kotlin
@RestController
@RequestMapping("/api/groups")
class GroupController(
    private val groupService: GroupService,
    private val userService: UserService
) {
    @PostMapping
    @PreAuthorize("@security.hasGroupPerm(#request.parentGroupId, 'GROUP_CREATE')")
    fun createGroup(
        @Valid @RequestBody request: CreateGroupRequest,
        authentication: Authentication
    ): ResponseEntity<ApiResponse<GroupDto>> {
        val user = userService.findByEmail(authentication.name)
        val group = groupService.createGroup(request, user.id!!)
        return ResponseEntity.ok(ApiResponse.success(group))
    }
}
```

### Service Layer
```kotlin
@Service
@Transactional
class GroupService(
    private val groupRepository: GroupRepository,
    private val workspaceService: WorkspaceService
) {
    fun createGroup(request: CreateGroupRequest, ownerId: Long): GroupDto {
        // 1. 비즈니스 로직 검증
        validateGroupCreation(request, ownerId)

        // 2. 엔티티 생성
        val group = Group(
            name = request.name,
            ownerId = ownerId,
            visibility = request.visibility
        )

        // 3. 저장
        val savedGroup = groupRepository.save(group)

        // 4. 연관 데이터 생성 (워크스페이스, 기본 채널)
        workspaceService.createDefaultWorkspace(savedGroup.id!!)

        return savedGroup.toDto()
    }
}
```

### Repository Layer
```kotlin
@Repository
interface GroupRepository : JpaRepository<Group, Long> {

    @Query("SELECT g FROM Group g WHERE g.deletedAt IS NULL AND g.visibility = 'PUBLIC'")
    fun findPublicGroups(pageable: Pageable): Page<Group>

    @Query("SELECT g FROM Group g JOIN g.members m WHERE m.user.id = :userId")
    fun findByMemberId(userId: Long): List<Group>
}
```

## 인증/인가 패턴

### JWT 토큰 처리
```kotlin
@Component
class JwtAuthenticationFilter : OncePerRequestFilter() {

    override fun doFilterInternal(
        request: HttpServletRequest,
        response: HttpServletResponse,
        filterChain: FilterChain
    ) {
        val token = extractTokenFromHeader(request)
        if (token != null && jwtTokenProvider.validateToken(token)) {
            val authentication = jwtTokenProvider.getAuthentication(token)
            SecurityContextHolder.getContext().authentication = authentication
        }
        filterChain.doFilter(request, response)
    }
}
```

### 권한 체크 서비스
```kotlin
@Component("security")
class GroupPermissionEvaluator(
    private val userRepository: UserRepository,
    private val permissionService: PermissionService
) : PermissionEvaluator {
    override fun hasPermission(
        authentication: Authentication?,
        targetId: Serializable?,
        targetType: String?,
        permission: Any?,
    ): Boolean {
        if (authentication == null || targetId !is Long || permission !is String) return false

        // 1. 글로벌 ADMIN은 모든 권한 통과
        if (authentication.authorities.any { it.authority == "ROLE_ADMIN" }) return true

        val user = userRepository.findByEmail(authentication.name).orElse(null) ?: return false

        // 2. PermissionService에 권한 계산 위임 (캐싱 처리 포함)
        val effectivePermissions = permissionService.getEffective(targetId, user.id)
        
        // 3. 최종 권한 확인
        return effectivePermissions.any { it.name == permission }
    }
}
```

## 표준 응답 형식

### ApiResponse 클래스
```kotlin
data class ApiResponse<T>(
    val success: Boolean,
    val data: T? = null,
    val error: ErrorResponse? = null
) {
    companion object {
        fun <T> success(data: T) = ApiResponse(success = true, data = data)
        fun <T> error(code: String, message: String) =
            ApiResponse<T>(success = false, error = ErrorResponse(code, message))
    }
}

data class ErrorResponse(
    val code: String,
    val message: String
)
```

### 전역 예외 처리
```kotlin
@RestControllerAdvice
class GlobalExceptionHandler {

    @ExceptionHandler(IllegalArgumentException::class)
    fun handleIllegalArgument(e: IllegalArgumentException): ResponseEntity<ApiResponse<Any>> {
        return ResponseEntity.badRequest()
            .body(ApiResponse.error("INVALID_REQUEST", e.message ?: "잘못된 요청"))
    }

    @ExceptionHandler(AccessDeniedException::class)
    fun handleAccessDenied(e: AccessDeniedException): ResponseEntity<ApiResponse<Any>> {
        return ResponseEntity.status(HttpStatus.FORBIDDEN)
            .body(ApiResponse.error("INSUFFICIENT_PERMISSION", "권한이 없습니다"))
    }
}
```

## 데이터 변환 패턴

### DTO 변환
```kotlin
// Entity -> DTO
fun Group.toDto(): GroupDto = GroupDto(
    id = this.id!!,
    name = this.name,
    visibility = this.visibility,
    memberCount = this.members.size,
    createdAt = this.createdAt
)

// DTO -> Entity
fun CreateGroupRequest.toEntity(ownerId: Long): Group = Group(
    name = this.name,
    ownerId = ownerId,
    visibility = this.visibility,
    description = this.description
)
```

### 페이징 응답
```kotlin
@GetMapping
fun getGroups(
    @PageableDefault(size = 20) pageable: Pageable,
    @RequestParam(required = false) search: String?
): ResponseEntity<ApiResponse<Page<GroupDto>>> {

    val groups = groupService.findGroups(search, pageable)
    return ResponseEntity.ok(ApiResponse.success(groups))
}
```

## 비즈니스 로직 패턴

### 도메인 검증
```kotlin
class GroupService {

    fun validateGroupCreation(request: CreateGroupRequest, ownerId: Long) {
        // 1. 그룹명 중복 검사
        if (groupRepository.existsByName(request.name)) {
            throw IllegalArgumentException("이미 존재하는 그룹명입니다")
        }

        // 2. 부모 그룹 권한 검사
        if (request.parentGroupId != null) {
            val hasPermission = permissionEvaluator.hasGroupPerm(
                request.parentGroupId, "SUB_GROUP_CREATE"
            )
            if (!hasPermission) {
                throw AccessDeniedException("하위 그룹 생성 권한이 없습니다")
            }
        }
    }
}
```

### 트랜잭션 관리
```kotlin
@Transactional
fun createGroupWithWorkspace(request: CreateGroupRequest, ownerId: Long): GroupDto {
    try {
        // 1. 그룹 생성
        val group = createGroup(request, ownerId)

        // 2. 워크스페이스 생성
        workspaceService.createDefaultWorkspace(group.id)

        // 3. 기본 채널 생성
        channelService.createDefaultChannels(group.id)

        return group
    } catch (e: Exception) {
        // 롤백 자동 처리
        throw e
    }
}
```

## 테스트 패턴

### 통합 테스트
```kotlin
@SpringBootTest
@Transactional
class GroupServiceIntegrationTest : DatabaseCleanup() {

    @Test
    fun `그룹 생성 시 워크스페이스와 기본 채널이 함께 생성된다`() {
        // given
        val owner = createTestUser()
        val request = CreateGroupRequest(
            name = "테스트 그룹",
            visibility = GroupVisibility.PUBLIC
        )

        // when
        val group = groupService.createGroup(request, owner.id!!)

        // then
        assertThat(group.name).isEqualTo("테스트 그룹")

        val workspaces = workspaceRepository.findByGroupId(group.id)
        assertThat(workspaces).hasSize(1)

        val channels = channelRepository.findByWorkspaceId(workspaces[0].id!!)
        assertThat(channels).hasSize(2) // 일반대화, 공지사항
    }
}
```

## 성능 최적화

### N+1 문제 해결
```kotlin
@Query("SELECT g FROM Group g JOIN FETCH g.members m JOIN FETCH m.user WHERE g.id = :groupId")
fun findWithMembersAndUsers(groupId: Long): Group?

// 사용 시
val group = groupRepository.findWithMembersAndUsers(groupId)
val memberDtos = group.members.map { it.toDto() } // 추가 쿼리 없음
```

### 캐싱 적용
```kotlin
@Cacheable(value = ["groups"], key = "#groupId")
fun findGroup(groupId: Long): GroupDto? {
    return groupRepository.findById(groupId)?.toDto()
}

@CacheEvict(value = ["groups"], key = "#groupId")
fun updateGroup(groupId: Long, request: UpdateGroupRequest): GroupDto {
    // 업데이트 로직
}
```

## 관련 개념

### 도메인 모델
- **그룹 계층**: [../concepts/group-hierarchy.md](../concepts/group-hierarchy.md)
- **권한 시스템**: [../concepts/permission-system.md](../concepts/permission-system.md)
- **사용자 라이프사이클**: [../concepts/user-lifecycle.md](../concepts/user-lifecycle.md)

### 구현 참조
- **API 상세**: [api-reference.md](api-reference.md)
- **데이터베이스**: [database-reference.md](database-reference.md)

### 문제 해결
- **권한 에러**: [../troubleshooting/permission-errors.md](../troubleshooting/permission-errors.md)
- **일반적 에러**: [../troubleshooting/common-errors.md](../troubleshooting/common-errors.md)
