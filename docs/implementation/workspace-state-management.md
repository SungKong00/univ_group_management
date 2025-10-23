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
  final List<String> channelHistory;    // 채널 히스토리
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

## previousView 활용 (뒤로가기)

### 단일 히스토리
```dart
// 페이지 이동 시
showYourNewPage() {
  previousView: state.currentView,  // 현재 → 이전
  currentView: WorkspaceView.yourNewPage,
}

// 뒤로가기 처리
handleWebBack() {
  if (state.previousView != null) {
    final prev = state.previousView!;
    state = state.copyWith(
      currentView: prev,
      previousView: null,  // 히스토리 초기화
    );
  }
}
```

### 다단계 히스토리
```dart
// memberManagement → groupAdmin → channel 순서
handleMobileBack() {
  final prev = state.previousView!;
  final nextPrev = prev == WorkspaceView.groupAdmin
      ? WorkspaceView.channel  // 2단계 뒤로가기
      : null;
  state = state.copyWith(currentView: prev, previousView: nextPrev);
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

## 참조

- [워크스페이스 페이지 체크리스트](workspace-page-checklist.md) - 단계별 가이드
- [워크스페이스 트러블슈팅](workspace-troubleshooting.md) - 문제 해결
