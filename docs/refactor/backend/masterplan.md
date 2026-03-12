# 백엔드 리팩터링 마스터 플랜 (backend_new)

## Executive Summary

### 목표
기존 `backend` 프로젝트를 Clean Architecture + Domain-Driven Design 기반으로 완전히 재구성하여 **도메인 경계 명확화**, **권한 시스템 최적화**, **API 일관성 확보**를 달성합니다.

### 전략
- **병행 개발 방식**: 기존 backend 유지하며 backend_new 독립 개발 (점진적 전환)
- **우선순위**: 도메인 경계 > 권한 시스템 > API 일관성 > 성능 최적화
- **참고 문서 활용**: api-simplification.md, domain-boundaries.md, permission-guard.md
- **테스트 전략**: 단위 테스트 (MockK) + 통합 테스트 (권한 시스템 집중)

### 예상 결과
- **도메인 독립성**: 6개 도메인 완전 분리 (User, Group, Permission, Workspace, Content, Calendar)
- **API 엔드포인트**: 50개 이하 (현재 17개 Controller → 표준화)
- **권한 검증**: N+1 쿼리 제거, 역함수 패턴 적용
- **응답 형식**: 100% ApiResponse<T> 통일
- **테스트 커버리지**: 핵심 로직 60% (헌법 60/30/10 원칙)

### 전체 일정
| Phase | 작업 내용 | 산출물 |
|-------|----------|--------|
| Phase 0 | 준비 단계 (분석 및 설계) | Entity 설계서, API 목록 |
| Phase 1 | Domain Layer (Entities + Repositories) | 29개 Entity, JPA Repositories |
| Phase 2 | Service Layer (도메인별 Service) | 6개 도메인 Service |
| Phase 3 | Permission System (권한 시스템) | PermissionEvaluator, 캐싱 |
| Phase 4 | Controller Layer (REST API) | 50개 이하 엔드포인트 |
| Phase 5 | Security & Auth (OAuth2 + JWT) | 인증/인가 완성 |
| Phase 6 | 테스트 및 검증 | 단위/통합 테스트 |
| Phase 7 | 마이그레이션 (병행 운영) | 점진적 전환 전략 |

### Risk & Mitigation
| Risk | Mitigation |
|------|------------|
| 기존 API와 불일치 | Phase 7에서 호환성 레이어 구현 |
| 권한 시스템 복잡도 | Phase 3에서 집중 개발 + 테스트 |
| 도메인 순환 의존성 | Phase 0에서 의존성 그래프 사전 검증 |
| 성능 저하 | Phase 6에서 병목 분석 및 최적화 |

---

## 기존 Backend 분석

### AS-IS: 현재 구조 (backend)

```
backend/src/main/kotlin/org/castlekong/backend/
├── BackendApplication.kt
├── common/
├── config/
├── controller/ (17개 Controller)
│   ├── AuthController, GroupController, ContentController, ...
│   └── (REST API 엔드포인트 혼재)
├── dto/ (14개 DTO)
│   ├── ApiResponse, GroupDto, ContentDto, AuthDto, ...
│   └── (응답 형식 일부 불일치)
├── entity/ (29개 Entity)
│   ├── User, Group, GroupMember, GroupRole
│   ├── Workspace, Channel, ChannelRoleBinding
│   ├── Post, Comment
│   ├── GroupEvent, PersonalEvent, PersonalSchedule
│   ├── Place (장소 관리)
│   └── GroupRecruitment, RecruitmentApplication
├── repository/ (29개 Repository)
├── service/ (34개 Service)
│   ├── GroupService, ContentService, AuthService
│   ├── ChannelPermissionCacheManager (권한 캐싱)
│   ├── GroupInitializationService, ChannelInitializationService
│   └── (서비스 간 의존성 복잡)
├── security/
├── exception/
├── mapper/
├── event/
└── runner/
```

**문제점**:
1. **도메인 경계 불명확**: Service 간 직접 의존, Repository 직접 접근
2. **권한 검증 분산**: Controller, Service, Repository에 퍼져 있음
3. **API 일관성 부족**: 응답 형식, 엔드포인트 네이밍 혼재
4. **테스트 어려움**: 의존성 복잡, Mock 어려움

### TO-BE: Clean Architecture 구조 (backend_new)

```
backend_new/src/main/kotlin/com/univgroup/
├── Application.kt
├── domain/ (6개 Bounded Context)
│   ├── user/
│   │   ├── entity/
│   │   │   └── User.kt (JPA Entity)
│   │   ├── repository/
│   │   │   └── UserRepository.kt (JPA Repository)
│   │   ├── service/
│   │   │   ├── IUserService.kt (Public API)
│   │   │   └── UserService.kt (구현)
│   │   ├── dto/
│   │   │   └── UserDto.kt
│   │   └── controller/
│   │       └── UserController.kt (REST API)
│   │
│   ├── group/
│   │   ├── entity/ (Group, GroupMember, GroupRole)
│   │   ├── repository/
│   │   ├── service/
│   │   │   ├── IGroupService.kt
│   │   │   └── GroupService.kt
│   │   ├── dto/
│   │   └── controller/
│   │
│   ├── permission/
│   │   ├── entity/ (Permission, RolePermissionBinding)
│   │   ├── repository/
│   │   ├── evaluator/
│   │   │   ├── IPermissionEvaluator.kt
│   │   │   └── PermissionEvaluator.kt
│   │   └── service/
│   │       ├── PermissionCacheManager.kt
│   │       └── AuditLogger.kt
│   │
│   ├── workspace/
│   │   ├── entity/ (Workspace, Channel, ChannelRoleBinding)
│   │   ├── repository/
│   │   ├── service/
│   │   │   ├── IWorkspaceService.kt
│   │   │   └── WorkspaceService.kt
│   │   ├── dto/
│   │   └── controller/
│   │
│   ├── content/
│   │   ├── entity/ (Post, Comment)
│   │   ├── repository/
│   │   ├── service/
│   │   │   ├── IContentService.kt
│   │   │   └── ContentService.kt
│   │   ├── dto/
│   │   └── controller/
│   │
│   └── calendar/
│       ├── entity/ (GroupEvent, PersonalEvent, PersonalSchedule, Place)
│       ├── repository/
│       ├── service/
│       ├── dto/
│       └── controller/
│
└── shared/
    ├── dto/
    │   ├── ApiResponse.kt (표준 응답)
    │   └── ErrorCode.kt
    ├── exception/
    │   ├── BusinessException.kt
    │   └── GlobalExceptionHandler.kt
    ├── config/
    │   ├── SecurityConfig.kt
    │   ├── JwtConfig.kt
    │   └── CacheConfig.kt
    ├── security/
    │   ├── JwtTokenProvider.kt
    │   ├── OAuth2UserService.kt
    │   └── CustomAuthenticationFilter.kt
    └── util/
```

**개선점**:
1. **도메인 경계 명확**: 각 도메인이 독립적으로 Entity, Repository, Service 소유
2. **권한 검증 중앙화**: PermissionEvaluator가 모든 권한 검증 담당
3. **API 일관성**: 모든 엔드포인트가 ApiResponse<T> 사용, REST 동사 표준화
4. **테스트 용이**: 도메인별 독립 테스트, Mock 간소화

---

## 도메인 설계

### Bounded Contexts (6개)

#### 1. User Domain (사용자 관리)
**책임**: 사용자 생성/조회/수정, 이메일 인증, 프로필 관리

**소유 데이터**:
- `User`: 사용자 정보 (id, email, name, profileImageUrl, createdAt)
- `EmailVerification`: 이메일 인증 토큰

**Public API** (`IUserService`):
```kotlin
interface IUserService {
  fun getUserById(id: Long): User
  fun getUserByEmail(email: String): User?
  fun createUser(email: String, name: String): User
  fun updateProfile(userId: Long, name: String?, profileImageUrl: String?): User
}
```

**의존성**: 없음 (최상위 도메인)

---

#### 2. Group Domain (그룹 관리)
**책임**: 그룹 생성/수정/삭제, 멤버 관리, 역할 할당, 계층 구조 관리

**소유 데이터**:
- `Group`: 그룹 정보 (id, name, description, parentGroupId, universityId)
- `GroupMember`: 그룹 멤버십 (userId, groupId, joinedAt)
- `GroupRole`: 역할 정의 (id, groupId, name, permissions)
- `GroupJoinRequest`: 가입 신청
- `SubGroupRequest`: 하위 그룹 생성 요청

**Public API** (`IGroupService`):
```kotlin
interface IGroupService {
  fun getGroupById(id: Long): Group
  fun createGroup(params: CreateGroupRequest): Group
  fun deleteGroup(id: Long)
  fun getMembers(groupId: Long): List<GroupMember>
  fun addMember(groupId: Long, userId: Long, roleId: Long): GroupMember
  fun removeMember(groupId: Long, userId: Long)
  fun getSubGroups(parentGroupId: Long): List<Group>
}
```

**의존성**: User Domain (사용자 조회)

---

#### 3. Permission Domain (권한 검증)
**책임**: RBAC 매트릭스 관리, 권한 평가, 캐싱, 감사 로깅

**소유 데이터**:
- `GroupPermission`: 그룹 권한 정의 (name, description)
- `ChannelPermission`: 채널 권한 정의

**Public API** (`IPermissionEvaluator`):
```kotlin
interface IPermissionEvaluator {
  fun checkGroupAccess(userId: Long, groupId: Long): GroupPermission?
  fun checkChannelAccess(userId: Long, channelId: Long): ChannelPermission?
  fun hasPermission(userId: Long, resourceId: Long, action: String): Boolean
  fun getPermissionsForUser(userId: Long, groupId: Long): Set<String>
}
```

**의존성**: Group Domain (역할 조회)

---

#### 4. Workspace Domain (워크스페이스/채널 관리)
**책임**: 채널 생성/수정/삭제, 권한 바인딩 관리, 읽음 위치 추적

**소유 데이터**:
- `Workspace`: 워크스페이스 (id, groupId, name)
- `Channel`: 채널 (id, workspaceId, name, type)
- `ChannelRoleBinding`: 채널별 역할 권한 매핑
- `ChannelReadPosition`: 읽음 위치 (userId, channelId, lastReadPostId)

**Public API** (`IWorkspaceService`):
```kotlin
interface IWorkspaceService {
  fun getChannels(groupId: Long): List<Channel>
  fun createChannel(groupId: Long, name: String, type: String): Channel
  fun deleteChannel(channelId: Long)
  fun saveReadPosition(userId: Long, channelId: Long, postId: Long)
  fun getReadPosition(userId: Long, channelId: Long): Long?
}
```

**의존성**: Group Domain (그룹 조회)

---

#### 5. Content Domain (게시글/댓글 관리)
**책임**: 게시글/댓글 생성/수정/삭제/조회

**소유 데이터**:
- `Post`: 게시글 (id, channelId, authorId, content, createdAt, updatedAt)
- `Comment`: 댓글 (id, postId, authorId, content, createdAt, updatedAt)

**Public API** (`IContentService`):
```kotlin
interface IContentService {
  fun getPost(id: Long): Post
  fun listPosts(channelId: Long, permission: ChannelPermission, limit: Int, offset: Int): List<Post>
  fun createPost(channelId: Long, userId: Long, content: String): Post
  fun updatePost(postId: Long, userId: Long, content: String): Post
  fun deletePost(postId: Long, userId: Long)

  fun getComment(id: Long): Comment
  fun listComments(postId: Long, limit: Int, offset: Int): List<Comment>
  fun createComment(postId: Long, userId: Long, content: String): Comment
}
```

**의존성**: Workspace Domain (채널 조회), Permission Domain (권한 검증)

---

#### 6. Calendar Domain (일정/장소 관리)
**책임**: 그룹/개인 일정 관리, 장소 예약 관리

**소유 데이터**:
- `GroupEvent`: 그룹 일정
- `PersonalEvent`: 개인 일정
- `PersonalSchedule`: 개인 시간표
- `EventParticipant`: 일정 참가자
- `EventException`: 일정 예외
- `Place`: 장소 정보
- `PlaceReservation`: 장소 예약
- `PlaceOperatingHours`: 장소 운영 시간
- `PlaceBlockedTime`: 장소 차단 시간
- `PlaceClosure`: 장소 휴무
- `PlaceRestrictedTime`: 장소 제한 시간
- `PlaceUsageGroup`: 장소 사용 그룹

**Public API** (`ICalendarService`):
```kotlin
interface ICalendarService {
  fun getGroupEvents(groupId: Long, startDate: LocalDate, endDate: LocalDate): List<GroupEvent>
  fun createGroupEvent(groupId: Long, params: CreateEventRequest): GroupEvent
  fun getPersonalEvents(userId: Long, startDate: LocalDate, endDate: LocalDate): List<PersonalEvent>

  fun getPlaces(groupId: Long): List<Place>
  fun reservePlace(placeId: Long, userId: Long, params: ReservationRequest): PlaceReservation
}
```

**의존성**: Group Domain (그룹 조회)

---

## 도메인 의존성 그래프

```
User (독립)
  ↓
Group (User 의존)
  ↓
Permission (Group 의존)
  ↓
Workspace (Group 의존)
  ↓
Content (Workspace, Permission 의존)

Calendar (Group 의존) - 독립적
```

**검증 규칙**:
- ❌ 순환 의존성 금지 (A → B → A)
- ❌ Repository 직접 접근 금지 (다른 도메인)
- ✅ Service 인터페이스 통해서만 통신

---

## Phase별 실행 계획

### Phase 0: 준비 단계 (분석 및 설계)

**목표**: 기존 코드 분석, Entity 설계, API 목록 작성

**작업**:
1. **기존 Entity 분석** (29개)
   - User, Group, GroupMember, GroupRole
   - Workspace, Channel, ChannelRoleBinding
   - Post, Comment
   - GroupEvent, PersonalEvent, PersonalSchedule
   - Place 관련 (9개 Entity)
   - 기타 (GroupRecruitment, EmailVerification)

2. **Entity 마이그레이션 매핑**
   ```kotlin
   // 기존 backend → backend_new 매핑
   org.castlekong.backend.entity.User → com.univgroup.domain.user.entity.User
   org.castlekong.backend.entity.Group → com.univgroup.domain.group.entity.Group
   // ...
   ```

3. **API 엔드포인트 목록 작성** (50개 이하 목표)
   - 기존 17개 Controller 분석
   - REST 동사 표준화 (GET/POST/PATCH/DELETE만)
   - 쿼리 파라미터 통일 (limit, offset, sort, search)

4. **의존성 그래프 검증**
   - 순환 의존성 확인
   - 도메인 경계 검증

**산출물**:
- [ ] Entity 설계서 (`docs/refactor/backend/entity-design.md`)
- [ ] API 엔드포인트 목록 (`docs/refactor/backend/api-endpoints.md`)
- [ ] 도메인 의존성 그래프 (`docs/refactor/backend/domain-dependencies.md`)
- [ ] 마이그레이션 매핑표 (`docs/refactor/backend/migration-mapping.md`)

**검증 기준**:
- [ ] 29개 Entity 설계 완료
- [ ] API 엔드포인트 50개 이하
- [ ] 순환 의존성 없음
- [ ] 각 도메인의 Public API 정의 완료

---

### Phase 1: Domain Layer (Entities + Repositories)

**목표**: JPA Entity 및 Repository 구현 (29개)

**작업 순서** (의존성 순서):

#### 1-1. User Domain (의존성 없음)
```kotlin
// entity/User.kt
@Entity
@Table(name = "users")
data class User(
  @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
  val id: Long = 0,

  @Column(unique = true, nullable = false)
  val email: String,

  @Column(nullable = false)
  val name: String,

  val profileImageUrl: String? = null,

  @CreatedDate
  val createdAt: LocalDateTime = LocalDateTime.now(),

  @LastModifiedDate
  val updatedAt: LocalDateTime = LocalDateTime.now()
)

// repository/UserRepository.kt
interface UserRepository : JpaRepository<User, Long> {
  fun findByEmail(email: String): User?
}

// dto/UserDto.kt
data class UserDto(
  val id: Long,
  val email: String,
  val name: String,
  val profileImageUrl: String?,
  val createdAt: String
)

// 변환 함수
fun User.toDto() = UserDto(
  id = id,
  email = email,
  name = name,
  profileImageUrl = profileImageUrl,
  createdAt = createdAt.toString()
)
```

#### 1-2. Group Domain (User 의존)
```kotlin
// entity/Group.kt (5개 Entity)
- Group
- GroupMember
- GroupRole
- GroupJoinRequest
- SubGroupRequest

// repository/
- GroupRepository
- GroupMemberRepository
- GroupRoleRepository
- GroupJoinRequestRepository
- SubGroupRequestRepository
```

#### 1-3. Permission Domain
```kotlin
// entity/Permission.kt (2개 Entity)
- GroupPermission
- ChannelPermission

// repository/
- GroupPermissionRepository
- ChannelPermissionRepository
```

#### 1-4. Workspace Domain
```kotlin
// entity/Workspace.kt (4개 Entity)
- Workspace
- Channel
- ChannelRoleBinding
- ChannelReadPosition

// repository/
- WorkspaceRepository
- ChannelRepository
- ChannelRoleBindingRepository
- ChannelReadPositionRepository
```

#### 1-5. Content Domain
```kotlin
// entity/Post.kt (2개 Entity)
- Post
- Comment

// repository/
- PostRepository
- CommentRepository
```

#### 1-6. Calendar Domain
```kotlin
// entity/Event.kt (12개 Entity)
- GroupEvent
- PersonalEvent
- PersonalSchedule
- EventParticipant
- EventException
- Place
- PlaceReservation
- PlaceOperatingHours
- PlaceBlockedTime
- PlaceClosure
- PlaceRestrictedTime
- PlaceUsageGroup

// repository/ (12개 Repository)
```

**검증 기준**:
- [ ] 모든 Entity에 JPA 어노테이션 적용
- [ ] 모든 Repository에 기본 CRUD 메서드 정의
- [ ] Entity ↔ DTO 변환 함수 구현
- [ ] `./gradlew compileKotlin` 성공
- [ ] 순환 참조 없음 (Entity 간)

**산출물**:
- [ ] 29개 Entity 파일
- [ ] 29개 Repository 인터페이스
- [ ] DTO 변환 함수

---

### Phase 2: Service Layer (도메인별 Service)

**목표**: 비즈니스 로직 구현 (6개 도메인 Service)

**작업 순서**:

#### 2-1. UserService
```kotlin
// service/IUserService.kt
interface IUserService {
  fun getUserById(id: Long): User
  fun getUserByEmail(email: String): User?
  fun createUser(email: String, name: String): User
  fun updateProfile(userId: Long, name: String?, profileImageUrl: String?): User
}

// service/UserService.kt
@Service
class UserService(
  private val userRepository: UserRepository
) : IUserService {
  @Transactional(readOnly = true)
  override fun getUserById(id: Long): User {
    return userRepository.findById(id)
      .orElseThrow { UserNotFoundException("사용자를 찾을 수 없습니다: $id") }
  }

  @Transactional
  override fun createUser(email: String, name: String): User {
    val user = User(email = email, name = name)
    return userRepository.save(user)
  }

  // ...
}
```

#### 2-2. GroupService
```kotlin
// service/IGroupService.kt + GroupService.kt
- 그룹 CRUD
- 멤버 관리 (추가/제거)
- 역할 할당
- 하위 그룹 관리

// 의존성
- userService: IUserService (사용자 조회)
```

#### 2-3. WorkspaceService
```kotlin
// service/IWorkspaceService.kt + WorkspaceService.kt
- 채널 CRUD
- 읽음 위치 관리

// 의존성
- groupService: IGroupService (그룹 조회)
```

#### 2-4. ContentService
```kotlin
// service/IContentService.kt + ContentService.kt
- 게시글/댓글 CRUD

// 의존성
- workspaceService: IWorkspaceService (채널 조회)
- permissionEvaluator: IPermissionEvaluator (권한 검증은 Phase 3)
```

#### 2-5. CalendarService
```kotlin
// service/ICalendarService.kt + CalendarService.kt
- 일정 CRUD
- 장소 예약 관리

// 의존성
- groupService: IGroupService (그룹 조회)
```

**검증 기준**:
- [ ] 모든 Service가 Interface 구현
- [ ] 다른 도메인 Repository 직접 접근 없음
- [ ] 트랜잭션 어노테이션 적용
- [ ] 예외 처리 (BusinessException)
- [ ] 단위 테스트 작성 (MockK)

**산출물**:
- [ ] 6개 도메인 Service (Interface + 구현)
- [ ] 단위 테스트 (각 Service별)

---

### Phase 3: Permission System (권한 시스템)

**목표**: 권한 검증 중앙화, 역함수 패턴 적용, 캐싱

**작업**:

#### 3-1. PermissionEvaluator 구현
```kotlin
// permission/evaluator/IPermissionEvaluator.kt
interface IPermissionEvaluator {
  fun checkGroupAccess(userId: Long, groupId: Long): GroupPermission?
  fun checkChannelAccess(userId: Long, channelId: Long): ChannelPermission?
  fun hasPermission(userId: Long, resourceId: Long, action: String): Boolean
}

// permission/evaluator/PermissionEvaluator.kt
@Service
class PermissionEvaluator(
  private val groupMemberRepository: GroupMemberRepository,
  private val groupRoleRepository: GroupRoleRepository,
  private val channelRoleBindingRepository: ChannelRoleBindingRepository,
  private val auditLogger: AuditLogger
) : IPermissionEvaluator {

  @Cacheable(value = "permissions", key = "#userId + '-' + #groupId")
  override fun checkGroupAccess(userId: Long, groupId: Long): GroupPermission? {
    try {
      // 1. 멤버십 확인
      val membership = groupMemberRepository.findByUserIdAndGroupId(userId, groupId)
        ?: return null

      // 2. 역할 조회
      val roles = groupRoleRepository.findByMemberId(membership.id)

      // 3. 권한 집계
      val permissions = roles.flatMap { it.permissions }.toSet()

      // 4. 감사 로그
      auditLogger.log(
        action = "CHECK_GROUP_ACCESS",
        userId = userId,
        resourceId = groupId,
        result = "SUCCESS"
      )

      return GroupPermission(roles, permissions)
    } catch (e: Exception) {
      auditLogger.log(
        action = "CHECK_GROUP_ACCESS",
        userId = userId,
        resourceId = groupId,
        result = "FAILURE",
        reason = e.message
      )
      return null
    }
  }

  // checkChannelAccess, hasPermission 구현
}
```

#### 3-2. 권한 캐싱 (PermissionCacheManager)
```kotlin
// permission/service/PermissionCacheManager.kt
@Service
class PermissionCacheManager(
  private val cacheManager: CacheManager
) {
  fun evictUserPermissions(userId: Long) {
    cacheManager.getCache("permissions")?.evict("$userId-*")
  }

  fun evictGroupPermissions(groupId: Long) {
    cacheManager.getCache("permissions")?.evict("*-$groupId")
  }
}
```

#### 3-3. 감사 로깅 (AuditLogger)
```kotlin
// permission/service/AuditLogger.kt
@Service
class AuditLogger {
  private val logger = LoggerFactory.getLogger(AuditLogger::class.java)

  fun log(
    action: String,
    userId: Long,
    resourceId: Long,
    result: String,
    reason: String? = null
  ) {
    logger.info(
      "AUDIT | action=$action | userId=$userId | resourceId=$resourceId | result=$result | reason=$reason"
    )
    // 필요 시 DB 저장
  }
}
```

**검증 기준**:
- [ ] PermissionEvaluator 단위 테스트 (MockK)
- [ ] 권한 캐싱 동작 확인 (Redis/Caffeine)
- [ ] 감사 로그 정상 기록
- [ ] N+1 쿼리 없음 (권한 확인 1회)

**산출물**:
- [ ] PermissionEvaluator (Interface + 구현)
- [ ] PermissionCacheManager
- [ ] AuditLogger
- [ ] 권한 테스트 (20개 이상)

---

### Phase 4: Controller Layer (REST API)

**목표**: REST API 엔드포인트 구현 (50개 이하)

**API 설계 원칙** (참고: `api-simplification.md`):
1. **REST 동사 제한**: GET/POST/PATCH/DELETE만
2. **응답 통일**: 모든 엔드포인트가 `ApiResponse<T>` 반환
3. **쿼리 파라미터 표준화**: limit, offset, sort, search
4. **별도 엔드포인트 금지**: /recent, /popular, /search 금지

**작업 순서**:

#### 4-1. UserController
```kotlin
@RestController
@RequestMapping("/api/v1/users")
class UserController(
  private val userService: IUserService,
  private val permissionEvaluator: IPermissionEvaluator
) : BaseController() {

  // 1. 사용자 목록 조회
  @GetMapping
  fun listUsers(
    @RequestParam(defaultValue = "20") limit: Int,
    @RequestParam(defaultValue = "0") offset: Int,
    @RequestParam(required = false) search: String?
  ): ApiResponse<List<UserDto>> {
    // 구현
  }

  // 2. 사용자 상세 조회
  @GetMapping("/{id}")
  fun getUser(@PathVariable id: Long): ApiResponse<UserDto> {
    val user = userService.getUserById(id)
    return ApiResponse.success(user.toDto())
  }

  // 3. 사용자 생성 (Admin만)
  @PostMapping
  fun createUser(@RequestBody request: CreateUserRequest): ApiResponse<UserDto> {
    // 권한 검증 (Admin만 가능)
    val currentUserId = getCurrentUserId()
    if (!permissionEvaluator.hasPermission(currentUserId, 0, "USER_CREATE")) {
      throw AccessDeniedException()
    }

    val user = userService.createUser(request.email, request.name)
    return ApiResponse.success(user.toDto())
  }

  // 4. 프로필 수정
  @PatchMapping("/{id}")
  fun updateUser(
    @PathVariable id: Long,
    @RequestBody request: UpdateUserRequest
  ): ApiResponse<UserDto> {
    // 본인 또는 Admin만 가능
    val currentUserId = getCurrentUserId()
    if (currentUserId != id && !permissionEvaluator.hasPermission(currentUserId, 0, "USER_UPDATE")) {
      throw AccessDeniedException()
    }

    val user = userService.updateProfile(id, request.name, request.profileImageUrl)
    return ApiResponse.success(user.toDto())
  }
}
```

#### 4-2. GroupController
```kotlin
@RestController
@RequestMapping("/api/v1/groups")
class GroupController(
  private val groupService: IGroupService,
  private val permissionEvaluator: IPermissionEvaluator
) : BaseController() {

  // 1. 그룹 목록 조회
  @GetMapping
  fun listGroups(
    @RequestParam(defaultValue = "20") limit: Int,
    @RequestParam(defaultValue = "0") offset: Int,
    @RequestParam(defaultValue = "recent") sort: String,
    @RequestParam(required = false) search: String?
  ): ApiResponse<List<GroupDto>> {
    // 구현
  }

  // 2. 그룹 상세 조회
  @GetMapping("/{id}")
  fun getGroup(@PathVariable id: Long): ApiResponse<GroupDto> {
    val userId = getCurrentUserId()

    // 권한 검증 먼저 (역함수 패턴)
    val permission = permissionEvaluator.checkGroupAccess(userId, id)
      ?: throw AccessDeniedException("그룹에 접근할 수 없습니다")

    val group = groupService.getGroupById(id)
    return ApiResponse.success(group.toDto())
  }

  // 3. 그룹 생성
  @PostMapping
  fun createGroup(@RequestBody request: CreateGroupRequest): ApiResponse<GroupDto> {
    val userId = getCurrentUserId()
    val group = groupService.createGroup(request)
    return ApiResponse.success(group.toDto())
  }

  // 4. 그룹 수정
  @PatchMapping("/{id}")
  fun updateGroup(
    @PathVariable id: Long,
    @RequestBody request: UpdateGroupRequest
  ): ApiResponse<GroupDto> {
    val userId = getCurrentUserId()

    // 권한 검증
    val permission = permissionEvaluator.checkGroupAccess(userId, id)
    if (permission == null || !permission.canManageGroup) {
      throw AccessDeniedException()
    }

    val group = groupService.updateGroup(id, request)
    return ApiResponse.success(group.toDto())
  }

  // 5. 그룹 삭제
  @DeleteMapping("/{id}")
  fun deleteGroup(@PathVariable id: Long): ApiResponse<Void> {
    val userId = getCurrentUserId()

    // 권한 검증
    val permission = permissionEvaluator.checkGroupAccess(userId, id)
    if (permission == null || !permission.isOwner) {
      throw AccessDeniedException()
    }

    groupService.deleteGroup(id)
    return ApiResponse.success(null)
  }

  // 6. 그룹 멤버 목록
  @GetMapping("/{id}/members")
  fun listMembers(
    @PathVariable id: Long,
    @RequestParam(defaultValue = "20") limit: Int,
    @RequestParam(defaultValue = "0") offset: Int
  ): ApiResponse<List<GroupMemberDto>> {
    val userId = getCurrentUserId()

    // 권한 검증
    val permission = permissionEvaluator.checkGroupAccess(userId, id)
      ?: throw AccessDeniedException()

    val members = groupService.getMembers(id)
    return ApiResponse.success(members.map { it.toDto() })
  }

  // 7. 멤버 추가
  @PostMapping("/{id}/members")
  fun addMember(
    @PathVariable id: Long,
    @RequestBody request: AddMemberRequest
  ): ApiResponse<GroupMemberDto> {
    val userId = getCurrentUserId()

    // 권한 검증
    val permission = permissionEvaluator.checkGroupAccess(userId, id)
    if (permission == null || !permission.canManageMembers) {
      throw AccessDeniedException()
    }

    val member = groupService.addMember(id, request.userId, request.roleId)
    return ApiResponse.success(member.toDto())
  }
}
```

#### 4-3. ContentController (역함수 패턴 적용)
```kotlin
@RestController
@RequestMapping("/api/v1/channels")
class ContentController(
  private val contentService: IContentService,
  private val permissionEvaluator: IPermissionEvaluator
) : BaseController() {

  // 1. 게시글 목록 조회 (권한 먼저 확인)
  @GetMapping("/{channelId}/posts")
  fun listPosts(
    @PathVariable channelId: Long,
    @RequestParam(defaultValue = "20") limit: Int,
    @RequestParam(defaultValue = "0") offset: Int,
    @RequestParam(defaultValue = "recent") sort: String
  ): ApiResponse<List<PostDto>> {
    val userId = getCurrentUserId()

    // 1단계: 권한 검증 먼저 (DB 접근 전)
    val permission = permissionEvaluator.checkChannelAccess(userId, channelId)
      ?: throw AccessDeniedException("채널에 접근할 수 없습니다")

    // 2단계: 권한과 함께 Service 호출 (최적화된 쿼리)
    val posts = contentService.listPosts(channelId, permission, limit, offset)

    return ApiResponse.success(posts.map { it.toDto() })
  }

  // 2. 게시글 작성
  @PostMapping("/{channelId}/posts")
  fun createPost(
    @PathVariable channelId: Long,
    @RequestBody request: CreatePostRequest
  ): ApiResponse<PostDto> {
    val userId = getCurrentUserId()

    // 권한 검증
    val permission = permissionEvaluator.checkChannelAccess(userId, channelId)
    if (permission == null || !permission.canCreatePost) {
      throw AccessDeniedException()
    }

    val post = contentService.createPost(channelId, userId, request.content)
    return ApiResponse.success(post.toDto())
  }

  // ...
}
```

#### 4-4. 나머지 Controller
- WorkspaceController (채널 관리)
- CalendarController (일정/장소 관리)

**최종 엔드포인트 목록** (50개 이하):

```
// User (5개)
GET    /api/v1/users?limit=20&offset=0&search=keyword
GET    /api/v1/users/{id}
POST   /api/v1/users
PATCH  /api/v1/users/{id}
DELETE /api/v1/users/{id}

// Group (10개)
GET    /api/v1/groups?limit=20&offset=0&sort=recent
GET    /api/v1/groups/{id}
POST   /api/v1/groups
PATCH  /api/v1/groups/{id}
DELETE /api/v1/groups/{id}
GET    /api/v1/groups/{id}/members?limit=20&offset=0
POST   /api/v1/groups/{id}/members
PATCH  /api/v1/groups/{id}/members/{userId}
DELETE /api/v1/groups/{id}/members/{userId}
GET    /api/v1/groups/{id}/subgroups

// Workspace (10개)
GET    /api/v1/groups/{groupId}/workspaces
GET    /api/v1/groups/{groupId}/workspaces/{id}
POST   /api/v1/groups/{groupId}/workspaces
PATCH  /api/v1/groups/{groupId}/workspaces/{id}
DELETE /api/v1/groups/{groupId}/workspaces/{id}
GET    /api/v1/groups/{groupId}/channels
GET    /api/v1/groups/{groupId}/channels/{id}
POST   /api/v1/groups/{groupId}/channels
PATCH  /api/v1/groups/{groupId}/channels/{id}
DELETE /api/v1/groups/{groupId}/channels/{id}

// Content (10개)
GET    /api/v1/channels/{channelId}/posts?limit=20&offset=0&sort=recent
GET    /api/v1/channels/{channelId}/posts/{id}
POST   /api/v1/channels/{channelId}/posts
PATCH  /api/v1/channels/{channelId}/posts/{id}
DELETE /api/v1/channels/{channelId}/posts/{id}
GET    /api/v1/posts/{postId}/comments?limit=20&offset=0
GET    /api/v1/posts/{postId}/comments/{id}
POST   /api/v1/posts/{postId}/comments
PATCH  /api/v1/posts/{postId}/comments/{id}
DELETE /api/v1/posts/{postId}/comments/{id}

// Calendar (15개)
GET    /api/v1/groups/{groupId}/events?start=2025-01-01&end=2025-12-31
GET    /api/v1/groups/{groupId}/events/{id}
POST   /api/v1/groups/{groupId}/events
PATCH  /api/v1/groups/{groupId}/events/{id}
DELETE /api/v1/groups/{groupId}/events/{id}
GET    /api/v1/users/{userId}/events?start=2025-01-01&end=2025-12-31
GET    /api/v1/users/{userId}/schedules
POST   /api/v1/users/{userId}/schedules
GET    /api/v1/groups/{groupId}/places
GET    /api/v1/groups/{groupId}/places/{id}
POST   /api/v1/groups/{groupId}/places
GET    /api/v1/places/{placeId}/reservations?date=2025-01-01
POST   /api/v1/places/{placeId}/reservations
PATCH  /api/v1/places/{placeId}/reservations/{id}
DELETE /api/v1/places/{placeId}/reservations/{id}

// 총 50개
```

**검증 기준**:
- [ ] 모든 엔드포인트가 `ApiResponse<T>` 반환
- [ ] 권한 검증이 Controller에서 먼저 수행
- [ ] 쿼리 파라미터 표준화 (limit, offset, sort, search)
- [ ] 별도 엔드포인트 없음 (/recent, /popular 금지)
- [ ] 통합 테스트 작성 (MockMvc)

**산출물**:
- [ ] 6개 Controller
- [ ] 50개 API 엔드포인트
- [ ] 통합 테스트 (각 Controller별)

---

### Phase 5: Security & Auth (OAuth2 + JWT)

**목표**: Google OAuth2 인증, JWT 토큰 생성/검증, Spring Security 설정

**작업**:

#### 5-1. JWT 토큰 Provider
```kotlin
// shared/security/JwtTokenProvider.kt
@Component
class JwtTokenProvider(
  @Value("\${jwt.secret}") private val secret: String,
  @Value("\${jwt.expiration}") private val expiration: Long
) {
  fun generateToken(userId: Long, email: String): String {
    val now = Date()
    val expiryDate = Date(now.time + expiration)

    return Jwts.builder()
      .setSubject(userId.toString())
      .claim("email", email)
      .setIssuedAt(now)
      .setExpiration(expiryDate)
      .signWith(Keys.hmacShaKeyFor(secret.toByteArray()))
      .compact()
  }

  fun validateToken(token: String): Boolean {
    try {
      Jwts.parserBuilder()
        .setSigningKey(Keys.hmacShaKeyFor(secret.toByteArray()))
        .build()
        .parseClaimsJws(token)
      return true
    } catch (e: Exception) {
      return false
    }
  }

  fun getUserIdFromToken(token: String): Long {
    val claims = Jwts.parserBuilder()
      .setSigningKey(Keys.hmacShaKeyFor(secret.toByteArray()))
      .build()
      .parseClaimsJws(token)
      .body

    return claims.subject.toLong()
  }
}
```

#### 5-2. OAuth2 User Service
```kotlin
// shared/security/OAuth2UserService.kt
@Service
class OAuth2UserService(
  private val userService: IUserService
) : DefaultOAuth2UserService() {

  override fun loadUser(userRequest: OAuth2UserRequest): OAuth2User {
    val oAuth2User = super.loadUser(userRequest)

    // Google 사용자 정보 추출
    val email = oAuth2User.getAttribute<String>("email")!!
    val name = oAuth2User.getAttribute<String>("name")!!
    val picture = oAuth2User.getAttribute<String>("picture")

    // DB에 사용자 생성 또는 조회
    val user = userService.getUserByEmail(email)
      ?: userService.createUser(email, name)

    return CustomOAuth2User(user, oAuth2User.attributes)
  }
}
```

#### 5-3. Security Configuration
```kotlin
// shared/config/SecurityConfig.kt
@Configuration
@EnableWebSecurity
class SecurityConfig(
  private val jwtTokenProvider: JwtTokenProvider,
  private val oAuth2UserService: OAuth2UserService
) {

  @Bean
  fun securityFilterChain(http: HttpSecurity): SecurityFilterChain {
    http
      .csrf { it.disable() }
      .cors { it.configurationSource(corsConfigurationSource()) }
      .sessionManagement { it.sessionCreationPolicy(SessionCreationPolicy.STATELESS) }
      .authorizeHttpRequests { auth ->
        auth
          .requestMatchers("/api/v1/auth/**").permitAll()
          .requestMatchers("/swagger-ui/**", "/v3/api-docs/**").permitAll()
          .anyRequest().authenticated()
      }
      .oauth2Login { oauth2 ->
        oauth2.userInfoEndpoint { it.userService(oAuth2UserService) }
      }
      .addFilterBefore(
        JwtAuthenticationFilter(jwtTokenProvider),
        UsernamePasswordAuthenticationFilter::class.java
      )

    return http.build()
  }

  @Bean
  fun corsConfigurationSource(): CorsConfigurationSource {
    val configuration = CorsConfiguration()
    configuration.allowedOrigins = listOf("http://localhost:5173")
    configuration.allowedMethods = listOf("GET", "POST", "PATCH", "DELETE")
    configuration.allowedHeaders = listOf("*")
    configuration.allowCredentials = true

    val source = UrlBasedCorsConfigurationSource()
    source.registerCorsConfiguration("/**", configuration)
    return source
  }
}
```

#### 5-4. Auth Controller
```kotlin
// shared/controller/AuthController.kt
@RestController
@RequestMapping("/api/v1/auth")
class AuthController(
  private val jwtTokenProvider: JwtTokenProvider,
  private val userService: IUserService
) {

  @PostMapping("/google")
  fun authenticateWithGoogle(@RequestBody request: GoogleAuthRequest): ApiResponse<AuthResponse> {
    // Google ID 토큰 검증
    val email = verifyGoogleToken(request.idToken)

    // 사용자 조회 또는 생성
    val user = userService.getUserByEmail(email)
      ?: userService.createUser(email, request.name)

    // JWT 생성
    val token = jwtTokenProvider.generateToken(user.id, user.email)

    return ApiResponse.success(
      AuthResponse(
        token = token,
        user = user.toDto()
      )
    )
  }

  @PostMapping("/refresh")
  fun refreshToken(@RequestBody request: RefreshTokenRequest): ApiResponse<AuthResponse> {
    // 토큰 갱신 로직
  }
}
```

**검증 기준**:
- [ ] Google OAuth2 로그인 성공
- [ ] JWT 토큰 생성/검증 성공
- [ ] 인증된 요청만 API 접근 가능
- [ ] CORS 설정 정상 동작
- [ ] 통합 테스트 (Spring Security Test)

**산출물**:
- [ ] JwtTokenProvider
- [ ] OAuth2UserService
- [ ] SecurityConfig
- [ ] AuthController
- [ ] 인증 테스트

---

### Phase 6: 테스트 및 검증

**목표**: 단위/통합 테스트, 권한 시스템 검증, 성능 측정

**작업**:

#### 6-1. 단위 테스트 (MockK)
```kotlin
// UserServiceTest.kt
@SpringBootTest
class UserServiceTest {

  @MockkBean
  private lateinit var userRepository: UserRepository

  @Autowired
  private lateinit var userService: UserService

  @Test
  fun `사용자 생성 성공`() {
    // Given
    val email = "test@example.com"
    val name = "Test User"
    val savedUser = User(id = 1, email = email, name = name)

    every { userRepository.save(any()) } returns savedUser

    // When
    val result = userService.createUser(email, name)

    // Then
    assertThat(result.email).isEqualTo(email)
    verify(exactly = 1) { userRepository.save(any()) }
  }

  @Test
  fun `존재하지 않는 사용자 조회 시 예외`() {
    // Given
    every { userRepository.findById(1) } returns Optional.empty()

    // When & Then
    assertThrows<UserNotFoundException> {
      userService.getUserById(1)
    }
  }
}
```

#### 6-2. 통합 테스트 (MockMvc)
```kotlin
// GroupControllerTest.kt
@WebMvcTest(GroupController::class)
class GroupControllerTest {

  @Autowired
  private lateinit var mockMvc: MockMvc

  @MockkBean
  private lateinit var groupService: IGroupService

  @MockkBean
  private lateinit var permissionEvaluator: IPermissionEvaluator

  @Test
  fun `그룹 조회 성공`() {
    // Given
    val groupId = 1L
    val group = Group(id = groupId, name = "Test Group")

    every { permissionEvaluator.checkGroupAccess(any(), groupId) } returns mockPermission
    every { groupService.getGroupById(groupId) } returns group

    // When & Then
    mockMvc.perform(
      get("/api/v1/groups/$groupId")
        .header("Authorization", "Bearer $token")
    )
      .andExpect(status().isOk)
      .andExpect(jsonPath("$.success").value(true))
      .andExpect(jsonPath("$.data.name").value("Test Group"))
  }

  @Test
  fun `권한 없는 사용자 그룹 조회 실패`() {
    // Given
    val groupId = 1L

    every { permissionEvaluator.checkGroupAccess(any(), groupId) } returns null

    // When & Then
    mockMvc.perform(
      get("/api/v1/groups/$groupId")
        .header("Authorization", "Bearer $token")
    )
      .andExpect(status().isForbidden)
  }
}
```

#### 6-3. 권한 시스템 테스트
```kotlin
// PermissionEvaluatorTest.kt
@SpringBootTest
class PermissionEvaluatorTest {

  @Autowired
  private lateinit var permissionEvaluator: IPermissionEvaluator

  @Test
  fun `그룹 오너 권한 확인`() {
    // Given
    val userId = 1L
    val groupId = 1L

    // When
    val permission = permissionEvaluator.checkGroupAccess(userId, groupId)

    // Then
    assertThat(permission).isNotNull
    assertThat(permission!!.isOwner).isTrue
    assertThat(permission.canManageGroup).isTrue
  }

  @Test
  fun `N+1 쿼리 방지 확인`() {
    // Given
    val userId = 1L
    val groupId = 1L

    // When
    val queryCount = measureQueryCount {
      permissionEvaluator.checkGroupAccess(userId, groupId)
    }

    // Then
    assertThat(queryCount).isLessThanOrEqualTo(2) // 권한 확인 1회 + 역할 조회 1회
  }
}
```

#### 6-4. 성능 측정
```bash
# 1. API 응답 시간 측정
ab -n 1000 -c 10 http://localhost:8080/api/v1/groups/1

# 2. 권한 캐싱 효과 측정
# - 첫 요청: ~50ms
# - 캐시 적중: ~5ms (10배 향상)

# 3. N+1 쿼리 확인
# - Hibernate SQL 로그 확인
# - 쿼리 개수 카운트
```

**검증 기준**:
- [ ] 단위 테스트 커버리지 60% 이상
- [ ] 통합 테스트 모든 Controller 커버
- [ ] 권한 시스템 테스트 통과
- [ ] N+1 쿼리 없음 확인
- [ ] API 응답 시간 100ms 이하

**산출물**:
- [ ] 단위 테스트 (각 Service별)
- [ ] 통합 테스트 (각 Controller별)
- [ ] 권한 테스트 (20개 이상)
- [ ] 성능 측정 보고서

---

### Phase 7: 마이그레이션 (병행 운영)

**목표**: 기존 backend와 backend_new 병행 운영, 점진적 전환

**전략**:

#### 7-1. 호환성 레이어 구현
```kotlin
// shared/adapter/LegacyApiAdapter.kt
@RestController
@RequestMapping("/api/legacy")
class LegacyApiAdapter(
  private val groupService: IGroupService
) {
  // 기존 API 형식 유지
  @GetMapping("/groups/{id}")
  fun getGroupLegacy(@PathVariable id: Long): GroupDto {
    val group = groupService.getGroupById(id)
    return group.toDto() // ApiResponse 없이 직접 반환
  }
}
```

#### 7-2. 데이터베이스 공유
```yaml
# application.yml (backend_new)
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/univgroup # 기존 DB 공유
    username: ${DB_USERNAME}
    password: ${DB_PASSWORD}
  jpa:
    hibernate:
      ddl-auto: validate # 기존 스키마 검증만
```

#### 7-3. 점진적 전환 계획
```
Week 1-2: backend_new 배포 (read-only 모드)
  - GET 엔드포인트만 backend_new로 라우팅
  - POST/PATCH/DELETE는 기존 backend 유지

Week 3-4: 쓰기 기능 전환
  - User, Group 도메인 먼저 전환
  - Content, Calendar 순차 전환

Week 5: 기존 backend 종료
  - 모든 트래픽을 backend_new로 전환
  - 기존 backend 모니터링 후 종료
```

#### 7-4. 롤백 계획
```
문제 발생 시:
1. Nginx 라우팅 변경 (backend_new → backend)
2. 데이터 정합성 확인
3. 문제 원인 분석 및 수정
4. 재배포
```

**검증 기준**:
- [ ] 기존 API와 100% 호환
- [ ] 데이터베이스 정합성 유지
- [ ] 성능 저하 없음 (±5%)
- [ ] 롤백 가능 (10분 이내)

**산출물**:
- [ ] 호환성 레이어
- [ ] 마이그레이션 스크립트
- [ ] 롤백 가이드
- [ ] 모니터링 대시보드

---

## 검증 체크리스트

### 구조 품질
- [ ] 6개 도메인 완전 분리
- [ ] 도메인 간 순환 의존성 없음
- [ ] Repository 직접 접근 없음 (다른 도메인)
- [ ] 모든 Service가 Interface 구현

### API 품질
- [ ] 엔드포인트 50개 이하
- [ ] 모든 응답이 `ApiResponse<T>` 형식
- [ ] REST 동사 표준화 (GET/POST/PATCH/DELETE만)
- [ ] 쿼리 파라미터 통일 (limit, offset, sort, search)

### 권한 시스템
- [ ] PermissionEvaluator 단일 진입점
- [ ] 권한 검증이 Controller에서 먼저 수행
- [ ] N+1 쿼리 없음 (권한 확인 1회)
- [ ] 권한 캐싱 동작
- [ ] 감사 로그 기록

### 테스트
- [ ] 단위 테스트 커버리지 60% 이상
- [ ] 통합 테스트 모든 Controller 커버
- [ ] 권한 테스트 20개 이상
- [ ] 성능 테스트 통과

### 보안
- [ ] Google OAuth2 인증 성공
- [ ] JWT 토큰 검증 정상
- [ ] CORS 설정 정상
- [ ] SQL Injection 방지

---

## 참고 문서

### 필수 문서
- [API 단순화](./api-simplification.md) - REST API 설계 원칙
- [도메인 경계](./domain-boundaries.md) - Bounded Contexts 정의
- [권한 검증 (역함수 패턴)](./permission-guard.md) - 권한 시스템 설계
- [헌법 v1.2.0](../../.specify/memory/constitution.md) - 프로젝트 핵심 원칙

### 구현 가이드
- [Backend 구현 가이드](../../implementation/backend/README.md)
- [API Reference](../../implementation/api-reference.md)
- [Database Reference](../../implementation/database-reference.md)

### 기존 코드 참고
- `backend/src/main/kotlin/` - 기존 구현 패턴 참고
- 특히 참고할 파일:
  - `entity/User.kt`, `entity/Group.kt` - Entity 설계
  - `service/GroupService.kt` - Service 패턴
  - `controller/GroupController.kt` - Controller 패턴
  - `security/JwtTokenProvider.kt` - JWT 구현

---

## 최종 목표

**backend_new 완성 시 달성 목표**:
1. ✅ **도메인 독립성**: 6개 도메인 완전 분리, 순환 의존성 0개
2. ✅ **API 일관성**: 50개 이하 엔드포인트, 100% ApiResponse<T>
3. ✅ **권한 최적화**: N+1 쿼리 제거, 권한 캐싱 적용
4. ✅ **테스트 커버리지**: 핵심 로직 60% (헌법 준수)
5. ✅ **성능**: API 응답 100ms 이하, 캐시 적중률 90% 이상
6. ✅ **보안**: Google OAuth2 + JWT, RBAC + Override 권한 시스템
7. ✅ **유지보수성**: 새 도메인 추가 시 기존 코드 수정 0개

**완료 후 다음 단계**:
- Phase 7에서 기존 backend 점진적 전환
- 모니터링 및 성능 최적화
- 새 기능 추가 (Recruitment, Place 확장)
