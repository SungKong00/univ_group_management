# 백엔드 구현 가이드 (Backend Implementation Guide)

## 최근 업데이트 (2025-10-04)
- **내 그룹 목록 API** 추가: `GET /api/me/groups` 엔드포인트 구현 완료
- 워크스페이스 자동 진입 기능 지원을 위한 계층 레벨 계산 로직 구현
- JOIN FETCH 최적화를 통한 N+1 문제 방지

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
    private val groupMemberRepository: GroupMemberRepository,
    private val channelRepository: ChannelRepository,
    private val channelRoleBindingRepository: ChannelRoleBindingRepository,
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

        // 2. 대상 타입별 권한 검증 라우팅
        return when (targetType) {
            "GROUP" -> checkGroupPermission(targetId, user.id, permission)
            "CHANNEL" -> checkChannelPermission(targetId, user.id, permission)
            "RECRUITMENT" -> checkRecruitmentPermission(targetId, user.id, permission)
            "APPLICATION" -> checkApplicationPermission(targetId, user.id, permission)
            else -> false
        }
    }

    private fun checkChannelPermission(channelId: Long, userId: Long, permission: String): Boolean {
        // 1단계: 채널 조회 및 그룹 멤버십 확인
        val channel = channelRepository.findById(channelId).orElse(null) ?: return false
        val member = groupMemberRepository.findByGroupIdAndUserId(channel.group.id, userId)
            .orElse(null) ?: return false

        // 2단계: 채널 권한 바인딩 확인
        val binding = channelRoleBindingRepository
            .findByChannelIdAndGroupRoleId(channelId, member.role.id) ?: return false

        return try {
            val channelPermission = ChannelPermission.valueOf(permission)
            binding.permissions.contains(channelPermission)
        } catch (e: IllegalArgumentException) {
            log.warn("Invalid channel permission: $permission", e)
            false
        }
    }
}
```

### 권한 검증 레이어 설계 결정

**핵심 결정: Security Layer에서 Repository 직접 사용**

GroupPermissionEvaluator는 Spring Security의 일부로서 `@PreAuthorize` 어노테이션이 실행되는 시점에 동작합니다. 이는 Controller 메서드가 호출되기 **전**에 실행되므로, Service Layer를 우회하여 Repository를 직접 사용하는 것이 적절합니다.

**Option A (채택): Security → Repository 직접 호출**
```
@PreAuthorize 실행 → GroupPermissionEvaluator
                    ↓
                Repository (직접)
                    ↓
                결과 반환 → true/false
                    ↓
         true면 Controller 실행, false면 403
```

**장점**:
- 빠른 권한 검증 (Service Layer 우회)
- 순수한 권한 검증 로직 (비즈니스 로직과 분리)
- 명확한 책임 분리: Security는 "접근 가능 여부만" 판단
- 불필요한 데이터 로딩 방지 (권한 검증에 필요한 최소 데이터만)

**Option B (기각): ChannelPermissionService 생성**
```
@PreAuthorize → GroupPermissionEvaluator
                    ↓
            ChannelPermissionService
                    ↓
                Repository
```

**기각 이유**:
- 권한 검증은 비즈니스 로직이 아닌 인프라 관심사
- Service Layer가 순수 권한 검증만 수행하면 역할이 모호해짐
- 추가 레이어로 인한 복잡도 증가
- 트랜잭션 경계 설정이 불필요 (읽기 전용 권한 체크)

**구현 원칙**:
1. **빠른 실패(Fail Fast)**: 조건 미충족 시 즉시 `false` 반환
2. **최소 권한 원칙**: 필요한 데이터만 조회 (엔티티 전체 로딩 지양)
3. **무상태(Stateless)**: 각 권한 검증은 독립적으로 실행
4. **로깅**: 잘못된 권한 요청은 경고 로그 기록

**검증 플로우 (채널 권한 예시)**:
1. 채널 존재 확인 (`channelRepository.findById`)
2. 그룹 멤버십 확인 (`groupMemberRepository.findByGroupIdAndUserId`)
3. 역할-채널 바인딩 확인 (`channelRoleBindingRepository.findByChannelIdAndGroupRoleId`)
4. 요청한 권한이 바인딩에 포함되어 있는지 확인

**그룹 권한 vs 채널 권한 차이**:
- **그룹 권한**: PermissionService의 캐시를 활용 (복잡한 상속/오버라이드 로직)
- **채널 권한**: Repository 직접 조회 (단순한 바인딩 매핑 확인)

**참고**: 채널 권한은 PermissionService 캐시를 사용하지 않습니다. 채널별 권한 바인딩은 그룹 권한보다 단순하고, 캐시 무효화 복잡도를 피하기 위해 직접 조회를 선택했습니다.

## 표준 응답 형식 (갱신)
```kotlin
data class ApiResponse<T>(
    val success: Boolean,
    val data: T? = null,
    val error: ErrorResponse? = null,
    val timestamp: LocalDateTime = LocalDateTime.now()
)

data class ErrorResponse(
    val code: String,
    val message: String,
)
```
- 이전 `message` / `errorCode` 분리 필드 → `error.code`, `error.message` 로 통합
- 모든 실패 응답은 `success=false` + `error` 객체 포함

### 전역 예외 매핑 (발췌)
| ErrorCode | HTTP | 비고 |
|-----------|------|------|
| INVALID_TOKEN / EXPIRED_TOKEN / UNAUTHORIZED | 401 | 인증/토큰 문제 |
| FORBIDDEN | 403 | 권한 부족 |
| SYSTEM_ROLE_IMMUTABLE | 403 | 시스템 역할 수정/삭제 금지 |
| GROUP_ROLE_NAME_ALREADY_EXISTS | 409 | 역할명 충돌 |

## 역할 & 권한 (System Role 불변성)
- 시스템 역할: OWNER / ADVISOR / MEMBER
- 이름/우선순위/권한 수정 및 삭제 시도 → `SYSTEM_ROLE_IMMUTABLE`
- 커스텀 역할만 CRUD 허용
- GroupRole 엔티티: data class 제거, id 기반 equals/hashCode

## 채널 권한 (Permission-Centric 모델)
- 새 채널 생성 시 ChannelRoleBinding 0개
- 권한 단위(ChannelPermission) 별 허용 역할 리스트 지정
- CHANNEL_VIEW 없으면 채널 네비게이션 미표시
- Owner 도 매핑 없으면 읽기/쓰기 불가 (자동 상속 제거)

### 권한 매트릭스 예시
```
CHANNEL_VIEW: OWNER, MEMBER
POST_READ:    OWNER, MEMBER
POST_WRITE:   OWNER
COMMENT_WRITE:OWNER
FILE_UPLOAD:  OWNER(optional)
```

## 권한 캐시 무효화 패턴
```kotlin
permissionService.invalidateGroup(groupId)      // 역할/바인딩 구조 변경 후
authorityCache.invalidate(userId)              // (사용자 단위 캐시가 별도로 있을 경우)
```
무효화 트리거:
- 역할 생성/수정/삭제
- 멤버 역할 변경
- 채널 권한 바인딩 추가/갱신/삭제

## 컨텐츠 삭제 벌크 순서 (Workspace/Channel)
```
ChannelRoleBinding → Comments → Posts → Channels
```
- N+1 및 TransientObjectException 방지
- Post/Comment 삭제는 ID 집합 기반 bulk query 활용

## 구현 주의사항 업데이트
| 항목 | 이전 | 현재 |
|------|------|------|
| 채널 기본 권한 | Owner/Member 자동 부여 | 자동 없음 (수동 매핑 필요) |
| 시스템 역할 수정 | 일부 허용 | 전면 금지 (SYSTEM_ROLE_IMMUTABLE) |
| ApiResponse 실패 | message/errorCode 혼용 | error.code / error.message 고정 |
| 삭제 로직 | 엔티티 순회 다중 delete | 벌크 순서 기반 배치 |

## 컨트롤러 테스트 가이드

### 통합 테스트 패턴 (권장)

**@SpringBootTest 사용** ✅
```kotlin
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.MOCK)
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
@DisplayName("MeController 통합 테스트")
class MeControllerTest {

    @Autowired private lateinit var mockMvc: MockMvc
    @Autowired private lateinit var userRepository: UserRepository
    @Autowired private lateinit var jwtTokenProvider: JwtTokenProvider

    private lateinit var testUser: User
    private lateinit var token: String

    @BeforeEach
    fun setUp() {
        testUser = userRepository.save(
            TestDataFactory.createTestUser(
                email = "test-${System.nanoTime()}@example.com"
            )
        )
        token = generateToken(testUser)
    }

    private fun generateToken(user: User): String {
        val authentication = UsernamePasswordAuthenticationToken(
            user.email,
            null,
            listOf(SimpleGrantedAuthority("ROLE_${user.globalRole.name}"))
        )
        return jwtTokenProvider.generateAccessToken(authentication)
    }

    @Test
    @DisplayName("GET /api/me - 내 정보 조회 성공")
    fun getMe_success() {
        mockMvc.perform(
            get("/api/me")
                .header("Authorization", "Bearer $token")
                .accept(MediaType.APPLICATION_JSON)
        )
        .andExpect(status().isOk)
        .andExpect(jsonPath("$.success").value(true))
        .andExpect(jsonPath("$.data.email").value(testUser.email))
    }
}
```

### @WebMvcTest vs @SpringBootTest 선택 기준

**@WebMvcTest (슬라이스 테스트)**
- Controller만 테스트, Service는 Mock 처리
- 빠른 테스트 실행 필요
- 단순한 컨트롤러 (적은 의존성)

**@SpringBootTest (통합 테스트)** ✅ 권장
- 실제 환경과 동일한 인증/권한 흐름 검증
- 다중 Service 의존성이 있는 컨트롤러
- Spring Security 통합 필요
- 실제 Repository/Service 동작 검증

**예시: MeController의 경우**
```kotlin
// ❌ @WebMvcTest 사용 시 문제
// NoSuchBeanDefinitionException: GroupMemberService 발생
// → MeController가 UserService + GroupMemberService 의존

// ✅ @SpringBootTest 사용
// 모든 빈이 로드되어 실제 환경과 동일하게 테스트
```

### Spring Security 인증 테스트 패턴

```kotlin
// ❌ 잘못된 예: 특정 상태 코드 기대
.andExpect(status().isUnauthorized) // 401만 기대

// ✅ 올바른 예: 4xx 클라이언트 에러 허용
.andExpect(status().is4xxClientError) // 401 or 403 허용
```

**이유**: Spring Security는 상황에 따라 401(Unauthorized) 또는 403(Forbidden)을 반환할 수 있으므로,
`.is4xxClientError`를 사용하여 두 상태 코드를 모두 허용하는 것이 안전합니다.

### 기타 테스트 가이드
- 시스템 역할 수정/삭제 테스트: 기대 ErrorCode = SYSTEM_ROLE_IMMUTABLE
- 새 채널 생성 직후 읽기 실패 테스트: CHANNEL_VIEW / POST_READ 미매핑 시 FORBIDDEN
- 캐시 무효화 검증: 역할 권한 변경 → 이전 권한으로 접근 실패하는지 확인

---

## 캘린더 시스템 구현 가이드 (예정)

> **개발 우선순위**: Phase 6 이후
> **상태**: 개념 설계 완료, 구현 미착수
> **관련 문서**: [캘린더 시스템](../concepts/calendar-system.md) | [설계 결정사항](../concepts/calendar-design-decisions.md)

### 구현 방향

1. **권한 통합** (DD-CAL-001)
   - GroupRole에 4개 캘린더 권한 추가
   - PermissionService 확장 (캘린더 권한 확인 로직)
   - GroupPermissionEvaluator에 CALENDAR 타입 추가

2. **반복 일정 처리** (DD-CAL-002, DD-CAL-003)
   - 생성 시 반복 범위만큼 인스턴스 명시적 저장
   - EventException으로 예외 관리
   - 일정 수정 시 "이 일정만" / "반복 전체" 분기 로직

3. **참여자 관리** (DD-CAL-004)
   - 일정 생성 시 EventParticipant 자동 생성
   - 참여 상태 변경 API (참여/불참/보류)
   - 불참 사유 저장

4. **장소 예약 통합** (DD-CAL-006)
   - PlaceReservation을 GroupEvent FK로 연결
   - 일정 삭제 시 예약 계단식 삭제
   - 장소 캘린더 = 장소 필터링된 일정 조회

### 다음 단계
1. 6개 엔티티 클래스 작성 (Kotlin)
2. Repository 및 Service 레이어 구현
3. 권한 검증 로직 통합
4. API 엔드포인트 구현 ([API 참조](api-reference.md) 참조)

---

## 관련 문서
- [권한 시스템](../concepts/permission-system.md)
- [채널 권한](../concepts/channel-permissions.md)
- [워크스페이스 & 채널](../concepts/workspace-channel.md)
- [캘린더 시스템](../concepts/calendar-system.md)
- [API 레퍼런스](api-reference.md)
- [트러블슈팅](../troubleshooting/permission-errors.md)
