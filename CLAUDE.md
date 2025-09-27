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
역할기반 권한 + 개인 권한 오버라이드
```

## 🚀 현재 구현 상태

### ✅ 완료된 기능
- **인증/회원가입**: Google OAuth + 프로필 설정
- **그룹 관리**: CRUD + 계층 구조 + 멤버십
- **권한 시스템**: RBAC + 개인 오버라이드
- **백엔드 API**: 모든 핵심 엔드포인트

### 🚧 진행 중
- **프론트엔드 UI**: 워크스페이스 화면 개발 중
- **컨텐츠 시스템**: 게시글/댓글 프론트엔드

### ❌ 미구현
- **모집 시스템**: 그룹 모집 게시판
- **알림 시스템**: 실시간 알림
- **관리자 대시보드**: 그룹 관리 UI

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