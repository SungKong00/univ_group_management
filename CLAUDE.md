# 대학 그룹 관리 시스템 (University Group Management)

## 🎯 빠른 네비게이션 (Quick Navigation)

### 핵심 개념 이해하기
- **전체 개념도**: [docs/concepts/domain-overview.md](docs/concepts/domain-overview.md)
- **그룹 계층**: [docs/concepts/group-hierarchy.md](docs/concepts/group-hierarchy.md)
- **권한 시스템**: [docs/concepts/permission-system.md](docs/concepts/permission-system.md)
- **워크스페이스**: [docs/concepts/workspace-channel.md](docs/concepts/workspace-channel.md)

### 개발 가이드
- **백엔드 개발**: [docs/implementation/backend-guide.md](docs/implementation/backend-guide.md)
- **프론트엔드 개발**: [docs/implementation/frontend-guide.md](docs/implementation/frontend-guide.md)
- **API 참조**: [docs/implementation/api-reference.md](docs/implementation/api-reference.md)
- **데이터베이스**: [docs/implementation/database-reference.md](docs/implementation/database-reference.md)

### UI/UX 설계
- **디자인 시스템**: [docs/ui-ux/design-system.md](docs/ui-ux/design-system.md)
- **레이아웃 가이드**: [docs/ui-ux/layout-guide.md](docs/ui-ux/layout-guide.md)
- **컴포넌트 가이드**: [docs/ui-ux/component-guide.md](docs/ui-ux/component-guide.md)

### 개발 워크플로우
- **개발 프로세스**: [docs/workflows/development-flow.md](docs/workflows/development-flow.md)
- **테스트 전략**: [docs/workflows/testing-strategy.md](docs/workflows/testing-strategy.md)

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

### 문제 해결
- **권한 에러**: [docs/troubleshooting/permission-errors.md](docs/troubleshooting/permission-errors.md)
- **일반적 에러**: [docs/troubleshooting/common-errors.md](docs/troubleshooting/common-errors.md)

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

### ✅ 완료된 기능
- **인증/회원가입**: Google OAuth + 프로필 설정 + 자동 로그인
- **그룹 관리**: CRUD + 계층 구조 + 멤버십
- **권한 시스템**: RBAC (시스템/커스텀 역할) + 채널 권한 Permission-Centric 모델 (**하이브리드**: 기본 2채널 템플릿 자동 / 사용자 정의 채널 0바인딩 시작)
- **백엔드 API**: 모든 핵심 엔드포인트
- **그룹 모집 시스템**: API 구현 완료
- **프론트엔드 로그인**: 완성된 Toss 디자인 기반 로그인 페이지
- **디자인 시스템**: 완전한 Toss 4대 원칙 기반 디자인 토큰 시스템
- **성능 최적화**: 앱 시작 성능 개선, 비차단 인증 방식
- **컨벤션**: Git 전략, 커밋 규칙, PR/리뷰 가이드
- **컨텍스트 추적**: 문서 동기화 시스템 구축

### 🚧 진행 중
- **프론트엔드 UI**: 워크스페이스 화면 개발 중
- **컨텐츠 시스템**: 게시글/댓글 프론트엔드
- **채널 권한 설정 UI**: Permission-Centric 매트릭스 UX 반영 작업 예정

### ❌ 미구현
- **모집 시스템 프론트엔드**: 그룹 모집 게시판 UI
- **알림 시스템**: 실시간 알림
- **관리자 대시보드**: 그룹 관리 UI

## 🆕 2025-10-01 권한 모델 개정 요약
- 시스템 역할(OWNER / ADVISOR / MEMBER) 불변성 명시 (이름/우선순위/권한 수정 및 삭제 금지)
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

## 📚 컨텍스트 가이드

### 개발 시작 전 필독
1. [domain-overview.md](docs/concepts/domain-overview.md) - 전체 시스템 이해
2. [group-hierarchy.md](docs/concepts/group-hierarchy.md) - 그룹 구조 이해
3. [permission-system.md](docs/concepts/permission-system.md) - 권한 시스템 이해
4. [git-strategy.md](docs/conventions/git-strategy.md) - Git 전략 및 브랜치 규칙

### 백엔드 개발 시
1. [backend-guide.md](docs/implementation/backend-guide.md) - 아키텍처 패턴
2. [api-reference.md](docs/implementation/api-reference.md) - API 규칙
3. [database-reference.md](docs/implementation/database-reference.md) - 데이터 모델

### 프론트엔드 개발 시
1. [frontend-guide.md](docs/implementation/frontend-guide.md) - 아키텍처 가이드
2. [design-system.md](docs/ui-ux/design-system.md) - UI/UX 가이드
3. [component-guide.md](docs/ui-ux/component-guide.md) - 컴포넌트 패턴

## 📝 문서 관리 규칙

컨텍스트 문서 작성 및 관리 규칙: [markdown-guidelines.md](markdown-guidelines.md)

## 🔗 참조 체계

- **개념 문서** → 구현 가이드로 링크
- **구현 가이드** → 개념 설명으로 역링크
- **에러 문서** → 관련 개념/구현으로 링크
- **UI/UX 문서** → 구현 예시로 링크