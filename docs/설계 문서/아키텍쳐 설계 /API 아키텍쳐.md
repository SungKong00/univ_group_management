# API 아키텍쳐

## ## API 설계 원칙

이 문서는 프로젝트의 모든 API가 따라야 할 설계 원칙과 규칙을 정의합니다. 일관성 있는 API는 프론트엔드와 백엔드 간의 협업 효율을 극대화하고, 시스템 전체의 안정성을 높입니다.

### 1. 기본 원칙

- **RESTful 원칙 준수:** HTTP Method(GET, POST, PUT, DELETE 등)와 URL(URI)을 통해 자원(Resource)을 표현하고 조작하는 REST의 기본 원칙을 따릅니다.
- **URL 버전 정보 미포함:** MVP의 단순성을 위해, API 주소에 `/api/v1/`과 같은 버전 정보는 포함하지 않습니다.

---

### 2. API 응답 구조 (Standard Response Format)

모든 API 응답은 아래와 같은 일관된 JSON 객체(Envelope)로 감싸서 전달합니다.

JSON

`{
    "success": boolean,
    "data": { ... },
    "error": { ... }
}`

### **✅ 성공 응답 (Success Response)**

요청이 성공적으로 처리되었을 경우 `success` 필드는 항상 `true`이며, `error` 필드는 `null`입니다.

- **데이터가 있는 경우 (예: `GET /api/users/me`)** `data` 필드에 요청한 결과 데이터가 담깁니다.JSON
    
    `{
        "success": true,
        "data": {
            "userId": 1,
            "email": "user@example.com",
            "nickname": "민준"
        },
        "error": null
    }`
    
- **데이터가 없는 경우 (예: `DELETE /api/posts/1`)** `data` 필드는 `null`이 됩니다.JSON
    
    `{
        "success": true,
        "data": null,
        "error": null
    }`
    

### **❌ 실패 응답 (Error Response)**

요청 처리 중 문제가 발생했을 경우 `success` 필드는 항상 `false`이며, `data` 필드는 `null`입니다.

- `error` 필드에는 **고유 에러 코드(`code`)**와 **에러 메시지(`message`)**가 포함됩니다.
- **예시: 인증 실패 시**JSON
    
    `{
        "success": false,
        "data": null,
        "error": {
            "code": "AUTH_001",
            "message": "인증 토큰이 유효하지 않습니다."
        }
    }`
    

---

### 3. 주요 HTTP 상태 코드 활용

JSON 응답 내용과 더불어, 상황에 맞는 HTTP 상태 코드를 함께 사용하여 명확한 소통을 지향합니다.

- **`200 OK`**: `GET`, `PUT`, `PATCH` 요청 성공 시
- **`201 Created`**: `POST` 요청으로 새로운 리소스가 성공적으로 생성되었을 시
- **`204 No Content`**: 요청은 성공했지만 응답할 내용이 없을 시 (예: `DELETE` 성공)
- **`400 Bad Request`**: 요청 파라미터가 잘못되었거나, 데이터 유효성 검사 실패 시
- **`401 Unauthorized`**: 로그인이 필요한 기능에 인증 없이 접근했을 시 (토큰 부재/만료)
- **`403 Forbidden`**: 로그인은 했지만 해당 리소스에 접근할 권한이 없을 시
- **`404 Not Found`**: 요청한 리소스(URL)를 찾을 수 없을 시
- **`500 Internal Server Error`**: 예측하지 못한 서버 내부의 에러 발생 시

모든 API 개발은 위 규칙을 기준으로 진행합니다.