# Implementation Plan: Flutter Code Quality & Analysis Issue Resolution

**Branch**: `003-flutter-analysis-fixes` | **Date**: 2025-11-13 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/003-flutter-analysis-fixes/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

프로젝트에서 `flutter analyze` 실행 시 발견된 76개의 Linting/Analysis 문제를 우선순위별로 해결합니다. Critical 컴파일 에러 (7개), BuildContext 안전성 경고 (17개), Deprecated API 사용 (44개), 그리고 Dead code/Documentation 문제 (8개)를 단계적으로 수정하여 코드 품질, 런타임 안정성, 그리고 향후 Flutter SDK 호환성을 보장합니다.

**Technical Approach**:
- P1 (Critical): 수동 수정 (AppSnackBar import, @JsonSerializable 위치, protected member 접근)
- P2 (BuildContext): `dart fix --apply` + 수동 mounted 체크 추가
- P3 (Deprecated APIs): `dart fix --apply` + Web platform 마이그레이션
- P4 (Cleanup): Dead code 제거 + 문서 수정

## Technical Context

**Language/Version**: Dart 3.x (Flutter SDK 3.x stable)
**Primary Dependencies**:
- flutter_riverpod (상태 관리)
- go_router (라우팅)
- json_annotation (JSON 직렬화)
- dart:js_interop (Web platform - 마이그레이션 대상)
- package:web (Web platform - 마이그레이션 목표)

**Storage**: N/A (코드 품질 수정, 데이터 모델 변경 없음)
**Testing**:
- Dart built-in test framework
- flutter_test (Widget 테스트)
- 기존 테스트 스위트 regression 검증 필수

**Target Platform**: Flutter Web (Chrome), iOS, Android (cross-platform 검증 필요)
**Project Type**: Mobile/Web (Flutter hybrid)
**Performance Goals**: 분석 시간 개선 (lint 에러 감소로 CI/CD 속도 향상)
**Constraints**:
- 모든 수정은 기존 테스트 스위트를 100% 통과해야 함
- Breaking change 없음 (기능 동작 유지)
- 우선순위별 점진적 배포 (P1 → P2 → P3 → P4)

**Scale/Scope**:
- 44개 파일 수정
- 76개 lint issue 해결
- 약 200줄 dead code 제거

## API Modifications

**N/A** - 이 작업은 코드 품질 개선 (linting, deprecated API 교체, dead code 제거)에 집중하며, REST API 엔드포인트나 백엔드 로직 변경은 포함하지 않습니다.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Principle I: 3-Layer Architecture (비협상)
**Status**: ✅ **PASS** - 이 작업은 프론트엔드 코드 품질 개선에 집중하며, 백엔드 아키텍처를 변경하지 않습니다.

### Principle II: 표준 응답 형식 (비협상)
**Status**: ✅ **PASS** - API 응답 형식 변경 없음. 프론트엔드 lint 수정만 수행합니다.

### Principle III: RBAC + Override 권한 시스템 (비협상)
**Status**: ✅ **PASS** - 권한 시스템 변경 없음. 다만 `group_calendar_page.dart`의 protected member 접근 수정 시 Riverpod 상태 관리 패턴을 올바르게 사용해야 합니다.

### Principle IV: 문서화 100줄 원칙
**Status**: ✅ **PASS** - Doc comment 수정 (HTML 이스케이핑, library directive 추가) 시 100줄 원칙을 준수합니다.

### Principle V: 테스트 피라미드 60/30/10
**Status**: ✅ **PASS** - 기존 테스트 스위트를 유지하며, 모든 수정 후 테스트가 100% 통과해야 합니다. 새로운 테스트 추가는 불필요합니다 (lint 수정이므로).

### Principle VI: MCP 사용 표준 (비협상)
**Status**: ✅ **PASS** - 이 작업은 MCP를 사용하여 lint 문제를 분석했으며, 향후 `dart fix --apply` 실행 시에도 MCP 도구를 우선 사용합니다.
- `mcp__dart-flutter__dart_fix` 사용 예정 (자동 수정)
- `mcp__dart-flutter__analyze_files` 사용 예정 (수정 후 검증)
- `mcp__dart-flutter__run_tests` 사용 예정 (regression 테스트)

### Principle VII: 프론트엔드 통합 원칙
**Status**: ✅ **PASS** - Flutter Web 및 모바일 플랫폼에서 코드 일관성을 유지하며, Web platform 특화 코드 (`dart:js` → `dart:js_interop`) 마이그레이션 시 다른 플랫폼 호환성을 검증합니다.

### Principle VIII: API 진화 및 리팩터링 원칙 (비협상)
**Status**: ✅ **PASS** - 이 작업은 API 변경이 아닌 코드 품질 개선이므로, 기존 API 호출 패턴을 유지합니다. 다만 BuildContext 안전성 수정 시 async 작업 후 `mounted` 체크를 추가하여 올바른 Flutter 패턴을 따릅니다.

**Overall Gate Result**: ✅ **PASS** - 모든 헌법 원칙을 준수합니다. Phase 0 연구를 진행할 수 있습니다.

## Project Structure

### Documentation (this feature)

```text
specs/003-flutter-analysis-fixes/
├── plan.md              # This file (Implementation plan)
├── research.md          # Phase 0: Dart fix patterns, BuildContext best practices
├── data-model.md        # N/A (no data model changes for lint fixes)
├── quickstart.md        # Phase 1: Fix execution guide
├── contracts/           # N/A (no API contracts for lint fixes)
├── checklists/
│   └── requirements.md  # Specification quality checklist (completed)
└── spec.md              # Feature specification (completed)
```

### Source Code (repository root)

```text
frontend/
├── lib/
│   ├── core/
│   │   ├── navigation/
│   │   │   └── navigation_state.dart        # [P1] @JsonSerializable 수정
│   │   └── utils/
│   │       └── place_availability_helper.dart  # [P4] HTML doc comment 수정
│   ├── features/
│   │   └── place_admin/
│   │       └── presentation/
│   │           └── widgets/
│   │               ├── available_times_widget.dart       # [P3] withOpacity → withValues
│   │               ├── place_closure_widgets.dart        # [P3] withOpacity → withValues
│   │               ├── place_operating_hours_editor.dart # [P3] withOpacity → withValues
│   │               └── restricted_time_widgets.dart      # [P4] unused field 제거
│   ├── presentation/
│   │   ├── adapters/
│   │   │   ├── group_event_adapter.dart          # [P4] unused element 제거
│   │   │   ├── personal_schedule_adapter.dart    # [P4] unused element 제거
│   │   │   └── place_reservation_adapter.dart    # [P4] unused element 제거
│   │   ├── pages/
│   │   │   ├── auth/
│   │   │   │   └── login_page.dart               # [P1] AppSnackBar import 수정
│   │   │   ├── calendar/
│   │   │   │   └── tabs/
│   │   │   │       └── timetable_tab.dart        # [P4] unused variable 제거
│   │   │   ├── demo_calendar/
│   │   │   │   └── demo_calendar_page.dart       # [P2] BuildContext 안전성
│   │   │   └── workspace/
│   │   │       ├── calendar/
│   │   │       │   ├── group_calendar_page.dart  # [P1] protected member + [P2] BuildContext
│   │   │       │   └── widgets/
│   │   │       │       ├── multi_place_calendar_view.dart  # [P2] BuildContext
│   │   │       │       └── place_picker_dialog.dart        # [P3] Radio + [P2] BuildContext
│   │   │       ├── place/
│   │   │       │   └── place_list_page.dart      # [P2] BuildContext
│   │   │       └── widgets/
│   │   │           └── group_home_view.dart      # [P3] withOpacity → withValues
│   │   ├── providers/
│   │   │   ├── workspace_state_provider_web.dart # [P3] dart:js → dart:js_interop + [P4] library directive
│   │   │   └── workspace_state_provider_stub.dart # [P4] library directive
│   │   └── widgets/
│   │       ├── buttons/
│   │       │   ├── calendar_add_button.dart      # [P3] withOpacity → withValues
│   │       │   └── primary_button.dart           # [P4] unreachable switch
│   │       ├── calendar/
│   │       │   └── color_generator.dart          # [P3] Color.red/green/blue → .r/.g/.b
│   │       ├── common/
│   │       │   └── app_empty_state.dart          # [P3] withOpacity → withValues
│   │       ├── navigation/
│   │       │   └── top_navigation.dart           # [P2] BuildContext
│   │       ├── post/
│   │       │   ├── post_list.dart                # [P4] unused variable
│   │       │   └── unread_message_divider.dart   # [P3] withOpacity → withValues
│   │       └── weekly_calendar/
│   │           ├── disabled_slots_painter.dart    # [P3] withOpacity → withValues
│   │           ├── event_create_dialog.dart       # [P3] Radio + Color.value → toARGB32
│   │           ├── event_painter.dart             # [P3] withOpacity → withValues
│   │           ├── fixed_duration_preview_painter.dart  # [P3] withOpacity → withValues
│   │           ├── highlight_painter.dart         # [P3] withOpacity → withValues
│   │           ├── selection_painter.dart         # [P3] withOpacity → withValues
│   │           └── weekly_schedule_editor.dart    # [P2] BuildContext + [P3] withOpacity
└── test/
    ├── design_system/
    │   └── contrast_validator_test.dart  # [P3] Color.red/green/blue → .r/.g/.b + Color.value → toARGB32
    └── presentation/
        └── widgets/
            └── navigation/
                └── keyboard_navigation_test.dart  # [P4] unused variable
```

**Structure Decision**: 이 프로젝트는 Flutter Web + Mobile 하이브리드 앱이므로, `frontend/` 디렉토리 아래에 모든 Dart 코드가 위치합니다. 수정 대상 파일은 44개이며, 우선순위 태그 ([P1], [P2], [P3], [P4])로 분류하여 단계적으로 수정합니다.

## Complexity Tracking

**N/A** - 이 작업은 Constitution Check에서 모든 원칙을 준수하며, 위반 사항이 없으므로 Complexity Tracking이 불필요합니다.

## Phase 0: Research & Best Practices

### Research Tasks

#### R1: Dart Fix Automation Patterns
**Question**: `dart fix --apply`가 자동으로 해결할 수 있는 lint 문제와 수동 개입이 필요한 문제를 구분하는 기준은?

**Research Goals**:
- Dart 3.x의 `dart fix` 명령어 기능 및 제약사항 파악
- 자동 수정 가능 항목: Color API (`withOpacity` → `withValues`), Radio deprecation
- 수동 수정 필요 항목: BuildContext 안전성, protected member 접근, import 누락

#### R2: BuildContext Safety Best Practices
**Question**: async 작업 후 BuildContext를 안전하게 사용하는 Flutter 표준 패턴은?

**Research Goals**:
- `mounted` 체크의 올바른 사용법 (StatefulWidget vs StatelessWidget)
- `context.mounted` vs `State.mounted` 차이점
- async gap에서 BuildContext를 안전하게 전달하는 패턴 (예: `if (mounted) { context.pop() }`)

#### R3: Web Platform Migration (dart:js → dart:js_interop)
**Question**: `dart:js`/`dart:html`을 `dart:js_interop`/`package:web`으로 마이그레이션하는 단계는?

**Research Goals**:
- `dart:js_interop` API 변경 사항 (JsObject, context 사용 패턴)
- `package:web` 마이그레이션 가이드 (window, document 접근)
- Web platform 전용 코드를 다른 플랫폼에서 안전하게 격리하는 방법

#### R4: Riverpod Protected Member Access
**Question**: StateNotifier의 `.state`를 외부에서 직접 접근하지 않고 Riverpod 패턴을 따르는 방법은?

**Research Goals**:
- `StateNotifierProvider`에서 상태를 올바르게 읽는 방법 (`ref.watch`, `ref.read`)
- `group_calendar_page.dart:68`의 문제 코드 분석 및 올바른 패턴 제안
- Riverpod 2.x의 권장 상태 관리 패턴

### Expected Outputs (research.md)

```markdown
# Research: Flutter Lint Fix Patterns & Best Practices

## R1: Dart Fix Automation

**Decision**: `dart fix --apply` 사용 + 수동 검토

**Rationale**:
- Dart 3.x의 `dart fix`는 deprecated API 교체 (withOpacity, Color accessors, Radio) 자동화 가능
- BuildContext 안전성은 자동 수정이 불가능하므로 수동으로 `mounted` 체크 추가 필요

**Alternatives Considered**:
- 전체 수동 수정: 시간 소요가 크고 휴먼 에러 위험
- IDE 자동 수정: IntelliJ/VSCode의 Quick Fix는 파일별로만 작동하여 대량 수정에 부적합

## R2: BuildContext Safety

**Decision**: `if (mounted) context.method()` 패턴 사용

**Rationale**:
- StatefulWidget에서 `mounted` getter는 위젯이 트리에 마운트되어 있는지 확인
- async 작업 후 항상 `mounted` 체크를 수행하여 BuildContext 접근 안전성 보장

**Pattern**:
```dart
// Before (경고 발생)
await someAsyncOperation();
Navigator.of(context).pop();  // ❌ BuildContext 안전하지 않음

// After (안전)
await someAsyncOperation();
if (mounted) {
  Navigator.of(context).pop();  // ✅ mounted 체크 후 사용
}
```

## R3: Web Platform Migration

**Decision**: `dart:js_interop` + `package:web` 마이그레이션

**Rationale**:
- Dart 3.0부터 `dart:js`/`dart:html`은 deprecated
- `dart:js_interop`는 타입 안전한 JS interop 제공
- `package:web`은 Web API를 Dart로 래핑하여 표준 인터페이스 제공

**Migration Steps**:
1. `import 'dart:js'` → `import 'dart:js_interop'`
2. `import 'dart:html'` → `import 'package:web'`
3. `JsObject`, `context` 사용 패턴을 `@JS()` annotation + extension types로 전환
4. `window.localStorage` → `window.localStorage` (package:web의 window)

## R4: Riverpod Protected Member

**Decision**: `ref.watch`/`ref.read`로 상태 접근

**Rationale**:
- `StateNotifier.state`는 protected member이므로 외부에서 직접 접근 금지
- Riverpod의 `StateNotifierProvider`는 `ref.watch(provider)` 또는 `ref.read(provider.notifier).method()`로 접근

**Pattern**:
```dart
// Before (에러 발생)
final notifier = ref.read(myProvider.notifier);
final currentState = notifier.state;  // ❌ protected member 접근

// After (올바른 패턴)
final currentState = ref.watch(myProvider);  // ✅ ref.watch로 상태 읽기
ref.read(myProvider.notifier).updateState();  // ✅ notifier 메서드 호출
```
```

## Phase 1: Design & Contracts

### Data Model

**N/A** - 이 작업은 코드 품질 개선이므로 데이터 모델 변경이 없습니다.

### API Contracts

**N/A** - API 엔드포인트 변경이 없으므로 contracts 디렉토리가 필요하지 않습니다.

### Quickstart Guide

**Objective**: 개발자가 lint 수정 작업을 단계적으로 실행할 수 있는 가이드 제공

**Contents** (quickstart.md):
```markdown
# Quickstart: Flutter Lint Fix Execution

## Prerequisites

- Flutter SDK 3.x stable
- Dart 3.x
- Git branch: `003-flutter-analysis-fixes`
- MCP dart-flutter tools available

## Phase 1: Critical Fixes (P1)

### 1.1 AppSnackBar Import Fix
```bash
# 파일: frontend/lib/presentation/pages/auth/login_page.dart
# 문제: AppSnackBar import 누락
# 해결: import 추가 또는 대체 스낵바 사용
```

### 1.2 @JsonSerializable Fix
```bash
# 파일: frontend/lib/core/navigation/navigation_state.dart:9
# 문제: @JsonSerializable이 클래스가 아닌 곳에 적용됨
# 해결: annotation을 클래스로 이동
```

### 1.3 Protected Member Fix
```bash
# 파일: frontend/lib/presentation/pages/workspace/calendar/group_calendar_page.dart:68
# 문제: StateNotifier.state 직접 접근
# 해결: ref.watch(provider) 사용
```

### 검증
```bash
# MCP 사용 (권장)
mcp__dart-flutter__analyze_files

# 또는 Bash (헌법 허용)
flutter analyze | grep "Severity 1"  # 0개 확인
```

## Phase 2: BuildContext Safety (P2)

### 2.1 Automated Fix Attempt
```bash
# MCP 사용 (권장)
mcp__dart-flutter__dart_fix --roots '[{"root": "file:///path/to/frontend"}]'
```

### 2.2 Manual mounted Checks
17개 파일에 `if (mounted)` 추가:
- group_calendar_page.dart (9개)
- multi_place_calendar_view.dart (3개)
- place_picker_dialog.dart (1개)
- place_list_page.dart (1개)
- top_navigation.dart (1개)
- weekly_schedule_editor.dart (4개)
- demo_calendar_page.dart (1개)

### 검증
```bash
flutter analyze | grep "use_build_context_synchronously"  # 0개 확인
```

## Phase 3: Deprecated API Migration (P3)

### 3.1 Color API Automated Fix
```bash
# MCP 사용 (권장)
mcp__dart-flutter__dart_fix --roots '[{"root": "file:///path/to/frontend"}]'

# 자동 수정 항목:
# - withOpacity() → withValues()
# - .red/.green/.blue → .r/.g/.b
# - .value → toARGB32()
```

### 3.2 Web Platform Migration
```bash
# 파일: frontend/lib/presentation/providers/workspace_state_provider_web.dart
# 1. import 'dart:js' → import 'dart:js_interop'
# 2. import 'dart:html' → import 'package:web'
# 3. JsObject 패턴을 @JS() annotation으로 전환
```

### 3.3 Radio Group Migration
4개 파일에 RadioGroup 적용:
- place_picker_dialog.dart
- event_create_dialog.dart (3개 라디오)

### 검증
```bash
flutter analyze | grep "deprecated_member_use"  # 0개 확인
```

## Phase 4: Code Cleanup (P4)

### 4.1 Remove Unused Code
```bash
# 8개 파일에서 unused elements 제거
# - _slotToTime (3개 파일)
# - _calculateDurationSlots (1개)
# - _handleScheduleTap (1개)
# - _dayLabels (1개)
# - selectedIndex (1개)
# - post variable (1개)
```

### 4.2 Fix Documentation
```bash
# HTML in doc comments: place_availability_helper.dart:287-288
# Library directives: workspace_state_provider_*.dart
```

### 검증
```bash
flutter analyze  # 0 issues 확인
```

## Final Verification

### Run All Tests
```bash
# MCP 사용 (권장)
mcp__dart-flutter__run_tests --roots '[{"root": "file:///path/to/frontend"}]'

# 또는 Bash (헌법 허용)
flutter test
```

### Cross-Platform Check
```bash
# Web
flutter run -d chrome --web-hostname localhost --web-port 5173

# Android (if available)
flutter run -d android

# iOS (if available)
flutter run -d ios
```

### Success Criteria
- ✅ flutter analyze: 0 issues (76→0)
- ✅ flutter test: 100% pass
- ✅ 앱이 모든 플랫폼에서 정상 실행
```

### Agent Context Update

**Execution**:
```bash
.specify/scripts/bash/update-agent-context.sh claude
```

**Expected Updates**:
- Add "Flutter lint fixes" to Active Technologies
- Add "Dart 3.x fix patterns, BuildContext safety" to Recent Changes
- Preserve manual additions between markers

## Post-Design Constitution Re-Check

*Re-evaluate after Phase 1 design completion*

### Principle VI: MCP 사용 표준 (비협상)
**Status**: ✅ **PASS** - quickstart.md에 MCP 도구 사용을 우선 명시했습니다:
- `mcp__dart-flutter__dart_fix` (자동 수정)
- `mcp__dart-flutter__analyze_files` (검증)
- `mcp__dart-flutter__run_tests` (테스트)

Bash 대안도 제공하지만, MCP를 권장 방법으로 표시했습니다.

**Overall Re-Check Result**: ✅ **PASS** - 모든 헌법 원칙을 준수하며, Phase 2 (tasks.md 생성)로 진행할 준비가 완료되었습니다.

## Next Steps

1. ✅ **Phase 0 Complete**: research.md 생성 (Dart fix patterns, BuildContext safety, Web migration, Riverpod patterns)
2. ✅ **Phase 1 Complete**: quickstart.md 생성 (단계별 실행 가이드)
3. ⏭️ **Phase 2**: `/speckit.tasks` 명령으로 tasks.md 생성 (이 plan.md는 여기서 종료)

**Ready for**: `/speckit.tasks` - 우선순위별 실행 가능한 태스크 목록 생성
