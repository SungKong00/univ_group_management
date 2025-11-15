# Feature Specification: Flutter Code Quality & Analysis Issue Resolution

**Feature Branch**: `003-flutter-analysis-fixes`
**Created**: 2025-11-13
**Status**: Draft
**Input**: User description: "MCP로 플러터 확인 시 발견된 76개 Linting/Analysis 문제 파악 및 수정"

## User Scenarios & Testing

### User Story 1 - Critical Compilation Errors Fixed (Priority: P1)

개발자가 프로젝트를 빌드하거나 실행할 때, 컴파일 에러로 인한 실패 없이 정상적으로 앱이 실행되어야 합니다. 현재 `AppSnackBar` 누락, `@JsonSerializable` 오용, protected member 접근 등 7개의 Critical 에러가 프로젝트 안정성을 위협하고 있습니다.

**Why this priority**: 컴파일 에러는 앱 실행 자체를 막기 때문에 모든 기능 개발과 테스트를 차단합니다. 이는 즉시 해결되어야 할 최우선 과제입니다.

**Independent Test**:
1. `flutter analyze` 실행 시 Severity 1 (Critical) 에러가 0개
2. `flutter run` 실행 시 컴파일 에러 없이 앱이 정상 실행됨
3. 로그인 페이지에서 에러 스낵바가 정상적으로 표시됨

**Acceptance Scenarios**:

1. **Given** 개발자가 프로젝트를 체크아웃했을 때, **When** `flutter analyze` 실행, **Then** Severity 1 에러가 0개로 보고됨
2. **Given** `AppSnackBar` import가 수정되었을 때, **When** 로그인 페이지에서 에러 발생, **Then** 스낵바가 정상 표시됨
3. **Given** `@JsonSerializable` 위치가 수정되었을 때, **When** 네비게이션 상태 직렬화 수행, **Then** JSON 변환이 정상 작동함
4. **Given** Protected member 접근이 수정되었을 때, **When** 그룹 캘린더 페이지 진입, **Then** StateNotifier 에러가 발생하지 않음

---

### User Story 2 - Async Safety & BuildContext Protection (Priority: P2)

개발자가 async 작업 (API 호출, 네비게이션 등)을 수행할 때, BuildContext 관련 런타임 에러가 발생하지 않아야 합니다. 현재 17개의 `use_build_context_synchronously` 경고가 잠재적 런타임 크래시 위험을 나타냅니다.

**Why this priority**: BuildContext 오용은 위젯이 언마운트된 후 접근하여 런타임 크래시를 유발할 수 있습니다. 사용자 경험에 직접적인 영향을 주므로 높은 우선순위입니다.

**Independent Test**:
1. `flutter analyze` 실행 시 `use_build_context_synchronously` 경고 0개
2. 캘린더 페이지에서 이벤트 생성/삭제 시 크래시 없음
3. 장소 예약 화면에서 빠른 뒤로가기 시 에러 없음

**Acceptance Scenarios**:

1. **Given** 캘린더 페이지가 로드되었을 때, **When** async 이벤트 생성 중 사용자가 뒤로가기, **Then** BuildContext 에러 없이 안전하게 종료됨
2. **Given** 장소 선택 다이얼로그가 열렸을 때, **When** API 호출 중 다이얼로그 닫기, **Then** 'mounted' 체크로 안전하게 처리됨
3. **Given** 주간 일정 편집기에서 저장 중일 때, **When** 사용자가 빠르게 네비게이션, **Then** BuildContext 관련 에러가 발생하지 않음
4. **Given** 모든 async 작업에 mounted 체크가 추가되었을 때, **When** `flutter analyze` 실행, **Then** BuildContext 경고가 0개로 보고됨

---

### User Story 3 - Deprecated API Migration (Priority: P3)

개발자가 프로젝트를 최신 Flutter SDK로 유지할 때, deprecated API 경고 없이 모던한 API를 사용해야 합니다. 현재 44개의 deprecated API 사용이 향후 Flutter 버전 업그레이드 시 호환성 문제를 야기할 수 있습니다.

**Why this priority**: Deprecated API는 당장 앱 실행을 막지는 않지만, 향후 Flutter SDK 업그레이드 시 breaking change가 될 수 있습니다. 프로젝트 유지보수성을 위해 중요합니다.

**Independent Test**:
1. `flutter analyze` 실행 시 `deprecated_member_use` 경고 0개
2. Color 관련 코드에서 `.withValues()` 사용 확인
3. Web platform 코드에서 `dart:js_interop` 사용 확인

**Acceptance Scenarios**:

1. **Given** Color opacity 설정이 필요할 때, **When** `.withOpacity()` 대신 `.withValues()` 사용, **Then** 정밀도 손실 경고가 사라짐
2. **Given** Color 컴포넌트 추출이 필요할 때, **When** `.red/.green/.blue` 대신 `.r/.g/.b` 사용, **Then** deprecated 경고가 사라짐
3. **Given** Radio 그룹 구현이 필요할 때, **When** `RadioGroup` 위젯 사용, **Then** `groupValue`/`onChanged` deprecated 경고가 사라짐
4. **Given** Web platform 코드에서 JS interop이 필요할 때, **When** `dart:js_interop` 마이그레이션, **Then** `dart:js` deprecated 경고가 사라짐

---

### User Story 4 - Code Cleanup & Best Practices (Priority: P4)

개발자가 코드베이스를 유지보수할 때, 사용하지 않는 코드나 문서화 문제로 인한 혼란이 없어야 합니다. 현재 8개의 unused code 및 문서 관련 경고가 코드 가독성을 저해합니다.

**Why this priority**: Dead code와 문서 문제는 기능적 영향은 없지만, 코드 가독성과 유지보수성에 영향을 줍니다. 낮은 우선순위이지만 장기적으로 개선이 필요합니다.

**Independent Test**:
1. `flutter analyze` 실행 시 `unused_element`/`unused_local_variable`/`unused_field` 경고 0개
2. Doc comment에서 HTML 이스케이핑 확인
3. Library directive 누락 문제 해결 확인

**Acceptance Scenarios**:

1. **Given** 사용하지 않는 함수가 존재할 때, **When** 해당 함수 제거 또는 사용처 추가, **Then** `unused_element` 경고가 사라짐
2. **Given** 선언만 하고 사용하지 않는 변수가 있을 때, **When** 변수 제거 또는 실제 사용, **Then** `unused_local_variable` 경고가 사라짐
3. **Given** Doc comment에 `<>` 기호가 있을 때, **When** backticks으로 감싸거나 HTML entity 사용, **Then** `unintended_html_in_doc_comment` 경고가 사라짐
4. **Given** Library doc comment가 있지만 `library` directive가 없을 때, **When** `library` directive 추가, **Then** `dangling_library_doc_comments` 경고가 사라짐

---

### Edge Cases

- **대량 파일 수정 시 Git 충돌**: 44개 파일을 동시에 수정하면 다른 개발자의 작업과 충돌 가능성이 있습니다. 우선순위별로 나누어 커밋하여 리스크를 분산합니다.
- **자동 수정 도구의 한계**: `dart fix --apply`가 모든 문제를 자동으로 해결하지 못할 수 있습니다. 특히 BuildContext 문제는 수동 분석이 필요합니다.
- **Web platform 특수 케이스**: `dart:js_interop` 마이그레이션은 Web platform에만 영향을 주므로, 다른 플랫폼 (Android/iOS)에서 테스트가 필요합니다.
- **Radio 그룹 리팩터링**: `RadioGroup` 위젯으로 전환 시 기존 상태 관리 로직을 변경해야 할 수 있습니다. UI 테스트로 동작 확인이 필요합니다.
- **Protected member 접근 수정**: StateNotifier의 `.state` 접근을 Riverpod의 올바른 패턴으로 변경 시 상태 관리 로직을 재설계해야 할 수 있습니다.

## Requirements

### Functional Requirements

- **FR-001**: 시스템은 `flutter analyze` 실행 시 Severity 1 (Critical) 에러 0개를 보장해야 함
- **FR-002**: 시스템은 `AppSnackBar` 컴포넌트를 로그인 페이지에서 정상적으로 import하고 사용해야 함
- **FR-003**: 시스템은 `@JsonSerializable` annotation을 클래스에만 적용해야 함
- **FR-004**: 시스템은 StateNotifier의 protected member인 `.state`를 외부에서 직접 접근하지 않아야 함
- **FR-005**: 시스템은 모든 async 작업 후 BuildContext 사용 시 `mounted` 체크를 수행해야 함
- **FR-006**: 시스템은 Color API에서 `.withOpacity()` 대신 `.withValues()`를 사용해야 함
- **FR-007**: 시스템은 Color 컴포넌트 추출 시 `.red/.green/.blue` 대신 `.r/.g/.b`를 사용해야 함
- **FR-008**: 시스템은 Web platform에서 `dart:js`/`dart:html` 대신 `dart:js_interop`/`package:web`을 사용해야 함
- **FR-009**: 시스템은 Radio 그룹 구현 시 `RadioGroup` 위젯을 사용해야 함
- **FR-010**: 시스템은 사용하지 않는 함수, 변수, 필드를 제거해야 함
- **FR-011**: 시스템은 Doc comment에서 HTML 특수문자를 적절히 이스케이핑해야 함
- **FR-012**: 시스템은 Library doc comment가 있는 파일에 `library` directive를 포함해야 함

### Key Entities

- **Lint Issue**: 분석 도구가 보고하는 코드 품질 문제
  - 속성: severity (1: Critical, 2: High, 3: Medium), code (에러 코드), message (설명), file path, line number
  - 관계: 하나의 파일에 여러 Lint Issue가 존재할 수 있음

- **Fix Strategy**: 각 Issue 유형에 대한 수정 전략
  - 속성: issue_code (연관된 lint code), fix_type (manual/automatic), priority (P1-P4), estimated_impact (high/medium/low)
  - 관계: 하나의 Fix Strategy가 여러 Lint Issue에 적용될 수 있음

- **File Modification**: 수정이 필요한 파일 정보
  - 속성: file_path, issue_count, affected_lines, modification_type (critical/refactor/cleanup)
  - 관계: 하나의 파일에 여러 Lint Issue가 연결되며, 각 Issue는 특정 Fix Strategy를 가짐

## Success Criteria

### Measurable Outcomes

- **SC-001**: `flutter analyze` 실행 시 Severity 1 에러가 7개 → 0개로 감소함
- **SC-002**: `flutter analyze` 실행 시 총 Lint 경고/에러가 76개 → 0개로 감소함
- **SC-003**: 모든 수정 후 기존 테스트 스위트가 100% 통과함 (regression 없음)
- **SC-004**: BuildContext 관련 경고가 17개 → 0개로 감소하여 런타임 안정성이 향상됨
- **SC-005**: Deprecated API 사용이 44개 → 0개로 감소하여 향후 Flutter SDK 호환성이 보장됨
- **SC-006**: Dead code (unused elements) 제거로 코드베이스 크기가 약 200줄 감소함
- **SC-007**: 모든 수정 사항이 우선순위별로 구분되어 점진적 배포가 가능함 (P1 → P2 → P3 → P4)
- **SC-008**: 수정 후 앱이 Web, Android, iOS 모든 플랫폼에서 정상 실행됨

### Assumptions

- Flutter SDK 버전은 3.x 이상이며, 최신 stable 버전을 사용한다고 가정합니다.
- 프로젝트는 이미 Navigator 2.0 및 Riverpod 상태 관리를 사용하고 있습니다.
- `dart fix --apply` 도구가 사용 가능하며, 자동 수정을 부분적으로 활용할 수 있습니다.
- 기존 테스트 스위트가 존재하며, 수정 후 regression 테스트가 가능합니다.
- Web platform 코드는 Chrome 브라우저를 주요 타겟으로 합니다.
- 개발팀은 Git을 사용하며, 우선순위별로 나누어 PR을 생성할 수 있습니다.

### Dependencies

- **Flutter SDK**: 최신 stable 버전 (3.x+)
- **Dart Analysis Server**: flutter analyze 명령어
- **Riverpod**: 상태 관리 (protected member 접근 수정 시 필요)
- **dart:js_interop & package:web**: Web platform 마이그레이션
- **Git**: 버전 관리 및 우선순위별 커밋 분리
