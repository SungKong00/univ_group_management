# API 설계 규약

## REST API 설계 원칙

### 기본 원칙
- RESTful 설계 패턴 준수
- HTTP 메서드의 의미에 맞는 사용
- 일관된 URL 구조 및 네이밍
- 명확한 HTTP 상태 코드 반환
- JSON 기반 데이터 교환

### Base URL 구조
```
# 개발 환경
http://localhost:8080/api/v1

# 프로덕션 환경 (예정)
https://api.univ-group.example.com/v1
```

## URL 설계 규칙

### 네이밍 규칙
- **리소스명**: 소문자, 복수형, kebab-case 사용
- **경로 구조**: `/api/v{version}/{resource}/{id}/{sub-resource}`
- **쿼리 파라미터**: snake_case 사용

### 리소스 URL 예시
```
# 사용자 관리
GET    /api/v1/users              # 사용자 목록 조회
POST   /api/v1/users              # 새 사용자 생성
GET    /api/v1/users/{id}         # 특정 사용자 조회
PUT    /api/v1/users/{id}         # 사용자 정보 전체 수정
PATCH  /api/v1/users/{id}         # 사용자 정보 부분 수정
DELETE /api/v1/users/{id}         # 사용자 삭제

# 그룹 관리
GET    /api/v1/groups             # 그룹 목록 조회
POST   /api/v1/groups             # 새 그룹 생성
GET    /api/v1/groups/{id}        # 특정 그룹 조회
PUT    /api/v1/groups/{id}        # 그룹 정보 수정
DELETE /api/v1/groups/{id}        # 그룹 삭제

# 그룹 멤버 관리
GET    /api/v1/groups/{id}/members    # 그룹 멤버 목록
POST   /api/v1/groups/{id}/members    # 그룹에 멤버 추가
DELETE /api/v1/groups/{id}/members/{user_id}  # 그룹에서 멤버 제거
```

## HTTP 메서드 사용 규칙

| 메서드 | 용도 | 멱등성 | 안전성 |
|--------|------|--------|--------|
| GET | 리소스 조회 | O | O |
| POST | 리소스 생성 | X | X |
| PUT | 리소스 전체 교체 | O | X |
| PATCH | 리소스 부분 수정 | X | X |
| DELETE | 리소스 삭제 | O | X |

## 응답 형식 표준

### 성공 응답 구조
```json
{
  "success": true,
  "data": {
    // 실제 데이터
  },
  "message": "요청이 성공적으로 처리되었습니다.",
  "timestamp": "2025-09-10T16:30:00Z"
}
```

### 에러 응답 구조
```json
{
  "success": false,
  "error": {
    "code": "USER_NOT_FOUND",
    "message": "사용자를 찾을 수 없습니다.",
    "details": "ID 123에 해당하는 사용자가 존재하지 않습니다."
  },
  "timestamp": "2025-09-10T16:30:00Z",
  "path": "/api/v1/users/123"
}
```

### 페이지네이션 응답
```json
{
  "success": true,
  "data": {
    "content": [
      // 데이터 배열
    ],
    "page": {
      "number": 0,
      "size": 20,
      "total_elements": 150,
      "total_pages": 8,
      "first": true,
      "last": false
    }
  }
}
```

## HTTP 상태 코드 사용 기준

### 성공 응답 (2xx)
- **200 OK**: 일반적인 성공 (GET, PUT, PATCH)
- **201 Created**: 리소스 생성 성공 (POST)
- **204 No Content**: 성공했지만 반환할 데이터 없음 (DELETE)

### 클라이언트 에러 (4xx)
- **400 Bad Request**: 잘못된 요청 형식
- **401 Unauthorized**: 인증 필요
- **403 Forbidden**: 권한 부족
- **404 Not Found**: 리소스를 찾을 수 없음
- **409 Conflict**: 리소스 충돌 (중복 생성 등)
- **422 Unprocessable Entity**: 유효성 검증 실패

### 서버 에러 (5xx)
- **500 Internal Server Error**: 서버 내부 오류
- **503 Service Unavailable**: 서버 일시 사용 불가

## DTO 설계 규칙

### Request DTO
```kotlin
// 사용자 생성 요청
data class CreateUserRequest(
    @field:NotBlank(message = "이름은 필수입니다")
    val name: String,
    
    @field:Email(message = "유효한 이메일 형식이어야 합니다")
    val email: String,
    
    @field:Size(min = 6, message = "비밀번호는 최소 6자 이상이어야 합니다")
    val password: String
)
```

### Response DTO
```kotlin
// 사용자 응답
data class UserResponse(
    val id: Long,
    val name: String,
    val email: String,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime
)
```

## 에러 코드 정의

### 사용자 관련 에러
- `USER_NOT_FOUND`: 사용자를 찾을 수 없음
- `USER_ALREADY_EXISTS`: 이미 존재하는 사용자
- `INVALID_USER_DATA`: 유효하지 않은 사용자 데이터

### 그룹 관련 에러
- `GROUP_NOT_FOUND`: 그룹을 찾을 수 없음
- `GROUP_ALREADY_EXISTS`: 이미 존재하는 그룹
- `GROUP_MEMBER_LIMIT_EXCEEDED`: 그룹 멤버 제한 초과

### 인증/인가 에러
- `AUTHENTICATION_REQUIRED`: 인증 필요
- `INVALID_TOKEN`: 유효하지 않은 토큰
- `ACCESS_DENIED`: 접근 권한 없음
- `TOKEN_EXPIRED`: 토큰 만료

## 버전 관리

### API 버전 정책
- URL 경로에 버전 명시: `/api/v1/...`
- 하위 호환성 유지 원칙
- 주요 변경 시에만 버전 업
- 이전 버전 최소 6개월 지원

### 버전 변경 기준
- **Major 변경**: 기존 API 호환성 중단
- **Minor 변경**: 새로운 기능 추가 (하위 호환)
- **Patch 변경**: 버그 수정, 성능 개선

## 보안 고려사항

### 인증 헤더
```
Authorization: Bearer {JWT_TOKEN}
```

### CORS 설정
```kotlin
@CrossOrigin(
    origins = ["http://localhost:3000", "https://univ-group.example.com"],
    allowedHeaders = ["*"],
    methods = [RequestMethod.GET, RequestMethod.POST, RequestMethod.PUT, 
               RequestMethod.PATCH, RequestMethod.DELETE]
)
```

### 민감 데이터 처리
- 비밀번호는 응답에 포함하지 않음
- 개인정보는 필요한 경우에만 노출
- 로그에 민감 정보 기록 금지

## API 문서화

### OpenAPI 3.0 (Swagger) 활용
- 모든 API 엔드포인트 문서화
- Request/Response 스키마 정의
- 에러 응답 예시 포함
- 인증 방법 명시

### 접근 경로
```
# Swagger UI
http://localhost:8080/swagger-ui/index.html

# OpenAPI JSON
http://localhost:8080/v3/api-docs
```