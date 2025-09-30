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
    joinGroup(member, group, "MEMBER")

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

#### MockMvc 기반 테스트
```kotlin
@SpringBootTest
@AutoConfigureTestDatabase
@TestMethodOrder(OrderAnnotation::class)
class GroupControllerIntegrationTest {

    @Autowired lateinit var mockMvc: MockMvc
    @Autowired lateinit var objectMapper: ObjectMapper

    @Test
    @WithMockUser(username = "test@test.com")
    fun `POST groups - 그룹 생성 성공`() {
        // Given
        val request = CreateGroupRequest(
            name = "새 그룹",
            visibility = GroupVisibility.PUBLIC
        )

        // When & Then
        mockMvc.perform(
            post("/api/groups")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        )
        .andExpect(status().isCreated)
        .andExpect(jsonPath("$.success").value(true))
        .andExpect(jsonPath("$.data.name").value("새 그룹"))
    }

    @Test
    fun `인증되지 않은 사용자는 그룹 생성할 수 없다`() {
        // Given
        val request = CreateGroupRequest("그룹", GroupVisibility.PUBLIC)

        // When & Then
        mockMvc.perform(
            post("/api/groups")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        )
        .andExpect(status().isUnauthorized)
    }
}
```

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
        joinGroup(user, group, "MEMBER") // Member 역할 부여

        // When & Then
        // Member는 WORKSPACE_ACCESS 권한을 가져야 함
        assertThat(
            permissionEvaluator.hasGroupPermission(group.id, "WORKSPACE_ACCESS", user.id!!)
        ).isTrue()

        // Member는 GROUP_MANAGE 권한이 없어야 함
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

## 관련 문서

### 개발 프로세스
- **개발 워크플로우**: [development-flow.md](development-flow.md)

### 구현 참조
- **백엔드 가이드**: [../implementation/backend-guide.md](../implementation/backend-guide.md)
- **프론트엔드 가이드**: [../implementation/frontend-guide.md](../implementation/frontend-guide.md)

### 문제 해결
- **일반적 에러**: [../troubleshooting/common-errors.md](../troubleshooting/common-errors.md)
