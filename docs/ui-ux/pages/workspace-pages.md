# UI/UX 명세서: 워크스페이스 콘텐츠 페이지

본 문서는 워크스페이스 내부의 주요 콘텐츠 페이지(채널, 그룹 홈, 그룹 캘린더)의 구조와 기능을 정의합니다. 이 페이지들은 워크스페이스의 좌측/모바일 네비게이션을 통해 전환되는 '콘텐츠 페이지' 영역에 해당합니다.

## 구현 현황

### 완료된 기능 (2025-10-04)

**워크스페이스 헤더 개선 (2025-10-09)**
- 워크스페이스 헤더에 현재 사용자의 그룹 내 역할(예: "그룹장", "멤버")을 표시하여 컨텍스트를 강화했습니다.
- 이 변경은 `WorkspaceHeader` 위젯에 `currentGroupRole` 파라미터를 추가하여 구현되었습니다.
- 상세한 디자인 가이드는 `docs/ui-ux/concepts/design-system.md`의 헤더 섹션을 참조하세요.
- 구현 파일:
  - `/frontend/lib/presentation/widgets/workspace/workspace_header.dart`
  - `/frontend/lib/presentation/widgets/navigation/top_navigation.dart`

**채널 네비게이션 시스템**
- 채널 목록 API 연동 (`/workspaces/{workspaceId}/channels`)
- 멤버십 권한 확인 API 연동 (`/groups/{groupId}/members/me`)
- 슬라이드 애니메이션 (160ms, 왼쪽→오른쪽, 지연 없음 / 글로벌 사이드바 축소와 동시 재생)
- 읽지 않음 배지 표시 (더미 데이터)
- 그룹 홈 / 캘린더 / 채널 뷰 전환
- 관리자 페이지 버튼 (조건부: hasAnyGroupPermission)

**워크스페이스 자동 진입**
- 최상위 그룹 자동 선택 (level 최소 → id 최소)
- 소속 그룹 없을 시 빈 상태 UI 표시
- "그룹 탐색하기" 버튼으로 /home 이동

**구현 파일**
- `/frontend/lib/core/models/channel_models.dart` - Channel, MembershipInfo 모델
- `/frontend/lib/core/models/group_models.dart` - GroupMembership 모델
- `/frontend/lib/core/services/channel_service.dart` - 채널 API 서비스
- `/frontend/lib/core/services/group_service.dart` - 그룹 API 서비스
- `/frontend/lib/presentation/widgets/workspace/channel_navigation.dart` - 채널 네비게이션
- `/frontend/lib/presentation/widgets/workspace/channel_item.dart` - 채널 아이템
- `/frontend/lib/presentation/widgets/workspace/unread_badge.dart` - 읽지 않음 배지
- `/frontend/lib/presentation/widgets/navigation/sidebar_navigation.dart` - 워크스페이스 자동 진입
- `/frontend/lib/presentation/providers/workspace_state_provider.dart` - 상태 관리
- `/frontend/lib/presentation/pages/workspace/workspace_page.dart` - 워크스페이스 페이지

**레이아웃/전환 개선 (2025-10-05)**
- 글로벌 라우팅 전환을 `NoTransitionPage`로 통일해 상단/좌측 네비게이션 고정 유지
- 데스크톱 워크스페이스 콘텐츠 영역을 `Stack`+`Positioned`로 재구성해 채널/댓글 사이드바 폭 선점

**그룹 드롭다운 최적화 (2025-10-06)**
- 스마트 폰트 크기: 채널바 너비 기반 동적 폰트 크기 조정 (bodyLarge 16px ↔ bodySmall 12px)
- 텍스트 너비 계산: TextPainter로 사전 측정하여 오버플로우 방지
- 반응형 아이콘 크기: 폰트 크기에 따라 20px ↔ 16px 자동 조정
- 구현 파일: `/frontend/lib/presentation/widgets/workspace/group_dropdown.dart`

**워크스페이스 애니메이션 (2025-10-07 리팩토링)**
- 댓글창 슬라이드 애니메이션: 재사용 가능한 `SlidePanel` 위젯을 사용하여 구현.
- `SlidePanel`은 애니메이션, 백드롭, 해제 제스처를 포함한 모든 사이드 패널 로직을 캡슐화.
- 이를 통해 `workspace_page.dart`에서 수동 `AnimationController` 관리가 제거되어 코드가 간소화되고 유지보수성이 향상됨.
- 구현 파일: 
  - `/frontend/lib/presentation/widgets/common/slide_panel.dart` (재사용 위젯)
  - `/frontend/lib/presentation/pages/workspace/workspace_page.dart` (위젯 사용)

### 향후 개선 사항

**읽지 않음 카운트 API**
현재 더미 데이터 사용 중. 백엔드 API 구현 필요.

제안 엔드포인트:
- `GET /channels/{channelId}/unread-count` - 개별 채널 읽지 않음 카운트
- 또는 채널 목록 API에 `unreadCount` 필드 포함

**워크스페이스 ID 조회**
현재 `workspaceId = groupId`로 가정하고 있음. 실제로는 그룹 정보에서 워크스페이스 ID를 조회해야 함.

제안:
- 그룹 상세 API 응답에 `workspaceId` 필드 추가
- 또는 `GET /groups/{groupId}/workspace` 엔드포인트 활용

## 1. 채널 페이지

채널은 그룹 멤버들이 메시지 형식으로 소통하는 핵심 공간입니다.

### 1.1. 기본 구조 및 플로우 (스크롤 방식 변경 - 2025-10-06)

-   **진입**: 사용자가 채널 네비게이션에서 특정 채널을 선택하면, 권한 확인 후 해당 채널의 게시글 목록을 표시합니다.
-   **스크롤**: 채팅 앱과 같이, 가장 최신 게시글이 있는 화면 하단에서 시작합니다. 사용자는 **위로 스크롤**하여 이전 게시글을 계속 불러올 수 있습니다 (Reverse Infinite Scroll).
-   **모바일**: `navigation-and-page-flow.md`에 정의된 전체 화면 전환 플로우를 따릅니다.

### 1.2. 게시글 구성 요소 (구현 완료 - 2025-10-05)

게시글은 제목과 내용을 구분하지 않는 연속적인 메시지 형태입니다.

**구현된 컴포넌트**:
- `PostCard`: 단일 게시글 카드 (작성자 정보, 본문, 댓글 버튼)
- `PostList`: 게시글 목록 (채팅형 역방향 무한 스크롤, 날짜 구분선)
- `PostComposer`: 게시글 작성 입력창 (권한 기반)
- `DateDivider`: 날짜 구분선 (한국어 로케일)
- `PostSkeleton`: 로딩 스켈레톤

**디자인 구조**:
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

**권한 기반 UI 제어**:
- `POST_WRITE` 권한이 있을 때만 게시글 작성 입력창 표시
- `COMMENT_WRITE` 권한이 있을 때만 댓글 작성 버튼 활성화
- 권한이 없는 경우 "이 채널에 글을 작성할 권한이 없습니다" 메시지 표시

**키보드 입력**:
- Enter: 게시글/댓글 전송
- Shift + Enter: 줄바꿈

**구현 위치**:
- `frontend/lib/presentation/widgets/post/post_card.dart`
- `frontend/lib/presentation/widgets/post/post_list.dart`
- `frontend/lib/presentation/widgets/post/post_composer.dart`
- `frontend/lib/presentation/widgets/post/date_divider.dart`
- `frontend/lib/presentation/widgets/post/post_skeleton.dart`

### 1.3. 댓글 시스템 (UX 개선 - 2025-10-06)

게시글에 대한 댓글을 확인하고 작성하는 시스템입니다. 웹과 모바일 환경 모두에서 사용자 편의성을 위해 **원본 게시글 미리보기** 기능을 제공합니다.

**핵심 UX 개선**:
-   사용자가 댓글을 확인할 때, 화면 상단에 원본 게시글의 내용(작성자, 본문 등)이 함께 표시됩니다. 이를 통해 사용자는 어떤 게시글에 대한 댓글을 보고 있는지 명확하게 인지할 수 있습니다.

**구현된 컴포넌트**:
-   `CommentList`: 댓글 목록 (웹/모바일 공통)
-   `CommentComposer`: 댓글 작성 입력창 (웹/모바일 공통)
-   `PostPreviewCard`: 모바일 댓글 뷰 상단에 표시되는 게시글 미리보기 카드
-   `CollapsibleContent`: 긴 게시글 본문을 '더보기/접기' 할 수 있는 공통 위젯

**플랫폼별 디자인 구조**:

1.  **웹 (데스크톱) 댓글 사이드바**:
    -   화면 우측에서 슬라이드되어 나타나는 사이드바 형태입니다.
    -   **상단**: 원본 게시글 미리보기가 표시됩니다.
        -   **헤더**: 작성자 프로필, 이름, 작성 시간을 보여줍니다.
        -   **본문**: `CollapsibleContent` 위젯을 사용하여 긴 내용은 자동으로 접히고, '더보기'를 통해 펼쳐볼 수 있습니다.
    -   **중단**: 댓글 목록(`CommentList`)이 시간순으로 표시됩니다.
    -   **하단**: 댓글 작성창(`CommentComposer`)이 위치합니다.

2.  **모바일 댓글 뷰**:
    -   게시글의 댓글 버튼 클릭 시, 전체 화면 페이지로 전환됩니다.
    -   **상단**: `PostPreviewCard` 위젯을 사용하여 원본 게시글을 카드로 명확하게 표시합니다.
    -   **중단**: 그 아래로 댓글 목록(`CommentList`)이 이어집니다.
    -   **하단**: 댓글 작성창(`CommentComposer`)이 위치합니다.

**권한 제어**:
-   `COMMENT_WRITE` 권한이 있을 때만 댓글 작성창이 활성화됩니다.

**구현 위치**:
-   `frontend/lib/presentation/pages/workspace/workspace_page.dart` (웹 사이드바)
-   `frontend/lib/presentation/widgets/workspace/mobile_post_comments_view.dart` (모바일 뷰)
-   `frontend/lib/presentation/widgets/post/post_preview_card.dart`
-   `frontend/lib/presentation/widgets/common/collapsible_content.dart`
-   `frontend/lib/presentation/widgets/comment/` (댓글 관련 위젯)

## 2. 그룹 홈, 캘린더, 그룹 관리 페이지

> **구현 상태**: 그룹 관리 페이지 구현 완료, 나머지는 준비 중 UI로 표시 (2025-10-10)

워크스페이스의 핵심 기능인 그룹 관리 페이지가 구현되었으며, 그룹 홈 및 캘린더는 현재 개발 준비 중입니다.

### 2.1. 구현된 페이지: 그룹 관리

-   **상태**: 구현 완료
-   **컴포넌트**: `GroupAdminPage`
-   **위치**: `frontend/lib/presentation/pages/group/group_admin_page.dart`
-   **동작**: 사용자가 채널 네비게이션의 '관리자' 버튼을 클릭하면, `workspace_page.dart`는 `GroupAdminPage` 위젯을 렌더링합니다. `workspace_state_provider`는 `previousView`를 기록하여 '뒤로가기' 시 이전 채널 뷰로 복귀할 수 있도록 지원합니다.

### 2.2. 준비 중인 페이지: 그룹 홈, 캘린더

그룹 홈과 그룹 캘린더 기능은 `WorkspaceEmptyState` 위젯을 사용하여 "준비 중" 상태를 표시합니다.

-   **컴포넌트**: `WorkspaceEmptyState`
-   **위치**: `frontend/lib/presentation/pages/workspace/widgets/workspace_empty_state.dart`
-   **동작**: 이 위젯은 `WorkspaceEmptyType` 값을 받아, 기능에 맞는 아이콘과 텍스트를 표시합니다.

| 기능 | `WorkspaceEmptyType` | 표시 아이콘 | 표시 제목 |
| :--- | :--- | :--- | :--- |
| 그룹 홈 | `groupHome` | `Icons.home_outlined` | 그룹 홈 |
| 그룹 캘린더 | `calendar` | `Icons.calendar_today_outlined` | 캘린더 |

### 2.3. 채널 미선택 시 화면

사용자가 워크스페이스에 진입했지만 아직 채널을 선택하지 않았을 때 표시되는 화면 역시 `WorkspaceEmptyState` 위젯을 사용합니다.

-   **`WorkspaceEmptyType`**: `noChannelSelected`
-   **표시 아이콘**: `Icons.tag`
-   **표시 제목**: "채널을 선택하세요"

### 2.4. 향후 계획

그룹 홈 및 캘린더의 실제 기능은 각 개별 명세에 따라 순차적으로 구현될 예정입니다. 현재의 `WorkspaceEmptyState`는 해당 기능들이 구현되기 전까지의 Placeholder 역할을 수행합니다.
