# Input Context

\n---\n## File: context/architecture.md\n
# 시스템 아키텍처

## 개요

대학 그룹 관리 시스템은 Spring Boot(백엔드)와 Flutter(프론트엔드)로 구성된 풀스택 웹 애플리케이션입니다. REST API 기반의 3-tier 아키텍처를 채택하여 확장 가능하고 유지보수하기 쉬운 구조로 설계되었습니다.

## 전체 시스템 구성

```
┌─────────────────┐    HTTP/REST API    ┌─────────────────┐
│   Flutter Web   │ ←──────────────────→ │  Spring Boot    │
│   (Frontend)    │    JSON Response    │   (Backend)     │
└─────────────────┘                     └─────────────────┘
                                                 │
                                        JPA/Hibernate
                                                 │
                                        ┌─────────────────┐
                                        │   PostgreSQL    │
                                        │   (Production)  │
                                        │       H2        │
                                        │  (Development)  │
                                        └─────────────────┘
```

## 백엔드 아키텍처 (Spring Boot)

### 기술 스택
- **런타임**: JVM 17, Kotlin 1.9.25
- **프레임워크**: Spring Boot 3.5.5
- **주요 모듈**:
  - Spring Data JPA (데이터 접근)
  - Spring Security (인증/인가)
  - Spring Web (REST API)
  - OAuth2 Client (소셜 로그인)
- **문서화**: SpringDoc OpenAPI 3 (Swagger UI)
- **코드 품질**: Ktlint, Detekt

### 패키지 구조
```
org.castlekong.backend/
├── config/          # 설정 클래스들
├── controller/      # REST 컨트롤러
├── service/         # 비즈니스 로직
├── repository/      # 데이터 접근 계층
├── entity/          # JPA 엔티티
├── dto/             # 데이터 전송 객체
├── security/        # 보안 설정
└── exception/       # 예외 처리
```

### 레이어별 책임
- **Controller Layer**: HTTP 요청/응답 처리, 입력 검증
- **Service Layer**: 비즈니스 로직 구현, 트랜잭션 관리
- **Repository Layer**: 데이터베이스 CRUD 연산
- **Entity Layer**: 도메인 모델 정의

## 프론트엔드 아키텍처 (Flutter)

### 기술 스택 (계획)
- **프레임워크**: Flutter 3.x
- **언어**: Dart
- **상태 관리**: Provider/Riverpod (예정)
- **HTTP 통신**: Dio
- **라우팅**: Go Router

### 구조 (계획)
```
lib/
├── main.dart
├── models/          # 데이터 모델
├── services/        # API 서비스
├── providers/       # 상태 관리
├── screens/         # 화면 위젯
├── widgets/         # 재사용 위젯
└── utils/           # 유틸리티 함수
```

## 데이터베이스 설계

### 데이터베이스 전략
- **개발/테스트**: H2 인메모리 데이터베이스
- **프로덕션**: PostgreSQL
- **ORM**: Hibernate (Spring Data JPA)
- **마이그레이션**: Flyway (향후 도입 예정)

### 주요 도메인 (예상)
- **User**: 사용자 정보
- **Group**: 그룹 정보
- **Member**: 그룹 멤버십
- **Role**: 사용자 권한

## 보안 아키텍처

### 인증/인가
- **인증 방식**: OAuth2 + JWT (계획)
- **소셜 로그인**: 구글, 카카오 등 (계획)
- **권한 관리**: Spring Security RBAC
- **세션 관리**: Stateless JWT 토큰

### 보안 정책
- HTTPS 강제 적용
- CORS 설정
- XSS, CSRF 방어
- SQL Injection 방어 (JPA 사용)

## 배포 및 인프라

### 개발 환경
- **로컬 개발**: Spring Boot DevTools, H2 Console
- **빌드 도구**: Gradle
- **코드 품질**: Ktlint, Detekt 자동화

### 배포 전략 (계획)
- **컨테이너화**: Docker
- **클라우드 배포**: AWS/GCP (예정)
- **CI/CD**: GitHub Actions (예정)

## 확장성 고려사항

### 성능 최적화
- JPA 쿼리 최적화 (N+1 문제 방지)
- 데이터베이스 인덱싱
- API 응답 캐싱 (Redis 도입 검토)

### 모니터링
- Spring Boot Actuator
- 애플리케이션 로그 전략
- 성능 메트릭 수집 (향후)

## 제약사항 및 고려사항

### 현재 제약사항
- 프론트엔드 Flutter 프로젝트 미설정
- 데이터베이스 스키마 미정의
- 인증/인가 시스템 미구현
- API 엔드포인트 미정의

### 향후 개선 계획
- 마이크로서비스 아키텍처 전환 고려
- 실시간 알림 시스템 (WebSocket)
- 파일 업로드/다운로드 기능
- 다국어 지원 (i18n)
\n---\n## File: context/CHANGELOG.md\n
# Context Changelog

- 초기화: 컨텍스트 디렉토리 생성 및 워크플로우 도입

\n---\n## File: context/testing.md\n
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
\n---\n## File: context/README.md\n
# Project Static Context

이 디렉토리는 장기적으로 유지되는 프로젝트의 정적 지식(아키텍처 원칙, 코드 규칙, API 규약 등)을 담습니다. `tasks` 내 작업 패키지에서 도출된 새로운 인사이트는 작업 완료 시 이곳 문서에 반영됩니다.

구성 권장안:
- architecture.md: 시스템 아키텍처 개요, 구성요소, 의존성 지도
- api-conventions.md: REST API/DTO 규칙, 에러 포맷, 버전 정책
- coding-standards.md: 패키징, 네이밍, 로그/예외 처리 규칙
- security.md: 인증/인가, 암호화, 시크릿 관리
- testing.md: 테스트 전략, 계층, 픽스처 규칙

운영 규칙:
- 문서명은 소문자-kebab-case로 작성합니다.
- 큰 변경사항은 CHANGELOG.md에 항목을 추가합니다.
- `.gemini/metadata.json`의 include/exclude 패턴으로 인덱싱 범위를 제어합니다.

\n---\n## File: context/coding-standards.md\n
# 코딩 표준 및 규칙

## 일반 원칙

### 코드 작성 철학
- **가독성**: 다른 개발자가 쉽게 이해할 수 있는 코드
- **일관성**: 프로젝트 전체에서 일관된 스타일 유지
- **간결성**: 불필요한 복잡성 제거
- **안전성**: 런타임 에러 방지를 위한 방어적 프로그래밍

## Kotlin 코딩 표준

### 네이밍 규칙

#### 클래스 및 인터페이스
```kotlin
// PascalCase 사용
class UserController
interface UserRepository
data class CreateUserRequest
enum class UserRole
```

#### 함수 및 변수
```kotlin
// camelCase 사용
fun getUserById(id: Long): User
val userName: String
var isActive: Boolean
```

#### 상수
```kotlin
// UPPER_SNAKE_CASE 사용
const val MAX_USERNAME_LENGTH = 50
const val DEFAULT_PAGE_SIZE = 20
const val JWT_SECRET_KEY = "jwt.secret.key"
```

#### 패키지명
```kotlin
// 소문자, 점으로 구분
package org.castlekong.backend.controller
package org.castlekong.backend.service
package org.castlekong.backend.repository
```

### 코드 구조 규칙

#### 파일 구조
```kotlin
// 1. 패키지 선언
package org.castlekong.backend.service

// 2. import 문 (최소한으로)
import org.springframework.stereotype.Service
import org.castlekong.backend.entity.User

// 3. 클래스 선언
@Service
class UserService(
    private val userRepository: UserRepository
) {
    // 구현 내용
}
```

#### 클래스 멤버 순서
```kotlin
class UserController {
    // 1. companion object
    companion object {
        private const val LOG = LoggerFactory.getLogger(UserController::class.java)
    }
    
    // 2. 프로퍼티
    private val userService: UserService
    
    // 3. 생성자
    constructor(userService: UserService) {
        this.userService = userService
    }
    
    // 4. public 함수
    fun getUsers(): List<User> { }
    
    // 5. private 함수
    private fun validateUser(user: User) { }
}
```

### 함수 작성 규칙

#### 함수 길이 제한
- 한 함수는 최대 30줄을 넘지 않도록 작성
- 복잡한 로직은 여러 함수로 분리

#### 매개변수 개수 제한
```kotlin
// 좋은 예: 매개변수 3개 이하
fun createUser(name: String, email: String, role: UserRole): User

// 나쁜 예: 매개변수가 너무 많음 - 데이터 클래스 사용
// fun createUser(name: String, email: String, password: String, 
//                phoneNumber: String, address: String, age: Int): User

// 개선된 예
data class CreateUserRequest(
    val name: String,
    val email: String,
    val password: String,
    val phoneNumber: String,
    val address: String,
    val age: Int
)

fun createUser(request: CreateUserRequest): User
```

#### Null 안전성
```kotlin
// Null 가능 타입 최소화
fun findUserById(id: Long): User? {
    return userRepository.findById(id).orElse(null)
}

// Safe call 연산자 활용
user?.email?.toLowerCase()

// Elvis 연산자 활용
val displayName = user?.name ?: "Unknown User"
```

## Spring Boot 관련 규칙

### 어노테이션 사용
```kotlin
@RestController
@RequestMapping("/api/v1/users")
@Validated
class UserController(
    private val userService: UserService
) {
    
    @GetMapping("/{id}")
    fun getUser(@PathVariable @Valid id: Long): ResponseEntity<UserResponse> {
        // 구현
    }
    
    @PostMapping
    fun createUser(@RequestBody @Valid request: CreateUserRequest): ResponseEntity<UserResponse> {
        // 구현
    }
}
```

### 의존성 주입
```kotlin
// 생성자 주입 사용 (권장)
@Service
class UserService(
    private val userRepository: UserRepository,
    private val passwordEncoder: PasswordEncoder
) {
    // 구현
}

// 필드 주입 사용 금지
// @Autowired
// private lateinit var userRepository: UserRepository
```

### Configuration 클래스
```kotlin
@Configuration
@EnableWebSecurity
class SecurityConfig {
    
    @Bean
    fun passwordEncoder(): PasswordEncoder {
        return BCryptPasswordEncoder()
    }
    
    @Bean
    @ConditionalOnProperty(name = ["app.security.enabled"], havingValue = "true")
    fun securityFilterChain(http: HttpSecurity): SecurityFilterChain {
        // 설정
    }
}
```

## 데이터베이스 관련 규칙

### Entity 클래스
```kotlin
@Entity
@Table(name = "users")
data class User(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,
    
    @Column(nullable = false, length = 100)
    val name: String,
    
    @Column(nullable = false, unique = true)
    val email: String,
    
    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),
    
    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now()
) {
    // JPA 요구사항을 위한 기본 생성자
    constructor() : this(0, "", "", LocalDateTime.now(), LocalDateTime.now())
}
```

### Repository 인터페이스
```kotlin
@Repository
interface UserRepository : JpaRepository<User, Long> {
    
    fun findByEmail(email: String): User?
    
    @Query("SELECT u FROM User u WHERE u.name LIKE %:name%")
    fun findByNameContaining(@Param("name") name: String): List<User>
}
```

## 예외 처리 규칙

### 커스텀 예외 정의
```kotlin
// 비즈니스 예외
sealed class BusinessException(message: String) : RuntimeException(message)

class UserNotFoundException(userId: Long) : 
    BusinessException("User not found with id: $userId")

class DuplicateEmailException(email: String) : 
    BusinessException("User already exists with email: $email")
```

### 글로벌 예외 처리기
```kotlin
@RestControllerAdvice
class GlobalExceptionHandler {
    
    @ExceptionHandler(UserNotFoundException::class)
    fun handleUserNotFound(ex: UserNotFoundException): ResponseEntity<ErrorResponse> {
        val errorResponse = ErrorResponse(
            code = "USER_NOT_FOUND",
            message = ex.message ?: "User not found"
        )
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResponse)
    }
}
```

## 로깅 규칙

### 로거 설정
```kotlin
class UserService {
    companion object {
        private val logger = LoggerFactory.getLogger(UserService::class.java)
    }
    
    fun createUser(request: CreateUserRequest): User {
        logger.info("Creating user with email: ${request.email}")
        
        try {
            val user = userRepository.save(User.from(request))
            logger.info("Successfully created user with id: ${user.id}")
            return user
        } catch (ex: Exception) {
            logger.error("Failed to create user with email: ${request.email}", ex)
            throw ex
        }
    }
}
```

### 로그 레벨 가이드
- **ERROR**: 시스템 오류, 예외 상황
- **WARN**: 경고, 잠재적 문제
- **INFO**: 중요한 비즈니스 이벤트
- **DEBUG**: 상세한 실행 흐름 (개발 환경)
- **TRACE**: 매우 상세한 디버그 정보

## 테스트 코드 규칙

### 테스트 클래스 네이밍
```kotlin
// 테스트 대상 클래스 + Test
class UserServiceTest {
    
    @Test
    fun `should create user when valid request provided`() {
        // given
        val request = CreateUserRequest("John", "john@example.com", "password")
        
        // when
        val result = userService.createUser(request)
        
        // then
        assertThat(result.email).isEqualTo("john@example.com")
    }
}
```

## 코드 품질 도구

### Ktlint 설정
```gradle
ktlint {
    version.set("0.50.0")
    debug.set(true)
    verbose.set(true)
    android.set(false)
    outputToConsole.set(true)
    ignoreFailures.set(false)
}
```

### Detekt 규칙
```yaml
# detekt.yml
complexity:
  LongMethod:
    threshold: 30
  TooManyFunctions:
    thresholdInFiles: 20
    thresholdInClasses: 20
    
style:
  MaxLineLength:
    maxLineLength: 120
```

## Git 커밋 메시지 규칙

### 커밋 메시지 형식
```
<type>(<scope>): <subject>

<body>

<footer>
```

### 타입별 사용 예시
- **feat**: 새로운 기능 추가
- **fix**: 버그 수정
- **docs**: 문서 수정
- **style**: 코드 스타일 변경
- **refactor**: 코드 리팩토링
- **test**: 테스트 코드 추가/수정
- **chore**: 빌드 설정, 패키지 관리

### 예시
```
feat(user): add user registration API

- Implement user registration endpoint
- Add email validation
- Add password encryption

Closes #123
```
\n---\n## File: context/api-conventions.md\n
# API 설계 규약

## REST API 설계 원칙

### 기본 원칙
- RESTful 설계 패턴 준수
- HTTP 메서드의 의미에 맞는 사용
- 일관된 URL 구조 및 네이밍
- 명확한 HTTP 상태 코드 반환
- JSON 기반 데이터 교환

### Base URL 구조
```
# 개발 환경
http://localhost:8080/api/v1

# 프로덕션 환경 (예정)
https://api.univ-group.example.com/v1
```

## URL 설계 규칙

### 네이밍 규칙
- **리소스명**: 소문자, 복수형, kebab-case 사용
- **경로 구조**: `/api/v{version}/{resource}/{id}/{sub-resource}`
- **쿼리 파라미터**: snake_case 사용

### 리소스 URL 예시
```
# 사용자 관리
GET    /api/v1/users              # 사용자 목록 조회
POST   /api/v1/users              # 새 사용자 생성
GET    /api/v1/users/{id}         # 특정 사용자 조회
PUT    /api/v1/users/{id}         # 사용자 정보 전체 수정
PATCH  /api/v1/users/{id}         # 사용자 정보 부분 수정
DELETE /api/v1/users/{id}         # 사용자 삭제

# 그룹 관리
GET    /api/v1/groups             # 그룹 목록 조회
POST   /api/v1/groups             # 새 그룹 생성
GET    /api/v1/groups/{id}        # 특정 그룹 조회
PUT    /api/v1/groups/{id}        # 그룹 정보 수정
DELETE /api/v1/groups/{id}        # 그룹 삭제

# 그룹 멤버 관리
GET    /api/v1/groups/{id}/members    # 그룹 멤버 목록
POST   /api/v1/groups/{id}/members    # 그룹에 멤버 추가
DELETE /api/v1/groups/{id}/members/{user_id}  # 그룹에서 멤버 제거
```

## HTTP 메서드 사용 규칙

| 메서드 | 용도 | 멱등성 | 안전성 |
|--------|------|--------|--------|
| GET | 리소스 조회 | O | O |
| POST | 리소스 생성 | X | X |
| PUT | 리소스 전체 교체 | O | X |
| PATCH | 리소스 부분 수정 | X | X |
| DELETE | 리소스 삭제 | O | X |

## 응답 형식 표준

### 성공 응답 구조
```json
{
  "success": true,
  "data": {
    // 실제 데이터
  },
  "message": "요청이 성공적으로 처리되었습니다.",
  "timestamp": "2025-09-10T16:30:00Z"
}
```

### 에러 응답 구조
```json
{
  "success": false,
  "error": {
    "code": "USER_NOT_FOUND",
    "message": "사용자를 찾을 수 없습니다.",
    "details": "ID 123에 해당하는 사용자가 존재하지 않습니다."
  },
  "timestamp": "2025-09-10T16:30:00Z",
  "path": "/api/v1/users/123"
}
```

### 페이지네이션 응답
```json
{
  "success": true,
  "data": {
    "content": [
      // 데이터 배열
    ],
    "page": {
      "number": 0,
      "size": 20,
      "total_elements": 150,
      "total_pages": 8,
      "first": true,
      "last": false
    }
  }
}
```

## HTTP 상태 코드 사용 기준

### 성공 응답 (2xx)
- **200 OK**: 일반적인 성공 (GET, PUT, PATCH)
- **201 Created**: 리소스 생성 성공 (POST)
- **204 No Content**: 성공했지만 반환할 데이터 없음 (DELETE)

### 클라이언트 에러 (4xx)
- **400 Bad Request**: 잘못된 요청 형식
- **401 Unauthorized**: 인증 필요
- **403 Forbidden**: 권한 부족
- **404 Not Found**: 리소스를 찾을 수 없음
- **409 Conflict**: 리소스 충돌 (중복 생성 등)
- **422 Unprocessable Entity**: 유효성 검증 실패

### 서버 에러 (5xx)
- **500 Internal Server Error**: 서버 내부 오류
- **503 Service Unavailable**: 서버 일시 사용 불가

## DTO 설계 규칙

### Request DTO
```kotlin
// 사용자 생성 요청
data class CreateUserRequest(
    @field:NotBlank(message = "이름은 필수입니다")
    val name: String,
    
    @field:Email(message = "유효한 이메일 형식이어야 합니다")
    val email: String,
    
    @field:Size(min = 6, message = "비밀번호는 최소 6자 이상이어야 합니다")
    val password: String
)
```

### Response DTO
```kotlin
// 사용자 응답
data class UserResponse(
    val id: Long,
    val name: String,
    val email: String,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime
)
```

## 에러 코드 정의

### 사용자 관련 에러
- `USER_NOT_FOUND`: 사용자를 찾을 수 없음
- `USER_ALREADY_EXISTS`: 이미 존재하는 사용자
- `INVALID_USER_DATA`: 유효하지 않은 사용자 데이터

### 그룹 관련 에러
- `GROUP_NOT_FOUND`: 그룹을 찾을 수 없음
- `GROUP_ALREADY_EXISTS`: 이미 존재하는 그룹
- `GROUP_MEMBER_LIMIT_EXCEEDED`: 그룹 멤버 제한 초과

### 인증/인가 에러
- `AUTHENTICATION_REQUIRED`: 인증 필요
- `INVALID_TOKEN`: 유효하지 않은 토큰
- `ACCESS_DENIED`: 접근 권한 없음
- `TOKEN_EXPIRED`: 토큰 만료

## 버전 관리

### API 버전 정책
- URL 경로에 버전 명시: `/api/v1/...`
- 하위 호환성 유지 원칙
- 주요 변경 시에만 버전 업
- 이전 버전 최소 6개월 지원

### 버전 변경 기준
- **Major 변경**: 기존 API 호환성 중단
- **Minor 변경**: 새로운 기능 추가 (하위 호환)
- **Patch 변경**: 버그 수정, 성능 개선

## 보안 고려사항

### 인증 헤더
```
Authorization: Bearer {JWT_TOKEN}
```

### CORS 설정
```kotlin
@CrossOrigin(
    origins = ["http://localhost:3000", "https://univ-group.example.com"],
    allowedHeaders = ["*"],
    methods = [RequestMethod.GET, RequestMethod.POST, RequestMethod.PUT, 
               RequestMethod.PATCH, RequestMethod.DELETE]
)
```

### 민감 데이터 처리
- 비밀번호는 응답에 포함하지 않음
- 개인정보는 필요한 경우에만 노출
- 로그에 민감 정보 기록 금지

## API 문서화

### OpenAPI 3.0 (Swagger) 활용
- 모든 API 엔드포인트 문서화
- Request/Response 스키마 정의
- 에러 응답 예시 포함
- 인증 방법 명시

### 접근 경로
```
# Swagger UI
http://localhost:8080/swagger-ui/index.html

# OpenAPI JSON
http://localhost:8080/v3/api-docs
```
\n---\n## File: context/security.md\n
# 보안 정책 및 가이드

## 개요

대학 그룹 관리 시스템의 보안 정책은 사용자 데이터 보호, 안전한 인증/인가, 그리고 일반적인 웹 보안 위협 방어를 목표로 합니다.

## 인증 (Authentication)

### 인증 전략
- **주요 방식**: OAuth2 + JWT (JSON Web Token)
- **소셜 로그인**: Google, Kakao, Naver (계획)
- **세션 관리**: Stateless JWT 기반

### JWT 토큰 설계
```kotlin
// JWT 클레임 구조
{
  "sub": "user_id",           // 사용자 ID
  "email": "user@example.com", // 사용자 이메일
  "roles": ["USER", "ADMIN"],  // 사용자 권한
  "iat": 1694352000,          // 발급 시간
  "exp": 1694438400           // 만료 시간 (24시간)
}
```

### 토큰 관리
```kotlin
@Component
class JwtTokenProvider {
    companion object {
        private const val ACCESS_TOKEN_EXPIRE_TIME = 24 * 60 * 60 * 1000L // 24시간
        private const val REFRESH_TOKEN_EXPIRE_TIME = 7 * 24 * 60 * 60 * 1000L // 7일
    }
    
    fun generateAccessToken(authentication: Authentication): String
    fun generateRefreshToken(userId: Long): String
    fun validateToken(token: String): Boolean
    fun getAuthentication(token: String): Authentication
}
```

### OAuth2 설정
```kotlin
@Configuration
@EnableWebSecurity
class OAuth2Config {
    
    @Bean
    fun oauth2ClientRegistrationRepository(): ClientRegistrationRepository {
        return InMemoryClientRegistrationRepository(
            googleClientRegistration(),
            kakaoClientRegistration()
        )
    }
    
    private fun googleClientRegistration(): ClientRegistration {
        return ClientRegistration.withRegistrationId("google")
            .clientId("\${oauth2.google.client-id}")
            .clientSecret("\${oauth2.google.client-secret}")
            .scope("openid", "profile", "email")
            .authorizationUri("https://accounts.google.com/o/oauth2/auth")
            .tokenUri("https://accounts.google.com/o/oauth2/token")
            .build()
    }
}
```

## 인가 (Authorization)

### 권한 모델
```kotlin
enum class UserRole {
    GUEST,      // 게스트 (읽기 전용)
    USER,       // 일반 사용자
    MODERATOR,  // 중재자
    ADMIN       // 관리자
}

enum class Permission {
    // 사용자 관련
    USER_READ,
    USER_WRITE,
    USER_DELETE,
    
    // 그룹 관련
    GROUP_READ,
    GROUP_WRITE,
    GROUP_DELETE,
    GROUP_MANAGE_MEMBERS,
    
    // 시스템 관리
    SYSTEM_ADMIN
}
```

### Spring Security 설정
```kotlin
@Configuration
@EnableWebSecurity
@EnableMethodSecurity(prePostEnabled = true)
class SecurityConfig {
    
    @Bean
    fun securityFilterChain(http: HttpSecurity): SecurityFilterChain {
        return http
            .csrf { it.disable() }
            .sessionManagement { 
                it.sessionCreationPolicy(SessionCreationPolicy.STATELESS) 
            }
            .authorizeHttpRequests { auth ->
                auth
                    .requestMatchers("/api/v1/auth/**").permitAll()
                    .requestMatchers("/api/v1/public/**").permitAll()
                    .requestMatchers(HttpMethod.GET, "/api/v1/groups").hasRole("USER")
                    .requestMatchers(HttpMethod.POST, "/api/v1/groups").hasRole("USER")
                    .requestMatchers("/api/v1/admin/**").hasRole("ADMIN")
                    .anyRequest().authenticated()
            }
            .oauth2Login { oauth2 ->
                oauth2.successHandler(oauth2AuthenticationSuccessHandler())
            }
            .addFilterBefore(jwtAuthenticationFilter(), UsernamePasswordAuthenticationFilter::class.java)
            .build()
    }
}
```

### 메서드 수준 보안
```kotlin
@RestController
@RequestMapping("/api/v1/groups")
class GroupController {
    
    @PreAuthorize("hasRole('USER')")
    @GetMapping
    fun getGroups(): List<GroupResponse> { }
    
    @PreAuthorize("hasRole('USER') and #request.ownerId == authentication.principal.id")
    @PostMapping
    fun createGroup(@RequestBody request: CreateGroupRequest): GroupResponse { }
    
    @PreAuthorize("@groupService.isGroupOwner(#groupId, authentication.principal.id) or hasRole('ADMIN')")
    @DeleteMapping("/{groupId}")
    fun deleteGroup(@PathVariable groupId: Long): ResponseEntity<Void> { }
}
```

## 비밀번호 보안

### 비밀번호 정책
- **최소 길이**: 8자 이상
- **복잡성**: 대소문자, 숫자, 특수문자 조합
- **금지 패턴**: 연속된 문자, 사전 단어, 개인정보 포함

### 암호화
```kotlin
@Configuration
class PasswordConfig {
    
    @Bean
    fun passwordEncoder(): PasswordEncoder {
        return BCryptPasswordEncoder(12) // 강력한 해시 강도
    }
}

@Service
class UserService(
    private val passwordEncoder: PasswordEncoder
) {
    
    fun createUser(request: CreateUserRequest): User {
        val encodedPassword = passwordEncoder.encode(request.password)
        // 사용자 생성 로직
    }
    
    fun changePassword(userId: Long, currentPassword: String, newPassword: String) {
        val user = findUserById(userId)
        
        if (!passwordEncoder.matches(currentPassword, user.password)) {
            throw InvalidPasswordException("현재 비밀번호가 일치하지 않습니다")
        }
        
        validatePasswordPolicy(newPassword)
        val encodedNewPassword = passwordEncoder.encode(newPassword)
        // 비밀번호 업데이트
    }
}
```

## 데이터 보호

### 민감 데이터 암호화
```kotlin
@Entity
@Table(name = "users")
data class User(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,
    
    val name: String,
    val email: String,
    
    @Column(name = "password_hash")
    val password: String, // 암호화된 비밀번호
    
    @Column(name = "phone_number")
    @Convert(converter = EncryptedStringConverter::class)
    val phoneNumber: String? = null, // 암호화된 전화번호
    
    val createdAt: LocalDateTime = LocalDateTime.now()
)

@Converter
class EncryptedStringConverter : AttributeConverter<String?, String?> {
    
    override fun convertToDatabaseColumn(attribute: String?): String? {
        return attribute?.let { encryptionService.encrypt(it) }
    }
    
    override fun convertToEntityAttribute(dbData: String?): String? {
        return dbData?.let { encryptionService.decrypt(it) }
    }
}
```

### 로그 보안
```kotlin
// 민감 정보 로깅 방지
@Component
class SecurityAuditLogger {
    
    private val logger = LoggerFactory.getLogger(SecurityAuditLogger::class.java)
    
    fun logLoginAttempt(email: String, success: Boolean, ip: String) {
        val maskedEmail = maskEmail(email)
        logger.info("Login attempt - Email: $maskedEmail, Success: $success, IP: $ip")
    }
    
    private fun maskEmail(email: String): String {
        val parts = email.split("@")
        if (parts.size != 2) return "***"
        
        val localPart = parts[0]
        val domain = parts[1]
        val maskedLocal = if (localPart.length > 2) {
            "${localPart.first()}***${localPart.last()}"
        } else {
            "***"
        }
        return "$maskedLocal@$domain"
    }
}
```

## API 보안

### CORS 설정
```kotlin
@Configuration
class CorsConfig {
    
    @Bean
    fun corsConfigurationSource(): CorsConfigurationSource {
        val configuration = CorsConfiguration()
        
        // 허용할 오리진 (개발/프로덕션 환경별 설정)
        configuration.allowedOrigins = listOf(
            "http://localhost:3000",  // 개발 환경
            "https://univ-group.example.com"  // 프로덕션 환경
        )
        
        configuration.allowedMethods = listOf("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS")
        configuration.allowedHeaders = listOf("*")
        configuration.allowCredentials = true
        configuration.maxAge = 3600L
        
        val source = UrlBasedCorsConfigurationSource()
        source.registerCorsConfiguration("/api/**", configuration)
        return source
    }
}
```

### Rate Limiting
```kotlin
@Component
class RateLimitingInterceptor : HandlerInterceptor {
    
    private val rateLimiter = RateLimiter.create(100.0) // 초당 100 요청
    
    override fun preHandle(request: HttpServletRequest, response: HttpServletResponse, handler: Any): Boolean {
        val clientIP = getClientIP(request)
        
        if (!rateLimiter.tryAcquire()) {
            response.status = HttpStatus.TOO_MANY_REQUESTS.value()
            response.writer.write("Rate limit exceeded")
            return false
        }
        
        return true
    }
}
```

### Input Validation
```kotlin
// DTO 레벨 검증
data class CreateUserRequest(
    @field:NotBlank(message = "이름은 필수입니다")
    @field:Size(min = 2, max = 50, message = "이름은 2-50자 사이여야 합니다")
    val name: String,
    
    @field:Email(message = "유효한 이메일 형식이어야 합니다")
    val email: String,
    
    @field:Pattern(
        regexp = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[@\$!%*?&])[A-Za-z\\d@\$!%*?&]{8,}$",
        message = "비밀번호는 대소문자, 숫자, 특수문자를 포함한 8자 이상이어야 합니다"
    )
    val password: String
)

// 서비스 레벨 추가 검증
@Service
class ValidationService {
    
    fun validateUserInput(request: CreateUserRequest) {
        // SQL Injection 방지
        if (containsSqlKeywords(request.name) || containsSqlKeywords(request.email)) {
            throw InvalidInputException("유효하지 않은 입력입니다")
        }
        
        // XSS 방지
        if (containsHtmlTags(request.name)) {
            throw InvalidInputException("HTML 태그는 허용되지 않습니다")
        }
    }
}
```

## 보안 헤더 설정

```kotlin
@Configuration
class SecurityHeadersConfig {
    
    @Bean
    fun securityHeadersFilter(): FilterRegistrationBean<SecurityHeadersFilter> {
        val registration = FilterRegistrationBean<SecurityHeadersFilter>()
        registration.filter = SecurityHeadersFilter()
        registration.addUrlPatterns("/*")
        registration.order = 1
        return registration
    }
}

class SecurityHeadersFilter : Filter {
    
    override fun doFilter(request: ServletRequest, response: ServletResponse, chain: FilterChain) {
        val httpResponse = response as HttpServletResponse
        
        // XSS 보호
        httpResponse.setHeader("X-XSS-Protection", "1; mode=block")
        
        // Content Type 스니핑 방지
        httpResponse.setHeader("X-Content-Type-Options", "nosniff")
        
        // 클릭재킹 방지
        httpResponse.setHeader("X-Frame-Options", "DENY")
        
        // HSTS (HTTPS 강제)
        httpResponse.setHeader("Strict-Transport-Security", "max-age=31536000; includeSubDomains")
        
        // Content Security Policy
        httpResponse.setHeader("Content-Security-Policy", 
            "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'")
        
        chain.doFilter(request, response)
    }
}
```

## 보안 모니터링 및 감사

### 보안 이벤트 로깅
```kotlin
@Component
class SecurityEventLogger {
    
    private val logger = LoggerFactory.getLogger(SecurityEventLogger::class.java)
    
    @EventListener
    fun handleAuthenticationSuccess(event: AuthenticationSuccessEvent) {
        val username = event.authentication.name
        val ip = getClientIP()
        logger.info("SUCCESS_LOGIN - User: $username, IP: $ip")
    }
    
    @EventListener
    fun handleAuthenticationFailure(event: AbstractAuthenticationFailureEvent) {
        val username = event.authentication.name
        val ip = getClientIP()
        logger.warn("FAILED_LOGIN - User: $username, IP: $ip, Reason: ${event.exception.message}")
    }
    
    @EventListener
    fun handleAccessDenied(event: AuthorizationDeniedEvent) {
        val username = event.authentication?.name ?: "anonymous"
        val ip = getClientIP()
        logger.warn("ACCESS_DENIED - User: $username, IP: $ip, Resource: ${event.resource}")
    }
}
```

## 환경변수 및 시크릿 관리

### 설정 파일 보안
```yaml
# application.yml - 민감 정보는 환경변수로
spring:
  datasource:
    url: \${DB_URL:jdbc:h2:mem:testdb}
    username: \${DB_USERNAME:sa}
    password: \${DB_PASSWORD:}
  
  security:
    oauth2:
      client:
        registration:
          google:
            client-id: \${GOOGLE_CLIENT_ID}
            client-secret: \${GOOGLE_CLIENT_SECRET}

jwt:
  secret: \${JWT_SECRET}
  expiration: \${JWT_EXPIRATION:86400000}

app:
  cors:
    allowed-origins: \${CORS_ALLOWED_ORIGINS:http://localhost:3000}
```

### 시크릿 검증
```kotlin
@Component
@ConfigurationProperties(prefix = "app.security")
class SecurityProperties {
    
    @PostConstruct
    fun validateProperties() {
        require(jwtSecret.length >= 32) { 
            "JWT secret must be at least 32 characters long" 
        }
        
        require(allowedOrigins.isNotEmpty()) { 
            "At least one CORS origin must be configured" 
        }
    }
    
    lateinit var jwtSecret: String
    lateinit var allowedOrigins: List<String>
}
```

## 보안 체크리스트

### 개발 단계
- [ ] 모든 API 엔드포인트에 적절한 인증/인가 적용
- [ ] 입력 데이터 검증 및 이스케이핑
- [ ] 비밀번호 안전한 해싱
- [ ] 민감 데이터 암호화
- [ ] SQL Injection 방지 (JPA 사용)
- [ ] XSS 방지 (CSP 헤더, 입력 검증)

### 배포 단계
- [ ] HTTPS 적용
- [ ] 보안 헤더 설정
- [ ] 환경변수로 시크릿 관리
- [ ] 불필요한 포트 및 서비스 비활성화
- [ ] 정기적인 보안 업데이트

### 운영 단계
- [ ] 보안 이벤트 모니터링
- [ ] 정기적인 보안 감사
- [ ] 백업 데이터 암호화
- [ ] 접근 로그 분석
