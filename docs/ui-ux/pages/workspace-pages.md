# 워크스페이스 콘텐츠 페이지 (Workspace Content Pages)

본 문서는 워크스페이스 내부의 주요 콘텐츠 페이지들의 전체 개요와 네비게이션 허브입니다.

## 개요

워크스페이스는 그룹 멤버들이 소통하고 협업하는 핵심 공간입니다. 이 페이지들은 워크스페이스의 좌측/모바일 네비게이션을 통해 전환되는 '콘텐츠 페이지' 영역에 해당합니다.

## 워크스페이스 구성

워크스페이스는 크게 세 가지 영역으로 구성됩니다:

### 1. 채널 시스템
**문서**: [workspace-channel-view.md](workspace-channel-view.md)

채널은 그룹 멤버들이 메시지 형식으로 소통하는 핵심 공간입니다:
- 게시글 시스템 (채팅형 역방향 무한 스크롤)
- 댓글 시스템 (웹 사이드바 / 모바일 전체 화면)
- 원본 게시글 미리보기 기능
- 권한 기반 UI 제어

### 2. 관리 페이지
**문서**: [workspace-admin-pages.md](workspace-admin-pages.md)

그룹 관리 권한을 가진 사용자가 접근할 수 있는 관리 페이지들:
- 그룹 관리 페이지
- 멤버 관리 페이지 (반응형 테이블/카드 레이아웃)
- 지원자 관리 페이지 (탭 구조, 상태 필터)

### 3. 준비 중인 기능
- 그룹 홈 (WorkspaceEmptyState 표시)
- 그룹 캘린더 (WorkspaceEmptyState 표시)

## 구현 현황 (2025-10-17)

### 완료된 기능

#### 워크스페이스 헤더 개선 (2025-10-09)
- 현재 사용자의 그룹 내 역할(예: "그룹장", "멤버") 표시
- `WorkspaceHeader` 위젯에 `currentGroupRole` 파라미터 추가
- 상세한 디자인 가이드: [design-system.md](../concepts/design-system.md) 헤더 섹션

**구현 파일**:
- `/frontend/lib/presentation/widgets/workspace/workspace_header.dart`
- `/frontend/lib/presentation/widgets/navigation/top_navigation.dart`

#### 채널 네비게이션 시스템
- 채널 목록 API 연동 (`/workspaces/{workspaceId}/channels`)
- 멤버십 권한 확인 API 연동 (`/groups/{groupId}/members/me`)
- 슬라이드 애니메이션 (160ms, 왼쪽→오른쪽)
- 읽지 않음 배지 표시 (더미 데이터)
- 그룹 홈 / 캘린더 / 채널 뷰 전환
- 관리자 페이지 버튼 (조건부: hasAnyGroupPermission)

**구현 파일**:
- `/frontend/lib/core/models/channel_models.dart` - Channel, MembershipInfo 모델
- `/frontend/lib/core/models/group_models.dart` - GroupMembership 모델
- `/frontend/lib/core/services/channel_service.dart` - 채널 API 서비스
- `/frontend/lib/core/services/group_service.dart` - 그룹 API 서비스
- `/frontend/lib/presentation/widgets/workspace/channel_navigation.dart`
- `/frontend/lib/presentation/widgets/workspace/channel_item.dart`
- `/frontend/lib/presentation/widgets/workspace/unread_badge.dart`
- `/frontend/lib/presentation/widgets/navigation/sidebar_navigation.dart`
- `/frontend/lib/presentation/providers/workspace_state_provider.dart`
- `/frontend/lib/presentation/pages/workspace/workspace_page.dart`

#### 워크스페이스 자동 진입
- 최상위 그룹 자동 선택 (level 최소 → id 최소)
- 소속 그룹 없을 시 빈 상태 UI 표시
- "그룹 탐색하기" 버튼으로 /home 이동

#### 레이아웃/전환 개선 (2025-10-05)
- 글로벌 라우팅 전환을 `NoTransitionPage`로 통일 (상단/좌측 네비게이션 고정 유지)
- 데스크톱 워크스페이스 콘텐츠 영역을 `Stack`+`Positioned`로 재구성

#### 그룹 드롭다운 최적화 (2025-10-06)
- 스마트 폰트 크기: 채널바 너비 기반 동적 폰트 크기 조정
- 텍스트 너비 계산: TextPainter로 사전 측정
- 반응형 아이콘 크기: 폰트 크기에 따라 자동 조정
- 구현 파일: `/frontend/lib/presentation/widgets/workspace/group_dropdown.dart`

#### 워크스페이스 애니메이션 (2025-10-07 리팩토링)
- 댓글창 슬라이드 애니메이션: 재사용 가능한 `SlidePanel` 위젯 사용
- `SlidePanel`은 애니메이션, 백드롭, 해제 제스처 포함
- 구현 파일:
  - `/frontend/lib/presentation/widgets/common/slide_panel.dart` (재사용 위젯)
  - `/frontend/lib/presentation/pages/workspace/workspace_page.dart` (위젯 사용)

### 향후 개선 사항

#### 읽지 않음 카운트 API
현재 더미 데이터 사용 중. 백엔드 API 구현 필요.

제안 엔드포인트:
- `GET /channels/{channelId}/unread-count` - 개별 채널 읽지 않음 카운트
- 또는 채널 목록 API에 `unreadCount` 필드 포함

#### 워크스페이스 ID 조회
현재 `workspaceId = groupId`로 가정. 실제로는 그룹 정보에서 워크스페이스 ID를 조회해야 함.

제안:
- 그룹 상세 API 응답에 `workspaceId` 필드 추가
- 또는 `GET /groups/{groupId}/workspace` 엔드포인트 활용

## 워크스페이스 구조 상세

### 채널 네비게이션 바 구조

워크스페이스 진입 시, 기존 페이지 콘텐츠 영역에 **채널 네비게이션 바**가 나타나며, 구조는 다음과 같습니다:

-   **그룹 메뉴 (상단)**
    -   그룹 홈
    -   캘린더
-   **채널 (중단)**
    -   사용자가 접근 권한을 가진 채널 목록
    -   읽지 않은 게시글이 있는 채널: 숫자 배지 표시
-   **그룹 관리 (하단)**
    -   그룹 관리 권한 보유 시에만 표시
    -   클릭 시 그룹 관리 페이지 표시

### 권한 기반 UI 제어

-   **게시글 입력창**: `POST_WRITE` 권한 보유 시 활성화
-   **댓글 작성**: `COMMENT_WRITE` 권한 보유 시 활성화
-   **관리자 페이지**: `hasAnyGroupPermission` 보유 시 버튼 표시

## 관련 문서

### 페이지 상세
- [워크스페이스 채널 뷰](workspace-channel-view.md) - 채널 및 게시글 시스템
- [워크스페이스 관리 페이지](workspace-admin-pages.md) - 그룹/멤버/지원자 관리
- [채널 페이지](channel-pages.md) - 채널 권한 및 생성 플로우

### 네비게이션
- [네비게이션 및 페이지 플로우](navigation-and-page-flow.md) - 전체 네비게이션 구조
- [워크스페이스 네비게이션 플로우](workspace-navigation-flow.md) - 워크스페이스 특수 플로우

### 개념 및 구현
- [워크스페이스 개념](../../concepts/workspace-channel.md) - 워크스페이스 개념
- [권한 시스템](../../concepts/permission-system.md) - 권한 개념
- [워크스페이스 구현 가이드](../../implementation/workspace-page-implementation-guide.md) - 구현 가이드
- [디자인 시스템](../concepts/design-system.md) - 디자인 원칙 및 토큰
