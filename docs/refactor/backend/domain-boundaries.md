# 도메인 경계 설계 (Domain Boundaries)

## 목적
처음부터 설계할 때 가장 먼저 정할 사항. 각 도메인의 책임을 명확히 하고 도메인 간 통신 방식을 사전에 정의하여 새 기능 추가 시 기존 코드를 건드리지 않도록 함.

## 현재 문제
- 권한 검증 로직이 Controller, Service, Repository에 퍼져 있음
- 데이터 접근이 명확하지 않아 누가 어떤 데이터를 소유하는지 불명확
- 도메인 간 의존성이 원형(circular) 구조를 이루기도 함
- 새 기능 추가 시 기존 도메인 코드를 수정해야 함 (변경의 파급)

## 원칙
### 1. Bounded Contexts 정의 (최우선)
```kotlin
// 📌 먼저 정의할 것: 각 도메인과 책임

Domain "Group" (그룹 관리)
├─ 책임: 그룹 생성/수정/삭제, 멤버 관리, 역할 할당
├─ 소유 데이터: Group, GroupMember, Role
├─ 외부 API: GroupService.getGroupById(id)
└─ 진입점: GroupController

Domain "Permission" (권한 검증)
├─ 책임: RBAC 매트릭스 관리, 권한 평가
├─ 소유 데이터: Permission, RolePermissionBinding, ChannelRoleBinding
├─ 외부 API: PermissionEvaluator.hasPermission(user, resource, action)
└─ 진입점: 내부 전용 (다른 Service에서만 호출)

Domain "Content" (게시글/댓글)
├─ 책임: 게시글/댓글 생성/수정/삭제, 조회
├─ 소유 데이터: Post, Comment, Channel
├─ 외부 API: ContentService.getPost(id), createPost(params)
└─ 진입점: ContentController

Domain "Workspace" (워크스페이스)
├─ 책임: 채널 관리, 권한 바인딩 관리
├─ 소유 데이터: Workspace, Channel, ChannelRoleBinding
├─ 외부 API: WorkspaceService.getChannels(groupId)
└─ 진입점: WorkspaceController
```

### 2. 도메인 간 통신 방식
```kotlin
// ✅ 도메인 A → 도메인 B 통신 패턴

// 1. 직접 호출 (같은 트랜잭션)
@Service
class ContentService(
  private val groupService: GroupService,  // 의존성 주입
  private val permissionEvaluator: PermissionEvaluator,
) {
  fun createPost(groupId: Long, userId: Long, params: CreatePostRequest): Post {
    // 1단계: 도메인 B (Group)에서 데이터 조회
    val group = groupService.getGroupById(groupId)
      ?: throw GroupNotFoundException()

    // 2단계: 도메인 B (Permission)에서 권한 검증
    val hasPermission = permissionEvaluator
      .hasPermission(userId, group, "POST_CREATE")
    if (!hasPermission) throw AccessDeniedException()

    // 3단계: 자신의 도메인 (Content)에서 비즈니스 로직 실행
    return postRepository.save(Post(groupId, userId, params))
  }
}

// 2. 이벤트 기반 통신 (도메인 결합도 낮춤)
@Service
class GroupService(
  private val applicationEventPublisher: ApplicationEventPublisher,
) {
  @Transactional
  fun deleteGroup(groupId: Long) {
    // 1단계: 자신의 도메인에서 삭제 실행
    groupRepository.delete(groupId)

    // 2단계: 다른 도메인에 알림 (비동기, 결합도 낮음)
    applicationEventPublisher.publishEvent(
      GroupDeletedEvent(groupId)
    )
    // Content 도메인은 이 이벤트를 받아서 자신의 포스트 삭제
    // Workspace 도메인은 이 이벤트를 받아서 자신의 채널 삭제
  }
}

// 3. 도메인 내부 전용 API (절대 외부 노출 금지)
@Service
internal class PermissionService(  // internal 제어자
  private val roleRepository: RoleRepository,
) {
  // ❌ 외부에서 절대 호출 금지
  internal fun checkPermission(userId: Long, resource: String): Boolean {
    // ...
  }

  // ✅ 외부에서 호출 가능
  fun evaluatePermission(userId: Long, groupId: Long, action: String): Boolean {
    // PermissionEvaluator를 통해서만 노출
  }
}
```

### 3. 데이터 소유권 (절대 규칙)
```kotlin
// 📌 각 도메인이 소유하는 데이터 명시

// ❌ 금지: 데이터 소유권 침해
@Service
class ContentService(
  private val groupRepository: GroupRepository,  // 다른 도메인 레포 직접 접근
) {
  fun getPostsInGroup(groupId: Long): List<Post> {
    val group = groupRepository.findById(groupId)  // ❌ Group 도메인 데이터
    return postRepository.findByGroupId(groupId)
  }
}

// ✅ 올바름: 도메인 서비스를 통해 접근
@Service
class ContentService(
  private val groupService: GroupService,  // 도메인 서비스
) {
  fun getPostsInGroup(groupId: Long): List<Post> {
    val group = groupService.getGroupById(groupId)  // ✅ GroupService 통해서만
    return postRepository.findByGroupId(groupId)
  }
}
```

### 4. 도메인 진입점 명시
```kotlin
// 📌 각 도메인의 public API (진입점) 명확히 정의

// Domain "Group"
public interface IGroupService {
  // 공개 API (외부에서 호출 가능)
  fun getGroupById(id: Long): Group
  fun createGroup(params: CreateGroupRequest): Group
  fun deleteGroup(id: Long): void
}

// Domain "Permission"
public interface IPermissionEvaluator {
  // 공개 API
  fun hasPermission(userId: Long, groupId: Long, action: String): Boolean
  fun getPermissionsForUser(userId: Long, groupId: Long): Set<Permission>
}

// Domain "Content"
public interface IContentService {
  // 공개 API
  fun getPost(id: Long): Post
  fun createPost(groupId: Long, userId: Long, params: CreatePostRequest): Post
}

// 도메인별 Controller에서 자신의 Service만 의존
@RestController
@RequestMapping("/api/v1/groups")
class GroupController(
  private val groupService: IGroupService,  // 자신의 도메인 Service만
) {
  @GetMapping("/{id}")
  fun getGroup(@PathVariable id: Long): ApiResponse<GroupDto> {
    val group = groupService.getGroupById(id)
    return ApiResponse.success(GroupConverter.toDto(group))
  }
}
```

## 구현 패턴

### Before (현재 - 도메인 경계 불명확)
```kotlin
// ❌ 도메인이 혼재되어 있음
@Service
class PostService(
  private val postRepository: PostRepository,
  private val groupRepository: GroupRepository,  // 다른 도메인
  private val channelRepository: ChannelRepository,  // 또 다른 도메인
  private val permissionService: PermissionService,  // 권한도 섞임
) {
  fun createPost(groupId: Long, channelId: Long, params: CreatePostRequest): Post {
    // 1단계: 다른 도메인 데이터 확인
    val group = groupRepository.findById(groupId) ?: throw Exception()
    val channel = channelRepository.findById(channelId) ?: throw Exception()

    // 2단계: 권한 확인 (다른 도메인)
    val permission = permissionService.checkPermission(...)

    // 3단계: 자신의 로직
    return postRepository.save(Post(...))
  }
}
```

### After (개선 - 도메인 경계 명확)
```kotlin
// ✅ 각 도메인 책임 명확
@Service
class PostService(
  private val postRepository: PostRepository,
  private val groupService: IGroupService,  // 도메인 서비스 인터페이스
  private val permissionEvaluator: IPermissionEvaluator,  // 도메인 서비스 인터페이스
) {
  fun createPost(
    groupId: Long,
    channelId: Long,
    userId: Long,
    params: CreatePostRequest,
  ): Post {
    // 1단계: 도메인 Group 확인 (IGroupService 통해)
    val group = groupService.getGroupById(groupId)

    // 2단계: 권한 검증 (IPermissionEvaluator 통해)
    val hasPermission = permissionEvaluator.hasPermission(
      userId = userId,
      groupId = groupId,
      action = "POST_CREATE"
    )
    if (!hasPermission) throw AccessDeniedException()

    // 3단계: 자신의 로직만
    return postRepository.save(Post(groupId, channelId, userId, params))
  }
}
```

## 검증 방법

### 체크리스트
- [ ] 모든 도메인의 책임이 한 문장으로 설명 가능한가?
- [ ] 도메인이 다른 도메인의 Repository에 직접 접근하지 않는가?
- [ ] 모든 도메인 간 통신이 Service 인터페이스를 통하는가?
- [ ] 각 도메인의 public API가 명시되어 있는가?
- [ ] 새 기능 추가 시 기존 도메인을 수정하지 않아도 되는가?

### 구체적 검증
```bash
# 1. Repository 직접 주입 검사 (금지)
grep -r "private.*Repository" src/main/kotlin/service/
# → {도메인}Service에서만 {도메인}Repository 주입 허용

# 2. 원형 의존성 검사
grep -r "@Autowired" src/main/kotlin/ | grep -E "Service.*Service"
# → A → B → A 순환 구조 없어야 함

# 3. Domain API 노출 확인
grep -r "public interface I" src/main/kotlin/
# → 각 도메인별로 최소 1개 이상의 public interface 필수
```

## 관련 문서
- [API 단순화](api-simplification.md) - 도메인 간 API 설계
- [권한 검증 (역함수 패턴)](permission-guard.md) - 도메인 경계에서 권한 검증
- [헌법 - 3-Layer Architecture](../../.specify/memory/constitution.md#i-3-layer-architecture-비협상)
