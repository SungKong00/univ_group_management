# API 엔드포인트 목록 (API Endpoints)

## 목적
backend_new 리팩터링을 위한 전체 REST API 엔드포인트 설계. [API 단순화 원칙](api-simplification.md)을 준수하여 최대 50개 엔드포인트로 제한.

## 설계 원칙

### 1. REST 동사 제한
- **허용**: GET, POST, PATCH, DELETE
- **금지**: PUT, HEAD, OPTIONS (커스텀)

### 2. 응답 형식
- 모든 응답은 `ApiResponse<T>` 래핑
- 성공: `{ "success": true, "data": {...}, "error": null, "timestamp": "..." }`
- 실패: `{ "success": false, "data": null, "error": {...}, "timestamp": "..." }`

### 3. 쿼리 파라미터 표준
- `limit`: 페이지 크기 (기본 20)
- `offset`: 시작 위치 (기본 0)
- `sort`: 정렬 기준 (recent|oldest|popular)
- `search`: 검색 키워드 (선택)

### 4. 금지 패턴
- ❌ `/recent`, `/popular`, `/search` 등 별도 엔드포인트 생성
- ❌ 응답 직접 반환 (반드시 `ApiResponse<T>` 사용)
- ❌ PUT 메서드 (PATCH만 사용)

---

## 전체 엔드포인트 개수: 47개

### Domain 1: User (5개)
- GET /api/v1/users/me
- PATCH /api/v1/users/me
- GET /api/v1/users/{id}
- POST /api/v1/users/verify-email
- POST /api/v1/users/professor-request

### Domain 2: Group (10개)
- GET /api/v1/groups
- POST /api/v1/groups
- GET /api/v1/groups/{id}
- PATCH /api/v1/groups/{id}
- DELETE /api/v1/groups/{id}
- GET /api/v1/groups/{id}/members
- POST /api/v1/groups/{id}/members
- PATCH /api/v1/groups/{id}/members/{userId}
- DELETE /api/v1/groups/{id}/members/{userId}
- GET /api/v1/groups/{id}/roles

### Domain 3: Permission (3개)
- GET /api/v1/groups/{groupId}/permissions
- POST /api/v1/groups/{groupId}/roles
- PATCH /api/v1/groups/{groupId}/roles/{roleId}

### Domain 4: Workspace (8개)
- GET /api/v1/groups/{groupId}/workspaces
- POST /api/v1/groups/{groupId}/workspaces
- GET /api/v1/groups/{groupId}/channels
- POST /api/v1/groups/{groupId}/channels
- GET /api/v1/groups/{groupId}/channels/{channelId}
- PATCH /api/v1/groups/{groupId}/channels/{channelId}
- DELETE /api/v1/groups/{groupId}/channels/{channelId}
- PATCH /api/v1/channels/{channelId}/read-position

### Domain 5: Content (6개)
- GET /api/v1/channels/{channelId}/posts
- POST /api/v1/channels/{channelId}/posts
- GET /api/v1/posts/{postId}
- PATCH /api/v1/posts/{postId}
- DELETE /api/v1/posts/{postId}
- GET /api/v1/posts/{postId}/comments
- POST /api/v1/posts/{postId}/comments
- PATCH /api/v1/comments/{commentId}
- DELETE /api/v1/comments/{commentId}

### Domain 6: Calendar (15개)
- GET /api/v1/groups/{groupId}/events
- POST /api/v1/groups/{groupId}/events
- GET /api/v1/events/{eventId}
- PATCH /api/v1/events/{eventId}
- DELETE /api/v1/events/{eventId}
- GET /api/v1/personal-events
- POST /api/v1/personal-events
- PATCH /api/v1/personal-events/{eventId}
- DELETE /api/v1/personal-events/{eventId}
- GET /api/v1/places
- POST /api/v1/places
- GET /api/v1/places/{placeId}
- PATCH /api/v1/places/{placeId}
- DELETE /api/v1/places/{placeId}
- GET /api/v1/places/{placeId}/availability

---

## Domain 1: User API (5개)

### 1.1 GET /api/v1/users/me
**설명**: 현재 로그인한 사용자 정보 조회

**권한**: 인증된 사용자

**응답**:
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "홍길동",
    "email": "hong@example.com",
    "globalRole": "STUDENT",
    "nickname": "길동이",
    "profileImageUrl": "https://...",
    "bio": "안녕하세요",
    "college": "공과대학",
    "department": "컴퓨터공학과",
    "studentNo": "20220001",
    "academicYear": 3,
    "createdAt": "2025-01-01T00:00:00Z"
  },
  "error": null,
  "timestamp": "2025-11-20T10:00:00Z"
}
```

### 1.2 PATCH /api/v1/users/me
**설명**: 현재 사용자 프로필 수정

**권한**: 인증된 사용자

**요청**:
```json
{
  "nickname": "새로운닉네임",
  "bio": "새로운 자기소개",
  "profileImageUrl": "https://..."
}
```

**응답**: UserDto (수정된 정보)

### 1.3 GET /api/v1/users/{id}
**설명**: 특정 사용자 공개 프로필 조회

**권한**: 인증된 사용자 (같은 그룹 멤버만)

**응답**: UserDto (공개 정보만)

### 1.4 POST /api/v1/users/verify-email
**설명**: 학교 이메일 인증 코드 발송

**권한**: 인증된 사용자

**요청**:
```json
{
  "schoolEmail": "hong@university.ac.kr"
}
```

**응답**:
```json
{
  "success": true,
  "data": {
    "email": "hong@university.ac.kr",
    "expiresAt": "2025-11-20T10:10:00Z"
  },
  "error": null,
  "timestamp": "2025-11-20T10:00:00Z"
}
```

### 1.5 POST /api/v1/users/professor-request
**설명**: 교수 인증 요청

**권한**: 인증된 사용자 (STUDENT)

**요청**:
```json
{
  "schoolEmail": "prof@university.ac.kr",
  "department": "컴퓨터공학과",
  "verificationCode": "123456"
}
```

**응답**: UserDto (professorStatus=PENDING)

---

## Domain 2: Group API (10개)

### 2.1 GET /api/v1/groups
**설명**: 그룹 목록 조회 (가입한 그룹 + 검색)

**권한**: 인증된 사용자

**쿼리 파라미터**:
- `limit` (기본 20)
- `offset` (기본 0)
- `sort` (recent|oldest|name)
- `search` (선택)
- `type` (AUTONOMOUS|OFFICIAL|...) (선택)

**응답**:
```json
{
  "success": true,
  "data": {
    "groups": [
      {
        "id": 1,
        "name": "컴퓨터공학과",
        "description": "...",
        "groupType": "DEPARTMENT",
        "memberCount": 150,
        "createdAt": "2025-01-01T00:00:00Z"
      }
    ],
    "total": 5,
    "limit": 20,
    "offset": 0
  },
  "error": null,
  "timestamp": "2025-11-20T10:00:00Z"
}
```

### 2.2 POST /api/v1/groups
**설명**: 그룹 생성

**권한**: 인증된 사용자

**요청**:
```json
{
  "name": "알고리즘 스터디",
  "description": "알고리즘 문제 풀이 스터디",
  "groupType": "AUTONOMOUS",
  "maxMembers": 30,
  "tags": ["알고리즘", "코딩테스트"]
}
```

**응답**: GroupDto

### 2.3 GET /api/v1/groups/{id}
**설명**: 그룹 상세 조회

**권한**: 그룹 멤버 or 공개 그룹

**응답**: GroupDto (상세 정보 + 멤버 수 + 채널 수)

### 2.4 PATCH /api/v1/groups/{id}
**설명**: 그룹 정보 수정

**권한**: GROUP_MANAGE 권한 필요

**요청**:
```json
{
  "description": "새로운 설명",
  "profileImageUrl": "https://...",
  "maxMembers": 50
}
```

**응답**: GroupDto

### 2.5 DELETE /api/v1/groups/{id}
**설명**: 그룹 삭제 (소프트 삭제)

**권한**: 그룹 오너만 (소유권 확인)

**응답**:
```json
{
  "success": true,
  "data": null,
  "error": null,
  "timestamp": "2025-11-20T10:00:00Z"
}
```

### 2.6 GET /api/v1/groups/{id}/members
**설명**: 그룹 멤버 목록 조회

**권한**: 그룹 멤버

**쿼리 파라미터**:
- `limit` (기본 20)
- `offset` (기본 0)
- `role` (역할 필터, 선택)

**응답**:
```json
{
  "success": true,
  "data": {
    "members": [
      {
        "userId": 1,
        "userName": "홍길동",
        "roleName": "그룹장",
        "joinedAt": "2025-01-01T00:00:00Z"
      }
    ],
    "total": 150,
    "limit": 20,
    "offset": 0
  },
  "error": null,
  "timestamp": "2025-11-20T10:00:00Z"
}
```

### 2.7 POST /api/v1/groups/{id}/members
**설명**: 그룹 멤버 추가 (초대 또는 가입 승인)

**권한**: MEMBER_MANAGE 권한 필요

**요청**:
```json
{
  "userId": 5,
  "roleId": 3
}
```

**응답**: GroupMemberDto

### 2.8 PATCH /api/v1/groups/{id}/members/{userId}
**설명**: 멤버 역할 변경

**권한**: MEMBER_MANAGE 권한 필요

**요청**:
```json
{
  "roleId": 2
}
```

**응답**: GroupMemberDto

### 2.9 DELETE /api/v1/groups/{id}/members/{userId}
**설명**: 멤버 강제 탈퇴 또는 자진 탈퇴

**권한**: MEMBER_MANAGE 권한 (강제) or 본인 (자진)

**응답**: 성공 메시지

### 2.10 GET /api/v1/groups/{id}/roles
**설명**: 그룹 역할 목록 조회

**권한**: 그룹 멤버

**응답**:
```json
{
  "success": true,
  "data": {
    "roles": [
      {
        "id": 1,
        "name": "그룹장",
        "isSystemRole": true,
        "roleType": "OPERATIONAL",
        "priority": 1,
        "permissions": ["GROUP_MANAGE", "MEMBER_MANAGE", "CHANNEL_MANAGE"]
      },
      {
        "id": 2,
        "name": "멤버",
        "isSystemRole": true,
        "roleType": "OPERATIONAL",
        "priority": 3,
        "permissions": []
      }
    ]
  },
  "error": null,
  "timestamp": "2025-11-20T10:00:00Z"
}
```

---

## Domain 3: Permission API (3개)

### 3.1 GET /api/v1/groups/{groupId}/permissions
**설명**: 현재 사용자의 그룹 내 권한 조회

**권한**: 그룹 멤버

**응답**:
```json
{
  "success": true,
  "data": {
    "groupPermissions": ["GROUP_MANAGE", "MEMBER_MANAGE"],
    "channelPermissions": {
      "1": ["POST_READ", "POST_WRITE", "COMMENT_WRITE"],
      "2": ["POST_READ"]
    }
  },
  "error": null,
  "timestamp": "2025-11-20T10:00:00Z"
}
```

### 3.2 POST /api/v1/groups/{groupId}/roles
**설명**: 커스텀 역할 생성

**권한**: MEMBER_MANAGE 권한 필요

**요청**:
```json
{
  "name": "부그룹장",
  "roleType": "OPERATIONAL",
  "priority": 2,
  "permissions": ["MEMBER_MANAGE", "CHANNEL_MANAGE"]
}
```

**응답**: GroupRoleDto

### 3.3 PATCH /api/v1/groups/{groupId}/roles/{roleId}
**설명**: 역할 수정 (시스템 역할은 수정 불가)

**권한**: MEMBER_MANAGE 권한 필요

**요청**:
```json
{
  "name": "수정된 이름",
  "priority": 3,
  "permissions": ["CHANNEL_MANAGE"]
}
```

**응답**: GroupRoleDto

---

## Domain 4: Workspace API (8개)

### 4.1 GET /api/v1/groups/{groupId}/workspaces
**설명**: 워크스페이스 목록 조회

**권한**: 그룹 멤버

**응답**:
```json
{
  "success": true,
  "data": {
    "workspaces": [
      {
        "id": 1,
        "name": "일반",
        "description": "일반 워크스페이스",
        "channelCount": 5
      }
    ]
  },
  "error": null,
  "timestamp": "2025-11-20T10:00:00Z"
}
```

### 4.2 POST /api/v1/groups/{groupId}/workspaces
**설명**: 워크스페이스 생성

**권한**: CHANNEL_MANAGE 권한 필요

**요청**:
```json
{
  "name": "프로젝트",
  "description": "프로젝트 관련 워크스페이스"
}
```

**응답**: WorkspaceDto

### 4.3 GET /api/v1/groups/{groupId}/channels
**설명**: 그룹 내 모든 채널 목록 조회 (워크스페이스별 그룹화)

**권한**: 그룹 멤버 (권한 있는 채널만 조회)

**응답**:
```json
{
  "success": true,
  "data": {
    "channels": [
      {
        "id": 1,
        "name": "공지사항",
        "type": "ANNOUNCEMENT",
        "workspaceId": 1,
        "workspaceName": "일반",
        "displayOrder": 1,
        "unreadCount": 5
      },
      {
        "id": 2,
        "name": "자유게시판",
        "type": "TEXT",
        "workspaceId": 1,
        "workspaceName": "일반",
        "displayOrder": 2,
        "unreadCount": 0
      }
    ]
  },
  "error": null,
  "timestamp": "2025-11-20T10:00:00Z"
}
```

### 4.4 POST /api/v1/groups/{groupId}/channels
**설명**: 채널 생성

**권한**: CHANNEL_MANAGE 권한 필요

**요청**:
```json
{
  "workspaceId": 1,
  "name": "새 채널",
  "description": "채널 설명",
  "type": "TEXT",
  "displayOrder": 3
}
```

**응답**: ChannelDto

### 4.5 GET /api/v1/groups/{groupId}/channels/{channelId}
**설명**: 채널 상세 조회

**권한**: 채널 접근 권한 (POST_READ) 필요

**응답**: ChannelDto (+ 권한 정보)

### 4.6 PATCH /api/v1/groups/{groupId}/channels/{channelId}
**설명**: 채널 정보 수정

**권한**: CHANNEL_MANAGE 권한 필요

**요청**:
```json
{
  "name": "수정된 이름",
  "description": "수정된 설명",
  "displayOrder": 5
}
```

**응답**: ChannelDto

### 4.7 DELETE /api/v1/groups/{groupId}/channels/{channelId}
**설명**: 채널 삭제

**권한**: CHANNEL_MANAGE 권한 필요

**응답**: 성공 메시지

### 4.8 PATCH /api/v1/channels/{channelId}/read-position
**설명**: 읽기 위치 업데이트

**권한**: 채널 접근 권한

**요청**:
```json
{
  "lastReadPostId": 42
}
```

**응답**:
```json
{
  "success": true,
  "data": {
    "channelId": 1,
    "lastReadPostId": 42,
    "updatedAt": "2025-11-20T10:00:00Z"
  },
  "error": null,
  "timestamp": "2025-11-20T10:00:00Z"
}
```

---

## Domain 5: Content API (9개)

### 5.1 GET /api/v1/channels/{channelId}/posts
**설명**: 채널 내 게시글 목록 조회

**권한**: POST_READ 권한 필요

**쿼리 파라미터**:
- `limit` (기본 20)
- `offset` (기본 0)
- `sort` (recent|oldest|popular)
- `type` (GENERAL|ANNOUNCEMENT|...) (선택)

**응답**:
```json
{
  "success": true,
  "data": {
    "posts": [
      {
        "id": 1,
        "channelId": 1,
        "authorId": 5,
        "authorName": "홍길동",
        "content": "게시글 내용",
        "type": "GENERAL",
        "isPinned": false,
        "viewCount": 120,
        "likeCount": 15,
        "commentCount": 8,
        "createdAt": "2025-11-20T09:00:00Z",
        "updatedAt": null
      }
    ],
    "total": 150,
    "limit": 20,
    "offset": 0
  },
  "error": null,
  "timestamp": "2025-11-20T10:00:00Z"
}
```

### 5.2 POST /api/v1/channels/{channelId}/posts
**설명**: 게시글 작성

**권한**: POST_WRITE 권한 필요

**요청**:
```json
{
  "content": "게시글 내용",
  "type": "GENERAL",
  "attachments": ["https://file1.jpg", "https://file2.pdf"]
}
```

**응답**: PostDto

### 5.3 GET /api/v1/posts/{postId}
**설명**: 게시글 상세 조회 (조회수 +1)

**권한**: POST_READ 권한 필요

**응답**: PostDto (댓글 포함)

### 5.4 PATCH /api/v1/posts/{postId}
**설명**: 게시글 수정

**권한**: 작성자 본인 or CHANNEL_MANAGE

**요청**:
```json
{
  "content": "수정된 내용",
  "attachments": ["https://new-file.jpg"]
}
```

**응답**: PostDto

### 5.5 DELETE /api/v1/posts/{postId}
**설명**: 게시글 삭제

**권한**: 작성자 본인 or CHANNEL_MANAGE

**응답**: 성공 메시지

### 5.6 GET /api/v1/posts/{postId}/comments
**설명**: 댓글 목록 조회

**권한**: POST_READ 권한 필요

**쿼리 파라미터**:
- `limit` (기본 50)
- `offset` (기본 0)

**응답**:
```json
{
  "success": true,
  "data": {
    "comments": [
      {
        "id": 1,
        "postId": 1,
        "authorId": 3,
        "authorName": "김철수",
        "content": "댓글 내용",
        "parentCommentId": null,
        "likeCount": 2,
        "createdAt": "2025-11-20T09:05:00Z"
      }
    ],
    "total": 8,
    "limit": 50,
    "offset": 0
  },
  "error": null,
  "timestamp": "2025-11-20T10:00:00Z"
}
```

### 5.7 POST /api/v1/posts/{postId}/comments
**설명**: 댓글 작성

**권한**: COMMENT_WRITE 권한 필요

**요청**:
```json
{
  "content": "댓글 내용",
  "parentCommentId": null
}
```

**응답**: CommentDto

### 5.8 PATCH /api/v1/comments/{commentId}
**설명**: 댓글 수정

**권한**: 작성자 본인

**요청**:
```json
{
  "content": "수정된 댓글"
}
```

**응답**: CommentDto

### 5.9 DELETE /api/v1/comments/{commentId}
**설명**: 댓글 삭제

**권한**: 작성자 본인 or CHANNEL_MANAGE

**응답**: 성공 메시지

---

## Domain 6: Calendar API (15개)

### 6.1 GET /api/v1/groups/{groupId}/events
**설명**: 그룹 일정 목록 조회

**권한**: 그룹 멤버

**쿼리 파라미터**:
- `startDate` (YYYY-MM-DD, 필수)
- `endDate` (YYYY-MM-DD, 필수)
- `type` (GENERAL|TARGETED|RSVP) (선택)
- `isOfficial` (true|false) (선택)

**응답**:
```json
{
  "success": true,
  "data": {
    "events": [
      {
        "id": 1,
        "groupId": 1,
        "title": "중간고사",
        "description": "...",
        "startDate": "2025-11-25T09:00:00Z",
        "endDate": "2025-11-25T11:00:00Z",
        "isAllDay": false,
        "isOfficial": true,
        "eventType": "GENERAL",
        "locationText": "공학관 301호",
        "color": "#3B82F6"
      }
    ]
  },
  "error": null,
  "timestamp": "2025-11-20T10:00:00Z"
}
```

### 6.2 POST /api/v1/groups/{groupId}/events
**설명**: 그룹 일정 생성

**권한**: CALENDAR_MANAGE 권한 필요 (isOfficial=true인 경우)

**요청**:
```json
{
  "title": "그룹 미팅",
  "description": "월례 회의",
  "startDate": "2025-11-25T14:00:00Z",
  "endDate": "2025-11-25T16:00:00Z",
  "isAllDay": false,
  "isOfficial": true,
  "eventType": "GENERAL",
  "locationText": "카페",
  "color": "#10B981"
}
```

**응답**: GroupEventDto

### 6.3 GET /api/v1/events/{eventId}
**설명**: 일정 상세 조회

**권한**: 그룹 멤버 (그룹 일정) or 본인 (개인 일정)

**응답**: GroupEventDto or PersonalEventDto

### 6.4 PATCH /api/v1/events/{eventId}
**설명**: 일정 수정

**권한**: 생성자 본인 or CALENDAR_MANAGE

**요청**:
```json
{
  "title": "수정된 제목",
  "startDate": "2025-11-26T14:00:00Z",
  "endDate": "2025-11-26T16:00:00Z"
}
```

**응답**: EventDto

### 6.5 DELETE /api/v1/events/{eventId}
**설명**: 일정 삭제

**권한**: 생성자 본인 or CALENDAR_MANAGE

**응답**: 성공 메시지

### 6.6 GET /api/v1/personal-events
**설명**: 개인 일정 목록 조회

**권한**: 본인

**쿼리 파라미터**:
- `startDate` (YYYY-MM-DD, 필수)
- `endDate` (YYYY-MM-DD, 필수)

**응답**: PersonalEventDto 목록

### 6.7 POST /api/v1/personal-events
**설명**: 개인 일정 생성

**권한**: 본인

**요청**:
```json
{
  "title": "개인 일정",
  "description": "...",
  "startDate": "2025-11-25T10:00:00Z",
  "endDate": "2025-11-25T12:00:00Z",
  "isAllDay": false,
  "color": "#F59E0B"
}
```

**응답**: PersonalEventDto

### 6.8 PATCH /api/v1/personal-events/{eventId}
**설명**: 개인 일정 수정

**권한**: 본인

**응답**: PersonalEventDto

### 6.9 DELETE /api/v1/personal-events/{eventId}
**설명**: 개인 일정 삭제

**권한**: 본인

**응답**: 성공 메시지

### 6.10 GET /api/v1/places
**설명**: 장소 목록 조회

**권한**: 인증된 사용자

**쿼리 파라미터**:
- `search` (선택)

**응답**: PlaceDto 목록

### 6.11 POST /api/v1/places
**설명**: 장소 생성

**권한**: ADMIN (글로벌)

**요청**:
```json
{
  "name": "공학관 301호",
  "description": "소회의실",
  "capacity": 20,
  "location": "공학관 3층"
}
```

**응답**: PlaceDto

### 6.12 GET /api/v1/places/{placeId}
**설명**: 장소 상세 조회

**권한**: 인증된 사용자

**응답**: PlaceDto (+ 운영시간, 휴무일 정보)

### 6.13 PATCH /api/v1/places/{placeId}
**설명**: 장소 정보 수정

**권한**: ADMIN

**응답**: PlaceDto

### 6.14 DELETE /api/v1/places/{placeId}
**설명**: 장소 삭제

**권한**: ADMIN

**응답**: 성공 메시지

### 6.15 GET /api/v1/places/{placeId}/availability
**설명**: 장소 예약 가능 시간 조회

**권한**: 인증된 사용자

**쿼리 파라미터**:
- `date` (YYYY-MM-DD, 필수)

**응답**:
```json
{
  "success": true,
  "data": {
    "placeId": 1,
    "placeName": "공학관 301호",
    "date": "2025-11-25",
    "availableSlots": [
      {
        "startTime": "09:00",
        "endTime": "10:00",
        "available": true
      },
      {
        "startTime": "10:00",
        "endTime": "11:00",
        "available": false
      }
    ]
  },
  "error": null,
  "timestamp": "2025-11-20T10:00:00Z"
}
```

---

## 검증 체크리스트

### API 설계 검증
- [x] 전체 엔드포인트 50개 이하 (현재: 47개)
- [x] 모든 응답은 ApiResponse<T> 형식
- [x] GET/POST/PATCH/DELETE만 사용 (PUT 금지)
- [x] 쿼리 파라미터 표준화 (limit, offset, sort, search)
- [x] 별도 엔드포인트 없음 (/recent, /popular 등)

### REST 원칙 검증
- [x] 리소스 중심 URL (/groups, /posts, /comments)
- [x] HTTP 메서드 의미 일관성 (GET=조회, POST=생성, PATCH=수정, DELETE=삭제)
- [x] 계층 구조 표현 (/groups/{id}/channels/{channelId})
- [x] 쿼리 파라미터로 필터링/정렬/검색 처리

### 권한 검증 패턴
- [x] 모든 엔드포인트에 권한 요구사항 명시
- [x] 권한 검증은 Controller 진입점에서 수행
- [x] 권한별로 다른 쿼리 실행 (역함수 패턴)

---

## 다음 단계

1. ✅ **Phase 0-1 완료**: Entity 설계서 작성
2. ✅ **Phase 0-2 완료**: API 엔드포인트 목록 작성
3. ⏭️ **Phase 0-3**: 도메인 의존성 그래프 작성 (`domain-dependencies.md`)
4. ⏭️ **Phase 0-4**: 마이그레이션 매핑표 작성 (`migration-mapping.md`)

---

## 참고 문서

- [마스터플랜](masterplan.md) - 전체 리팩터링 계획
- [Entity 설계서](entity-design.md) - 29개 Entity 구조
- [API 단순화](api-simplification.md) - REST API 원칙
- [권한 검증 패턴](permission-guard.md) - 역함수 패턴
