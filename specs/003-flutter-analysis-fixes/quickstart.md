# Quickstart: Flutter Lint Fix Execution

**Feature**: Flutter Code Quality & Analysis Issue Resolution
**Branch**: `003-flutter-analysis-fixes`
**Date**: 2025-11-13

이 가이드는 76개의 Flutter lint/analysis 문제를 우선순위별로 해결하는 실행 매뉴얼입니다.

## Prerequisites

- **Flutter SDK**: 3.x stable
- **Dart SDK**: 3.x
- **Git Branch**: `003-flutter-analysis-fixes` (자동 생성됨)
- **MCP Tools**: dart-flutter MCP 서버 설정 완료 (권장)
- **Working Directory**: `frontend/` 디렉토리

## Quick Status Check

### Current State
```bash
# MCP 사용 (권장)
mcp__dart-flutter__analyze_files

# 또는 Bash (헌법 허용)
cd frontend && flutter analyze
```

**Expected**: 76개 issues (Severity 1: 7개, Severity 2: 25개, Severity 3: 44개)

### Goal State
```bash
# 모든 수정 완료 후
flutter analyze
# Expected: 0 issues
```

---

## Phase 1: Critical Fixes (P1) - Severity 1 에러 해결

**목표**: 컴파일 에러 7개 → 0개

### 1.1 AppSnackBar Import Fix

**파일**: `frontend/lib/presentation/pages/auth/login_page.dart`
**라인**: 91, 96, 120, 310
**문제**: `AppSnackBar` 클래스를 찾을 수 없음

**해결 방법 1**: AppSnackBar 파일 찾기
```bash
# AppSnackBar 파일 검색
cd frontend && find lib -name "*snack*" -type f

# 발견 시 import 추가
# import 'package:your_app/path/to/app_snack_bar.dart';
```

**해결 방법 2**: Flutter 기본 SnackBar 사용
```dart
// Before
AppSnackBar.showError(context, '에러 메시지');

// After
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('에러 메시지')),
);
```

**검증**:
```bash
flutter analyze lib/presentation/pages/auth/login_page.dart | grep "AppSnackBar"
# Expected: 0 matches
```

---

### 1.2 @JsonSerializable Annotation Fix

**파일**: `frontend/lib/core/navigation/navigation_state.dart`
**라인**: 9
**문제**: `@JsonSerializable`이 클래스가 아닌 곳에 적용됨

**현재 코드 분석**:
```bash
# 문제 위치 확인
cd frontend && cat -n lib/core/navigation/navigation_state.dart | head -20
```

**해결 방법**:
```dart
// ❌ Before: annotation이 클래스 밖에 있음
@JsonSerializable()
part 'navigation_state.g.dart';

class NavigationState {
  // ...
}

// ✅ After: annotation을 클래스에 직접 적용
part 'navigation_state.g.dart';

@JsonSerializable()
class NavigationState {
  // ...
}
```

**검증**:
```bash
flutter analyze lib/core/navigation/navigation_state.dart | grep "invalid_annotation_target"
# Expected: 0 matches
```

---

### 1.3 Protected Member Access Fix

**파일**: `frontend/lib/presentation/pages/workspace/calendar/group_calendar_page.dart`
**라인**: 68
**문제**: `StateNotifier.state`를 외부에서 직접 접근

**현재 코드 패턴**:
```dart
// ❌ Before
final notifier = ref.read(calendarStateProvider.notifier);
final currentState = notifier.state;  // protected member 접근
```

**해결 방법**:
```dart
// ✅ After: ref.watch 또는 ref.read 사용
final currentState = ref.watch(calendarStateProvider);  // 반응형 읽기
// 또는
final currentState = ref.read(calendarStateProvider);  // 일회성 읽기
```

**검증**:
```bash
flutter analyze lib/presentation/pages/workspace/calendar/group_calendar_page.dart | grep "invalid_use_of_protected_member"
# Expected: 0 matches
```

---

### Phase 1 최종 검증
```bash
# MCP 사용 (권장)
mcp__dart-flutter__analyze_files

# Severity 1 에러만 확인
cd frontend && flutter analyze | grep "error •"
# Expected: 0 errors
```

**Checkpoint**: Severity 1 에러 7개 → 0개 달성

---

## Phase 2: BuildContext Safety (P2) - 런타임 안정성 강화

**목표**: `use_build_context_synchronously` 경고 17개 → 0개

### 2.1 Automated Fix Attempt

먼저 자동 수정 시도:
```bash
# MCP 사용 (권장)
mcp__dart-flutter__dart_fix --roots '[{"root": "file:///Users/nohsungbeen/univ/2025-2/project/personal_project/univ_group_management/frontend"}]'

# 또는 Bash (헌법 허용)
cd frontend && dart fix --apply
```

> **Note**: BuildContext 문제는 자동 수정이 제한적일 수 있으므로 수동 검토 필요

---

### 2.2 Manual mounted Checks

자동 수정 후에도 남은 경고를 수동으로 수정합니다.

#### 2.2.1 group_calendar_page.dart (9개 경고)
**파일**: `frontend/lib/presentation/pages/workspace/calendar/group_calendar_page.dart`
**라인**: 919, 948, 970, 1002, 1007, 1047, 1077, 1082, 1150, 1155

**패턴**:
```dart
// ❌ Before
await someAsyncOperation();
Navigator.of(context).pop();

// ✅ After
await someAsyncOperation();
if (mounted) {
  Navigator.of(context).pop();
}
```

**적용 예시**:
```dart
// 예시 1: 이벤트 생성 후 다이얼로그 닫기
Future<void> _createEvent() async {
  await ref.read(calendarProvider).createEvent(event);
  if (mounted) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('이벤트가 생성되었습니다')),
    );
  }
}

// 예시 2: 에러 처리 후 스낵바 표시
try {
  await someOperation();
} catch (e) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('오류: $e')),
    );
  }
}
```

---

#### 2.2.2 multi_place_calendar_view.dart (3개 경고)
**파일**: `frontend/lib/presentation/pages/workspace/calendar/widgets/multi_place_calendar_view.dart`
**라인**: 261, 402, 407

**패턴**:
```dart
// ❌ Before
await reservePlace();
context.pop();

// ✅ After
await reservePlace();
if (mounted) {
  context.pop();
}
```

---

#### 2.2.3 기타 파일 (5개 경고)
| 파일 | 라인 | 수정 패턴 |
|-----|------|----------|
| place_picker_dialog.dart | 52 | `if (mounted) Navigator.pop()` |
| place_list_page.dart | 314 | `if (mounted) showDialog()` |
| top_navigation.dart | 146 | `if (mounted) context.go()` |
| weekly_schedule_editor.dart | 1223, 1234, 1259, 1273 | `if (mounted) context.pop/showSnackBar()` |
| demo_calendar_page.dart | 269 | `if (mounted) setState()` |

---

### Phase 2 최종 검증
```bash
cd frontend && flutter analyze | grep "use_build_context_synchronously"
# Expected: 0 warnings
```

**Checkpoint**: BuildContext 경고 17개 → 0개 달성

---

## Phase 3: Deprecated API Migration (P3) - 향후 호환성 보장

**목표**: `deprecated_member_use` 경고 44개 → 0개

### 3.1 Color API Automated Fix

대부분의 Color API deprecated 경고는 자동 수정 가능:

```bash
# MCP 사용 (권장)
mcp__dart-flutter__dart_fix --roots '[{"root": "file:///Users/nohsungbeen/univ/2025-2/project/personal_project/univ_group_management/frontend"}]'

# 또는 Bash (헌법 허용)
cd frontend && dart fix --apply
```

**자동 수정 항목**:
- `withOpacity()` → `withValues(alpha: 0.5)`
- `.red/.green/.blue` → `.r/.g/.b`
- `.value` → `toARGB32()`

**영향받는 파일 (13개)**:
- available_times_widget.dart
- place_closure_widgets.dart (3개)
- place_operating_hours_editor.dart
- group_home_view.dart
- calendar_add_button.dart
- app_empty_state.dart (3개)
- unread_message_divider.dart (2개)
- highlight_painter.dart
- selection_painter.dart
- disabled_slots_painter.dart
- event_painter.dart (4개)
- fixed_duration_preview_painter.dart (2개)
- weekly_schedule_editor.dart

**검증 예시**:
```bash
# 수정 전
Colors.blue.withOpacity(0.5)

# 수정 후
Colors.blue.withValues(alpha: 0.5)
```

---

### 3.2 Web Platform Migration

**파일**: `frontend/lib/presentation/providers/workspace_state_provider_web.dart`
**문제**: `dart:js`와 `dart:html`이 deprecated

**Step 1: Import 변경**
```dart
// ❌ Before
import 'dart:js' as js;
import 'dart:html' as html;

// ✅ After
import 'dart:js_interop' as js;
import 'package:web/web.dart' as web;
```

**Step 2: API 패턴 전환**
```dart
// ❌ Before: JsObject 패턴
js.context['localStorage'].callMethod('setItem', ['key', 'value']);

// ✅ After: package:web 패턴
web.window.localStorage.setItem('key', 'value');
```

**Step 3: pubspec.yaml 업데이트**
```yaml
dependencies:
  web: ^1.0.0  # 추가 필요 시
```

**검증**:
```bash
# Web 빌드 테스트
cd frontend && flutter build web --release

# 또는 Web 실행
flutter run -d chrome --web-hostname localhost --web-port 5173
```

---

### 3.3 Radio Group Migration

**영향받는 파일 (2개)**:
1. `place_picker_dialog.dart` (2개 deprecated)
2. `event_create_dialog.dart` (6개 deprecated)

**Before**:
```dart
Radio<int>(
  value: 1,
  groupValue: selectedValue,  // deprecated
  onChanged: (value) => setState(...),  // deprecated
)
```

**After**: RadioGroup 사용
```dart
RadioGroup<int>(
  value: selectedValue,
  onChanged: (value) => setState(...),
  children: [
    Radio<int>(value: 1),
    Radio<int>(value: 2),
  ],
)
```

**Note**: RadioGroup API는 Flutter 3.7+에서 도입되었으므로, Flutter SDK 버전 확인 필요

---

### Phase 3 최종 검증
```bash
cd frontend && flutter analyze | grep "deprecated_member_use"
# Expected: 0 warnings
```

**Checkpoint**: Deprecated API 경고 44개 → 0개 달성

---

## Phase 4: Code Cleanup (P4) - 코드 가독성 향상

**목표**: Unused code 8개 + Documentation 문제 제거

### 4.1 Remove Unused Elements

#### 4.1.1 _slotToTime (3개 파일)
```bash
# 파일 목록
- frontend/lib/presentation/adapters/group_event_adapter.dart:173
- frontend/lib/presentation/adapters/personal_schedule_adapter.dart:148
- frontend/lib/presentation/adapters/place_reservation_adapter.dart:122
```

**조치**: 각 파일에서 `_slotToTime` 함수 제거 (사용하지 않음)

---

#### 4.1.2 기타 Unused Code
| 파일 | 라인 | 대상 | 조치 |
|-----|------|------|------|
| personal_schedule_adapter.dart | 157 | `_calculateDurationSlots` | 제거 |
| timetable_tab.dart | 185 | `_handleScheduleTap` | 제거 또는 사용 |
| timetable_tab.dart | 349 | `textTheme` 변수 | 제거 |
| restricted_time_widgets.dart | 18 | `_dayLabels` 필드 | 제거 |
| keyboard_navigation_test.dart | 16 | `selectedIndex` 변수 | 제거 |
| post_list.dart | 262 | `post` 변수 | 제거 또는 사용 |

**검증**:
```bash
cd frontend && flutter analyze | grep "unused_"
# Expected: 0 warnings
```

---

### 4.2 Fix Documentation Issues

#### 4.2.1 HTML in Doc Comments
**파일**: `frontend/lib/core/utils/place_availability_helper.dart`
**라인**: 287-288
**문제**: Doc comment에 `<>` 기호가 이스케이핑되지 않음

**Before**:
```dart
/// Returns a <Map<String, dynamic>> with availability data
```

**After**:
```dart
/// Returns a `Map<String, dynamic>` with availability data
```

---

#### 4.2.2 Library Directive 추가
**파일**:
- `workspace_state_provider_web.dart` (라인 0)
- `workspace_state_provider_stub.dart` (라인 0)

**Before**:
```dart
/// Workspace state provider for web platform
import 'package:...';
```

**After**:
```dart
/// Workspace state provider for web platform
library workspace_state_provider_web;

import 'package:...';
```

---

#### 4.2.3 기타 수정
| 파일 | 라인 | 문제 | 조치 |
|-----|------|------|------|
| primary_button.dart | 64 | unreachable switch default | default case 제거 |

---

### Phase 4 최종 검증
```bash
cd frontend && flutter analyze
# Expected: 0 issues (완전 클린)
```

**Checkpoint**: 모든 cleanup 완료

---

## Final Verification

### Step 1: Full Analysis
```bash
# MCP 사용 (권장)
mcp__dart-flutter__analyze_files

# 또는 Bash (헌법 허용)
cd frontend && flutter analyze
```

**Expected Output**:
```
Analyzing frontend...
No issues found!
```

---

### Step 2: Run All Tests
```bash
# MCP 사용 (권장)
mcp__dart-flutter__run_tests --roots '[{"root": "file:///Users/nohsungbeen/univ/2025-2/project/personal_project/univ_group_management/frontend"}]'

# 또는 Bash (헌법 허용)
cd frontend && flutter test
```

**Expected**: 100% 테스트 통과 (regression 없음)

---

### Step 3: Cross-Platform Verification

#### Web Platform
```bash
cd frontend && flutter run -d chrome --web-hostname localhost --web-port 5173
```

**Test Cases**:
- ✅ 로그인 페이지에서 에러 스낵바 표시
- ✅ 그룹 전환 시 상태 유지 (localStorage)
- ✅ 캘린더 이벤트 생성/수정/삭제
- ✅ 장소 예약 기능

#### Android (Optional)
```bash
cd frontend && flutter run -d android
```

#### iOS (Optional)
```bash
cd frontend && flutter run -d ios
```

---

## Success Criteria Checklist

### ✅ Code Quality
- [ ] `flutter analyze`: 0 issues (76 → 0)
- [ ] Severity 1 에러: 0개 (7 → 0)
- [ ] BuildContext 경고: 0개 (17 → 0)
- [ ] Deprecated API 경고: 0개 (44 → 0)
- [ ] Unused code: 0개 (8 → 0)

### ✅ Functionality
- [ ] `flutter test`: 100% pass
- [ ] 로그인 페이지 정상 작동
- [ ] 캘린더 기능 정상 작동
- [ ] 장소 예약 기능 정상 작동
- [ ] Web/Android/iOS 모든 플랫폼 정상 실행

### ✅ Documentation
- [ ] Doc comments HTML 이스케이핑 완료
- [ ] Library directives 추가 완료

---

## Troubleshooting

### Issue 1: dart fix가 일부 파일을 수정하지 못함
**Solution**: 수동으로 패턴 검색 및 수정
```bash
# withOpacity 사용 찾기
cd frontend && grep -r "withOpacity" lib/

# 수동으로 withValues로 변경
```

### Issue 2: Web migration 후 localStorage 오동작
**Solution**: package:web API 재확인
```dart
// 올바른 사용법
import 'package:web/web.dart' as web;

web.window.localStorage.setItem('key', 'value');
final value = web.window.localStorage.getItem('key');
```

### Issue 3: 테스트 실패
**Solution**: 변경 사항 rollback 및 개별 파일 검증
```bash
# 특정 파일만 테스트
flutter test test/path/to/failing_test.dart

# 변경 사항 확인
git diff
```

---

## Next Steps

1. ✅ **All Phases Complete**: 76개 lint 문제 모두 해결
2. ⏭️ **Code Review**: PR 생성 및 리뷰 요청
3. ⏭️ **Merge**: develop 브랜치로 병합

**PR Checklist**:
- [ ] 모든 Phase 완료 (P1, P2, P3, P4)
- [ ] flutter analyze 0 issues
- [ ] flutter test 100% pass
- [ ] Cross-platform 검증 완료
- [ ] Commit message 규칙 준수

**Branch**: `003-flutter-analysis-fixes` → `develop`
