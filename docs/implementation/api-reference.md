# API 참조 가이드 (API Reference)

## 인증 & 사용자 관리

### Google OAuth 로그인
```http
POST /api/auth/google/callback
Content-Type: application/json

{
  "id_token": "google_oauth_id_token"
}

Response:
{
  "success": true,
  "data": {
    "access_token": "jwt_token_here",
    "user": {
      "id": 1,
      "email": "user@gmail.com",
      "name": "김철수",
      "profileCompleted": false
    }
  }
}
```

### 프로필 설정
```http
POST /api/users/profile
Authorization: Bearer {jwt_token}
Content-Type: application/json

{
  "nickname": "철수짱",
  "department": "AI/SW 학부",
  "studentNo": "20241234",
  "globalRole": "STUDENT"
}

Response:
{
  "success": true,
  "data": {
    "id": 1,
    "nickname": "철수짱",
    "department": "AI/SW 학부",
    "profileCompleted": true
  }
}
```

### 닉네임 중복 확인
```http
GET /api/users/nickname-check?nickname=철수짱

Response:
{
  "success": true,
  "data": {
    "available": false,
    "suggestions": ["철수짱123", "철수왕", "철수님"]
  }
}
```

## 그룹 관리

### 그룹 생성
```http
POST /api/groups
Authorization: Bearer {jwt_token}
Content-Type: application/json

{
  "name": "AI 학회",
  "parentGroupId": 123,
  "visibility": "PUBLIC",
  "description": "AI 연구 및 스터디 그룹"
}

Response:
{
  "success": true,
  "data": {
    "id": 456,
    "name": "AI 학회",
    "visibility": "PUBLIC",
    "memberCount": 1,
    "createdAt": "2024-09-27T10:00:00Z"
  }
}
```

### 그룹 목록 조회
```http
GET /api/groups/explore?page=0&size=20&search=AI
Authorization: Bearer {jwt_token}

Response:
{
  "success": true,
  "data": {
    "content": [
      {
        "id": 456,
        "name": "AI 학회",
        "description": "AI 연구 및 스터디",
        "memberCount": 25,
        "visibility": "PUBLIC"
      }
    ],
    "totalElements": 1,
    "totalPages": 1
  }
}
```

### 그룹 가입 요청
```http
POST /api/groups/456/join
Authorization: Bearer {jwt_token}

Response:
{
  "success": true,
  "data": {
    "requestId": 789,
    "status": "PENDING",
    "requestedAt": "2024-09-27T10:30:00Z"
  }
}
```

### 가입 요청 승인/거부 {#가입승인}
```http
PATCH /api/groups/456/join-requests/789
Authorization: Bearer {jwt_token}
Content-Type: application/json

{
  "action": "APPROVE",  // or "REJECT"
  "note": "환영합니다!"
}

Response:
{
  "success": true,
  "data": {
    "requestId": 789,
    "status": "APPROVED",
    "processedAt": "2024-09-27T11:00:00Z"
  }
}
```

## 권한 관리

### 권한 체크 {#권한체크}
```http
GET /api/groups/456/permissions/check?permission=GROUP_MANAGE
Authorization: Bearer {jwt_token}

Response:
{
  "success": true,
  "data": {
    "hasPermission": true
  }
}
```

### 역할 생성 {#역할관리}
```http
POST /api/groups/456/roles
Authorization: Bearer {jwt_token}
Content-Type: application/json

{
  "name": "모더레이터",
  "permissions": ["CHANNEL_WRITE", "POST_DELETE_ANY", "MEMBER_KICK"],
  "description": "채널 및 컨텐츠 관리"
}

Response:
{
  "success": true,
  "data": {
    "id": 10,
    "name": "모더레이터",
    "permissions": ["CHANNEL_WRITE", "POST_DELETE_ANY", "MEMBER_KICK"],
    "isSystemRole": false
  }
}
```

### 멤버 역할 변경
```http
PATCH /api/groups/456/members/123/role
Authorization: Bearer {jwt_token}
Content-Type: application/json

{
  "roleId": 10
}

Response:
{
  "success": true,
  "data": {
    "userId": 123,
    "groupId": 456,
    "roleName": "모더레이터",
    "updatedAt": "2024-09-27T12:00:00Z"
  }
}
```

## 워크스페이스 & 채널

### 워크스페이스 목록 {#워크스페이스}
```http
GET /api/groups/456/workspaces
Authorization: Bearer {jwt_token}

Response:
{
  "success": true,
  "data": [
    {
      "id": 100,
      "name": "메인 워크스페이스",
      "description": "기본 워크스페이스",
      "channelCount": 3
    }
  ]
}
```

### 채널 생성 {#채널관리}
```http
POST /api/workspaces/100/channels
Authorization: Bearer {jwt_token}
Content-Type: application/json

{
  "name": "개발논의",
  "type": "TEXT",
  "isPrivate": false,
  "description": "개발 관련 논의"
}

Response:
{
  "success": true,
  "data": {
    "id": 200,
    "name": "개발논의",
    "type": "TEXT",
    "isPrivate": false,
    "displayOrder": 1
  }
}
```

### 채널 목록
```http
GET /api/workspaces/100/channels
Authorization: Bearer {jwt_token}

Response:
{
  "success": true,
  "data": [
    {
      "id": 200,
      "name": "일반대화",
      "type": "TEXT",
      "isPrivate": false,
      "displayOrder": 0
    },
    {
      "id": 201,
      "name": "공지사항",
      "type": "ANNOUNCEMENT",
      "isPrivate": false,
      "displayOrder": 1
    }
  ]
}
```

## 컨텐츠 관리

### 게시글 목록 {#컨텐츠}
```http
GET /api/channels/200/posts?page=0&size=20
Authorization: Bearer {jwt_token}

Response:
{
  "success": true,
  "data": {
    "content": [
      {
        "id": 1001,
        "title": "안녕하세요!",
        "content": "첫 게시글입니다.",
        "type": "GENERAL",
        "author": {
          "id": 123,
          "nickname": "철수짱"
        },
        "isPinned": false,
        "commentCount": 5,
        "createdAt": "2024-09-27T09:00:00Z"
      }
    ]
  }
}
```

### 게시글 작성
```http
POST /api/channels/200/posts
Authorization: Bearer {jwt_token}
Content-Type: application/json

{
  "title": "프로젝트 아이디어",
  "content": "새로운 프로젝트 아이디어를 공유합니다...",
  "type": "GENERAL"
}

Response:
{
  "success": true,
  "data": {
    "id": 1002,
    "title": "프로젝트 아이디어",
    "content": "새로운 프로젝트 아이디어를 공유합니다...",
    "author": {
      "id": 123,
      "nickname": "철수짱"
    },
    "createdAt": "2024-09-27T13:00:00Z"
  }
}
```

### 댓글 작성
```http
POST /api/posts/1002/comments
Authorization: Bearer {jwt_token}
Content-Type: application/json

{
  "content": "좋은 아이디어네요!",
  "parentCommentId": null  // 대댓글인 경우 부모 댓글 ID
}

Response:
{
  "success": true,
  "data": {
    "id": 2001,
    "content": "좋은 아이디어네요!",
    "author": {
      "id": 124,
      "nickname": "영희님"
    },
    "depth": 0,
    "createdAt": "2024-09-27T13:30:00Z"
  }
}
```

## 그룹 계층 관리

### 하위 그룹 생성 요청 {#그룹계층}
```http
POST /api/groups/456/sub-groups/requests
Authorization: Bearer {jwt_token}
Content-Type: application/json

{
  "name": "프로젝트팀 A",
  "description": "캡스톤 프로젝트팀",
  "visibility": "PRIVATE"
}

Response:
{
  "success": true,
  "data": {
    "requestId": 5001,
    "groupName": "프로젝트팀 A",
    "status": "PENDING",
    "requestedAt": "2024-09-27T14:00:00Z"
  }
}
```

### 하위 그룹 목록 {#계층조회}
```http
GET /api/groups/456/sub-groups
Authorization: Bearer {jwt_token}

Response:
{
  "success": true,
  "data": [
    {
      "id": 457,
      "name": "프로젝트팀 A",
      "memberCount": 4,
      "createdAt": "2024-09-25T10:00:00Z"
    }
  ]
}
```

## 모집 시스템

### 모집 게시글 작성
```http
POST /api/groups/{groupId}/recruitments
Authorization: Bearer {jwt_token}
Content-Type: application/json

{
  "title": "2024년 신입 멤버 모집",
  "content": "프로그래밍에 관심있는 신입생을 모집합니다.",
  "maxApplicants": 20,
  "recruitmentEndDate": "2024-03-15T23:59:59",
  "autoApprove": false,
  "showApplicantCount": true,
  "applicationQuestions": [
    "프로그래밍 경험을 간단히 작성해주세요.",
    "동아리 활동에 대한 기대를 적어주세요."
  ]
}

Response:
{
  "success": true,
  "data": {
    "id": 1,
    "group": {
      "id": 5,
      "name": "프로그래밍 동아리"
    },
    "title": "2024년 신입 멤버 모집",
    "content": "프로그래밍에 관심있는 신입생을 모집합니다.",
    "maxApplicants": 20,
    "currentApplicantCount": 0,
    "recruitmentEndDate": "2024-03-15T23:59:59",
    "status": "OPEN",
    "autoApprove": false,
    "showApplicantCount": true,
    "applicationQuestions": [
      "프로그래밍 경험을 간단히 작성해주세요.",
      "동아리 활동에 대한 기대를 적어주세요."
    ],
    "createdAt": "2024-02-01T10:00:00",
    "updatedAt": "2024-02-01T10:00:00"
  }
}
```

### 활성 모집 게시글 조회
```http
GET /api/groups/{groupId}/recruitments
Authorization: Bearer {jwt_token}

Response:
{
  "success": true,
  "data": {
    "id": 1,
    "title": "2024년 신입 멤버 모집",
    "currentApplicantCount": 15,
    "status": "OPEN"
  }
}
```

### 그룹 가입 지원
```http
POST /api/recruitments/{recruitmentId}/applications
Authorization: Bearer {jwt_token}
Content-Type: application/json

{
  "motivation": "프로그래밍을 체계적으로 배우고 싶어서 지원합니다.",
  "questionAnswers": {
    "0": "Python과 JavaScript 기초 문법을 알고 있습니다.",
    "1": "다양한 프로젝트를 통해 실력을 향상시키고 싶습니다."
  }
}

Response:
{
  "success": true,
  "data": {
    "id": 101,
    "recruitment": {
      "id": 1,
      "title": "2024년 신입 멤버 모집"
    },
    "applicant": {
      "id": 10,
      "name": "김신입",
      "nickname": "신입이"
    },
    "motivation": "프로그래밍을 체계적으로 배우고 싶어서 지원합니다.",
    "status": "PENDING",
    "appliedAt": "2024-02-15T14:30:00"
  }
}
```

### 지원서 심사
```http
PATCH /api/applications/{applicationId}/review
Authorization: Bearer {jwt_token}
Content-Type: application/json

{
  "action": "APPROVE",
  "reviewComment": "적극적인 자세가 좋습니다. 환영합니다!"
}

Response:
{
  "success": true,
  "data": {
    "id": 101,
    "status": "APPROVED",
    "reviewedBy": {
      "id": 5,
      "name": "김회장",
      "nickname": "회장님"
    },
    "reviewedAt": "2024-02-20T10:00:00",
    "reviewComment": "적극적인 자세가 좋습니다. 환영합니다!"
  }
}
```

### 공개 모집 검색
```http
GET /api/recruitments/public?keyword=프로그래밍&page=0&size=20

Response:
{
  "success": true,
  "data": [
    {
      "id": 1,
      "groupId": 5,
      "groupName": "프로그래밍 동아리",
      "title": "2024년 신입 멤버 모집",
      "maxApplicants": 20,
      "currentApplicantCount": 15,
      "recruitmentEndDate": "2024-03-15T23:59:59",
      "status": "OPEN",
      "createdAt": "2024-02-01T10:00:00"
    }
  ],
  "pagination": {
    "page": 0,
    "size": 20,
    "totalElements": 3,
    "totalPages": 1
  }
}
```

## 에러 응답 형식

### 권한 부족
```http
HTTP/1.1 403 Forbidden
Content-Type: application/json

{
  "success": false,
  "data": null,
  "error": {
    "code": "INSUFFICIENT_PERMISSION",
    "message": "해당 작업을 수행할 권한이 없습니다"
  }
}
```

### 유효성 검증 실패
```http
HTTP/1.1 400 Bad Request
Content-Type: application/json

{
  "success": false,
  "data": null,
  "error": {
    "code": "VALIDATION_FAILED",
    "message": "입력값이 올바르지 않습니다",
    "details": {
      "nickname": "닉네임은 2-20자 사이여야 합니다",
      "studentNo": "학번 형식이 올바르지 않습니다"
    }
  }
}
```

### 리소스 없음
```http
HTTP/1.1 404 Not Found
Content-Type: application/json

{
  "success": false,
  "data": null,
  "error": {
    "code": "RESOURCE_NOT_FOUND",
    "message": "요청한 그룹을 찾을 수 없습니다"
  }
}
```

## 공통 헤더

### 인증 헤더
```http
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 페이징 파라미터
```http
GET /api/groups?page=0&size=20&sort=name,asc
```

### 검색 파라미터
```http
GET /api/groups/explore?search=AI&category=STUDY
```

## 관련 문서

### 백엔드 구현
- **백엔드 가이드**: [backend-guide.md](backend-guide.md)
- **데이터베이스**: [database-reference.md](database-reference.md)

### 프론트엔드 연동
- **프론트엔드 가이드**: [frontend-guide.md](frontend-guide.md)

### 도메인 개념
- **권한 시스템**: [../concepts/permission-system.md](../concepts/permission-system.md)
- **그룹 계층**: [../concepts/group-hierarchy.md](../concepts/group-hierarchy.md)
- **워크스페이스**: [../concepts/workspace-channel.md](../concepts/workspace-channel.md)
- **모집 시스템**: [../concepts/recruitment-system.md](../concepts/recruitment-system.md)
- **사용자 여정**: [../concepts/user-lifecycle.md](../concepts/user-lifecycle.md)

### 문제 해결
- **권한 에러**: [../troubleshooting/permission-errors.md](../troubleshooting/permission-errors.md)
