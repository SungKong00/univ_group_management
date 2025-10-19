# 워크스페이스 페이지 추가 구현 가이드

## 개요

워크스페이스 시스템에 새로운 관리 페이지를 추가할 때 따라야 할 **완전한 체크리스트**입니다.
가입 승인 페이지(ApplicationManagementPage) 구현 패턴을 기반으로 작성되었습니다.

이 가이드는 WorkspaceView enum 기반 상태 관리 시스템에서 페이지를 추가하는 전체 플로우를 다룹니다.

**예상 소요 시간**: 1-2시간 (페이지 로직 복잡도에 따라 다름)

## 문서 구성
이 가이드는 4개 파트로 구성되어 있습니다:
- **Part 1** (현재): 개요 및 체크리스트 1-4단계
- [Part 2](workspace-page-implementation-guide-part2.md): 체크리스트 5-10단계, 구현 패턴
- [Part 3](workspace-page-implementation-guide-part3.md): 실수하기 쉬운 부분 TOP 10, 상태 관리 설계
- [Part 4](workspace-page-implementation-guide-part4.md): 설계 고려사항, 트러블슈팅, 참조

## 관련 문서
- [워크스페이스 레벨 네비게이션 가이드](workspace-level-navigation-guide.md) - 새 가이드
- [워크스페이스 시스템](../concepts/workspace-channel.md) - 개념 이해
- [프론트엔드 가이드](frontend-guide.md) - 전반적인 아키텍처

## 핵심 아키텍처 이해

### WorkspaceView Enum 기반 상태 관리
```dart
// workspace_state_provider.dart (라인 15-24)
enum WorkspaceView {
  channel,                  // 일반 채널 뷰
  groupHome,               // 그룹 홈
  calendar,                // 캘린더
  groupAdmin,              // 그룹 관리
  memberManagement,        // 멤버 관리
  channelManagement,       // 채널 관리
  recruitmentManagement,   // 모집 관리
  applicationManagement,   // 지원자 관리 ⬅️ 예시
}
```

### 페이지 표시 플로우
```
WorkspaceStateNotifier.showXXXPage()
  ↓ (상태 업데이트)
WorkspaceState.currentView = WorkspaceView.xxx
  ↓ (Provider 감지)
workspace_page.dart의 switch 문
  ↓ (라우팅)
해당 페이지 위젯 렌더링
```

## 필수 체크리스트 (10단계)

### 1단계: WorkspaceView Enum 추가
**파일**: `frontend/lib/presentation/providers/workspace_state_provider.dart`
**위치**: 라인 15-24 (enum 정의부)

```dart
enum WorkspaceView {
  channel,
  groupHome,
  calendar,
  groupAdmin,
  memberManagement,
  channelManagement,
  recruitmentManagement,
  applicationManagement,
  yourNewPage,  // ⬅️ 새 페이지 추가
}
```

**주의**: enum 순서를 변경하지 마세요. 기존 값 사이에 삽입하면 직렬화 문제가 발생할 수 있습니다.

### 2단계: 네비게이션 메서드 추가
**파일**: `frontend/lib/presentation/providers/workspace_state_provider.dart`
**위치**: 라인 600-634 근처 (showXXXPage 메서드들)

```dart
/// Show your new page view
void showYourNewPage() {
  state = state.copyWith(
    previousView: state.currentView,        // 뒤로가기 지원
    currentView: WorkspaceView.yourNewPage,
    selectedChannelId: null,                // 상태 초기화
    isCommentsVisible: false,               // 댓글창 닫기
    selectedPostId: null,                   // 선택된 게시글 초기화
    isNarrowDesktopCommentsFullscreen: false,
  );
}
```

**실수 방지**:
- `previousView: state.currentView` 필수 (뒤로가기 지원)
- 모든 상태 초기화 필수 (채널/게시글/댓글)

### 3단계: workspace_page.dart - 모바일 switch 추가
**파일**: `frontend/lib/presentation/pages/workspace/workspace_page.dart`
**위치**: 라인 448-472 (`_buildMobileWorkspace` 메서드의 switch 문)

```dart
// 4. 특수 뷰 우선 처리
if (currentView != WorkspaceView.channel) {
  switch (currentView) {
    case WorkspaceView.groupHome:
      return const GroupHomeView();
    case WorkspaceView.calendar:
      if (selectedGroupId == null) {
        return const WorkspaceStateView(type: WorkspaceStateType.noGroup);
      }
      return GroupCalendarPage(groupId: int.parse(selectedGroupId));
    case WorkspaceView.yourNewPage:  // ⬅️ 추가
      return const YourNewPage();
    // ... 기존 케이스들
    case WorkspaceView.channel:
      break;
  }
}
```

**주의**: `WorkspaceView.channel`을 마지막에 두고 `break`로 처리해야 합니다.

### 4단계: workspace_page.dart - 데스크톱 switch 추가
**파일**: `frontend/lib/presentation/pages/workspace/workspace_page.dart`
**위치**: 라인 570-604 (`_buildMainContent` 메서드의 switch 문)

```dart
// Switch view based on currentView
switch (currentView) {
  case WorkspaceView.groupHome:
    return const GroupHomeView();
  case WorkspaceView.yourNewPage:  // ⬅️ 추가
    return const YourNewPage();
  // ... 기존 케이스들
  case WorkspaceView.channel:
    // 채널 콘텐츠 렌더링
}
```

**실수 방지**: 2곳 모두 추가해야 모바일/데스크톱 양쪽에서 작동합니다.
