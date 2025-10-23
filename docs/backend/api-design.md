# API 설계 원칙

백엔드 REST API의 설계 패턴과 표준화 규칙입니다.

## 개요

RESTful 원칙 준수(A- 수준), 일관된 응답 형식, 통합 에러 처리로
안정적인 80+ 엔드포인트를 제공합니다.

## 핵심 설계 원칙

### 1. HTTP 메서드와 상태 코드
- `GET` - 조회 (200, 404)
- `POST` - 생성 (201 Created)
- `PUT` - 수정 (200 또는 204 No Content)
- `PATCH` - 부분 수정 (200 또는 204)
- `DELETE` - 삭제 (204 No Content)

### 2. 계층적 URL 구조
```
/api/groups/{groupId}/members
/api/groups/{groupId}/roles
/api/workspaces/{workspaceId}/channels
/api/channels/{channelId}/posts
/api/posts/{postId}/comments
```

### 3. 통일된 응답 형식
모든 응답은 `ApiResponse<T>` 래퍼 사용:
```kotlin
// 성공: { "success": true, "data": {...} }
// 에러: { "success": false, "error": {"code": "...", "message": "..."} }
```

### 4. 권한 검증 패턴
`@PreAuthorize("@security.hasGroupPerm(#groupId, 'PERMISSION_NAME')")`
- 403 Forbidden 자동 반환 (GlobalExceptionHandler)

## 코드 참조

**컨트롤러 파일:**
- `backend/src/main/kotlin/org/castlekong/backend/controller/GroupController.kt`
- `backend/src/main/kotlin/org/castlekong/backend/controller/ContentController.kt`
- `backend/src/main/kotlin/org/castlekong/backend/controller/AuthController.kt`

**기본 클래스:**
- `BaseController` - 사용자 조회 헬퍼 메서드
- `ApiResponse<T>` - 표준 응답 래퍼

**에러 처리:**
- `GlobalExceptionHandler` - 모든 예외의 통합 처리
- `ErrorCode` - 표준화된 에러 코드

## 주요 API 영역

1. **인증** (`/api/auth`)
2. **사용자** (`/api/users`, `/api/me`)
3. **그룹** (`/api/groups`, `/api/groups/{id}/...`)
4. **콘텐츠** (`/api/workspaces`, `/api/channels`, `/api/posts`, `/api/comments`)
5. **관리** (`/api/admin`, `/api/roles`)

## 관련 문서

- [API 엔드포인트](../implementation/api-reference.md) - 상세 명세
- [백엔드 가이드](../implementation/backend/README.md) - 구현 패턴
- **상세 분석**: `backend/check/api_design_analysis.md` 파일 참조 (A- 평가, 80+ 엔드포인트 분석)
