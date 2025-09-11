# SYNTHESIZED_CONTEXT.MD

## 1. 핵심 목표 및 제약사항

**목표:** JWT(JSON Web Token) 기반의 로그인/회원가입 API를 Spring Boot와 Kotlin을 사용하여 구현합니다.

**성공 기준:**
- **인증 API:** 사용자가 이메일/비밀번호로 인증하고, 유효한 JWT Access Token과 Refresh Token을 발급받을 수 있어야 합니다.
- **보안 설정:** Spring Security를 통해 인증이 필요한 엔드포인트와 공개 엔드포인트를 분리하고, JWT 필터를 올바르게 적용해야 합니다.
- **데이터베이스:** `User` 엔티티를 정의하고 `UserRepository`를 통해 사용자 정보를 관리합니다. 비밀번호는 반드시 BCrypt로 암호화하여 저장합니다.
- **API 규약:** 정의된 `ApiResponse` 형식에 맞춰 성공/실패 응답을 반환해야 합니다.
- **테스트:** 로그인 및 회원가입 기능에 대한 통합 테스트를 작성하고 통과해야 합니다.

## 2. 아키텍처 및 주요 원칙

- **3-Tier 아키텍처:** `Controller` -> `Service` -> `Repository` 계층 구조를 따릅니다.
- **Stateless 인증:** 세션을 사용하지 않고, 모든 요청은 `Authorization: Bearer {JWT}` 헤더를 통해 인증되는 상태 비저장(Stateless) 방식으로 구현합니다.
- **의존성 주입:** Spring의 모든 의존성은 **생성자 주입(Constructor Injection)**을 사용합니다. 필드 주입은 금지됩니다.
- **Kotlin 중심:** `data class`를 DTO와 Entity에 적극 활용하고, Null 안전성(`?`, `!!`, `?:`) 규칙을 준수합니다.

## 3. 구현 가이드라인 및 패턴

### Do (해야 할 것)
- **`BCryptPasswordEncoder` 사용:** 비밀번호 암호화에는 `BCryptPasswordEncoder`를 사용하며, 강도는 `12`로 설정합니다. (`security.md`)
- **`application.yml` 설정:** JWT 시크릿 키, 토큰 만료 시간 등 민감 정보는 `application.yml`에 정의하고, 환경 변수(`\${...}`)를 통해 주입받습니다.
- **표준 응답 형식 준수:** 모든 API 응답은 `ApiResponse` 래퍼 클래스를 사용합니다. (`api-conventions.md`)
- **커스텀 예외 처리:** `UserNotFoundException`, `DuplicateEmailException` 등 비즈니스 로직에 맞는 커스텀 예외를 정의하고 `@RestControllerAdvice`에서 처리합니다.
- **DTO 사용:** Controller 계층에서는 Request/Response에 반드시 DTO(`AuthDto.kt`)를 사용하며, `@Valid` 어노테이션으로 입력값을 검증합니다.

### Don't (하지 말 것)
- **비밀번호 직접 노출 금지:** API 응답에 사용자의 암호화된 비밀번호를 포함해서는 안 됩니다.
- **하드코딩 금지:** JWT 시크릿 키와 같은 중요 값을 소스 코드에 직접 작성하지 마세요.
- **`User` 엔티티 직접 반환 금지:** Controller는 `UserResponse` DTO를 사용해 필요한 정보만 노출해야 합니다.

## 4. 주요 파일 및 모듈

- **`SecurityConfig.kt`**: Spring Security의 핵심 설정 파일. HTTP 요청 권한 설정, CORS, CSRF 비활성화, `JwtAuthenticationFilter` 등록 등을 담당합니다.
- **`JwtTokenProvider.kt`**: JWT 토큰의 생성, 유효성 검증, 클레임 추출 등 토큰 관련 모든 로직을 담당하는 유틸리티 클래스입니다.
- **`JwtAuthenticationFilter.kt`**: 모든 요청을 가로채 `Authorization` 헤더의 JWT 토큰을 검증하고, 유효할 경우 `SecurityContextHolder`에 인증 정보를 설정하는 필터입니다.
- **`AuthController.kt`**: `/api/v1/auth/register`, `/api/v1/auth/login` 엔드포인트를 제공하는 REST 컨트롤러입니다.
- **`AuthService.kt`**: 로그인/회원가입 비즈니스 로직을 처리하는 서비스 클래스입니다. `PasswordEncoder`와 `JwtTokenProvider`를 사용합니다.
- **`User.kt` / `UserRepository.kt`**: 사용자 정보를 담는 JPA 엔티티와 데이터베이스 작업을 위한 Spring Data JPA 리포지토리입니다.
- **`AuthDto.kt`**: `SignUpRequest`, `LoginRequest`, `TokenResponse` 등 인증 관련 데이터 전송 객체(DTO)를 정의합니다.
- **`application.yml`**: 데이터베이스 연결 정보, JWT 시크릿 키 및 만료 시간 등 애플리케이션의 주요 설정을 포함합니다.

## 5. API 흐름 및 명세

### 회원가입
1.  **Request**: `POST /api/v1/auth/register`
    -   Body: `SignUpRequest` (name, email, password)
2.  **Process**:
    -   `AuthService`는 이메일 중복을 확인합니다.
    -   비밀번호를 `BCryptPasswordEncoder`로 암호화합니다.
    -   `UserRepository`를 통해 새로운 `User`를 저장합니다.
3.  **Response**: `201 Created`
    -   Body: `ApiResponse<UserResponse>`

### 로그인
1.  **Request**: `POST /api/v1/auth/login`
    -   Body: `LoginRequest` (email, password)
2.  **Process**:
    -   `AuthService`는 `UserRepository`에서 이메일로 사용자를 찾습니다.
    -   `BCryptPasswordEncoder.matches()`로 비밀번호 일치 여부를 확인합니다.
    -   `JwtTokenProvider`를 호출하여 Access Token과 Refresh Token을 생성합니다.
3.  **Response**: `200 OK`
    -   Body: `ApiResponse<TokenResponse>` (accessToken, refreshToken)

## 6. 테스트 전략

- **통합 테스트 (`@SpringBootTest`)**:
  - **회원가입 성공/실패:** `MockMvc`를 사용하여 `/api/v1/auth/register` API를 호출하고, 성공 시 201 상태 코드와 응답 본문을 검증합니다. 이메일 중복 시 409 Conflict를 검증합니다.
  - **로그인 성공/실패:** 올바른/잘못된 자격증명으로 `/api/v1/auth/login`을 호출하여 200 OK 또는 401 Unauthorized 상태 코드를 검증합니다.
  - **보안 엔드포인트 접근 제어:**
    -   인증 없이 보호된 API 호출 시 401 Unauthorized 응답을 확인합니다.
    -   로그인으로 발급받은 JWT를 `Authorization` 헤더에 포함하여 API 호출 시 200 OK 응답을 확인합니다.

## 7. 위험 요소 및 고려사항

- **JWT 시크릿 키 관리:** 시크릿 키가 유출되면 토큰 위조가 가능하므로, 환경 변수를 통해 안전하게 관리해야 합니다.
- **토큰 탈취:** Refresh Token을 사용하여 Access Token의 유효 기간을 짧게(예: 24시간) 유지하고, 탈취에 대비한 토큰 폐기 전략을 고려해야 합니다. (현재 구현 범위에는 미포함)
- **입력값 검증:** Bean Validation(`@Valid`)을 통해 이메일 형식, 비밀번호 길이 등 기본적인 입력값 검증을 철저히 수행하여 비정상적인 데이터 유입을 막아야 합니다.
