# 대학 그룹 관리 시스템 (University Group Management)

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

#### 프론트엔드 (100줄 내, 13개 파일)
- **프론트엔드 가이드 인덱스**: [docs/implementation/frontend/README.md](docs/implementation/frontend/README.md)
- **아키텍처**: [docs/implementation/frontend/architecture.md](docs/implementation/frontend/architecture.md) - 기술 스택, 디렉토리 구조, 레이어 분리
- **인증 시스템**: [docs/implementation/frontend/authentication.md](docs/implementation/frontend/authentication.md) - Google OAuth, 자동 로그인, 토큰 관리
- **상태 관리**: [docs/implementation/frontend/state-management.md](docs/implementation/frontend/state-management.md) - Riverpod, Provider 초기화, 액션 패턴
- **고급 상태 패턴**: [docs/implementation/frontend/advanced-state-patterns.md](docs/implementation/frontend/advanced-state-patterns.md) - Unified Provider, LocalFilterNotifier
- **필터 모델 구현**: [docs/implementation/frontend/filter-model-guide.md](docs/implementation/frontend/filter-model-guide.md) - FilterModel, Sentinel Value Pattern, copyWith() 패턴
- **디자인 시스템**: [docs/implementation/frontend/design-system.md](docs/implementation/frontend/design-system.md) - Toss 기반 토큰, 버튼 스타일, 재사용성
- **컴포넌트 구현**: [docs/implementation/frontend/components.md](docs/implementation/frontend/components.md) - StateView, 게시글/댓글, CollapsibleContent, Chip
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

## ⚠️ 개발 진행 중 주의사항

### 커밋 관련
- **작업 중 마음대로 커밋하지 말 것**: 단계별 작업 완료 후 최종 커밋만 수행
- **커밋 전 반드시 확인**: `git status`로 변경사항 확인 및 검토
- **컨텍스트 추적 업데이트**: 커밋 후 [context-tracking/](docs/context-tracking/) 폴더의 문서 상태 업데이트
- **커밋 메시지 컨벤션 준수**: [커밋 규칙](docs/conventions/commit-conventions.md) 참고
- **문서 동기화 확인**: 코드 변경 시 관련 문서도 함께 업데이트

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
