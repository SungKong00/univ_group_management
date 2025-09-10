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