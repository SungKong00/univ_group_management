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

API 엔드포인트에 대한 전체 최신 명세는 아래 문서를 참고하십시오:

- **[API Conventions](api-conventions.md)**
