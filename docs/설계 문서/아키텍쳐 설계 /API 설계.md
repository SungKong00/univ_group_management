# API 설계

### 1. 공통 규칙

- **Base URL:** `https://서버주소/api` (로컬: `http://localhost:8080/api`)
- **인증:** 인증이 필요한 API는 HTTP 헤더에 `Authorization: Bearer <JWT Access Token>`을 포함해야 합니다.
- **응답 형식:** 모든 응답은 표준 형식 `{ "success": boolean, "data": ..., "error": ... }`을 따릅니다.

---

### 2. 인증 (Auth) API

| 기능 | Endpoint | 인증 | 요청 Body | 성공 응답 (data) |
| --- | --- | --- | --- | --- |
| **회원가입** | `POST /auth/signup` | 불필요 | `{ "email", "name", "nickname", "globalRole", "department", "studentId" }` | `{ "userId", "nickname" }` |
| **구글 로그인/가입** | `POST /auth/google` | 불필요 | `{ "googleAuthToken": "..." }` | `{ "accessToken": "..." }` |
| **내 정보 조회** | `GET /users/me` | **필수** | (없음) | `{ "userId", "email", "nickname", ... }` |

Sheets로 내보내기

---

### 3. 그룹 (Group) API

| 기능 | Endpoint | 인증 | 요청 Body | 성공 응답 (data) | 권한 |
| --- | --- | --- | --- | --- | --- |
| **그룹 생성** | `POST /groups` | **필수** | `{ "parentId", "name", "description" }` | `{ "groupId", "name", ... }` | 로그인 사용자 |
| **전체 그룹 목록 조회** | `GET /groups` | 불필요 | (없음) | `[ { "groupId", "name", ... } ]` | 누구나 |
| **그룹 상세 조회** | `GET /groups/{groupId}` | 불필요 | (없음) | `{ "groupId", "name", "description", ... }` | 누구나 |
| **그룹 정보 수정** | `PUT /groups/{groupId}` | **필수** | `{ "name", "description" }` | `{ "groupId", "name", ... }` | 그룹장/지도교수 |
| **그룹 삭제** | `DELETE /groups/{groupId}` | **필수** | (없음) | `null` | 그룹장/지도교수 |

Sheets로 내보내기

---

### 4. 멤버 및 가입 (Member & Join) API

| 기능 | Endpoint | 인증 | 요청 Body | 성공 응답 (data) | 권한 |
| --- | --- | --- | --- | --- | --- |
| **그룹 가입 신청** | `POST /groups/{groupId}/join` | **필수** | (없음) | `{ "joinRequestId", "status" }` | 로그인 사용자 |
| **가입 신청 목록 조회** | `GET /groups/{groupId}/join-requests` | **필수** | (없음) | `[ { "requestId", "user": { ... } } ]` | 그룹장/지도교수 |
| **가입 신청 처리 (승인/거절)** | `PATCH /groups/{groupId}/join-requests/{requestId}` | **필수** | `{ "status": "APPROVED" | "REJECTED" }` | `null` |
| **그룹 멤버 목록 조회** | `GET /groups/{groupId}/members` | **필수** | (없음) | `[ { "userId", "nickname", "role": "..." } ]` | 그룹 멤버 |
| **멤버 강제 탈퇴** | `DELETE /groups/{groupId}/members/{userId}` | **필수** | (없음) | `null` | 그룹장/지도교수 |

Sheets로 내보내기

---

### 5. 역할 (Role) API

| 기능 | Endpoint | 인증 | 요청 Body | 성공 응답 (data) | 권한 |
| --- | --- | --- | --- | --- | --- |
| **커스텀 역할 생성** | `POST /groups/{groupId}/roles` | **필수** | `{ "name", "permissions": ["...", "..."] }` | `{ "roleId", "name", ... }` | 그룹장/지도교수(또는 ROLE_MANAGE) |
| **그룹 내 역할 목록** | `GET /groups/{groupId}/roles` | **필수** | (없음) | `[ { "roleId", "name" } ]` | 그룹 멤버 |
| **멤버 역할 변경** | `PUT /groups/{groupId}/members/{userId}/role` | **필수** | `{ "roleId": ... }` | `null` | 그룹장/지도교수(또는 ROLE_MANAGE) |

—

#### 권한 검사 표준화
- `@PreAuthorize("hasPermission(#groupId, 'GROUP', '<PERMISSION>')")` 형태로 통일
- 예: 가입신청 처리 → `<PERMISSION> = MEMBER_APPROVE`, 멤버 강퇴 → `MEMBER_KICK`

#### 전역 역할(GlobalRole) 입력 정책
- `globalRole` 허용 값: `STUDENT`, `PROFESSOR`, `ADMIN`
- JWT `auth`에는 `ROLE_STUDENT|ROLE_PROFESSOR|ROLE_ADMIN`로 매핑되어 포함됨

Sheets로 내보내기

---

### 6. 모집 공고 (Recruitment) API

| 기능 | Endpoint | 인증 | 요청 Body | 성공 응답 (data) | 권한 |
| --- | --- | --- | --- | --- | --- |
| **모집 공고 생성** | `POST /recruitments` | **필수** | `{ "groupId", "title", "content", "tags": [...] }` | `{ "postId", "title", ... }` | 해당 그룹장 |
| **모집 공고 목록 조회** | `GET /recruitments` | 불필요 | Query: `?tag=...` | `[ { "postId", "title", "group":{...} } ]` | 누구나 |
| **모집 공고 상세 조회** | `GET /recruitments/{postId}` | 불필요 | (없음) | `{ "postId", "title", "content", ... }` | 누구나 |
| **모집 공고 수정** | `PUT /recruitments/{postId}` | **필수** | `{ "title", "content", "tags": [...] }` | `{ "postId", "title", ... }` | 해당 그룹장 |
| **모집 공고 삭제** | `DELETE /recruitments/{postId}` | **필수** | (없음) | `null` | 해당 그룹장 |

Sheets로 내보내기

---

### 7. 게시글 및 댓글 (Post & Comment) API

| 기능 | Endpoint | 인증 | 요청 Body | 성공 응답 (data) | 권한 |
| --- | --- | --- | --- | --- | --- |
| **게시글 생성** | `POST /channels/{channelId}/posts` | **필수** | `{ "title", "content" }` | `{ "postId", "title", ... }` | 채널 쓰기 권한자 |
| **채널 내 게시글 목록** | `GET /channels/{channelId}/posts` | **필수** | (없음) | `[ { "postId", "title", "author":{...} } ]` | 채널 읽기 권한자 |
| **댓글 생성** | `POST /posts/{postId}/comments` | **필수** | `{ "content", "parentCommentId"(Optional) }` | `{ "commentId", "content", ... }` | 게시글 읽기 권한자 |
| **게시글 내 댓글 목록** | `GET /posts/{postId}/comments` | **필수** | (없음) | `[ { "commentId", "content", "author":{...} } ]` | 게시글 읽기 권한자 |
| **댓글 삭제** | `DELETE /comments/{commentId}` | **필수** | (없음) | `null` | 댓글 작성자 또는 그룹 관리자 |
