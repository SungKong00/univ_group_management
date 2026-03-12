# 도메인 의존성 그래프 (Domain Dependencies)

## 목적
backend_new 리팩터링의 6개 Bounded Context 간 의존성을 명확히 하여 순환 참조를 방지하고 구현 순서를 결정.

## 설계 원칙

### 1. 의존 방향 규칙
- **단방향 의존만 허용** (A → B, B → C는 허용, A ← B는 금지)
- **순환 참조 절대 금지** (A → B → C → A 금지)
- **상위 레이어는 하위 레이어 의존 불가**

### 2. 도메인 간 통신 방식
- **직접 호출**: 같은 트랜잭션 내에서 Service 인터페이스를 통해 호출
- **이벤트 발행**: 도메인 결합도를 낮추기 위한 비동기 통신
- **절대 금지**: Repository 직접 접근 (반드시 Service 인터페이스 경유)

---

## 도메인 의존성 그래프

```
         ┌─────────────┐
         │    User     │ (Lv 0 - Foundation)
         └──────┬──────┘
                │
        ┌───────┴───────┬─────────┐
        │               │         │
   ┌────▼────┐    ┌────▼────┐   ┌▼─────────┐
   │  Group  │    │Calendar │   │Permission│ (Lv 1 - Core)
   └────┬────┘    └─────────┘   └────┬─────┘
        │                             │
        │         ┌───────────────────┘
        │         │
   ┌────▼─────────▼──┐
   │   Workspace     │ (Lv 2 - Service)
   └────┬────────────┘
        │
   ┌────▼────┐
   │ Content │ (Lv 3 - Application)
   └─────────┘
```

### 레벨별 설명
- **Lv 0 (Foundation)**: 다른 도메인을 의존하지 않는 기반 도메인
- **Lv 1 (Core)**: Foundation 도메인만 의존
- **Lv 2 (Service)**: Foundation + Core 도메인 의존
- **Lv 3 (Application)**: Foundation + Core + Service 도메인 의존

---

## 1. User Domain (Lv 0 - Foundation)

### 의존성
- **의존하는 도메인**: 없음 (독립)
- **의존받는 도메인**: Group, Permission, Workspace, Content, Calendar

### 역할
- 사용자 기본 정보 관리
- 글로벌 역할 (STUDENT/PROFESSOR/ADMIN)
- 인증 정보 (email, password)

### Service 인터페이스
```kotlin
interface IUserService {
    fun getUserById(id: Long): User
    fun getUserByEmail(email: String): User?
    fun updateProfile(userId: Long, request: UpdateProfileRequest): User
    fun verifyEmail(userId: Long, code: String): Boolean
}
```

### 구현 순서: Phase 1 (가장 먼저)

---

## 2. Group Domain (Lv 1 - Core)

### 의존성
- **의존하는 도메인**: User (소유자, 멤버)
- **의존받는 도메인**: Permission, Workspace, Content, Calendar

### 역할
- 그룹 생성/수정/삭제
- 멤버 관리 (가입/탈퇴/역할 변경)
- 역할 정의 (GroupRole)

### Service 인터페이스
```kotlin
interface IGroupService {
    // Group CRUD
    fun getGroupById(id: Long): Group
    fun createGroup(ownerId: Long, request: CreateGroupRequest): Group
    fun updateGroup(groupId: Long, request: UpdateGroupRequest): Group
    fun deleteGroup(groupId: Long): Unit

    // Member Management
    fun getMembers(groupId: Long, limit: Int, offset: Int): List<GroupMember>
    fun addMember(groupId: Long, userId: Long, roleId: Long): GroupMember
    fun updateMemberRole(groupId: Long, userId: Long, roleId: Long): GroupMember
    fun removeMember(groupId: Long, userId: Long): Unit

    // Role Management
    fun getRoles(groupId: Long): List<GroupRole>
    fun createRole(groupId: Long, request: CreateRoleRequest): GroupRole
    fun updateRole(roleId: Long, request: UpdateRoleRequest): GroupRole
}
```

### 의존 예시
```kotlin
@Service
class GroupService(
    private val groupRepository: GroupRepository,
    private val userService: IUserService,  // User 도메인 의존
    private val eventPublisher: ApplicationEventPublisher
) : IGroupService {
    override fun createGroup(ownerId: Long, request: CreateGroupRequest): Group {
        // 1. User 도메인에서 owner 조회
        val owner = userService.getUserById(ownerId)

        // 2. 자신의 도메인 로직
        val group = Group(
            name = request.name,
            owner = owner,
            // ...
        )
        return groupRepository.save(group)
    }

    override fun deleteGroup(groupId: Long) {
        groupRepository.delete(groupId)

        // 이벤트 발행 (다른 도메인이 구독)
        eventPublisher.publishEvent(GroupDeletedEvent(groupId))
    }
}
```

### 구현 순서: Phase 1

---

## 3. Permission Domain (Lv 1 - Core)

### 의존성
- **의존하는 도메인**: User, Group
- **의존받는 도메인**: Workspace, Content

### 역할
- 권한 매트릭스 관리 (RBAC + Override)
- 권한 평가 (PermissionEvaluator)
- 채널 역할 바인딩 (ChannelRoleBinding)

### Service 인터페이스
```kotlin
interface IPermissionEvaluator {
    // Group-Level Permission
    fun checkGroupAccess(userId: Long, groupId: Long): GroupPermission?
    fun hasGroupPermission(userId: Long, groupId: Long, permission: GroupPermission): Boolean

    // Channel-Level Permission
    fun checkChannelAccess(userId: Long, channelId: Long): ChannelPermission?
    fun hasChannelPermission(userId: Long, channelId: Long, permission: ChannelPermission): Boolean

    // Permission Cache
    @Cacheable("permissions")
    fun getPermissionsForUser(userId: Long, groupId: Long): Set<GroupPermission>

    @CacheEvict("permissions")
    fun invalidatePermissionCache(userId: Long, groupId: Long)
}
```

### 의존 예시
```kotlin
@Service
class PermissionEvaluator(
    private val groupRoleRepository: GroupRoleRepository,
    private val channelRoleBindingRepository: ChannelRoleBindingRepository,
    private val groupService: IGroupService,  // Group 도메인 의존
    private val userService: IUserService,    // User 도메인 의존
    private val auditLogger: AuditLogger
) : IPermissionEvaluator {
    override fun checkGroupAccess(userId: Long, groupId: Long): GroupPermission? {
        // 1. User 확인
        val user = userService.getUserById(userId)

        // 2. Group 확인
        val group = groupService.getGroupById(groupId)

        // 3. 권한 계산
        val roles = groupRoleRepository.findByUserIdAndGroupId(userId, groupId)
        val permissions = roles.flatMap { it.permissions }.toSet()

        // 4. 감사 로그
        auditLogger.log("CHECK_PERMISSION", userId, groupId, "SUCCESS")

        return if (permissions.isNotEmpty()) permissions else null
    }
}
```

### 구현 순서: Phase 3 (Group 이후)

---

## 4. Calendar Domain (Lv 1 - Core, 독립)

### 의존성
- **의존하는 도메인**: User, Group
- **의존받는 도메인**: 없음 (독립)

### 역할
- 그룹 일정 관리
- 개인 일정 관리
- 장소 예약 관리

### Service 인터페이스
```kotlin
interface ICalendarService {
    // Group Event
    fun getGroupEvents(groupId: Long, startDate: LocalDate, endDate: LocalDate): List<GroupEvent>
    fun createGroupEvent(groupId: Long, creatorId: Long, request: CreateEventRequest): GroupEvent

    // Personal Event
    fun getPersonalEvents(userId: Long, startDate: LocalDate, endDate: LocalDate): List<PersonalEvent>
    fun createPersonalEvent(userId: Long, request: CreateEventRequest): PersonalEvent

    // Place
    fun getPlaces(search: String?): List<Place>
    fun getPlaceAvailability(placeId: Long, date: LocalDate): List<TimeSlot>
}
```

### 의존 예시
```kotlin
@Service
class CalendarService(
    private val groupEventRepository: GroupEventRepository,
    private val personalEventRepository: PersonalEventRepository,
    private val placeRepository: PlaceRepository,
    private val groupService: IGroupService,  // Group 도메인 의존
    private val userService: IUserService     // User 도메인 의존
) : ICalendarService {
    override fun createGroupEvent(
        groupId: Long,
        creatorId: Long,
        request: CreateEventRequest
    ): GroupEvent {
        // 1. Group 확인
        val group = groupService.getGroupById(groupId)

        // 2. Creator 확인
        val creator = userService.getUserById(creatorId)

        // 3. 일정 생성
        return groupEventRepository.save(GroupEvent(
            group = group,
            creator = creator,
            title = request.title,
            // ...
        ))
    }
}
```

### 구현 순서: Phase 2 (Group과 병렬 가능)

---

## 5. Workspace Domain (Lv 2 - Service)

### 의존성
- **의존하는 도메인**: User, Group, Permission
- **의존받는 도메인**: Content

### 역할
- 워크스페이스 관리
- 채널 생성/수정/삭제
- 읽기 위치 추적

### Service 인터페이스
```kotlin
interface IWorkspaceService {
    // Workspace
    fun getWorkspaces(groupId: Long): List<Workspace>
    fun createWorkspace(groupId: Long, request: CreateWorkspaceRequest): Workspace

    // Channel
    fun getChannels(groupId: Long, userId: Long): List<Channel>
    fun createChannel(groupId: Long, creatorId: Long, request: CreateChannelRequest): Channel
    fun updateChannel(channelId: Long, request: UpdateChannelRequest): Channel
    fun deleteChannel(channelId: Long): Unit

    // Read Position
    fun updateReadPosition(channelId: Long, userId: Long, lastReadPostId: Long): ChannelReadPosition
}
```

### 의존 예시
```kotlin
@Service
class WorkspaceService(
    private val workspaceRepository: WorkspaceRepository,
    private val channelRepository: ChannelRepository,
    private val channelReadPositionRepository: ChannelReadPositionRepository,
    private val groupService: IGroupService,          // Group 도메인 의존
    private val userService: IUserService,            // User 도메인 의존
    private val permissionEvaluator: IPermissionEvaluator  // Permission 도메인 의존
) : IWorkspaceService {
    override fun getChannels(groupId: Long, userId: Long): List<Channel> {
        // 1. Group 확인
        val group = groupService.getGroupById(groupId)

        // 2. 권한 확인
        val hasAccess = permissionEvaluator.checkGroupAccess(userId, groupId) != null
        if (!hasAccess) throw AccessDeniedException()

        // 3. 채널 조회 (권한 필터링)
        val allChannels = channelRepository.findByGroupId(groupId)
        return allChannels.filter { channel ->
            permissionEvaluator.hasChannelPermission(userId, channel.id, ChannelPermission.POST_READ)
        }
    }

    override fun createChannel(
        groupId: Long,
        creatorId: Long,
        request: CreateChannelRequest
    ): Channel {
        // 1. 권한 확인 (CHANNEL_MANAGE 필요)
        val hasPermission = permissionEvaluator.hasGroupPermission(
            creatorId, groupId, GroupPermission.CHANNEL_MANAGE
        )
        if (!hasPermission) throw AccessDeniedException()

        // 2. Group 확인
        val group = groupService.getGroupById(groupId)

        // 3. Creator 확인
        val creator = userService.getUserById(creatorId)

        // 4. 채널 생성
        return channelRepository.save(Channel(
            group = group,
            createdBy = creator,
            name = request.name,
            // ...
        ))
    }
}
```

### 구현 순서: Phase 2 (Permission 이후)

---

## 6. Content Domain (Lv 3 - Application)

### 의존성
- **의존하는 도메인**: User, Group, Permission, Workspace
- **의존받는 도메인**: 없음 (최상위)

### 역할
- 게시글 생성/수정/삭제
- 댓글 생성/수정/삭제
- 조회수/좋아요 카운팅

### Service 인터페이스
```kotlin
interface IContentService {
    // Post
    fun getPosts(channelId: Long, userId: Long, limit: Int, offset: Int): List<Post>
    fun getPost(postId: Long, userId: Long): Post
    fun createPost(channelId: Long, authorId: Long, request: CreatePostRequest): Post
    fun updatePost(postId: Long, userId: Long, request: UpdatePostRequest): Post
    fun deletePost(postId: Long, userId: Long): Unit

    // Comment
    fun getComments(postId: Long, userId: Long, limit: Int, offset: Int): List<Comment>
    fun createComment(postId: Long, authorId: Long, request: CreateCommentRequest): Comment
    fun updateComment(commentId: Long, userId: Long, request: UpdateCommentRequest): Comment
    fun deleteComment(commentId: Long, userId: Long): Unit
}
```

### 의존 예시
```kotlin
@Service
class ContentService(
    private val postRepository: PostRepository,
    private val commentRepository: CommentRepository,
    private val workspaceService: IWorkspaceService,      // Workspace 도메인 의존
    private val permissionEvaluator: IPermissionEvaluator // Permission 도메인 의존
) : IContentService {
    override fun getPosts(
        channelId: Long,
        userId: Long,
        limit: Int,
        offset: Int
    ): List<Post> {
        // 1. 권한 확인 (POST_READ 필요)
        val hasPermission = permissionEvaluator.hasChannelPermission(
            userId, channelId, ChannelPermission.POST_READ
        )
        if (!hasPermission) throw AccessDeniedException()

        // 2. 게시글 조회 (권한에 따른 최적화 쿼리)
        return postRepository.findByChannelId(channelId, limit, offset)
    }

    override fun createPost(
        channelId: Long,
        authorId: Long,
        request: CreatePostRequest
    ): Post {
        // 1. 권한 확인 (POST_WRITE 필요)
        val hasPermission = permissionEvaluator.hasChannelPermission(
            authorId, channelId, ChannelPermission.POST_WRITE
        )
        if (!hasPermission) throw AccessDeniedException()

        // 2. Channel 확인
        val channel = workspaceService.getChannelById(channelId)

        // 3. Author 확인
        val author = userService.getUserById(authorId)

        // 4. 게시글 생성
        return postRepository.save(Post(
            channel = channel,
            author = author,
            content = request.content,
            // ...
        ))
    }
}
```

### 구현 순서: Phase 2 (Workspace 이후)

---

## 도메인 이벤트 (비동기 통신)

### 목적
- 도메인 간 결합도 낮추기
- 순환 참조 방지
- 비즈니스 로직 분리

### 이벤트 목록

#### 1. GroupDeletedEvent
```kotlin
data class GroupDeletedEvent(
    val groupId: Long,
    val deletedAt: LocalDateTime
)
```

**발행**: Group Domain (GroupService.deleteGroup)

**구독**:
- Workspace Domain → 해당 그룹의 모든 Workspace/Channel 삭제
- Content Domain → 해당 그룹의 모든 Post/Comment 삭제
- Calendar Domain → 해당 그룹의 모든 GroupEvent 삭제
- Permission Domain → 해당 그룹의 모든 ChannelRoleBinding 삭제

#### 2. ChannelDeletedEvent
```kotlin
data class ChannelDeletedEvent(
    val channelId: Long,
    val deletedAt: LocalDateTime
)
```

**발행**: Workspace Domain (WorkspaceService.deleteChannel)

**구독**:
- Content Domain → 해당 채널의 모든 Post/Comment 삭제
- Permission Domain → 해당 채널의 모든 ChannelRoleBinding 삭제

#### 3. MemberRemovedEvent
```kotlin
data class MemberRemovedEvent(
    val groupId: Long,
    val userId: Long,
    val removedAt: LocalDateTime
)
```

**발행**: Group Domain (GroupService.removeMember)

**구독**:
- Permission Domain → 해당 사용자의 권한 캐시 무효화
- Workspace Domain → 해당 사용자의 ChannelReadPosition 삭제

---

## 의존성 검증 체크리스트

### 순환 참조 검증
- [x] User → (의존 없음)
- [x] Group → User (단방향)
- [x] Permission → User, Group (단방향)
- [x] Calendar → User, Group (단방향, 독립)
- [x] Workspace → User, Group, Permission (단방향)
- [x] Content → User, Group, Permission, Workspace (단방향)

### Repository 직접 접근 금지
- [x] 모든 도메인 간 통신은 Service 인터페이스 경유
- [x] Repository는 자신의 도메인 Service에서만 접근

### 이벤트 사용 원칙
- [x] 삭제 작업은 이벤트 발행 (GroupDeletedEvent, ChannelDeletedEvent)
- [x] 이벤트 구독자는 자신의 도메인 데이터만 정리
- [x] 이벤트는 비동기 처리 (@Async)

---

## 구현 순서 (Phase별)

### Phase 1: Foundation & Core (User, Group)
1. **User Domain** (독립, 의존 없음)
   - UserEntity, UserRepository
   - UserService (IUserService 구현)
   - 단위 테스트 (MockK)

2. **Group Domain** (User 의존)
   - Group, GroupMember, GroupRole Entity
   - GroupRepository
   - GroupService (IGroupService 구현)
   - 단위 테스트

### Phase 2: Core & Service (Calendar, Permission, Workspace)
3. **Calendar Domain** (User, Group 의존, 병렬 가능)
   - GroupEvent, PersonalEvent, Place Entity
   - CalendarRepository
   - CalendarService (ICalendarService 구현)
   - 단위 테스트

4. **Permission Domain** (User, Group 의존)
   - ChannelRoleBinding Entity
   - PermissionEvaluator (IPermissionEvaluator 구현)
   - 권한 캐싱 (Caffeine)
   - 단위 테스트 (권한 시나리오 20개)

5. **Workspace Domain** (User, Group, Permission 의존)
   - Workspace, Channel, ChannelReadPosition Entity
   - WorkspaceRepository
   - WorkspaceService (IWorkspaceService 구현)
   - 단위 테스트

### Phase 3: Application (Content)
6. **Content Domain** (User, Group, Permission, Workspace 의존)
   - Post, Comment Entity
   - ContentRepository
   - ContentService (IContentService 구현)
   - 단위 테스트

---

## 다음 단계

1. ✅ **Phase 0-1 완료**: Entity 설계서 작성
2. ✅ **Phase 0-2 완료**: API 엔드포인트 목록 작성
3. ✅ **Phase 0-3 완료**: 도메인 의존성 그래프 작성
4. ⏭️ **Phase 0-4**: 마이그레이션 매핑표 작성 (`migration-mapping.md`)

---

## 참고 문서

- [마스터플랜](masterplan.md) - 전체 리팩터링 계획
- [Entity 설계서](entity-design.md) - 29개 Entity 구조
- [API 엔드포인트 목록](api-endpoints.md) - 47개 API 설계
- [도메인 경계](domain-boundaries.md) - Bounded Contexts 원칙
