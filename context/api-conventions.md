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
