# 권한 검증 (역함수 패턴) (Permission as Guard, not Filter)

## 목적
권한 검증을 **사전 조건으로** 처리하여 N+1 쿼리를 방지하고, 권한에 따라 최적화된 쿼리를 실행하도록 함. 보안 감시도 명확해짐.

## 현재 문제
- 데이터를 먼저 조회 후 권한 확인 (후처리)
- 권한이 없는 데이터도 DB에서 조회함
- N+1 쿼리 문제 (목록 조회 후 각각 권한 확인)
- 감시 로그에 접근 실패 기록이 남지 않음
- 권한에 따른 최적화 불가능

## 원칙
### 1. 권한 먼저, 쿼리는 그 다음 (역함수 패턴)
```kotlin
// ❌ 현재 (위험한 패턴)
@Service
class PostService(
  private val postRepository: PostRepository,
  private val permissionService: PermissionService,
) {
  fun getPostsInChannel(channelId: Long, userId: Long): List<Post> {
    // 1단계: DB에서 모든 포스트 조회
    val posts = postRepository.findByChannelId(channelId)

    // 2단계: 메모리에서 권한 필터링 (N+1 처럼 보임)
    val filtered = posts.filter { post ->
      permissionService.canRead(post, userId)
    }

    return filtered
  }
}
// 문제: 100개 게시글이 있으면 100개 조회 + 100번 권한 확인 쿼리

// ✅ 개선 (역함수 패턴)
@Service
class PostService(
  private val postRepository: PostRepository,
  private val permissionEvaluator: PermissionEvaluator,
) {
  fun getPostsInChannel(channelId: Long, userId: Long): List<Post> {
    // 1단계: 권한 먼저 확인 (DB 쿼리 0개)
    val permission = permissionEvaluator.checkChannelAccess(userId, channelId)
      ?: throw AccessDeniedException()

    // 2단계: 권한에 따른 쿼리 결정 (최적화된 쿼리)
    return when (permission.level) {
      PermissionLevel.OWNER -> {
        // 그룹 오너: 모든 포스트 조회
        postRepository.findByChannelId(channelId)
      }
      PermissionLevel.MEMBER -> {
        // 일반 멤버: 공개 포스트만 조회
        postRepository.findPublishedByChannelId(channelId)
      }
      else -> {
        // 권한 없음: 빈 리스트
        emptyList()
      }
    }
  }
}
// 장점: 권한 확인 1회 + 최적화된 쿼리 1회 = 총 2회 쿼리
```

### 2. API 진입점에서 권한 검증
```kotlin
// 📌 컨트롤러에서 먼저 권한 확인

@RestController
@RequestMapping("/api/v1/groups")
class GroupController(
  private val groupService: GroupService,
  private val permissionEvaluator: PermissionEvaluator,
) {
  @GetMapping("/{groupId}/posts")
  fun listPosts(
    @PathVariable groupId: Long,
    @RequestParam(defaultValue = "20") limit: Int,
    @RequestParam(defaultValue = "0") offset: Int,
  ): ApiResponse<PostListDto> {
    // 1단계: 사용자 정보 추출
    val userId = SecurityContextHolder.getContext().authentication.principal as Long

    // 2단계: 권한 검증 (DB 접근 전)
    val permission = permissionEvaluator.checkGroupAccess(userId, groupId)
    if (permission == null || !permission.canViewPosts) {
      throw AccessDeniedException("그룹에 접근할 수 없습니다")
    }

    // 3단계: 권한이 확인된 후 Service 호출
    val posts = groupService.listPosts(groupId, userId, limit, offset, permission)

    return ApiResponse.success(PostListConverter.toDto(posts))
  }
}

// Service는 권한이 이미 확인됨을 가정
@Service
class GroupService(
  private val postRepository: PostRepository,
) {
  // 주의: 이 메서드는 Controller에서 권한 확인 후에만 호출됨
  fun listPosts(
    groupId: Long,
    userId: Long,
    limit: Int,
    offset: Int,
    permission: GroupPermission,  // 이미 확인된 권한
  ): List<Post> {
    // 권한에 따른 쿼리 최적화
    val query = when {
      permission.isOwner -> {
        // 오너: 모든 포스트
        postRepository.findByGroupId(groupId, limit, offset)
      }
      permission.isMember -> {
        // 멤버: 공개 포스트만
        postRepository.findPublishedByGroupId(groupId, limit, offset)
      }
      else -> {
        // 권한 없음 (이미 Controller에서 차단됨)
        emptyList()
      }
    }

    return query
  }
}
```

### 3. 권한 검증 실패 시 명확한 로깅
```kotlin
// 📌 권한 검증 실패는 로깅되어야 함 (감시 목적)

@Service
class PermissionEvaluator(
  private val roleRepository: RoleRepository,
  private val auditLogger: AuditLogger,  // 감시 로깅
) {
  fun checkGroupAccess(userId: Long, groupId: Long): GroupPermission? {
    return try {
      // 권한 확인
      val membership = roleRepository.findByUserIdAndGroupId(userId, groupId)
        ?: return null  // 멤버 아님

      val roles = roleRepository.getRolesForMember(userId, groupId)
      val permissions = roleRepository.getPermissionsForRoles(roles)

      // ✅ 감시 로그: 권한 접근 시도 (성공)
      auditLogger.log(
        action = "CHECK_PERMISSION",
        userId = userId,
        resourceId = groupId,
        result = "SUCCESS",
        permissions = permissions.map { it.name }
      )

      GroupPermission(roles, permissions)
    } catch (e: Exception) {
      // ❌ 감시 로그: 권한 접근 시도 (실패)
      auditLogger.log(
        action = "CHECK_PERMISSION",
        userId = userId,
        resourceId = groupId,
        result = "FAILURE",
        reason = e.message
      )

      null
    }
  }
}
```

## 구현 패턴

### Before (현재 - 후처리 권한 검증)
```kotlin
// ❌ 문제: 권한 없는 데이터도 조회
@Service
class PostService(
  private val postRepository: PostRepository,
  private val permissionService: PermissionService,
) {
  @Transactional(readOnly = true)
  fun listPostsInChannel(channelId: Long, userId: Long): List<PostDto> {
    // 1단계: 모든 데이터 조회 (권한 무시)
    val posts = postRepository.findByChannelId(channelId)
      .map { PostConverter.toDto(it) }

    // 2단계: 메모리에서 필터링 (이미 늦음)
    val filtered = posts.filter { post ->
      permissionService.canReadPost(userId, post.id)
    }

    return filtered
  }
}

// 클라이언트
val posts = postService.listPostsInChannel(channelId, userId)
// → 100개 조회 + 100번 권한 확인

// 문제점:
// 1. 데이터베이스에 불필요한 트래픽
// 2. N+1 쿼리 발생
// 3. 감시 로그에 "접근 시도" 기록 안 남음
```

### After (개선 - 사전 권한 검증)
```kotlin
// ✅ 권한 먼저, 최적화된 쿼리
@RestController
class ChannelController(
  private val postService: PostService,
  private val permissionEvaluator: PermissionEvaluator,
) {
  @GetMapping("/channels/{channelId}/posts")
  fun listPosts(
    @PathVariable channelId: Long,
    @RequestParam(defaultValue = "20") limit: Int,
  ): ApiResponse<PostListDto> {
    val userId = getCurrentUserId()

    // 1단계: 권한 검증 (DB 접근 전)
    val permission = permissionEvaluator.checkChannelAccess(userId, channelId)
      ?: throw AccessDeniedException("채널에 접근할 수 없습니다")

    // 2단계: 권한과 함께 Service 호출
    val posts = postService.listPostsInChannel(
      channelId = channelId,
      userId = userId,
      permission = permission,
      limit = limit
    )

    return ApiResponse.success(PostListConverter.toDto(posts))
  }
}

@Service
class PostService(
  private val postRepository: PostRepository,
) {
  @Transactional(readOnly = true)
  fun listPostsInChannel(
    channelId: Long,
    userId: Long,
    permission: ChannelPermission,  // 이미 확인된 권한
    limit: Int,
  ): List<Post> {
    // 권한에 따른 쿼리 최적화
    return when {
      permission.isChannelOwner -> {
        // 채널 오너: 모든 포스트
        postRepository.findByChannelId(channelId, limit)
      }
      permission.isMember -> {
        // 멤버: 공개 포스트만
        postRepository.findPublishedByChannelId(channelId, limit)
      }
      else -> {
        // 권한 없음 (이미 Controller에서 차단됨)
        emptyList()
      }
    }
  }
}

// 클라이언트
val posts = channelController.listPosts(channelId)
// → 권한 확인 1회 + 최적화된 쿼리 1회 = 2회 쿼리

// 장점:
// 1. 권한 없으면 DB 접근 안 함
// 2. 권한에 따른 쿼리 최적화
// 3. 감시 로그에 정확히 기록됨
```

### 권한 캐싱 전략
```kotlin
// 📌 권한은 자주 변하지 않으므로 캐시 사용

@Service
class PermissionEvaluator(
  private val roleRepository: RoleRepository,
) {
  @Cacheable(value = "permissions", key = "#userId + '-' + #groupId")
  fun checkGroupAccess(userId: Long, groupId: Long): GroupPermission? {
    // 이 메서드 결과는 캐시됨
    val roles = roleRepository.getRolesForMember(userId, groupId)
    return GroupPermission(roles)
  }

  // 권한 변경 시 캐시 무효화
  @CacheEvict(value = "permissions", key = "#userId + '-' + #groupId")
  fun updateMemberRole(userId: Long, groupId: Long, role: Role) {
    roleRepository.updateRole(userId, groupId, role)
  }
}
```

## 검증 방법

### 체크리스트
- [ ] Service 메서드가 permission 파라미터를 받는가?
- [ ] Controller에서 먼저 권한을 확인하는가?
- [ ] 권한 없으면 DB 쿼리를 실행하지 않는가?
- [ ] 권한 검증 실패가 로깅되는가?
- [ ] 권한별로 다른 쿼리를 사용하는가?

### 구체적 검증
```bash
# 1. Service 메서드 분석
grep -A 5 "fun list.*(" src/main/kotlin/service/ | grep -E "permission|authority"
# → 첫 파라미터가 permission/authority 관련이어야 함

# 2. Controller에서의 권한 검증 위치
grep -B 10 "service\." src/main/kotlin/controller/ | grep -E "@PreAuthorize|permissionEvaluator"
# → service 호출 전에 권한 검증이 있어야 함

# 3. N+1 쿼리 검사
grep -c "for.*permission\|for.*hasPermission" src/main/kotlin/service/
# → 0개 (루프 내 권한 확인 금지)
```

## 관련 문서
- [도메인 경계](domain-boundaries.md) - 권한 도메인의 책임
- [API 단순화](api-simplification.md) - API 진입점에서의 권한 검증
- [헌법 - RBAC + Override 권한 시스템](../../.specify/memory/constitution.md#iii-rbac--override-권한-시스템-비협상)
