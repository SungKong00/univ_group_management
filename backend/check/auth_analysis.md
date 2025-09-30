# 1단계: 인증(Authentication) 코드 상세 분석

이 문서는 프로젝트의 인증(Authentication) 기능, 특히 Google OAuth2를 이용한 로그인 및 JWT(JSON Web Token) 기반의 API 인증 흐름을 코드 레벨에서 상세히 분석합니다.

## 분석 대상 핵심 파일

-   **Configuration:** `config/SecurityConfig.kt`
-   **Controller:** `controller/AuthController.kt`
-   **Service:** `service/AuthService.kt`
-   **Security Components:**
    -   `security/JwtTokenProvider.kt`
    -   `security/JwtAuthenticationFilter.kt`
-   **Entity:** `entity/User.kt`

## 전체 인증 흐름도

```
(1. 최초 로그인)
Frontend --(Google ID Token)--> /api/auth/google
    |
    v
AuthController
    |
    v
AuthService.authenticateWithGoogle()
    |  1. Google 토큰 검증
    |  2. 사용자 조회/생성 (UserService)
    |  3. Spring Security Authentication 객체 생성
    v
JwtTokenProvider.generateAccessToken() --(JWT 생성)--> AuthService
    |
    v
Frontend <-- (JWT, 사용자 정보) -- AuthController

--------------------------------------------------------------------

(2. API 요청)
Frontend --(JWT in Header)--> Any Authenticated API
    |
    v
JwtAuthenticationFilter.doFilterInternal()
    |  1. 헤더에서 JWT 추출
    |  2. 토큰 유효성 검증
    v
JwtTokenProvider.validateToken() & .getAuthentication()
    |  1. 서명/만료일 검증
    |  2. 토큰에서 사용자 정보/권한 추출
    |  3. Authentication 객체 재구성
    v
SecurityContextHolder <--(Authentication 저장)-- JwtAuthenticationFilter
    |
    v
Controller (API 실행, @PreAuthorize 등 권한 검사)
```

## 1. 최초 로그인 및 JWT 발급 과정

### 1.1. `SecurityConfig.kt`: 보안 필터 체인 설정

-   **Stateless 설정**: `sessionManagement { it.sessionCreationPolicy(SessionCreationPolicy.STATELESS) }`
    -   세션을 사용하지 않는 '무상태(Stateless)' 인증 방식을 설정합니다. 모든 요청은 헤더에 포함된 JWT 토큰을 통해 독립적으로 인증되어야 합니다.
-   **요청 권한 설정**: `authorizeHttpRequests`
    -   `/api/auth/google`, `/swagger-ui/**` 등 특정 경로는 `permitAll()`로 설정하여 인증 없이 접근을 허용합니다.
    -   나머지 모든 요청은 `anyRequest().authenticated()`로 설정하여 반드시 인증을 거치도록 강제합니다.
-   **커스텀 필터 추가**: `addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter::class.java)`
    -   핵심 설정으로, 모든 요청이 `UsernamePasswordAuthenticationFilter`(폼 로그인 등 처리)에 도달하기 전에 우리가 직접 만든 `JwtAuthenticationFilter`를 먼저 거치도록 합니다. 이 필터가 바로 요청 헤더의 JWT를 검사하는 역할을 합니다.

### 1.2. `AuthController.kt`: 로그인 요청의 진입점

-   `@PostMapping("/google")`: 프론트엔드에서 Google 로그인을 통해 얻은 `googleAuthToken`(ID Token)을 받아 `AuthService`로 전달하는 역할을 합니다.

### 1.3. `AuthService.kt`: 핵심 인증 로직

-   `authenticateWithGoogle(googleAuthToken: String)` 메소드가 주 로직을 담당합니다.
    1.  **Google ID Token 검증**:
        -   `verifyGoogleToken(token)` 메소드는 Google API 클라이언트 라이브러리를 사용하여 토큰의 유효성을 검증합니다.
        -   이때 `application.yml`에 설정된 `app.google.client-id`를 사용하여, 해당 토큰이 우리 애플리케이션에 발급된 것이 맞는지 확인합니다.
        -   검증에 성공하면 토큰의 Payload에서 이메일, 이름, 프로필 사진 URL을 추출하여 `GoogleUserInfo` 객체로 반환합니다.
    2.  **사용자 조회 및 생성**:
        -   `userService.findOrCreateUser(googleUser)`를 호출합니다.
        -   `UserRepository`를 통해 DB에서 해당 이메일을 가진 사용자를 조회합니다.
        -   사용자가 존재하지 않으면, `GoogleUserInfo`의 정보를 바탕으로 새로운 `User` 엔티티를 생성하여 DB에 저장합니다. 이때 `profileCompleted` 필드는 `false`로 초기화됩니다.
    3.  **Spring Security `Authentication` 객체 생성**:
        -   JWT를 발급하기 위해, 먼저 Spring Security가 이해할 수 있는 `Authentication` 객체를 만듭니다.
        -   `UsernamePasswordAuthenticationToken(user.email, null, authorities)`:
            -   `principal`: 사용자를 식별하는 주요 정보로 `user.email`을 사용합니다.
            -   `credentials`: 비밀번호는 사용하지 않으므로 `null`입니다.
            -   `authorities`: 사용자의 권한 목록으로, `user.globalRole` (e.g., `ROLE_STUDENT`)을 설정합니다.
    4.  **JWT 발급 요청**:
        -   생성된 `Authentication` 객체를 `jwtTokenProvider.generateAccessToken()`에 전달하여 최종적으로 JWT를 발급받습니다.
    5.  **응답 생성**:
        -   발급된 JWT, 사용자 정보, 그리고 최초 로그인 여부를 나타내는 `firstLogin`(`!user.profileCompleted`) 값을 `LoginResponse`에 담아 컨트롤러로 반환합니다.

### 1.4. `User.kt`: 사용자 데이터 모델

-   `profileCompleted` 필드는 사용자가 온보딩(추가 정보 입력)을 완료했는지 여부를 나타내는 중요한 상태 값입니다. `AuthService`는 이 값을 보고 `firstLogin` 여부를 판단하여 프론트엔드에 알려줍니다.
-   `globalRole` 필드는 사용자의 전역 역할을 정의하며, 이 값은 JWT의 `auth` 클레임에 포함되어 API 접근 제어에 사용됩니다.

## 2. JWT를 이용한 API 인증 과정

프론트엔드는 로그인 시 발급받은 JWT를 로컬에 저장해두고, 이후 서버에 API를 요청할 때마다 HTTP `Authorization` 헤더에 담아 보냅니다. (형식: `Bearer <JWT>`)

### 2.1. `JwtAuthenticationFilter.kt`: 요청 가로채기 및 토큰 검증

-   `SecurityConfig`에 등록된 이 필터는 서버로 들어오는 모든 요청을 가로챕니다.
-   `doFilterInternal` 메소드 로직:
    1.  **JWT 추출**: `getJwtFromRequest` 메소드가 `Authorization` 헤더에서 "Bearer " 접두사를 제거하고 순수한 토큰 문자열을 추출합니다.
    2.  **유효성 검증**: `jwtTokenProvider.validateToken(jwt)`를 호출하여 토큰이 유효한지(서명, 만료일 등) 확인합니다.
    3.  **인증 정보 생성**: 토큰이 유효하면, `jwtTokenProvider.getAuthentication(jwt)`를 호출하여 토큰 내부의 정보(subject, auth 클레임)를 바탕으로 `Authentication` 객체를 재구성합니다.
    4.  **SecurityContext에 저장**: `SecurityContextHolder.getContext().authentication = authentication;`
        -   **가장 핵심적인 부분**입니다. 재구성된 `Authentication` 객체를 `SecurityContextHolder`에 저장합니다.
        -   이 작업이 완료되면, 해당 요청을 처리하는 스레드 내내 Spring Security는 이 사용자가 "인증된 상태"라고 인식하게 됩니다.

### 2.2. `JwtTokenProvider.kt`: JWT 생성, 검증 및 정보 추출

-   **`init()`**: `@PostConstruct`를 통해 컴포넌트가 초기화될 때 `jwt.secret` 설정값을 바이트 배열로 변환하여 HMAC-SHA 키를 미리 생성해둡니다.
-   **`generateAccessToken()`**:
    -   `Authentication` 객체에서 사용자 이름(`authentication.name`)을 `subject`으로, 권한(`authorities`)을 `auth`라는 커스텀 클레임으로 추출합니다.
    -   `Jwts.builder()`를 사용하여 클레임을 설정하고, 만료 시간을 지정한 뒤, `signWith()` 메소드로 생성해둔 키를 사용해 서명합니다.
-   **`validateToken()`**:
    -   `Jwts.parser()`를 사용하여 토큰을 파싱합니다. 이때 `verifyWith(key)`를 통해 서명을 검증합니다.
    -   서명 불일치, 만료, 형식 오류 등 어떤 예외(`JwtException`, `IllegalArgumentException`)라도 발생하면 `false`를 반환하여 토큰이 유효하지 않음을 알립니다.
-   **`getAuthentication()`**:
    -   `validateToken()`이 성공한 후에 호출됩니다.
    -   토큰을 파싱하여 `subject`에서 사용자 이메일을, `auth` 클레임에서 권한 문자열을 추출합니다.
    -   추출된 정보로 `UsernamePasswordAuthenticationToken`을 다시 만들어 반환합니다. 이 객체가 `SecurityContext`에 저장될 최종 인증 정보입니다.

## 결론

-   **로그인**: Google ID Token을 검증하여 사용자를 식별하고, 서버가 직접 서명한 **JWT Access Token**을 발급하는 과정입니다.
-   **API 인증**: 서버로 들어오는 모든 요청을 필터에서 가로채, 요청 헤더의 JWT를 검증하고, 검증이 성공하면 토큰에 담긴 정보를 바탕으로 `SecurityContext`에 "누가, 어떤 권한으로" 요청했는지를 등록하는 과정입니다.
-   이러한 구조를 통해 매번 DB 조회 없이도 빠르고 안전하게 API 요청자를 인증하고, `@PreAuthorize` 같은 선언적 방식으로 권한을 검사할 수 있게 됩니다.
