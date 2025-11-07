# 워크스페이스 페이지 (Workspace Pages)

워크스페이스 내부 주요 페이지들의 전체 개요와 네비게이션 허브입니다.

## 개요

워크스페이스는 그룹 멤버들이 소통하고 협업하는 핵심 공간입니다. 채널 시스템, 관리 페이지, 네비게이션 플로우로 구성됩니다.

## 구성 요소

### 1. 채널 시스템
**문서**: [workspace-channel-view.md](workspace-channel-view.md)

채널 게시글 및 댓글 시스템:
- 게시글 시스템 (역방향 무한 스크롤)
- 댓글 시스템 (웹 사이드바 / 모바일 전체 화면)
- 원본 게시글 미리보기
- 권한 기반 UI 제어

### 2. 관리 페이지
**문서**: [workspace-admin-pages.md](workspace-admin-pages.md)

그룹 관리 페이지 (권한 필요):
- 그룹 관리
- 멤버 관리 (반응형 테이블/카드)
- 지원자 관리 (탭, 상태 필터)

### 3. 네비게이션 플로우
**문서**: [workspace-navigation-flow.md](workspace-navigation-flow.md)

워크스페이스 특수 플로우:
- 좌측 네비게이션 축소
- 채널 네비게이션 바
- 모바일/반응형 동작

## 주요 기능

### 채널 네비게이션
- 채널 목록, 그룹 홈, 캘린더 메뉴
- 읽지 않음 배지 표시
- 관리자 버튼 (조건부)

### 권한 기반 UI
- **게시글 작성**: `POST_WRITE` 권한
- **댓글 작성**: `COMMENT_WRITE` 권한
- **관리 페이지**: `hasAnyGroupPermission`

### 주요 위젯
- `WorkspaceHeader` - 헤더 (역할 표시)
- `ChannelNavigation` - 채널 목록
- `PostList`, `PostCard` - 게시글
- `CommentList`, `CommentComposer` - 댓글
- `SlidePanel` - 슬라이드 애니메이션

## 관련 문서

### 페이지 상세
- [워크스페이스 채널 뷰](workspace-channel-view.md) - 게시글/댓글
- [워크스페이스 관리 페이지](workspace-admin-pages.md) - 관리 페이지
- [워크스페이스 네비게이션](workspace-navigation-flow.md) - 특수 플로우
- [채널 페이지](channel-pages.md) - 채널 권한

### 네비게이션
- [네비게이션](navigation-and-page-flow.md) - 전체 네비게이션

### 개념 및 구현
- [워크스페이스 개념](../../concepts/workspace-channel.md) - 개념
- [권한 시스템](../../concepts/permission-system.md) - 권한
- [구현 가이드](../../implementation/workspace-page-implementation-guide.md) - 구현
- [디자인 시스템](../concepts/design-system.md) - 디자인
