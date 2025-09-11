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
- [ ] 목표 요약: Flutter 앱의 인증 상태 지속성 문제 해결 및 로그아웃 기능 수정
- [ ] 성공 기준: 뒤로가기, 새로고침, 로그아웃 시에도 인증 상태가 정상적으로 관리됨

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
| `password_hash` | VARCHAR(255) | Not Null | 패스워드 해시 (현재 사용되지 않음) |
| `global_role` | ENUM | Not Null | 전역 역할 (STUDENT, PROFESSOR, ADMIN) |
| `is_active` | BOOLEAN | Not Null | 계정 활성화 상태 |
| `created_at` | DATETIME | Not Null | 생성 일시 |
| `updated_at` | DATETIME | Not Null | 수정 일시 |

**주요 차이점:**
- nickname, profile_image_url, bio 필드 미구현
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

```
1. 사용자 -> Google Sign-In 버튼 클릭
2. GoogleSignInService -> Google OAuth 팝업 표시
3. Google OAuth -> ID Token/Access Token 반환
4. AuthService -> 백엔드 API 호출 (/api/auth/google)
5. Backend -> Google 토큰 검증 및 사용자 생성/조회
6. Backend -> JWT Access Token 반환
7. TokenStorage -> JWT 암호화 저장
8. AuthProvider -> 인증 상태 업데이트
9. Navigator -> HomeScreen으로 이동
```

### 1.3. 기술적 구현 상세

**Frontend 컴포넌트:**
- `GoogleSignInService`: Google OAuth SDK 래핑
- `AuthService`: HTTP 통신 서비스
- `AuthProvider`: 인증 상태 관리 (ChangeNotifier)
- `AuthRepository`: 비즈니스 로직 레이어
- `TokenStorage`: Secure Storage 추상화

**Error Handling:**
- Google OAuth 오류 처리
- 네트워크 오류 처리
- 토큰 만료/무효 처리
- 사용자 치화 오류 메시지

**❌ 여전히 미구현:**
- 역할 선택 UI (student/professor)
- 추가 정보 입력 화면
- 학교 이메일 인증
- 교수 승인 프로세스
- nickname, profile_image_url, bio 등 추가 필드

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

## 8. User Profile & Account Management (미구현) ❌

**⚠️ 전체 기능이 미구현 상태입니다.**

**계획된 기능:**
- 마이페이지
- 프로필 편집 (사진, 닉네임, 자기소개)
- 서비스 탈퇴
- 계정 설정

**미구현 사유:**
- User 엔티티에 nickname, bio, profile_image_url 필드 없음
- 프로필 관련 API 미구현
- 프로필 UI 미구현

**현재 구현된 것:**
- 기본 사용자 정보 (id, name, email, globalRole, isActive, createdAt, updatedAt) 저장


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
│   │   ├── user_model.dart          # 사용자 모델
│   │   └── user_model.g.dart        # 자동 생성 코드
│   ├── services/
│   │   └── auth_service.dart        # 인증 API 서비스
│   └── repositories/
│       └── auth_repository_impl.dart # 인증 저장소 구현체
└── presentation/                    # 프레젠테이션 레이어
    ├── providers/
    │   └── auth_provider.dart       # 인증 상태 관리
    ├── screens/
    │   ├── auth/
    │   │   ├── login_screen.dart    # 로그인 화면
    │   │   └── register_screen.dart # 회원가입 화면
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

### 3.3. 인증 상태 관리

```dart
enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  AuthState _state = AuthState.initial;
  UserModel? _currentUser;
  
  // 자동 인증 상태 확인
  Future<void> checkAuthStatus() async {
    final isLoggedIn = await _authRepository.isLoggedIn();
    // 상태 업데이트 및 UI 리스너 알림
  }
}
```

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

**RegisterScreen**: 회원가입 (기본 구조만)
- 추가 정보 입력 예정
- 현재는 스켈레톤 구조만

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

