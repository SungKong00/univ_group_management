# System Architecture Overview

**⚠️ 현재 구현 상태**: 계획된 기능 중 일부만 구현되었습니다. 이 문서는 실제 구현 상태를 반영하여 업데이트되었습니다.

이 문서는 프로젝트의 실제 구현된 아키텍처와 계획된 아키텍처를 포함합니다.

---

## 1. General Architecture & Deployment

- **Tech Stack**:
    - **Frontend**: Flutter (targeting Web as the primary platform).
    - **Backend**: Spring Boot with Kotlin.
    - **Database**: RDBMS (planned for AWS RDS).

- **Deployment Architecture (AWS)**:
    - A minimal setup using **EC2 (Server) + RDS (DB) + S3 (Build Storage)**.
    - **Unified Deployment**: The Flutter web build output (HTML, JS) is included in the Spring Boot project's `src/main/resources/static` directory. The entire application is deployed as a single JAR file, with Spring Boot handling both API serving and web hosting.

- **CI/CD (GitHub Actions)**:
    - **Trigger**: Merging code from the `develop` branch into the `main` branch triggers an automatic deployment to production.
    - **Pipeline**: 
        1. Build and test the project.
        2. Upload the executable JAR to AWS S3.
        3. Connect to AWS EC2, pull the new JAR from S3, and run the server.
    - **Secrets Management**: All sensitive information (DB passwords, JWT keys) is stored in GitHub Actions Secrets and used to dynamically generate `application-prod.yml` during the CI/CD process.

---

## 2. Backend Architecture (Spring Boot)

### 2.1. Code-Level 3-Layer Architecture

The backend follows a strict, single-direction data flow (`Controller` → `Service` → `Repository`).

- **`Controller`**: Handles HTTP requests/responses and performs first-pass syntactic validation on DTOs (`@Valid`). It knows nothing about Entities.
- **`Service`**: Contains all business logic, manages transactions (`@Transactional`), and is solely responsible for converting between DTOs and Entities. It performs second-pass semantic validation (business rules).
- **`Repository`**: Manages data persistence (CRUD) by communicating directly with the database. It knows nothing about DTOs.

### 2.2. API Design Principles

- **Standard Response Format**: All API responses are wrapped in a standard JSON envelope:
  ```json
  {
      "success": boolean,
      "data": { ... } | [ ... ] | null,
      "error": { "code": "...", "message": "..." } | null
  }
  ```
  
  **✅ 프론트엔드 연동 완료**: 프론트엔드 AuthService가 이 표준 ApiResponse 래퍼 형태를 정확히 파싱하도록 수정 완료됨. Google 로그인 API의 응답을 LoginResponse 객체로 직접 변환하여 처리하며, AuthRepository, AuthProvider 전체 레이어에서 타입 일치성이 확보됨.
  
- **HTTP Status Codes**: Standard codes are used (`200 OK`, `201 Created`, `204 No Content`, `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`, `404 Not Found`, `500 Internal Server Error`).

### 2.3. Authentication & Authorization (부분 구현됨)

**✅ 구현된 부분:**
- **Authentication Flow**: 
    - Google Sign-In을 통한 인증이 구현됨
    1. Frontend gets a **Google Auth Token** via Google Sign-In.
    2. This token is sent to the backend (`POST /api/auth/google`).
    3. Backend validates the token with Google, finds or creates a user in the DB.
    4. Backend generates and returns a service-specific **JWT Access Token**.
    5. Frontend sends this JWT in the `Authorization: Bearer <JWT>` header for all subsequent requests.

**추가 구현됨:**
- **Authorization Strategy** (기본):
    - Spring Method Security (@PreAuthorize)
    - Custom `PermissionEvaluator` 등록 (GroupPermissionEvaluator)
    - Helper: `@security.hasGroupPerm(#groupId, '<PERMISSION>')`
    - 전역 역할(GlobalRole)과 그룹 권한(DB 평가) 분리

**여전히 미구현:**
- 그룹/멤버/역할 API 실제 비즈니스 로직 및 컨트롤러 어노테이션 적용 전면화

### 2.4. Exception Handling & Logging

- **Global Exception Handling**: A central `@RestControllerAdvice` class catches all exceptions. Custom `BusinessException` (containing an `ErrorCode` enum) is used for predictable errors, which are translated into the standard error JSON format.
- **Logging Strategy (SLF4J + Logback)**:
    - **Levels**: `DEBUG` for local/dev, `INFO` for production.
    - **Content**: `INFO` for key events (server start), `WARN` for potential issues, `ERROR` for all exceptions (with stack trace for 500 errors).
    - **Rotation**: Logs are rotated daily and kept for a maximum of 30 days.

### 2.5. Testing Strategy

- **Pyramid Focus**: The strategy prioritizes **Integration Tests** over Unit Tests. E2E tests are out of scope for MVP.
- **Environment**: Tests run against an **H2 in-memory database** for speed and isolation.
- **Structure**: 
    - An `IntegrationTest` base class provides common setup (`@SpringBootTest`).
    - A `DatabaseCleanup` component ensures each test runs on a clean DB (`@AfterEach`).
    - An `AcceptanceTest` helper class abstracts away `MockMvc` complexity, allowing tests to be written in a business-readable format (e.g., `acceptanceTest.createGroup(...)`).

---

## 3. Frontend Architecture (Flutter)

### 3.1. 현재 구현된 상태 ✅

- **State Management**: **Provider + GetIt** 조합으로 구현됨 (Riverpod 대신)
    - `Provider`: 상태 관리 (AuthProvider)
    - `GetIt`: 의존성 주입 (Singleton/Factory 패턴)
- **Project Structure**: **Clean Architecture** 기반으로 구현됨:
    - `lib/presentation/`: UI (Screens, Widgets, Providers, Themes)
    - `lib/domain/`: Business Logic (Repositories)
    - `lib/data/`: Data Layer (Models, Services, Repository Implementations)
    - `lib/core/`: Core utilities (Network, Storage, Auth, Constants)
    - `lib/injection/`: Dependency Injection setup
- **API Client**: **Dio** with interceptors for automatic JWT token injection
- **Routing**: **MaterialApp** with named routes (go_router는 미사용)
- **Authentication**: Google OAuth2 + JWT 토큰 시스템 완전 구현
- **Storage**: Flutter Secure Storage for token persistence
- **UI Design System**: AppTheme class with centralized color/style definitions

### 3.2. 기술 스택 상세

**의존성 (pubspec.yaml):**
```yaml
# HTTP & 네트워킹
dio: ^5.3.2

# 상태 관리 & DI
provider: ^6.0.5
get_it: ^7.6.4

# 인증 & 저장소
google_sign_in: ^6.2.1
shared_preferences: ^2.2.2
flutter_secure_storage: ^9.0.0

# 유틸리티
json_annotation: ^4.8.1
equatable: ^2.0.5
webview_flutter: ^4.7.0
```

### 3.3. 인증 플로우 구현 상태

**✅ 구현 완료:**
1. Google Sign-In을 통한 토큰 획득 (ID Token + Access Token)
2. 백엔드 인증 API 호출 (`/api/auth/google`)
3. JWT 토큰 수신 및 로컬 저장
4. HTTP 요청 시 자동 토큰 주입
5. 인증 상태 기반 화면 라우팅

**📱 구현된 화면들:**
- SplashScreen: 초기 인증 상태 확인
- LoginScreen: Google OAuth 로그인
- RegisterScreen: 회원가입 (미완성)
- HomeScreen: 인증 후 메인 화면
- WebViewScreen: 웹뷰 표시용

---

## 4. API Endpoint Specifications

**⚠️ 현재 구현 상태**: 대부분의 API가 미구현 상태입니다.

### 4.1. Auth API (완전 구현됨) ✅

**✅ Frontend-Backend 연동 구현:**
| Feature | Endpoint | Auth | Request Body | Success Response (data) |
| --- | --- | --- | --- | --- |
| **Google Login/Sign-up** | `POST /api/auth/google` | None | `{ "googleAuthToken": "...", "googleAccessToken": "..." }` | `{ "accessToken": "...", "user": { id, name, email, globalRole, ... } }` |

**Frontend 구현 상세:**
- `GoogleSignInService`: Google OAuth 토큰 획득
- `AuthService`: 백엔드 API 통신
- `AuthProvider`: 인증 상태 관리
- `TokenStorage`: JWT 토큰 암호화 저장
- `DioClient`: 자동 Authorization 헤더 주입

**❌ 미구현 API:**
- `POST /auth/signup` - 별도 회원가입 (Google 인증으로 자동 처리됨)
- `GET /users/me` - 사용자 정보 조회

### 4.2. Group API (미구현) ❌

**모든 그룹 관련 API가 미구현 상태입니다:**
- `POST /groups` - 그룹 생성
- `GET /groups` - 그룹 목록 조회
- `GET /groups/{groupId}` - 그룹 상세 조회
- `PUT /groups/{groupId}` - 그룹 정보 수정
- `DELETE /groups/{groupId}` - 그룹 삭제

### 4.3. Member & Join API (미구현) ❌

**모든 멤버 관리 API가 미구현 상태입니다:**
- `POST /groups/{groupId}/join` - 그룹 가입 신청
- `GET /groups/{groupId}/join-requests` - 가입 신청 목록
- `PATCH /groups/{groupId}/join-requests/{requestId}` - 가입 신청 처리
- `GET /groups/{groupId}/members` - 그룹 멤버 목록
- `DELETE /groups/{groupId}/members/{userId}` - 멤버 추방

### 4.4. Role API (미구현) ❌

**모든 역할 관리 API가 미구현 상태입니다:**
- `POST /groups/{groupId}/roles` - 커스텀 역할 생성
- `GET /groups/{groupId}/roles` - 그룹 역할 목록
- `PUT /groups/{groupId}/members/{userId}/role` - 멤버 역할 변경

### 4.5. Recruitment API (미구현) ❌

**모든 모집 공고 API가 미구현 상태입니다:**
- `POST /recruitments` - 모집 공고 생성
- `GET /recruitments` - 모집 공고 목록
- `GET /recruitments/{postId}` - 모집 공고 상세
- `PUT /recruitments/{postId}` - 모집 공고 수정
- `DELETE /recruitments/{postId}` - 모집 공고 삭제

### 4.6. Post & Comment API (미구현) ❌

**모든 게시글/댓글 API가 미구현 상태입니다:**
- `POST /channels/{channelId}/posts` - 게시글 작성
- `GET /channels/{channelId}/posts` - 채널 게시글 목록
- `POST /posts/{postId}/comments` - 댓글 작성
- `GET /posts/{postId}/comments` - 게시글 댓글 목록
- `DELETE /comments/{commentId}` - 댓글 삭제
