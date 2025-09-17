# Input Context


---
## File: context/api-conventions.md

# API Conventions

이 문서는 프로젝트의 API 설계 규칙과 구현된 엔드포인트를 정의합니다.

---

## 1. API 설계 원칙

### 1.1. 표준 응답 형식
모든 API 응답은 다음 JSON 구조를 따릅니다:

```json
{
    "success": boolean,
    "data": { ... } | [ ... ] | null,
    "error": { "code": "...", "message": "..." } | null
}
```

### 1.2. HTTP 상태 코드
- `200 OK`: 성공적인 조회/수정
- `201 Created`: 리소스 생성 성공
- `204 No Content`: 성공적인 삭제
- `400 Bad Request`: 잘못된 요청 데이터
- `401 Unauthorized`: 인증 실패
- `403 Forbidden`: 권한 부족
- `404 Not Found`: 리소스 없음
- `500 Internal Server Error`: 서버 내부 오류

### 1.3. 인증 및 권한
- JWT 토큰을 `Authorization: Bearer <token>` 헤더로 전송
- 그룹 권한은 `@PreAuthorize`와 `GroupPermissionEvaluator` 사용
- 글로벌 역할은 `GlobalRole` enum으로 관리

### 1.4. 페이지네이션 응답 규칙

#### 1.4.1. 표준 페이지네이션 응답 형식
일부 API 엔드포인트(특히 목록 조회)는 페이지네이션을 지원하며, 다음 구조로 응답합니다:

```json
{
    "success": true,
    "data": {
        "content": [
            // 실제 데이터 배열
        ],
        "pageable": {
            "sort": {
                "sorted": false,
                "empty": false,
                "unsorted": true
            },
            "pageNumber": 0,
            "pageSize": 20,
            "offset": 0,
            "paged": true,
            "unpaged": false
        },
        "last": true,
        "totalPages": 1,
        "totalElements": 5,
        "first": true,
        "size": 20,
        "number": 0,
        "numberOfElements": 5,
        "sort": {
            "sorted": false,
            "empty": false,
            "unsorted": true
        },
        "empty": false
    }
}
```

#### 1.4.2. 하위 호환성 고려사항
- 프론트엔드는 레거시 형태(`data`가 직접 배열)와 페이지네이션 형태를 모두 처리해야 함
- 레거시 형태: `{ "success": true, "data": [...] }`
- 페이지네이션 형태: `{ "success": true, "data": { "content": [...], ... } }`

#### 1.4.3. 페이지네이션 파라미터
| 파라미터 | 타입 | 기본값 | 설명 |
|----------|------|--------|------|
| `page` | `int` | `0` | 페이지 번호 (0부터 시작) |
| `size` | `int` | `20` | 페이지 당 항목 수 |
| `sort` | `string` | - | 정렬 기준 (예: `name,asc` 또는 `createdAt,desc`) |

#### 1.4.4. 프론트엔드 처리 가이드
프론트엔드에서는 다음과 같이 유연하게 응답을 처리해야 합니다:

```typescript
// 의사 코드
function parseApiResponse(response) {
  if (response.data.length !== undefined) {
    // 레거시 형태: data가 직접 배열
    return response.data;
  } else if (response.data.content) {
    // 페이지네이션 형태: data.content에서 배열 추출
    return response.data.content;
  } else {
    // 단일 객체 형태
    return [response.data];
  }
}
```

---

## 2. 구현된 API 엔드포인트

### 2.1. 인증 API (Auth) - ✅ 확장됨

| 메서드 | 엔드포인트 | 설명 | 인증 | 요청 본문 | 응답 데이터 |
|--------|------------|------|------|-----------|-------------|
| `POST` | `/api/auth/google` | Google OAuth 로그인/회원가입 | None | `{ "googleAuthToken": "...", "googleAccessToken": "..." }` | `{ "accessToken": "...", "firstLogin": bool, "user": { ... } }` |
| `POST` | `/api/auth/google/callback` | Google OAuth 콜백 (ID Token) | None | `{ "id_token": "..." }` | `{ "accessToken": "...", "firstLogin": bool, "user": { ... } }` |

### 2.2. 사용자 API (Users) - ✅ 온보딩 지원

| 메서드 | 엔드포인트 | 설명 | 인증 | 요청 본문 | 응답 데이터 |
|--------|------------|------|------|-----------|-------------|
| `GET` | `/api/users/me` | 현재 사용자 정보 조회 | Required | - | `User` 객체 (추가 필드: `professorStatus`, `department`, `studentNo`, `schoolEmail`) |
| `GET` | `/api/me` | 현재 사용자 정보 조회(alias) | Required | - | `User` 객체 |
| `PUT` | `/api/users/profile` | 사용자 프로필 완성 | Required | `{ "globalRole": "STUDENT\|PROFESSOR", "nickname": "...", "profileImageUrl": "?", "bio": "?" }` | `User` 객체 |
| `POST` | `/api/users` | 첫 로그인 온보딩 정보 확정 | Required | `{ "name": "...", "nickname": "...", "dept": "?", "studentNo": "?", "schoolEmail": "...", "role": "STUDENT\|PROFESSOR" }` | `User` 객체 |
| `GET` | `/api/users/nickname-check?nickname=...` | 닉네임 중복 확인 | Required | - | `{ "available": true|false, "suggestions": ["..."] }` |

### 2.3. 그룹 API (Groups) - ✅ 새로 구현됨

| 메서드 | 엔드포인트 | 설명 | 인증 | 권한 | 요청 본문 | 응답 데이터 |
|--------|------------|------|------|------|-----------|-------------|
| `POST` | `/api/groups` | 그룹 생성 | Required | - | `{ "name": "그룹명", "description": "설명", "isPublic": true, "university": "대학명", "department": "학과명", "maxMembers": 100 }` | `Group` 객체 |
| `GET` | `/api/groups` | 그룹 목록 조회 | Required | - | - | `Group[]` |
| `GET` | `/api/groups/{groupId}` | 그룹 상세 조회 | Required | GROUP_READ | - | `Group` 객체 |
| `PUT` | `/api/groups/{groupId}` | 그룹 정보 수정 | Required | GROUP_EDIT | `{ "name": "새 이름", "description": "새 설명", ... }` | `Group` 객체 |
| `DELETE` | `/api/groups/{groupId}` | 그룹 삭제 | Required | GROUP_DELETE | - | - |

#### 2.3.1. 그룹 탐색/검색 (Explore) - ✅ 추가

| 메서드 | 엔드포인트 | 설명 | 인증 | 요청 파라미터 | 응답 데이터 |
|--------|------------|------|------|----------------|-------------|
| `GET` | `/api/groups/explore` | 그룹 탐색/검색 | Optional | `recruiting?`, `visibility?`, `university?`, `college?`, `department?`, `q?`, `tags?=tag1,tag2` | 페이지네이션 `GroupSummary[]` |

메모:
- 소프트 삭제(`deletedAt != null`)된 그룹은 노출되지 않음.
- `tags`는 OR 매칭(하나라도 포함).

### 2.4. 그룹 멤버십 API (Group Membership) - ✅ 새로 구현됨

| 메서드 | 엔드포인트 | 설명 | 인증 | 권한 | 요청 본문 | 응답 데이터 |
|--------|------------|------|------|-----------|-------------|-------------|
| `POST` | `/api/groups/{groupId}/join` | 그룹 가입 신청 | Required | - | `{ "message": "선택 입력" }` | `GroupJoinRequest` 객체 |
| `GET` | `/api/groups/{groupId}/join-requests` | 가입 신청 목록 조회 | Required | GROUP_MANAGE_MEMBERS | - | `GroupJoinRequest[]` |
| `PATCH` | `/api/groups/{groupId}/join-requests/{requestId}` | 가입 신청 처리 (승인/거절) | Required | GROUP_MANAGE_MEMBERS | `{ "action": "APPROVE\|REJECT" }` | `GroupJoinRequest` 객체 |
| `GET` | `/api/groups/{groupId}/members` | 그룹 멤버 목록 조회 | Required | GROUP_READ | - | `GroupMember[]` |
| `DELETE` | `/api/groups/{groupId}/members/{userId}` | 멤버 추방/탈퇴 | Required | GROUP_MANAGE_MEMBERS | - | - |

### 2.5. 그룹 역할 API (Group Roles) - ✅ 새로 구현됨

| 메서드 | 엔드포인트 | 설명 | 인증 | 권한 | 요청 본문 | 응답 데이터 |
|--------|------------|------|------|-----------|-------------|-------------|
| `POST` | `/api/groups/{groupId}/roles` | 커스텀 역할 생성 | Required | GROUP_MANAGE_ROLES | `{ "name": "역할명", "permissions": ["PERMISSION1", "PERMISSION2"], "priority": 100 }` | `GroupRole` 객체 |
| `GET` | `/api/groups/{groupId}/roles` | 그룹 역할 목록 조회 | Required | GROUP_READ | - | `GroupRole[]` |
| `PUT` | `/api/groups/{groupId}/roles/{roleId}` | 역할 수정 | Required | GROUP_MANAGE_ROLES | `{ "name": "새 이름", "permissions": [...], "priority": 150 }` | `GroupRole` 객체 |
| `DELETE` | `/api/groups/{groupId}/roles/{roleId}` | 역할 삭제 | Required | GROUP_MANAGE_ROLES | - | - |
| `PUT` | `/api/groups/{groupId}/members/{userId}/role` | 멤버 역할 변경 | Required | GROUP_MANAGE_MEMBERS | `{ "roleId": 123 }` | `GroupMember` 객체 |

#### 2.5.1. 멤버 개인 권한 오버라이드 - ✅ 추가

| 메서드 | 엔드포인트 | 설명 | 인증 | 권한 | 요청 본문 | 응답 데이터 |
|--------|------------|------|------|------|-----------|-------------|
| `GET` | `/api/groups/{groupId}/members/{userId}/permissions` | 개인 오버라이드 조회 | Required | `ROLE_MANAGE` | - | `{ allowed[], denied[], effective[] }` |
| `PUT` | `/api/groups/{groupId}/members/{userId}/permissions` | 개인 오버라이드 설정 | Required | `ROLE_MANAGE` | `{ allowed[], denied[] }` | `{ allowed[], denied[], effective[] }` |

메모: 유효 권한 = 역할 권한 ∪ allowed − denied.

#### 2.3.1. 하위 그룹(서브그룹) 신청/관리 - ✅ 구현됨

| 메서드 | 엔드포인트 | 설명 | 인증 | 권한 | 요청 본문 | 응답 데이터 |
|--------|------------|------|------|-----------|-------------|-------------|
| `POST` | `/api/groups/{groupId}/sub-groups/requests` | 하위 그룹 생성 신청 | Required | - | `{ "requestedGroupName": "...", "requestedGroupDescription": "...", "requestedUniversity": "...", "requestedCollege": "...", "requestedDepartment": "...", "requestedMaxMembers": 30 }` | `SubGroupRequest` |
| `GET` | `/api/groups/{groupId}/sub-groups/requests` | 하위 그룹 신청 목록 | Required | GROUP_MANAGE | - | `SubGroupRequest[]` |
| `PATCH` | `/api/groups/{groupId}/sub-groups/requests/{requestId}` | 하위 그룹 신청 처리 | Required | GROUP_MANAGE | `{ "action": "APPROVE\|REJECT", "responseMessage": "선택" }` | `SubGroupRequest` |
| `GET` | `/api/groups/{groupId}/sub-groups` | 하위 그룹 목록 조회 | Required | - | - | `Group[] (summary)` |


#### 2.3.2. 지도교수 관리 - ✅ 구현됨

| 메서드 | 엔드포인트 | 설명 | 인증 | 권한 | 요청 본문 | 응답 데이터 |
|--------|------------|------|------|-----------|-------------|-------------|
| `GET` | `/api/groups/{groupId}/professors` | 지도교수 목록 조회 | Required | - | - | `GroupMember[]` |
| `POST` | `/api/groups/{groupId}/professors/{professorId}` | 지도교수 지정 | Required | GROUP_MANAGE | - | `GroupMember` |
| `DELETE` | `/api/groups/{groupId}/professors/{professorId}` | 지도교수 해제 | Required | GROUP_MANAGE | - | - |

### 2.6. 워크스페이스 API (Workspaces) - ✅ 새로 구현됨

| 메서드 | 엔드포인트 | 설명 | 인증 | 권한 | 요청 본문 | 응답 데이터 |
|--------|------------|------|------|-----------|-------------|-------------|
| `GET` | `/api/groups/{groupId}/workspaces` | 그룹의 워크스페이스 조회 | Required | GROUP_READ | - | `Workspace[]` (1개 보장) |
| `POST` | `/api/groups/{groupId}/workspaces` | 워크스페이스 생성 | Required | GROUP_MANAGE | `{ "name": "워크스페이스명", "description": "설명" }` | `Workspace` 객체 |
| `PUT` | `/api/workspaces/{workspaceId}` | 워크스페이스 수정 | Required | GROUP_MANAGE | `{ "name": "새 이름", "description": "새 설명" }` | `Workspace` 객체 |
| `DELETE` | `/api/workspaces/{workspaceId}` | 워크스페이스 삭제 | Required | GROUP_MANAGE | - | - |

메모: 그룹이 소프트 삭제된 경우, 모든 워크스페이스/채널 접근은 `404 GROUP_NOT_FOUND`로 처리.

### 2.7. 채널 API (Channels) - ✅ 새로 구현됨

| 메서드 | 엔드포인트 | 설명 | 인증 | 권한 | 요청 본문 | 응답 데이터 |
|--------|------------|------|------|-----------|-------------|-------------|
| `POST` | `/api/workspaces/{workspaceId}/channels` | 채널 생성 | Required | GROUP_MANAGE_CHANNELS | `{ "name": "채널명", "type": "GENERAL\|ANNOUNCEMENT\|PROJECT" }` | `Channel` 객체 |
| `GET` | `/api/workspaces/{workspaceId}/channels` | 채널 목록 조회 | Required | GROUP_READ | - | `Channel[]` |
| `PUT` | `/api/channels/{channelId}` | 채널 수정 | Required | GROUP_MANAGE_CHANNELS | `{ "name": "새 이름", "type": "..." }` | `Channel` 객체 |
| `DELETE` | `/api/channels/{channelId}` | 채널 삭제 | Required | GROUP_MANAGE_CHANNELS | - | - |

### 2.8. 게시글 API (Posts) - ✅ 새로 구현됨

| 메서드 | 엔드포인트 | 설명 | 인증 | 권한 | 요청 본문 | 응답 데이터 |
|--------|------------|------|------|-----------|-------------|-------------|
| `POST` | `/api/channels/{channelId}/posts` | 게시글 작성 | Required | GROUP_POST | `{ "content": "내용", "type": "GENERAL\|QUESTION\|ANNOUNCEMENT\|NOTICE" }` | `Post` 객체 |
| `GET` | `/api/channels/{channelId}/posts` | 채널 게시글 목록 | Required | GROUP_READ | - | `Post[]` |
| `GET` | `/api/posts/{postId}` | 게시글 상세 조회 | Required | GROUP_READ | - | `Post` 객체 |
| `PUT` | `/api/posts/{postId}` | 게시글 수정 | Required | Own Post or GROUP_POST | `{ "title": "새 제목", "content": "새 내용" }` | `Post` 객체 |
| `DELETE` | `/api/posts/{postId}` | 게시글 삭제 | Required | Own Post or GROUP_DELETE | - | - |

### 2.9. 댓글 API (Comments) - ✅ 새로 구현됨

| 메서드 | 엔드포인트 | 설명 | 인증 | 권한 | 요청 본문 | 응답 데이터 |
|--------|------------|------|------|-----------|-------------|-------------|
| `POST` | `/api/posts/{postId}/comments` | 댓글 작성 | Required | GROUP_COMMENT | `{ "content": "댓글 내용", "parentCommentId": null }` | `Comment` 객체 |
| `GET` | `/api/posts/{postId}/comments` | 게시글 댓글 목록 | Required | GROUP_READ | - | `Comment[]` |
| `PUT` | `/api/comments/{commentId}` | 댓글 수정 | Required | Own Comment or GROUP_COMMENT | `{ "content": "수정된 내용" }` | `Comment` 객체 |
| `DELETE` | `/api/comments/{commentId}` | 댓글 삭제 | Required | Own Comment or GROUP_DELETE | - | - |

### 2.10. 모집 공고 API (Recruitments) - ❌ 미구현

| 메서드 | 엔드포인트 | 설명 | 인증 | 권한 | 상태 |
|--------|------------|------|------|------|------|
| `POST` | `/api/recruitments` | 모집 공고 생성 | Required | - | ❌ 미구현 |
| `GET` | `/api/recruitments` | 모집 공고 목록 | Required | - | ❌ 미구현 |
| `GET` | `/api/recruitments/{postId}` | 모집 공고 상세 | Required | - | ❌ 미구현 |
| `PUT` | `/api/recruitments/{postId}` | 모집 공고 수정 | Required | - | ❌ 미구현 |
| `DELETE` | `/api/recruitments/{postId}` | 모집 공고 삭제 | Required | - | ❌ 미구현 |

---

## 3. 권한 시스템

### 3.1. GroupPermission 열거형
```kotlin
enum class GroupPermission {
    // 그룹 기본 권한
    GROUP_READ,           // 그룹 정보 조회
    GROUP_EDIT,           // 그룹 정보 수정
    GROUP_DELETE,         // 그룹 삭제
    
    // 멤버 관리 권한
    GROUP_MANAGE_MEMBERS, // 멤버 초대/추방/승인
    GROUP_MANAGE_ROLES,   // 역할 생성/수정/삭제
    
    // 콘텐츠 권한
    GROUP_MANAGE_CHANNELS, // 채널/워크스페이스 관리
    GROUP_POST,           // 게시글 작성
    GROUP_COMMENT,        // 댓글 작성
    GROUP_DELETE_OTHERS_POSTS, // 타인의 게시글 삭제
    
    // 고급 권한
    GROUP_ADMIN           // 모든 권한
}
```

### 3.2. 기본 역할과 권한
- **OWNER**: 모든 권한
- **ADMIN**: GROUP_DELETE를 제외한 모든 권한
- **MODERATOR**: 콘텐츠 관리 및 멤버 관리 권한
- **MEMBER**: 기본적인 읽기/쓰기 권한

---

## 4. 에러 코드

### 4.1. 인증 관련
- `AUTH_001`: Invalid token
- `AUTH_002`: Token expired
- `AUTH_003`: Insufficient permissions

### 4.2. 그룹 관련
- `GROUP_001`: Group not found
- `GROUP_002`: Already member of group
- `GROUP_003`: Group capacity exceeded
- `GROUP_004`: Not a group member

### 4.3. 일반적인 에러
- `VALIDATION_001`: Invalid request data
- `SERVER_001`: Internal server error

---

이 문서는 API 구현 상황에 따라 지속적으로 업데이트됩니다.
### 2.10. 이메일 인증 API (Email Verification) - ✅ 신규

| 메서드 | 엔드포인트 | 설명 | 인증 | 요청 본문 | 응답 데이터 |
|--------|------------|------|------|-----------|-------------|
| `POST` | `/api/email/verification/send` | 학교 이메일로 OTP 발송 | Required | `{ "email": "...@hs.ac.kr" }` | `{ success: true }` |
| `POST` | `/api/email/verification/verify` | OTP 검증 및 사용자 업데이트 | Required | `{ "email": "...@hs.ac.kr", "code": "123456" }` | `{ success: true }` |

도메인 화이트리스트: `app.school-email.allowed-domains` (기본값: `hs.ac.kr`)

오류 코드 표준: `E_BAD_DOMAIN`, `E_OTP_MISMATCH`, `E_OTP_EXPIRED`, `E_DUP_NICK`

### 2.11. 역할 신청 API (Roles) - ✅ 신규

| 메서드 | 엔드포인트 | 설명 | 인증 | 요청 본문 | 응답 데이터 |
|--------|------------|------|------|-----------|-------------|
| `POST` | `/api/roles/apply` | 역할 신청(교수는 승인 대기) | Required | `{ "role": "PROFESSOR" }` | `{ success: true }` |
### 2.11. 관리자 API (Admin) - ⏳ 추가 예정

| 메서드 | 엔드포인트 | 설명 | 인증 | 권한 | 응답 |
|--------|------------|------|------|------|------|
| `GET` | `/api/admin/group-requests` | 공식 그룹 신청 목록 | Required | ADMIN | `GroupRequest[]` |
| `PATCH` | `/api/admin/group-requests/{id}` | 공식 그룹 신청 처리 | Required | ADMIN | `GroupRequest` |
| `GET` | `/api/admin/join-requests` | 멤버 가입 신청 전체 목록 | Required | ADMIN | `JoinRequest[]` |
| `PATCH` | `/api/admin/join-requests/{id}` | 멤버 가입 신청 처리 | Required | ADMIN | `JoinRequest` |

### 2.12. 마이페이지 API (My) - ⏳ 추가 예정

| 메서드 | 엔드포인트 | 설명 | 인증 | 응답 |
|--------|------------|------|------|------|
| `GET` | `/api/users/me/join-requests` | 내 가입 신청 목록 | Required | `JoinRequest[]` |
| `GET` | `/api/users/me/sub-group-requests` | 내 하위 그룹 신청 목록 | Required | `SubGroupRequest[]` |


---
## File: context/architecture-overview.md

# System Architecture Overview

**⚠️ 현재 구현 상태**: 이 문서는 프론트엔드 코드가 제거된 현재의 백엔드 전용 아키텍처를 반영하여 업데이트되었습니다.

---

## 1. General Architecture & Deployment

- **Tech Stack**:
    - **Backend**: Spring Boot with Kotlin.
    - **Database**: RDBMS (H2 for dev, planned for AWS RDS for prod).

- **Deployment Architecture (AWS)**:
    - A minimal setup using **EC2 (Server) + RDS (DB) + S3 (Build Storage)**.
    - The project is deployed as a standalone JAR file, serving a RESTful API.

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

- **`Controller`**: Handles HTTP requests/responses and performs first-pass syntactic validation on DTOs (`@Valid`).
- **`Service`**: Contains all business logic, manages transactions (`@Transactional`), and is solely responsible for converting between DTOs and Entities.
- **`Repository`**: Manages data persistence (CRUD) by communicating directly with the database.

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

### 2.3. Authentication & Authorization

- **Authentication Flow**: 
    1. A client gets a **Google Auth ID Token**.
    2. This token is sent to the backend (`POST /api/auth/google/callback`).
    3. Backend validates the token with Google, finds or creates a user in the DB.
    4. Backend generates and returns a service-specific **JWT Access Token**.
    5. The client sends this JWT in the `Authorization: Bearer <JWT>` header for all subsequent requests.
- **Authorization Strategy**:
    - Spring Method Security (`@PreAuthorize`).
    - Custom `PermissionEvaluator` for group-specific permissions (e.g., `@security.hasGroupPerm(#groupId, 'EDIT_GROUP')`).
    - Separation of global roles and group-specific roles.

### 2.4. Exception Handling & Logging

- **Global Exception Handling**: A central `@RestControllerAdvice` class catches all exceptions and translates them into the standard error JSON format.
- **Logging Strategy (SLF4J + Logback)**: Standard level-based logging with daily rotation.

### 2.5. Testing Strategy

- **Pyramid Focus**: The strategy prioritizes **Integration Tests** over Unit Tests.
- **Environment**: Tests run against an **H2 in-memory database** for speed and isolation.
- **Structure**: An `IntegrationTest` base class provides common setup, and a `DatabaseCleanup` component ensures each test runs on a clean DB.

---

## 3. API Endpoint Specifications

API 엔드포인트 명세는 이제 각 기능별 명세서에서 관리됩니다. 최신 정보는 아래 문서들을 참고하십시오:

- `docs/설계 문서/기능명세서/`

---
## File: context/database-design.md

# Database Design (Entity Relationship Diagram)

This document outlines the current database schema implementation status. 

**⚠️ 현재 구현 상태**: 문서 기반 엔티티 정리 완료 (2025-09-12)
- GroupInvite 엔티티 삭제 (문서에 정의되지 않음)
- GroupPermission을 기존 14개 권한으로 축소
- Group, Channel, Post, Comment 엔티티 확장 구현 완료

## High-Level Summary

현재 구현된 도메인:
1.  **Users**: 기본 사용자 관리 (Google OAuth2 인증, GlobalRole)
2.  **Group Auth Scaffolding**: 그룹/멤버/그룹역할/권한 카탈로그 스키마 기본 골격
3.  **Groups & Content**: 그룹 상세, 채널, 게시글, 댓글 관리 (엔티티 구현 완료)

계획된 도메인 (미구현):
4.  **Recruitment & System**: 모집 공고, 태그, 알림 시스템 (엔티티 미구현)

---

## 1. Users (현재 구현됨)

### User (사용자) - ✅ 구현됨
**실제 구현된 스키마:**
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 사용자 고유 번호 |
| `email` | VARCHAR(100) | Not Null, **Unique** | 이메일 주소 (Google OAuth2 로그인) |
| `name` | VARCHAR(50) | Not Null | 실명 |
| `nickname` | VARCHAR(50) | | 사용자 닉네임 |
| `profile_image_url` | VARCHAR(500) | | 프로필 이미지 URL |
| `bio` | VARCHAR(500) | | 자기소개 |
| `password_hash` | VARCHAR(255) | Not Null | 패스워드 해시 (현재 사용되지 않음) |
| `global_role` | ENUM | Not Null | 전역 역할 (STUDENT, PROFESSOR, ADMIN) |
| `profile_completed` | BOOLEAN | Not Null | 프로필 완성 여부 (기본값: false) |
| `email_verified` | BOOLEAN | Not Null | 이메일 인증 여부 (기본값: true, OTP는 후순위) |
| `department` | VARCHAR(100) | | 학과 |
| `student_no` | VARCHAR(30) | | 학번 |
| `school_email` | VARCHAR(100) | | 학교 이메일 (도메인 `hs.ac.kr` 권장) |
| `professor_status` | ENUM | | 교수 승인 상태 (PENDING, APPROVED, REJECTED) |
| `is_active` | BOOLEAN | Not Null | 계정 활성화 상태 |
| `created_at` | DATETIME | Not Null | 생성 일시 |
| `updated_at` | DATETIME | Not Null | 수정 일시 |

**최근 업데이트 (2025-09-13):**
- ✅ 온보딩 단일 화면 대응 필드 추가: `department`, `student_no`, `school_email`, `professor_status`
- ✅ `email_verified` 기본값 true (메일 인증은 MVP 말로 이연)
- ✅ UserResponse에 확장 필드 노출
  
과거 업데이트 (2025-09-11):
- nickname, profile_image_url, bio 필드 추가
- profile_completed 필드 추가 (회원가입 플로우 제어용)
- email_verified 필드 추가

---

## 2. Group Auth Scaffolding (부분 구현)

### Group (그룹) - ✅ 확장 구현됨
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 그룹 고유 번호 |
| `name` | VARCHAR(100) | Not Null, **Unique** | 그룹 이름 |
| `description` | VARCHAR(500) | | 그룹 소개 |
| `profile_image_url` | VARCHAR(500) | | 그룹 프로필 이미지 URL |
| `owner_id` | BIGINT | Not Null, **FK** (User.id) | 그룹 소유자 ID |
| `visibility` | ENUM | Not Null | 공개 설정 (PUBLIC, PRIVATE, INVITE_ONLY) |
| `is_recruiting` | BOOLEAN | Not Null | 모집 중 여부 |
| `max_members` | INT | | 최대 멤버 수 제한 |
| `tags` | ElementCollection | | 그룹 태그 집합 |
| `created_at` | DATETIME | Not Null | 생성 일시 |
| `updated_at` | DATETIME | Not Null | 수정 일시 |
| `deleted_at` | DATETIME | | 소프트 삭제 일시 (30일 보존 후 영구 삭제) |

### GroupRole (그룹 역할) - ✅ 구현됨
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 역할 고유 번호 |
| `group_id` | BIGINT | Not Null, **FK** (Group.id) | 소속 그룹 |
| `name` | VARCHAR(50) | Not Null | 역할 이름 (그룹별 유니크) |
| `is_system_role` | BOOLEAN | Not Null | 시스템 역할 여부 (기본값: false) |
| `permissions` | ElementCollection | | 권한 집합 (group_role_permissions 테이블)

### GroupMember (그룹 멤버) - ✅ 구현됨
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 멤버 관계 고유 번호 |
| `group_id` | BIGINT | Not Null, **FK** (Group.id) | 그룹 ID (사용자별 유니크) |
| `user_id` | BIGINT | Not Null, **FK** (User.id) | 사용자 ID |
| `role_id` | BIGINT | Not Null, **FK** (GroupRole.id) | 그룹 내 역할 ID |
| `joined_at` | DATETIME | Not Null | 가입 일시 (기본값: 현재 시간) |

### GroupMemberPermissionOverride (개인 권한 오버라이드) - ✅ 추가
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 오버라이드 고유 번호 |
| `group_id` | BIGINT | Not Null, **FK** (Group.id) | 그룹 ID |
| `user_id` | BIGINT | Not Null, **FK** (User.id) | 사용자 ID |
| `allowed_permissions` | ElementCollection | | 추가로 허용된 권한 (열거형 컬렉션) |
| `denied_permissions` | ElementCollection | | 명시적으로 차단된 권한 (열거형 컬렉션) |

유효 권한 계산: `effective = role.permissions ∪ allowed − denied`.

### GroupPermission (권한 열거형) - ✅ 구현됨
**현재 정의된 14개 권한:**
- `GROUP_MANAGE`: 그룹 관리 권한
- `MEMBER_READ`: 멤버 조회 권한
- `MEMBER_APPROVE`: 멤버 승인 권한
- `MEMBER_KICK`: 멤버 제명 권한
- `ROLE_MANAGE`: 역할 관리 권한
- `CHANNEL_READ`: 채널 읽기 권한
- `CHANNEL_WRITE`: 채널 쓰기 권한
- `POST_CREATE`: 게시글 작성 권한
- `POST_UPDATE_OWN`: 자신의 게시글 수정 권한
- `POST_DELETE_OWN`: 자신의 게시글 삭제 권한
- `POST_DELETE_ANY`: 모든 게시글 삭제 권한
- `RECRUITMENT_CREATE`: 모집 공고 작성 권한
- `RECRUITMENT_UPDATE`: 모집 공고 수정 권한
- `RECRUITMENT_DELETE`: 모집 공고 삭제 권한

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

## 3. Groups & Content - ✅ 구현됨

**최근 업데이트 (2025-09-12):** 문서 정의에 따른 엔티티 정리 완료
- GroupInvite 엔티티 삭제 (문서에 정의되지 않음)
- GroupPermission을 기존 14개 권한으로 복구
- Group, Channel, Post, Comment 엔티티는 확장된 기능과 함께 구현 완료

### Group (그룹) - ✅ 구현됨
**실제 구현된 스키마:**
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 그룹 고유 번호 |
| `name` | VARCHAR(100) | Not Null, **Unique** | 그룹 이름 |
| `description` | VARCHAR(500) | | 그룹 소개 |
| `profile_image_url` | VARCHAR(500) | | 그룹 프로필 이미지 URL |
| `owner_id` | BIGINT | Not Null, **FK** (User.id) | 그룹 소유자 ID |
| `visibility` | ENUM | Not Null | 공개 설정 (PUBLIC, PRIVATE, INVITE_ONLY) |
| `is_recruiting` | BOOLEAN | Not Null | 모집 중 여부 (기본값: false) |
| `max_members` | INT | | 최대 멤버 수 제한 |
| `tags` | ElementCollection | | 그룹 태그 집합 (group_tags 테이블) |
| `created_at` | DATETIME | Not Null | 생성 일시 |
| `updated_at` | DATETIME | Not Null | 수정 일시 |

### Channel (채널) - ✅ 구현됨
**실제 구현된 스키마:**
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 채널 고유 번호 |
| `group_id` | BIGINT | Not Null, **FK** (Group.id) | 채널이 속한 그룹 ID |
| `name` | VARCHAR(100) | Not Null | 채널 이름 (그룹별 유니크) |
| `description` | VARCHAR(500) | | 채널 설명 |
| `type` | ENUM | Not Null | 채널 타입 (TEXT, VOICE, ANNOUNCEMENT, FILE_SHARE) |
| `is_private` | BOOLEAN | Not Null | 비공개 채널 여부 (기본값: false) |
| `display_order` | INT | Not Null | 채널 정렬 순서 |
| `created_by` | BIGINT | Not Null, **FK** (User.id) | 채널 생성자 ID |
| `created_at` | DATETIME | Not Null | 생성 일시 |
| `updated_at` | DATETIME | Not Null | 수정 일시 |

### Post (게시글) - ✅ 구현됨
**실제 구현된 스키마:**
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 게시글 고유 번호 |
| `channel_id` | BIGINT | Not Null, **FK** (Channel.id) | 게시글이 등록된 채널 ID |
| `author_id` | BIGINT | Not Null, **FK** (User.id) | 작성자 ID |
| `title` | VARCHAR(200) | Not Null | 제목 |
| `content` | TEXT | Not Null | 내용 |
| `type` | ENUM | Not Null | 게시글 타입 (GENERAL, ANNOUNCEMENT, QUESTION, POLL, FILE_SHARE) |
| `is_pinned` | BOOLEAN | Not Null | 고정 여부 (기본값: false) |
| `view_count` | BIGINT | Not Null | 조회수 (기본값: 0) |
| `like_count` | BIGINT | Not Null | 좋아요 수 (기본값: 0) |
| `attachments` | ElementCollection | | 첨부 파일 URL 집합 (post_attachments 테이블) |
| `created_at` | DATETIME | Not Null | 생성 일시 |
| `updated_at` | DATETIME | Not Null | 수정 일시 |

### Comment (댓글) - ✅ 구현됨
**실제 구현된 스키마:**
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 댓글 고유 번호 |
| `post_id` | BIGINT | Not Null, **FK** (Post.id) | 부모 게시글 ID |
| `author_id` | BIGINT | Not Null, **FK** (User.id) | 작성자 ID |
| `content` | TEXT | Not Null | 내용 |
| `parent_comment_id` | BIGINT | **FK** (self-reference) | 부모 댓글 ID (대댓글 구조) |
| `like_count` | BIGINT | Not Null | 좋아요 수 (기본값: 0) |
| `created_at` | DATETIME | Not Null | 생성 일시 |
| `updated_at` | DATETIME | Not Null | 수정 일시 |

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

# 기능 명세 종합 (Master Feature List)

**본 문서는 `docs/설계 문서/기능명세서`에 정의된 모든 기능의 핵심 사항을 종합하고, 현재 구현 상태를 추적하기 위해 작성되었습니다.**

---

## 1. 회원가입 / 로그인 (Sign-up / Login)

- **상태:** 핵심 구현 완료 ✅, 일부 보완 후순위 ⚠️ (이메일 OTP, 교수 승인)
- **개요(업데이트):** Google 로그인 후 첫 로그인 사용자에게 단일 온보딩 화면에서 프로필·역할·학적·학교 이메일을 한 번에 수집. 교수 선택 시 승인 대기(PENDING)로 표기되며 홈 상단 배너로 안내. 학교 이메일 인증(OTP)은 MVP 말로 이연되며 도메인은 `hs.ac.kr`만 허용.
- **핵심 UX:** `한 화면 = 한 목표`. 온보딩 단일 화면에 다음 항목 포함: 실명, 닉네임(중복 확인/제안), 학과, 학번, 역할 선택(학생/교수), 학교 이메일(힌트만 표시).
- **주요 기능:**
    - **Google OAuth2 인증:** `/api/auth/google/callback { id_token }` 우선 사용, 필요 시 `/api/auth/google` 폴백.
    - **단일 온보딩 제출:** `POST /api/users { name, nickname, dept?, studentNo?, schoolEmail, role }` → 성공 시 `/api/me`로 갱신.
    - **닉네임 중복 확인:** `GET /api/users/nickname-check?nickname=...` 디바운스(400ms) + 제안 칩 노출.
    - **교수 선택 시 처리:** 서버에서 `professorStatus=PENDING` 설정, 홈 상단 고정 배너로 안내.
    - **JWT 기반 인증:** 액세스 토큰 저장 및 자동 헤더 주입.
- **개발 단계 임시 정책:**
    - 가입 시 소속 부서는 기본값으로 `AI/SW 학부`가 적용됩니다(입력값이 없을 때).
    - 기본 그룹(한신대학교 → AI/SW 대학 → AI/SW 학부)이 자동 생성되며, 프로필 제출 시 `AI/SW 학부` 그룹에 자동 가입됩니다.

- **후순위(이연) 기능:**
    - **학교 이메일 인증(OTP):** `POST /api/email/verification/send|verify` 엔드포인트 준비, UI/플로우는 MVP 말 구현. 허용 도메인: `hs.ac.kr`.
    - **교수 역할 승인:** 관리자 승인/반려 워크플로우 및 UI.

---

## 2. 그룹 / 워크스페이스 (Group / Workspace)

- **상태:** 핵심 구현 완료 ✅ (워크스페이스 관리 기능 완성)
- **개요:** 사용자들이 커뮤니티(그룹)를 형성하고, 각 그룹은 슬랙과 유사한 **단일 워크스페이스(1:1)** 를 갖습니다. 워크스페이스 내부에는 **여러 채널**을 생성할 수 있으며, 채널별 권한(읽기/작성/관리)에 따라 접근과 작성 권한을 제한합니다.
- **주요 기능:**
    - **최상위 그룹 생성:** 시스템 관리자가 대학, 단과대 등 기본 조직 그룹을 생성.
    - **하위 그룹 생성 신청:** 일반 사용자가 상위 그룹 내에 소속될 하위 그룹(스터디, 팀 등) 생성을 신청.
    - **승인 워크플로우:** 상위 그룹의 그룹장이 하위 그룹 생성 신청을 승인/반려.
    - **그룹장 유고 처리:** 그룹장 부재 시, 가입일 및 학년 기준으로 임시 그룹장 자동 위임.
    - **그룹 상세/가입 신청 (신규):** 프론트에 그룹 상세 화면(`/group`) 추가, 가입 신청 시 `message` 본문(optional) 포함 전송.
- **데이터 정책(초기 단계):**
    - 그룹 삭제: **단순 삭제** 정책. 그룹 및 관련 워크스페이스/채널/게시글/댓글이 즉시 삭제됨. (하위 그룹 삭제 동작은 관리자 정책에 따라 연쇄 삭제. 향후 보존 기능 검토 가능)
    - 사용자 탈퇴: 작성한 게시물/댓글은 `(탈퇴한 사용자)`로 익명화 처리.

### 구현 완료된 기능 (핵심 워크스페이스 관리)
- **백엔드 완전 구현:**
  - 그룹/워크스페이스 CRUD API 완성
  - 멤버 관리 API (가입/승인/반려/역할변경/강제탈퇴) 구현
  - 하위 그룹 생성 신청 및 관리 API 구현
  - 그룹 탐색/검색 API (`/api/groups/explore`) 구현
  - 개인별 권한 오버라이드 시스템 구현
  - 소프트 삭제 및 리패런팅 정책 구현
  - 채널 관리 API (생성/수정/삭제/권한설정) 구현
  - 워크스페이스 1:1 매핑 완성 (그룹당 기본 워크스페이스 자동 생성)

- **프론트엔드 최소 구현:**
  - 그룹 목록(`/groups`) → 그룹 상세(`/group`) 라우팅 구현
  - 그룹 탐색(`/explore`) 화면: 검색어/태그/모집중 필터 + 계층 트리(대학교→단과대→학부) + 결과 리스트
  - 모집 전용 탭(`/recruitment`): 모집중 필터 고정 리스트
  - 그룹 상세 화면에서 가입 신청 메시지 입력 및 전송 지원

### 관리자 및 신청/승인
- **관리자 탭 추가:** 공식 그룹 신청, 멤버 가입 신청을 처리하는 관리자 탭을 추가(권한 가드).
- **내 신청 현황:** 마이페이지에 '내 신청 현황' 간단 목록(가입 신청/하위 그룹 신청) 추가.

### 채널/게시글/댓글
- **채널 권한:** 채널 관리 권한 보유자가 채널 생성/수정/삭제 등 관리. 채널 가시성/작성 권한을 채널 단위로 제한.
- **핀 기능:** 사용하지 않음(비활성).
- 백엔드:
  - 그룹/멤버/역할/하위 그룹 신청 API 구현
  - 워크스페이스/채널/게시글/댓글 컨트롤러 기본 구현 및 그룹 상세에 연동 (그룹당 기본 워크스페이스 호환)
  - 멤버 역할 변경/강제 탈퇴 엔드포인트 구현
  - 하위 그룹 신청/관리/조회 엔드포인트 구현
  - 신규: 그룹 탐색/검색 API(`/api/groups/explore`) 추가, 멤버 개인 권한 오버라이드 GET/PUT 추가

### 미구현/개선 예정 (프론트엔드 UI 중심)
- 가입 신청 관리(목록/승인/반려) UI 완성
- 멤버 관리 UI (역할 변경, 강제 탈퇴) 완성
- 역할 관리 폼(생성/삭제) UI 완성
- 하위 그룹 생성 신청 및 관리 UI 완성
- 지도교수 관리 UI (검색/지정/해제) 완성
- 그룹 삭제 UX (바텀 시트 확인 + 빨간색 버튼) 완성
- 워크스페이스 내 채널/게시글/댓글 UI 연동 완성

---

## 3. 권한 및 멤버 관리 (Permissions & Member Management)

- **상태:** 핵심 구현 완료 ✅ (권한 시스템 및 개인 오버라이드 완성)
- **개요:** 역할 기반 접근 제어(RBAC) 시스템. 그룹장이 커스텀 역할을 생성하고 권한을 부여.
- **고정 역할:**
    - **그룹장:** 그룹의 모든 권한을 가지며 수정 불가. (그룹 정보 수정, 그룹 삭제 등 고유 권한 보유)
    - **일반 멤버:** 가입 시 기본 부여되는 역할. (게시글 조회/작성 등 기본 권한)
- **커스텀 역할 권한 목록 (MVP):**
    - **모집 관리:** 가입 신청 처리 및 모집 공고 관리.
    - **멤버 관리:** 멤버 역할 변경 및 강제 탈퇴.
    - **채널 관리:** 채널 생성/수정/삭제 및 타인 게시물 관리.
- **관리 화면:**
    - 멤버 목록, 역할 변경(드롭다운), 강제 탈퇴, 그룹장 위임 기능 제공.
    - 가입 대기자 승인/거절 기능 제공.
    - 신규: 특정 멤버에 대해 역할 권한을 **개인 오버라이드(허용/차단)**로 미세 조정 가능.

---

## 4. 홍보 / 모집 (Promotion / Recruitment)

- **상태:** 미구현 ❌
- **개요:** 서비스 내 별도 '모집' 게시판을 통해 그룹 홍보 및 신규 멤버 모집.
- **주요 기능:**
    - **모집 공고 작성:** 제목, 본문, 모집 기간, 모집 인원, 태그 등 필수 정보 입력.
    - **게시 정책:** 한 그룹은 동시에 **하나의 활성 공고**만 게시 가능.
    - **상태 관리:** 모집 기간 종료 시 자동으로 '마감' 처리 및 목록에서 비공개.
    - **지원 방법:** 별도 지원서 없이, 공고를 통해 그룹 페이지로 이동 후 '가입 신청' 기능을 재사용.
- **UI/UX:**
    - 활성 공고가 있을 경우, 새 공고 작성 시도 시 안내 메시지와 함께 차단.

---

## 5. 게시글 / 댓글 (Posts / Comments)

- **상태:** 미구현 ❌
- **개요:** 워크스페이스 내 채널에서 사용하는 실시간 채팅 형식의 소통 기능.
- **구조:**
    - **채팅 형식:** 최신 메시지가 하단에 표시되고, 입력창은 하단에 고정.
    - **게시물:** 제목 없이 본문만으로 구성. (작성자, 시간, 본문, 반응, 댓글 수)
    - **댓글:** **1단계 댓글(대댓글 미지원)**만 구현. (단, DB 스키마는 `parent_comment_id` 필드를 포함하여 확장성 확보)
- **주요 기능:**
    - **CRUD:** 자신이 작성한 게시물/댓글만 수정/삭제 가능.
    - **관리자 중재:** '채널 관리' 권한 보유자는 타인의 게시물/댓글 삭제 가능.
- **삭제 정책:** 부모 댓글 삭제 시, 모든 대댓글도 함께 영구 삭제.

---

## 6. 알림 시스템 (Notification System)

- **상태:** 미구현 ❌
- **개요:** 사용자의 주요 활동 및 상호작용에 대한 실시간 알림.
- **기술/정책:**
    - **구조화된 데이터:** 모든 알림 정보를 구조화하여 저장 (향후 '개인화 홈' 기능에 활용).
    - **데이터 보관:** 생성 후 90일이 지난 알림은 자동 삭제.
- **UI/UX:**
    - 상단 헤더에 종(🔔) 아이콘과 읽지 않은 알림(빨간 점) 표시.
    - 아이콘 클릭 시 드롭다운 목록 표시, 목록을 여는 순간 '읽음' 처리.
    - 알림 클릭 시 관련 페이지로 이동.
- **알림 종류 (MVP):**
    - 그룹 가입 신청 결과 (승인/거절).
    - 새로운 그룹 가입 신청 접수.
    - 내 역할 변경.

---

## 7. 관리자 페이지 (Admin Page)

- **상태:** 미구현 ❌
- **개요:** 권한을 가진 사용자를 위한 그룹 관리 기능 모음.
- **핵심 UX:** `Toss UI/UX 적용`.
    - **관리 홈:** 아이콘과 설명이 포함된 카드/리스트 형태의 메뉴. (`가입 대기 N명` 등 맥락 정보 표시)
    - **한 화면 설정:** 역할/채널 생성 시 여러 단계의 복잡한 흐름 대신, 한 페이지 내에서 모든 설정을 완료하고 저장.
    - **강력한 확인 절차:** 그룹 삭제 시 바텀 시트(Bottom Sheet)를 통해 삭제될 데이터를 명확히 안내하고, 빨간색 버튼으로 최종 확인.
- **MVP 기능 목록:**
    - 멤버 관리, 역할 관리, 채널 관리, 지도교수 관리, 그룹 정보 수정, 그룹 삭제.

---

## 8. 사용자 프로필 및 계정 관리 (User Profile & Account)

- **상태:** 부분 구현 ⚠️
- **개요:** 사용자 정보 조회, 프로필 수정 및 계정 설정.
- **구현 완료된 기능:**
    - **프로필 초기 설정:** 회원가입 시 닉네임, 프로필 사진(URL), 자기소개 입력.
    - **내 정보 조회 API:** `/api/users/me` 엔드포인트.
- **미구현 및 개선 필요 기능:**
    - **프로필 수정:** 가입 후 프로필 사진, 닉네임, 한 줄 소개 수정 기능.
    - **서비스 탈퇴:**
        - **UI/UX 변경:** "탈퇴하겠습니다" 문구 입력 대신, **바텀 시트**를 통한 결과 안내 및 **빨간색 [탈퇴하기] 버튼**으로 최종 확인.
        - **데이터 처리:** 사용자가 작성한 게시물/댓글은 `(탈퇴한 사용자)`로 익명화.


---
## File: context/frontend-architecture.md

# Deprecated

This file is deprecated as the frontend has been removed from the project.

---
## File: context/frontend-auth-web-error-archive.md

# Deprecated

This file is deprecated as the frontend has been removed from the project.

---
## File: context/frontend-maintenance.md

# Deprecated

This file is deprecated as the frontend has been removed from the project.

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
- **✅ 완료**: 인증 시스템 (Google OAuth + JWT), 단일 온보딩 UI(닉네임 중복 확인 포함)
- **(삭제됨)**: Flutter Frontend 기초 구조
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

## 3. MVP 우선순위/이연 항목 (인증 관련)

- ✅ 단일 온보딩 화면 도입: `POST /api/users`로 일괄 제출, 제출 후 `/api/me` 갱신
- ✅ 닉네임 중복 확인: `GET /api/users/nickname-check` 연동 및 제안 칩 UX
- ⚠️ 이메일 인증(OTP) 이연: UI/플로우는 MVP 말 구현, 서버 엔드포인트만 준비(`send/verify`), 허용 도메인 `hs.ac.kr`
- ⚠️ 교수 역할 승인 이연: 관리자 승인/반려 플로우 및 UI는 후순위, 승인 전까지 `professorStatus=PENDING` 배너 노출

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
## File: context/security.md

# 보안 설정 가이드

## 1. 인증 및 권한 부여

### JWT 기반 인증
- JWT 토큰을 사용한 Stateless 인증 방식 채택
- Google OAuth2와 연동하여 외부 인증 공급자 활용
- JwtAuthenticationFilter를 통한 토큰 검증

### 권한 관리 (업데이트)
- Spring Security의 Method-level 보안 활용 (@PreAuthorize)
- GlobalRole과 GroupRole을 통한 역할 기반 접근 제어 (RBAC)
- Custom PermissionEvaluator(`GroupPermissionEvaluator`)로 세밀 권한 검증
  - 전역 관리자(`ROLE_ADMIN`)는 즉시 통과
  - 그룹 멤버의 역할 권한을 가져와 시스템 역할이면 내장 권한 집합을 사용
  - 개인 오버라이드가 존재할 경우: `effective = rolePermissions ∪ allowed − denied`
  - `@security.hasGroupPerm(#groupId, 'PERMISSION')` 표현식으로 사용

## 2. 패스워드 보안

### PasswordEncoder Bean 설정 규칙
프로젝트에서 패스워드 암호화가 필요한 경우, 다음 규칙을 따라 PasswordEncoder Bean을 설정해야 합니다:

```kotlin
@Bean
fun passwordEncoder(): PasswordEncoder {
    return BCryptPasswordEncoder()
}
```

**규칙 및 권장사항:**
- **필수**: BCryptPasswordEncoder 사용 (Spring Security 권장)
- **금지**: PlainTextPasswordEncoder, MD5, SHA-1 등 취약한 알고리즘 사용 금지
- **위치**: SecurityConfig 클래스 내 Bean으로 정의
- **용도**: 사용자 패스워드 저장 시 암호화, 로그인 시 패스워드 검증
- **주의사항**: 현재 프로젝트는 Google OAuth2 전용으로, 직접 패스워드 저장/검증 기능은 없음

### 패스워드 정책
향후 직접 회원가입 기능 추가 시 적용할 패스워드 정책:
- 최소 8자 이상
- 영문 대/소문자, 숫자, 특수문자 중 3종류 이상 포함
- 연속된 문자 3자리 이상 금지
- 사용자 정보(이름, 이메일 등)와 유사한 패스워드 금지

## 3. CORS 설정

### 개발 환경
- localhost의 모든 포트 허용 (패턴 기반)
- 모든 HTTP 메서드 및 헤더 허용
- Credentials 비활성화 (JWT 토큰 기반으로 충분)

### 운영 환경 (향후 적용)
- 특정 도메인만 허용
- 필요한 메서드/헤더만 허용
- 보안 헤더 강화

## 4. 세션 관리

- **Stateless**: SessionCreationPolicy.STATELESS 설정
- **JWT 토큰**: 클라이언트 측에서 토큰 저장 및 관리
- **토큰 만료**: 적절한 만료 시간 설정으로 보안성 확보

## 5. API 엔드포인트 보안

### Public 엔드포인트
- `/api/auth/google` - Google OAuth2 인증 (레거시 페이로드)
- `/api/auth/google/callback` - Google OAuth2 인증 (ID Token 콜백)
- `/swagger-ui/**`, `/v3/api-docs/**` - API 문서
- `/h2-console/**` - 개발용 H2 데이터베이스 콘솔
- `OPTIONS` 메서드 - CORS preflight 요청

### Protected 엔드포인트
- 위 Public 엔드포인트를 제외한 모든 API
- JWT 토큰을 통한 인증 필수
- Method-level 보안을 통한 세밀한 권한 제어
- 예시: `@PreAuthorize("@security.hasGroupPerm(#groupId, 'ROLE_MANAGE')")`

### 채널/워크스페이스 권한 범주 (제안)
- Workspace: `WORKSPACE_READ`, `WORKSPACE_MANAGE`
- Channel: `CHANNEL_READ`, `CHANNEL_CREATE`, `CHANNEL_UPDATE`, `CHANNEL_DELETE` (관리), `CHANNEL_INVITE` (초대는 관리와 별도로 분리, 채널 manage에 포함되지 않음)
- Post: `POST_CREATE`, `POST_UPDATE_OWN`, `POST_DELETE_OWN`, `POST_DELETE_ANY`
- Comment: `COMMENT_CREATE`, `COMMENT_UPDATE_OWN`, `COMMENT_DELETE_OWN`, `COMMENT_DELETE_ANY`

핀 기능은 사용하지 않음. 채널/게시글 권한은 역할 및 개인 오버라이드로 최종 결정됩니다.

### 이메일 인증 도메인 정책
- 허용 도메인(서버 설정): `app.school-email.allowed-domains: hs.ac.kr`
- 프론트엔드 힌트: `@hs.ac.kr`만 표시 (실제 검증은 서버가 수행)

## 6. 보안 헤더

### 현재 설정
- `X-Frame-Options: SAMEORIGIN` - H2 Console 사용을 위해 설정

### 향후 강화 예정
- Content Security Policy (CSP)
- X-Content-Type-Options: nosniff
- X-XSS-Protection: 1; mode=block
- Strict-Transport-Security (HTTPS 적용 시)

## 7. 개발 vs 운영 환경 보안 차이

### 개발 환경 (현재)
- H2 Console 접근 허용
- 넓은 범위의 CORS 설정
- 상세한 오류 메시지 노출

### 운영 환경 (향후)
- H2 Console 비활성화
- 제한적 CORS 설정
- 오류 메시지 최소화
- HTTPS 강제 적용
- 보안 헤더 강화

## 8. 모니터링 및 로깅

### 보안 이벤트 로깅
- 인증 실패 시도
- 권한 없는 리소스 접근 시도
- 토큰 관련 오류

### 모니터링 대상
- 비정상적인 API 호출 패턴
- 반복된 인증 실패
- 권한 상승 시도


---
## File: context/troubleshooting.md

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

## 4. 워크스페이스 관리 기능 가이드

### 4.1. 워크스페이스/그룹 관리 기능 트러블슈팅

**증상**: 워크스페이스 관련 기능이 정상적으로 동작하지 않거나 권한 오류가 발생합니다.

**확인 사항**:
1. **그룹 멤버십 확인**: 사용자가 해당 그룹의 멤버인지 확인합니다.
2. **권한 검증**: 요청하는 작업에 필요한 권한(GroupPermission)을 보유하고 있는지 확인합니다.
3. **역할 및 개인 권한 오버라이드**: 멤버의 역할 권한과 개인별 권한 오버라이드 설정을 확인합니다.

**해결 방법**:
- **멤버 관리 API 사용**: `/api/groups/{groupId}/members` 엔드포인트를 통해 멤버 목록과 권한 상태를 확인합니다.
- **권한 오버라이드 API**: `/api/groups/{groupId}/members/{userId}/permissions` 엔드포인트를 통해 개인별 권한 설정을 조회하고 수정합니다.
- **그룹 탐색 기능**: `/api/groups/explore` 엔드포인트를 사용하여 그룹 검색 및 필터링을 구현합니다.

### 4.2. 채널 관리 관련 문제

**증상**: 채널 생성, 수정, 삭제 기능에서 오류가 발생합니다.

**원인 및 해결방법**:
- **워크스페이스 존재 확인**: 그룹에 연결된 워크스페이스가 존재하는지 확인합니다. 그룹 생성 시 자동으로 워크스페이스가 생성되어야 합니다.
- **채널 권한 확인**: `CHANNEL_MANAGE` 권한이 있는지 확인합니다.
- **기본 채널 정책**: 그룹 생성 시 '공지채널'과 '자유채널'이 기본으로 생성되는지 확인합니다.

### 4.3. 멤버 관리 및 권한 문제

**증상**: 멤버 역할 변경, 강제 탈퇴 등의 기능이 작동하지 않습니다.

**해결 단계**:
1. **그룹장 권한 확인**: 현재 사용자가 그룹장이거나 `MEMBER_MANAGE` 권한을 보유하고 있는지 확인합니다.
2. **대상 멤버 상태 확인**: 대상 멤버가 현재 그룹에 속해 있고 `APPROVED` 상태인지 확인합니다.
3. **권한 오버라이드 적용**: 개인별 권한 오버라이드가 올바르게 적용되고 있는지 확인합니다.

**로깅 및 디버깅**:
```kotlin
// 권한 확인 로깅 예시
@PreAuthorize("@security.hasGroupPerm(#groupId, 'MEMBER_MANAGE')")
fun updateMemberRole(groupId: Long, userId: Long, roleId: Long) {
    logger.debug("Checking MEMBER_MANAGE permission for group: $groupId, user: $userId")
    // 구현 로직
}
```

---

## 5. 문제 해결이 안 될 때

### 4.1. 이슈 보고 전 체크리스트

1.  **로그 수집**: 에러 발생 시점의 상세한 백엔드 로그를 확인합니다.
2.  **재현 단계**: 문제가 발생하는 정확한 API 요청 순서나 조건을 확인합니다.
3.  **환경 정보**: OS, Java 버전, DB 종류 등 실행 환경 정보를 확인합니다.

### 4.2. 추가 리소스

- **Spring Boot 공식 문서**: https://docs.spring.io/spring-boot/docs/current/reference/htmlsingle/
- **Stack Overflow**: spring-boot, kotlin 등 관련 태그로 검색
