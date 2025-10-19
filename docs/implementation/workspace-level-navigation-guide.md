# 워크스페이스 레벨 네비게이션 가이드

## 개요

워크스페이스 내에서 **전체 화면 교체 없이** 뷰를 전환하는 상태 관리 방식입니다.
`WorkspaceView` enum으로 채널 목록, 그룹 정보, 권한을 유지하며 부드럽게 화면을 전환합니다.

**관련**: [워크스페이스 페이지 추가 가이드](workspace-page-implementation-guide.md)

## 아키텍처

### WorkspaceView Enum
9가지 뷰 타입: `channel`, `groupHome`, `calendar`, `groupAdmin`, `memberManagement`, `channelManagement`, `recruitmentManagement`, `applicationManagement`, `placeTimeManagement`

### WorkspaceState
- `currentView`: 현재 뷰 (WorkspaceView enum)
- `previousView`: 뒤로가기용 이전 뷰
- 채널 상태: 특수 뷰 진입 시 초기화

### 플로우
버튼 클릭 → `showXXXPage()` → `state.copyWith(currentView, previousView)` → `switch (currentView)` → 위젯 렌더링

## 구현 과정

### 1. Enum 추가 (workspace_state_provider.dart, 라인 15-25)
새 뷰 타입을 enum 끝에 추가 (순서 변경 금지)

### 2. 네비게이션 메서드 (workspace_state_provider.dart, 라인 600-660)
`showXXXPage()` 구현: `previousView` 설정, 채널 상태 초기화 필수

### 3-4. Switch 문 추가 (workspace_page.dart)
- 모바일: `_buildMobileWorkspace` (라인 448-487)
- 데스크톱: `_buildMainContent` (라인 585-634)

### 5. 브레드크럼 (page_title_provider.dart, 라인 176-226)
`_buildDesktopBreadcrumb`, `_buildMobileBreadcrumb`에 케이스 추가

### 6. 진입점 추가
```dart
ElevatedButton(
  onPressed: () => ref.read(workspaceStateProvider.notifier).showXXXPage(),
  child: Text('XXX 관리'),
)
```

### 7. 뒤로가기 검증
`handleWebBack()`, `handleMobileBack()` 동작 및 `previousView` 복원 확인

## 발생한 오류 및 해결

### 1. BoxConstraints 무한 너비 에러
**원인**: Row/Column 내부에서 무제한 크기를 갖는 위젯 사용
**해결**: `Expanded`, `Flexible`, 또는 `ConstrainedBox`로 명시적 크기 제약

### 2. 모달 무한 로딩 (Riverpod ref 컨텍스트)
**원인**: `showDialog` 내부에서 `ref.read(provider.notifier)` 호출 시 위젯 트리 외부 컨텍스트 사용
**해결**: 다이얼로그 열기 전에 notifier를 미리 추출하거나, Consumer로 감싸서 올바른 ref 제공

### 3. WorkspaceView Switch Exhaustive Matching 에러
**원인**: enum에 새 케이스 추가 시 switch 문에 해당 케이스 누락
**에러 메시지**: "The type 'WorkspaceView' is not exhaustively matched by the switch cases"
**해결**: `workspace_page.dart`의 두 switch 문 모두에 새 케이스 추가

### 4. ScaffoldMessenger 의존성 문제
**원인**: Scaffold 없는 workspace-level 페이지의 하위 위젯에서 `ScaffoldMessenger.of(context)` 호출
**에러**: "Could not find parent Scaffold" 런타임 에러
**예**: `restricted_time_widgets.dart` 다이얼로그에서 SnackBar 표시 시도
**해결**:
- SnackBar 호출 제거 (`showSnackBar` 6곳 삭제)
- `ref.invalidate()`로 목록 자동 갱신 (피드백 대체)
- 필요시 `Dialog` 또는 Toast 라이브러리 사용

### 5. BoxConstraints 무한 너비 에러 (Row 내부)
**원인**: `Row(mainAxisAlignment: MainAxisAlignment.spaceBetween)` 내부의 버튼이 무제한 너비를 받음
**에러**: "BoxConstraints forces an infinite width"
**예**: `restricted_time_widgets.dart` L38-70, Card/Column 내 Row에서 `ElevatedButton.icon` 크기 계산 불가
**해결**: `Flexible`로 버튼 감싸기
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text(...),
    Flexible(child: ElevatedButton.icon(...)),
  ],
)
```

## 재발 방지 체크리스트

### 새 페이지 추가 시 (7단계)
1. `WorkspaceView` enum 끝에 추가
2. `showXXXPage()` 메서드: `previousView`, 채널 상태 초기화
3. `workspace_page.dart` 모바일 switch 추가
4. `workspace_page.dart` 데스크톱 switch 추가
5. `page_title_provider.dart` 브레드크럼 (데스크톱/모바일)
6. 진입 버튼 추가
7. 뒤로가기 테스트

### 컨벤션
- 메서드: `showXXXPage()`
- Enum: camelCase (예: `applicationManagement`)
- 브레드크럼: 한글 (예: "지원자 관리")
- 상태 초기화: `selectedChannelId: null`, `isCommentsVisible: false`, `previousView: state.currentView`

### UI 컴포넌트 (workspace-level 페이지)
- **Scaffold 의존성**: 하위 위젯에서 `ScaffoldMessenger`, `Scaffold.of(context)` 사용 금지
- **Row/Column 레이아웃**: `Flexible`/`Expanded`로 자식 위젯 감싸기 (무한 너비 방지)
- **피드백**: SnackBar 대신 `ref.invalidate()` 또는 `Dialog` 사용
- **테스트**: 다이얼로그 열기/닫기, 목록 자동 갱신, `flutter analyze` 통과

## 참고 구현

**`applicationManagement` 뷰** (지원자 관리 페이지)
- `workspace_state_provider.dart` L635-645: `showApplicationManagementPage()`
- `workspace_page.dart` L467-468, L603-604: switch 케이스
- `page_title_provider.dart` L185-186, L220-222: 브레드크럼

**상세 가이드**: [워크스페이스 페이지 추가 가이드](workspace-page-implementation-guide.md)
