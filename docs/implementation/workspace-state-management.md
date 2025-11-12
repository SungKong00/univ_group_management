# 워크스페이스 상태 관리

> [워크스페이스 페이지 구현 가이드](workspace-page-implementation-guide.md) 시리즈

## WorkspaceView Enum 기반 아키텍처

### 상태 구조
```dart
class WorkspaceState {
  final String? selectedGroupId;        // 현재 그룹
  final String? selectedChannelId;      // 현재 채널
  final bool isCommentsVisible;         // 댓글 사이드바
  final String? selectedPostId;         // 선택된 게시글
  final WorkspaceView currentView;      // 현재 뷰
  final WorkspaceView? previousView;    // 이전 뷰 (뒤로가기)
  final List<NavigationHistoryEntry> navigationHistory;  // 통합 네비게이션 히스토리
}
```

### NavigationHistoryEntry
모든 네비게이션 이동(채널, 뷰, 그룹 전환)을 기록하는 통합 히스토리:
```dart
class NavigationHistoryEntry {
  final String groupId;              // 그룹 ID
  final WorkspaceView view;          // 뷰 타입
  final MobileWorkspaceView mobileView;  // 모바일 뷰
  final String? channelId;           // 채널 ID (옵션)
  final String? postId;              // 게시글 ID (옵션)
  final bool isCommentsVisible;      // 댓글 표시 여부
  final DateTime timestamp;          // 기록 시간
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

## 상태 격리 원칙

각 뷰는 독립적인 상태를 가져야 합니다.

**올바른 설계**:
```dart
showYourNewPage() {
  state = state.copyWith(
    selectedChannelId: null,        // 상태 격리
    isCommentsVisible: false,
    selectedPostId: null,
  );
}
```

## 네비게이션 메서드 패턴

### 표준 템플릿
```dart
void showXXXPage() {
  state = state.copyWith(
    // 1. 뒤로가기 지원
    previousView: state.currentView,

    // 2. 뷰 전환
    currentView: WorkspaceView.xxx,

    // 3. 상태 초기화
    selectedChannelId: null,
    isCommentsVisible: false,
    selectedPostId: null,
    isNarrowDesktopCommentsFullscreen: false,
  );
}
```

### 채널 뷰로 복귀
```dart
void showChannel(String channelId) {
  selectChannel(channelId);  // 기존 메서드 재사용
}
```

## 통합 네비게이션 히스토리 (뒤로가기)

### 히스토리 추가
모든 네비게이션 이동 시 자동 기록:
```dart
void _addToNavigationHistory({
  required String groupId,
  required WorkspaceView view,
  required MobileWorkspaceView mobileView,
  String? channelId,
  String? postId,
  bool isCommentsVisible = false,
}) {
  // 중복 방지: 마지막 히스토리와 동일하면 스킵
  if (state.navigationHistory.isNotEmpty) {
    final last = state.navigationHistory.last;
    if (last.groupId == groupId &&
        last.view == view &&
        last.mobileView == mobileView &&
        last.channelId == channelId &&
        last.postId == postId &&
        last.isCommentsVisible == isCommentsVisible) {
      return;
    }
  }

  final newHistory = List<NavigationHistoryEntry>.from(state.navigationHistory);
  newHistory.add(NavigationHistoryEntry(
    groupId: groupId,
    view: view,
    mobileView: mobileView,
    channelId: channelId,
    postId: postId,
    isCommentsVisible: isCommentsVisible,
    timestamp: DateTime.now(),
  ));
  state = state.copyWith(navigationHistory: newHistory);
}
```

### 뒤로가기 처리
히스토리 스택에서 이전 상태로 완전 복원:
```dart
Future<bool> navigateBackInHistory() async {
  if (state.navigationHistory.isEmpty) {
    return false;  // 히스토리 없음
  }

  final newHistory = List<NavigationHistoryEntry>.from(state.navigationHistory);
  final previousEntry = newHistory.removeLast();

  // 히스토리 업데이트 (재추가 방지)
  state = state.copyWith(navigationHistory: newHistory);

  // 이전 상태로 완전 복원 (그룹 ID, 뷰, 채널, 게시글, 댓글)
  final isSameGroup = state.selectedGroupId == previousEntry.groupId;

  if (!isSameGroup) {
    // 다른 그룹: enterWorkspace 호출
    await enterWorkspace(
      previousEntry.groupId,
      channelId: previousEntry.channelId,
      targetView: previousEntry.view,
    );
  }

  state = state.copyWith(
    selectedGroupId: previousEntry.groupId,
    selectedChannelId: previousEntry.channelId,
    currentView: previousEntry.view,
    mobileView: previousEntry.mobileView,
    selectedPostId: previousEntry.postId,
    isCommentsVisible: previousEntry.isCommentsVisible,
  );

  // 채널 권한 로드
  if (previousEntry.channelId != null) {
    await loadChannelPermissions(previousEntry.channelId!);
  }

  return true;
}
```

### workspace_page.dart에서 사용
```dart
/// 뒤로가기 가능 여부 확인 (Web/Tablet 공통)
bool _canHandleBack() {
  final navigationHistory = ref.read(workspaceNavigationHistoryProvider);
  return navigationHistory.isNotEmpty;
}

/// 뒤로가기 처리 (Web/Tablet 공통)
Future<void> _handleBack() async {
  await ref.read(workspaceStateProvider.notifier).navigateBackInHistory();
}
```

## 에러 바운더리

### 필수 체크 항목
```dart
// 1. 그룹 미선택
if (groupIdStr == null) {
  return const WorkspaceStateView(type: WorkspaceStateType.noGroup);
}

// 2. 잘못된 ID
final groupId = int.tryParse(groupIdStr);
if (groupId == null) {
  return WorkspaceStateView(
    type: WorkspaceStateType.error,
    errorMessage: '그룹 정보를 불러오지 못했습니다.',
  );
}
```

## 읽음 위치 저장 메커니즘

### 저장 트리거
읽음 위치는 다음 이벤트에서 자동 저장됩니다:

1. **채널 전환 (`selectChannel`)**: 현재 채널에서 다른 채널로 이동
2. **워크스페이스 이탈 (`exitWorkspace`)**: 글로벌 네비게이션 또는 로그아웃
3. **앱 종료 (웹 전용)**: beforeunload 이벤트 (페이지 닫기/새로고침)

### 라우트 기반 자동 감지 (router_listener.dart)
`RouterListener`가 라우트 변경을 감지하여 워크스페이스 이탈 시 자동 저장:

```dart
void _handleWorkspaceStateTransition(String route, NavigationController navigationController) {
  final isWorkspaceRoute = route.startsWith('/workspace');
  final previousRoute = _previousRoute;

  // 워크스페이스 벗어날 시 자동 확장 및 읽음 위치 저장
  if (previousRoute != null && previousRoute.startsWith('/workspace') && !isWorkspaceRoute) {
    ref.read(workspaceStateProvider.notifier).exitWorkspace();
    navigationController.exitWorkspace();
  }
}
```

### 조건부 Import (테스트 환경 지원)
웹/테스트 환경 분리를 위한 조건부 import 적용:

```dart
// workspace_state_provider.dart
import 'workspace_state_provider_stub.dart'
    if (dart.library.html) 'workspace_state_provider_web.dart' as web_utils;

// 웹: localStorage 동기 접근 (beforeunload 타이밍 보장)
// 테스트: No-op 구현
```

**파일 구조**:
- `workspace_state_provider_web.dart`: 웹 전용 JS interop (dart:html, dart:js)
- `workspace_state_provider_stub.dart`: 테스트 환경용 stub (no-op)

### Best-Effort 전략
읽음 위치 저장은 Best-Effort 방식으로 에러를 무시:

```dart
try {
  await saveReadPosition(channelId, postId);
  await loadUnreadCount(channelId);
} catch (e) {
  // Silently ignore errors
}
```

## 참조

- [워크스페이스 페이지 체크리스트](workspace-page-checklist.md) - 단계별 가이드
- [워크스페이스 트러블슈팅](workspace-troubleshooting.md) - 문제 해결
- [워크스페이스 네비게이션 플로우](../ui-ux/pages/workspace-navigation-flow.md) - 읽음 위치 저장 시점
