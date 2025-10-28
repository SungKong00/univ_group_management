# Phase 3-D: 네비게이션/기타 원시 버튼 제거 - 진행 현황

## 📊 작업 개요

**목표**: 네비게이션 및 기타 부분에서 사용되는 원시 버튼을 재사용 컴포넌트로 마이그레이션
- **예상 대상**: 26개 파일, 약 130회 사용
- **예상 절감**: 300-500줄

## ✅ 완료된 작업 (Phase 3-D 1차)

### 1. 고빈도 파일 마이그레이션 (46개 버튼)

#### 1.1 calendar_page.dart (16개 버튼 → 완료)
**위치**: `frontend/lib/presentation/pages/calendar/calendar_page.dart`

**변경 내역**:
- ✅ TextButton → NeutralOutlinedButton (5회)
- ✅ FilledButton → PrimaryButton (action variant, 3회)
- ✅ FilledButton (error) → ErrorButton (2회)
- ✅ OutlinedButton.icon → OutlinedLinkButton (1회)

**절감 라인 수**: ~50줄 (스타일 정의 제거)

#### 1.2 recruitment_application_section.dart (10개 버튼 → 완료)
**위치**: `frontend/lib/presentation/pages/member_management/widgets/recruitment_application_section.dart`

**변경 내역**:
- ✅ OutlinedButton.icon (error) → ErrorButton (2회)
- ✅ ElevatedButton.icon (brand) → PrimaryButton (2회)
- ✅ TextButton → NeutralOutlinedButton (2회)
- ✅ ElevatedButton (brand) → PrimaryButton (2회)
- ✅ TextButton (error) → ErrorButton (2회)

**절감 라인 수**: ~40줄

#### 1.3 join_request_section.dart (10개 버튼 → 완료)
**위치**: `frontend/lib/presentation/pages/member_management/widgets/join_request_section.dart`

**변경 내역**: recruitment_application_section.dart와 동일 패턴
- ✅ OutlinedButton.icon (error) → ErrorButton (2회)
- ✅ ElevatedButton.icon (brand) → PrimaryButton (2회)
- ✅ TextButton → NeutralOutlinedButton (2회)
- ✅ ElevatedButton (brand) → PrimaryButton (2회)
- ✅ TextButton (error) → ErrorButton (2회)

**절감 라인 수**: ~40줄

#### 1.4 subgroup_request_section.dart (10개 버튼 → 완료)
**위치**: `frontend/lib/presentation/pages/group/widgets/subgroup_request_section.dart`

**변경 내역**: 동일 패턴
- ✅ OutlinedButton.icon (error) → ErrorButton (2회)
- ✅ ElevatedButton.icon (brand) → PrimaryButton (2회)
- ✅ TextButton → NeutralOutlinedButton (2회)
- ✅ ElevatedButton (brand) → PrimaryButton (2회)
- ✅ TextButton (error) → ErrorButton (2회)

**절감 라인 수**: ~40줄

### 📈 1차 완료 통계
- **마이그레이션 완료**: 4개 파일
- **버튼 변환**: 46개
- **코드 절감**: ~170줄
- **검증**: flutter analyze 통과 ✅

## 🔄 마이그레이션 패턴

### Pattern 1: 다이얼로그 확인/취소 버튼
```dart
// 변경 전
TextButton(
  onPressed: () => Navigator.pop(context, false),
  child: const Text('취소'),
)

// 변경 후
NeutralOutlinedButton(
  text: '취소',
  onPressed: () => Navigator.pop(context, false),
)
```

### Pattern 2: 승인/확인 버튼 (Brand)
```dart
// 변경 전
ElevatedButton(
  onPressed: () => _handleApprove(),
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.brand,
    foregroundColor: Colors.white,
  ),
  child: const Text('승인'),
)

// 변경 후
PrimaryButton(
  text: '승인',
  onPressed: () => _handleApprove(),
  variant: PrimaryButtonVariant.brand,
)
```

### Pattern 3: 삭제/거절 버튼 (Error)
```dart
// 변경 전
TextButton(
  onPressed: () => Navigator.pop(context, true),
  style: TextButton.styleFrom(foregroundColor: AppColors.error),
  child: const Text('거절'),
)

// 변경 후
ErrorButton(
  text: '거절',
  onPressed: () => Navigator.pop(context, true),
)
```

### Pattern 4: 아이콘 버튼 (Outlined)
```dart
// 변경 전
OutlinedButton.icon(
  style: OutlinedButton.styleFrom(
    minimumSize: const Size(0, AppComponents.buttonHeight),
  ),
  onPressed: () => _action(),
  icon: const Icon(Icons.school_outlined),
  label: const Text('수업 추가'),
)

// 변경 후
OutlinedLinkButton(
  text: '수업 추가',
  onPressed: () => _action(),
  icon: Icons.school_outlined,
  variant: ButtonVariant.outlined,
)
```

### Pattern 5: 액션 버튼 (Action Variant)
```dart
// 변경 전
FilledButton.icon(
  style: FilledButton.styleFrom(
    backgroundColor: colorScheme.primary,
  ),
  onPressed: () => _action(),
  icon: const Icon(Icons.add_circle_outline),
  label: const Text('개인 일정 추가'),
)

// 변경 후
PrimaryButton(
  text: '개인 일정 추가',
  onPressed: () => _action(),
  icon: Icons.add_circle_outline,
  variant: PrimaryButtonVariant.action,
)
```

## 📋 다음 단계 (Phase 3-D 2차)

### 우선순위 1: 중빈도 파일 (9개 버튼씩, 2개 파일)
1. ⏳ `place_usage_management_tab.dart` (9개 버튼)
2. ⏳ `group_calendar_page.dart` (9개 버튼)

### 우선순위 2: 중간 빈도 파일 (5-8개 버튼, 5개 파일)
3. ⏳ `member_filter_panel.dart` (8개 버튼)
4. ⏳ `member_edit_page.dart` (7개 버튼)
5. ⏳ `weekly_schedule_editor.dart` (7개 버튼)
6. ⏳ `workspace_state_view.dart` (6개 버튼)
7. ⏳ `role_management_section.dart` (5개 버튼)

### 우선순위 3: 저빈도 파일 (2-4개 버튼, ~15개 파일)
8-22. ⏳ 나머지 파일들 (각 2-4개 버튼)

## 🎯 예상 최종 결과

### Phase 3-D 완료 시:
- **총 파일 수**: ~26개
- **총 버튼 변환**: ~130개
- **예상 코드 절감**: 400-500줄
- **누적 절감 (Phase 1-3D)**: ~650-750줄

### 전체 효과:
1. **코드 일관성**: 모든 버튼이 디자인 시스템 준수
2. **유지보수성**: 중앙화된 스타일 관리
3. **재사용성**: 표준 컴포넌트 사용
4. **가독성**: 스타일 코드 제거로 로직 명확화

## 🔍 검증 결과

```bash
cd frontend && flutter analyze --no-pub
```

**결과**: ✅ 마이그레이션된 파일에서 에러 없음
- 기존 info/warning은 마이그레이션과 무관
- 모든 버튼 컴포넌트 정상 동작

## 📝 작업 가이드

### 다음 파일 마이그레이션 시 체크리스트:
1. ☑️ 파일 읽기 및 버튼 패턴 분석
2. ☑️ 버튼 컴포넌트 import 추가
3. ☑️ 각 버튼을 패턴에 맞게 마이그레이션:
   - TextButton → NeutralOutlinedButton
   - FilledButton (brand) → PrimaryButton (brand variant)
   - FilledButton (action) → PrimaryButton (action variant)
   - OutlinedButton → OutlinedLinkButton 또는 NeutralOutlinedButton
   - Error 색상 버튼 → ErrorButton
4. ☑️ 스타일 정의 코드 완전 제거
5. ☑️ 검증: `grep -n "FilledButton\|ElevatedButton\|OutlinedButton\|TextButton" <file> | grep -v "import"`

## 💡 베스트 프랙티스

### 1. 컴포넌트 선택 기준
- **PrimaryButton**: 주요 액션 (저장, 확인, 승인)
  - `variant: PrimaryButtonVariant.brand` - 브랜드 컬러 (보라색)
  - `variant: PrimaryButtonVariant.action` - 액션 컬러 (파란색)
- **ErrorButton**: 위험한 액션 (삭제, 거절, 취소)
- **NeutralOutlinedButton**: 보조 액션 (취소, 닫기, 뒤로)
- **OutlinedLinkButton**: 탐색 액션 (더보기, 이동)
  - `variant: ButtonVariant.outlined` - outlined 스타일
  - `variant: ButtonVariant.tonal` - tonal 스타일

### 2. 아이콘 처리
```dart
// 변경 전: Icon 위젯 사용
icon: const Icon(Icons.add, size: 18),

// 변경 후: IconData만 전달
icon: Icons.add,
```

### 3. 로딩 상태
```dart
// isLoading 매개변수 활용 (PrimaryButton에서 자동 처리)
PrimaryButton(
  text: '저장',
  onPressed: isSaving ? null : () => _save(),
  isLoading: isSaving,
)
```

## 🚀 다음 액션

1. **우선순위 1 파일 마이그레이션** (place_usage_management_tab.dart, group_calendar_page.dart)
2. **우선순위 2 파일 마이그레이션** (member_filter_panel.dart 등 5개)
3. **우선순위 3 파일 일괄 마이그레이션** (~15개 파일)
4. **최종 검증 및 통계 업데이트**
5. **Phase 3-D 완료 커밋**

---

**작성일**: 2025-10-27
**상태**: Phase 3-D 1차 완료 (4/26 파일, 46/130 버튼)
