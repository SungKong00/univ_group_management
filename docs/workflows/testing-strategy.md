# 테스트 전략 (Testing Strategy)

## 테스트 피라미드

```
        E2E Tests (적음)
       ─────────────────
      Integration Tests (보통)
     ─────────────────────────
    Unit Tests (많음)
   ─────────────────────────────
```

### 우선순위
1. **통합 테스트 (60%)**: 실제 동작 검증
2. **단위 테스트 (30%)**: 복잡한 비즈니스 로직
3. **E2E 테스트 (10%)**: 핵심 사용자 플로우

## 백엔드 테스트 전략

### 1. 통합 테스트 (Primary)

#### 기본 구조
```kotlin
@SpringBootTest
@Transactional
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class GroupServiceIntegrationTest : DatabaseCleanup() {

    @Autowired lateinit var groupService: GroupService
    @Autowired lateinit var userService: UserService
    @Autowired lateinit var groupRepository: GroupRepository

    @Test
    fun `그룹 생성 시 워크스페이스와 채널이 자동 생성된다`() {
        // Given
        val owner = createTestUser("owner@test.com")
        val request = CreateGroupRequest(
            name = "테스트 그룹",
            visibility = GroupVisibility.PUBLIC
        )

        // When
        val group = groupService.createGroup(request, owner.id!!)

        // Then
        assertThat(group.name).isEqualTo("테스트 그룹")

        val workspaces = workspaceRepository.findByGroupId(group.id)
        assertThat(workspaces).hasSize(1)

        val channels = channelRepository.findByWorkspaceId(workspaces[0].id!!)
        assertThat(channels).hasSize(2) // 기본 채널 2개
    }
}
```

#### 권한 테스트
```kotlin
@Test
fun `그룹 관리 권한이 없으면 그룹 수정할 수 없다`() {
    // Given
    val owner = createTestUser("owner@test.com")
    val member = createTestUser("member@test.com")
    val group = createTestGroup(owner)
    joinGroup(member, group, "멤버")

    // When & Then
    assertThatThrownBy {
        groupService.updateGroup(group.id, UpdateGroupRequest("새 이름"), member.id!!)
    }.isInstanceOf(AccessDeniedException::class.java)
}
```

#### 계층형 그룹 테스트
```kotlin
@Test
fun `하위 그룹 생성 시 상위 그룹 권한이 필요하다`() {
    // Given
    val parentOwner = createTestUser("parent@test.com")
    val normalUser = createTestUser("user@test.com")
    val parentGroup = createTestGroup(parentOwner)

    // When & Then
    assertThatThrownBy {
        groupService.createSubGroup(
            parentGroup.id,
            CreateGroupRequest("하위그룹"),
            normalUser.id!!
        )
    }.isInstanceOf(AccessDeniedException::class.java)
}
```

### 2. API 테스트 (Controller Layer)

#### 통합 테스트 패턴 (권장)
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

    @Test
    @DisplayName("GET /api/me - 인증 없이 요청 시 401 또는 403")
    fun getMe_unauthorized() {
        mockMvc.perform(
            get("/api/me")
                .accept(MediaType.APPLICATION_JSON)
        )
        .andExpect(status().is4xxClientError) // 401 or 403 허용
    }
}
```

#### @WebMvcTest vs @SpringBootTest 선택 기준

**@WebMvcTest 사용 (슬라이스 테스트)**
- Controller만 테스트하고 Service는 Mock 처리
- 빠른 테스트 실행 필요
- 단순한 컨트롤러 (적은 의존성)

**@SpringBootTest 사용 (통합 테스트)** ✅ 권장
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

#### Spring Security 인증 테스트 패턴
```kotlin
// ❌ 잘못된 예: 특정 상태 코드 기대
.andExpect(status().isUnauthorized) // 401만 기대

// ✅ 올바른 예: 4xx 클라이언트 에러 허용
.andExpect(status().is4xxClientError) // 401 or 403 허용
```

Spring Security는 상황에 따라 401(Unauthorized) 또는 403(Forbidden)을 반환할 수 있으므로,
`.is4xxClientError`를 사용하여 두 상태 코드를 모두 허용하는 것이 안전합니다.

### 3. 데이터베이스 테스트

#### Repository 테스트
```kotlin
@DataJpaTest
class GroupRepositoryTest {

    @Autowired lateinit var groupRepository: GroupRepository
    @Autowired lateinit var testEntityManager: TestEntityManager

    @Test
    fun `삭제되지 않은 공개 그룹만 조회된다`() {
        // Given
        val publicGroup = Group(name = "공개그룹", visibility = GroupVisibility.PUBLIC)
        val privateGroup = Group(name = "비공개그룹", visibility = GroupVisibility.PRIVATE)
        val deletedGroup = Group(name = "삭제그룹", deletedAt = LocalDateTime.now())

        testEntityManager.persistAndFlush(publicGroup)
        testEntityManager.persistAndFlush(privateGroup)
        testEntityManager.persistAndFlush(deletedGroup)

        // When
        val result = groupRepository.findPublicGroups(Pageable.unpaged())

        // Then
        assertThat(result.content).hasSize(1)
        assertThat(result.content[0].name).isEqualTo("공개그룹")
    }
}
```

### 4. 권한 시스템 테스트

#### Permission Evaluator 테스트
```kotlin
@SpringBootTest
class GroupPermissionEvaluatorTest {

    @Autowired lateinit var permissionEvaluator: GroupPermissionEvaluator

    @Test
    fun `그룹 오너는 모든 권한을 가진다`() {
        // Given
        val owner = createTestUser()
        val group = createTestGroup(owner)

        // When & Then
        GroupPermission.values().forEach { permission ->
            val hasPermission = permissionEvaluator.hasGroupPermission(
                group.id, permission.name, owner.id!!
            )
            assertThat(hasPermission).isTrue()
        }
    }

    @Test
    fun `일반 멤버는 주어진 역할의 권한만 가진다`() {
        // Given
        val user = createTestUser()
        val group = createTestGroup()
        joinGroup(user, group, "멤버") // 멤버 역할 부여

        // When & Then
        // 멤버는 WORKSPACE_ACCESS 권한을 가져야 함
        assertThat(
            permissionEvaluator.hasGroupPermission(group.id, "WORKSPACE_ACCESS", user.id!!)
        ).isTrue()

        // 멤버는 GROUP_MANAGE 권한이 없어야 함
        assertThat(
            permissionEvaluator.hasGroupPermission(group.id, "GROUP_MANAGE", user.id!!)
        ).isFalse()
    }
}
```

## 프론트엔드 테스트 전략

### 1. Widget/Component 테스트 (Flutter)

#### Widget 테스트
```dart
void main() {
  group('GroupCard Widget Tests', () {
    testWidgets('displays group information correctly', (tester) async {
      // Given
      final group = Group(
        id: 1,
        name: 'Test Group',
        memberCount: 25,
        description: 'Test description',
      );

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: GroupCard(group: group),
        ),
      );

      // Then
      expect(find.text('Test Group'), findsOneWidget);
      expect(find.text('25명'), findsOneWidget);
      expect(find.text('Test description'), findsOneWidget);
    });

    testWidgets('join button calls onJoin callback', (tester) async {
      // Given
      bool joinCalled = false;
      final group = Group(id: 1, name: 'Test Group');

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: GroupCard(
            group: group,
            onJoin: (id) => joinCalled = true,
          ),
        ),
      );

      await tester.tap(find.text('가입'));
      await tester.pump();

      // Then
      expect(joinCalled, isTrue);
    });
  });
}
```

### 2. Provider/State 테스트
```dart
void main() {
  group('AuthProvider Tests', () {
    late AuthProvider authProvider;
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
      authProvider = AuthProvider(authService: mockAuthService);
    });

    test('login success updates user state', () async {
      // Given
      final user = User(id: 1, email: 'test@test.com');
      when(mockAuthService.googleLogin(any))
          .thenAnswer((_) async => LoginResponse(user: user, token: 'token'));

      // When
      await authProvider.login('id_token');

      // Then
      expect(authProvider.user, equals(user));
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.isLoading, isFalse);
    });

    test('login failure shows error', () async {
      // Given
      when(mockAuthService.googleLogin(any))
          .thenThrow(ApiException('LOGIN_FAILED', 'Login failed'));

      // When & Then
      expect(
        () => authProvider.login('invalid_token'),
        throwsA(isA<ApiException>()),
      );
      expect(authProvider.user, isNull);
      expect(authProvider.isLoading, isFalse);
    });
  });
}
```

### 3. React Component 테스트 (향후)

#### Jest + Testing Library
```typescript
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { GroupCard } from './GroupCard';

describe('GroupCard', () => {
  const mockGroup = {
    id: 1,
    name: 'Test Group',
    description: 'Test description',
    memberCount: 25,
  };

  test('renders group information', () => {
    const onJoin = jest.fn();

    render(<GroupCard group={mockGroup} onJoin={onJoin} />);

    expect(screen.getByText('Test Group')).toBeInTheDocument();
    expect(screen.getByText('25명')).toBeInTheDocument();
    expect(screen.getByText('Test description')).toBeInTheDocument();
  });

  test('calls onJoin when join button is clicked', async () => {
    const onJoin = jest.fn();

    render(<GroupCard group={mockGroup} onJoin={onJoin} />);

    fireEvent.click(screen.getByText('가입'));

    await waitFor(() => {
      expect(onJoin).toHaveBeenCalledWith(1);
    });
  });
});
```

## E2E 테스트 전략

### 1. 핵심 사용자 플로우

#### 회원가입 및 그룹 가입 플로우
```typescript
// Playwright 예시
test('사용자 온보딩 전체 플로우', async ({ page }) => {
  // 1. 로그인 페이지 접근
  await page.goto('/login');

  // 2. Google 로그인 (Mock)
  await page.click('[data-testid="google-login-button"]');

  // 3. 프로필 설정
  await page.fill('[data-testid="nickname-input"]', '테스트유저');
  await page.selectOption('[data-testid="department-select"]', 'AI/SW 학부');
  await page.fill('[data-testid="student-no-input"]', '20241234');
  await page.click('[data-testid="complete-profile-button"]');

  // 4. 홈 페이지 도달 확인
  await expect(page).toHaveURL('/home');

  // 5. 그룹 탐색 및 가입
  await page.click('[data-testid="explore-groups-link"]');
  await page.click('[data-testid="group-card"]:first-child [data-testid="join-button"]');

  // 6. 가입 성공 확인
  await expect(page.locator('.success-message')).toBeVisible();
});
```

### 2. 권한 기반 기능 테스트
```typescript
test('그룹 관리 권한 플로우', async ({ page }) => {
  // Given: 그룹 오너로 로그인
  await loginAsGroupOwner(page);

  // When: 그룹 관리 페이지 접근
  await page.goto('/groups/1/manage');

  // Then: 관리 기능들이 표시됨
  await expect(page.locator('[data-testid="add-member-button"]')).toBeVisible();
  await expect(page.locator('[data-testid="edit-group-button"]')).toBeVisible();
  await expect(page.locator('[data-testid="delete-group-button"]')).toBeVisible();

  // When: 멤버 추방 시도
  await page.click('[data-testid="member-item"]:first-child [data-testid="kick-button"]');
  await page.click('[data-testid="confirm-kick-button"]');

  // Then: 성공 메시지 표시
  await expect(page.locator('.success-message')).toContainText('멤버가 추방되었습니다');
});
```

## 테스트 데이터 관리

### 1. Test Fixtures
```kotlin
object TestDataFactory {
    fun createTestUser(
        email: String = "test@test.com",
        name: String = "테스트 사용자",
        globalRole: GlobalRole = GlobalRole.STUDENT
    ): User {
        return User(
            email = email,
            name = name,
            globalRole = globalRole,
            profileCompleted = true
        )
    }

    fun createTestGroup(
        owner: User,
        name: String = "테스트 그룹",
        visibility: GroupVisibility = GroupVisibility.PUBLIC
    ): Group {
        return Group(
            name = name,
            ownerId = owner.id!!,
            visibility = visibility
        )
    }
}
```

### 2. Database Cleanup
```kotlin
@Component
@Transactional
class DatabaseCleanup {

    @Autowired lateinit var entityManager: EntityManager

    @AfterEach
    fun cleanup() {
        val tables = listOf(
            "group_members",
            "group_roles",
            "groups",
            "users"
        )

        tables.forEach { table ->
            entityManager.createNativeQuery("DELETE FROM $table").executeUpdate()
        }
    }
}
```

## 동적 테스트 데이터 전략

### 목표
- 테스트 간 데이터 충돌(이메일, 닉네임 등)로 인한 실패 제거
- 읽기 쉬운 패턴 + 재현 가능한 식별자 유지

### 규칙
1. 이메일, 닉네임, 학번 등 Unique 제약 컬럼은 helper 로 생성
2. TestDataFactory 에 `uniqueEmail()`, `uniqueNickname()` 패턴 추가 (timestamp + 카운터)
3. 통합 테스트에서는 트랜잭션 롤백 + 고유 데이터로 격리 강화
4. 테스트 실패 재현 시 출력 로그에 사용된 식별자 노출

### 예시
```kotlin
override fun createTestUser(
    email: String = uniqueEmail("student"),
    globalRole: GlobalRole = GlobalRole.STUDENT,
): User { /* ... */ }
```

## DB Unique 제약 vs 비즈니스 예외

| 구분 | 처리 계층 | 예외 타입 | 재시도 가능? | 메시지 예시 |
|------|-----------|----------|-------------|-------------|
| DB Unique 위반 | DB (INSERT 시) | DataIntegrityViolationException | 낮음 | "EMAIL_ALREADY_EXISTS" |
| 애플리케이션 중복 검사 | Service (사전 조회) | Custom (IllegalArgumentException 등) | 높음 | "닉네임이 이미 사용 중" |

### 전략
1. 사용자/닉네임/이메일: 서비스 레벨 선행 검사 + DB 제약 이중 안전망
2. 동시성 경합 예상되는 구간(대량 가입): Optimistic 재시도 정책 고려
3. 테스트에서는 의도적으로 중복 상황 2종(Test: 사전 검사 / DB 레벨) 분리 검증

### 테스트 포인트
- 사전 검사 실패 -> DB hit 없음 verify
- 레이스 컨디션 시 하나 성공, 하나 DB 예외 -> 예외 메시지/코드 단언

## Mock/Stubbing 가이드 (Auth 예시)

### 기본 원칙
1. 외부 시스템(구글 검증, JWT, 메일, Redis)은 모두 포트/인터페이스로 추상화 후 Mock
2. 단위 테스트: Happy Path + 에러 경계(Invalid Token, Inactive User, Expired Token)
3. verify 호출 횟수는 의미 있는 상호작용만(토큰 1회 발급 등)

### AuthService 핵심 Stub 목록
```kotlin
every { googleIdTokenVerifierPort.verify(validToken) } returns GoogleUserInfo("u@test.com", "User", null)
every { userService.findOrCreateUser(any()) } returns user
every { jwtTokenProvider.generateAccessToken(any()) } returns "access.jwt"
every { jwtTokenProvider.generateRefreshToken(any()) } returns "refresh.jwt"
every { userService.convertToUserResponse(user) } returns userResponse
```

### 슬럿 캡처 (권한 검증)
```kotlin
val authSlot = slot<Authentication>()
every { jwtTokenProvider.generateAccessToken(capture(authSlot)) } returns "token"
// 실행 후
assertThat(authSlot.captured.authorities.first().authority).isEqualTo("ROLE_STUDENT")
```

### 실패 패턴 & 해결
| 패턴 | 원인 | 해결 |
|------|------|------|
| MockKException: no answer found | stub 누락 | every { ... } 추가 또는 relaxedMockk 사용 |
| verify 실패 | 호출 순서/조건 변경 | 불필요 verify 제거 / exactly 조정 |
| Random unique 위반 | 하드코딩 식별자 재사용 | unique* 헬퍼 사용 |

### 권장 구조
- 포트 추상화: GoogleIdTokenVerifierPort -> 실제 구현 + 테스트용 Mock
- 내부 private 메서드 스파이 지양 -> 전략 주입으로 대체

## 향후 보강 예정
- Refresh Token 블랙리스트/재사용 감지 시나리오
- 멱등성 토큰 처리 (중복 로그인 요청)
- 통합 테스트에서 TestContainer 기반 실 DB 주입 옵션

## 테스트 실행 전략

### 1. 개발 중 테스트
```bash
# 단일 테스트 클래스 실행
./gradlew test --tests "GroupServiceIntegrationTest"

# 특정 패턴 테스트 실행
./gradlew test --tests "*Integration*"

# Flutter 테스트
flutter test test/widget/group_card_test.dart
```

### 2. CI/CD 파이프라인 (향후)
```yaml
# GitHub Actions 예시
name: Tests
on: [push, pull_request]

jobs:
  backend-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-java@v3
        with:
          java-version: '17'
      - run: ./gradlew test

  frontend-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter test
```

### 3. 성능 테스트 (향후)
```kotlin
@Test
@Timeout(value = 5, unit = TimeUnit.SECONDS)
fun `대량 그룹 조회 성능 테스트`() {
    // Given: 1000개 그룹 생성
    repeat(1000) {
        createTestGroup(name = "그룹$it")
    }

    // When: 그룹 목록 조회
    val start = System.currentTimeMillis()
    val result = groupService.findGroups(null, Pageable.ofSize(20))
    val duration = System.currentTimeMillis() - start

    // Then: 응답 시간 및 결과 검증
    assertThat(duration).isLessThan(1000) // 1초 이내
    assertThat(result.content).hasSize(20)
}
```

## 테스트 커버리지 목표

### 백엔드
- **Service Layer**: 90% 이상
- **Controller Layer**: 80% 이상
- **Repository Layer**: 70% 이상 (복잡한 쿼리 위주)

### 프론트엔드
- **비즈니스 로직**: 80% 이상
- **UI 컴포넌트**: 60% 이상 (주요 상호작용 위주)

## 테스트 작성 시 주의사항 및 일반적인 에러

### 1. Entity 및 Enum 참조 시 주의사항

#### GroupType 참조
```kotlin
// ❌ 잘못된 예
groupType = GroupType.CLUB

// ✅ 올바른 예 (Entity 확인 필수)
groupType = GroupType.AUTONOMOUS  // 또는 OFFICIAL, UNIVERSITY, COLLEGE, DEPARTMENT, LAB
```

#### 역할 이름 참조
```kotlin
// ❌ 잘못된 예
assertThat(roles.map { it.name }).containsExactlyInAnyOrder("그룹장", "PROFESSOR", "멤버")

// ✅ 올바른 예 (시스템 역할 이름 확인 필수)
assertThat(roles.map { role -> role.name }).containsExactlyInAnyOrder("그룹장", "교수", "멤버")
```

### 2. Service 리팩토링 주의사항

#### GroupService 분리
- `GroupService`는 `GroupManagementService`와 `GroupMemberService`로 분리되었습니다
- 테스트 코드 작성 시 적절한 서비스를 사용해야 합니다:

```kotlin
// ❌ 잘못된 예
@Autowired
private lateinit var groupService: GroupService

// ✅ 올바른 예
@Autowired
private lateinit var groupManagementService: GroupManagementService

@Autowired
private lateinit var groupMemberService: GroupMemberService
```

**메서드 매핑:**
- `groupService.createGroup()` → `groupManagementService.createGroup()`
- `groupService.getGroup()` → `groupManagementService.getGroup()`
- `groupService.getGroups()` → `groupManagementService.getGroups()`
- `groupService.joinGroup()` → `groupMemberService.joinGroup()`
- `groupService.leaveGroup()` → `groupMemberService.leaveGroup()`
- `groupService.getGroupMembers()` → `groupMemberService.getGroupMembers()`

### 3. User Entity 필드 설정

#### profileCompleted 필드
User 엔티티의 `profileCompleted` 필드는 생성자 파라미터가 아닌 필드입니다:

```kotlin
// ❌ 잘못된 예
TestDataFactory.createTestUser(
    name = "그룹장",
    email = "owner@example.com",
    profileCompleted = true,  // 컴파일 에러
)

// ✅ 올바른 예 (copy 사용)
TestDataFactory.createTestUser(
    name = "그룹장",
    email = "owner@example.com",
).copy(profileCompleted = true)
```

### 4. Lambda 파라미터 명시

Kotlin 1.9+ 버전에서는 람다의 `it` 사용을 명시적으로 권장합니다:

```kotlin
// ❌ 잘못된 예
roles.map { it.name }

// ✅ 올바른 예
roles.map { role -> role.name }
```

### 5. 테스트 데이터 팩토리 사용

#### 계층형 그룹 테스트
```kotlin
// 대학교 → 학부 → 학과 계층 구조 생성
val university = createGroupWithRoles("대학교", owner, GroupType.UNIVERSITY)
val college = createGroupWithRoles("학부", owner, GroupType.COLLEGE, university)
val department = createGroupWithRoles("학과", owner, GroupType.DEPARTMENT, college)
```

#### 역할 생성
```kotlin
// 기본 역할 생성
val ownerRole = TestDataFactory.createOwnerRole(group)
val advisorRole = TestDataFactory.createAdvisorRole(group)
val memberRole = TestDataFactory.createMemberRole(group)

// 커스텀 역할 생성
val customRole = TestDataFactory.createTestGroupRole(
    group = group,
    name = "MODERATOR",
    isSystemRole = false,
    permissions = setOf(GroupPermission.CHANNEL_MANAGE),
    priority = 50,
)
```

### 6. 통합 테스트 작성 체크리스트

테스트 작성 전 반드시 확인:
- [ ] 최신 Entity 구조 확인 (Enum 값, 필드 타입)
- [ ] Service 계층 구조 확인 (리팩토링 여부)
- [ ] Repository 메서드 시그니처 확인
- [ ] TestDataFactory에 필요한 헬퍼 메서드 추가
- [ ] 트랜잭션 및 데이터 클린업 설정
- [ ] 테스트 격리 보장 (각 테스트는 독립적으로 실행 가능)

### 7. 일반적인 컴파일 에러 해결

#### "Unresolved reference" 에러
1. Import 문 확인
2. Entity/Enum 최신 구조 확인
3. 패키지 구조 변경 여부 확인

#### "Cannot find a parameter with this name" 에러
1. 생성자 파라미터 vs 프로퍼티 구분
2. data class의 copy() 메서드 활용
3. TestDataFactory 최신화

#### "Type mismatch" 에러
1. Service 메서드 반환 타입 변경 여부 확인
2. DTO 구조 변경 여부 확인
3. nullable 타입 처리 확인

## 관련 문서

### 개발 프로세스
- **개발 워크플로우**: [development-flow.md](development-flow.md)

### 구현 참조
- **백엔드 가이드**: [../implementation/backend/README.md](../implementation/backend/README.md)
- **프론트엔드 가이드**: [../implementation/frontend/README.md](../implementation/frontend/README.md)

### 문제 해결
- **일반적 에러**: [../troubleshooting/common-errors.md](../troubleshooting/common-errors.md)

## Auth 테스트 실패 방지 가이드 (Failure Prevention)

### 1. 빈번/잠재 실패 유형 요약
| 코드/레이어 | 실패 유형 | 징후 (로그/에러) | 원인 | 해결 | 재발 방지 체크 |
|-------------|-----------|-----------------|------|------|----------------|
| AuthServiceTest | MockKException: no answer found | generateRefreshToken 호출 직전 실패 | refresh 토큰 stub 누락 | every { jwtTokenProvider.generateRefreshToken(any()) } returns "..." | 공통 setUp에 relaxed mock 또는 공통 stub 함수 도입 |
| AuthServiceTest | Private method spy 관련 실패 | spyk(... recordPrivateCalls) 사용, 내부 구현 변경 시 깨짐 | private 함수 직접 스파이 | 포트 추상화(전략 인터페이스)로 대체 | 새로운 외부 연동 추가 시 먼저 Port 정의 |
| AuthControllerTest | 401 대신 500 반환 | IllegalArgumentException 처리 핸들러 미적용 / 메시지 상이 | 예외 매핑 누락 또는 메서드 명 오타 | @ControllerAdvice 매핑 점검, 메시지 상수화 | 에러 코드/메시지 스냅샷 테스트(추후) |
| AuthService | tokenType 필드 잘못된 값(Bearer 대신 refreshToken) | 응답 JSON data.tokenType 값이 refresh JWT 문자열 | 비즈니스 로직 실수 | tokenType 고정 문자열 "Bearer" 리팩터 | PR 리뷰 체크리스트에 응답 스키마 확인 항목 추가 |
| SecurityContext 사용 테스트 | Null authentication / IllegalStateException | verifyToken 테스트에서 SecurityContext null | SecurityContextHolder 설정 누락 | createEmptyContext() 후 setContext | 헬퍼 util 함수 도입 setAuth(email, role) |
| refreshAccessToken | Invalid or expired refresh token 기대 실패 | 예외 메시지/코드 매칭 실패 | validateToken stub 잘못된 값 | every { validateToken(token) } returns false/true 재확인 | 메시지 상수화 & 재사용 |
| Access Token 경로 테스트 | Invalid Google access token 예상 메시지 불일치 | 실제 메시지 vs 테스트 단언 차이 | 메시지 하드코딩 불일치 | 메시지 상수(Companion object) 또는 central ErrorCode 사용 | 테스트는 ErrorCode 기준 단언 |
| 포트(Mock) | 네트워크 예외 wrap 실패 | Google userinfo fetch failed: ... | 포트 구현에서 예외 throw 타입 불일치 | IllegalArgumentException 통일 | 예외 메시지 prefix 고정(`Google userinfo fetch failed:`) |

### 2. 공통 Stub/Helper 패턴
```kotlin
// Auth 단위 테스트 공통 헬퍼 (예: AbstractAuthTest.kt 로 분리 가능)
fun stubJwtTokens(access: String = "access.jwt", refresh: String = "refresh.jwt") {
    every { jwtTokenProvider.generateAccessToken(any()) } returns access
    every { jwtTokenProvider.generateRefreshToken(any()) } returns refresh
}

fun stubGoogleIdToken(email: String = "user@test.local") {
    every { googleIdTokenVerifierPort.verify(any()) } returns GoogleUserInfo(email, "User", null)
}

fun stubGoogleAccessToken(email: String = "user2@test.local") {
    every { googleUserInfoFetcherPort.fetch(any()) } returns GoogleUserInfo(email, "User2", null)
}
```

### 3. 테스트 작성 사전 체크리스트 (Auth)
- [ ] Port (IdToken / AccessToken) 중 어떤 경로인지 명확히? (두 개 혼용 금지)
- [ ] jwtTokenProvider access + refresh 모두 stub 또는 relaxed?
- [ ] inactive / invalid token 네거티브 케이스 추가했는가?
- [ ] 메시지 문자열 하드코딩 대신 공통 상수 또는 에러 코드 단언 가능한가?
- [ ] SecurityContext 사용하는 테스트 후 clearContext 호출했는가?

### 4. 예외 메시지/코드 표준화 제안
| 상황 | 예외 타입 | 메시지(권장) | 에러 코드(향후) |
|------|-----------|-------------|----------------|
| 잘못된 ID Token | IllegalArgumentException | Invalid Google token | AUTH_INVALID_ID_TOKEN |
| 잘못된 Access Token | IllegalArgumentException | Invalid Google access token | AUTH_INVALID_ACCESS_TOKEN |
| 비활성 사용자 | IllegalArgumentException | 비활성화된 사용자입니다 | AUTH_INACTIVE_USER |
| 리프레시 토큰 오류 | IllegalArgumentException | Invalid or expired refresh token | AUTH_INVALID_REFRESH |

> 추후 ApiErrorResponse 에 code 필드 확장 시 표준화.

### 5. Port 주입 신규 외부 연동 패턴 템플릿
```kotlin
interface ExternalXYZPort { fun call(req: XYZRequest): XYZResult }
@Component
class DefaultExternalXYZPort(/* deps */): ExternalXYZPort { override fun call(req: XYZRequest): XYZResult { /* http */ } }
// Service 주입 → 단위 테스트에서 Port Mock, 통합 테스트 실 구현
```

### 6. Anti-Pattern → Replacement 매핑
| Anti-Pattern | Replacement |
|--------------|-------------|
| spyk + private 함수 호출 | Port 인터페이스 + Mock |
| 개별 테스트마다 중복 stub | 공통 helper 함수(stubJwtTokens 등) |
| 메시지 하드코딩 분산 | 상수/에러코드 중앙화 |
| SecurityContext static mock | createEmptyContext() 사용 |
| verify 횟수 과도 단언 | 의미있고 불변의 상호작용만 (예: findOrCreateUser 1회) |

### 7. 테스트 실패 디버깅 순서
1. 첫 스택트레이스: MockKException → 누락 stub 우선 확인 (generateRefreshToken?)
2. IllegalArgumentException 메시지 불일치 → 실제 구현 메시지 & 테스트 단언 비교
3. 인증 흐름 NullPointer → userService.findOrCreateUser 반환 null 여부 / 포트 null 반환
4. 권한(authorities) 단언 실패 → Authentication 캡처 slot 위치 확인 (access token stub 이전?)
5. Controller 401/500 혼동 → ExceptionHandler 매핑 확인, 혹은 예외 타입 재검토

### 8. CI 실패 자동 분석(권장 스크립트 개요)
- 테스트 로그 grep: `MockKException|IllegalArgumentException|NoSuchBeanDefinition`
- 매칭되면 사전 정의된 원인 메시지 출력 → PR 코멘트 자동 달기 (GitHub Actions) 

### 9. 추가 개선 로드맵
- JaCoCo 커버리지 리포트 + 임계치 (lines 80%, instructions 80%)
- ErrorCode enum 도입 후 메시지/코드 이중 단언 전환
- Auth 통합 테스트에서 WireMock 기반 AccessToken userinfo 응답 시나리오 추가
