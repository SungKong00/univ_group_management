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
        "pageable": { ... },
        "last": true,
        "totalPages": 1,
        "totalElements": 5,
        "first": true,
        "size": 20,
        "number": 0,
        "numberOfElements": 5,
        "sort": { ... },
        "empty": false
    }
}
```

#### 1.4.2. 프론트엔드 처리 가이드
프론트엔드에서는 다음과 같이 유연하게 응답을 처리해야 합니다:

```typescript
// 의사 코드
function parseApiResponse(response) {
  if (response.data && Array.isArray(response.data.content)) {
    // 페이지네이션 형태: data.content에서 배열 추출
    return response.data.content;
  } else if (Array.isArray(response.data)) {
    // 레거시 형태: data가 직접 배열
    return response.data;
  } else {
    // 단일 객체 형태
    return response.data;
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
| `POST` | `/api/auth/logout` | 로그아웃 | Required | - | `{ "success": true }` |
| `POST` | `/api/auth/debug/reset-profile-status` | (디버그용) 프로필 상태 초기화 | Required | - | `{ "success": true }` |

### 2.2. 사용자 API (Users) - ✅ 확장됨

| 메서드 | 엔드포인트 | 설명 | 인증 | 요청 본문 / 쿼리 | 응답 데이터 |
|--------|------------|------|------|-----------|-------------|
| `GET` | `/api/users/me` | 현재 사용자 정보 조회 | Required | - | `User` 객체 |
| `GET` | `/api/me` | 현재 사용자 정보 조회(alias) | Required | - | `User` 객체 |
| `PUT` | `/api/users/profile` | 사용자 프로필 완성 | Required | `{ "globalRole": "...", "nickname": "...", ... }` | `User` 객체 |
| `POST` | `/api/users` | 첫 로그인 온보딩 정보 확정 | Required | `{ "name": "...", "nickname": "...", ... }` | `User` 객체 |
| `GET` | `/api/users/nickname-check?nickname=...` | 닉네임 중복 확인 | Required | `nickname` 쿼리 | `{ "available": bool, "suggestions": [...] }` |
| `GET` | `/api/users/search?query=...` | 사용자 검색 | Required | `query` 쿼리 | `User[]` |

### 2.3. 그룹 API (Groups) - ✅ 확장됨

| 메서드 | 엔드포인트 | 설명 | 인증 | 권한 | 요청 본문 | 응답 데이터 |
|--------|------------|------|------|------|-----------|-------------|
| `POST` | `/api/groups` | 그룹 생성 | Required | - | `{ "name": "...", "description": "...", ... }` | `Group` 객체 |
| `GET` | `/api/groups` | 내 그룹 목록 조회 | Required | - | - | `Group[]` |
| `GET` | `/api/groups/all` | 모든 그룹 목록 조회 (관리자용) | Required | ADMIN | - | `Group[]` |
| `GET` | `/api/groups/explore` | 그룹 탐색/검색 | Optional | - | 페이지네이션 `GroupSummary[]` |
| `GET` | `/api/groups/hierarchy` | 그룹 계층 구조 조회 | Required | - | - | `GroupHierarchyNode[]` |
| `GET` | `/api/groups/{groupId}` | 그룹 상세 조회 | Required | GROUP_READ | - | `Group` 객체 |
| `PUT` | `/api/groups/{groupId}` | 그룹 정보 수정 | Required | GROUP_EDIT | `{ "name": "...", ... }` | `Group` 객체 |
| `DELETE` | `/api/groups/{groupId}` | 그룹 삭제 | Required | GROUP_DELETE | - | - |
| `POST` | `/api/groups/{groupId}/transfer-ownership/{newOwnerId}` | 그룹 소유권 이전 | Required | GROUP_OWNER | - | `GroupMember` |
| `GET` | `/api/groups/{groupId}/workspace` | 그룹의 기본 워크스페이스 조회 | Required | GROUP_READ | - | `Workspace` |
| `GET` | `/api/groups/{groupId}/admin/stats` | 그룹 관리자 통계 조회 | Required | GROUP_MANAGE | - | `GroupStats` |

### 2.4. 그룹 멤버십 API (Group Membership) - ✅ 확장됨

| 메서드 | 엔드포인트 | 설명 | 인증 | 권한 | 요청 본문 | 응답 데이터 |
|--------|------------|------|------|------|-----------|-------------|
| `POST` | `/api/groups/{groupId}/join` | 그룹 가입 신청 | Required | - | `{ "message": "..." }` | `GroupJoinRequest` |
| `DELETE` | `/api/groups/{groupId}/leave` | 그룹 탈퇴 | Required | - | - | - |
| `GET` | `/api/groups/{groupId}/join-requests` | 가입 신청 목록 조회 | Required | GROUP_MANAGE_MEMBERS | - | `GroupJoinRequest[]` |
| `PATCH` | `/api/groups/{groupId}/join-requests/{requestId}` | 가입 신청 처리 | Required | GROUP_MANAGE_MEMBERS | `{ "action": "APPROVE\|REJECT" }` | `GroupJoinRequest` |
| `GET` | `/api/groups/{groupId}/members` | 그룹 멤버 목록 조회 | Required | GROUP_READ | - | `GroupMember[]` |
| `GET` | `/api/groups/{groupId}/members/me` | 내 멤버십 정보 조회 | Required | GROUP_READ | - | `GroupMember` |
| `DELETE` | `/api/groups/{groupId}/members/{userId}` | 멤버 추방 | Required | GROUP_MANAGE_MEMBERS | - | - |
| `GET` | `/api/groups/{groupId}/membership/check` | 현재 유저의 그룹 멤버십 확인 | Required | - | - | `{ "isMember": bool }` |
| `POST` | `/api/groups/membership/check` | 여러 그룹에 대한 멤버십 확인 | Required | - | `{ "groupIds": [...] }` | `{ "groupId": bool, ... }` |

### 2.5. 그룹 역할 및 권한 API (Group Roles & Permissions) - ✅ 확장됨

| 메서드 | 엔드포인트 | 설명 | 인증 | 권한 | 요청 본문 | 응답 데이터 |
|--------|------------|------|------|------|-----------|-------------|
| `POST` | `/api/groups/{groupId}/roles` | 커스텀 역할 생성 | Required | GROUP_MANAGE_ROLES | `{ "name": "...", "permissions": [...], ... }` | `GroupRole` |
| `GET` | `/api/groups/{groupId}/roles` | 그룹 역할 목록 조회 | Required | GROUP_READ | - | `GroupRole[]` |
| `GET` | `/api/groups/{groupId}/roles/{roleId}` | 특정 역할 조회 | Required | GROUP_READ | - | `GroupRole` |
| `PUT` | `/api/groups/{groupId}/roles/{roleId}` | 역할 수정 | Required | GROUP_MANAGE_ROLES | `{ "name": "...", "permissions": [...], ... }` | `GroupRole` |
| `DELETE` | `/api/groups/{groupId}/roles/{roleId}` | 역할 삭제 | Required | GROUP_MANAGE_ROLES | - | - |
| `PUT` | `/api/groups/{groupId}/members/{userId}/role` | 멤버 역할 변경 | Required | GROUP_MANAGE_MEMBERS | `{ "roleId": ... }` | `GroupMember` |
| `GET` | `/api/groups/{groupId}/members/{userId}/permissions` | 개인 권한 오버라이드 조회 | Required | `ROLE_MANAGE` | - | `{...}` |
| `PUT` | `/api/groups/{groupId}/members/{userId}/permissions` | 개인 권한 오버라이드 설정 | Required | `ROLE_MANAGE` | `{...}` | `{...}` |

**참고**: 개인 권한 오버라이드(`.../permissions`) API는 문서에만 존재하며, 현재 코드에 구현되어 있지 않습니다. (❌ **미구현**)

### 2.6. 하위 그룹 API (Sub-Groups) - ✅ 구현됨

| 메서드 | 엔드포인트 | 설명 | 인증 | 권한 | 요청 본문 | 응답 데이터 |
|--------|------------|------|------|------|-----------|-------------|
| `POST` | `/api/groups/{groupId}/sub-groups/requests` | 하위 그룹 생성 신청 | Required | - | `{ "requestedGroupName": "...", ... }` | `SubGroupRequest` |
| `GET` | `/api/groups/{groupId}/sub-groups/requests` | 하위 그룹 신청 목록 | Required | GROUP_MANAGE | - | `SubGroupRequest[]` |
| `PATCH` | `/api/groups/{groupId}/sub-groups/requests/{requestId}` | 하위 그룹 신청 처리 | Required | GROUP_MANAGE | `{ "action": "APPROVE\|REJECT", ... }` | `SubGroupRequest` |
| `GET` | `/api/groups/{groupId}/sub-groups` | 하위 그룹 목록 조회 | Required | - | - | `Group[]` |

### 2.7. 지도교수 API (Professors) - ✅ 구현됨

| 메서드 | 엔드포인트 | 설명 | 인증 | 권한 | 요청 본문 | 응답 데이터 |
|--------|------------|------|------|------|-----------|-------------|
| `POST` | `/api/groups/{groupId}/professors/{professorId}` | 지도교수 지정 | Required | GROUP_MANAGE | - | `GroupMember` |
| `DELETE` | `/api/groups/{groupId}/professors/{professorId}` | 지도교수 해제 | Required | GROUP_MANAGE | - | - |
| `GET` | `/api/groups/{groupId}/professors` | 지도교수 목록 조회 | Required | - | - | `GroupMember[]` |

### 2.8. 콘텐츠 API (Workspaces, Channels, Posts, Comments) - ✅ 구현됨

| 메서드 | 엔드포인트 | 설명 | 인증 | 권한 | 요청 본문 | 응답 데이터 |
|--------|------------|------|------|------|-----------|-------------|
| `GET` | `/api/groups/{groupId}/workspaces` | 그룹의 워크스페이스 조회 | Required | GROUP_READ | - | `Workspace[]` |
| `POST` | `/api/groups/{groupId}/workspaces` | 워크스페이스 생성 | Required | GROUP_MANAGE | `{ "name": "...", ... }` | `Workspace` |
| `PUT` | `/api/workspaces/{workspaceId}` | 워크스페이스 수정 | Required | GROUP_MANAGE | `{ "name": "...", ... }` | `Workspace` |
| `DELETE` | `/api/workspaces/{workspaceId}` | 워크스페이스 삭제 | Required | GROUP_MANAGE | - | - |
| `GET` | `/api/workspaces/{workspaceId}/channels` | 채널 목록 조회 | Required | GROUP_READ | - | `Channel[]` |
| `POST` | `/api/workspaces/{workspaceId}/channels` | 채널 생성 | Required | GROUP_MANAGE_CHANNELS | `{ "name": "...", "type": "..." }` | `Channel` |
| `PUT` | `/api/channels/{channelId}` | 채널 수정 | Required | GROUP_MANAGE_CHANNELS | `{ "name": "...", ... }` | `Channel` |
| `DELETE` | `/api/channels/{channelId}` | 채널 삭제 | Required | GROUP_MANAGE_CHANNELS | - | - |
| `GET` | `/api/channels/{channelId}/permissions/me`| 채널에 대한 내 권한 조회 | Required | GROUP_READ | - | `ChannelPermission` |
| `GET` | `/api/channels/{channelId}/posts` | 채널 게시글 목록 | Required | GROUP_READ | - | `Post[]` |
| `POST` | `/api/channels/{channelId}/posts` | 게시글 작성 | Required | GROUP_POST | `{ "content": "...", ... }` | `Post` |
| `GET` | `/api/posts/{postId}` | 게시글 상세 조회 | Required | GROUP_READ | - | `Post` |
| `PUT` | `/api/posts/{postId}` | 게시글 수정 | Required | Own Post or GROUP_POST | `{ "content": "...", ... }` | `Post` |
| `DELETE` | `/api/posts/{postId}` | 게시글 삭제 | Required | Own Post or GROUP_DELETE | - | - |
| `GET` | `/api/posts/{postId}/comments` | 게시글 댓글 목록 | Required | GROUP_READ | - | `Comment[]` |
| `POST` | `/api/posts/{postId}/comments` | 댓글 작성 | Required | GROUP_COMMENT | `{ "content": "...", ... }` | `Comment` |
| `PUT` | `/api/comments/{commentId}` | 댓글 수정 | Required | Own Comment | `{ "content": "..." }` | `Comment` |
| `DELETE` | `/api/comments/{commentId}` | 댓글 삭제 | Required | Own Comment or GROUP_DELETE | - | - |

### 2.9. 이메일 인증 API (Email Verification) - ✅ 구현됨

| 메서드 | 엔드포인트 | 설명 | 인증 | 요청 본문 | 응답 데이터 |
|--------|------------|------|------|-----------|-------------|
| `POST` | `/api/email/verification/send` | 학교 이메일로 OTP 발송 | Required | `{ "email": "..." }` | `{ "success": true }` |
| `POST` | `/api/email/verification/verify` | OTP 검증 및 사용자 업데이트 | Required | `{ "email": "...", "code": "..." }` | `{ "success": true }` |

### 2.10. 역할 신청 API (Role Application) - ✅ 구현됨

| 메서드 | 엔드포인트 | 설명 | 인증 | 요청 본문 | 응답 데이터 |
|--------|------------|------|------|-----------|-------------|
| `POST` | `/api/roles/apply` | 역할 신청 (예: 교수) | Required | `{ "role": "PROFESSOR" }` | `{ "success": true }` |

### 2.11. 관리자 API (Admin) - ✅ 구현됨

| 메서드 | 엔드포인트 | 설명 | 인증 | 권한 | 응답 |
|--------|------------|------|------|------|------|
| `GET` | `/api/admin/join-requests` | 모든 가입 신청 목록 | Required | ADMIN | `JoinRequest[]` |
| `PATCH` | `/api/admin/join-requests/{id}` | 가입 신청 처리 | Required | ADMIN | `JoinRequest` |
| `GET` | `/api/admin/group-requests` | 공식 그룹 신청 목록 | Required | ADMIN | `GroupRequest[]` |
| `PATCH` | `/api/admin/group-requests/{id}` | 공식 그룹 신청 처리 | Required | ADMIN | `GroupRequest` |

### 2.12. 마이페이지 API (MyPage) - ✅ 구현됨

| 메서드 | 엔드포인트 | 설명 | 인증 | 응답 |
|--------|------------|------|------|------|
| `GET` | `/api/users/me/join-requests` | 내 가입 신청 목록 | Required | `JoinRequest[]` |
| `GET` | `/api/users/me/sub-group-requests` | 내 하위 그룹 신청 목록 | Required | `SubGroupRequest[]` |

### 2.13. 모집 공고 API (Recruitments) - ❌ 미구현

---

## 3. 권한 시스템

### 3.1. GroupPermission 열거형
```kotlin
enum class GroupPermission {
    GROUP_READ,
    GROUP_EDIT,
    GROUP_DELETE,
    GROUP_MANAGE_MEMBERS,
    GROUP_MANAGE_ROLES,
    GROUP_MANAGE_CHANNELS,
    GROUP_POST,
    GROUP_COMMENT,
    GROUP_DELETE_OTHERS_POSTS,
    GROUP_ADMIN
}
```

---

## 4. 에러 코드

(기존 내용과 동일)