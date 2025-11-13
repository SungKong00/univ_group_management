# Research: Flutter Lint Fix Patterns & Best Practices

**Feature**: Flutter Code Quality & Analysis Issue Resolution
**Date**: 2025-11-13
**Purpose**: 76개 lint 문제 해결을 위한 기술적 연구 및 Best Practice 결정

## R1: Dart Fix Automation

**Question**: `dart fix --apply`가 자동으로 해결할 수 있는 lint 문제와 수동 개입이 필요한 문제를 구분하는 기준은?

**Decision**: `dart fix --apply` 사용 + 수동 검토

**Rationale**:
- Dart 3.x의 `dart fix`는 deprecated API 교체 (withOpacity, Color accessors, Radio) 자동화 가능
- BuildContext 안전성은 자동 수정이 불가능하므로 수동으로 `mounted` 체크 추가 필요
- AppSnackBar import와 @JsonSerializable 위치는 프로젝트별 컨텍스트가 필요하여 수동 수정

**Alternatives Considered**:
1. **전체 수동 수정**: 시간 소요가 크고 휴먼 에러 위험
2. **IDE 자동 수정**: IntelliJ/VSCode의 Quick Fix는 파일별로만 작동하여 대량 수정에 부적합
3. **Custom Linter Rule**: 프로젝트 특화 규칙 작성은 과도한 투자 (일회성 수정)

**Automatic Fix Coverage**:
| Issue Type | Auto Fix | 개수 | 방법 |
|-----------|----------|-----|------|
| withOpacity → withValues | ✅ Yes | 13 files | dart fix --apply |
| Color.red/green/blue → .r/.g/.b | ✅ Yes | 2 files | dart fix --apply |
| Color.value → toARGB32 | ✅ Yes | 2 files | dart fix --apply |
| Radio deprecation | ✅ Yes | 4 files | dart fix --apply |
| dart:js → dart:js_interop | ❌ No | 1 file | Manual migration |
| BuildContext safety | ❌ No | 17 files | Manual mounted checks |
| AppSnackBar import | ❌ No | 1 file | Manual import |
| @JsonSerializable | ❌ No | 1 file | Manual annotation move |
| Protected member | ❌ No | 1 file | Manual Riverpod pattern |
| Unused code | ⚠️ Partial | 8 files | Remove dead code manually |

**Execution Strategy**:
1. Phase P3에서 `dart fix --apply` 실행 → 자동 수정 가능 항목 처리
2. Phase P1, P2에서 수동 수정 → 컨텍스트 의존적 문제 해결
3. 각 Phase 후 `flutter analyze`로 진행 상황 검증

---

## R2: BuildContext Safety Best Practices

**Question**: async 작업 후 BuildContext를 안전하게 사용하는 Flutter 표준 패턴은?

**Decision**: `if (mounted) context.method()` 패턴 사용

**Rationale**:
- StatefulWidget에서 `mounted` getter는 위젯이 트리에 마운트되어 있는지 확인
- async 작업 후 항상 `mounted` 체크를 수행하여 BuildContext 접근 안전성 보장
- Flutter 3.x부터 `mounted` 체크가 표준 권장 사항으로 자리 잡음

**Pattern**:
```dart
// ❌ Before (경고 발생)
await someAsyncOperation();
Navigator.of(context).pop();  // BuildContext 안전하지 않음

// ✅ After (안전)
await someAsyncOperation();
if (mounted) {
  Navigator.of(context).pop();  // mounted 체크 후 사용
}
```

**Alternatives Considered**:
1. **GlobalKey 사용**: 과도한 복잡도, 메모리 관리 부담
2. **BuildContext를 변수에 저장**: async gap 전에 저장해도 unmount 위험 동일
3. **StatelessWidget 전환**: 상태 관리가 필요한 위젯에서 불가능

**Application Details**:

| 파일 | 위치 | 패턴 | 설명 |
|-----|------|------|------|
| group_calendar_page.dart | 9곳 | `if (mounted) context.showSnackBar()` | 이벤트 생성/수정/삭제 후 스낵바 표시 |
| multi_place_calendar_view.dart | 3곳 | `if (mounted) context.pop()` | 예약 처리 후 다이얼로그 닫기 |
| place_picker_dialog.dart | 1곳 | `if (mounted) Navigator.of(context).pop()` | 장소 선택 후 닫기 |
| place_list_page.dart | 1곳 | `if (mounted) context.showDialog()` | API 호출 후 다이얼로그 표시 |
| top_navigation.dart | 1곳 | `if (mounted) context.go()` | 비동기 라우팅 |
| weekly_schedule_editor.dart | 4곳 | `if (mounted) context.pop()` | 저장/삭제 후 화면 이동 |
| demo_calendar_page.dart | 1곳 | `if (mounted) setState()` | async 후 상태 업데이트 |

**Edge Cases**:
- **중첩 async**: 여러 async 작업이 연속될 경우 각 작업 후 mounted 체크 필요
- **Timer/Future.delayed**: 지연된 작업도 mounted 체크 필요
- **Stream 구독**: `StreamSubscription.cancel()` 시점에 mounted 체크 불필요 (dispose에서 처리)

---

## R3: Web Platform Migration (dart:js → dart:js_interop)

**Question**: `dart:js`/`dart:html`을 `dart:js_interop`/`package:web`으로 마이그레이션하는 단계는?

**Decision**: `dart:js_interop` + `package:web` 마이그레이션

**Rationale**:
- Dart 3.0부터 `dart:js`/`dart:html`은 deprecated (Flutter 3.7+ 반영)
- `dart:js_interop`는 타입 안전한 JS interop 제공 (extension types 기반)
- `package:web`은 Web API를 Dart로 래핑하여 표준 인터페이스 제공

**Migration Steps**:

### Step 1: Import 변경
```dart
// Before
import 'dart:js' as js;
import 'dart:html' as html;

// After
import 'dart:js_interop' as js;
import 'package:web' as web;
```

### Step 2: JsObject 패턴 전환
```dart
// Before: JsObject 사용
js.context['localStorage'].callMethod('setItem', ['key', 'value']);

// After: @JS() annotation + extension types
@JS('localStorage.setItem')
external void setItem(String key, String value);

void saveToLocalStorage() {
  setItem('key', 'value');
}
```

### Step 3: window/document 접근 전환
```dart
// Before: dart:html
html.window.localStorage['key'] = 'value';

// After: package:web
web.window.localStorage.setItem('key', 'value');
```

**Affected File**: `workspace_state_provider_web.dart`

**Breaking Change Risk**: **LOW**
- 이 파일은 Web platform 전용 stub 구현
- Android/iOS에서는 `workspace_state_provider_stub.dart` 사용
- Platform-specific import로 격리되어 있어 다른 플랫폼 영향 없음

**Testing Strategy**:
1. Web 빌드: `flutter build web --release`
2. Chrome 실행: `flutter run -d chrome`
3. localStorage 기능 수동 테스트: 그룹 전환 시 상태 유지 확인

**Alternatives Considered**:
1. **dart:js 계속 사용**: Flutter SDK 업그레이드 시 breaking change 위험
2. **Conditional import 유지**: 현재도 사용 중이지만 deprecated API를 최신 API로 교체 필요
3. **완전 Riverpod 마이그레이션**: 과도한 리팩터링, 이번 작업 범위 초과

---

## R4: Riverpod Protected Member Access

**Question**: StateNotifier의 `.state`를 외부에서 직접 접근하지 않고 Riverpod 패턴을 따르는 방법은?

**Decision**: `ref.watch`/`ref.read`로 상태 접근

**Rationale**:
- `StateNotifier.state`는 protected member이므로 외부에서 직접 접근 금지
- Riverpod의 `StateNotifierProvider`는 `ref.watch(provider)` 또는 `ref.read(provider.notifier).method()`로 접근
- 캡슐화 유지 및 반응형 상태 관리를 위한 Riverpod 2.x 표준 패턴

**Pattern**:
```dart
// ❌ Before (에러 발생)
final notifier = ref.read(myProvider.notifier);
final currentState = notifier.state;  // protected member 접근

// ✅ After (올바른 패턴)
final currentState = ref.watch(myProvider);  // ref.watch로 상태 읽기
ref.read(myProvider.notifier).updateState();  // notifier 메서드 호출
```

**Specific Issue**: `group_calendar_page.dart:68`
```dart
// Current code (line 68)
final calendarState = ref.read(calendarStateProvider.notifier).state;  // ❌

// Fixed code
final calendarState = ref.watch(calendarStateProvider);  // ✅
```

**Riverpod 2.x Best Practices**:
1. **State 읽기**: `ref.watch(provider)` - 위젯 빌드 시 자동 재빌드
2. **State 수정**: `ref.read(provider.notifier).method()` - notifier 메서드 호출
3. **일회성 읽기**: `ref.read(provider)` - 이벤트 핸들러에서 현재 값 읽기 (재빌드 없음)

**Affected Code Locations**:
- `group_calendar_page.dart:68` - 캘린더 상태 읽기
- 필요 시 notifier 메서드 추가로 캡슐화 강화 (예: `getFilteredEvents()`)

**Alternatives Considered**:
1. **State를 public으로 변경**: Riverpod 설계 원칙 위반, 반응형 시스템 손상
2. **Getter 메서드 추가**: `notifier.getCurrentState()` - 불필요한 보일러플레이트
3. **Provider 재설계**: 과도한 리팩터링, 이번 작업 범위 초과

---

## Summary

### Research Outcomes

| 연구 항목 | 결정 사항 | 적용 범위 | 예상 효과 |
|---------|----------|---------|----------|
| R1: Dart Fix | `dart fix --apply` + 수동 검토 | 44 files | 자동화로 시간 절감, 일관성 향상 |
| R2: BuildContext Safety | `if (mounted)` 패턴 | 17 files | 런타임 크래시 방지, 안정성 향상 |
| R3: Web Migration | `dart:js_interop` + `package:web` | 1 file | 향후 Flutter SDK 호환성 보장 |
| R4: Riverpod Pattern | `ref.watch`/`ref.read` | 1 file | 캡슐화 유지, 반응형 상태 관리 |

### Risk Assessment

| 리스크 | 확률 | 영향도 | 완화 전략 |
|--------|------|--------|----------|
| dart fix가 일부 코드를 잘못 수정 | 중간 | 중간 | 수정 후 전체 테스트 실행 + 수동 검토 |
| Web migration 후 localStorage 오동작 | 낮음 | 높음 | 수동 테스트 + 다른 플랫폼 격리 확인 |
| Riverpod 패턴 변경 후 상태 관리 이슈 | 낮음 | 중간 | 캘린더 기능 E2E 테스트 |
| 대량 수정으로 Git 충돌 | 높음 | 낮음 | 우선순위별 분할 커밋 |

### Tools & Commands

**MCP Tools** (권장):
```bash
# 분석
mcp__dart-flutter__analyze_files

# 자동 수정
mcp__dart-flutter__dart_fix --roots '[{"root": "file:///path/to/frontend"}]'

# 테스트
mcp__dart-flutter__run_tests --roots '[{"root": "file:///path/to/frontend"}]'
```

**Bash Alternatives** (헌법 허용):
```bash
# 분석
cd frontend && flutter analyze

# 자동 수정
cd frontend && dart fix --apply

# 테스트
cd frontend && flutter test
```

### Next Steps

1. ✅ **Research Complete**: 모든 기술적 의사결정 완료
2. ⏭️ **Phase 1**: quickstart.md 생성 (단계별 실행 가이드)
3. ⏭️ **Phase 2**: `/speckit.tasks` 실행 (우선순위별 태스크 목록)
