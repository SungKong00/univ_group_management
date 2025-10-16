# 워크스페이스 페이지 추가 가이드 (Part 2)

> 이 문서는 [workspace-page-implementation-guide.md](workspace-page-implementation-guide.md)의 연속입니다.

## 필수 체크리스트 계속

### 5단계: page_title_provider.dart - 데스크톱 브레드크럼 추가
**파일**: `frontend/lib/presentation/providers/page_title_provider.dart`
**위치**: 라인 160-189 (`_buildDesktopBreadcrumb` 함수)

```dart
PageBreadcrumb _buildDesktopBreadcrumb(WorkspaceBreadcrumbContext context) {
  // ... 댓글 오버레이 처리

  switch (context.currentView) {
    case WorkspaceView.groupAdmin:
      return const PageBreadcrumb(title: '그룹 관리');
    case WorkspaceView.yourNewPage:  // ⬅️ 추가
      return const PageBreadcrumb(title: '내 페이지');
    // ... 기존 케이스들
    case WorkspaceView.channel:
      return const PageBreadcrumb(title: '워크스페이스');
  }
}
```

### 6단계: page_title_provider.dart - 모바일 브레드크럼 추가
**파일**: `frontend/lib/presentation/providers/page_title_provider.dart`
**위치**: 라인 196-216 (`_buildMobileBreadcrumb` 함수)

```dart
PageBreadcrumb _buildMobileBreadcrumb(
  WorkspaceBreadcrumbContext context,
  String groupName,
) {
  // 특수 뷰는 전용 타이틀 우선 표시
  if (context.currentView == WorkspaceView.groupAdmin) {
    return const PageBreadcrumb(title: '그룹 관리', path: ['그룹 관리']);
  }
  if (context.currentView == WorkspaceView.yourNewPage) {  // ⬅️ 추가
    return const PageBreadcrumb(title: '내 페이지', path: ['내 페이지']);
  }
  // ... 기존 조건들

  // 현재 뷰 타입에 따라 브레드크럼 형식 결정
  switch (context.mobileView) {
    // ...
  }
}
```

**실수 방지**: 2곳 모두 추가해야 제목이 정상 표시됩니다.

### 7단계: 페이지 파일 작성
**파일**: `frontend/lib/presentation/pages/your_feature/your_new_page.dart` (새 파일)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme.dart';
import '../../providers/workspace_state_provider.dart';
import '../workspace/widgets/workspace_state_view.dart';

/// 내 새 페이지
///
/// 기능 설명
class YourNewPage extends ConsumerWidget {
  const YourNewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupIdStr = ref.watch(currentGroupIdProvider);

    // 에러 처리 1: 그룹 미선택
    if (groupIdStr == null) {
      return const WorkspaceStateView(type: WorkspaceStateType.noGroup);
    }

    final groupId = int.tryParse(groupIdStr);
    // 에러 처리 2: 잘못된 그룹 ID
    if (groupId == null) {
      return WorkspaceStateView(
        type: WorkspaceStateType.error,
        errorMessage: '그룹 정보를 불러오지 못했습니다.',
      );
    }

    // 반응형 레이아웃
    final isDesktop = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
    final paddingHorizontal = isDesktop ? AppSpacing.lg : AppSpacing.sm;
    final paddingVertical = isDesktop ? AppSpacing.lg : AppSpacing.sm;

    return Container(
      color: AppColors.neutral100,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: paddingHorizontal,
          vertical: paddingVertical,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Text(
              '내 페이지',
              style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                color: AppColors.neutral900,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              '페이지 설명을 여기에 작성하세요.',
              style: AppTheme.bodyMedium.copyWith(
                color: AppColors.neutral600,
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            // 실제 콘텐츠
            YourContentWidget(
              groupId: groupId,
              isDesktop: isDesktop,
            ),
          ],
        ),
      ),
    );
  }
}
```

### 8단계: workspace_page.dart에 import 추가
**파일**: `frontend/lib/presentation/pages/workspace/workspace_page.dart`
**위치**: 라인 1-37 (import 섹션)

```dart
// ... 기존 import들
import '../recruitment_management/application_management_page.dart';
import '../your_feature/your_new_page.dart';  // ⬅️ 추가
import 'calendar/group_calendar_page.dart';
```

### 9단계: 네비게이션 연결 (옵션)
페이지를 어디서 호출할지에 따라 다음 위치에 버튼/메뉴 추가:

**그룹 관리자 페이지에서 접근**:
```dart
// frontend/lib/presentation/pages/group/group_admin_page.dart
ElevatedButton(
  onPressed: () {
    ref.read(workspaceStateProvider.notifier).showYourNewPage();
  },
  child: const Text('내 페이지 열기'),
)
```

**워크스페이스 사이드바 메뉴**:
```dart
// frontend/lib/presentation/widgets/workspace/mobile_channel_list.dart
// 또는 데스크톱 메뉴에 추가
```

### 10단계: 테스트 및 검증
1. **모바일 뷰 테스트**: 크롬 개발자 도구로 모바일 크기 확인
2. **데스크톱 뷰 테스트**: 전체 화면에서 레이아웃 확인
3. **뒤로가기 테스트**: 브라우저 뒤로가기 버튼 동작 확인
4. **브레드크럼 테스트**: 제목이 정상 표시되는지 확인
5. **에러 케이스**: 그룹 미선택 시 에러 메시지 확인
6. **반응형 전환**: 창 크기 조절 시 레이아웃 변화 확인

## 페이지 구현 패턴

### ConsumerWidget vs ConsumerStatefulWidget

**ConsumerWidget (권장)**:
- 상태가 Provider로만 관리되는 경우
- 예: 지원자 관리, 채널 관리 페이지
- 코드가 간결하고 테스트 용이

**ConsumerStatefulWidget**:
- 로컬 UI 상태가 필요한 경우
- 예: 폼 입력, 탭 전환, 애니메이션
- 예: WorkspacePage (스크롤 위치 보존)

### 에러 처리 패턴

**WorkspaceStateView 활용**:
```dart
// 1. 로딩 상태
if (isLoading) {
  return const WorkspaceStateView(type: WorkspaceStateType.loading);
}

// 2. 에러 상태
if (errorMessage != null) {
  return WorkspaceStateView(
    type: WorkspaceStateType.error,
    errorMessage: errorMessage,
    onRetry: _retryLoad,  // 재시도 콜백
  );
}

// 3. 빈 상태
if (data.isEmpty) {
  return const WorkspaceStateView(type: WorkspaceStateType.empty);
}
```

### 반응형 레이아웃 패턴

**ResponsiveBreakpoints 활용**:
```dart
final isDesktop = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
final isMobile = ResponsiveBreakpoints.of(context).isMobile;

// 조건부 패딩
final paddingH = isDesktop ? AppSpacing.lg : AppSpacing.sm;

// 조건부 컬럼 수
final crossAxisCount = isDesktop ? 3 : 1;

// 조건부 위젯
if (isDesktop) DesktopLayout() else MobileLayout()
```
