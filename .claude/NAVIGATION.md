# 📚 문서 네비게이션 (Document Navigation)

> 이 문서는 프로젝트의 모든 문서 링크를 모아놓은 참조용 인덱스입니다.
> 필요할 때 찾아보세요.

## 핵심 개념 이해하기

- **전체 개념도**: [docs/concepts/domain-overview.md](../docs/concepts/domain-overview.md)
- **그룹 계층**: [docs/concepts/group-hierarchy.md](../docs/concepts/group-hierarchy.md)
- **권한 시스템**: [docs/concepts/permission-system.md](../docs/concepts/permission-system.md)
- **워크스페이스**: [docs/concepts/workspace-channel.md](../docs/concepts/workspace-channel.md)
- **사용자 여정**: [docs/concepts/user-lifecycle.md](../docs/concepts/user-lifecycle.md)
- **모집 시스템**: [docs/concepts/recruitment-system.md](../docs/concepts/recruitment-system.md)
- **멤버 시스템**:
  - **멤버 필터링**: [docs/concepts/member-list-system.md](../docs/concepts/member-list-system.md)
  - **멤버 선택 플로우**: [docs/features/member-selection-flow.md](../docs/features/member-selection-flow.md)
  - **Preview API**: [docs/features/member-selection-preview-api.md](../docs/features/member-selection-preview-api.md)
- **캘린더 시스템**:
  - **개인 캘린더**: [docs/concepts/personal-calendar-system.md](../docs/concepts/personal-calendar-system.md)
  - **그룹 캘린더**: [docs/concepts/group-calendar-system.md](../docs/concepts/group-calendar-system.md)
  - **장소 캘린더**: [docs/concepts/place-calendar-system.md](../docs/concepts/place-calendar-system.md)
  - **캘린더 통합**: [docs/concepts/calendar-integration.md](../docs/concepts/calendar-integration.md)

## 개발 가이드

### 백엔드
- **기술 설계**:
  - [도메인 모델](../docs/backend/domain-model.md)
  - [API 설계](../docs/backend/api-design.md)
  - [인증 시스템](../docs/backend/authentication.md)
  - [캘린더 핵심 설계](../docs/backend/calendar-core-design.md)
  - [캘린더 특수 설계](../docs/backend/calendar-specialized-design.md)
- **구현 가이드**:
  - [가이드 인덱스](../docs/implementation/backend/README.md)
  - [개발 환경](../docs/implementation/backend/development-setup.md)
  - [아키텍처](../docs/implementation/backend/architecture.md)
  - [인증](../docs/implementation/backend/authentication.md)
  - [권한 검증](../docs/implementation/backend/permission-checking.md)
  - [트랜잭션](../docs/implementation/backend/transaction-patterns.md)
  - [Best-Effort](../docs/implementation/backend/best-effort-pattern.md)
  - [예외 처리](../docs/implementation/backend/exception-handling.md)
  - [테스트](../docs/implementation/backend/testing.md)

### 프론트엔드
- [가이드 인덱스](../docs/implementation/frontend/README.md)
- [아키텍처](../docs/implementation/frontend/architecture.md)
- [인증 시스템](../docs/implementation/frontend/authentication.md)
- [상태 관리](../docs/implementation/frontend/state-management.md)
- [고급 상태 패턴](../docs/implementation/frontend/advanced-state-patterns.md)
- [필터 모델 구현](../docs/implementation/frontend/filter-model-guide.md)
- [디자인 시스템](../docs/implementation/frontend/design-system.md)
- [컴포넌트 구현](../docs/implementation/frontend/components.md)
- [재사용 컴포넌트 가이드](../docs/implementation/frontend/reusable-components-guide.md)
- [Chip 컴포넌트](../docs/implementation/frontend/chip-components.md)
- [멤버 필터 Phase 1](../docs/implementation/frontend/member-list-implementation.md)
- [멤버 필터 Phase 2-3](../docs/implementation/frontend/member-filter-advanced-features.md)
- [멤버 선택 구현](../docs/implementation/frontend/member-selection-implementation.md)
- [반응형 디자인](../docs/implementation/frontend/responsive-design.md)
- [성능 최적화](../docs/implementation/frontend/performance.md)

### 워크스페이스 페이지
- [구현 가이드](../docs/implementation/workspace-page-implementation-guide.md)
- [체크리스트](../docs/implementation/workspace-page-checklist.md)
- [상태 관리](../docs/implementation/workspace-state-management.md)
- [트러블슈팅](../docs/implementation/workspace-troubleshooting.md)

### 참조 문서
- [Row/Column 체크리스트](../docs/implementation/row-column-layout-checklist.md)
- [API 참조](../docs/implementation/api-reference.md)
- [데이터베이스](../docs/implementation/database-reference.md)

## 기능별 개발 계획

### 캘린더 시스템
- [통합 로드맵](../docs/features/calendar-integration-roadmap.md)
- [개인 캘린더 MVP](../docs/features/personal-calendar-mvp.md)
- [그룹 캘린더 개발 계획](../docs/features/group-calendar-development-plan.md)
- [장소 캘린더 명세](../docs/features/place-calendar-specification.md)

### 그룹 탐색 시스템
- [하이브리드 전략](../docs/features/group-explore-hybrid-strategy.md)

## UI/UX 설계

### 디자인 시스템
- [디자인 시스템 개요](../docs/ui-ux/concepts/design-system.md)
- [디자인 원칙](../docs/ui-ux/concepts/design-principles.md)
- [디자인 토큰](../docs/ui-ux/concepts/design-tokens.md)
- [버튼 디자인 가이드](../docs/ui-ux/concepts/button-design-guide.md)
- [버튼 디자인 토큰](../docs/ui-ux/concepts/button-design-tokens.md)
- [컬러 가이드](../docs/ui-ux/concepts/color-guide.md)
- [반응형 가이드](../docs/ui-ux/concepts/responsive-design-guide.md)

### 컴포넌트 명세
- [멤버 필터 개요](../docs/ui-ux/components/member-list-component.md)
- [멤버 필터 UI 명세](../docs/ui-ux/components/member-filter-ui-spec.md)

### 페이지 명세
- [워크스페이스 페이지](../docs/ui-ux/pages/workspace-pages.md)
- [채널 뷰](../docs/ui-ux/pages/workspace-channel-view.md)
- [관리 페이지](../docs/ui-ux/pages/workspace-admin-pages.md)
- [채널 페이지](../docs/ui-ux/pages/channel-pages.md)
- [모집 페이지](../docs/ui-ux/pages/recruitment-pages.md)
- [사용자 페이지](../docs/ui-ux/pages/recruitment-user-pages.md)
- [관리자 페이지](../docs/ui-ux/pages/recruitment-admin-pages.md)
- [네비게이션](../docs/ui-ux/pages/navigation-and-page-flow.md)
- [워크스페이스 플로우](../docs/ui-ux/pages/workspace-navigation-flow.md)

## 개발 워크플로우
- [개발 프로세스](../docs/workflows/development-flow.md)
- [테스트 전략](../docs/workflows/testing-strategy.md)
- [테스트 데이터](../docs/testing/test-data-reference.md)

## 개발 컨벤션
- [Git 전략](../docs/conventions/git-strategy.md)
- [커밋 규칙](../docs/conventions/commit-conventions.md)
- [PR 가이드](../docs/conventions/pr-guidelines.md)
- [코드 리뷰](../docs/conventions/code-review-standards.md)

## 컨텍스트 추적 시스템
- [업데이트 로그](../docs/context-tracking/context-update-log.md)
- [대기 목록](../docs/context-tracking/pending-updates.md)
- [동기화 상태](../docs/context-tracking/sync-status.md)

## 서브 에이전트
- [커밋 관리](../docs/agents/commit-management-agent.md)
- [컨텍스트 동기화](../docs/agents/context-sync-agent.md)
- [프론트엔드 개발](../docs/agents/frontend-development-agent.md)

## 유지보수 가이드
- [그룹 관리 권한](../docs/maintenance/group-management-permissions.md)

## 문제 해결
- [권한 에러](../docs/troubleshooting/permission-errors.md)
