# Test Patterns (테스트 작성 패턴)

## 1. 60/30/10 테스트 피라미드

- **통합 테스트 (60%)**: 실제 환경 + 실제 DB + 실제 인증 플로우
- **단위 테스트 (30%)**: Mock + 복잡한 비즈니스 로직
- **E2E 테스트 (10%)**: 핵심 사용자 여정

## 2. 백엔드 통합 테스트 패턴

```kotlin
@SpringBootTest(webEnvironment = MOCK)
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional  // 테스트 후 롤백
class XxxControllerTest {
    @Autowired private lateinit var mockMvc: MockMvc
    @Autowired private lateinit var jwtTokenProvider: JwtTokenProvider

    @BeforeEach
    fun setUp() {
        // 고유 이메일로 데이터 격리
        testUser = userRepository.save(
            createTestUser(email = "test-${System.nanoTime()}@example.com")
        )
        token = generateToken(testUser)
    }
}
```

## 3. 권한 테스트 매트릭스

| 작업 | 그룹장 | 교수 | 멤버 | 비멤버 |
|------|--------|------|------|--------|
| 그룹 수정 | 200 | 200 | 403 | 403 |
| 멤버 추방 | 200 | 200 | 403 | 403 |
| 게시글 작성 | 200 | 200 | 200* | 403 |
| 채널 생성 | 200 | 200 | 403 | 403 |

*채널 권한 바인딩에 따라 달라질 수 있음

## 4. Widget 테스트 패턴 (Flutter)

```dart
testWidgets('displays correct data', (tester) async {
    await tester.pumpWidget(
        ProviderScope(
            overrides: [mockProvider],
            child: MaterialApp(home: MyWidget()),
        ),
    );

    await tester.pumpAndSettle();  // 애니메이션 대기
    expect(find.text('Expected'), findsOneWidget);
});
```

## 5. 자주 하는 실수 (에러 패턴)

### 실수 1: @BeforeEach 데이터 격리 누락

**증상**: "Unique constraint violation" 또는 "Duplicate entry for key"
```
org.springframework.dao.DataIntegrityViolationException:
could not execute statement; SQL [n/a]; constraint [email]
```

**원인**: 여러 테스트가 같은 이메일/닉네임으로 사용자를 생성하여 데이터 충돌

**해결책**:
1. `TestDataFactory.uniqueEmail("prefix")` 사용
2. 또는 `System.nanoTime()`으로 고유 식별자 생성
```kotlin
// ❌ 잘못된 예
testUser = createTestUser(email = "test@example.com")

// ✅ 올바른 예
testUser = createTestUser(email = "test-${System.nanoTime()}@example.com")
```

**파일 참조**: backend/src/test/kotlin/.../ContentControllerTest.kt:114

---

### 실수 2: 권한 검증 시 @WithMockUser만 사용

**증상**: 403 Forbidden이 발생하는데 권한이 충분해 보임
```
org.springframework.web.bind.MethodArgumentNotValidException
MockHttpServletResponse: Status = 403
```

**원인**: @WithMockUser는 Spring Security 인증만 통과하지만, 실제 데이터베이스의 그룹 멤버십과 역할 기반 권한은 검증하지 않음

**해결책**:
1. 실제 JWT 토큰 생성 사용
2. 데이터베이스에 그룹 멤버십 등록
3. ChannelRoleBinding 설정 필수
```kotlin
// ✅ 올바른 예
token = generateToken(testUser)
mockMvc.perform(
    get("/api/groups/${group.id}/permissions")
        .header("Authorization", "Bearer $token")
)
```

**파일 참조**: backend/src/test/kotlin/.../GroupPermissionControllerIntegrationTest.kt

---

### 실수 3: @Transactional 누락으로 LazyInitializationException

**증상**: "could not initialize proxy - no Session"
```
org.hibernate.LazyInitializationException:
failed to lazily initialize a collection of role
```

**원인**: Hibernate 세션이 닫힌 후 지연 로딩(Lazy Loading) 시도

**해결책**:
1. 테스트 클래스에 `@Transactional` 추가
2. 또는 fetch join 사용
3. Service 레이어에서 필요한 연관 엔티티 미리 로드
```kotlin
// ✅ 올바른 예
@SpringBootTest
@Transactional  // 추가
class GroupServiceIntegrationTest { ... }
```

**파일 참조**: docs/workflows/testing-strategy.md:27

---

### 실수 4: Widget 테스트에서 pumpAndSettle 누락

**증상**: Widget이 렌더링되지 않았다고 나오는데 실제로는 존재함
```
Expected: exactly one matching node in the widget tree
Actual: _TextFinder:<zero widgets with text "Expected">
```

**원인**: 비동기 빌드나 애니메이션이 완료되지 않은 상태에서 검증

**해결책**:
1. `await tester.pumpAndSettle()` 사용 (모든 애니메이션 완료 대기)
2. 또는 `await tester.pump(Duration(seconds: 1))` (특정 시간 대기)
```dart
// ❌ 잘못된 예
await tester.pumpWidget(MyWidget());
expect(find.text('Title'), findsOneWidget);

// ✅ 올바른 예
await tester.pumpWidget(MyWidget());
await tester.pumpAndSettle();
expect(find.text('Title'), findsOneWidget);
```

**파일 참조**: frontend/test/navigation/navigation_controller_test.dart

---

### 실수 5: Mock Stub 누락으로 no answer found

**증상**: "MockKException: no answer found for..."
```
io.mockk.MockKException:
no answer found for: JwtTokenProvider(#1).generateRefreshToken(any())
```

**원인**: MockK에서 호출될 메서드에 대한 stub(every)을 정의하지 않음

**해결책**:
1. 모든 호출 메서드에 대해 `every { ... } returns ...` 정의
2. 또는 `relaxedMockk<T>()` 사용 (기본값 자동 반환)
```kotlin
// ❌ 잘못된 예
val jwtProvider = mockk<JwtTokenProvider>()
every { jwtProvider.generateAccessToken(any()) } returns "access"
// generateRefreshToken stub 누락!

// ✅ 올바른 예
val jwtProvider = mockk<JwtTokenProvider>()
every { jwtProvider.generateAccessToken(any()) } returns "access"
every { jwtProvider.generateRefreshToken(any()) } returns "refresh"
```

**파일 참조**: backend/src/test/kotlin/.../PermissionServiceTest.kt:63

---

### 실수 6: Service 분리 후 잘못된 참조

**증상**: "Unresolved reference: groupService"
```
Error: Unresolved reference: groupService
```

**원인**: GroupService가 GroupManagementService + GroupMemberService로 분리됨

**해결책**:
1. 적절한 서비스 사용
```kotlin
// ❌ 잘못된 예
@Autowired private lateinit var groupService: GroupService

// ✅ 올바른 예
@Autowired private lateinit var groupManagementService: GroupManagementService
@Autowired private lateinit var groupMemberService: GroupMemberService
```

**파일 참조**: backend/src/test/kotlin/.../GroupServiceIntegrationTest.kt

---

### 실수 7: 채널 권한 바인딩 미설정

**증상**: 멤버인데도 채널 접근 시 403 Forbidden
```
MockHttpServletResponse: Status = 403
Expected: 200, Actual: 403
```

**원인**: 사용자 정의 채널은 생성 직후 권한 바인딩이 0개 (접근 불가)

**해결책**:
1. GroupInitializationRunner가 생성한 기본 채널 사용
2. 또는 `ChannelRoleBindingRepository.save()`로 수동 바인딩 추가
```kotlin
// ✅ 올바른 예
channelRoleBindingRepository.save(
    ChannelRoleBinding.create(channel, memberRole,
        setOf(CHANNEL_VIEW, POST_READ, POST_WRITE))
)
```

**파일 참조**: backend/src/test/kotlin/.../ContentControllerTest.kt:224

---

### 실수 8: Entity data class copy 사용

**증상**: "Unresolved reference: copy"
```
Error: Unresolved reference: copy
```

**원인**: GroupRole이 data class에서 일반 class로 변경되어 copy() 불가

**해결책**:
1. TestDataFactory 메서드 사용
2. 또는 apply 블록으로 수정
```kotlin
// ❌ 잘못된 예
val role = ownerRole.copy(permissions = newPerms)

// ✅ 올바른 예 1
val role = createOwnerRole(group).apply {
    replacePermissions(newPerms)
}

// ✅ 올바른 예 2
val role = createTestGroupRole(
    group = group,
    permissions = newPerms
)
```

**파일 참조**: backend/src/test/kotlin/.../PermissionServiceTest.kt:44

## 6. 성능 테스트 SLA

| 시나리오 | 최대 응답 시간 | 동시 사용자 |
|----------|----------------|-------------|
| 그룹 목록 조회 (20개) | 1초 | 100명 |
| 권한 조회 (캐시) | 100ms | 500명 |
| 게시글 작성 | 500ms | 50명 |
| 파일 업로드 (10MB) | 5초 | 10명 |

## 관련 문서

- **테스트 전략**: [testing-strategy.md](../workflows/testing-strategy.md) - 전체 테스트 전략
- **테스트 데이터**: [test-data-reference.md](../testing/test-data-reference.md) - TestDataRunner
- **일반 에러**: [common-errors.md](../troubleshooting/common-errors.md) - 운영 에러
