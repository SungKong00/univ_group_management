# 워크스페이스: 채널 페이지 (Workspace Channel View)

본 문서는 워크스페이스 내 채널의 게시글 및 댓글 시스템의 UI/UX를 정의합니다.

## 개요

채널은 그룹 멤버들이 메시지 형식으로 소통하는 핵심 공간입니다. 이 문서는 채널 페이지의 구조, 게시글 구성, 댓글 시스템에 대한 상세 명세를 제공합니다.

## 1. 채널 페이지 기본 구조

### 1.1. 진입 및 스크롤 (2025-10-06 변경)

-   **진입**: 사용자가 채널 네비게이션에서 특정 채널을 선택하면, 권한 확인 후 해당 채널의 게시글 목록을 표시합니다.
-   **스크롤**: 채팅 앱과 같이, 가장 최신 게시글이 있는 화면 하단에서 시작합니다. 사용자는 **위로 스크롤**하여 이전 게시글을 계속 불러올 수 있습니다 (Reverse Infinite Scroll).
-   **모바일**: 전체 화면 전환 플로우를 따릅니다. ([navigation-and-page-flow.md](navigation-and-page-flow.md) 참조)

## 2. 게시글 구성

게시글은 제목과 내용을 구분하지 않는 연속적인 메시지 형태입니다.

### 2.1. 컴포넌트

PostCard (단일 게시글), PostList (역방향 무한 스크롤), PostComposer (작성 입력창), DateDivider (날짜 구분선), PostSkeleton (로딩)

### 2.2. 디자인

**구조**: 프로필 이미지, 닉네임, 작성 시간, 메시지 본문, 댓글 버튼
**시간 표시**:
- 수정 안 된 게시글: "HH:mm" (예: "10:30")
- 수정된 게시글: "작성 시간 • MM/dd HH:mm 수정됨" (예: "10:30 • 11/01 11:30 수정됨")

**수정/삭제 버튼**:
- 본인 게시글만 수정/삭제 버튼 표시
- 옵션 메뉴 순서: 수정, 신고하기, 삭제
- 옵션 메뉴 위치: 시간 표시 바로 오른쪽

**날짜 구분선**: "── 2025년 9월 29일 ──" 형식
**댓글 버튼**: 반응형 너비 (모바일 ≤600px: 게시글 폭 70%, 웹 >600px: 최대 800px), 좌측 아이콘+텍스트, 우측 ">", 우측 64px 여백. 댓글 없을 때 "댓글 작성하기", 있을 때 "N개의 댓글 • M분 전". 호버 시 "댓글 펼치기"로 변경, 브랜드 컬러 테두리

### 2.3. 권한 및 입력

**권한**: POST_WRITE (작성 입력창 표시), COMMENT_WRITE (댓글 버튼 활성화)
**키보드**: Enter (전송), Shift+Enter (줄바꿈)
**구현**: frontend/lib/presentation/widgets/post/

## 3. 댓글 시스템

웹/모바일 모두에서 원본 게시글 미리보기 기능을 제공하여 사용자가 댓글 컨텍스트를 명확히 인지할 수 있습니다.

### 3.1. 컴포넌트

CommentList (댓글 목록), CommentComposer (작성 입력창), PostPreviewCard (게시글 미리보기), CollapsibleContent (더보기/접기 위젯)

### 3.2. 플랫폼별 구조

**웹 (데스크톱)**: 우측 슬라이드 사이드바. 상단: 원본 게시글 미리보기 (작성자 프로필, 이름, 시간, CollapsibleContent 본문), 중단: CommentList, 하단: CommentComposer
**모바일**: 전체 화면 전환. 상단: PostPreviewCard, 중단: CommentList, 하단: CommentComposer

### 3.3. 권한

COMMENT_WRITE 권한 보유 시에만 댓글 작성창 활성화

**구현**: frontend/lib/presentation/pages/workspace/, frontend/lib/presentation/widgets/workspace/, frontend/lib/presentation/widgets/comment/

## 관련 문서

- [워크스페이스 페이지](workspace-pages.md) - 워크스페이스 전체 구조
- [워크스페이스 관리 페이지](workspace-admin-pages.md) - 그룹 관리 페이지
- [채널 페이지](channel-pages.md) - 채널 권한 및 생성 플로우
- [네비게이션 및 페이지 플로우](navigation-and-page-flow.md) - 전체 네비게이션 구조
- [디자인 시스템](../concepts/design-system.md) - 디자인 원칙 및 토큰
