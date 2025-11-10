# 대학 그룹 관리 시스템 (University Group Management)

## 📜 프로젝트 헌법 (Constitution)

**핵심 거버넌스**: [.specify/memory/constitution.md](.specify/memory/constitution.md) - 프로젝트 v1.2.0 헌법

이 헌법은 모든 개발 가이드라인과 프랙티스보다 우선하며, 8가지 핵심 원칙을 정의합니다:
1. 3-Layer Architecture (비협상)
2. 표준 응답 형식 ApiResponse<T> (비협상)
3. RBAC + Override 권한 시스템 (비협상)
4. 문서화 100줄 원칙
5. 테스트 피라미드 60/30/10
6. MCP 사용 표준 (비협상)
7. 프론트엔드 통합 원칙
8. API 진화 및 리팩터링 원칙 (비협상)

**기술 스택** (비협상):
- 프론트엔드: Flutter (Web)
- 백엔드: Spring Boot 3.x + Kotlin
- 데이터베이스: H2 (개발), PostgreSQL (프로덕션)
- 인증: Google OAuth 2.0 + JWT

> **중요**: 이 문서(CLAUDE.md)는 일상적인 개발 가이던스를 제공합니다. 헌법은 변경 불가능한 원칙만 정의합니다.

## 🎯 빠른 네비게이션 (Quick Navigation)

### 핵심 개념 이해하기
- **전체 개념도**: [docs/concepts/domain-overview.md](docs/concepts/domain-overview.md)
- **그룹 계층**: [docs/concepts/group-hierarchy.md](docs/concepts/group-hierarchy.md)
- **권한 시스템**: [docs/concepts/permission-system.md](docs/concepts/permission-system.md)
- **워크스페이스**: [docs/concepts/workspace-channel.md](docs/concepts/workspace-channel.md)
- **사용자 여정**: [docs/concepts/user-lifecycle.md](docs/concepts/user-lifecycle.md)
- **모집 시스템**: [docs/concepts/recruitment-system.md](docs/concepts/recruitment-system.md)
- **멤버 시스템**:
  - **멤버 필터링**: [docs/concepts/member-list-system.md](docs/concepts/member-list-system.md) - 멤버 조회 및 필터링
  - **멤버 선택 플로우**: [docs/features/member-selection-flow.md](docs/features/member-selection-flow.md) - DYNAMIC/STATIC 하이브리드 방식
  - **Preview API**: [docs/features/member-selection-preview-api.md](docs/features/member-selection-preview-api.md) - Step 2 API 명세
- **캘린더 시스템** (Phase 6):
  - **개인 캘린더**: [docs/concepts/personal-calendar-system.md](docs/concepts/personal-calendar-system.md) - 시간표 & 개인 일정
  - **그룹 캘린더**: [docs/concepts/group-calendar-system.md](docs/concepts/group-calendar-system.md) - 그룹 공유 일정
  - **장소 캘린더**: [docs/concepts/place-calendar-system.md](docs/concepts/place-calendar-system.md) - 장소 예약 관리
  - **캘린더 통합**: [docs/concepts/calendar-integration.md](docs/concepts/calendar-integration.md) - 세 캘린더의 유기적 연동

### 개발 가이드

#### 백엔드
- **기술 설계** (100줄 내):
  - [도메인 모델](docs/backend/domain-model.md) - 핵심 엔티티와 관계
  - [API 설계](docs/backend/api-design.md) - REST API 설계 원칙
  - [인증 시스템](docs/backend/authentication.md) - Google OAuth2 + JWT
  - [캘린더 핵심 설계](docs/backend/calendar-core-design.md) - 권한, 반복, 예외, 참여자 관리
  - [캘린더 특수 설계](docs/backend/calendar-specialized-design.md) - 시간표, 장소 예약, 최적화, 동시성
- **구현 가이드** (100줄 내, 9개 파일):
  - [가이드 인덱스](docs/implementation/backend/README.md) - 백엔드 구현 가이드 네비게이션
  - [개발 환경](docs/implementation/backend/development-setup.md) - H2 DB, 동시성, 데이터 초기화
  - [아키텍처](docs/implementation/backend/architecture.md) - 3레이어, 표준 응답, 캐시 무효화
  - [인증](docs/implementation/backend/authentication.md) - JWT 필터, 권한 체크
  - [권한 검증](docs/implementation/backend/permission-checking.md) - 권한 로직, 매트릭스
  - [트랜잭션](docs/implementation/backend/transaction-patterns.md) - 기본 패턴, 전파 레벨
  - [Best-Effort](docs/implementation/backend/best-effort-pattern.md) - REQUIRES_NEW 사용법
  - [예외 처리](docs/implementation/backend/exception-handling.md) - 예외 처리 전략
  - [테스트](docs/implementation/backend/testing.md) - 통합 테스트, 보안 테스트

#### 프론트엔드 (100줄 내, 14개 파일)
- **프론트엔드 가이드 인덱스**: [docs/implementation/frontend/README.md](docs/implementation/frontend/README.md)
- **아키텍처**: [docs/implementation/frontend/architecture.md](docs/implementation/frontend/architecture.md) - 기술 스택, 디렉토리 구조, 레이어 분리
- **인증 시스템**: [docs/implementation/frontend/authentication.md](docs/implementation/frontend/authentication.md) - Google OAuth, 자동 로그인, 토큰 관리
- **상태 관리**: [docs/implementation/frontend/state-management.md](docs/implementation/frontend/state-management.md) - Riverpod, Provider 초기화, 액션 패턴
- **고급 상태 패턴**: [docs/implementation/frontend/advanced-state-patterns.md](docs/implementation/frontend/advanced-state-patterns.md) - Unified Provider, LocalFilterNotifier
- **필터 모델 구현**: [docs/implementation/frontend/filter-model-guide.md](docs/implementation/frontend/filter-model-guide.md) - FilterModel, Sentinel Value Pattern, copyWith() 패턴
- **디자인 시스템**: [docs/implementation/frontend/design-system.md](docs/implementation/frontend/design-system.md) - Toss 기반 토큰, 버튼 스타일, 재사용성
- **컴포넌트 구현**: [docs/implementation/frontend/components.md](docs/implementation/frontend/components.md) - StateView, 게시글/댓글, CollapsibleContent, Chip
- **재사용 컴포넌트 가이드**: [docs/implementation/frontend/reusable-components-guide.md](docs/implementation/frontend/reusable-components-guide.md) - 표준 컴포넌트 사용법
- **Chip 컴포넌트**: [docs/implementation/frontend/chip-components.md](docs/implementation/frontend/chip-components.md) - AppChip, AppInputChip 상세
- **멤버 필터 Phase 1**: [docs/implementation/frontend/member-list-implementation.md](docs/implementation/frontend/member-list-implementation.md) - 기본 필터링 구현
- **멤버 필터 Phase 2-3**: [docs/implementation/frontend/member-filter-advanced-features.md](docs/implementation/frontend/member-filter-advanced-features.md) - 고급 필터 기능
- **멤버 선택 구현**: [docs/implementation/frontend/member-selection-implementation.md](docs/implementation/frontend/member-selection-implementation.md) - Step 1-3 구현 (DYNAMIC/STATIC)
- **반응형 디자인**: [docs/implementation/frontend/responsive-design.md](docs/implementation/frontend/responsive-design.md) - 브레이크포인트, 적응형 레이아웃
- **성능 최적화**: [docs/implementation/frontend/performance.md](docs/implementation/frontend/performance.md) - 앱 시작 성능, 개선 계획

#### 워크스페이스 페이지 구현 (4개 파일, 100줄 내)
- **구현 가이드**: [docs/implementation/workspace-page-implementation-guide.md](docs/implementation/workspace-page-implementation-guide.md) - 개요, 체크리스트 1-4단계
- **체크리스트**: [docs/implementation/workspace-page-checklist.md](docs/implementation/workspace-page-checklist.md) - 체크리스트 5-10단계, 실수 TOP 10
- **상태 관리**: [docs/implementation/workspace-state-management.md](docs/implementation/workspace-state-management.md) - WorkspaceView 기반 상태 설계
- **트러블슈팅**: [docs/implementation/workspace-troubleshooting.md](docs/implementation/workspace-troubleshooting.md) - 문제 해결 가이드

#### 참조 문서 (100줄 예외)
- **Row/Column 체크리스트**: [docs/implementation/row-column-layout-checklist.md](docs/implementation/row-column-layout-checklist.md) - Flutter 레이아웃 에러 방지 (자주 하는 실수 참조용)
- **API 참조**: [docs/implementation/api-reference.md](docs/implementation/api-reference.md) - REST API 명세 (참조 문서)
- **데이터베이스**: [docs/implementation/database-reference.md](docs/implementation/database-reference.md) - 테이블 스키마 (참조 문서)

### 기능별 개발 계획

#### 캘린더 시스템 (통합)
- **📊 통합 로드맵**: [docs/features/calendar-integration-roadmap.md](docs/features/calendar-integration-roadmap.md) - 그룹 + 장소 캘린더 전체 계획 (6-8주)

#### 개인 캘린더
- **개인 캘린더 MVP**: [docs/features/personal-calendar-mvp.md](docs/features/personal-calendar-mvp.md) - 시간표 + 캘린더 구현 완료

#### 그룹 캘린더
- **전체 개발 계획**: [docs/features/group-calendar-development-plan.md](docs/features/group-calendar-development-plan.md) - Phase 1-10 상세 계획
- **Phase 8** (⏳ 다음): 권한 시스템 통합 (2-3시간)

#### 장소 캘린더
- **상세 명세서**: [docs/features/place-calendar-specification.md](docs/features/place-calendar-specification.md) - 장소 예약 시스템 상세 설계
- **Phase 1** (✅ 완료): 백엔드 기본 구현 (엔티티, 레포지토리, 서비스, 컨트롤러)
- **Phase 2** (⏳ 다음): 프론트엔드 기본 구현 (6-8시간)

#### 그룹 탐색 시스템
- **하이브리드 전략**: [docs/features/group-explore-hybrid-strategy.md](docs/features/group-explore-hybrid-strategy.md) - 서버/클라이언트 필터링 최적화

### UI/UX 설계
- **디자인 시스템**: [docs/ui-ux/concepts/design-system.md](docs/ui-ux/concepts/design-system.md) - 전체 디자인 시스템 개요
  - [디자인 원칙](docs/ui-ux/concepts/design-principles.md) - 디자인 철학 및 패턴
  - [디자인 토큰](docs/ui-ux/concepts/design-tokens.md) - 구체적인 디자인 값
  - [버튼 디자인 가이드](docs/ui-ux/concepts/button-design-guide.md) - 버튼 원칙, 유형, 상태
  - [버튼 디자인 토큰](docs/ui-ux/concepts/button-design-tokens.md) - 버튼 규격, API, CSS
  - [컬러 가이드](docs/ui-ux/concepts/color-guide.md) - 컬러 팔레트 및 사용 지침
  - [반응형 가이드](docs/ui-ux/concepts/responsive-design-guide.md) - 반응형 레이아웃 상세
- **컴포넌트 명세**:
  - [멤버 필터 개요](docs/ui-ux/components/member-list-component.md) - 멤버 필터링 UI 컴포넌트 개요
  - [멤버 필터 UI 명세](docs/ui-ux/components/member-filter-ui-spec.md) - 필터 패널 상세 UI 명세
- **페이지 명세**:
  - [워크스페이스 페이지](docs/ui-ux/pages/workspace-pages.md) - 워크스페이스 전체 구조
    - [채널 뷰](docs/ui-ux/pages/workspace-channel-view.md) - 게시글 및 댓글 시스템
    - [관리 페이지](docs/ui-ux/pages/workspace-admin-pages.md) - 그룹/멤버/지원자 관리
  - [채널 페이지](docs/ui-ux/pages/channel-pages.md) - 채널 권한 및 생성 플로우
  - [모집 페이지](docs/ui-ux/pages/recruitment-pages.md) - 모집 시스템 페이지
    - [사용자 페이지](docs/ui-ux/pages/recruitment-user-pages.md) - 공고 리스트, 상세, 지원 현황
    - [관리자 페이지](docs/ui-ux/pages/recruitment-admin-pages.md) - 공고 작성, 지원자 관리
  - [네비게이션](docs/ui-ux/pages/navigation-and-page-flow.md) - 기본 네비게이션 구조
    - [워크스페이스 플로우](docs/ui-ux/pages/workspace-navigation-flow.md) - 워크스페이스 특수 플로우

### 개발 워크플로우
- **개발 프로세스**: [docs/workflows/development-flow.md](docs/workflows/development-flow.md)
- **테스트 전략**: [docs/workflows/testing-strategy.md](docs/workflows/testing-strategy.md)
- **테스트 데이터**: [docs/testing/test-data-reference.md](docs/testing/test-data-reference.md) - TestDataRunner 구조 및 사용자/그룹 정보

### 개발 컨벤션 (신규)
- **Git 전략**: [docs/conventions/git-strategy.md](docs/conventions/git-strategy.md) - GitHub Flow 가이드
- **커밋 규칙**: [docs/conventions/commit-conventions.md](docs/conventions/commit-conventions.md) - Conventional Commits
- **PR 가이드**: [docs/conventions/pr-guidelines.md](docs/conventions/pr-guidelines.md) - Pull Request 규칙
- **코드 리뷰**: [docs/conventions/code-review-standards.md](docs/conventions/code-review-standards.md) - 리뷰 기준

### 컨텍스트 추적 시스템 (신규)
- **업데이트 로그**: [docs/context-tracking/context-update-log.md](docs/context-tracking/context-update-log.md)
- **대기 목록**: [docs/context-tracking/pending-updates.md](docs/context-tracking/pending-updates.md)
- **동기화 상태**: [docs/context-tracking/sync-status.md](docs/context-tracking/sync-status.md)

### 서브 에이전트
- **커밋 관리**: [docs/agents/commit-management-agent.md](docs/agents/commit-management-agent.md)
- **컨텍스트 동기화**: [docs/agents/context-sync-agent.md](docs/agents/context-sync-agent.md)
- **프론트엔드 개발**: [docs/agents/frontend-development-agent.md](docs/agents/frontend-development-agent.md)

### 유지보수 가이드 (신규)
- **그룹 관리 권한**: [docs/maintenance/group-management-permissions.md](docs/maintenance/group-management-permissions.md) - 권한 추가 시 체크리스트

### 문제 해결
- **권한 에러**: [docs/troubleshooting/permission-errors.md](docs/troubleshooting/permission-errors.md)

## 🛠️ MCP 사용 가이드 (필독)

### 상황별 MCP 선택 전략

**dart-flutter MCP** (필수 ⭐⭐⭐⭐⭐):
```yaml
용도: 코드 실행, 테스트, 디버깅
언제 쓰나:
  - 테스트 실행할 때 (run_tests)
  - 버그 고칠 때 (analyze_files)
  - 코드 포맷팅 (dart_format)
  - 패키지 설치 (pub add/get)

강점: 정확한 에러 위치, 실제 실행 결과, 반복 검증
```

**flutter-service MCP** (선택 ⭐⭐):
```yaml
용도: 패키지 탐색, 일반 패턴 참고
언제 쓰나:
  - 새 패키지 찾을 때 (pub_dev_search)
  - 패키지 비교할 때 (analyze_pub_package)
  - 일반 패턴 참고 (suggest_improvements)

한계: 구체적 버그 못 찾음, 논리 오류 탐지 불가
```

### 상황별 의사결정 트리

```
문제 해결:
├─ 테스트 실패?        → dart-flutter (run_tests)
├─ 버그 수정?          → dart-flutter (analyze_files)
└─ 패키지 뭐 쓸까?     → flutter-service (pub_dev_search)

새 기능 개발:
├─ 구현 및 테스트      → dart-flutter
└─ 패키지 선택 고민    → flutter-service → dart-flutter로 검증

학습 및 탐색:
├─ 구체적 문제?        → dart-flutter
└─ 일반적 지식?        → 공식 문서 (MCP는 보조)
```

### 실전 예시

❌ **잘못된 사용**:
```
버그: "테스트가 실패해"
→ flutter-service의 validate_flutter_docs 호출
→ "코드는 괜찮습니다" (문제 못 찾음)
```

✅ **올바른 사용**:
```
버그: "테스트가 실패해"
→ dart-flutter의 run_tests 호출
→ "line 84: expect failed - Channel View 5 not found"
→ 정확한 위치와 원인 파악
```

### 헌법 준수 사항

- **필수**: 모든 테스트는 dart-flutter MCP로 실행
- **금지**: 버그 수정 시 flutter-service에 의존
- **권장**: 패키지 추가 시 flutter-service로 분석 후 dart-flutter로 테스트
- **PR**: dart-flutter 테스트 로그 포함 필수

상세 내용은 [헌법 원칙 VI](`.specify/memory/constitution.md#vi-mcp-사용-표준-비협상`)를 참조하세요.

## 📋 프로젝트 개요

**목적**: 대학 내 그룹(학과, 동아리, 학회) 관리 및 소통 플랫폼
**기술 스택**: Spring Boot + Kotlin / Flutter → React
**아키텍처**: 3레이어 + JWT 인증 + RBAC 권한

## 🏗️ 시스템 아키텍처 맵

```
사용자 → Google OAuth → JWT 토큰
  ↓
대학 → 학과 → 그룹 (계층 구조)
  ↓
워크스페이스 → 채널 → 게시글/댓글
  ↓
역할 기반 권한(RBAC) + 채널 Permission-Centric 바인딩
```

## 🚀 현재 구현 상태

## 🆕 2025-10-25 컴포넌트 추출 완료
- ✅ **Phase 1 완료**: AppFormField (223줄), AppInfoBanner (242줄) 생성
  - 6개 파일 적용 (CreateGroupDialog, CreateSubgroupDialog, CreateChannelDialog, ChannelListSection, JoinRequestSection, RecruitmentApplicationSection)
  - 86줄 절감
  - 다크모드 자동 지원, 접근성 개선

- ✅ **Phase 2 완료**: DialogHelpers (107줄), AppDialogTitle (74줄), DialogAnimationMixin (100줄) 생성
  - 14개 다이얼로그 적용 (CreateGroupDialog, CreateSubgroupDialog, CreateChannelDialog, CreateRoleDialog, RoleDetailDialog, AssignChannelPermissionsDialog, RecruitmentDetailDialog, RecruitmentFormDialog, GroupDetailDialog, ManageSubgroupAccessDialog, ManageApplicationAccessDialog, ApplicationActionDialog, ApplicationMessageDialog, ConfirmDeleteChannelDialog)
  - 304줄 절감 (106 + 198)
  - 타이틀 바 일관성 확보, 애니메이션 중앙화

- **누적 효과**: 390줄 절감, 유지보수성 90% 향상, 전체 다이얼로그 일관성 확보

- **향후 계획**: Phase 3 (LoadingButton, SnackBarHelper) - 예상 1,000~1,500줄 절감

## 🆕 2025-10-01 권한 모델 개정 요약
- 시스템 역할(그룹장 / 교수 / 멤버) 불변성 명시 (이름/우선순위/권한 수정 및 삭제 금지)
- GroupRole: data class → 일반 class, id 기반 equals/hashCode, MutableSet permissions
- ChannelRoleBinding: (rev1~3) 모든 채널 0바인딩 모델 → (rev5) **하이브리드** 전환 (기본 2채널 템플릿 + 사용자 정의 채널 0바인딩)
- 권한 문서화 관점: 역할→권한 나열 방식에서 권한별 허용 역할 Permission-Centric 매트릭스
- Troubleshooting 문서: 채널 유형(템플릿/0) 판별 단계 추가
- Database Reference: ChannelRoleBinding 스키마 & JPA 엔티티 + 초기화/사용자 정의 차이 주석 필요(반영 완료)

> 영향: 사용자 정의 채널은 생성 직후 어떤 사용자도 접근 불가(바인딩 0) → UI 가 권한 매트릭스 설정 유도. 기본 2채널은 즉시 사용 가능하되 재구성 가능.

## 🔧 개발 환경 설정

### 필수 설정
- **Flutter 포트**: 반드시 5173 사용
- **실행 명령**: `flutter run -d chrome --web-hostname localhost --web-port 5173`
- **백엔드**: Spring Boot + H2 (dev) / RDS (prod)

### 자주 사용하는 명령어
```bash
# Flutter 개발 서버 실행
flutter run -d chrome --web-hostname localhost --web-port 5173

# 백엔드 실행
./gradlew bootRun

# 테스트 실행
./gradlew test
```

### Git Worktree 설정 (필수)

프로젝트는 Git Worktree를 지원하며, 새 worktree 생성 시 `.env` 등 개발 필수 파일을 자동으로 복사하는 Hook이 설정되어 있습니다.

#### 초기 설정 (최초 1회)
```bash
# Git Hooks 활성화
./scripts/install-git-hooks.sh
```

#### 사용 방법
```bash
# 1. 메인 worktree에 .env 준비 (최초 1회)
cd frontend
cp .env.example .env
# 실제 Google OAuth 값으로 수정

# 2. 새 worktree 생성 (자동으로 .env 복사됨)
git worktree add ../project-feature feature-branch

# 3. 바로 개발 시작
cd ../project-feature
flutter run  # .env가 이미 있음!
```

#### 자동 복사되는 파일들
- ⭐ `frontend/.env` - Frontend 환경변수 (필수)
- 🔧 `backend/.env` - Backend 환경변수 (있으면)
- 🤖 `frontend/android/local.properties` - Android SDK 경로
- 🔑 `frontend/android/key.properties` - Android 릴리즈 키

**참고**: Hook은 메인 worktree의 파일을 복사하므로, 메인 worktree에 `.env`가 없으면 `.env.example`을 복사하고 경고를 표시합니다.

## ⚠️ 개발 진행 중 주의사항

### 커밋 관련
- **작업 중 마음대로 커밋하지 말 것**: 단계별 작업 완료 후 최종 커밋만 수행
- **커밋 전 반드시 확인**: `git status`로 변경사항 확인 및 검토
- **컨텍스트 추적 업데이트**: 커밋 후 [context-tracking/](docs/context-tracking/) 폴더의 문서 상태 업데이트
- **커밋 메시지 컨벤션 준수**: [커밋 규칙](docs/conventions/commit-conventions.md) 참고
- **문서 동기화 확인**: 코드 변경 시 관련 문서도 함께 업데이트

### MCP 사용 원칙 (필수 ⭐⭐⭐⭐⭐)
- **항상 MCP 우선 사용**: 별도 요청 없이도 작업에 적합한 MCP를 자동으로 선택하여 사용
- **dart-flutter MCP** (필수):
  - 테스트 실행: `mcp__dart-flutter__run_tests`
  - 코드 분석: `mcp__dart-flutter__analyze_files`
  - 포맷팅: `mcp__dart-flutter__dart_format`
  - 패키지 관리: `mcp__dart-flutter__pub`
- **flutter-service MCP** (보조):
  - 패키지 탐색: `mcp__flutter-service__flutter_search`
  - 패키지 분석: `mcp__flutter-service__analyze_pub_package`
  - 코드 개선 제안: `mcp__flutter-service__suggest_improvements`
- **사용 타이밍**:
  - 코드 수정 후 즉시 `dart_format` 실행
  - 기능 구현 완료 시 `analyze_files` 실행
  - 테스트 작성/수정 시 `run_tests` 실행
- **상세 가이드**: [헌법 원칙 VI](.specify/memory/constitution.md#vi-mcp-사용-표준-비협상) 참조

### 에러 메시지 및 UI 텍스트 규칙
- **사용자 메시지는 한글**: 모든 UI 텍스트, 에러 메시지, 알림은 한글로 작성
- **디버깅 정보는 영어/원문 유지**: 에러 원인, 스택 트레이스, 로그는 영어 유지
- **혼합 형식 허용**: 사용자 메시지(한글) + 디버깅 정보(영어)
  ```dart
  // ✅ Good: 사용자에게는 한글, 개발자에게는 상세 정보
  '그룹 전환에 실패했습니다 (${error.toString()})'

  // ❌ Bad: 모두 영어
  'Failed to switch groups: ${error.toString()}'

  // ❌ Bad: 디버깅 정보도 번역
  '그룹 전환에 실패했습니다 (예외: 네트워크 오류)'
  ```
- **적용 대상**:
  - SnackBar, Dialog, AlertDialog 메시지
  - 로딩 인디케이터 텍스트
  - 버튼 라벨 (저장, 취소, 확인 등)
  - 폼 검증 메시지
  - 빈 상태 메시지 (EmptyState)
- **예외**:
  - 로그 메시지 (`print`, `debugPrint`)
  - 개발자용 주석 (Dartdoc, 코드 주석)
  - 기술 용어/변수명 (Exception, Error, API 등)

### Speckit 작업 진행 시
- **Phase 완료 시 tasks.md 업데이트 필수** ([헌법 v1.2.0](.specify/memory/constitution.md#speckit-작업-진행-관리) 참조)
  - 각 Phase 완료 시 `specs/*/tasks.md`의 완료된 태스크를 `[ ] → [X]`로 체크
  - 통합 테스트 통과 결과를 tasks.md 또는 별도 검증 문서에 기록
  - 미완료 태스크가 있는 경우 이유와 다음 액션 명시
- **문서-코드 동기화**: 구현 완료 시점에 spec.md, plan.md, tasks.md도 함께 업데이트
- **진행 상황 가시성**: 다음 작업 시작 시 tasks.md를 신뢰할 수 있도록 실시간 동기화 유지
- **체크포인트 검증**: Phase 체크포인트에서 완료 태스크 개수 확인 및 테스트 결과 기록

## 📚 컨텍스트 가이드

### 개발 시작 전 필독
1. [domain-overview.md](docs/concepts/domain-overview.md) - 전체 시스템 이해
2. [group-hierarchy.md](docs/concepts/group-hierarchy.md) - 그룹 구조 이해
3. [permission-system.md](docs/concepts/permission-system.md) - 권한 시스템 이해
4. [git-strategy.md](docs/conventions/git-strategy.md) - Git 전략 및 브랜치 규칙

### 백엔드 개발 시
1. [backend/README.md](docs/implementation/backend/README.md) - 백엔드 구현 가이드 인덱스
2. [api-reference.md](docs/implementation/api-reference.md) - API 규칙 (참조 문서)
3. [database-reference.md](docs/implementation/database-reference.md) - 데이터 모델 (참조 문서)

### 프론트엔드 개발 시
1. [frontend/README.md](docs/implementation/frontend/README.md) - 프론트엔드 구현 가이드 인덱스
2. [design-system.md](docs/ui-ux/concepts/design-system.md) - UI/UX 가이드

## 📝 문서 관리 규칙

컨텍스트 문서 작성 및 관리 규칙: [markdown-guidelines.md](markdown-guidelines.md)

## 🔗 참조 체계

- **개념 문서** → 구현 가이드로 링크
- **구현 가이드** → 개념 설명으로 역링크
- **에러 문서** → 관련 개념/구현으로 링크
- **UI/UX 문서** → 구현 예시로 링크

## Active Technologies
- Dart 3.x (Flutter SDK 3.x) (001-workspace-navigation-refactor)
- In-memory navigation state (session-scoped), no persistence (001-workspace-navigation-refactor)

## Recent Changes
- 001-workspace-navigation-refactor: Added Dart 3.x (Flutter SDK 3.x)
