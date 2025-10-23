# 프론트엔드 개발 가이드 (Frontend Implementation Guide)

## 개요

Flutter 기반 대학 그룹 관리 시스템의 프론트엔드 아키텍처 및 구현 가이드. 각 주제별로 독립적인 가이드 문서를 제공합니다.

## 빠른 네비게이션

- [아키텍처](architecture.md) - 기술 스택, 디렉토리 구조, 레이어 분리
- [인증 시스템](authentication.md) - Google OAuth, 자동 로그인, 토큰 관리
- [상태 관리](state-management.md) - Riverpod, Provider 초기화, 액션 패턴
- [디자인 시스템](design-system.md) - 테마, 디자인 토큰, 재사용성
- [컴포넌트 구현](components.md) - 게시글/댓글, 재사용 위젯
- [반응형 디자인](responsive-design.md) - 브레이크포인트, 적응형 레이아웃
- [성능 최적화](performance.md) - 앱 시작 성능, 최적화 계획

## 관련 문서

- [워크스페이스 가이드](../workspace-page-implementation-guide.md) - 워크스페이스 페이지 구현
- [네비게이션 가이드](../workspace-state-management.md) - WorkspaceView 기반 네비게이션
- [페이지 추가 가이드](../workspace-page-implementation-guide.md) - 새 관리 페이지 추가 체크리스트
- [컴포넌트 재사용성](components.md) - DRY 패턴 및 4단계 재사용 전략
- [디자인 시스템](../../ui-ux/concepts/design-system.md) - Toss 기반 UI/UX 설계
- [API 참조](../api-reference.md) - 백엔드 API 명세

## 기술 스택

- **Framework**: Flutter 3.x (Web)
- **상태 관리**: Riverpod
- **라우팅**: GoRouter
- **인증**: Google OAuth2 + JWT
- **디자인**: Toss 철학 기반 토큰 시스템

## 개발 환경 설정

```bash
# Flutter 웹 서버 실행 (반드시 5173 포트)
flutter run -d chrome --web-hostname localhost --web-port 5173

# 환경 변수 (.env 파일)
GOOGLE_WEB_CLIENT_ID=your_web_client_id
GOOGLE_SERVER_CLIENT_ID=your_server_client_id
API_BASE_URL=http://localhost:8080
```

## 다음 구현 예정

### 진행 중
- 워크스페이스 화면 개발
- 그룹 관리 UI 구현

### 미구현
- 그룹 모집 시스템 프론트엔드
- 실시간 알림 시스템
- 관리자 대시보드
