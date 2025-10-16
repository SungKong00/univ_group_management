# 워크스페이스 페이지 추가 가이드 (Part 4)

> 이 문서는 [workspace-page-implementation-guide-part3.md](workspace-page-implementation-guide-part3.md)의 연속입니다.

## 설계 고려사항

### 1. 페이지 간 상태 격리
각 페이지는 독립적인 상태를 유지해야 합니다.

**잘못된 설계**:
```dart
// 채널 페이지의 상태가 다른 페이지에 영향을 줌
showYourNewPage() {
  // selectedChannelId를 초기화하지 않음
  currentView: WorkspaceView.yourNewPage,
}
```

**올바른 설계**:
```dart
showYourNewPage() {
  selectedChannelId: null,        // 상태 격리
  isCommentsVisible: false,
  selectedPostId: null,
}
```

### 2. 네비게이션 히스토리 관리
사용자의 네비게이션 경로를 추적하여 자연스러운 뒤로가기를 지원합니다.

**단일 히스토리**:
```dart
previousView: state.currentView  // A → B 이동 시 A 저장
```

**다단계 히스토리**:
```dart
// channel → groupAdmin → memberManagement
// 뒤로가기: memberManagement → groupAdmin → channel
handleMobileBack() {
  final prev = state.previousView!;
  final nextPrev = prev == WorkspaceView.groupAdmin
      ? WorkspaceView.channel
      : null;
  state = state.copyWith(currentView: prev, previousView: nextPrev);
}
```

### 3. 에러 바운더리
페이지 진입 시 필수 조건을 검증하여 안정성을 확보합니다.

**필수 체크 항목**:
1. 그룹 선택 여부
2. 그룹 ID 유효성
3. 권한 확인
4. 데이터 로딩 상태

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

// 3. 권한 확인
final hasPermission = ref.watch(hasAdminPermissionProvider);
if (!hasPermission) {
  return WorkspaceStateView(
    type: WorkspaceStateType.error,
    errorMessage: '접근 권한이 없습니다.',
  );
}
```

### 4. 로딩 상태 처리
비동기 데이터 로딩 중 사용자에게 피드백을 제공합니다.

```dart
final dataAsync = ref.watch(yourDataProvider(groupId));

return dataAsync.when(
  loading: () => const WorkspaceStateView(type: WorkspaceStateType.loading),
  error: (error, stack) => WorkspaceStateView(
    type: WorkspaceStateType.error,
    errorMessage: error.toString(),
    onRetry: () => ref.refresh(yourDataProvider(groupId)),
  ),
  data: (data) => YourContent(data: data),
);
```

### 5. 빈 상태 처리
데이터가 없을 때 적절한 안내를 표시합니다.

```dart
if (data.isEmpty) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.inbox, size: 64, color: AppColors.neutral400),
        SizedBox(height: AppSpacing.md),
        Text(
          '아직 데이터가 없습니다',
          style: AppTheme.bodyLarge.copyWith(color: AppColors.neutral600),
        ),
        SizedBox(height: AppSpacing.sm),
        ElevatedButton(
          onPressed: () => _createNew(),
          child: const Text('새로 만들기'),
        ),
      ],
    ),
  );
}
```

### 6. 권한 기반 접근 제어
사용자의 역할에 따라 UI를 동적으로 표시합니다.

```dart
final hasAdminPermission = ref.watch(
  workspaceCurrentGroupPermissionsProvider.select(
    (permissions) => permissions?.contains('GROUP_MANAGE') ?? false,
  ),
);

// 조건부 렌더링
if (hasAdminPermission) {
  ElevatedButton(
    onPressed: () => _editGroup(),
    child: const Text('그룹 수정'),
  )
}
```

### 7. 반응형 디자인
화면 크기에 따라 레이아웃을 최적화합니다.

**브레이크포인트**:
- **Mobile**: 0-450px
- **Tablet**: 451-800px
- **Desktop**: 801px+

**패턴**:
```dart
final isDesktop = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

// 1. 조건부 패딩
final padding = isDesktop ? AppSpacing.lg : AppSpacing.sm;

// 2. 조건부 그리드
final crossAxisCount = isDesktop ? 3 : 1;

// 3. 조건부 위젯
if (isDesktop) {
  Row(children: [Sidebar(), Content()])
} else {
  Column(children: [Header(), Content()])
}
```

### 8. 성능 최적화 (Provider 재계산 최소화)

**select를 활용한 정밀한 구독**:
```dart
// ❌ 전체 상태 구독 (불필요한 재빌드)
final state = ref.watch(workspaceStateProvider);
final groupId = state.selectedGroupId;

// ✅ 필요한 부분만 구독
final groupId = ref.watch(
  workspaceStateProvider.select((state) => state.selectedGroupId),
);
```

**autoDispose로 메모리 관리**:
```dart
final dataProvider = FutureProvider.autoDispose.family<Data, int>((ref, id) async {
  // 페이지 벗어나면 자동으로 dispose
  return await fetchData(id);
});
```

## 트러블슈팅

### 페이지가 표시되지 않을 때

**체크리스트**:
1. WorkspaceView enum에 추가했는가?
2. workspace_page.dart 2곳(모바일/데스크톱)에 추가했는가?
3. import를 추가했는가?
4. showXXXPage() 메서드를 정의했는가?
5. 페이지를 호출하는 버튼/메뉴가 있는가?

**디버깅**:
```dart
// workspace_page.dart의 switch 문에 로그 추가
print('Current view: ${currentView}');
switch (currentView) {
  case WorkspaceView.yourNewPage:
    print('Rendering YourNewPage');
    return const YourNewPage();
}
```

### 상태가 초기화되지 않을 때

**증상**: 이전 채널/게시글이 선택된 채로 남음

**해결**:
```dart
void showYourNewPage() {
  state = state.copyWith(
    selectedChannelId: null,    // 추가
    isCommentsVisible: false,   // 추가
    selectedPostId: null,       // 추가
    isNarrowDesktopCommentsFullscreen: false,  // 추가
  );
}
```

### 뒤로가기가 작동하지 않을 때

**증상**: 브라우저 뒤로가기 버튼을 눌러도 아무 일도 일어나지 않음

**해결**:
```dart
// 1. previousView 저장 확인
void showYourNewPage() {
  state = state.copyWith(
    previousView: state.currentView,  // 필수!
  );
}

// 2. handleWebBack/handleMobileBack 로직 확인
bool handleWebBack() {
  if (state.currentView != WorkspaceView.channel &&
      state.previousView != null) {
    final prev = state.previousView!;
    state = state.copyWith(currentView: prev, previousView: null);
    return true;  // 내부 처리 완료
  }
  return false;  // 시스템 뒤로가기 허용
}
```

### enum exhaustive 에러 발생 시

**에러 메시지**: "The switch is not exhaustive"

**원인**: switch 문에서 모든 enum 케이스를 처리하지 않음

**해결**:
```dart
// ❌ 에러 발생
switch (currentView) {
  case WorkspaceView.channel:
    return ChannelView();
  // yourNewPage 케이스 누락!
}

// ✅ 모든 케이스 처리
switch (currentView) {
  case WorkspaceView.channel:
    return ChannelView();
  case WorkspaceView.yourNewPage:
    return YourNewPage();
  // ... 모든 케이스 추가
}
```

## 참조

### 관련 문서
- [워크스페이스 개념](../concepts/workspace-channel.md) - 시스템 이해
- [프론트엔드 가이드](frontend-guide.md) - 전체 아키텍처
- [권한 시스템](../concepts/permission-system.md) - 권한 관리
- [API 참조](api-reference.md) - 백엔드 연동

### 예시 구현
- **가입 승인 페이지**: `frontend/lib/presentation/pages/recruitment_management/application_management_page.dart`
- **채널 관리 페이지**: `frontend/lib/presentation/pages/admin/channel_management_page.dart`
- **멤버 관리 페이지**: `frontend/lib/presentation/pages/member_management/member_management_page.dart`

### 주요 파일 위치
```
frontend/lib/
├── presentation/
│   ├── providers/
│   │   ├── workspace_state_provider.dart    # 상태 관리 핵심
│   │   └── page_title_provider.dart         # 브레드크럼
│   └── pages/
│       ├── workspace/
│       │   ├── workspace_page.dart          # 라우팅 핵심
│       │   └── widgets/
│       │       └── workspace_state_view.dart  # 에러 처리
│       └── your_feature/
│           └── your_new_page.dart           # 새 페이지
```

### 다음 단계
1. 페이지 구현 후 [컨텍스트 업데이트 로그](../context-tracking/context-update-log.md)에 기록
2. 권한 관련 변경 시 [그룹 관리 권한 가이드](../maintenance/group-management-permissions.md) 참조
3. 테스트 데이터 추가 시 [테스트 데이터 참조](../testing/test-data-reference.md) 업데이트
