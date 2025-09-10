# 테스트 전략 및 가이드

## 테스트 전략 개요

### 테스트 피라미드
```
       /\
      /  \
     /    \
    / E2E  \     <- 통합 테스트 (적은 수, 핵심 시나리오)
   /--------\
  /          \
 /Integration\ <- 통합 테스트 (중간 수, API 테스트)
/____________\
/    Unit     \ <- 단위 테스트 (많은 수, 빠른 실행)
/____________\
```

### 테스트 유형별 목표
- **Unit Tests (70%)**: 개별 클래스, 메서드의 로직 검증
- **Integration Tests (20%)**: 컴포넌트 간 상호작용 검증
- **E2E Tests (10%)**: 전체 시스템 워크플로우 검증

## 단위 테스트 (Unit Tests)

### 기본 원칙
- **FIRST 원칙**: Fast, Independent, Repeatable, Self-validating, Timely
- **AAA 패턴**: Arrange, Act, Assert
- **한 테스트당 하나의 검증 사항**

### 테스트 클래스 구조
```kotlin
@ExtendWith(MockitoExtension::class)
class UserServiceTest {
    
    @Mock
    private lateinit var userRepository: UserRepository
    
    @Mock
    private lateinit var passwordEncoder: PasswordEncoder
    
    @InjectMocks
    private lateinit var userService: UserService
    
    @BeforeEach
    fun setUp() {
        // 공통 설정
    }
    
    @Test
    fun `should create user when valid request provided`() {
        // Given (준비)
        val request = CreateUserRequest("John", "john@example.com", "password123")
        val encodedPassword = "encoded_password"
        val savedUser = User(1L, "John", "john@example.com", encodedPassword)
        
        given(passwordEncoder.encode("password123")).willReturn(encodedPassword)
        given(userRepository.save(any(User::class.java))).willReturn(savedUser)
        
        // When (실행)
        val result = userService.createUser(request)
        
        // Then (검증)
        assertThat(result.id).isEqualTo(1L)
        assertThat(result.name).isEqualTo("John")
        assertThat(result.email).isEqualTo("john@example.com")
        verify(userRepository).save(any(User::class.java))
        verify(passwordEncoder).encode("password123")
    }
    
    @Test
    fun `should throw exception when user already exists`() {
        // Given
        val request = CreateUserRequest("John", "john@example.com", "password123")
        given(userRepository.existsByEmail("john@example.com")).willReturn(true)
        
        // When & Then
        assertThatThrownBy { userService.createUser(request) }
            .isInstanceOf(DuplicateEmailException::class.java)
            .hasMessage("User already exists with email: john@example.com")
    }
}
```

### 네이밍 규칙
```kotlin
// 패턴: should_[expectedBehavior]_when_[stateUnderTest]
@Test
fun `should return user when valid id provided`() { }

@Test
fun `should throw UserNotFoundException when user does not exist`() { }

@Test
fun `should update user email when new email is valid`() { }
```

## 통합 테스트 (Integration Tests)

### 웹 계층 테스트 (@WebMvcTest)
```kotlin
@WebMvcTest(UserController::class)
class UserControllerTest {
    
    @Autowired
    private lateinit var mockMvc: MockMvc
    
    @MockBean
    private lateinit var userService: UserService
    
    @Autowired
    private lateinit var objectMapper: ObjectMapper
    
    @Test
    fun `should return user when GET users by valid id`() {
        // Given
        val userId = 1L
        val user = UserResponse(userId, "John", "john@example.com")
        given(userService.getUserById(userId)).willReturn(user)
        
        // When & Then
        mockMvc.perform(
            get("/api/v1/users/{id}", userId)
                .contentType(MediaType.APPLICATION_JSON)
        )
        .andExpect(status().isOk)
        .andExpect(jsonPath("$.success").value(true))
        .andExpect(jsonPath("$.data.id").value(1))
        .andExpect(jsonPath("$.data.name").value("John"))
        .andExpect(jsonPath("$.data.email").value("john@example.com"))
    }
    
    @Test
    fun `should return 400 when POST users with invalid data`() {
        // Given
        val invalidRequest = CreateUserRequest("", "invalid-email", "123") // 유효하지 않은 데이터
        
        // When & Then
        mockMvc.perform(
            post("/api/v1/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(invalidRequest))
        )
        .andExpect(status().isBadRequest)
        .andExpect(jsonPath("$.success").value(false))
        .andExpect(jsonPath("$.error.code").value("VALIDATION_ERROR"))
    }
}
```

### 데이터베이스 통합 테스트 (@DataJpaTest)
```kotlin
@DataJpaTest
@TestPropertySource(locations = ["classpath:application-test.properties"])
class UserRepositoryTest {
    
    @Autowired
    private lateinit var testEntityManager: TestEntityManager
    
    @Autowired
    private lateinit var userRepository: UserRepository
    
    @Test
    fun `should find user by email`() {
        // Given
        val user = User(name = "John", email = "john@example.com", password = "encoded")
        testEntityManager.persist(user)
        testEntityManager.flush()
        
        // When
        val found = userRepository.findByEmail("john@example.com")
        
        // Then
        assertThat(found).isNotNull
        assertThat(found?.name).isEqualTo("John")
        assertThat(found?.email).isEqualTo("john@example.com")
    }
    
    @Test
    fun `should return null when user not found by email`() {
        // When
        val found = userRepository.findByEmail("nonexistent@example.com")
        
        // Then
        assertThat(found).isNull()
    }
}
```

### 전체 애플리케이션 통합 테스트 (@SpringBootTest)
```kotlin
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@TestPropertySource(locations = ["classpath:application-test.properties"])
@Transactional
class UserIntegrationTest {
    
    @Autowired
    private lateinit var restTemplate: TestRestTemplate
    
    @Autowired
    private lateinit var userRepository: UserRepository
    
    @Test
    fun `should create and retrieve user through API`() {
        // Given
        val createRequest = CreateUserRequest("John", "john@example.com", "password123")
        
        // When - Create user
        val createResponse = restTemplate.postForEntity(
            "/api/v1/users",
            createRequest,
            ApiResponse::class.java
        )
        
        // Then - Verify creation
        assertThat(createResponse.statusCode).isEqualTo(HttpStatus.CREATED)
        
        val createdUserId = (createResponse.body?.data as Map<*, *>)["id"] as Int
        
        // When - Retrieve user
        val getResponse = restTemplate.getForEntity(
            "/api/v1/users/$createdUserId",
            ApiResponse::class.java
        )
        
        // Then - Verify retrieval
        assertThat(getResponse.statusCode).isEqualTo(HttpStatus.OK)
        val userData = getResponse.body?.data as Map<*, *>
        assertThat(userData["name"]).isEqualTo("John")
        assertThat(userData["email"]).isEqualTo("john@example.com")
    }
}
```

## 보안 테스트

### 인증/인가 테스트
```kotlin
@SpringBootTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
class SecurityIntegrationTest {
    
    @Autowired
    private lateinit var mockMvc: MockMvc
    
    @Test
    @WithMockUser(roles = ["USER"])
    fun `should allow access to user endpoint with USER role`() {
        mockMvc.perform(get("/api/v1/users/profile"))
            .andExpect(status().isOk)
    }
    
    @Test
    @WithMockUser(roles = ["USER"])
    fun `should deny access to admin endpoint with USER role`() {
        mockMvc.perform(get("/api/v1/admin/users"))
            .andExpect(status().isForbidden)
    }
    
    @Test
    fun `should return unauthorized for protected endpoint without authentication`() {
        mockMvc.perform(get("/api/v1/users/profile"))
            .andExpect(status().isUnauthorized)
    }
}

// 커스텀 Security Test 어노테이션
@Target(AnnotationTarget.FUNCTION)
@Retention(AnnotationRetention.RUNTIME)
@WithSecurityContext(factory = WithMockCustomUserSecurityContextFactory::class)
annotation class WithMockCustomUser(
    val id: Long = 1L,
    val email: String = "test@example.com",
    val roles: Array<String> = ["USER"]
)
```

## 테스트 데이터 관리

### 테스트 픽스처 (Test Fixtures)
```kotlin
object UserFixtures {
    
    fun createValidUser(
        id: Long = 1L,
        name: String = "John Doe",
        email: String = "john@example.com",
        password: String = "encoded_password"
    ): User = User(id, name, email, password)
    
    fun createValidCreateUserRequest(
        name: String = "John Doe",
        email: String = "john@example.com",
        password: String = "password123"
    ): CreateUserRequest = CreateUserRequest(name, email, password)
    
    fun createValidUserResponse(
        id: Long = 1L,
        name: String = "John Doe",
        email: String = "john@example.com"
    ): UserResponse = UserResponse(id, name, email, LocalDateTime.now())
}

// 사용 예시
@Test
fun `should create user successfully`() {
    // Given
    val request = UserFixtures.createValidCreateUserRequest()
    val expectedUser = UserFixtures.createValidUser()
    
    given(userRepository.save(any())).willReturn(expectedUser)
    
    // When & Then
    val result = userService.createUser(request)
    assertThat(result.name).isEqualTo(expectedUser.name)
}
```

### 데이터베이스 초기화 전략
```kotlin
// test/resources/data.sql
INSERT INTO users (id, name, email, password, created_at) 
VALUES (1, 'Test User', 'test@example.com', 'encoded_password', NOW());

INSERT INTO groups (id, name, description, owner_id, created_at)
VALUES (1, 'Test Group', 'Test Description', 1, NOW());
```

```yaml
# test/resources/application-test.yml
spring:
  datasource:
    url: jdbc:h2:mem:testdb;MODE=MySQL;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE
    driver-class-name: org.h2.Driver
    username: sa
    password: 
  
  jpa:
    hibernate:
      ddl-auto: create-drop
    show-sql: true
    properties:
      hibernate:
        format_sql: true
  
  sql:
    init:
      mode: always
      data-locations: classpath:data.sql
```

## 성능 테스트

### 기본 성능 테스트
```kotlin
@Test
@Timeout(value = 5, unit = TimeUnit.SECONDS)
fun `should complete user creation within 5 seconds`() {
    // Given
    val request = UserFixtures.createValidCreateUserRequest()
    
    // When
    val result = userService.createUser(request)
    
    // Then
    assertThat(result).isNotNull
}

@Test
fun `should handle concurrent user creation requests`() {
    // Given
    val numberOfThreads = 10
    val executor = Executors.newFixedThreadPool(numberOfThreads)
    val latch = CountDownLatch(numberOfThreads)
    val results = Collections.synchronizedList(mutableListOf<User>())
    val errors = Collections.synchronizedList(mutableListOf<Exception>())
    
    // When
    repeat(numberOfThreads) { index ->
        executor.submit {
            try {
                val request = UserFixtures.createValidCreateUserRequest(
                    email = "user$index@example.com"
                )
                val result = userService.createUser(request)
                results.add(result)
            } catch (e: Exception) {
                errors.add(e)
            } finally {
                latch.countDown()
            }
        }
    }
    
    latch.await(10, TimeUnit.SECONDS)
    
    // Then
    assertThat(results).hasSize(numberOfThreads)
    assertThat(errors).isEmpty()
}
```

## 테스트 환경 설정

### 테스트 프로파일 설정
```kotlin
@ActiveProfiles("test")
@SpringBootTest
class BaseIntegrationTest {
    // 공통 테스트 설정
}
```

### 테스트 컨테이너 활용 (TestContainers)
```kotlin
@Testcontainers
@SpringBootTest
class DatabaseIntegrationTest {
    
    companion object {
        @Container
        @JvmStatic
        val postgresContainer = PostgreSQLContainer<Nothing>("postgres:13").apply {
            withDatabaseName("testdb")
            withUsername("test")
            withPassword("test")
        }
    }
    
    @DynamicPropertySource
    companion object {
        @JvmStatic
        fun configureProperties(registry: DynamicPropertyRegistry) {
            registry.add("spring.datasource.url", postgresContainer::getJdbcUrl)
            registry.add("spring.datasource.username", postgresContainer::getUsername)
            registry.add("spring.datasource.password", postgresContainer::getPassword)
        }
    }
    
    @Test
    fun `should persist data in real PostgreSQL`() {
        // PostgreSQL 컨테이너를 사용한 실제 데이터베이스 테스트
    }
}
```

## 테스트 실행 및 리포팅

### Gradle 테스트 설정
```kotlin
// build.gradle.kts
tasks.withType<Test> {
    useJUnitPlatform()
    
    testLogging {
        events("passed", "skipped", "failed")
        exceptionFormat = TestExceptionFormat.FULL
    }
    
    // 병렬 실행 설정
    systemProperty("junit.jupiter.execution.parallel.enabled", "true")
    systemProperty("junit.jupiter.execution.parallel.mode.default", "concurrent")
}

// 테스트 커버리지 (JaCoCo)
jacoco {
    toolVersion = "0.8.8"
}

tasks.jacocoTestReport {
    reports {
        xml.required.set(true)
        html.required.set(true)
        csv.required.set(false)
    }
    
    finalizedBy(tasks.jacocoTestCoverageVerification)
}

tasks.jacocoTestCoverageVerification {
    violationRules {
        rule {
            limit {
                minimum = "0.80".toBigDecimal()
            }
        }
    }
}
```

## 테스트 모범 사례

### DO (해야 할 것)
- 테스트는 독립적이고 순서에 무관하게 실행 가능해야 함
- Given-When-Then 패턴으로 명확한 구조 유지
- 의미 있는 테스트 메서드명 사용
- 테스트 데이터는 각 테스트에서 생성하거나 고정된 픽스처 사용
- Mock은 필요한 경우에만 사용, 과도한 Mock 사용 지양

### DON'T (하지 말 것)
- 프로덕션 데이터베이스에서 테스트 실행 금지
- 테스트 간 상태 공유 금지
- Thread.sleep()을 사용한 시간 기반 테스트 지양
- 테스트에서 System.out.println() 사용 지양
- 하나의 테스트에서 너무 많은 것을 검증하지 말 것

### 테스트 코드 리뷰 체크리스트
- [ ] 테스트 메서드명이 테스트 의도를 명확히 표현하는가?
- [ ] Given-When-Then 구조가 명확한가?
- [ ] 테스트가 독립적으로 실행 가능한가?
- [ ] 적절한 어설션(assertion)을 사용했는가?
- [ ] 테스트 데이터가 적절히 관리되고 있는가?
- [ ] Mock 객체 사용이 적절한가?