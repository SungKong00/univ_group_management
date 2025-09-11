You are Gemini CLI acting as a Context Synthesizer for a specific task folder.

Goal:
- Read the task goals and constraints from TASK.MD.
- Read the project static context from INPUT_CONTEXT.md.
- Optionally scan referenced code files if explicitly mentioned.
- Produce a tailored, concise SYNTHESIZED_CONTEXT.MD for this task with:
  - Objectives & constraints summary
  - Relevant architecture/principles extracted from static context
  - APIs, modules, and files likely involved
  - Risks, edge cases, and test ideas
  - Clear do/don't for coding style and patterns

Output format:
- A single Markdown document suitable to drop into SYNTHESIZED_CONTEXT.MD


---
# TASK.MD


# TASK

## 작업 목표
- [ ] 목표 요약: (예: JWT 기반 로그인 API 구현)
- [ ] 성공 기준: (예: 통합 테스트 통과, 문서 반영)

## 컨텍스트 요청 (태그, 파일, 영역)
- 태그: (예: auth, jwt, spring-security)
- 관련 소스/디렉토리: (예: backend/src/main/java, frontend/lib)
- 참고 문서: (예: context/security.md, context/api-conventions.md)

## 개발 지시 (Claude Code용)
- SYNTHESIZED_CONTEXT.MD를 먼저 읽고 구현 순서를 제안하세요.
- 생성/수정 파일 목록을 제안한 뒤 합의된 순서대로 구현하세요.
- 모든 변경은 본 작업 폴더의 '작업 로그'에 요약을 남기세요.
- 실패/에러는 로그와 함께 Codex 호출을 요청하세요.

## 작업 로그
- YYYY-MM-DD HH:MM [Claude] 초기 세팅 완료.
- YYYY-MM-DD HH:MM [Codex] 에러 원인 분석 및 수정 제안.

## 변경 사항 요약
- 생성/수정 파일:
  - backend/src/main/java/.../AuthController.java (신규)
  - backend/src/main/java/.../SecurityConfig.java (수정)
- 핵심 로직:
  - 비밀번호 인코딩, JWT 발급/검증, 예외 처리

## 컨텍스트 업데이트 요청
- context/security.md에 PasswordEncoder Bean 규칙 추가 요청
- metadata.json에 auth 관련 문서 인덱싱 태그 추가 요청



---
# PROJECT CONTEXT


# Input Context


---
## File: context/architecture-overview.md

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


---
## File: context/database-design.md

# Database Design (Entity Relationship Diagram)

This document outlines the current database schema implementation status. 

**⚠️ 현재 구현 상태**: User 전역 역할 리팩터링 및 그룹 권한 스캐폴딩이 반영되었습니다.

## High-Level Summary

현재 구현된 도메인:
1.  **Users**: 기본 사용자 관리 (Google OAuth2 인증, GlobalRole)
2.  **Group Auth Scaffolding**: 그룹/멤버/그룹역할/권한 카탈로그 스키마 기본 골격

계획된 도메인 (부분/미구현):
3.  **Groups & Content**: 그룹 상세, 채널, 게시글, 댓글 관리 (API/로직 미구현)
4.  **Recruitment & System**: 모집 공고, 태그, 알림 시스템

---

## 1. Users (현재 구현됨)

### User (사용자) - ✅ 구현됨
**실제 구현된 스키마:**
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 사용자 고유 번호 |
| `email` | VARCHAR(100) | Not Null, **Unique** | 이메일 주소 (Google OAuth2 로그인) |
| `name` | VARCHAR(50) | Not Null | 실명 |
| `nickname` | VARCHAR(30) | | 사용자 닉네임 |
| `profile_image_url` | VARCHAR(500) | | 프로필 이미지 URL |
| `bio` | VARCHAR(500) | | 자기소개 |
| `password_hash` | VARCHAR(255) | Not Null | 패스워드 해시 (현재 사용되지 않음) |
| `global_role` | ENUM | Not Null | 전역 역할 (STUDENT, PROFESSOR, ADMIN) |
| `profile_completed` | BOOLEAN | Not Null | 프로필 완성 여부 (기본값: false) |
| `email_verified` | BOOLEAN | Not Null | 이메일 인증 여부 (기본값: false) |
| `is_active` | BOOLEAN | Not Null | 계정 활성화 상태 |
| `created_at` | DATETIME | Not Null | 생성 일시 |
| `updated_at` | DATETIME | Not Null | 수정 일시 |

**최근 업데이트 (2025-09-11):**
- ✅ nickname, profile_image_url, bio 필드 추가
- ✅ profile_completed 필드 추가 (회원가입 플로우 제어용)
- ✅ email_verified 필드 추가 (향후 이메일 인증 기능용)
- password_hash 필드 존재 (Google OAuth2만 사용하므로 실제로는 사용되지 않음)

---

## 2. Group Auth Scaffolding (부분 구현)

### Group (그룹) - ✅ 스키마 추가
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 그룹 고유 번호 |
| `name` | VARCHAR(100) | Not Null, **Unique** | 그룹 이름 |

### GroupRole (그룹 역할) - ✅ 스키마 추가
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 역할 고유 번호 |
| `group_id` | BIGINT | Not Null, **FK** (Group.id) | 소속 그룹 |
| `name` | VARCHAR(50) | Not Null | 역할 이름 (OWNER/ADVISOR/MEMBER/커스텀) |
| `is_system_role` | BOOLEAN | Not Null | 시스템 역할 여부 |

### GroupRolePermission (역할-권한 집합) - ✅ 스키마 추가
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `group_role_id` | BIGINT | **FK** (GroupRole.id) | 그룹 역할 ID |
| `permission` | VARCHAR(50) | Not Null | 권한 키 (Enum: GROUP_MANAGE 등) |

### GroupMember (그룹 멤버) - ✅ 스키마 추가
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 멤버 관계 고유 번호 |
| `group_id` | BIGINT | Not Null, **FK** (Group.id) | 그룹 ID |
| `user_id` | BIGINT | Not Null, **FK** (User.id) | 사용자 ID |
| `role_id` | BIGINT | Not Null, **FK** (GroupRole.id) | 그룹 내 역할 ID |
| `joined_at` | DATETIME | Not Null | 가입 일시 |

---

### JoinRequest (가입 신청) - ❌ 미구현
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 가입 신청 고유 번호 |
| `user_id` | BIGINT | Not Null, **FK** (User.id) | 신청한 사용자 ID |
| `group_id` | BIGINT | Not Null, **FK** (Group.id) | 신청한 그룹 ID |
| `status` | VARCHAR(20) | Not Null | 상태 ('PENDING', 'APPROVED', 'REJECTED') |
| `created_at` | DATETIME | Not Null | 신청 일시 |

---

## 3. Groups & Content (미구현) ❌

**⚠️ 주의**: 아래 엔티티들은 모두 미구현 상태입니다.

### Group (그룹) - ❌ 미구현
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 그룹 고유 번호 |
| `parent_id` | BIGINT | **FK** (self-reference) | 상위 그룹 ID (계층 구조) |
| `name` | VARCHAR(100) | Not Null | 그룹 이름 |
| `description` | TEXT | | 그룹 소개 |
| `created_at` | DATETIME | Not Null | 생성 일시 |

### Channel (채널) - ❌ 미구현
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 채널 고유 번호 |
| `group_id` | BIGINT | Not Null, **FK** (Group.id) | 채널이 속한 그룹 ID |
| `name` | VARCHAR(100) | Not Null | 채널 이름 (예: 공지사항) |

### Post (게시글) - ❌ 미구현
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 게시글 고유 번호 |
| `channel_id` | BIGINT | Not Null, **FK** (Channel.id) | 게시글이 등록된 채널 ID |
| `author_id` | BIGINT | Not Null, **FK** (User.id) | 작성자 ID |
| `title` | VARCHAR(255) | Not Null | 제목 |
| `content` | TEXT | Not Null | 내용 |
| `created_at` | DATETIME | Not Null | 생성 일시 |

### Comment (댓글) - ❌ 미구현
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 댓글 고유 번호 |
| `post_id` | BIGINT | Not Null, **FK** (Post.id) | 부모 게시글 ID |
| `author_id` | BIGINT | Not Null, **FK** (User.id) | 작성자 ID |
| `parent_comment_id` | BIGINT | **FK** (self-reference) | 부모 댓글 ID (대댓글 구조) |
| `content` | TEXT | Not Null | 내용 |
| `created_at` | DATETIME | Not Null | 생성 일시 |

---

## 4. Recruitment & System (미구현) ❌

**⚠️ 주의**: 아래 엔티티들은 모두 미구현 상태입니다.

### RecruitmentPost (모집 공고) - ❌ 미구현
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 모집 공고 고유 번호 |
| `group_id` | BIGINT | Not Null, **FK** (Group.id) | 공고를 게시한 그룹 ID |
| `title` | VARCHAR(255) | Not Null | 제목 |
| `content` | TEXT | Not Null | 본문 |
| `start_date` | DATE | Not Null | 모집 시작일 |
| `end_date` | DATE | Not Null | 모집 종료일 |
| `status` | VARCHAR(20) | Not Null | 상태 ('ACTIVE', 'CLOSED') |

### Tag (태그) - ❌ 미구현
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 태그 고유 번호 |
| `name` | VARCHAR(50) | Not Null, **Unique** | 태그 이름 (예: #스터디) |

### PostTag (공고-태그 매핑) - ❌ 미구현
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `post_id` | BIGINT | **PK**, **FK** (RecruitmentPost.id) | 모집 공고 ID |
| `tag_id` | BIGINT | **PK**, **FK** (Tag.id) | 태그 ID |

### Notification (알림) - ❌ 미구현
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 알림 고유 번호 |
| `recipient_id` | BIGINT | Not Null, **FK** (User.id) | 알림을 받는 사용자 ID |
| `type` | VARCHAR(50) | Not Null | 알림 종류 (예: `JOIN_APPROVED`) |
| `content` | VARCHAR(255) | Not Null | 알림 내용 |
| `is_read` | BOOLEAN | Not Null | 읽음 여부 |
| `created_at` | DATETIME | Not Null | 생성 일시 |


---
## File: context/feature-specifications.md

# Application Feature Specifications

**⚠️ 현재 구현 상태**: 대부분의 기능이 미구현 상태입니다. 이 문서는 실제 구현 상태를 반영하여 업데이트되었습니다.

이 문서는 프로젝트의 계획된 기능 명세와 현재 구현 상태를 포함합니다.

---

## 1. Sign-up / Login (후햄드 구현 완료) ✅

### 1.1. Frontend + Backend 완전 구현됨

**✅ 완료된 기능:**
- **Google OAuth2 인증**: ID Token과 Access Token 모두 지원
- **사용자 자동 생성**: 백엔드에서 사용자 자동 생성/조회
- **JWT 기반 인증 시스템**: 완전한 end-to-end 구현
- **토큰 저장 및 관리**: Flutter Secure Storage 사용
- **자동 인증 상태 관리**: AuthProvider로 상태 관리
- **HTTP 인터셉터**: 자동 Authorization 헤더 주입
- **라우팅 가드**: 인증 상태 기반 화면 이동

### 1.2. 구현된 사용자 플로우

**신규 사용자 회원가입 플로우:**
```
1. 사용자 -> Google Sign-In 버튼 클릭
2. GoogleSignInService -> Google OAuth 팝업 표시
3. Google OAuth -> ID Token/Access Token 반환
4. AuthService -> 백엔드 API 호출 (/api/auth/google)
5. Backend -> Google 토큰 검증 및 사용자 생성/조회
6. Backend -> JWT Access Token 반환 (profileCompleted: false)
7. TokenStorage -> JWT 암호화 저장
8. AuthProvider -> 인증 상태 업데이트
9. Navigator -> RoleSelectionScreen으로 이동 (신규 사용자)
10. 사용자 -> 역할 선택 (학생/교수)
11. Navigator -> ProfileSetupScreen으로 이동
12. 사용자 -> 닉네임, 프로필사진, 자기소개 입력
13. AuthService -> 프로필 완성 API 호출 (/api/users/complete-profile)
14. Backend -> 프로필 정보 업데이트 (profileCompleted: true)
15. Navigator -> HomeScreen으로 이동
```

**기존 사용자 로그인 플로우:**
```
1-8. 위와 동일
9. Backend -> profileCompleted가 true인 경우
10. Navigator -> HomeScreen으로 직접 이동
```

### 1.3. 기술적 구현 상세

**Frontend 컴포넌트:**
- `GoogleSignInService`: Google OAuth SDK 래핑
- `AuthService`: HTTP 통신 서비스 (프로필 완성 API 포함)
- `AuthProvider`: 인증 상태 관리 (ChangeNotifier)
- `AuthRepository`: 비즈니스 로직 레이어 (프로필 완성 기능 포함)
- `TokenStorage`: Secure Storage 추상화
- `RoleSelectionScreen`: 학생/교수 역할 선택 화면
- `ProfileSetupScreen`: 닉네임, 프로필사진, 자기소개 입력 화면

**Error Handling:**
- Google OAuth 오류 처리
- 네트워크 오류 처리
- 토큰 만료/무효 처리
- 사용자 치화 오류 메시지

**✅ 추가로 구현된 기능:**
- **역할 선택 UI**: 학생/교수 선택 화면 구현
- **프로필 설정 화면**: 닉네임, 프로필사진, 자기소개 입력
- **단계별 회원가입 플로우**: Google OAuth → 역할선택 → 프로필설정
- **User 엔티티 확장**: nickname, profileImageUrl, bio, profileCompleted, emailVerified 필드 추가
- **프로필 완성 API**: 백엔드 API 및 프론트엔드 연동 완료

**❌ 여전히 미구현:**
- 학교 이메일 인증
- 교수 승인 프로세스

---

## 2. Group / Workspace Management (미구현) ❌

**⚠️ 전체 기능이 미구현 상태입니다.**

**계획된 기능:**
- **2.1. Overview:** 사용자가 커뮤니티(그룹)를 형성하고 전용 협업 공간(워크스페이스)을 운영
- **2.2. Roles & Permissions:**
    - **System Admin:** 최상위 그룹 생성 및 그룹 리더 부재 시 개입
    - **Group Leader (Student Rep):** 하위그룹 생성/멤버 가입 승인/거부, 지도교수 임명/해제, 리더십 위임, 그룹 삭제
    - **Supervising Professor (Faculty):** 그룹 리더가 임명, 그룹 리더와 동일한 권한 (다른 리더/교수 관리 제외)
    - **Group Member:** 그룹 내 일반 사용자
    - **General User:** 그룹 검색 및 가입 신청 가능

**미구현 사유:**
- Group, Member, Role, Permission 등 관련 엔티티가 모두 미구현
- 그룹 관리 API 전체 미구현
- 권한 시스템 미구현

---

## 3. Permissions / Member Management (미구현) ❌

**⚠️ 전체 기능이 미구현 상태입니다.**

**계획된 기능:**
- 역할 기반 권한 시스템
- 커스텀 역할 생성 및 권한 할당
- 멤버 관리 화면

**미구현 사유:**
- Role, Permission, RolePermission 엔티티 미구현
- 권한 검증 시스템 미구현
- 멤버 관리 UI 미구현

---

## 4. Promotion / Recruitment (미구현) ❌

**⚠️ 전체 기능이 미구현 상태입니다.**

**계획된 기능:**
- 전용 모집 게시판
- 모집 공고 작성, 수정, 삭제
- 태그 기반 검색
- 자동 마감 처리

**미구현 사유:**
- RecruitmentPost, Tag, PostTag 엔티티 미구현
- 모집 관련 API 전체 미구현
- 모집 게시판 UI 미구현

---

## 5. Posts / Comments (미구현) ❌

**⚠️ 전체 기능이 미구현 상태입니다.**

**계획된 기능:**
- 실시간 채팅 형태의 게시글/댓글 시스템
- 단일 레벨 댓글 (대댓글 없음)
- 게시글/댓글 CRUD

**미구현 사유:**
- Channel, Post, Comment 엔티티 미구현
- 게시글/댓글 관련 API 전체 미구현
- 실시간 채팅 UI 미구현

---

## 6. Notification System (미구현) ❌

**⚠️ 전체 기능이 미구현 상태입니다.**

**계획된 기능:**
- 구조화된 알림 시스템
- 90일 자동 삭제 정책
- 실시간 알림 UI
- 그룹 가입/역할 변경 알림

**미구현 사유:**
- Notification 엔티티 미구현
- 알림 관련 API 전체 미구현
- 알림 UI 미구현

---

## 7. Admin Page (미구현) ❌

**⚠️ 전체 기능이 미구현 상태입니다.**

**계획된 기능:**
- 권한 기반 관리자 페이지
- 멤버/역할/채널 관리
- 아이콘 기반 UI

**미구현 사유:**
- 관리자 권한 시스템 미구현
- 관리 기능 API 전체 미구현
- 관리자 UI 미구현

---

## 8. User Profile & Account Management (부분 구현) ⚠️

**✅ 구현 완료된 기능:**
- **프로필 초기 설정**: 회원가입 시 닉네임, 프로필사진, 자기소개 입력
- **User 엔티티 확장**: nickname, profileImageUrl, bio, profileCompleted, emailVerified 필드 추가
- **프로필 완성 API**: `/api/users/complete-profile` 엔드포인트 구현
- **내 정보 조회 API**: `/api/users/me` 엔드포인트 구현
- **프로필 완성 상태 관리**: profileCompleted 플래그를 통한 회원가입 플로우 제어

**❌ 여전히 미구현:**
- 마이페이지 (프로필 조회/편집 화면)
- 프로필 편집 기능 (가입 후 수정)
- 서비스 탈퇴
- 계정 설정
- 프로필 이미지 업로드 기능 (현재는 URL만 저장)

**현재 구현된 것:**
- 확장된 사용자 정보 (id, name, email, nickname, profileImageUrl, bio, globalRole, profileCompleted, emailVerified, isActive, createdAt, updatedAt) 저장
- 회원가입 시 프로필 완성 플로우


---
## File: context/frontend-architecture.md

# Flutter Frontend Architecture

**⚠️ 현재 구현 상태**: Flutter 프로젝트가 완전히 구현되었으며, Google OAuth 인증 시스템이 백엔드와 연동 완료되었습니다.

이 문서는 Flutter 앱의 상세한 아키텍처와 구현 상태를 설명합니다.

---

## 1. 프로젝트 구조 (Clean Architecture)

### 1.1. 디렉토리 구조 ✅
```
lib/
├── main.dart                          # 앱 진입점
├── injection/                         # 의존성 주입 설정
│   └── injection.dart
├── core/                             # 핵심 유틸리티
│   ├── auth/
│   │   └── google_signin.dart        # Google OAuth 서비스
│   ├── constants/
│   │   └── app_constants.dart        # 앱 전역 상수
│   ├── network/
│   │   ├── dio_client.dart           # HTTP 클라이언트
│   │   ├── api_response.dart         # API 응답 모델
│   │   └── api_response.g.dart       # 자동 생성 코드
│   └── storage/
│       └── token_storage.dart        # 토큰 저장소
├── domain/                           # 비즈니스 레이어
│   └── repositories/
│       └── auth_repository.dart      # 인증 저장소 인터페이스
├── data/                            # 데이터 레이어
│   ├── models/
│   │   ├── user_model.dart          # 사용자 모델 (확장됨)
│   │   └── user_model.g.dart        # 자동 생성 코드
│   ├── services/
│   │   └── auth_service.dart        # 인증 API 서비스 (프로필 완성 API 포함)
│   └── repositories/
│       └── auth_repository_impl.dart # 인증 저장소 구현체
└── presentation/                    # 프레젠테이션 레이어
    ├── providers/
    │   └── auth_provider.dart       # 인증 상태 관리
    ├── screens/
    │   ├── auth/
    │   │   ├── login_screen.dart    # 로그인 화면
    │   │   ├── register_screen.dart # 회원가입 화면
    │   │   ├── role_selection_screen.dart # 역할 선택 화면 (학생/교수)
    │   │   └── profile_setup_screen.dart  # 프로필 설정 화면
    │   ├── home/
    │   │   └── home_screen.dart     # 홈 화면
    │   └── webview/
    │       └── webview_screen.dart  # 웹뷰 화면
    └── theme/
        └── app_theme.dart           # 앱 테마 설정
```

### 1.2. Architecture Layers

**Core Layer** (최하위): 외부 의존성과 인프라 관련 코드
- 네트워크 클라이언트, 저장소, 외부 서비스 연동

**Data Layer**: 데이터 접근과 변환 담당
- API 서비스, 모델, Repository 구현체

**Domain Layer**: 비즈니스 로직 추상화
- Repository 인터페이스, 비즈니스 엔티티

**Presentation Layer**: UI와 상태 관리
- 화면, 위젯, 상태 관리 Provider

---

## 2. 기술 스택 및 의존성

### 2.1. 핵심 의존성 ✅
```yaml
dependencies:
  # HTTP 통신
  dio: ^5.3.2
  
  # 상태 관리 & 의존성 주입
  provider: ^6.0.5              # 상태 관리 (Riverpod 대신)
  get_it: ^7.6.4               # 의존성 주입
  
  # 인증 & 저장
  google_sign_in: ^6.2.1       # Google OAuth
  shared_preferences: ^2.2.2    # 일반 저장소
  flutter_secure_storage: ^9.0.0 # 보안 저장소
  
  # 유틸리티
  json_annotation: ^4.8.1      # JSON 직렬화
  equatable: ^2.0.5            # 객체 비교
  webview_flutter: ^4.7.0      # 웹뷰
```

### 2.2. 개발 의존성
```yaml
dev_dependencies:
  # 코드 생성
  json_serializable: ^6.7.1    # JSON 모델 자동 생성
  build_runner: ^2.4.7         # 빌드 도구
  
  # 테스트 & 품질
  flutter_lints: ^3.0.0        # 린팅
  mockito: ^5.4.2              # 목킹
```

---

## 3. 인증 시스템 (완전 구현됨) ✅

### 3.1. Google OAuth 인증 흐름

```dart
// 1. Google Sign-In 서비스
class GoogleSignInService {
  Future<GoogleTokens?> signInAndGetTokens() async {
    final account = await _googleSignIn.signIn();
    if (account == null) return null;
    
    final auth = await account.authentication;
    return GoogleTokens(
      idToken: auth.idToken,
      accessToken: auth.accessToken
    );
  }
}

// 2. 백엔드 API 호출
class AuthService {
  Future<ApiResponse<Map<String, dynamic>>> loginWithGoogle(String idToken) async {
    return await _dioClient.dio.post('/api/auth/google', data: {
      'googleAuthToken': idToken,
    });
  }
}

// 3. 상태 관리
class AuthProvider extends ChangeNotifier {
  Future<bool> loginWithGoogleTokens({String? idToken, String? accessToken}) async {
    // 토큰 검증 및 JWT 저장
    // 인증 상태 업데이트
    // UI 리스너 알림
  }
  
  // 4. 프로필 완성 (새로 추가됨)
  Future<bool> completeProfile({
    required String nickname,
    required String globalRole,
    String? profileImageUrl,
    String? bio,
  }) async {
    // 프로필 완성 API 호출
    // 사용자 정보 업데이트
    // profileCompleted 상태 업데이트
  }
}
```

### 3.2. 토큰 관리 시스템

**JWT 토큰 저장**:
```dart
abstract class TokenStorage {
  Future<void> saveAccessToken(String token);
  Future<String?> getAccessToken();
  Future<void> clearTokens();
}

class SecureTokenStorage implements TokenStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  // 암호화된 저장소 사용
}
```

**자동 토큰 주입**:
```dart
class DioClient {
  void _setupInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _tokenStorage.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }
}
```

### 3.3. 인증 상태 관리 (개선됨)

```dart
enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  AuthState _state = AuthState.initial;
  UserModel? _currentUser;
  String? _errorMessage;
  
  // 자동 인증 상태 확인 (개선된 에러 처리)
  Future<void> checkAuthStatus() async {
    try {
      _setState(AuthState.loading);
      final isLoggedIn = await _authRepository.isLoggedIn();
      
      if (isLoggedIn) {
        final user = await _authRepository.getCurrentUser();
        _currentUser = user;
        _setState(AuthState.authenticated);
      } else {
        _setState(AuthState.unauthenticated);
      }
    } catch (e) {
      _setError('인증 상태 확인 실패: ${e.toString()}');
    }
  }
  
  // 상태 관리 개선 사항
  void _setState(AuthState newState) {
    _state = newState;
    _errorMessage = null; // 새 상태로 변경 시 에러 초기화
    notifyListeners();
  }
  
  void _setError(String error) {
    _state = AuthState.error;
    _errorMessage = error;
    notifyListeners();
  }
  
  // 로그아웃 개선 (완전한 상태 초기화)
  Future<void> logout() async {
    try {
      _setState(AuthState.loading);
      await _authRepository.logout();
      await _tokenStorage.clearTokens();
      _currentUser = null;
      _setState(AuthState.unauthenticated);
    } catch (e) {
      _setError('로그아웃 실패: ${e.toString()}');
    }
  }
}
```

#### 3.3.1. 인증 상태 관리 개선 사항

**개선된 에러 처리**:
- 모든 인증 관련 작업에 try-catch 블록 적용
- 사용자 친화적 에러 메시지 제공
- 에러 상태와 메시지를 분리하여 UI에서 선택적 표시 가능

**상태 전환 일관성**:
- `_setState()` 메서드를 통한 일관된 상태 변경
- 상태 변경 시 이전 에러 메시지 자동 초기화
- 로딩 상태의 적절한 표시

**완전한 로그아웃 처리**:
- 토큰 삭제와 상태 초기화를 원자적으로 처리
- 사용자 정보 완전 삭제
- 에러 발생 시에도 안전한 상태 유지

**자동 토큰 갱신 준비**:
- 향후 refresh token 구현을 위한 구조적 기반 마련
- 토큰 만료 감지 및 처리 로직 개선

### 3.4. 향상된 회원가입 플로우 (2025-09-11 추가) ✅

**신규 사용자 회원가입 단계**:
```dart
// 1. Google OAuth 인증 완료 후
// 2. profileCompleted가 false인 경우 단계별 진행

class SignupFlowManager {
  // Step 1: 역할 선택
  static void navigateToRoleSelection(BuildContext context) {
    Navigator.pushNamed(context, '/role-selection');
  }
  
  // Step 2: 프로필 설정
  static void navigateToProfileSetup(BuildContext context, String role) {
    Navigator.pushNamed(context, '/profile-setup', arguments: {'role': role});
  }
  
  // Step 3: 프로필 완성 및 홈으로 이동
  static Future<void> completeSignupAndNavigateHome(
    BuildContext context, 
    AuthProvider authProvider, 
    ProfileData profileData
  ) async {
    final success = await authProvider.completeProfile(
      nickname: profileData.nickname,
      globalRole: profileData.role,
      profileImageUrl: profileData.profileImageUrl,
      bio: profileData.bio,
    );
    
    if (success) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
  }
}
```

**새로운 화면 컴포넌트**:
- **RoleSelectionScreen**: 학생/교수 역할 선택 UI
- **ProfileSetupScreen**: 닉네임, 프로필사진, 자기소개 입력 UI
- **교수 선택 시 안내**: 승인 필요 메시지 표시

**상태 관리 개선**:
```dart
class AuthProvider extends ChangeNotifier {
  bool get isProfileCompleted => _currentUser?.profileCompleted ?? false;
  
  Future<bool> completeProfile({
    required String nickname,
    required String globalRole,
    String? profileImageUrl,
    String? bio,
  }) async {
    try {
      final success = await _authRepository.completeProfile(
        nickname: nickname,
        globalRole: globalRole,
        profileImageUrl: profileImageUrl,
        bio: bio,
      );
      
      if (success) {
        // 사용자 정보 갱신
        await _loadUserProfile();
        notifyListeners();
      }
      
      return success;
    } catch (e) {
      _setError('프로필 완성 실패: ${e.toString()}');
      return false;
    }
  }
}

---

## 4. 네트워크 레이어

### 4.1. HTTP 클라이언트 구성 ✅

```dart
class DioClient {
  late final Dio _dio;
  
  DioClient(TokenStorage tokenStorage) {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,           // "http://localhost:8080"
      connectTimeout: Duration(milliseconds: 5000),
      receiveTimeout: Duration(milliseconds: 10000),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    _setupInterceptors();  // 자동 토큰 주입 & 로깅
  }
}
```

### 4.2. API 응답 모델 ✅

```dart
@JsonSerializable(genericArgumentFactories: true)
class ApiResponse<T> {
  final bool success;
  final T? data;
  final ApiError? error;
  
  // 자동 JSON 직렬화/역직렬화
}
```

**✅ 백엔드 API 응답 형태 일치 완료**: AuthService가 백엔드의 표준 ApiResponse 래퍼 형태 `{ "success": true, "data": {...} }`를 정확히 파싱하도록 수정됨. Google 로그인 API의 응답을 LoginResponse 객체로 직접 변환하여 처리하며, AuthRepository, AuthProvider 전체 레이어에서 타입 일치성이 확보됨. 향후 다른 API 엔드포인트들도 동일한 표준 형태로 수정할 때 이 구조를 참고할 수 있음.

### 4.3. 에러 처리

- **401 Unauthorized**: 토큰 만료 처리 (향후 리프레시 토큰 구현 예정)
- **Network Errors**: 연결 실패, 타임아웃 처리
- **Server Errors**: 5xx 에러 처리
- **Business Logic Errors**: 백엔드 비즈니스 예외 처리

---

## 5. 상태 관리 패턴

### 5.1. Provider + GetIt 조합 ✅

**Provider**: UI 상태 관리 및 리스너 패턴
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider<AuthProvider>(
      create: (_) => getIt<AuthProvider>()..checkAuthStatus(),
    ),
  ],
  child: MaterialApp(...),
)
```

**GetIt**: 의존성 주입 컨테이너
```dart
Future<void> setupDependencyInjection() async {
  // Singleton 등록
  getIt.registerLazySingleton<TokenStorage>(() => SecureTokenStorage());
  getIt.registerLazySingleton<DioClient>(() => DioClient(getIt<TokenStorage>()));
  
  // Factory 등록
  getIt.registerFactory<AuthProvider>(() => AuthProvider(getIt<AuthRepository>()));
}
```

### 5.2. 상태 흐름

```
User Action (로그인 버튼 클릭)
    ↓
AuthProvider.loginWithGoogleTokens()
    ↓
AuthRepository.loginWithGoogle()
    ↓
AuthService.loginWithGoogle()
    ↓
DioClient (자동 토큰 주입)
    ↓
Backend API Call
    ↓
TokenStorage.saveAccessToken()
    ↓
AuthProvider.notifyListeners()
    ↓
UI Update (Navigator.pushNamed('/home'))
```

---

## 6. UI 및 화면 구조

### 6.1. 구현된 화면들 ✅

**SplashScreen**: 초기 로딩 및 인증 상태 확인
- AuthProvider 초기화
- 자동 로그인 여부 확인
- 적절한 화면으로 리다이렉트

**LoginScreen**: Google OAuth 로그인
- Google Sign-In 버튼
- 에러 메시지 표시
- 로딩 상태 관리
- 프로필 완성 여부에 따른 라우팅 분기

**RegisterScreen**: 회원가입 (기본 구조만)
- 추가 정보 입력 예정
- 현재는 스켈레톤 구조만

**RoleSelectionScreen**: 역할 선택 화면 ✅
- 학생/교수 역할 선택 UI
- 교수 선택 시 승인 필요 안내 메시지
- 선택 완료 후 프로필 설정으로 자동 이동

**ProfileSetupScreen**: 프로필 설정 화면 ✅
- 닉네임 입력 (필수)
- 프로필 이미지 URL 입력 (선택)
- 자기소개 입력 (선택)
- 프로필 완성 API 연동 및 상태 관리

**HomeScreen**: 인증 후 메인 화면
- 로그아웃 기능
- 사용자 정보 표시
- 그룹 관리 기능 연결점 (향후 구현)

**WebViewScreen**: 외부 링크 표시용

### 6.2. 테마 시스템 ✅

```dart
class AppTheme {
  static const Color primaryColor = Color(0xFF1976D2);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color textPrimaryColor = Color(0xFF212121);
  static const Color textSecondaryColor = Color(0xFF757575);
  
  static ThemeData get lightTheme => ThemeData(
    primarySwatch: Colors.blue,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    // 통일된 색상과 폰트 적용
  );
}
```

### 6.3. 라우팅 시스템

**Named Routes 사용**:
```dart
MaterialApp(
  initialRoute: '/login',
  routes: {
    '/': (context) => const SplashScreen(),
    '/login': (context) => const LoginScreen(),
    '/register': (context) => const RegisterScreen(),
    '/role-selection': (context) => const RoleSelectionScreen(),
    '/profile-setup': (context) => const ProfileSetupScreen(),
    '/home': (context) => const HomeScreen(),
    '/webview': (context) => const WebViewScreen(),
  },
)
```

---

## 7. 보안 고려사항

### 7.1. 토큰 저장 ✅
- **Flutter Secure Storage** 사용하여 암호화된 저장소에 JWT 저장
- 앱 제거 시 자동 삭제
- 루팅/탈옥 디바이스에서도 상대적으로 안전

### 7.2. 네트워크 보안
- HTTPS 통신 (프로덕션)
- Certificate Pinning (향후 추가 예정)
- API 요청 로깅 (개발 환경에서만)

### 7.3. 인증 보안
- Google OAuth 표준 준수
- JWT 토큰 만료 처리
- 자동 로그아웃 (토큰 무효시)

---

## 8. 현재 한계점 및 향후 개선사항

### 8.1. 미구현 기능 ❌
- **Refresh Token**: 자동 토큰 갱신
- **Offline Support**: 오프라인 모드
- **Push Notifications**: 실시간 알림
- **Deep Linking**: URL 기반 화면 이동
- **Internationalization**: 다국어 지원

### 8.2. 성능 최적화 필요
- **이미지 캐싱**: 프로필 이미지 등
- **무한 스크롤**: 리스트 성능
- **상태 지속성**: 앱 재시작 시 상태 복원

### 8.3. 테스트 부재 ❌
- Unit Tests
- Widget Tests
- Integration Tests
- 모든 테스트가 미구현 상태

---

## 9. 빌드 및 배포

### 9.1. 웹 빌드 ✅
```bash
flutter build web
# build/web/ 폴더에 정적 파일 생성
# Spring Boot static 폴더로 복사하여 통합 배포
```

### 9.2. 환경별 설정
- **Development**: localhost:8080
- **Production**: AWS EC2 서버 주소
- AppConstants.dart에서 환경별 분리 관리

---

## 10. 결론

Flutter 프론트엔드는 **Google OAuth 인증 시스템을 중심으로 완전히 구현**되었습니다. Clean Architecture를 기반으로 한 확장 가능한 구조를 가지고 있으며, 백엔드 API와의 완전한 연동이 완료된 상태입니다.

다음 단계에서는 그룹 관리, 멤버십, 게시글 등의 핵심 비즈니스 기능들을 이 견고한 아키텍처 기반 위에 구현할 수 있습니다.

---
## File: context/frontend-auth-web-error-archive.md

# 프론트엔드 에러 해결 아카이브 — 웹 인증 상태 이슈 (뒤로가기/새로고침/로그아웃)

## 문제 요약
- 웹에서 첫 로그인은 성공하나, 메인 화면에서 브라우저 뒤로가기, 새로고침, 또는 로그아웃 시 인증 상태가 깨지거나 화면이 반응하지 않음.
- `flutter clean` 후 재실행/재로그인해야 정상화되는 현상 발생.

## 증상
- 뒤로가기: 로그인 페이지로 이동하지만 즉시 인증 상태가 반영되지 않거나 홈으로 복귀하지 않음.
- 새로고침: 홈에 머물러야 하는데 인증이 해제된 것처럼 보이거나, 반대로 인증이 없는데 홈에 남는 경우 발생.
- 로그아웃: 버튼을 눌러도 UI에 변화가 없거나, 네트워크 대기 때문에 반응이 매우 느림.

## 원인 분석
1. Web 환경에서의 토큰 저장소 선택 문제
   - 기본 `flutter_secure_storage`는 웹/로컬 환경에서 제약이 있어 새로고침/히스토리 이동 후 토큰을 신뢰성 있게 읽지 못할 수 있음.
   - 결과적으로 `isLoggedIn()` 판단이 불안정해 인증 상태가 교란됨.

2. 초기 라우트가 로그인 화면으로 고정됨
   - `initialRoute: '/login'`로 시작해 Splash(인증 점검 로직)를 우회.
   - 뒤로가기/새로고침 시 인증 실체와 화면 라우팅이 쉽게 불일치.

3. 로그아웃 동작이 네트워크 응답에 종속
   - 서버 `/auth/logout` 호출을 기다린 뒤 상태를 변경하므로, CORS/네트워크 지연 시 "아무 반응 없음"으로 체감.

4. 라우트 가드 부재
   - 로그인 페이지에서 이미 인증된 사용자를 홈으로 보내지 않음.
   - 홈에서 인증이 해제된 경우 로그인으로 강제 리다이렉트하지 않음.

## 해결 사항 (코드 변경)
1. Web 전용 토큰 저장소 스위칭
   - `kIsWeb ? SharedPrefsTokenStorage() : SecureTokenStorage()`
   - 파일: `frontend/lib/injection/injection.dart`

2. 앱 진입점을 Splash로 변경하여 인증 상태 기반 라우팅 일원화
   - `initialRoute: '/'` (Splash)
   - 파일: `frontend/lib/main.dart`

3. 로그인/홈 양방향 가드 추가
   - 로그인 화면: 이미 인증된 경우 `'/home'`으로 즉시 리다이렉트
   - 홈 화면: 비인증 상태(그리고 로딩 아님)면 `'/login'`으로 리다이렉트
   - 파일: `frontend/lib/presentation/screens/auth/login_screen.dart`, `frontend/lib/presentation/screens/home/home_screen.dart`

4. 로그아웃 UX를 즉시형으로 개선
   - 로컬 세션(토큰/유저) 즉시 클리어 → 상태 `unauthenticated` 반영 → UI/라우팅 즉시 전환
   - 서버 로그아웃과 Google Sign-Out은 백그라운드에서 처리 (실패 무시)
   - 파일: `frontend/lib/presentation/providers/auth_provider.dart`

## 변경 파일 목록
- `frontend/lib/injection/injection.dart`
- `frontend/lib/main.dart`
- `frontend/lib/presentation/screens/auth/login_screen.dart`
- `frontend/lib/presentation/screens/home/home_screen.dart`
- `frontend/lib/presentation/providers/auth_provider.dart`

## 재현 방지 검증 체크리스트
1. `flutter run -d chrome` 실행
2. Google 로그인 완료 → 홈 진입 확인
3. 브라우저 뒤로가기 → 로그인으로 갔다가 즉시 홈 복귀 확인
4. 홈에서 새로고침 → 로그인 유지 시 홈에 머무름 / 미인증 시 로그인으로 이동
5. 로그아웃 클릭 → 즉시 로그인 화면으로 이동, 재로그인 가능 (네트워크 상태와 무관)

## 회귀 및 부작용 고려
- 웹 환경에서 보안 스토리지가 필요한 경우, HTTPS 및 `flutter_secure_storage`의 웹 옵션을 충분히 검토해야 함. 개발/로컬에서는 `SharedPreferences`가 신뢰성과 DX를 보장.
- 서버 로그아웃 실패 시에도 클라이언트는 로그아웃으로 간주함. 보안 정책상 서버 세션 무효화 보장이 필요하면 API 성공 여부를 별도 로깅/모니터링하거나 재시도 큐 도입 고려.

---

# JSON 직렬화 에러 해결 사례

## 문제 요약
- Flutter 웹 환경에서 API 응답을 DTO로 변환할 때 JSON 직렬화 에러 발생
- `json_annotation` 및 `build_runner` 관련 코드 생성 문제로 인한 런타임 에러

## 증상
- API 호출은 성공하지만 응답 데이터를 모델 객체로 변환하는 과정에서 `FormatException` 또는 `TypeError` 발생
- 개발 모드에서는 정상 동작하지만 빌드된 웹에서만 에러 발생
- 콘솔에 "type 'String' is not a subtype of type 'int'" 등의 타입 불일치 에러 출력

## 원인 분석
1. **JSON 키-값 타입 불일치**
   - 서버에서 숫자를 문자열로 전송하거나, null 값을 예상치 못한 타입으로 처리
   - DTO 클래스의 필드 타입과 실제 JSON 응답의 타입 불일치

2. **코드 생성 파일 누락 또는 구버전**
   - `*.g.dart` 파일이 최신 DTO 정의를 반영하지 않음
   - `build_runner` 실행 없이 DTO 필드를 변경한 경우

3. **웹 컴파일러의 엄격한 타입 체킹**
   - Flutter 웹은 다른 플랫폼보다 타입 안정성을 더 엄격하게 검사

## 해결 사항 (코드 변경)
1. **타입 안전 JSON 변환 추가**
   ```dart
   // 기존 코드
   factory UserDto.fromJson(Map<String, dynamic> json) => _$UserDtoFromJson(json);
   
   // 개선된 코드 
   factory UserDto.fromJson(Map<String, dynamic> json) {
     return UserDto(
       id: _parseToInt(json['id']),
       name: json['name']?.toString() ?? '',
       email: json['email']?.toString() ?? '',
       createdAt: json['created_at'] != null 
         ? DateTime.tryParse(json['created_at'].toString())
         : null,
     );
   }
   
   static int _parseToInt(dynamic value) {
     if (value is int) return value;
     if (value is String) return int.tryParse(value) ?? 0;
     return 0;
   }
   ```

2. **build_runner 재실행으로 코드 생성 파일 동기화**
   ```bash
   flutter packages pub run build_runner clean
   flutter packages pub run build_runner build --delete-conflicting-outputs
   ```

3. **nullable 필드 처리 강화**
   ```dart
   // DTO 클래스에서 nullable 명시적 선언
   class UserDto {
     final int id;
     final String name;
     final String email;
     final DateTime? createdAt; // nullable로 명시적 선언
     
     const UserDto({
       required this.id,
       required this.name, 
       required this.email,
       this.createdAt,
     });
   }
   ```

## 변경 파일 목록
- `frontend/lib/data/dto/user_dto.dart`
- `frontend/lib/data/dto/auth_dto.dart`
- `frontend/lib/data/dto/*.g.dart` (자동 생성)

## 재현 방지 검증 체크리스트
1. `flutter clean && flutter pub get` 실행
2. `flutter packages pub run build_runner build --delete-conflicting-outputs` 실행
3. `flutter run -d chrome` 으로 웹 실행
4. API 호출이 포함된 모든 기능 테스트 (로그인, 데이터 조회 등)
5. 브라우저 개발자 도구에서 콘솔 에러 없음 확인
6. `flutter build web --release` 빌드 후 동일 테스트 수행

## 회귀 및 부작용 고려
- 수동 JSON 파싱 코드 추가로 코드 복잡성 증가
- `json_serializable` 자동 생성의 이점 일부 포기 (타입 안전성과의 트레이드오프)
- 새로운 DTO 추가 시 동일한 패턴 적용 필요

## 향후 개선 제안
- `go_router`로 전역 라우트 가드 통합 및 상태 기반 리다이렉트 일관화.
- 토큰 자동 갱신(401 처리) 로직 구현 및 공통 재시도 핸들러 도입.
- 에러/이벤트 로깅(예: Sentry)으로 웹 환경 특이 이슈 추적 강화.
- API 스키마 검증 도구 도입으로 백엔드-프론트엔드 간 타입 불일치 사전 방지.



---
## File: context/process-conventions.md

# Development Process and Conventions

**⚠️ 현재 상태**: 자동화된 AI Agent 협업 워크플로우가 완전히 가동되는 상태입니다. Claude는 사용자 지시에 따라 자동으로 Gemini CLI 명령을 실행합니다.

This document summarizes the AI agent-based development workflow, roles, and conventions for this project. It is synthesized from `ai-agent-workflow.md`, `gemini-integration.md`, and `tasks-conventions.md`.

## 1. Core Principles

- **Task-Centric**: All development work is managed within isolated task packages located at `tasks/<date>-<slug>/`.
- **Single Source of Truth**: `TASK.MD` within each package is the central hub for all instructions, logs, and decisions related to a task.
- **Knowledge Separation**:
    - **Static Knowledge**: Long-term knowledge like architecture, standards, and conventions are stored in the `context/` directory.
    - **Dynamic Context**: Task-specific, synthesized context is generated into `SYNTHESIZED_CONTEXT.MD` for one-time use.
- **AI Agent Collaboration**: The workflow relies on a team of specialized AI agents orchestrated by the developer.

## 2. AI Agent Roles

- **Developer**: Oversees the entire process, defines tasks, provides instructions, and gives final approval.
- **Gemini CLI (Orchestrator)**: Manages the task lifecycle and synthesizes context. Its primary role is to create `SYNTHESIZED_CONTEXT.MD` based on `TASK.MD` and the `context/` knowledge base.
- **Claude Code (Implementer)**: Executes development and refactoring tasks as instructed in `TASK.MD`.
- **Codex (Debugger)**: Analyzes errors and suggests solutions when Claude is blocked.

## 3. Development Workflow Lifecycle

The development process follows a four-step lifecycle managed by the `gemini` helper script.

### Step 1: Task Creation
- **Command**: `gemini task new "<descriptive-task-title>"`
- **Action**: Creates a new directory `tasks/<date>-<slug>/` and initializes it with a `TASK.MD` file from the template.

### Step 2: Context Synthesis
- **Command**: `gemini task run-context` (executed within the task directory)
- **Action**: Gemini CLI analyzes the `TASK.MD`, gathers relevant static knowledge from `context/` (guided by `.gemini/metadata.json`), and generates a tailored `SYNTHESIZED_CONTEXT.MD` file for the current task.

### Step 3: Development Cycle
1.  The **Developer** provides specific instructions to Claude Code in the "개발 지시" (Development Instruction) section of `TASK.MD`.
2.  **Claude Code** executes the instructions, logging all activities, progress, and issues in the "작업 로그" (Work Log).
3.  If errors occur, **Codex** is invoked to analyze the problem and provide a solution, which is also logged.

### Step 4: Task Completion & Knowledge Assetization
1.  Once the goal is achieved, the **Developer** fills out the "변경 사항 요약" (Summary of Changes) and "컨텍스트 업데이트 요청" (Context Update Request) sections in `TASK.MD`.
2.  **Command**: `gemini task complete`
3.  **Action**: The task package is moved to `tasks/archive/`, and a record is appended to `context/CHANGELOG.md`. Any requested updates to the static knowledge base (`context/` files) are then performed based on the "컨텍스트 업데이트 요청".

## 4. Key Artifact: TASK.MD Structure

The `TASK.MD` file is the operational center of every task and contains the following sections:
- **작업 목표 (Task Goal)**: A clear, measurable objective.
- **컨텍스트 요청 (Context Request)**: Specifies the required static and dynamic context.
- **개발 지시 (Development Instruction)**: Concrete instructions for Claude Code.
- **작업 로그 (Work Log)**: A complete record of all actions, results, and errors.
- **변경 사항 요약 (Summary of Changes)**: A detailed summary of code modifications upon completion.
- **컨텍스트 업데이트 요청 (Context Update Request)**: Specifies what new knowledge should be integrated into the `context/` base.
- **최종 검토 (Final Review)**: Developer's final approval and feedback.


---
## File: context/project-plan.md

# Project Plan: MVP and Post-MVP Roadmap

**⚠️ 현재 구현 상태**: Flutter Frontend와 Spring Boot Backend 기초 구조가 완성되었으며, Google OAuth 인증 시스템이 완전 연동되었습니다.

This document outlines the project's scope, starting with the Minimum Viable Product (MVP) and followed by the development roadmap. It is synthesized from `MVP.md` and `MVP 이후 개발 로드맵.md`.

---

## 1. MVP (Minimum Viable Product) Scope

**Core Goal:** To enable new users to discover attractive groups through the **[Explore]** and **[Recruitment]** tabs, join them, and experience systematic announcements and detailed permission management within their groups.

### 현재 구현 상태 요약:
- **✅ 완료**: 인증 시스템 (Google OAuth + JWT)
- **✅ 완료**: Flutter Frontend 기초 구조
- **✅ 완료**: Spring Boot Backend 기초 구조
- **❌ 미구현**: 그룹 관리, 미버십, 권한 시스템
- **❌ 미구현**: 모집 게시판, 게시글/댓글 시스템
- **❌ 미구현**: 알림, 관리자 페이지, 사용자 프로필

### MVP Feature List:

1.  **Group Discovery & Recruitment:**
    - **[Explore] Tab:** A space for users to browse all groups. Each group has a profile page showcasing its identity and activity archive. Searchable by tags.
    - **[Recruitment] Tab:** A feed showing only groups that are actively recruiting. Posts contain key information like recruitment period, qualifications, etc.

2.  **Group Navigation:**
    - A hierarchical navigator (University -> College -> Department) to understand the overall group structure.

3.  **Announcements & Communication:**
    - Ability to create and view text-based announcements within a group.
    - **Threaded comments** are supported for organized discussions on announcements.

4.  **Permission Management:**
    - A detailed permission system from the start.
    - Group leaders can create custom roles (e.g., 'Accounting Team') and assign specific permissions (e.g., create announcements, invite members) to each role.
    - Group leaders can appoint a **'Supervising Professor'** who shares the same authority.

5.  **Notifications:**
    - Minimal, interaction-based notifications are sent only when:
        - A user's join request is **approved or rejected**.
        - A **new join request** is submitted to a group led by the user.
        - A user's **role is changed**.

6.  **Admin Page:**
    - A minimal set of tools for group management:
        - Member management (approve/reject, kick).
        - Role management (create/edit/delete).
        - Edit group information.

7.  **User Profile:**
    - Basic functionality for users to manage their own profile:
        - Edit profile picture, nickname, bio.
        - View a list of their groups.
        - Logout and leave the service.

---

## 2. Post-MVP Roadmap

**Development Goal:** To sequentially expand features so that users acquired through the MVP can settle in successfully and handle all core group activities within the app.

### 2.1. Major Feature Roadmap (In Order of Priority)

1.  **🙋‍♂️ Personalized Home (My Activities):** A personalized To-Do list to reduce information fatigue and encourage daily visits by showing tasks needing attention (e.g., new announcements, RSVPs).
2.  **📅 Calendar:** A central hub to view all group schedules in a monthly/weekly format.
3.  **⏰ Schedule Coordination (Admin-led):** A 'Smart Scheduling Board' for admins to view participants' availability and set optimal event times.
4.  **🧑‍🏫 Professor/Operator Dashboard:** Anonymized statistical data (attendance rates, activity frequency) to support administrative tasks and enhance the app's official credibility.
5.  **✨ Functional Posts (Super Posts):** Ability to create posts with embedded functions like polls and RSVPs.
6.  **✅ QR Code Attendance:** A system to manage attendance for offline events registered in the calendar.
7.  **💬 Real-time Chat Channels:** Separate channels for casual, real-time conversations to prevent users from leaving for external messengers like KakaoTalk.
8.  **Later Stages:** Kanban boards, accounting, gamification (badges), file management, dark mode, etc.

### 2.2. Detailed Feature Enhancements

- **Group & Permissions:**
    - Change group deletion from immediate to a **30-day retention period**.
    - Change subgroup deletion policy to **re-parenting** instead of cascading deletion.
    - Add **private/public** settings for groups.
    - Allow **individual permission adjustments** for specific members, overriding their role.

- **Member Management:**
    - **Bulk Actions** (e.g., change roles for multiple members at once).
    - Display additional info like **'Last Seen'** in the member list.

- **Recruitment & Promotion:**
    - Feature recruitment posts on the **main home screen**.
    - Allow **image attachments** in posts.
    - Add **sorting and filtering** (by deadline, popularity) to the recruitment board.
    - Add a **Q&A (comment) section** to recruitment posts.


---
## File: context/troubleshooting.md

# Troubleshooting Guide

이 문서는 프로젝트에서 발생할 수 있는 일반적인 문제들과 해결 방법을 안내합니다.

---

## 1. 인증 관련 문제 해결

### 1.1. Google OAuth 로그인 실패

**증상**: Google 로그인 버튼을 눌러도 로그인이 진행되지 않거나 실패합니다.

**원인 및 해결방법**:

#### 1.1.1. Google Services 설정 문제
```bash
# Android의 경우
android/app/google-services.json 파일 확인
- Firebase 프로젝트에서 올바른 파일을 다운로드했는지 확인
- package name이 일치하는지 확인

# iOS의 경우  
ios/Runner/GoogleService-Info.plist 파일 확인
- Bundle ID가 일치하는지 확인
```

#### 1.1.2. 개발 환경에서의 SHA-1 지문 미등록
```bash
# Android 개발용 SHA-1 지문 생성
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Firebase Console에서 해당 SHA-1 지문 등록 필요
```

#### 1.1.3. 권한 설정 문제
```yaml
# android/app/src/main/AndroidManifest.xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

### 1.2. 토큰 저장/로드 실패

**증상**: 로그인은 성공하지만 앱을 재시작하면 로그아웃 상태가 됩니다.

**디버깅 방법**:
```dart
// TokenStorage 디버깅
Future<void> debugTokenStorage() async {
  final storage = getIt<TokenStorage>();
  
  // 토큰 저장 테스트
  await storage.saveAccessToken('test_token');
  final savedToken = await storage.getAccessToken();
  
  print('Token saved successfully: ${savedToken == 'test_token'}');
  
  // 토큰 삭제 테스트
  await storage.clearTokens();
  final clearedToken = await storage.getAccessToken();
  
  print('Token cleared successfully: ${clearedToken == null}');
}
```

**해결방법**:
1. **Android 키 관리 문제**: 앱 재설치 시 SecureStorage 키가 변경될 수 있음
2. **iOS Keychain 권한**: Info.plist에 Keychain 접근 권한 확인
3. **에뮬레이터 제한**: 실제 디바이스에서 테스트 필요할 수 있음

### 1.3. 인증 상태가 올바르게 업데이트되지 않음

**증상**: 로그인 후에도 UI가 인증되지 않은 상태로 표시됩니다.

**원인 및 해결방법**:

#### 1.3.1. Provider 리스너 누락
```dart
// 올바른 사용 예시
Consumer<AuthProvider>(
  builder: (context, authProvider, child) {
    switch (authProvider.state) {
      case AuthState.loading:
        return CircularProgressIndicator();
      case AuthState.authenticated:
        return HomeScreen();
      case AuthState.unauthenticated:
        return LoginScreen();
      case AuthState.error:
        return ErrorScreen(message: authProvider.errorMessage);
      default:
        return SplashScreen();
    }
  },
)
```

#### 1.3.2. notifyListeners() 호출 누락
```dart
// AuthProvider에서 상태 변경 시 반드시 호출
void _setState(AuthState newState) {
  _state = newState;
  notifyListeners(); // 이 부분이 누락되면 UI가 업데이트되지 않음
}
```

### 1.4. API 호출 시 401 Unauthorized 에러

**증상**: 로그인 후 API 호출 시 401 에러가 발생합니다.

**디버깅 단계**:
```dart
// 1. 토큰이 실제로 저장되어 있는지 확인
final token = await getIt<TokenStorage>().getAccessToken();
print('Current token: $token');

// 2. DioClient의 인터셉터가 토큰을 주입하는지 확인
_dio.interceptors.add(LogInterceptor(
  request: true,
  requestHeader: true,
  requestBody: true,
  responseHeader: false,
  responseBody: true,
  error: true,
));
```

**해결방법**:
1. **토큰 형식 확인**: `Bearer ` 접두사가 올바르게 추가되는지 확인
2. **토큰 만료**: 백엔드에서 토큰 만료 시간 확인
3. **백엔드 엔드포인트**: API 엔드포인트가 올바른지 확인

### 1.5. 앱 백그라운드 복귀 시 인증 상태 초기화

**증상**: 앱을 백그라운드로 보냈다가 다시 돌아오면 로그아웃 상태가 됩니다.

**해결방법**:
```dart
// main.dart에서 앱 라이프사이클 관리
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 앱이 포그라운드로 복귀했을 때 인증 상태 재확인
      context.read<AuthProvider>().checkAuthStatus();
    }
  }
}
```

---

## 2. 네트워크 관련 문제

### 2.1. 개발 서버 연결 실패

**증상**: Flutter 웹에서 백엔드 API 호출 시 CORS 에러나 연결 실패가 발생합니다.

**해결방법**:
1. **백엔드 CORS 설정 확인**:
   ```kotlin
   // Spring Boot WebConfig
   @CrossOrigin(origins = ["http://localhost:3000", "http://localhost:8080"])
   ```

2. **Flutter 웹 개발 서버 실행**:
   ```bash
   flutter run -d chrome --web-port 3000
   ```

### 2.2. 타임아웃 에러

**증상**: API 호출이 오래 걸리거나 타임아웃됩니다.

**설정 조정**:
```dart
Dio(BaseOptions(
  connectTimeout: Duration(milliseconds: 10000), // 연결 타임아웃 증가
  receiveTimeout: Duration(milliseconds: 15000), // 응답 타임아웃 증가
))
```

---

## 3. 빌드 관련 문제

### 3.1. Android 빌드 실패

**일반적인 해결방법**:
```bash
# 1. 클린 빌드
flutter clean
flutter pub get

# 2. Android 프로젝트 클린
cd android
./gradlew clean
cd ..

# 3. 빌드 재시도
flutter build apk
```

#### 3.1.1. Gradle 버전 호환성 문제

**증상**: `Could not determine the dependencies of task ':app:compileFlutterBuildDebug'`

**해결방법**:
```gradle
// android/gradle/wrapper/gradle-wrapper.properties
distributionUrl=https\://services.gradle.org/distributions/gradle-8.0.2-all.zip

// android/build.gradle
dependencies {
    classpath 'com.android.tools.build:gradle:8.1.0'
    classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
}
```

#### 3.1.2. 안드로이드 SDK 경로 문제

**증상**: `Android SDK not found`

**해결방법**:
```bash
# Android SDK 경로 설정 확인
echo $ANDROID_HOME
echo $ANDROID_SDK_ROOT

# 경로가 설정되지 않았다면
export ANDROID_HOME=$HOME/Library/Android/sdk  # macOS
export ANDROID_HOME=$HOME/Android/Sdk          # Linux
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools
```

#### 3.1.3. MultiDex 설정 문제 (APK 크기 초과)

**증상**: `The number of method references in a .dex file cannot exceed 64K`

**해결방법**:
```gradle
// android/app/build.gradle
android {
    defaultConfig {
        multiDexEnabled true
    }
}

dependencies {
    implementation 'androidx.multidex:multidex:2.0.1'
}
```

```java
// android/app/src/main/java/.../MainApplication.java
import androidx.multidex.MultiDexApplication;

public class MainApplication extends MultiDexApplication {
    // existing code
}
```

### 3.2. 웹 빌드 최적화

**빌드 명령어**:
```bash
# 개발 빌드
flutter build web

# 프로덕션 빌드 (최적화된)
flutter build web --release --web-renderer canvaskit
```

#### 3.2.1. 웹 빌드 시 메모리 부족 에러

**증상**: `JavaScript heap out of memory`

**해결방법**:
```bash
# Node.js 힙 메모리 크기 증가
export NODE_OPTIONS="--max-old-space-size=8192"
flutter build web --release

# 또는 빌드 옵션으로 최적화
flutter build web --release --tree-shake-icons --split-debug-info=build/debug-info
```

#### 3.2.2. 웹 빌드 시 CORS 에러

**증상**: 빌드는 성공하지만 실행 시 API 호출에서 CORS 에러

**해결방법**:
```bash
# 개발 서버에서 CORS 허용으로 실행
flutter run -d chrome --web-port 3000 --web-browser-flag="--disable-web-security"

# 또는 로컬 웹 서버로 테스트
cd build/web
python -m http.server 8080
```

### 3.3. iOS 빌드 문제

#### 3.3.1. CocoaPods 의존성 충돌

**증상**: `CocoaPods could not find compatible versions for pod`

**해결방법**:
```bash
# 1. Podfile.lock 삭제 및 재설치
cd ios
rm Podfile.lock
rm -rf Pods/
pod deintegrate
pod install

# 2. Flutter 의존성 재설치
cd ..
flutter clean
flutter pub get
cd ios
pod install
```

#### 3.3.2. Xcode 서명 문제

**증상**: `Failed to create provisioning profile`

**해결방법**:
```bash
# 1. 개발용 서명으로 임시 해결
open ios/Runner.xcworkspace

# Xcode에서:
# 1. Runner 타겟 선택
# 2. Signing & Capabilities 탭
# 3. Team을 개발자 계정으로 선택
# 4. Bundle Identifier 변경 (고유한 값)
```

### 3.4. 종속성 충돌 문제

#### 3.4.1. 패키지 버전 충돌

**증상**: `Because project depends on both X and Y, version solving failed`

**진단 방법**:
```bash
# 의존성 트리 확인
flutter pub deps

# 특정 패키지의 의존성 확인
flutter pub deps --style=tree | grep package_name
```

**해결방법**:
```yaml
# pubspec.yaml에서 버전 명시적 지정
dependency_overrides:
  http: ^0.13.5
  meta: ^1.8.0
```

#### 3.4.2. Native 플러그인 충돌

**증상**: Android/iOS에서 중복된 심볼 에러

**해결방법**:
```bash
# 1. 캐시 완전 삭제
flutter clean
flutter pub cache repair
rm -rf ~/.pub-cache

# 2. 의존성 재설치
flutter pub get

# 3. 네이티브 빌드 캐시 삭제 (Android)
cd android
./gradlew clean
cd ..

# 4. iOS 캐시 삭제
cd ios
pod deintegrate
pod install
cd ..
```

### 3.5. 빌드 성능 최적화

#### 3.5.1. 빌드 속도 개선

```bash
# 병렬 빌드 활성화
export FLUTTER_BUILD_PARALLEL=true

# 증분 빌드 활성화 (개발 시)
flutter run --hot

# 릴리즈 빌드 최적화
flutter build apk --release --split-per-abi
```

#### 3.5.2. 빌드 크기 최적화

```bash
# APK 크기 분석
flutter build apk --analyze-size

# 웹 빌드 크기 최적화
flutter build web --release --tree-shake-icons --split-debug-info=build/debug-info --source-maps

# 사용하지 않는 리소스 제거
flutter build apk --release --shrink
```

### 3.6. 빌드 환경별 설정

#### 3.6.1. 개발/스테이징/프로덕션 환경 분리

```dart
// lib/config/environment.dart
enum Environment { development, staging, production }

class Config {
  static Environment _environment = Environment.development;
  
  static String get apiBaseUrl {
    switch (_environment) {
      case Environment.development:
        return 'http://localhost:8080';
      case Environment.staging:
        return 'https://staging-api.example.com';
      case Environment.production:
        return 'https://api.example.com';
    }
  }
}
```

```bash
# 환경별 빌드
flutter build apk --release --dart-define=ENV=production
flutter build web --release --dart-define=ENV=staging
```

### 3.7. CI/CD 빌드 문제

#### 3.7.1. GitHub Actions 빌드 실패

**일반적인 해결 체크리스트**:
```yaml
# .github/workflows/build.yml
- name: Setup Flutter
  uses: subosito/flutter-action@v2
  with:
    flutter-version: '3.10.0'  # 버전 고정
    channel: 'stable'

- name: Get dependencies
  run: flutter pub get

- name: Run tests
  run: flutter test

- name: Build APK
  run: flutter build apk --release
```

#### 3.7.2. 빌드 캐시 문제

```yaml
# 빌드 캐시 설정
- name: Cache Flutter dependencies
  uses: actions/cache@v3
  with:
    path: |
      ~/.pub-cache
      ~/.gradle/caches
      ~/.gradle/wrapper
    key: ${{ runner.os }}-flutter-${{ hashFiles('**/pubspec.lock') }}
```

---

## 4. 개발 도구 및 디버깅

### 4.1. Flutter Inspector 활용

**유용한 디버깅 명령어**:
```bash
# 디바이스별 로그 확인
flutter logs

# 특정 디바이스 로그
flutter logs -d <device-id>

# 성능 프로파일링
flutter run --profile
```

### 4.2. 네트워크 요청 모니터링

**Dio 로깅 설정**:
```dart
if (kDebugMode) {
  _dio.interceptors.add(LogInterceptor(
    request: true,
    requestHeader: true,
    requestBody: true,
    responseBody: true,
    error: true,
  ));
}
```

---

## 5. 문제 해결이 안 될 때

### 5.1. 이슈 보고 전 체크리스트

1. **Flutter 버전 확인**: `flutter --version`
2. **의존성 업데이트**: `flutter pub upgrade`
3. **로그 수집**: 에러 발생 시점의 상세한 로그
4. **재현 단계**: 문제가 발생하는 정확한 단계들
5. **환경 정보**: 디바이스, OS 버전, 빌드 타겟 등

### 5.2. 추가 리소스

- **Flutter 공식 문서**: https://docs.flutter.dev
- **Stack Overflow**: flutter 태그로 검색
- **GitHub Issues**: 사용 중인 패키지들의 이슈 트래커 확인

---

이 가이드는 프로젝트 진행에 따라 지속적으로 업데이트될 예정입니다.
