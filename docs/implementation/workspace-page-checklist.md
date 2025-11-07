# 워크스페이스 페이지 체크리스트

> [워크스페이스 페이지 구현 가이드](workspace-page-implementation-guide.md)의 연속

## 체크리스트 5-10단계

### 5단계: page_title_provider.dart - 데스크톱 브레드크럼 추가
**파일**: frontend/lib/presentation/providers/page_title_provider.dart
**위치**: 라인 160-189 (_buildDesktopBreadcrumb 함수)

```dart
switch (context.currentView) {
  case WorkspaceView.yourNewPage:  // ⬅️ 추가
    return const PageBreadcrumb(title: '내 페이지');
  // ... 기존 케이스들
}
```

### 6단계: page_title_provider.dart - 모바일 브레드크럼 추가
**파일**: frontend/lib/presentation/providers/page_title_provider.dart
**위치**: 라인 196-216 (_buildMobileBreadcrumb 함수)

```dart
if (context.currentView == WorkspaceView.yourNewPage) {  // ⬅️ 추가
  return const PageBreadcrumb(title: '내 페이지', path: ['내 페이지']);
}
```

### 7단계: 페이지 파일 작성
**필수 패턴**:
- ConsumerWidget 사용 (상태가 Provider로만 관리되는 경우)
- 그룹 ID 검증 (WorkspaceStateView 활용)
- 반응형 레이아웃 (ResponsiveBreakpoints)

### 8단계: workspace_page.dart에 import 추가
```dart
import '../your_feature/your_new_page.dart';  // ⬅️ 추가
```

### 9단계: 네비게이션 연결
```dart
ElevatedButton(
  onPressed: () => ref.read(workspaceStateProvider.notifier).showYourNewPage(),
  child: const Text('내 페이지 열기'),
)
```

### 10단계: 테스트 및 검증
- 모바일/데스크톱 뷰 확인
- 뒤로가기 동작 확인
- 브레드크럼 표시 확인

## 실수하기 쉬운 부분 TOP 10

### 1. workspace_page.dart 2곳 수정 누락 ⭐⭐⭐
**증상**: 모바일에서만 작동하거나 데스크톱에서만 작동
**해결**: _buildMobileWorkspace와 _buildMainContent 모두 수정

### 2. page_title_provider.dart 2곳 수정 누락 ⭐⭐⭐
**증상**: 페이지 제목이 표시되지 않음
**해결**: _buildDesktopBreadcrumb와 _buildMobileBreadcrumb 모두 수정

### 3. 상태 초기화 누락 ⭐⭐
**증상**: 이전 페이지의 채널/게시글이 선택된 채로 남음
**해결**: selectedChannelId, isCommentsVisible, selectedPostId 모두 null 처리

### 4. previousView 저장 누락 ⭐⭐
**증상**: 브라우저 뒤로가기 버튼이 작동하지 않음
**해결**: `previousView: state.currentView` 필수

### 5. enum 순서 변경 ⭐
**증상**: 기존 페이지가 엉뚱한 페이지로 표시됨
**해결**: 항상 enum 끝에 추가

### 6. import 누락 ⭐
**증상**: 컴파일 에러 "Undefined name 'YourNewPage'"
**해결**: workspace_page.dart에 import 추가

### 7. switch 문 exhaustive 처리 누락
**증상**: 컴파일러 경고
**해결**: 모든 enum 케이스 처리

### 8. WorkspaceStateView 에러 처리 누락 ⭐
**증상**: 그룹 미선택 시 빈 화면 또는 크래시
**해결**: groupId null 체크 필수

### 9. 반응형 레이아웃 고려 누락
**증상**: 모바일에서 레이아웃이 깨짐
**해결**: ResponsiveBreakpoints 활용

### 10. Provider family 파라미터 타입 불일치
**증상**: 런타임 에러 "type 'String' is not a subtype of type 'int'"
**해결**: int.parse(groupIdStr) 명시적 변환

## 참조

**관련 가이드**:
- [워크스페이스 구현 가이드](workspace-page-implementation-guide.md) - Part 1
- [워크스페이스 상태 관리](workspace-state-management.md) - 상태 설계
- [워크스페이스 트러블슈팅](workspace-troubleshooting.md) - 문제 해결
