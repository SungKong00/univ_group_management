# Context Changelog

## 2025-09-13

### Onboarding + Auth Flow Alignment (Single Screen) & Domain Policy
- Backend
  - Added `/api/auth/google/callback { id_token }` and kept `/api/auth/google` as fallback
  - Added `/api/users` (onboarding submit), `/api/me` (alias), `/api/users/nickname-check`, `/api/email/verification/send|verify`, `/api/roles/apply`
  - `User` entity extended (`department`, `studentNo`, `schoolEmail`, `professorStatus`), `emailVerified` default true (OTP deferred)
  - `LoginResponse` now includes `firstLogin` for frontend routing
  - Email domain whitelist default set to `hs.ac.kr`
- Frontend
  - Replaced two-step onboarding with single screen (`/onboarding`)
  - Wired nickname duplicate check (debounce + suggestions)
  - Shows professor pending banner on Home via `/api/me`
  - Removed obsolete screens: `role_selection_screen.dart`, `profile_setup_screen.dart`
- Docs/Context
  - Updated `context/frontend-architecture.md` (routes, screens, onboarding UX details)
  - Updated `context/api-conventions.md` (auth endpoints, onboarding submit, nickname-check, email OTP, default domain)
  - Updated `context/security.md` (public endpoints include `/auth/google/callback`, domain policy `hs.ac.kr`)
  - Updated `context/feature-specifications.md` (single-screen onboarding, OTP/approval deferred)
  - Updated `context/project-plan.md` (MVP priorities and deferrals for auth)

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
- 2025-09-12T00:38:56Z archived task: tasks/archive/2025-09-12-task
- 2025-09-12T01:16:28Z archived task: tasks/archive/2025-09-12-task
- 2025-09-12T01:27:33Z archived task: tasks/archive/2025-09-12-flutter-const-apiresponse
- 2025-09-12T05:30:58Z archived task: tasks/archive/2025-09-12-flutter
- 2025-09-12T05:46:29Z archived task: tasks/archive/2025-09-12-flutter-null-to-num

### Fix: Flutter null to num 타입 에러 해결 (페이지네이션 응답 처리 구현)
- **Problem**: 백엔드 API가 페이지네이션 응답 구조로 변경되어 Flutter 앱에서 타입 에러 발생
- **Root Cause**: 기존 `{success: true, data: [...]}` 형태에서 `{success: true, data: {content: [...], pageable: {...}}}` 형태로 응답 구조 변경
- **Solution**: GroupService.getGroups() 메서드에 유연한 응답 처리 로직 추가
  - 레거시 형태(직접 리스트)와 페이지네이션 형태 모두 지원
  - data.content 배열 추출 기능 구현
  - 안전한 타입 체크를 통한 데이터 파싱
- **Files Changed**: `frontend/lib/data/services/group_service.dart`
- **Documentation Updates**:
  - `context/troubleshooting.md`: 섹션 9 "페이지네이션 응답 처리 문제" 추가
  - `context/api-conventions.md`: 섹션 1.4 "페이지네이션 응답 규칙" 추가
  - `context/CHANGELOG.md`: 이번 수정사항 기록
  - `.gemini/metadata.json`: pagination, api-response-handling 태그 추가 및 recent_tasks 갱신
- 2025-09-12T09:14:37Z archived task: tasks/archive/2025-09-12-numberformatexception

## 2025-09-12: Flutter Web /groups 오류·로그인 경고 개선

### Fix: `/groups` 호출 시 간헐적 `Error: null /groups` 반복 출력
- 로깅 강화: 에러 타입/메시지 추가 출력으로 진단 개선 (`DioClient`)
- 리트라이 추가: 연결 오류/타임아웃/응답 없음 케이스에서 최대 2회 백오프 재시도 (`GroupService.getGroups`)
- JSON 파싱 안정화: `GroupModel.fromJson`을 안전 파서로 교체(널/타입 변형 허용, `tags` 기본값 [])
- Files: `frontend/lib/core/network/dio_client.dart`, `frontend/lib/data/services/group_service.dart`, `frontend/lib/data/models/group_model.dart`

### Chore: Google Sign-In 웹 경고 완화 준비
- Google Identity Services 스크립트 포함 (`web/index.html`)
- 향후 `renderButton` 마이그레이션을 위한 기반 구성 (현재는 기존 `signIn()` 유지)

### DX: 에러 메시지 가독성 향상
- 그룹 목록 조회 실패 시 구체 메시지 표시 (`GroupProvider.loadGroups`)

### Docs: 컨텍스트/트러블슈팅 업데이트
- `context/troubleshooting.md`: 웹에서 `Error: null /groups` 증상/원인/해결 섹션 추가
- `context/architecture-overview.md` 및 `context/frontend-architecture.md`: 차기 작업 노트에 GIS 버튼 도입 계획 명시 (N/A if already present)
- 2025-09-12T11:29:48Z archived task: tasks/archive/2025-09-12-task
- 2025-09-12T13:17:36Z archived task: tasks/archive/2025-09-12-task

## 2025-09-12: 그룹 가입신청 본문/그룹 상세 라우트 추가 (Minimal Flow)

### Frontend
- Join Request 본문 지원: `GroupService.joinGroup(int, {String? message})`로 확장하여 `POST /api/groups/{id}/join` 호출 시 `{ "message": "..." }` 페이로드 전송.
- Provider 시그니처 동기화: `GroupProvider.joinGroup(int, {String? message})`로 갱신.
- 그룹 상세 라우트 추가: `'/group'` 경로 등록, `GroupDetailScreen(groupId)` 추가. 기본 정보 표시 + 가입신청 메시지 입력/전송 기능 제공.

### Docs/Context 업데이트
- `context/api-conventions.md`: 그룹 가입신청 엔드포인트 요청 본문에 `message`(optional) 명시.
- `context/frontend-architecture.md`: 라우트 맵에 `'/group'` 추가, GroupProvider/GroupService 기반 상세 화면 존재 표기.
- `context/feature-specifications.md`: 그룹/워크스페이스 상태를 "부분 구현"으로 갱신(그룹 상세/가입신청 최소 흐름 구현), 미구현 항목 명시 유지.

### 참고 파일
- Frontend: `frontend/lib/data/services/group_service.dart`, `frontend/lib/presentation/providers/group_provider.dart`, `frontend/lib/presentation/screens/groups/group_detail_screen.dart`, `frontend/lib/main.dart`

## 2025-09-12: 가입 신청 관리 UI(목록/승인/반려) 최소 추가

### Frontend
- `GroupDetailScreen`에 가입 신청 관리 섹션 추가: 새로고침으로 목록 로드, 각 항목에 대해 '승인/반려' 액션 버튼 제공.
- Provider 연계: `GroupProvider.loadJoinRequests`, `processJoinRequest` 사용.

### Docs/Context 업데이트
- `context/frontend-architecture.md`: `GroupDetailScreen` 설명에 가입 신청 관리(최소 UI) 포함.
- `context/feature-specifications.md`: 현재 구현 범위에 "가입 신청 관리(목록/승인/반려) 최소 UI" 추가.

## 2025-09-12: 멤버 관리(역할 변경/강제 탈퇴) 최소 추가 + 백엔드 엔드포인트

### Backend
- DTO: `UpdateMemberRoleRequest(roleId: Long)` 추가.
- Controller: 멤버 역할 변경 `PUT /api/groups/{groupId}/members/{userId}/role`, 멤버 강제 탈퇴 `DELETE /api/groups/{groupId}/members/{userId}` 추가.
- Service: `updateMemberRole(...)`, `removeMember(...)` 구현. (그룹장만 허용, OWNER 역할 변경은 위임 API 사용 유도)

### Frontend
- Provider: `GroupProvider.updateMemberRole(...)` 추가.
- UI: `GroupDetailScreen`에 멤버 관리 카드 추가(역할 드롭다운/변경 버튼, 강제 탈퇴 버튼, 새로고침으로 멤버/역할 로드).

### Docs/Context 업데이트
- `context/frontend-architecture.md`: GroupDetailScreen에 멤버 관리(역할 변경/강제 탈퇴) 최소 UI와 Provider 호출 목록 업데이트.
- `context/feature-specifications.md`: 현재 구현 범위에 멤버 관리 최소 UI 포함.

## 2025-09-12: 그룹 삭제 UX 강화 (이름 입력 확인)

### Frontend
- `GroupDetailScreen`에 그룹 삭제 섹션 추가: 그룹명 입력 시에만 삭제 버튼 활성화.
- 삭제 시 워닝 문구(연쇄 삭제, 영구 삭제) 노출 및 성공 후 `/groups`로 라우팅.

### Backend
- 기존 `DELETE /api/groups/{groupId}` 엔드포인트 사용 (소유자 검증 및 연쇄 삭제는 서비스에서 처리).

### Docs/Context 업데이트
- `context/frontend-architecture.md`: 그룹 상세 화면에 삭제 UX 포함 명시.
- `context/feature-specifications.md`: 데이터/정책(연쇄 삭제) 경고 문구와 삭제 UX 반영.
- `context/frontend-maintenance.md`: 위험 동작 시 이름 입력 확인 가이드 추가.

## 2025-09-12: 하위 그룹 생성 신청/관리 최소 추가

### Frontend
- GroupDetailScreen에 하위 그룹 생성 폼 추가(그룹명/설명/대학/단과대/학과/최대 인원) 및 제출 후 스낵바 피드백.
- 하위 그룹 신청 관리 카드 추가(그룹장 전용): 목록/승인/반려 + 새로고침, 승인 시 하위 그룹 목록 갱신.
- 하위 그룹 목록 카드 추가: 서브그룹 리스트와 상세 이동.

### Frontend Providers/Services
- Service: `createSubGroupRequest`, `getSubGroupRequests`, `reviewSubGroupRequest`, `getSubGroups` 추가.
- Provider: `loadSubGroups`, `createSubGroupRequest`, `loadSubGroupRequests`, `reviewSubGroupRequest` 추가 및 상태 보관.

### Docs/Context 업데이트
- `context/api-conventions.md`: 하위 그룹(서브그룹) 신청/관리/조회 엔드포인트 표 추가.
- `context/frontend-architecture.md`: GroupDetailScreen 기능 목록에 하위 그룹 생성/관리/목록 포함.
- `context/feature-specifications.md`: 현재 구현 범위에 하위 그룹 생성/관리 최소 UI 반영.


## 2025-09-12: 화면/권한 UX 손질 (관리 섹션 표기/확인 팝업)

### Frontend UX
- 관리 섹션(가입 신청 관리, 하위 그룹 신청 관리, 멤버 관리, 지도교수 관리, 그룹 삭제)을 그룹장에게만 표시.
- 승인/반려, 강제 탈퇴, 지도교수 해제, 그룹 삭제 등 중요/파괴적 액션에 확인 팝업 추가.
- 그룹 삭제 입력 변화에 따른 버튼 활성화 즉시 반영(입력 리스너 기반).

### Docs/Context 업데이트
- `context/frontend-architecture.md`: 관리 섹션의 소유자 전용 표기 및 Provider 호출 목록에 지도교수 관련 메서드 포함.
- `context/api-conventions.md`: 지도교수 관리 엔드포인트 표 추가.


## 2025-09-12: 워크스페이스/채널/게시글/댓글 백엔드 컨트롤러(최소 구현)

### Backend
- Repos: ChannelRepository, PostRepository, CommentRepository 추가.
- DTO: `ContentDto.kt` (Channel/Post/Comment 요청·응답 모델) 추가.
- Service: `ContentService` 추가 — 그룹당 단일 기본 워크스페이스(호환) 제공, 채널/게시글/댓글 CRUD 구현.
- Controller: `ContentController` 추가 — 프론트 호출 경로(`/groups/{id}/workspaces`, `/workspaces/{id}/channels`, `/channels/{id}/posts`, `/posts/{id}/comments` 등) 구현. 워크스페이스 생성/수정/삭제는 호환 목적의 no-op/반환으로 처리.

### Docs/Context 업데이트
- `context/api-conventions.md`: 해당 엔드포인트가 실제 구현됨을 반영(지도교수 표와 함께).
- `context/frontend-architecture.md`: 상세 화면에서 채널/게시글/댓글 연동의 백엔드 구현 상태 일치.


## 2025-09-12: 채널/게시글 최소 UI 연동 (그룹 상세)

### Frontend
- GroupDetailScreen에 채널/게시글 섹션 추가: 워크스페이스 호환으로 groupId를 workspaceId로 사용.
- 채널: 목록/새로고침/생성(다이얼로그) → 생성 후 목록 갱신.
- 게시글: 선택된 채널 기준 목록 표시, 제목/내용 입력 후 게시.

### Docs/Context 업데이트
- `context/frontend-architecture.md`: GroupDetailScreen 기능 목록에 채널/게시글 최소 UI 반영.


## 2025-09-13: 그룹 탐색/소프트 삭제/개인 권한 오버라이드

### Backend
- Group: `deletedAt` 필드 추가, 그룹 삭제를 소프트 삭제(30일 보존)로 전환. 삭제 시 하위 그룹은 부모로 리패런팅.
- GroupService: 하드 삭제 재귀 로직 제거, 소프트 삭제 + 리패런팅 구현. `purgeSoftDeletedGroups(before)` 유지보수 메서드 추가.
- 검색: `/api/groups/explore` 엔드포인트 추가(모집/가시성/학교 계층/검색어/태그 필터 지원).
- 권한 오버라이드: `GroupMemberPermissionOverride` 엔티티/리포지토리 추가. `GET/PUT /api/groups/{id}/members/{userId}/permissions` 구현.
- Security: `GroupPermissionEvaluator`가 오버라이드(allowed/denied)를 반영해 유효 권한 계산하도록 수정.
- ContentService: 소프트 삭제 그룹 접근 시 `GROUP_NOT_FOUND` 처리.

### Docs/Context 업데이트
- `context/database-design.md`: `deleted_at` 필드와 개인 권한 오버라이드 테이블 추가.
- `context/api-conventions.md`: `/api/groups/explore`와 개인 권한 오버라이드 API 표 추가, 소프트 삭제 접근 정책 메모 추가.
- `context/feature-specifications.md`: 그룹 삭제 데이터 정책을 소프트 삭제/리패런팅으로 갱신, 권한 관리 상태를 부분 구현으로 갱신.

### Frontend
- 라우트 추가: `/explore` (그룹 탐색/검색 화면). 홈의 [그룹 검색] 빠른 접근이 `/explore`로 이동.
- ExploreScreen: 검색어/태그/모집중 필터 UI + 결과 리스트(탭 시 그룹 상세 이동).
- GroupDetailScreen: 멤버 행에 [권한 오버라이드] 버튼 추가 → 허용/차단 권한 콤마 입력 다이얼로그(효과적 권한 미리보기) → 저장 시 API 호출.
 - GroupDetailScreen: 지도교수 관리 UI 추가 — 이름/이메일 검색으로 후보 지정, 교수 목록 관리(해제 포함).
 - GroupDetailScreen: 그룹 삭제 UX를 바텀 시트 강력 확인(소프트 삭제/리패런팅 정책 안내 + 빨간 버튼)으로 변경.
- Dev seed & signup defaulting:
  - Seed user `castlekong1019@gmail.com` and groups hierarchy `한신대학교` → `AI/SW 대학` → `AI/SW 학부` at startup.
  - On signup profile submit, default `department` to `AI/SW 학부` if blank and auto-join `AI/SW 학부` when present.
## 2025-09-13: 워크스페이스/채널/관리자/신청 현황 정책 확정

### Decisions
- Group-Workspace: 1:1 (슬랙형). 워크스페이스 내부에 여러 채널 생성 가능.
- 채널 권한: 채널 관리 권한자가 채널 CRUD/초대 관리. 채널 단위로 조회/작성 제한.
- 핀 기능: 미사용(비활성).
- 삭제: 초기 단계는 단순 삭제(즉시 삭제, 하위그룹 삭제 동작은 관리자 정책에 따름). 향후 보존 기능은 별도 검토.
- 관리자 탭: 공식 그룹 신청/멤버 가입 신청을 처리하는 관리자 탭 추가.
- 마이페이지: '내 신청 현황' 간단 목록 추가(가입/하위그룹).

### Context Updates
- feature-specifications.md: 위 결정사항 반영 (워크스페이스 1:1, 채널 권한, 핀 비활성, 삭제 정책, 관리자/신청 현황 추가).
- frontend-architecture.md: 라우트에 `/admin/...`, `/me/applications` 추가, 그룹 상세는 워크스페이스 1:1 전제로 설명 보완.
- api-conventions.md: 마이페이지/관리자 API 초안 엔드포인트 표 추가.
- security.md: 권한 카테고리 제안(Workspace/Channel/Post/Comment) 추가.
- 2025-09-16T07:37:56Z archived task: tasks/archive/2025-09-16-task
- 2025-09-18T18:40:46Z archived task: tasks/archive/2025-09-19-ui
- 2025-09-18T23:59:16Z archived task: tasks/archive/2025-09-19-task-2
