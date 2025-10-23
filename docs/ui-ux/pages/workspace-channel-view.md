# 워크스페이스: 채널 페이지 (Workspace Channel View)

본 문서는 워크스페이스 내 채널의 게시글 및 댓글 시스템의 UI/UX를 정의합니다.

## 개요

채널은 그룹 멤버들이 메시지 형식으로 소통하는 핵심 공간입니다. 이 문서는 채널 페이지의 구조, 게시글 구성, 댓글 시스템에 대한 상세 명세를 제공합니다.

## 1. 채널 페이지 기본 구조

### 1.1. 진입 및 스크롤 (2025-10-06 변경)

-   **진입**: 사용자가 채널 네비게이션에서 특정 채널을 선택하면, 권한 확인 후 해당 채널의 게시글 목록을 표시합니다.
-   **스크롤**: 채팅 앱과 같이, 가장 최신 게시글이 있는 화면 하단에서 시작합니다. 사용자는 **위로 스크롤**하여 이전 게시글을 계속 불러올 수 있습니다 (Reverse Infinite Scroll).
-   **모바일**: 전체 화면 전환 플로우를 따릅니다. ([navigation-and-page-flow.md](navigation-and-page-flow.md) 참조)

## 2. 게시글 구성 요소 (구현 완료 - 2025-10-05)

게시글은 제목과 내용을 구분하지 않는 연속적인 메시지 형태입니다.

### 2.1. 구현된 컴포넌트

- `PostCard`: 단일 게시글 카드 (작성자 정보, 본문, 댓글 버튼)
- `PostList`: 게시글 목록 (채팅형 역방향 무한 스크롤, 날짜 구분선)
- `PostComposer`: 게시글 작성 입력창 (권한 기반)
- `DateDivider`: 날짜 구분선 (한국어 로케일)
- `PostSkeleton`: 로딩 스켈레톤

### 2.2. 디자인 구조

1.  **작성자 정보**: 좌측에 작성자의 프로필 이미지, 우측 상단에 닉네임과 작성 시간(예: "오후 3:15")을 표시합니다.
2.  **날짜 구분선**: 날짜가 바뀔 경우, 게시글 사이에 "── 2025년 9월 29일 ──"과 같은 구분선을 삽입하여 시각적으로 분리합니다.
3.  **메시지 본문**: 텍스트 기반의 메시지를 표시합니다.
4.  **댓글 버튼**: 게시글 하단에 반응형 너비의 직사각형 버튼을 배치합니다.
    -   **반응형 너비**: 모바일(≤600px)에서는 게시글 폭의 70%, 웹(>600px)에서는 최대 800px
    -   **레이아웃**: 왼쪽에 아이콘과 텍스트, 오른쪽 끝에 ">" 아이콘 (spaceBetween 정렬)
    -   **외부 여백**: 버튼 우측에 64px 여백으로 댓글창과 간격 확보
    -   **댓글이 없을 때**: "댓글 작성하기" 텍스트를 표시합니다.
    -   **댓글이 있을 때**: "N개의 댓글 • M분 전" 형식으로 댓글 수와 마지막 댓글이 달린 시간을 함께 표시합니다.
    -   **마우스 호버 시**: "댓글 펼치기"로 텍스트가 변경되며, 브랜드 컬러 테두리가 나타납니다.

### 2.3. 권한 기반 UI 제어

- `POST_WRITE` 권한이 있을 때만 게시글 작성 입력창 표시
- `COMMENT_WRITE` 권한이 있을 때만 댓글 작성 버튼 활성화
- 권한이 없는 경우 "이 채널에 글을 작성할 권한이 없습니다" 메시지 표시

### 2.4. 키보드 입력

- Enter: 게시글/댓글 전송
- Shift + Enter: 줄바꿈

### 2.5. 구현 위치

- `frontend/lib/presentation/widgets/post/post_card.dart`
- `frontend/lib/presentation/widgets/post/post_list.dart`
- `frontend/lib/presentation/widgets/post/post_composer.dart`
- `frontend/lib/presentation/widgets/post/date_divider.dart`
- `frontend/lib/presentation/widgets/post/post_skeleton.dart`

## 3. 댓글 시스템 (UX 개선 - 2025-10-06)

게시글에 대한 댓글을 확인하고 작성하는 시스템입니다. 웹과 모바일 환경 모두에서 사용자 편의성을 위해 **원본 게시글 미리보기** 기능을 제공합니다.

### 3.1. 핵심 UX 개선

-   사용자가 댓글을 확인할 때, 화면 상단에 원본 게시글의 내용(작성자, 본문 등)이 함께 표시됩니다. 이를 통해 사용자는 어떤 게시글에 대한 댓글을 보고 있는지 명확하게 인지할 수 있습니다.

### 3.2. 구현된 컴포넌트

-   `CommentList`: 댓글 목록 (웹/모바일 공통)
-   `CommentComposer`: 댓글 작성 입력창 (웹/모바일 공통)
-   `PostPreviewCard`: 모바일 댓글 뷰 상단에 표시되는 게시글 미리보기 카드
-   `CollapsibleContent`: 긴 게시글 본문을 '더보기/접기' 할 수 있는 공통 위젯

### 3.3. 플랫폼별 디자인 구조

#### 웹 (데스크톱) 댓글 사이드바

화면 우측에서 슬라이드되어 나타나는 사이드바 형태입니다.

-   **상단**: 원본 게시글 미리보기가 표시됩니다.
    -   **헤더**: 작성자 프로필, 이름, 작성 시간을 보여줍니다.
    -   **본문**: `CollapsibleContent` 위젯을 사용하여 긴 내용은 자동으로 접히고, '더보기'를 통해 펼쳐볼 수 있습니다.
-   **중단**: 댓글 목록(`CommentList`)이 시간순으로 표시됩니다.
-   **하단**: 댓글 작성창(`CommentComposer`)이 위치합니다.

#### 모바일 댓글 뷰

게시글의 댓글 버튼 클릭 시, 전체 화면 페이지로 전환됩니다.

-   **상단**: `PostPreviewCard` 위젯을 사용하여 원본 게시글을 카드로 명확하게 표시합니다.
-   **중단**: 그 아래로 댓글 목록(`CommentList`)이 이어집니다.
-   **하단**: 댓글 작성창(`CommentComposer`)이 위치합니다.

### 3.4. 권한 제어

-   `COMMENT_WRITE` 권한이 있을 때만 댓글 작성창이 활성화됩니다.

### 3.5. 구현 위치

-   `frontend/lib/presentation/pages/workspace/workspace_page.dart` (웹 사이드바)
-   `frontend/lib/presentation/widgets/workspace/mobile_post_comments_view.dart` (모바일 뷰)
-   `frontend/lib/presentation/widgets/post/post_preview_card.dart`
-   `frontend/lib/presentation/widgets/common/collapsible_content.dart`
-   `frontend/lib/presentation/widgets/comment/` (댓글 관련 위젯)

## 관련 문서

- [워크스페이스 페이지](workspace-pages.md) - 워크스페이스 전체 구조
- [워크스페이스 관리 페이지](workspace-admin-pages.md) - 그룹 관리 페이지
- [채널 페이지](channel-pages.md) - 채널 권한 및 생성 플로우
- [네비게이션 및 페이지 플로우](navigation-and-page-flow.md) - 전체 네비게이션 구조
- [디자인 시스템](../concepts/design-system.md) - 디자인 원칙 및 토큰
