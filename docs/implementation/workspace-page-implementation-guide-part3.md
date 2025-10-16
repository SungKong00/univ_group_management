# 워크스페이스 페이지 추가 가이드 (Part 3)

> 이 문서는 [workspace-page-implementation-guide-part2.md](workspace-page-implementation-guide-part2.md)의 연속입니다.

## 실수하기 쉬운 부분 TOP 10

### 1. workspace_page.dart 2곳 수정 누락 ⭐⭐⭐
**증상**: 모바일에서만 작동하거나 데스크톱에서만 작동
**원인**: `_buildMobileWorkspace`와 `_buildMainContent` 중 한 곳만 수정
**해결**: 두 메서드의 switch 문 모두에 케이스 추가
```dart
// 라인 448-472: _buildMobileWorkspace
case WorkspaceView.yourNewPage:
  return const YourNewPage();

// 라인 570-604: _buildMainContent
case WorkspaceView.yourNewPage:
  return const YourNewPage();
```

### 2. page_title_provider.dart 2곳 수정 누락 ⭐⭐⭐
**증상**: 페이지 제목이 표시되지 않거나 "워크스페이스"로만 표시
**원인**: `_buildDesktopBreadcrumb`와 `_buildMobileBreadcrumb` 중 한 곳만 수정
**해결**: 두 함수 모두에 케이스 추가
```dart
// 라인 160-189: _buildDesktopBreadcrumb (switch 문)
case WorkspaceView.yourNewPage:
  return const PageBreadcrumb(title: '내 페이지');

// 라인 196-216: _buildMobileBreadcrumb (if 문)
if (context.currentView == WorkspaceView.yourNewPage) {
  return const PageBreadcrumb(title: '내 페이지', path: ['내 페이지']);
}
```

### 3. 네비게이션 메서드에서 상태 초기화 누락 ⭐⭐
**증상**: 이전 페이지의 채널/게시글이 선택된 채로 남음
**원인**: `showYourNewPage()`에서 상태 초기화 안 함
**해결**: 필수 필드 모두 null 처리
```dart
void showYourNewPage() {
  state = state.copyWith(
    previousView: state.currentView,
    currentView: WorkspaceView.yourNewPage,
    selectedChannelId: null,                // 필수!
    isCommentsVisible: false,               // 필수!
    selectedPostId: null,                   // 필수!
    isNarrowDesktopCommentsFullscreen: false, // 필수!
  );
}
```

### 4. previousView 저장 누락 ⭐⭐
**증상**: 브라우저 뒤로가기 버튼이 작동하지 않음
**원인**: `previousView: state.currentView` 누락
**해결**: 항상 이전 뷰 저장
```dart
void showYourNewPage() {
  state = state.copyWith(
    previousView: state.currentView,  // 필수!
    currentView: WorkspaceView.yourNewPage,
    // ...
  );
}
```

### 5. enum 순서 변경 ⭐
**증상**: 기존 페이지가 엉뚱한 페이지로 표시됨
**원인**: enum 값 사이에 새 값 삽입
**해결**: 항상 enum 끝에 추가
```dart
// ❌ 잘못된 방법
enum WorkspaceView {
  channel,
  yourNewPage,  // 기존 값 사이에 삽입
  groupHome,    // 순서가 바뀜!
}

// ✅ 올바른 방법
enum WorkspaceView {
  channel,
  groupHome,
  yourNewPage,  // 끝에 추가
}
```

### 6. import 누락 ⭐
**증상**: 컴파일 에러 "Undefined name 'YourNewPage'"
**원인**: workspace_page.dart에 import 안 함
**해결**: 파일 상단에 import 추가
```dart
import '../your_feature/your_new_page.dart';
```

### 7. switch 문에서 exhaustive 처리 누락
**증상**: 컴파일러 경고 "The switch is not exhaustive"
**원인**: 모든 enum 케이스를 처리하지 않음
**해결**: 빠진 케이스 추가 또는 default 처리
```dart
switch (currentView) {
  case WorkspaceView.channel:
    return ChannelView();
  case WorkspaceView.yourNewPage:
    return YourNewPage();
  // ... 모든 케이스 처리 필수
}
```

### 8. WorkspaceStateView 에러 처리 누락 ⭐
**증상**: 그룹 미선택 시 빈 화면 또는 크래시
**원인**: groupId null 체크 안 함
**해결**: 페이지 진입 시 필수 체크
```dart
final groupIdStr = ref.watch(currentGroupIdProvider);
if (groupIdStr == null) {
  return const WorkspaceStateView(type: WorkspaceStateType.noGroup);
}
```

### 9. 반응형 레이아웃 고려 누락
**증상**: 모바일에서 레이아웃이 깨짐
**원인**: 고정된 패딩/폰트 크기 사용
**해결**: ResponsiveBreakpoints 활용
```dart
final isDesktop = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
final padding = isDesktop ? AppSpacing.lg : AppSpacing.sm;
```

### 10. Provider family 파라미터 타입 불일치
**증상**: 런타임 에러 "type 'String' is not a subtype of type 'int'"
**원인**: groupId를 String으로 전달했는데 Provider는 int 기대
**해결**: 타입 변환 명시
```dart
// ❌ 잘못된 방법
YourProvider(groupId: groupIdStr)  // String 전달

// ✅ 올바른 방법
YourProvider(groupId: int.parse(groupIdStr))  // int 변환
```

## 상태 관리 설계

### WorkspaceStateProvider 아키텍처

**상태 구조**:
```dart
class WorkspaceState {
  final String? selectedGroupId;        // 현재 그룹
  final String? selectedChannelId;      // 현재 채널
  final bool isCommentsVisible;         // 댓글 사이드바 표시 여부
  final String? selectedPostId;         // 선택된 게시글
  final WorkspaceView currentView;      // 현재 뷰
  final WorkspaceView? previousView;    // 이전 뷰 (뒤로가기)
  final List<String> channelHistory;    // 채널 히스토리
}
```

**상태 격리 원칙**:
- 각 뷰는 독립적인 상태를 가짐
- 뷰 전환 시 불필요한 상태는 초기화
- 채널 관련 상태는 channel 뷰에서만 유효

### 네비게이션 메서드 패턴

**표준 템플릿**:
```dart
void showXXXPage() {
  state = state.copyWith(
    // 1. 뒤로가기 지원
    previousView: state.currentView,

    // 2. 뷰 전환
    currentView: WorkspaceView.xxx,

    // 3. 상태 초기화 (채널/게시글/댓글)
    selectedChannelId: null,
    isCommentsVisible: false,
    selectedPostId: null,
    isNarrowDesktopCommentsFullscreen: false,

    // 4. 필요시 추가 상태 설정
    // customState: value,
  );
}
```

**채널 뷰로 복귀**:
```dart
void showChannel(String channelId) {
  selectChannel(channelId);  // 기존 메서드 재사용
}
```

### previousView 활용 (뒤로가기)

**히스토리 추적**:
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

**다단계 히스토리**:
```dart
// memberManagement → groupAdmin → channel 순서
showMemberManagementPage() {
  previousView: WorkspaceView.groupAdmin,  // 직전 페이지
}

handleMobileBack() {
  final prev = state.previousView!;
  final nextPrev = prev == WorkspaceView.groupAdmin
      ? WorkspaceView.channel  // 2단계 뒤로가기
      : null;
  state = state.copyWith(currentView: prev, previousView: nextPrev);
}
```
