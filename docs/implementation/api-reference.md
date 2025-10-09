# Backend API Reference

본 문서는 백엔드 API의 명세를 코드 기준으로 정리한 최신 문서입니다.

## API 응답 구조

```json
{
  "success": true,
  "data": { },
  "error": { "code": "...", "message": "..." },
  "timestamp": "2025-10-01T12:00:00"
}
```
- 기존 message / errorCode 필드 표기는 폐기됨 (error.code / error.message 사용)

### 표준 에러 코드 (발췌)
| 코드 | HTTP | 의미 |
|------|------|------|
| INVALID_TOKEN | 401 | 위변조/형식 오류 |
| EXPIRED_TOKEN | 401 | 만료된 토큰 |
| UNAUTHORIZED | 401 | 인증 정보 없음 |
| FORBIDDEN | 403 | 권한 부족 |
| SYSTEM_ROLE_IMMUTABLE | 403 | 시스템 역할 수정/삭제 시도 |
| INVALID_STATE | 400 | 잘못된 서버 설정 또는 상태 |
| INVALID_REQUEST_BODY | 400 | 요청 본문 파싱 불가 (JSON 형식 오류) |
| DATA_INTEGRITY_VIOLATION | 409 | 데이터 무결성 제약 조건 위반 (e.g., ID 중복) |
| GROUP_ROLE_NAME_ALREADY_EXISTS | 409 | 역할명 중복 |
| RECRUITMENT_ALREADY_OPEN | 409 | 그룹에 이미 활성 모집 존재 |
| RECRUITMENT_CLOSED | 400 | 마감/취소된 모집 접근 |
| APPLICATION_DUPLICATE | 409 | 동일 모집 중복 지원 |
| APPLICATION_NOT_PENDING | 409 | PENDING 아님 (심사/철회 불가) |

## 1. Auth API (`/api/auth`)

Google OAuth2 인증 및 로그인/로그아웃을 처리합니다.

-   `POST /google`
    -   **설명**: Google 인증 토큰(ID Token 또는 Access Token)으로 로그인/회원가입을 처리합니다.
    -   **요청**: `GoogleLoginRequest`
        ```json
        {
          "googleAuthToken": "ID_TOKEN_STRING",  // ID Token (권장)
          "googleAccessToken": "ACCESS_TOKEN_STRING"  // Access Token (대안)
        }
        ```
    -   **응답**: `ApiResponse<LoginResponse>` (JWT 토큰 및 사용자 정보 포함)
    -   **응답 구조**:
        ```json
        {
          "success": true,
          "data": {
            "accessToken": "eyJ...",
            "tokenType": "Bearer",
            "expiresIn": 86400000,
            "user": {
              "id": 1,
              "name": "사용자명",
              "email": "user@example.com",
              "globalRole": "STUDENT",
              "isActive": true,
              "nickname": "닉네임",
              "profileImageUrl": null,
              "bio": null,
              "profileCompleted": true,
              "emailVerified": true,
              "professorStatus": null,
              "department": "AI/SW계열",
              "studentNo": "20250001",
              "schoolEmail": null,
              "createdAt": "2025-09-29T03:22:41.234567",
              "updatedAt": "2025-09-29T03:22:41.234567"
            },
            "firstLogin": false
          },
          "error": null
        }
        ```

-   `POST /google/callback`
    -   **설명**: Google ID Token으로 로그인/회원가입을 처리하는 콜백 엔드포인트입니다.
    -   **요청**: `{"id_token": "..."}`
    -   **응답**: `ApiResponse<LoginResponse>` (위와 동일한 구조)
    -   **테스트**: 개발용 토큰 `mock_google_token_for_castlekong1019`를 사용하면 테스트 계정으로 로그인

-   `POST /logout`
    -   **설명**: 사용자를 로그아웃 처리합니다. (현재는 토큰 무효화 로직 없음)
    -   **권한**: `isAuthenticated()`

-   `POST /debug/reset-profile-status`
    -   **설명**: [DEBUG] 모든 사용자의 프로필 완성 상태(`profileCompleted`)를 `false`로 초기화합니다. 개발 환경에서만 사용해야 합니다.

## 2. User API (`/api/users`)

사용자 정보, 프로필, 활동 관련 API를 제공합니다.

-   `POST /`
    -   **설명**: 온보딩 과정에서 사용자의 초기 프로필 정보(닉네임, 학과, 학번, 역할 등)를 제출받아 저장합니다.
    -   **권한**: `isAuthenticated()`
    -   **요청**: `SignupProfileRequest`
        ```json
        {
          "name": "실명",
          "nickname": "닉네임",
          "college": "AI/SW계열",
          "dept": "AI/SW학과",
          "studentNo": "20250001",
          "academicYear": 1,
          "schoolEmail": "student@hanshin.ac.kr",
          "role": "STUDENT"
        }
        ```
    -   **응답**: `ApiResponse<UserResponse>`

-   `GET /nickname-check`
    -   **설명**: 닉네임 중복 여부를 확인하고, 중복 시 추천 닉네임을 제공합니다.
    -   **권한**: `isAuthenticated()`
    -   **파라미터**: `nickname` (String)
    -   **응답**: `ApiResponse<NicknameCheckResponse>`
        ```json
        {
          "success": true,
          "data": {
            "available": false,
            "suggestions": ["닉네임1", "닉네임2", "닉네임3"]
          },
          "error": null
        }
        ```

-   `PUT /profile`
    -   **설명**: 사용자 프로필 정보(닉네임, 프로필 이미지, 자기소개 등)를 업데이트합니다.
    -   **권한**: `isAuthenticated()`
    -   **요청**: `ProfileUpdateRequest`
    -   **응답**: `UserResponse`

-   `GET /search`
    -   **설명**: 사용자 이름 또는 닉네임으로 사용자를 검색합니다. 역할(e.g., `PROFESSOR`)로 필터링할 수 있습니다.
    -   **권한**: `isAuthenticated()`
    -   **파라미터**: `q` (String), `role` (String, Optional)
    -   **응답**: `List<UserSummaryResponse>`
    -   **응답 구조**:
        ```json
        [
          {
            "id": 2,
            "name": "사용자명",
            "email": "user2@example.com",
            "profileImageUrl": null,
            "studentNo": "20250002",
            "academicYear": 1
          }
        ]
        ```

-   `GET /me/join-requests`
    -   **설명**: 현재 사용자가 신청한 그룹 가입 요청 목록을 조회합니다.
    -   **권한**: `isAuthenticated()`
    -   **파라미터**: `status` (String, Optional, 기본값: `PENDING`)
    -   **응답**: `List<GroupJoinRequestResponse>`

-   `GET /me/sub-group-requests`
    -   **설명**: 현재 사용자가 신청한 하위 그룹 생성 요청 목록을 조회합니다.
    -   **권한**: `isAuthenticated()`
    -   **파라미터**: `status` (String, Optional, 기본값: `PENDING`)
    -   **응답**: `List<SubGroupRequestResponse>`

## 3. Group API (`/api/groups`)

그룹 생성, 조회, 멤버 관리 등 그룹과 관련된 핵심 기능을 제공합니다.

### 3.1. 그룹 관리

-   `POST /`: 그룹 생성
-   `GET /`: 모든 그룹 목록 조회 (페이징)
-   `GET /all`: 모든 그룹 목록 조회 (페이징 없음)
-   `GET /explore`: 조건부 그룹 검색 (모집여부, 공개범위, 종류, 소속, 키워드, 태그 등)
-   `GET /hierarchy`: 전체 그룹 계층 구조 조회 (온보딩용)
-   `GET /{groupId}`: 특정 그룹 상세 정보 조회
-   `PUT /{groupId}`: 그룹 정보 수정 (`GROUP_MANAGE` 권한 필요)
-   `DELETE /{groupId}`: 그룹 삭제 (`GROUP_MANAGE` 권한 필요)

### 3.2. 멤버십 관리

-   `POST /{groupId}/join`: 그룹 가입 신청
-   `DELETE /{groupId}/leave`: 그룹 탈퇴
-   `GET /{groupId}/members`: 그룹 멤버 목록 조회 (`MEMBER_MANAGE` 권한 필요)
-   `GET /{groupId}/members/me`: 나의 그룹 내 멤버십 정보 조회
    - **설명**: 현재 로그인한 사용자의 특정 그룹 내 역할 및 그룹 수준 권한을 조회합니다.
    - **권한**: 그룹 멤버
    - **응답**: `ApiResponse<GroupMemberResponse>`
    - **응답 구조 (v2, 2025-10-07 이후)**:
        ```json
        {
          "success": true,
          "data": {
            "user": {
              "id": 1,
              "name": "Castlekong",
              "nickname": "castlekong",
              "profileImageUrl": null
            },
            "role": {
              "id": 1,
              "name": "그룹장",
              "priority": 100,
              "permissions": [
                "GROUP_MANAGE",
                "RECRUITMENT_MANAGE",
                "MEMBER_MANAGE"
                // ... 모든 그룹 권한
              ]
            },
            "joinedAt": "2025-10-07T12:00:00"
          },
          "error": null
        }
        ```
    - **참고**: 이전 버전의 평평한 구조(`userId`, `roleName` 등)에서 중첩된 `user`, `role` 객체 구조로 변경되었습니다. 프론트엔드에서는 이 구조에 맞춰 파싱해야 합니다.

-   `PUT /{groupId}/members/{userId}/role`: 멤버 역할 변경 (`MEMBER_MANAGE` 권한 필요)
-   `DELETE /{groupId}/members/{userId}`: 멤버 강제 탈퇴 (`MEMBER_MANAGE` 권한 필요)
-   `POST /{groupId}/transfer-ownership/{newOwnerId}`: 그룹 소유권 이전 (`GROUP_MANAGE` 권한 필요)

### 3.3. 역할(Role) 관리

-   `POST /{groupId}/roles`: 그룹 내 역할 생성 (`MEMBER_MANAGE` 권한 필요)
    -   **요청**: `CreateGroupRoleRequest`
        ```json
        {
          "name": "역할이름",
          "permissions": [], // 권한이 없어도 생성 가능
          "priority": 0
        }
        ```
-   `GET /{groupId}/roles`: 그룹 내 역할 목록 조회 (`MEMBER_MANAGE` 권한 필요)
    -   **응답**: `List<GroupRoleResponse>`
        ```json
        [
          {
            "id": 1,
            "name": "그룹장",
            "permissions": ["GROUP_MANAGE", "MEMBER_MANAGE", ...],
            "priority": 100,
            "memberCount": 1
          }
        ]
        ```
-   `GET /{groupId}/roles/{roleId}`: 특정 역할 상세 조회 (`MEMBER_MANAGE` 권한 필요)
-   `PUT /{groupId}/roles/{roleId}`: 역할 정보 및 권한 수정 (`MEMBER_MANAGE` 권한 필요)
-   `DELETE /{groupId}/roles/{roleId}`: 역할 삭제 (`MEMBER_MANAGE` 권한 필요)

### 3.4. 가입 및 생성 요청 관리

-   `GET /{groupId}/join-requests`: 그룹 가입 신청 목록 조회 (`MEMBER_MANAGE` 권한 필요)
-   `PATCH /{groupId}/join-requests/{requestId}`: 가입 신청 승인/거절 (`MEMBER_MANAGE` 권한 필요)
-   `POST /{groupId}/sub-groups/requests`: 하위 그룹 생성 요청
-   `GET /{groupId}/sub-groups/requests`: 하위 그룹 생성 요청 목록 조회 (`GROUP_MANAGE` 권한 필요)
-   `PATCH /{groupId}/sub-groups/requests/{requestId}`: 하위 그룹 생성 요청 승인/거절 (`GROUP_MANAGE` 권한 필요)

### 3.5. 기타

-   `GET /{groupId}/sub-groups`: 하위 그룹 목록 조회
-   `POST /{groupId}/professors/{professorId}`: 지도교수 지정 (`GROUP_MANAGE` 권한 필요)
-   `DELETE /{groupId}/professors/{professorId}`: 지도교수 지정 해제 (`GROUP_MANAGE` 권한 필요)
-   `GET /{groupId}/professors`: 지도교수 목록 조회
-   `GET /{groupId}/workspace`: 그룹의 워크스페이스 정보 조회 (멤버만 가능)
-   `GET /{groupId}/admin/stats`: 그룹 관리 통계 조회 (멤버만 가능)
-   `GET /{groupId}/membership/check`: 현재 사용자의 특정 그룹 멤버 여부 확인
-   `POST /membership/check`: 현재 사용자의 여러 그룹 멤버 여부 일괄 확인

## 4. Recruitment API (`/api`)

그룹의 신규 멤버 모집과 관련된 기능을 제공합니다.

-   `POST /groups/{groupId}/recruitments`: 모집 공고 생성 (`RECRUITMENT_MANAGE` 권한 필요)
-   `GET /groups/{groupId}/recruitments`: 특정 그룹의 활성 모집 공고 조회
-   `PUT /recruitments/{recruitmentId}`: 모집 공고 수정 (`RECRUITMENT_MANAGE` 권한 필요)
-   `PATCH /recruitments/{recruitmentId}/close`: 모집 공고 마감 (`RECRUITMENT_MANAGE` 권한 필요)
-   `DELETE /recruitments/{recruitmentId}`: 모집 공고 삭제 (`RECRUITMENT_MANAGE` 권한 필요)
-   `GET /groups/{groupId}/recruitments/archive`: 특정 그룹의 지난 모집 공고 목록 조회 (`RECRUITMENT_MANAGE` 권한 필요)
-   `GET /recruitments/public`: 공개된 전체 모집 공고 검색 (필터: q, status, groupType 등 확장 가능)
-   `POST /recruitments/{recruitmentId}/applications`: 모집에 지원서 제출
-   `GET /recruitments/{recruitmentId}/applications`: 특정 모집의 지원서 목록 조회 (`RECRUITMENT_MANAGE` 권한 필요)
-   `GET /applications/{applicationId}`: 지원서 상세 조회 (모집 관리자 또는 지원자 본인만 가능)
-   `PATCH /applications/{applicationId}/review`: 지원서 심사 (승인/거절) (`RECRUITMENT_MANAGE` 권한 필요)
-   `DELETE /applications/{applicationId}`: 지원서 제출 철회 (지원자 본인만 가능)
-   `GET /recruitments/{recruitmentId}/stats`: 모집 관련 통계 조회 (`RECRUITMENT_MANAGE` 권한 필요, 구현 예정)

### 4.1 모집 공고 생성
```
POST /api/groups/{groupId}/recruitments
Content-Type: application/json
Authorization: Bearer <token>
```
요청(JSON):
```json
{
  "title": "2025 1학기 신입 기수 모집",
  "content": "활동 소개 및 일정...",
  "maxApplicants": 30,
  "recruitmentEndDate": "2025-11-15T23:59:59",
  "autoApprove": false,
  "showApplicantCount": true,
  "applicationQuestions": ["지원 동기?", "관련 경험?"]
}
```
응답(성공):
```json
{
  "success": true,
  "data": {
    "id": 12,
    "groupId": 7,
    "title": "2025 1학기 신입 기수 모집",
    "status": "OPEN",
    "maxApplicants": 30,
    "currentApplicants": 0,
    "recruitmentStartDate": "2025-10-01T10:11:12",
    "recruitmentEndDate": "2025-11-15T23:59:59",
    "showApplicantCount": true,
    "applicationQuestions": ["지원 동기?", "관련 경험?"],
    "createdAt": "2025-10-01T10:11:12",
    "updatedAt": "2025-10-01T10:11:12"
  },
  "error": null,
  "timestamp": "2025-10-01T10:11:12"
}
```
에러 사례:
| code | 조건 |
|------|------|
| RECRUITMENT_ALREADY_OPEN | 동일 그룹에 OPEN 상태 존재 |
| FORBIDDEN | 권한 없음 |

### 4.2 활성 모집 조회
```
GET /api/groups/{groupId}/recruitments
```
응답: 단일 활성 모집 (없으면 404 처리 or success:true, data:null 정책 중 하나 — 현재 success:true & data:null)

### 4.3 모집 수정
```
PUT /api/recruitments/{id}
```
- title/content/maxApplicants/recruitmentEndDate/showApplicantCount 변경
- status 가 CLOSED/CANCELLED 면 RECRUITMENT_CLOSED

### 4.4 조기 마감
```
PATCH /api/recruitments/{id}/close
```
- 상태 OPEN -> CLOSED 전환
- 이미 CLOSED 인 경우 RECRUITMENT_CLOSED

### 4.5 모집 삭제
```
DELETE /api/recruitments/{id}
```
- DRAFT 또는 OPEN 상태에서만 허용 (CLOSED 는 정책에 따라 보존) → CLOSED 삭제 시 RECRUITMENT_CLOSED

### 4.6 아카이브 조회
```
GET /api/groups/{groupId}/recruitments/archive?page=0&size=20
```
응답 예시:
```json
{
  "success": true,
  "data": {
    "content": [
      {"id":11,"title":"2024 2학기 모집","status":"CLOSED","closedAt":"2024-12-01T12:00:00"}
    ],
    "page": 0,
    "size": 20,
    "totalElements": 1,
    "totalPages": 1
  },
  "error": null
}
```

### 4.7 공개 모집 검색
```
GET /api/recruitments/public?q=AI&status=OPEN&page=0&size=20
```
필터 파라미터:
- q: 제목/내용 검색
- status: OPEN/CLOSED (기본 OPEN)
- groupType (선택)

### 4.8 지원서 제출
```
POST /api/recruitments/{id}/applications
```
요청:
```json
{
  "motivation": "서비스 기획 역량 성장",
  "questionAnswers": {"0":"학교 프로젝트 경험","1":"AI 경진대회 수상"}
}
```
에러:
| code | 조건 |
|------|------|
| APPLICATION_DUPLICATE | 이미 PENDING/APPROVED 존재 |
| RECRUITMENT_CLOSED | 모집이 OPEN 아님 |

### 4.9 지원서 목록 / 상세
- 목록: `GET /api/recruitments/{id}/applications?page=0&size=20` (RECRUITMENT_MANAGE)
- 상세: `GET /api/applications/{appId}` (권한자 또는 본인)

### 4.10 지원서 심사
```
PATCH /api/applications/{appId}/review
{
  "decision": "APPROVE", // or REJECT
  "comment": "활동 기대합니다"
}
```
에러:
| code | 조건 |
|------|------|
| APPLICATION_NOT_PENDING | 이미 처리된 상태 |
| RECRUITMENT_CLOSED | 모집 CLOSED/CANCELLED |

### 4.11 지원서 철회
```
DELETE /api/applications/{appId}
```
- 본인 & 상태 PENDING
- APPLICATION_NOT_PENDING 위반 시 409

### 4.12 통계 (예정)
```
GET /api/recruitments/{id}/stats
```
예시(미구현):
```json
{
  "success": true,
  "data": {
    "recruitmentId": 12,
    "total": 20,
    "approved": 8,
    "rejected": 5,
    "pending": 7,
    "averageReviewTimeSeconds": 86400
  },
  "error": null
}
```
> 통계 계산은 별도 비동기 집계/캐시 후 제공 예정.

## 5. Content API (`/api`)

워크스페이스, 채널, 게시글, 댓글 등 컨텐츠 관련 기능을 제공합니다.

### 5.1. 워크스페이스 및 채널

-   `GET /groups/{groupId}/workspaces`: 그룹의 워크스페이스 목록 조회 (`CHANNEL_READ` 권한 필요)
-   `POST /groups/{groupId}/workspaces`: 워크스페이스 생성 (`GROUP_MANAGE` 권한 필요)
-   `PUT /workspaces/{workspaceId}`: 워크스페이스 수정 (관련자만 가능)
-   `DELETE /workspaces/{workspaceId}`: 워크스페이스 삭제 (관련자만 가능)
-   `GET /workspaces/{workspaceId}/channels`: 워크스페이스 내 채널 목록 조회
-   `POST /workspaces/{workspaceId}/channels`: 채널 생성 (관련자만 가능)
-   `PUT /channels/{channelId}`: 채널 수정 (관련자만 가능)
-   `DELETE /channels/{channelId}`: 채널 삭제 (관련자만 가능)
-   `GET /channels/{channelId}/permissions/me`: 채널에 대한 나의 권한 목록 조회

### 5.2. 게시글 (Posts)

**게시글 목록 조회**
```
GET /api/channels/{channelId}/posts?page=0&size=20
```
- **권한**: `POST_READ` (채널 권한)
- **응답**: `ApiResponse<PostListResponse>`
- **PostListResponse**:
  ```json
  {
    "posts": [
      {
        "id": 1,
        "channelId": 10,
        "content": "게시글 내용",
        "authorId": 5,
        "authorName": "작성자명",
        "createdAt": "2025-10-05T14:30:00",
        "updatedAt": "2025-10-05T14:30:00"
      }
    ],
    "hasNext": true
  }
  ```

**게시글 작성**
```
POST /api/channels/{channelId}/posts
Content-Type: application/json
```
- **권한**: `POST_WRITE` (채널 권한)
- **요청**: `CreatePostRequest`
  ```json
  {
    "content": "게시글 내용"
  }
  ```
- **응답**: `ApiResponse<Post>`

**게시글 수정**
```
PUT /api/posts/{postId}
```
- **권한**: 작성자 본인 또는 관리자
- **요청**: `CreatePostRequest`
- **응답**: `ApiResponse<Post>`

**게시글 삭제**
```
DELETE /api/posts/{postId}
```
- **권한**: 작성자 본인 또는 관리자
- **응답**: `ApiResponse<void>`

### 5.3. 댓글 (Comments)

**댓글 목록 조회**
```
GET /api/posts/{postId}/comments?page=0&size=50
```
- **권한**: `POST_READ` (채널 권한)
- **응답**: `ApiResponse<CommentListResponse>`
- **CommentListResponse**:
  ```json
  {
    "comments": [
      {
        "id": 1,
        "postId": 10,
        "content": "댓글 내용",
        "author": {
          "id": 5,
          "name": "작성자명",
          "profileImageUrl": "url..."
        },
        "createdAt": "2025-10-05T14:35:00",
        "updatedAt": "2025-10-05T14:35:00",
        "parentCommentId": null
      }
    ],
    "hasNext": false
  }
  ```

**댓글 작성**
```
POST /api/posts/{postId}/comments
Content-Type: application/json
```
- **권한**: `COMMENT_WRITE` (채널 권한)
- **요청**: `CreateCommentRequest`
  ```json
  {
    "content": "댓글 내용"
  }
  ```
- **응답**: `ApiResponse<Comment>`

**댓글 수정**
```
PUT /api/comments/{commentId}
```
- **권한**: 작성자 본인 또는 관리자
- **요청**: `CreateCommentRequest`
- **응답**: `ApiResponse<Comment>`

**댓글 삭제**
```
DELETE /api/comments/{commentId}
```
- **권한**: 작성자 본인 또는 관리자
- **응답**: `ApiResponse<void>`

**권한 에러 예시**:
| 상황 | ErrorCode | HTTP |
|------|-----------|------|
| 채널 멤버가 아님 | FORBIDDEN | 403 |
| POST_READ 권한 없음 | FORBIDDEN | 403 |
| POST_WRITE 권한 없음 | FORBIDDEN | 403 |
| COMMENT_WRITE 권한 없음 | FORBIDDEN | 403 |
| 타인 게시글 수정/삭제 | FORBIDDEN | 403 |

## 6. Admin API (`/api/admin`)

플랫폼 전체 관리자 기능입니다.

-   `GET /join-requests`: 모든 그룹 가입 신청 목록 조회 (`ADMIN` 역할 필요)
-   `PATCH /join-requests/{id}`: 그룹 가입 신청 처리 (`ADMIN` 역할 필요)
-   `GET /group-requests`: 모든 하위 그룹 생성 요청 목록 조회 (`ADMIN` 역할 필요)
-   `PATCH /group-requests/{id}`: 하위 그룹 생성 요청 처리 (`ADMIN` 역할 필요)

## 7. 기타 API

-   **Email Verification API (`/api/email/verification`)**
    -   `POST /send`: 학교 이메일 인증 코드 발송
    -   `POST /verify`: 인증 코드 검증

-   **Me API (`/api`)**
    -   `GET /me`: 현재 로그인한 사용자 정보 조회
    -   `GET /me/groups`: 내가 속한 모든 그룹 목록 조회 (계층 레벨순 정렬)

### Me API 상세

#### GET /api/me/groups
현재 사용자가 속한 모든 그룹을 계층 레벨 순으로 조회합니다.

-   **권한**: `isAuthenticated()`
-   **사용 사례**: 워크스페이스 자동 진입 시 최상위 그룹 선택
-   **정렬**: level 오름차순 (0=최상위) → id 오름차순
-   **응답**: `ApiResponse<List<MyGroupResponse>>`

**응답 구조**:
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "한신대학교",
      "type": "UNIVERSITY",
      "level": 0,
      "parentId": null,
      "role": "멤버",
      "permissions": ["CHANNEL_READ", "POST_READ"],
      "profileImageUrl": null
    },
    {
      "id": 2,
      "name": "AI/SW학부",
      "type": "DEPARTMENT",
      "level": 2,
      "parentId": 1,
      "role": "멤버",
      "permissions": ["CHANNEL_READ", "POST_READ", "POST_WRITE"],
      "profileImageUrl": null
    }
  ],
  "error": null
}
```

**프론트엔드 최상위 그룹 선택 로직**:
```dart
// 1. level이 가장 작은 그룹들 필터링
final minLevel = groups.map((g) => g.level).reduce((a, b) => a < b ? a : b);
final topLevelGroups = groups.where((g) => g.level == minLevel).toList();

// 2. id가 가장 작은 그룹 선택 (가장 먼저 가입한 그룹)
topLevelGroups.sort((a, b) => a.id.compareTo(b.id));
final topGroup = topLevelGroups.first;

// 3. /workspace/{topGroup.id}로 자동 진입
context.go('/workspace/${topGroup.id}');
```

-   **Role API (`/api/roles`)**
    -   `POST /apply`: 역할(교수) 신청

---

## 캘린더 API (v1.3)

> **개발 우선순위**: Phase 6 이후
> **상태**: 스키마 및 API 설계 완료, 구현 미착수
> **관련 문서**: [캘린더 시스템](../concepts/calendar-system.md)

### 시간표 API (`/api/timetable`)

개인의 고정/반복 일정을 관리합니다.

- `GET /me`: 내 **시간표** 조회 (학교 강의 + 개인 반복 일정) (권한: `isAuthenticated()`)
- `POST /me/courses`: 내 시간표에 강의 추가 (권한: `isAuthenticated()`)
- `DELETE /me/courses/{userCourseTimetableId}`: 내 시간표에서 강의 삭제 (권한: `isAuthenticated()`)
- `POST /me/schedules`: 내 시간표에 개인 반복 일정 추가 (권한: `isAuthenticated()`)
- `PUT /me/schedules/{scheduleId}`: 개인 반복 일정 수정 (권한: `isAuthenticated()`)
- `DELETE /me/schedules/{scheduleId}`: 개인 반복 일정 삭제 (권한: `isAuthenticated()`)

### 개인 캘린더 API (`/api/calendar`)

개인의 모든 유동적/확정적 일정을 통합 조회하고 관리합니다.

- `GET /me/events?year=2025&month=11`: 특정 월의 내 **캘린더** 이벤트 조회 (권한: `isAuthenticated()`)
- `POST /me/events`: 개인 이벤트 생성 (권한: `isAuthenticated()`)
- `PUT /me/events/{eventId}`: 개인 이벤트 수정 (권한: `isAuthenticated()`)
- `DELETE /me/events/{eventId}`: 개인 이벤트 삭제 (권한: `isAuthenticated()`)

### 그룹 캘린더 API (`/api/groups/{groupId}/events`)

그룹의 일정을 관리합니다.

- `GET /`: 그룹 캘린더의 일정 목록 조회 (권한: **그룹 멤버**)
- `POST /`: 그룹 일정 생성 (공식: **`CALENDAR_MANAGE`** / 비공식: **그룹 멤버**)
- `GET /{eventId}`: 특정 그룹 일정 상세 조회 (권한: **그룹 멤버**)
- `PUT /{eventId}`: 그룹 일정 수정 (공식: **`CALENDAR_MANAGE`** / 비공식: **작성자 or `CALENDAR_MANAGE`**)
- `DELETE /{eventId}`: 그룹 일정 삭제 (공식: **`CALENDAR_MANAGE`** / 비공식: **작성자 or `CALENDAR_MANAGE`**)
- `POST /{eventId}/participants`: 일정 참여 상태 변경 (권한: **그룹 멤버**)
- `GET /{eventId}/participants`: 일정 참여자 목록 조회 (권한: **그룹 멤버**)

### 최적 시간 추천 API (`/api/groups/{groupId}/recommend-time`)

- `POST /`: 그룹 일정 생성을 위한 최적 시간 추천 (권한: **그룹 멤버**)

### 장소 API (`/api/places`)

장소 및 예약 관련 기능을 관리합니다.

- `POST /`: 장소 등록 (권한: `PLACE_MANAGE`)
- `GET /{placeId}`: 특정 장소 상세 정보 조회 (권한: `isAuthenticated()`)
- `POST /{placeId}/usage-groups`: 장소 사용 그룹 신청 (권한: 그룹 관리자)
- `GET /{placeId}/usage-groups`: 장소 사용 그룹 신청 목록 조회 (권한: `PLACE_MANAGE`)
- `PATCH /{placeId}/usage-groups/{usageGroupId}`: 사용 그룹 신청 승인/거절 (권한: `PLACE_MANAGE`)

- **장소 운영 규칙 관리 API**:
    - `GET /{placeId}/availability`: 장소 운영 규칙 목록 조회 (권한: `PLACE_MANAGE`)
    - `POST /{placeId}/availability`: 장소 운영 규칙 추가 (권한: `PLACE_MANAGE`)
    - `PUT /availability/{availabilityId}`: 장소 운영 규칙 수정 (권한: `PLACE_MANAGE`)
    - `DELETE /availability/{availabilityId}`: 장소 운영 규칙 삭제 (권한: `PLACE_MANAGE`)

- **장소 예약 현황 조회 API**:
    - `GET /{placeId}/available-slots?date=YYYY-MM-DD`: 특정 날짜의 **최종 예약 가능 시간 슬롯** 목록 조회 (권한: **`isAuthenticated()`**)