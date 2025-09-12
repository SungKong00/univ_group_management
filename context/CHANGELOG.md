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
- 2025-09-11T10:21:30Z archived task: tasks/archive/2025-09-11-task-2
- 2025-09-11T10:42:51Z archived task: tasks/archive/2025-09-11-flutter

### Context Updates - JSON 직렬화 에러 & Flutter 빌드 문제 해결
- **Updated**: `context/frontend-auth-web-error-archive.md` 
  - Added JSON 직렬화 에러 해결 사례 섹션
  - Flutter 웹 환경에서의 타입 불일치 문제 및 해결방법 문서화
  - build_runner 코드 생성 동기화 방법 추가
- **Updated**: `context/troubleshooting.md`
  - Flutter 빌드 관련 문제 해결 섹션 대폭 강화
  - Android/iOS/웹 빌드 실패 상황별 해결책 추가
  - 종속성 충돌, 빌드 성능 최적화, CI/CD 빌드 문제 등 포괄적 가이드 추가
- **Links**: 
  - JSON 직렬화 문제: `/Users/nohsungbeen/univ/2025-2/project/personal_project/univ_group_management/context/frontend-auth-web-error-archive.md#json-직렬화-에러-해결-사례`
  - Flutter 빌드 가이드: `/Users/nohsungbeen/univ/2025-2/project/personal_project/univ_group_management/context/troubleshooting.md#3-빌드-관련-문제`
- 2025-09-11T11:12:16Z archived task: tasks/archive/2025-09-11-api

### API 응답 형태 일치 작업 완료
- **CONTEXT**: 백엔드와 프론트엔드 간 API 응답 형태 표준화 완료
  - 프론트엔드 AuthService가 백엔드의 표준 ApiResponse 래퍼 형태 `{ "success": true, "data": {...} }`를 정확히 파싱하도록 수정
  - Google 로그인 API의 응답을 LoginResponse 객체로 직접 변환하여 처리
  - AuthRepository, AuthProvider 전체 레이어에서 타입 일치성 확보
- **Future Reference**: 향후 다른 API 엔드포인트들도 동일한 표준 형태로 수정 필요 시 이 작업을 참고
- 2025-09-11T20:12:00Z archived task: tasks/archive/2025-09-11-api
- 2025-09-11T14:27:32Z archived task: tasks/archive/2025-09-11-task-2
- 2025-09-11T15:15:08Z archived task: tasks/archive/2025-09-11-oauth2
- 2025-09-11T15:18:14Z archived task: tasks/archive/2025-09-11-task

## 2025-09-12: 회원가입 단계 라우팅/프로필 완성/닉네임 표시 업데이트

### Fix: 신규 사용자 역할 선택 화면이 즉시 홈으로 넘어가던 문제
- 로그인 화면의 인증 가드를 `profileCompleted` 기준으로 분기하도록 수정
- 네비게이션 시 `pushNamedAndRemoveUntil` 사용으로 스택 충돌 제거
- Files: `frontend/lib/presentation/screens/auth/login_screen.dart`, `frontend/lib/main.dart`

### Fix: 프로필 완성 시 401/403 "접근 권한 없음" 오류
- 프로필 완료 API 엔드포인트를 상수 `ApiEndpoints.updateProfile`로 사용 (상대 경로 `/users/profile`)
- Files: `frontend/lib/data/services/auth_service.dart`

### UX: 홈 인사말/아바타 이니셜 닉네임 기준으로 변경
- 인사말: 닉네임 존재 시 닉네임 우선, 없으면 이름으로 폴백
- 아바타: 닉네임 첫 글자 → 이름 첫 글자 → 'U'
- Files: `frontend/lib/presentation/screens/home/home_screen.dart`

### Docs: 컨텍스트/트러블슈팅 업데이트
- `context/feature-specifications.md`: 프로필 완성 엔드포인트를 `PUT /api/users/profile`로 정정, 닉네임 표시 규칙 추가
- `context/frontend-architecture.md`: 엔드포인트 상수 사용, 네비게이션 레이스 방지 가이드 명시
- `context/frontend-auth-web-error-archive.md`: 역할 선택 화면 플래시 및 프로필 완성 403 이슈 해결 기록 추가
- `context/troubleshooting.md`: 5.3(해결), 5.4 섹션 추가
- `context/frontend-maintenance.md`: 프런트 유지보수 가이드 신설 (라우팅/엔드포인트/토큰/닉네임 규칙/체크리스트)
- 2025-09-12T00:04:17Z archived task: tasks/archive/2025-09-12-task
- 2025-09-12T00:14:38Z archived task: tasks/archive/2025-09-12-task
