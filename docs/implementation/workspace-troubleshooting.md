# 워크스페이스 트러블슈팅

> [워크스페이스 페이지 구현 가이드](workspace-page-implementation-guide.md) 시리즈

## 페이지가 표시되지 않을 때

### 체크리스트
1. WorkspaceView enum에 추가했는가?
2. workspace_page.dart 2곳(모바일/데스크톱)에 추가했는가?
3. import를 추가했는가?
4. showXXXPage() 메서드를 정의했는가?
5. 페이지를 호출하는 버튼/메뉴가 있는가?

### 디버깅
```dart
print('Current view: ${currentView}');
switch (currentView) {
  case WorkspaceView.yourNewPage:
    print('Rendering YourNewPage');
    return const YourNewPage();
}
```

## 상태가 초기화되지 않을 때

**증상**: 이전 채널/게시글이 선택된 채로 남음

**해결**:
```dart
void showYourNewPage() {
  state = state.copyWith(
    selectedChannelId: null,
    isCommentsVisible: false,
    selectedPostId: null,
    isNarrowDesktopCommentsFullscreen: false,
  );
}
```

## 뒤로가기가 작동하지 않을 때

**증상**: 브라우저 뒤로가기 버튼을 눌러도 아무 일도 일어나지 않음

**해결**:
```dart
// 1. previousView 저장 확인
void showYourNewPage() {
  state = state.copyWith(
    previousView: state.currentView,  // 필수!
  );
}

// 2. handleWebBack 로직 확인
bool handleWebBack() {
  if (state.currentView != WorkspaceView.channel &&
      state.previousView != null) {
    final prev = state.previousView!;
    state = state.copyWith(currentView: prev, previousView: null);
    return true;
  }
  return false;
}
```

## enum exhaustive 에러 발생 시

**에러 메시지**: "The switch is not exhaustive"

**원인**: switch 문에서 모든 enum 케이스를 처리하지 않음

**해결**: 모든 케이스 추가
```dart
switch (currentView) {
  case WorkspaceView.channel: return ChannelView();
  case WorkspaceView.yourNewPage: return YourNewPage();
  // ... 모든 케이스 추가
}
```

## 발생한 오류 및 해결

### 읽지 않은 글 경계선 표시 안 됨 (2025-11-03)
**증상**: 워크스페이스 채널에서 읽지 않은 글 뱃지는 정상이나, 경계선 표시 및 자동 스크롤이 작동하지 않음

**원인**: `read_position_helper.dart`의 `findFirstUnreadGlobalIndex()` 메서드가 `lastReadPostId == null`을 잘못 해석
- 기존: null → "읽지 않은 글 없음" (return null)
- 올바른 해석: null → "모든 글이 읽지 않음" (return 0)

**해결**:
1. **read_position_helper.dart** (line 51-60)
   - `lastReadPostId == null`일 때 0 반환 (첫 번째 글이 읽지 않음)
   - `lastReadPostId`를 찾지 못한 경우 null 반환 (모든 글이 읽음)

2. **post_list.dart** (line 127-160, 264-268)
   - `_waitForReadPositionData()` 메서드 추가 (Race Condition 방지)
   - AutoScrollController 대기 시간 100ms → 300ms 증가

### BoxConstraints 무한 너비 에러
**원인**: Row/Column 내부에서 무제한 크기 위젯 사용
**해결**: Expanded, Flexible로 명시적 크기 제약

자세한 가이드: [row-column-layout-checklist.md](row-column-layout-checklist.md)

### ScaffoldMessenger 의존성 문제
**원인**: Scaffold 없는 페이지에서 ScaffoldMessenger.of(context) 호출
**해결**: SnackBar 대신 ref.invalidate() 또는 Dialog 사용

## 참조

### 관련 문서
- [워크스페이스 개념](../concepts/workspace-channel.md) - 시스템 이해
- [프론트엔드 아키텍처](frontend/architecture.md) - 전체 아키텍처
- [권한 시스템](../concepts/permission-system.md) - 권한 관리

### 예시 구현
- **가입 승인**: frontend/lib/presentation/pages/recruitment_management/application_management_page.dart
- **채널 관리**: frontend/lib/presentation/pages/admin/channel_management_page.dart
- **멤버 관리**: frontend/lib/presentation/pages/member_management/member_management_page.dart

### 주요 파일 위치
```
frontend/lib/presentation/
├── providers/
│   ├── workspace_state_provider.dart    # 상태 관리 핵심
│   └── page_title_provider.dart         # 브레드크럼
└── pages/workspace/
    ├── workspace_page.dart              # 라우팅 핵심
    └── widgets/workspace_state_view.dart  # 에러 처리
```
