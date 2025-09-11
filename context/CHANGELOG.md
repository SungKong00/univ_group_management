# Context Changelog

## 2025-09-11

### Context Synchronization Update
- **CONTEXT**: 백엔드 코드와 컨텍스트 파일 간 불일치 해결 및 실제 구현 상태 반영
  - `database-design.md`: User 엔티티 실제 구현 반영, 미구현 엔티티들 명시
  - `architecture-overview.md`: 구현된 API만 반영, 미구현 기능 상태 표시
  - `feature-specifications.md`: 각 기능별 구현 상태 명확히 표시
  - `metadata.json`: 태그 업데이트 및 최신 작업 기록 추가
- **Main Issues Fixed**:
  - User 엔티티 스키마 불일치 (nickname, role 시스템 등)
  - 미구현 API 엔드포인트들의 문서화 문제
  - 계획된 기능과 실제 구현 상태의 혼재

### Refactor
- **CONTEXT**: Performed a major refactoring of the knowledge base. Consolidated scattered design documents from `docs/` into five comprehensive, agent-optimized files within the `context/` directory:
  - `architecture-overview.md`
  - `database-design.md`
  - `feature-specifications.md`
  - `process-conventions.md`
  - `project-plan.md`
- This change streamlines context synthesis for the AI workflow and improves the maintainability of the project's core knowledge.

---

- 초기화: 컨텍스트 디렉토리 생성 및 워크플로우 도입
- 2025-09-10T11:18:48Z archived task: tasks/archive/2025-09-10-api
- 2025-09-10T11:32:59Z archived task: tasks/archive/2025-09-10-api-2
- 2025-09-10T19:10:29Z archived task: tasks/archive/2025-09-11-flutter-api- 2025-09-11T02:41:06Z archived task: tasks/archive/2025-09-11-google-oauth2-api

## 2025-09-11 (Later)

### GlobalRole & PermissionEvaluator Alignment
- **User**: `role` → `globalRole (STUDENT|PROFESSOR|ADMIN)`로 변경 반영
- **Auth**: JWT 권한은 전역 역할만 포함 (`ROLE_STUDENT|PROFESSOR|ADMIN`)
- **Group Auth**: `Group`, `GroupMember`, `GroupRole(+permissions)`, `GroupPermission` 카탈로그 스캐폴딩 추가
- **Authorization**: Spring `PermissionEvaluator` 등록 및 헬퍼 제공 (`@security.hasGroupPerm`)
- **Frontend Context**: 사용자 모델 필드 `role` → `globalRole`로 변경
- 2025-09-11T08:04:04Z archived task: tasks/archive/2025-09-10-context

### Test Failures Resolution & Exception Handling Architecture
- **Testing**: 백엔드 테스트 실패 문제 해결 및 품질 보증 체계 확립
  - AuthController 테스트에서 빈 토큰 검증 시 HTTP 상태 코드 의미 구분
  - ValidationException 클래스 추가 (400 Bad Request 전용 예외)
  - IllegalArgumentException → 401 Unauthorized (인증 실패)
  - ValidationException → 400 Bad Request (잘못된 요청 데이터)
- **Exception Architecture**: 예외 처리 아키텍처 개선으로 HTTP 응답 코드 의미론적 정확성 확보
- **Quality Assurance**: 전체 테스트 스위트 안정성 확보 (BUILD SUCCESSFUL)
- 2025-09-11T08:33:55Z archived task: tasks/archive/2025-09-11-
- 2025-09-11T09:02:20Z archived task: tasks/archive/2025-09-11-task
- 2025-09-11T09:16:19Z archived task: tasks/archive/2025-09-11-task-2

## 2025-09-11: 프론트엔드 웹 인증 상태 이슈 해결 기록 추가
- Added: `context/frontend-auth-web-error-archive.md` (웹에서 뒤로가기/새로고침/로그아웃 시 인증 상태 붕괴 문제의 원인과 수정 내역 정리)
- Frontend changes (for traceability):
  - DI: Web 환경에서 `SharedPrefsTokenStorage` 사용
  - Routing: `initialRoute`를 Splash(`/`)로 변경하여 인증 판별 후 라우팅
  - Guards: 로그인/홈 화면에 인증 상태 기반 즉시 리다이렉트 추가
  - Logout UX: 로컬 세션 즉시 해제 후 백그라운드 네트워크 호출
