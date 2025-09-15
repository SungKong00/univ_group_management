# Troubleshooting Guide

이 문서는 프로젝트에서 발생할 수 있는 일반적인 문제들과 해결 방법을 안내합니다.

---

## 1. 인증 관련 문제 해결

### 1.1. Google OAuth 로그인 실패

**증상**: 백엔드에서 Google 토큰 검증에 실패하거나 관련 설정 오류가 발생합니다.

**원인 및 해결방법**:
- **백엔드 `application.yml` 설정 확인**: `spring.security.oauth2.client.registration.google.client-id` 및 `client-secret`이 올바른지 확인합니다.
- **Google Cloud Console 설정**: OAuth 동의 화면, 사용자 인증 정보가 올바르게 설정되었는지 확인합니다.

### 1.2. 백엔드 인증 처리 관련 문제 (NumberFormatException)

**증상**: 백엔드 컨트롤러에서 `authentication.name.toLong()` 호출 시 NumberFormatException이 발생합니다.

**원인**: Spring Security의 JWT 인증에서 `authentication.name`이 사용자 ID(Long)가 아닌 이메일(String)으로 설정되어 있을 때 발생합니다.

**해결방법**:
1.  **이메일 기반 사용자 조회로 변경**:
    ```kotlin
    // 컨트롤러에서 UserService를 주입받아 이메일로 사용자를 조회합니다.
    private fun getUserByEmail(email: String): User {
        return userService.findByEmail(email)
            ?: throw IllegalArgumentException("User not found with email: $email")
    }
    
    // API 메서드 내에서 아래와 같이 사용합니다.
    val user = getUserByEmail(authentication.name) // 이메일로 사용자 조회
    val userId = user.id!!
    ```

2.  **JWT 토큰 설정 확인**: `JwtTokenProvider`에서 토큰의 `subject`가 이메일로 설정되어 있는지 확인합니다.
    ```kotlin
    fun generateAccessToken(user: User): String {
        return Jwts.builder()
            .setSubject(user.email) // ID가 아닌 이메일을 subject로 설정
            // ...
            .compact()
    }
    ```

3.  **타입 안전한 사용자 ID 추출**: 모든 컨트롤러에서 일관성을 유지하기 위해 `BaseController`나 확장 함수를 사용하는 것을 권장합니다.
    ```kotlin
    // 확장 함수 예시
    fun Authentication.getUserId(userService: UserService): Long {
        val user = userService.findByEmail(this.name)
            ?: throw IllegalArgumentException("User not found with email: ${this.name}")
        return user.id ?: throw IllegalStateException("User ID is null")
    }
    ```

---

## 2. Group 권한 시스템 문제

### 2.1. GroupPermission 열거형 확장 이슈

**증상**: 새로운 GroupPermission 추가 시 기존 데이터베이스 값과 충돌하거나 권한 검증이 실패합니다.

**원인**: GroupPermission enum의 순서가 변경되면 데이터베이스에 저장된 ordinal 값이 맞지 않을 수 있습니다.

**해결방법**:
- **안전한 권한 추가**: 새로운 권한은 항상 enum의 맨 끝에 추가하여 기존 ordinal 값의 순서를 유지합니다.
- **DB 마이그레이션**: 만약 순서를 변경해야 한다면, String 기반으로 변환하는 DB 마이그레이션 스크립트를 작성해야 합니다.

### 2.2. 권한 검증 실패 디버깅

**디버깅 단계**:
1.  **로그 레벨 설정**: `application-dev.yml`에서 `com.yourproject.security`와 `org.springframework.security`의 로그 레벨을 `DEBUG`로 설정하여 상세한 권한 검증 과정을 확인합니다.
2.  **권한 확인 로직 디버깅**: `@PreAuthorize`를 사용하는 서비스 메서드 내에서 현재 사용자의 역할과 권한을 직접 로그로 출력하여 확인합니다.
    ```kotlin
    @PreAuthorize("@security.hasGroupPerm(#groupId, 'GROUP_EDIT')")
    fun updateGroup(groupId: Long, request: GroupUpdateRequest): GroupDto {
        logger.debug("Checking GROUP_EDIT permission for group: $groupId")
        // ...
    }
    ```

---

## 3. 빌드 및 실행 문제

### 3.1. Gradle 관련 문제

**증상**: `./gradlew` 실행 시 JDK를 찾지 못하거나 버전 호환성 문제가 발생합니다.

**해결방법**:
- **JDK 17+ 설치**: 프로젝트에 맞는 버전의 JDK(권장: Temurin/OpenJDK 17)가 설치되어 있는지 확인합니다.
- **Gradle 클린 빌드**: 문제가 지속되면 아래 명령어로 캐시를 정리하고 다시 시도합니다.
  ```bash
  ./gradlew clean build -x test
  ```

---

## 4. 문제 해결이 안 될 때

### 4.1. 이슈 보고 전 체크리스트

1.  **로그 수집**: 에러 발생 시점의 상세한 백엔드 로그를 확인합니다.
2.  **재현 단계**: 문제가 발생하는 정확한 API 요청 순서나 조건을 확인합니다.
3.  **환경 정보**: OS, Java 버전, DB 종류 등 실행 환경 정보를 확인합니다.

### 4.2. 추가 리소스

- **Spring Boot 공식 문서**: https://docs.spring.io/spring-boot/docs/current/reference/htmlsingle/
- **Stack Overflow**: spring-boot, kotlin 등 관련 태그로 검색