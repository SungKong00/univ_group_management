# 워크스페이스 페이지 추가 구현 가이드

## 개요

워크스페이스 시스템에 새로운 관리 페이지를 추가할 때 따라야 할 완전한 체크리스트입니다.

WorkspaceView enum 기반 상태 관리 시스템에서 페이지를 추가하는 전체 플로우를 다룹니다.

**예상 소요 시간**: 1-2시간 (페이지 로직 복잡도에 따라 다름)

## 문서 구성
- **Part 1** (현재): 개요 및 체크리스트 1-4단계
- [workspace-page-checklist.md](workspace-page-checklist.md): 체크리스트 5-10단계, 실수 TOP 10
- [workspace-state-management.md](workspace-state-management.md): 상태 관리 설계, previousView 활용
- [workspace-troubleshooting.md](workspace-troubleshooting.md): 트러블슈팅, 참조

## 관련 문서
- [워크스페이스 시스템](../concepts/workspace-channel.md) - 개념 이해
- [프론트엔드 아키텍처](frontend/architecture.md) - 전반적인 아키텍처

## 핵심 아키텍처 이해

### WorkspaceView Enum 기반 상태 관리
```dart
enum WorkspaceView {
  channel,
  groupHome,
  calendar,
  groupAdmin,
  memberManagement,
  channelManagement,
  recruitmentManagement,
  applicationManagement,  // 예시
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

## 필수 체크리스트 (1-4단계)

### 1단계: WorkspaceView Enum 추가
**파일**: frontend/lib/presentation/providers/workspace_state_provider.dart
**위치**: 라인 15-24 (enum 정의부)

```dart
enum WorkspaceView {
  channel,
  groupHome,
  // ... 기존 값들
  yourNewPage,  // ⬅️ 끝에 추가 (순서 변경 금지!)
}
```

**주의**: enum 값 사이에 삽입하면 직렬화 문제 발생

### 2단계: 네비게이션 메서드 추가
**파일**: frontend/lib/presentation/providers/workspace_state_provider.dart
**위치**: 라인 600-634 근처 (showXXXPage 메서드들)

```dart
/// Show your new page view
void showYourNewPage() {
  state = state.copyWith(
    previousView: state.currentView,        // 뒤로가기 지원
    currentView: WorkspaceView.yourNewPage,
    selectedChannelId: null,                // 상태 초기화
    isCommentsVisible: false,
    selectedPostId: null,
    isNarrowDesktopCommentsFullscreen: false,
  );
}
```

**실수 방지**:
- previousView: state.currentView 필수
- 모든 상태 초기화 필수

### 3단계: workspace_page.dart - 모바일 switch 추가
**파일**: frontend/lib/presentation/pages/workspace/workspace_page.dart
**위치**: 라인 448-472 (_buildMobileWorkspace 메서드의 switch 문)

```dart
if (currentView != WorkspaceView.channel) {
  switch (currentView) {
    case WorkspaceView.yourNewPage:
      return const YourNewPage();
    // ... 기존 케이스들
    case WorkspaceView.channel:
      break;
  }
}
```

### 4단계: workspace_page.dart - 데스크톱 switch 추가
**파일**: frontend/lib/presentation/pages/workspace/workspace_page.dart
**위치**: 라인 570-604 (_buildMainContent 메서드의 switch 문)

```dart
switch (currentView) {
  case WorkspaceView.yourNewPage:
    return const YourNewPage();
  // ... 기존 케이스들
}
```

**실수 방지**: 2곳 모두 추가해야 모바일/데스크톱 양쪽에서 작동

## 다음 단계

5-10단계는 [workspace-page-checklist.md](workspace-page-checklist.md)를 참조하세요.
