# 일반적 에러 해결 가이드 (Common Error Troubleshooting)

## 백엔드 에러

### 1. 데이터베이스 연결 에러

#### 증상 {#데이터베이스연결}
```
org.springframework.jdbc.CannotGetJdbcConnectionException: Failed to obtain JDBC Connection
```

#### 원인 및 해결
```yaml
# application.yml 확인
spring:
  datasource:
    url: jdbc:h2:mem:testdb  # 개발환경
    # url: jdbc:mysql://localhost:3306/univgroup  # 프로덕션
    username: sa
    password:
    driver-class-name: org.h2.Driver
```

#### H2 콘솔 접근
```
URL: http://localhost:8080/h2-console
JDBC URL: jdbc:h2:mem:testdb
User: sa
Password: (빈 값)
```

### 2. JWT 토큰 관련 에러

#### 만료된 토큰
```
io.jsonwebtoken.ExpiredJwtException: JWT expired at 2024-09-27T10:00:00Z
```

해결: 클라이언트에서 토큰 갱신 또는 재로그인 처리

#### 잘못된 토큰 형식
```
io.jsonwebtoken.MalformedJwtException: Unable to read JSON value
```

해결: Authorization 헤더 형식 확인 (`Bearer {token}`)

### 3. 유효성 검증 에러

#### Request Body 검증 실패
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_FAILED",
    "message": "입력값이 올바르지 않습니다",
    "details": {
      "nickname": "닉네임은 2-20자 사이여야 합니다",
      "studentNo": "학번 형식이 올바르지 않습니다"
    }
  }
}
```

#### DTO 검증 어노테이션 확인
```kotlin
data class CreateGroupRequest(
    @field:Size(min = 2, max = 50, message = "그룹명은 2-50자 사이여야 합니다")
    val name: String,

    @field:NotNull(message = "공개 설정은 필수입니다")
    val visibility: GroupVisibility,

    @field:Size(max = 500, message = "설명은 500자를 초과할 수 없습니다")
    val description: String? = null
)
```

### 4. JPA 연관관계 에러

#### DataIntegrityViolationException (ID 중복 또는 제약조건 위반)

**증상:**
```
org.springframework.dao.DataIntegrityViolationException: could not execute statement; SQL [n/a]; constraint ["PRIMARY KEY ON ..."];
... Caused by: org.h2.jdbc.JdbcSQLIntegrityConstraintViolationException: Unique index or primary key violation
```

**주요 원인 및 해결:**

1.  **H2 DB 시퀀스 불일치 (로컬 개발)**
    -   **원인**: `data.sql`로 수동 삽입한 ID와 DB의 자동 증가(auto-increment) 카운터가 충돌.
    -   **해결**: `data.sql` 마지막에 `ALTER TABLE ... RESTART WITH ...` 쿼리를 추가하여 다음 ID를 명시적으로 지정. 자세한 내용은 [백엔드 가이드 - H2 DB ID 충돌 해결](../implementation/backend/development-setup.md) 참조.

2.  **사용자 동시 생성 (Concurrency Issue)**
    -   **원인**: 여러 요청이 동시에 같은 이메일로 가입을 시도하여 DB의 `UNIQUE` 제약조건 위반.
    -   **해결**: 사용자 생성 로직(`findOrCreateUser`)에서 `saveAndFlush`를 `try-catch`로 감싸고, `DataIntegrityViolationException` 발생 시 해당 사용자를 다시 조회하여 반환. 자세한 내용은 [백엔드 가이드 - 동시성 처리](../implementation/backend/development-setup.md) 참조.

3.  **잘못된 요청 본문 (Invalid Request Body)**
    -   **증상**: `HttpMessageNotReadableException`이 발생하며, 서버 로그에 `FAIL_TO_PARSE`와 유사한 메시지 기록.
    -   **원인**: 클라이언트가 보낸 JSON 요청의 형식이 잘못되었거나, 필수 필드가 누락됨.
    -   **해결**: `GlobalExceptionHandler`에 `HttpMessageNotReadableException` 핸들러를 추가하여 400 Bad Request로 처리하고, 클라이언트에 명확한 에러 메시지("요청 본문을 읽을 수 없습니다. JSON 형식을 확인하세요.")를 반환하도록 개선.

#### LazyInitializationException
```
org.hibernate.LazyInitializationException: could not initialize proxy - no Session
```

해결: `@Transactional` 추가 또는 Fetch Join 사용
```kotlin
@Query("SELECT g FROM Group g JOIN FETCH g.members WHERE g.id = :id")
fun findWithMembers(id: Long): Group?
```

#### 순환 참조 문제
```
com.fasterxml.jackson.databind.JsonMappingException: Infinite recursion
```

해결: `@JsonIgnore` 또는 DTO 변환 사용
```kotlin
@Entity
data class Group(
    @OneToMany(mappedBy = "group")
    @JsonIgnore  // JSON 직렬화에서 제외
    val members: List<GroupMember> = emptyList()
)
```

### 5. 트랜잭션 롤백 에러 (2025-10-09 추가) {#트랜잭션롤백}

#### UnexpectedRollbackException

**증상:**
```
org.springframework.transaction.UnexpectedRollbackException: Transaction silently rolled back because it has been marked as rollback-only
```

**원인:**
- `@Transactional` 메서드 내부에서 **unchecked exception**(RuntimeException)이 발생하면 Spring은 트랜잭션을 rollback-only로 마킹
- 예외를 `try-catch`로 잡아서 처리해도 트랜잭션은 이미 rollback-only 상태
- 메서드가 정상 종료되어 커밋을 시도하면 `UnexpectedRollbackException` 발생

**예시 시나리오:**
```kotlin
@Transactional
fun submitSignupProfile(userId: Long, req: SignupProfileRequest): User {
    val user = userRepository.save(updatedUser)

    // ❌ 문제: joinGroup()에서 BusinessException 발생 시 트랜잭션 롤백
    try {
        groupMemberService.joinGroup(groupId, userId)  // @Transactional 메서드
    } catch (e: Exception) {
        logger.warn("Failed to join group: ${e.message}")
        // 예외를 잡아서 로깅만 하지만, 트랜잭션은 이미 rollback-only!
    }

    return user  // 정상 종료 시도 → UnexpectedRollbackException 발생
}
```

**해결 방법:**

**1. 사전 체크로 예외 발생 방지 (권장)**
```kotlin
@Transactional
fun submitSignupProfile(userId: Long, req: SignupProfileRequest): User {
    val user = userRepository.save(updatedUser)

    // ✅ 해결: 예외가 발생하기 전에 사전 체크
    val alreadyMember = groupMemberRepository.findByGroupIdAndUserId(groupId, userId).isPresent
    if (!alreadyMember) {
        try {
            groupMemberService.joinGroup(groupId, userId)
        } catch (e: Exception) {
            logger.warn("Failed to join group: ${e.message}")
        }
    }

    return user
}
```

**2. 별도 트랜잭션으로 분리**
```kotlin
@Transactional
fun submitSignupProfile(userId: Long, req: SignupProfileRequest): User {
    val user = userRepository.save(updatedUser)

    // ✅ 해결: 자동 가입을 별도 트랜잭션으로 실행
    autoJoinGroupInSeparateTransaction(groupId, userId)

    return user
}

@Transactional(propagation = Propagation.REQUIRES_NEW)
protected open fun autoJoinGroupInSeparateTransaction(groupId: Long, userId: Long) {
    try {
        groupMemberService.joinGroup(groupId, userId)
    } catch (e: Exception) {
        logger.warn("Auto-join failed: ${e.message}")
        // 별도 트랜잭션이므로 외부 트랜잭션에 영향 없음
    }
}
```

**3. noRollbackFor 사용 (비권장)**
```kotlin
// ⚠️ 주의: 특정 예외는 롤백하지 않도록 설정 가능하나,
// 비즈니스 로직에 따라 데이터 정합성 문제 발생 가능
@Transactional(noRollbackFor = [BusinessException::class])
fun submitSignupProfile(...): User {
    // ...
}
```

**관련 문서:**
- [백엔드 가이드 - 트랜잭션 전파 레벨](../implementation/backend/transaction-patterns.md)
- [백엔드 가이드 - 예외 처리 전략](../implementation/backend/exception-handling.md)

## 프론트엔드 에러

### 6. Flutter Web 포트 관련 에러

#### 포트 충돌 문제 {#포트충돌}
```
Error: Port 3000 is already in use
```

해결: **반드시 5173 포트 사용**
```bash
# ❌ 잘못된 명령어
flutter run -d chrome --web-port 3000

# ✅ 올바른 명령어
flutter run -d chrome --web-hostname localhost --web-port 5173
```

### 7. CORS 에러

#### 증상
```
Access to XMLHttpRequest at 'http://localhost:8080/api/groups'
from origin 'http://localhost:5173' has been blocked by CORS policy
```

#### 백엔드 CORS 설정 확인
```kotlin
@Configuration
class WebConfig : WebMvcConfigurer {
    override fun addCorsMappings(registry: CorsRegistry) {
        registry.addMapping("/api/**")
            .allowedOrigins("http://localhost:5173")
            .allowedMethods("GET", "POST", "PUT", "DELETE", "PATCH")
            .allowedHeaders("*")
            .allowCredentials(true)
    }
}
```

### 8. 상태 관리 에러

#### Provider 에러 (Flutter)
```
ProviderNotFoundException: No provider found for type AuthProvider
```

해결: Provider 계층 구조 확인
```dart
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => GroupProvider()),
      ],
      child: MyApp(),
    ),
  );
}
```

#### 무한 리빌드 문제
```dart
// ❌ 잘못된 사용
Widget build(BuildContext context) {
  context.read<AuthProvider>().checkAuth(); // 무한 호출!
  return Text('Hello');
}

// ✅ 올바른 사용
Widget build(BuildContext context) {
  return Consumer<AuthProvider>(
    builder: (context, auth, child) {
      if (!auth.isInitialized) {
        auth.checkAuth();
      }
      return Text('Hello');
    },
  );
}
```

#### 로그아웃 후 이전 계정 데이터 표시 문제 (2025-10-05 추가) {#로그아웃데이터}

**증상:**
```
로그아웃 후 다른 계정으로 로그인했는데,
이전 계정의 워크스페이스 목록이나 그룹 정보가 표시됨
```

**원인:**
- Riverpod FutureProvider/Provider가 데이터를 캐시함
- 로그아웃 시 Provider 상태가 초기화되지 않음
- 계정 전환 시 이전 계정의 캐시된 데이터가 유지됨

**해결: Provider 초기화 시스템 사용**

1. **중앙 Provider 초기화 시스템 설정** (`core/providers/provider_reset.dart`)
```dart
typedef LogoutResetCallback = void Function(Ref ref);

final _providersToInvalidateOnLogout = <ProviderOrFamily<dynamic>>[
  myGroupsProvider,
  homeStateProvider,
  groupCalendarProvider,
  // ... 사용자 데이터 Provider 등록
];

final _customLogoutCallbacks = <LogoutResetCallback>[
  (ref) => ref.read(workspaceStateProvider.notifier).forceClearForLogout(),
  (ref) => ref.read(homeStateProvider.notifier).clearSnapshots(),
];

void resetAllUserDataProviders(Ref ref) {
  for (final callback in _customLogoutCallbacks) {
    callback(ref); // 메모리 스냅샷/로컬 상태 정리
  }

  for (final provider in _providersToInvalidateOnLogout) {
    ref.invalidate(provider); // Riverpod 캐시 무효화
  }
}
```

2. **로그아웃 로직에 통합** (`presentation/providers/auth_provider.dart`)
```dart
Future<void> logout() async {
  await _authService.logout();

  // ✅ 모든 사용자 데이터 Provider 초기화
  resetAllUserDataProviders(_ref);

  // 네비게이션 초기화
  final navigationController = _ref.read(navigationControllerProvider.notifier);
  navigationController.resetToHome();

  state = AuthState(user: null, isLoading: false);
}
```

3. **keepAlive + 로그아웃 가드 패턴 적용** (세션 캐시 유지 + Race Condition 차단)
```dart
// ✅ 권장: keepAlive로 세션 캐시 유지
final myGroupsProvider = FutureProvider<List<GroupMembership>>((ref) async {
  ref.keepAlive();  // 탭 전환 시 캐시 유지
  return await groupService.getMyGroups();
});
```

**로그아웃 시 처리** (`core/providers/provider_reset.dart`):
```dart
void resetAllUserDataProviders(Ref ref) {
  // 모든 Provider 일괄 invalidate (myGroupsProvider 포함)
  for (final provider in _providersToInvalidateOnLogout) {
    ref.invalidate(provider);
  }
}
```

**Race Condition 차단** (`presentation/providers/workspace_state_provider.dart`):
```dart
Future<GroupMembership?> _resolveGroupMembership(String groupId) async {
  // ⭐ 로그아웃 중 접근 시도 차단
  if (_ref.read(authProvider).isLoggingOut) {
    throw LogoutInProgressException();  // 로그아웃 중 → 즉시 에러
  }

  // 일반 그룹 조회
  try {
    final memberships = await _ref.read(myGroupsProvider.future);
    return memberships.firstWhere(
      (group) => group.id.toString() == groupId,
    );
  } catch (e) {
    if (e is LogoutInProgressException) rethrow;
    return null;
  }
}
```

**keepAlive + 로그아웃 가드 사용 이유**:
- **탭 전환 시**: keepAlive로 캐시 유지 (사용자 UX 개선)
- **로그아웃 중**: isLoggingOut 가드로 진행 중인 로드 차단
- **새 로그인 시**: 다음 read에서 새 API 호출로 새 데이터 로드
- **캐시 일관성**: 로그아웃 후 새 계정의 데이터 정상 표시

**검증 방법:**
1. 계정 A로 로그인하여 워크스페이스 생성
2. 로그아웃
3. 계정 B로 로그인
4. 계정 A의 워크스페이스가 보이지 않는지 확인

**관련 파일:**
- `lib/core/providers/provider_reset.dart` - 중앙 Provider 초기화 시스템
- `lib/presentation/providers/workspace_state_provider.dart` - 스냅샷 강제 초기화
- `lib/presentation/providers/home_state_provider.dart` - 홈 스냅샷 초기화
- `lib/presentation/providers/calendar_events_provider.dart` - 캘린더 스냅샷 초기화
- `lib/presentation/providers/auth_provider.dart` - 로그아웃 로직

**참고:** [프론트엔드 가이드 - Provider 초기화 시스템](../implementation/frontend/README.md#상태-관리-패턴)

## API 통신 에러

### 9. 네트워크 연결 에러

#### 타임아웃 에러
```
DioException: The request connection timeout
```

해결: 타임아웃 설정 조정
```dart
final dio = Dio(BaseOptions(
  connectTimeout: Duration(seconds: 10),
  receiveTimeout: Duration(seconds: 10),
  sendTimeout: Duration(seconds: 10),
));
```

#### 연결 거부
```
SocketException: Connection refused
```

체크리스트:
- [ ] 백엔드 서버가 실행 중인가?
- [ ] 포트 번호가 올바른가? (8080)
- [ ] 방화벽이 차단하고 있는가?

### 10. JSON 파싱 에러

#### 예상치 못한 응답 형식
```
FormatException: Unexpected character (at character 1)
<html>...
```

원인: HTML 에러 페이지를 JSON으로 파싱하려 할 때 발생

해결: HTTP 상태 코드 먼저 확인
```dart
if (response.statusCode == 200) {
  return ApiResponse.fromJson(response.data);
} else {
  throw ApiException.fromResponse(response);
}
```

## 인증 관련 에러

### 11. Google OAuth 설정 에러 {#인증}

#### Invalid client error
```
Error 400: invalid_client
```

해결: Google Console에서 설정 확인
```
1. OAuth 2.0 클라이언트 ID 생성
2. 승인된 JavaScript 출처: http://localhost:5173
3. 승인된 리디렉션 URI 설정
```

#### 프로필 미완성 루프
```
사용자가 프로필 설정 후에도 계속 프로필 페이지로 리다이렉트됨
```

해결: 프로필 완료 상태 업데이트 확인
```kotlin
fun completeProfile(userId: Long, request: ProfileRequest) {
    // 프로필 정보 업데이트
    userService.updateProfile(userId, request)

    // ⭐ 중요: profileCompleted 플래그 설정
    userService.markProfileCompleted(userId)
}
```

## 성능 관련 문제

### 12. N+1 쿼리 문제

#### 증상
```sql
-- 그룹 목록 조회 시 각 그룹마다 멤버 수 조회
SELECT * FROM groups;
SELECT COUNT(*) FROM group_members WHERE group_id = 1;
SELECT COUNT(*) FROM group_members WHERE group_id = 2;
...
```

#### 해결: Batch 쿼리 또는 Join 사용
```kotlin
@Query("""
    SELECT g.id, g.name, COUNT(gm.id) as memberCount
    FROM Group g LEFT JOIN g.members gm
    GROUP BY g.id, g.name
""")
fun findGroupsWithMemberCount(): List<GroupWithMemberCount>
```

### 13. 메모리 누수 (Flutter)

#### 증상
앱 사용 중 메모리 사용량이 계속 증가

#### 해결: Dispose 패턴 적용
```dart
class _MyWidgetState extends State<MyWidget> {
  late StreamSubscription _subscription;
  late Timer _timer;

  @override
  void dispose() {
    _subscription.cancel();
    _timer.cancel();
    super.dispose();
  }
}
```

## 개발 환경 문제

### 14. Gradle 빌드 에러

#### Out of memory error
```
org.gradle.api.tasks.TaskExecutionException: Execution failed for task ':compileKotlin'
java.lang.OutOfMemoryError: Java heap space
```

해결: `gradle.properties` 설정
```properties
org.gradle.jvmargs=-Xmx2048m -XX:MaxMetaspaceSize=512m
org.gradle.parallel=true
org.gradle.caching=true
```

#### Dependency conflict
```
Could not resolve dependencies for configuration ':runtimeClasspath'
```

해결: `./gradlew dependencies` 로 의존성 트리 확인 후 버전 통일

### 15. IDE 관련 문제

#### IntelliJ 인덱싱 문제
증상: 자동완성이 안 되고 빨간 줄이 표시됨

해결:
1. File → Invalidate Caches and Restart
2. Reimport Gradle Project
3. Build → Rebuild Project

#### VSCode Flutter 확장 문제
증상: Hot reload가 안 됨

해결:
1. Flutter 확장 재시작
2. 개발자 도구에서 페이지 새로고침 (Ctrl+R)
3. `flutter clean && flutter run`

## 배포 관련 에러

### 16. 빌드 에러

#### Flutter Web 빌드 실패
```
Error: Could not resolve the package 'path' in 'package:path/path.dart'
```

해결:
```bash
flutter clean
flutter pub get
flutter build web
```

#### 환경변수 문제
증상: 프로덕션에서 API 호출이 localhost로 가는 문제

해결: 환경별 설정 분리
```dart
class ApiConfig {
  static const String baseUrl = kDebugMode
    ? 'http://localhost:8080'
    : 'https://api.univgroup.com';
}
```

## 로깅 및 모니터링

### 디버깅을 위한 로깅 설정
```yaml
# application-dev.yml
logging:
  level:
    com.univgroup: DEBUG
    org.springframework.web: DEBUG
    org.springframework.security: DEBUG
```

### 프론트엔드 에러 트래킹
```dart
// Flutter - Global error handler
void main() {
  FlutterError.onError = (FlutterErrorDetails details) {
    print('Flutter Error: ${details.exception}');
    // 로그 수집 서비스에 전송
  };

  runZonedGuarded(() {
    runApp(MyApp());
  }, (error, stack) {
    print('Dart Error: $error');
    // 로그 수집 서비스에 전송
  });
}
```

## 응급 복구 가이드

### 데이터베이스 초기화
```bash
# H2 데이터베이스 재시작 (개발환경)
./gradlew bootRun

# 또는 스키마 재생성
./gradlew flywayClean flywayMigrate
```

### 캐시 초기화
```bash
# Gradle 캐시
./gradlew clean

# Flutter 캐시
flutter clean
flutter pub get
```

## 관련 문서

### 권한 관련 문제
- **권한 에러**: [permission-errors.md](permission-errors.md)

### 구현 참조
- **백엔드 구현 가이드**: [../implementation/backend/README.md](../implementation/backend/README.md)
- **프론트엔드 가이드**: [../implementation/frontend/README.md](../implementation/frontend/README.md)
- **API 참조**: [../implementation/api-reference.md](../implementation/api-reference.md)

### 개발 프로세스
- **개발 워크플로우**: [../workflows/development-flow.md](../workflows/development-flow.md)
- **테스트 전략**: [../workflows/testing-strategy.md](../workflows/testing-strategy.md)
