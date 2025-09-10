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