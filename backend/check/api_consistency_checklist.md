# API 일관성 유지 체크리스트

## 📋 개요

본 문서는 백엔드 API의 일관성을 유지하기 위한 종합적인 체크리스트입니다. 새로운 API 개발 시나 기존 API 수정 시 반드시 준수해야 할 표준화 패턴들을 정리했습니다.

**작성일:** 2025-09-27
**적용 범위:** 모든 Spring Boot Controller 클래스
**준수 필수도:** 🔴 필수, 🟡 권장, 🟢 선택

---

## 🏗️ 1. 컨트롤러 구조 표준화

### 1.1 BaseController 상속 🔴 필수

**모든 컨트롤러는 BaseController를 상속해야 합니다.**

```kotlin
// ✅ 올바른 패턴
@RestController
@RequestMapping("/api/users")
class UserController(
    userService: UserService,  // private 제거
    private val otherService: OtherService,
) : BaseController(userService) {
    // ...
}

// ❌ 잘못된 패턴
class UserController(
    private val userService: UserService,
) {
    // BaseController 상속 없음
}
```

### 1.2 사용자 조회 표준화 🔴 필수

**사용자 조회는 BaseController의 헬퍼 메서드를 사용합니다.**

```kotlin
// ✅ 올바른 패턴
fun someMethod(authentication: Authentication): ApiResponse<SomeResponse> {
    val user = getCurrentUser(authentication)  // BaseController 메서드 사용
    // 비즈니스 로직
    return ApiResponse.success(result)
}

// ❌ 잘못된 패턴
fun someMethod(authentication: Authentication): ApiResponse<SomeResponse> {
    val user = userService.findByEmail(authentication.name)
        ?: return ApiResponse.error("USER_NOT_FOUND", "사용자를 찾을 수 없습니다.")
}
```

### 1.3 중복 헬퍼 메서드 금지 🔴 필수

**컨트롤러별 개별 getUserByEmail 메서드는 금지됩니다.**

```kotlin
// ❌ 삭제해야 할 패턴
private fun getUserByEmail(email: String) =
    userService.findByEmail(email) ?: throw BusinessException(ErrorCode.USER_NOT_FOUND)

// ✅ BaseController 사용
val user = getUserByEmail(email)  // 상속받은 메서드 사용
```

---

## 📤 2. 응답 형식 표준화

### 2.1 기본 응답 타입 🔴 필수

**모든 API는 ApiResponse<T> 직접 반환을 사용합니다.**

```kotlin
// ✅ 올바른 패턴
fun createUser(@RequestBody request: CreateUserRequest): ApiResponse<UserResponse> {
    val result = userService.createUser(request)
    return ApiResponse.success(result)
}

// ❌ 잘못된 패턴 - ResponseEntity 래핑 금지
fun createUser(@RequestBody request: CreateUserRequest): ResponseEntity<ApiResponse<UserResponse>> {
    return ResponseEntity.ok(ApiResponse.success(result))
}
```

### 2.2 페이징 응답 표준화 🔴 필수

**페이징이 필요한 API는 PagedApiResponse를 사용합니다.**

```kotlin
// ✅ 올바른 패턴
fun getUsers(pageable: Pageable): PagedApiResponse<UserResponse> {
    val page = userService.getUsers(pageable)
    val pagination = PaginationInfo.fromSpringPage(page)
    return PagedApiResponse.success(page.content, pagination)
}

// ❌ 잘못된 패턴 - Spring Page 직접 노출 금지
fun getUsers(pageable: Pageable): ApiResponse<Page<UserResponse>> {
    val page = userService.getUsers(pageable)
    return ApiResponse.success(page)  // Page 직접 노출
}
```

### 2.3 에러 응답 표준화 🔴 필수

**에러 처리는 GlobalExceptionHandler에 위임합니다.**

```kotlin
// ✅ 올바른 패턴
fun updateUser(@RequestBody request: UpdateUserRequest): ApiResponse<UserResponse> {
    // 예외 발생 시 GlobalExceptionHandler가 처리
    val result = userService.updateUser(request)
    return ApiResponse.success(result)
}

// ❌ 잘못된 패턴 - 개별 try-catch 금지
fun updateUser(@RequestBody request: UpdateUserRequest): ApiResponse<UserResponse> {
    return try {
        val result = userService.updateUser(request)
        ApiResponse.success(result)
    } catch (e: Exception) {
        ApiResponse.error("ERROR", e.message ?: "오류")
    }
}
```

---

## 🔐 3. 권한 표현식 표준화

### 3.1 hasPermission 방식 통일 🔴 필수

**권한 검증은 hasPermission 패턴으로 통일합니다.**

```kotlin
// ✅ 올바른 패턴
@PreAuthorize("hasPermission(#groupId, 'GROUP', 'GROUP_MANAGE')")
@PreAuthorize("hasPermission(#channelId, 'CHANNEL', 'POST_WRITE')")
@PreAuthorize("hasPermission(#postId, 'POST', 'POST_READ')")

// ❌ 잘못된 패턴 - 혼재 방식 금지
@PreAuthorize("@security.hasGroupPerm(#groupId, 'CHANNEL_READ')")  // 커스텀 헬퍼 금지
```

### 3.2 개인 데이터 접근 권한 🟡 권장

**개인 데이터나 자신의 작업에는 isAuthenticated() 유지 가능합니다.**

```kotlin
// ✅ 적절한 사용 - 개인 정보 접근
@PreAuthorize("isAuthenticated()")
fun getMyProfile(authentication: Authentication): ApiResponse<UserResponse>

@PreAuthorize("isAuthenticated()")
fun createGroup(@RequestBody request: CreateGroupRequest): ApiResponse<GroupResponse>

// ✅ 리소스별 권한 - 타인의 리소스 접근
@PreAuthorize("hasPermission(#groupId, 'GROUP', 'GROUP_MANAGE')")
fun updateGroup(@PathVariable groupId: Long): ApiResponse<GroupResponse>
```

### 3.3 권한 리소스 타입 매핑 🔴 필수

**리소스별 권한 타입을 일관되게 사용합니다.**

| 리소스 타입 | 사용 패턴 | 권한 예시 |
|-------------|-----------|-----------|
| **GROUP** | `hasPermission(#groupId, 'GROUP', 'PERMISSION')` | `GROUP_MANAGE`, `ADMIN_MANAGE`, `CHANNEL_READ` |
| **CHANNEL** | `hasPermission(#channelId, 'CHANNEL', 'PERMISSION')` | `CHANNEL_VIEW`, `POST_READ`, `POST_WRITE` |
| **POST** | `hasPermission(#postId, 'POST', 'PERMISSION')` | `POST_READ`, `POST_WRITE`, `POST_DELETE` |

---

## 📊 4. HTTP 상태 코드 표준화

### 4.1 생성 작업 🔴 필수

**모든 POST 엔드포인트는 @ResponseStatus(CREATED)를 명시합니다.**

```kotlin
// ✅ 올바른 패턴
@PostMapping
@ResponseStatus(HttpStatus.CREATED)
fun createUser(@RequestBody request: CreateUserRequest): ApiResponse<UserResponse>

@PostMapping("/{groupId}/join")
@ResponseStatus(HttpStatus.CREATED)
fun joinGroup(@PathVariable groupId: Long): ApiResponse<JoinResponse>
```

### 4.2 삭제 작업 🔴 필수

**모든 DELETE 엔드포인트는 @ResponseStatus(NO_CONTENT)를 명시합니다.**

```kotlin
// ✅ 올바른 패턴
@DeleteMapping("/{id}")
@ResponseStatus(HttpStatus.NO_CONTENT)
fun deleteUser(@PathVariable id: Long): ApiResponse<Unit>
```

### 4.3 수정 작업 🟡 권장

**PUT/PATCH는 기본 200 OK를 사용합니다 (명시적 선언 불필요).**

```kotlin
// ✅ 올바른 패턴
@PutMapping("/{id}")
fun updateUser(@PathVariable id: Long): ApiResponse<UserResponse>  // 200 OK 기본값
```

---

## 📝 5. 어노테이션 순서 표준화

### 5.1 어노테이션 배치 순서 🟡 권장

**일관된 어노테이션 순서를 유지합니다.**

```kotlin
// ✅ 권장 순서
@PostMapping("/path")
@PreAuthorize("hasPermission(...)")
@ResponseStatus(HttpStatus.CREATED)
@Operation(summary = "...", description = "...")
@ApiResponses(...)
fun methodName(): ApiResponse<T>
```

### 5.2 Swagger 문서화 🟡 권장

**주요 API에는 Swagger 어노테이션을 추가합니다.**

```kotlin
// ✅ 문서화된 패턴
@PostMapping
@PreAuthorize("isAuthenticated()")
@ResponseStatus(HttpStatus.CREATED)
@Operation(summary = "사용자 생성", description = "새로운 사용자를 생성합니다")
@ApiResponses(value = [
    SwaggerApiResponse(responseCode = "201", description = "생성 성공"),
    SwaggerApiResponse(responseCode = "400", description = "잘못된 요청"),
])
fun createUser(@RequestBody request: CreateUserRequest): ApiResponse<UserResponse>
```

---

## 🎯 6. 신규 API 개발 체크리스트

### 개발 전 체크 ✅

- [ ] BaseController 상속 확인
- [ ] 응답 타입 결정 (ApiResponse vs PagedApiResponse)
- [ ] 권한 수준 분석 (개인 vs 리소스별)
- [ ] HTTP 메서드별 상태 코드 확인

### 개발 중 체크 ✅

- [ ] getCurrentUser() 또는 getUserByEmail() 사용
- [ ] try-catch 제거하고 예외 throw 방식 사용
- [ ] hasPermission 패턴으로 권한 설정
- [ ] @ResponseStatus 어노테이션 추가

### 개발 후 체크 ✅

- [ ] 중복된 헬퍼 메서드 제거
- [ ] ResponseEntity 래핑 제거
- [ ] GlobalExceptionHandler 동작 확인
- [ ] Swagger 문서 생성 확인

---

## 🚨 7. 금지 패턴 목록

### 7.1 절대 사용 금지 🔴

```kotlin
// ❌ ResponseEntity 래핑
fun method(): ResponseEntity<ApiResponse<T>>

// ❌ 개별 try-catch
return try { ... } catch (e: Exception) { ... }

// ❌ 중복 헬퍼 메서드
private fun getUserByEmail(email: String)

// ❌ Spring Page 직접 노출
fun method(): ApiResponse<Page<T>>

// ❌ 커스텀 권한 헬퍼
@PreAuthorize("@security.hasGroupPerm(...)")
```

### 7.2 권장하지 않음 🟡

```kotlin
// 🟡 BaseController 미상속 (기존 코드만 허용)
class SomeController(private val userService: UserService)

// 🟡 isAuthenticated() 남용 (개인 데이터 외 사용 지양)
@PreAuthorize("isAuthenticated()") // 리소스별 권한이 더 적절한 경우
```

---

## 📊 8. 코드 리뷰 체크포인트

### 8.1 PR 리뷰 시 필수 확인사항

1. **컨트롤러 구조**
   - [ ] BaseController 상속 여부
   - [ ] 중복 헬퍼 메서드 존재 여부

2. **응답 형식**
   - [ ] ApiResponse/PagedApiResponse 직접 반환
   - [ ] ResponseEntity 래핑 사용 여부

3. **권한 표현식**
   - [ ] hasPermission 패턴 사용
   - [ ] 적절한 권한 수준 설정

4. **HTTP 상태 코드**
   - [ ] POST → @ResponseStatus(CREATED)
   - [ ] DELETE → @ResponseStatus(NO_CONTENT)

### 8.2 자동화 가능한 검증

```bash
# 금지 패턴 검색 스크립트 예시
grep -r "ResponseEntity<ApiResponse" src/  # ResponseEntity 래핑 검색
grep -r "private fun getUserByEmail" src/  # 중복 헬퍼 검색
grep -r "@security.hasGroupPerm" src/     # 구 권한 패턴 검색
```

---

## 📈 9. 마이그레이션 가이드

### 기존 코드 개선 순서

1. **Phase 1**: BaseController 상속 추가
2. **Phase 2**: ResponseEntity 래핑 제거
3. **Phase 3**: try-catch를 GlobalExceptionHandler로 이관
4. **Phase 4**: 권한 표현식 표준화
5. **Phase 5**: HTTP 상태 코드 추가

### 마이그레이션 템플릿

```kotlin
// Before (개선 전)
@RestController
class OldController(private val userService: UserService) {
    @PostMapping
    fun method(authentication: Authentication): ResponseEntity<ApiResponse<T>> {
        return try {
            val user = userService.findByEmail(authentication.name)
                ?: return ResponseEntity.notFound().build()
            ResponseEntity.ok(ApiResponse.success(result))
        } catch (e: Exception) {
            ResponseEntity.status(500).body(ApiResponse.error(...))
        }
    }
}

// After (개선 후)
@RestController
class NewController(
    userService: UserService
) : BaseController(userService) {
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasPermission(#resourceId, 'RESOURCE', 'PERMISSION')")
    fun method(authentication: Authentication): ApiResponse<T> {
        val user = getCurrentUser(authentication)
        return ApiResponse.success(result)
    }
}
```

---

## 🔄 10. 지속적 개선

### 10.1 정기 점검 항목

- **월 1회**: 새로운 컨트롤러의 패턴 준수도 검토
- **분기 1회**: 금지 패턴 사용 현황 전체 스캔
- **반기 1회**: 새로운 표준화 패턴 도입 검토

### 10.2 피드백 및 개선

본 체크리스트는 개발팀의 피드백을 반영하여 지속적으로 개선됩니다.

**현재 버전**: v1.0 (2025-09-27)
**다음 검토 예정**: 2025-12-27

---

*이 체크리스트를 준수함으로써 API의 일관성을 유지하고, 코드 품질과 유지보수성을 향상시킬 수 있습니다.*