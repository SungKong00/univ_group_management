# SYNTHESIZED_CONTEXT.MD

## 1. 작업 목표 및 제약 조건

- **핵심 목표**: 기존의 모든 로그인/회원가입 API를 제거하고, Google OAuth2를 통한 소셜 로그인 기능만 남겨 재구현합니다.
- **성공 기준**:
    - `POST /api/auth/google` 엔드포인트가 Google 인증 토큰을 받아 서비스 전용 JWT를 발급합니다.
    - 기존에 존재하던 `POST /auth/signup` 등 다른 모든 인증 관련 API는 완전히 삭제되어야 합니다.
- **주요 제약 조건**:
    - 최종 인증 방식은 백엔드가 발급한 JWT(Access Token)를 `Authorization: Bearer <JWT>` 헤더에 담아 전송하는 것입니다.
    - 모든 API 응답은 `{ success, data, error }` 구조의 표준 JSON 형식를 따라야 합니다.

## 2. 아키텍처 및 개발 원칙

- **3-Layer Architecture**: `Controller` → `Service` → `Repository`의 단방향 데이터 흐름을 엄격히 준수해야 합니다.
    - **Controller**: HTTP 요청/응답 및 DTO 유효성 검증만 담당합니다.
    - **Service**: 모든 비즈니스 로직, 트랜잭션(`@Transactional`), DTO-Entity 변환을 책임집니다.
    - **Repository**: 데이터베이스 영속성만 관리합니다.
- **인증 흐름 (Authentication Flow)**:
    1.  클라이언트(Flutter)가 Google Sign-In을 통해 **Google Auth Token**을 얻습니다.
    2.  이 토큰을 백엔드 `POST /api/auth/google` API로 전송합니다.
    3.  백엔드는 Google 서버에 토큰 유효성을 검증합니다.
    4.  유효한 토큰이면, 이메일로 DB에서 사용자를 조회하거나 신규 사용자를 생성합니다.
    5.  백엔드는 서비스 전용 **JWT Access Token**을 생성하여 클라이언트에 반환합니다.
- **예외 처리**: `@RestControllerAdvice`를 사용하여 전역 예외를 처리합니다. 예측 가능한 비즈니스 오류(예: 유효하지 않은 토큰)는 `BusinessException`과 `ErrorCode` Enum을 사용하여 표준 에러 JSON 형식으로 응답해야 합니다.

## 3. 구현 가이드 및 핵심 파일

### **Step 1: Security Configuration (`SecurityConfig.kt`)**

- 기존의 `formLogin`, `basicAuth` 등 모든 인증 방식을 비활성화합니다.
- `POST /api/auth/google` 엔드포인트는 인증 없이 접근할 수 있도록 `permitAll()`로 설정합니다.
- 그 외 모든 API(`/**`)는 백엔드가 발급한 JWT를 통해서만 접근 가능하도록 설정합니다.
- CORS 설정을 확인하고 필요한 경우 프론트엔드 주소를 허용합니다.

### **Step 2: Controller (`AuthController.kt`)**

- 기존의 로그인, 회원가입 관련 엔드포인트를 모두 삭제합니다.
- 아래 명세에 따라 `googleLogin` API를 구현합니다.
    - **Endpoint**: `POST /api/auth/google`
    - **Request Body**: `{ "googleAuthToken": "..." }`
    - **Success Response**: `{ "success": true, "data": { "accessToken": "..." }, "error": null }`
    - **Failure Response**: `{ "success": false, "data": null, "error": { "code": "AUTH_ERROR", "message": "Invalid token." } }`

### **Step 3: Service (`AuthService.kt`, `UserService.kt`)**

- **`AuthService.googleLogin(googleAuthToken)`**:
    1.  Google 토큰을 검증하는 로직을 구현합니다. (Google API Client Library 또는 `RestTemplate` 사용)
    2.  검증 후 얻은 사용자 정보(이메일, 이름 등)를 `UserService`로 전달합니다.
    3.  `UserService`로부터 받은 `User` 엔티티 정보를 바탕으로 `JwtProvider`를 사용해 서비스 JWT를 생성하고 반환합니다.
- **`UserService.findOrCreateUser(googleUserInfo)`**:
    1.  Google로부터 받은 이메일로 `UserRepository.findByEmail()`을 호출하여 사용자를 조회합니다.
    2.  **사용자가 존재하면**, 해당 `User` 엔티티를 반환합니다.
    3.  **사용자가 존재하지 않으면**, 새로운 `User` 엔티티를 생성하여 DB에 저장(`save`)하고 반환합니다.
        - `email`, `name`, `profile_image_url` 등은 Google 정보로 채웁니다.
        - `user_role`은 `STUDENT`로, `status`는 `ACTIVE`로 기본 설정합니다.

### **Step 4: 관련 엔티티 및 유틸리티**

- **`User.kt` (Entity)**: Google 로그인으로 얻은 정보를 담을 수 있도록 필드를 확인합니다. (`email`, `name`, `user_role`, `status` 등)
- **`UserRepository.kt`**: `fun findByEmail(email: String): User?` 메서드가 정의되어 있는지 확인합니다.
- **`JwtProvider.kt`**: 사용자 ID와 역할을 받아 JWT를 생성하는 유틸리티 클래스를 활용합니다.

## 4. 위험 요소 및 엣지 케이스

- **유효하지 않은 Google 토큰**: 클라이언트가 만료되었거나 위조된 토큰을 보낼 경우, `401 Unauthorized` 에러를 표준 응답 형식에 맞춰 반환해야 합니다.
- **Google API 통신 실패**: Google의 토큰 검증 API가 응답하지 않거나 에러를 반환하는 경우, `500 Internal Server Error` 또는 적절한 `BusinessException`으로 처리해야 합니다.
- **신규/기존 사용자 처리**: 사용자를 조회하고 없을 때 생성하는 로직은 원자적(atomic)으로 동작해야 합니다. `@Transactional` 어노테이션을 `UserService`의 메서드에 적용하여 데이터 일관성을 보장하세요.

## 5. Do's and Don'ts

- **DO**: `SecurityConfig`에서 `http.authorizeHttpRequests`를 사용하여 엔드포인트별 접근 제어를 명확히 설정하세요.
- **DO**: DTO를 사용하여 `Controller`와 `Service` 간 데이터를 전달하고, API 응답 시 절대 Entity를 직접 노출하지 마세요.
- **DON'T**: `Controller`에 비즈니스 로직(토큰 검증, DB 조회 등)을 포함시키지 마세요. 모든 로직은 `Service` 계층에 위임해야 합니다.
- **DON'T**: Google OAuth2와 관련 없는 기존의 `PasswordEncoder`, `UserDetailsService` 구현체 등은 이번 작업에서 모두 삭제하거나 주석 처리하여 영향을 주지 않도록 해야 합니다.
