# LoadingButton & SnackBar 리팩터링 분석 보고서

**작성일**: 2025-10-27
**목적**: Phase 3 컴포넌트 추출 - LoadingButton & SnackBarHelper 통합 전략 수립

---

## 📊 현재 상황 분석

### 1. 기존 버튼 컴포넌트 현황

#### ✅ 이미 구현된 재사용 컴포넌트 (4개)

1. **PrimaryButton** (`lib/presentation/widgets/buttons/primary_button.dart`, 168줄)
   - `isLoading` 지원 ✅
   - 2가지 variant (action, brand)
   - `_PrimaryButtonChild` 내부 위젯으로 로딩 처리
   - GoogleSignInButton 포함

2. **ErrorButton** (`lib/presentation/widgets/buttons/error_button.dart`, 72줄)
   - `isLoading` 지원 ✅
   - 위험한 액션 전용 (삭제, 로그아웃 등)

3. **NeutralOutlinedButton** (`lib/presentation/widgets/buttons/neutral_outlined_button.dart`, 71줄)
   - `isLoading` 지원 ✅
   - 중립적인 취소 액션 전용

4. **OutlinedLinkButton** (`lib/presentation/widgets/buttons/outlined_link_button.dart`, 160줄)
   - `isLoading` 지원 ✅
   - 2가지 variant (outlined, tonal)
   - `_OutlinedChild` 내부 위젯으로 로딩 처리
   - AdminLoginButton 포함

#### 🔧 공통 특징

- **모든 버튼이 `isLoading` 속성을 이미 지원**
- 로딩 상태에서는 CircularProgressIndicator 표시
- `onPressed`가 null이거나 `isLoading`이 true일 때 disabled 상태
- 일관된 스타일 적용 (`AppButtonStyles` 사용)

#### ⚠️ 문제점

1. **로딩 UI 로직 중복**: 각 버튼 컴포넌트가 독립적으로 로딩 UI 구현
2. **코드 중복**: `_PrimaryButtonChild`, `_OutlinedChild` 등 유사한 로직 반복
3. **일관성 부족**: CircularProgressIndicator 크기, 색상이 버튼마다 약간씩 다름
4. **확장성 부족**: 새로운 로딩 스타일 추가 시 모든 버튼 수정 필요

### 2. 원시 버튼 사용 패턴 (61개 파일, 222회 사용)

#### 직접 사용되는 Flutter 버튼
- **TextButton**: 주로 다이얼로그 액션에서 사용 (취소 버튼)
- **FilledButton**: 주요 액션, 확인 버튼
- **OutlinedButton**: 보조 액션
- **ElevatedButton**: 일부 레거시 코드에서 사용

#### 주요 사용처
- 다이얼로그 액션 바: `recruitment_management_page.dart` (8회)
- 폼 제출 버튼: 로딩 상태 직접 관리
- 네비게이션 버튼: 간단한 onClick 처리

#### 문제점
1. **로딩 상태 관리 산재**: `_isSubmitting`, `_isLoading` 등 로컬 상태 남발
2. **스타일 불일치**: 각 파일에서 `styleFrom()` 직접 호출
3. **접근성 부족**: semanticsLabel 누락
4. **유지보수 어려움**: 디자인 변경 시 61개 파일 수정 필요

### 3. SnackBar 사용 패턴 (42개 파일, 158회 사용)

#### 현재 구현 상태

**✅ AppSnackBar 헬퍼 있음**: `lib/core/utils/snack_bar_helper.dart`

```dart
// 이미 구현된 헬퍼
AppSnackBar.success(context, '성공 메시지');
AppSnackBar.error(context, '에러 메시지');
AppSnackBar.info(context, '정보 메시지');
```

#### 사용 패턴 분석
- **성공/에러/정보 메시지 표시**: 대부분의 사용 사례
- **액션 버튼 포함**: 일부에서 SnackBarAction 사용
- **다크모드 지원**: 이미 구현됨

#### 문제점
1. **일관성 부족**: 일부 파일은 `ScaffoldMessenger.of(context).showSnackBar()` 직접 호출
2. **스타일 중복**: 커스텀 SnackBar 생성 시 스타일 재정의
3. **메시지 위치 불일치**: 일부는 상단, 일부는 하단 표시

---

## 🎯 LoadingButton이 필요 없는 이유

### 현재 시스템 분석 결과

1. **이미 완벽한 로딩 지원**: 모든 재사용 버튼 컴포넌트가 `isLoading` 지원
2. **재사용 컴포넌트 우수**: PrimaryButton, ErrorButton 등이 이미 LoadingButton 역할 수행
3. **추가 추상화 불필요**: LoadingButton을 만들면 오히려 복잡도 증가

### 대안 전략

**✅ LoadingButton 생성 ❌**
**✅ 기존 버튼 컴포넌트 개선 ✅**

---

## 📋 Phase 3 리팩터링 전략

### 목표

1. **원시 버튼 사용 제거**: 61개 파일의 222회 사용을 재사용 컴포넌트로 전환
2. **SnackBar 일관성 확보**: 모든 파일에서 AppSnackBar 사용
3. **로딩 UI 표준화**: 버튼 내부 로딩 로직 공통 컴포넌트 추출

### Phase 3-A: 버튼 내부 로직 통합 (2-3시간)

#### 1. `_ButtonLoadingChild` 공통 컴포넌트 생성

**파일**: `lib/presentation/widgets/buttons/button_loading_child.dart`

```dart
/// 버튼 로딩 상태 처리 공통 컴포넌트
class ButtonLoadingChild extends StatelessWidget {
  final String text;
  final Widget? icon;
  final bool isLoading;
  final TextStyle textStyle;
  final Color indicatorColor;

  // isLoading이 true면 CircularProgressIndicator 표시
  // icon이 있으면 Row 레이아웃, 없으면 Text만 표시
}
```

**적용 대상**:
- PrimaryButton의 `_PrimaryButtonChild` 제거 → ButtonLoadingChild 사용
- OutlinedLinkButton의 `_OutlinedChild` 제거 → ButtonLoadingChild 사용
- ErrorButton의 `_buildChild()` → ButtonLoadingChild 사용
- NeutralOutlinedButton의 `_buildChild()` → ButtonLoadingChild 사용

**예상 효과**:
- **코드 절감**: ~80줄 (중복 로직 제거)
- **일관성 향상**: 모든 버튼의 로딩 UI 통일
- **확장성**: 로딩 애니메이션 변경 시 1곳만 수정

#### 2. 버튼 스타일 표준화

**기존**:
```dart
// ErrorButton
child: const SizedBox(
  width: 16,
  height: 16,
  child: CircularProgressIndicator(
    strokeWidth: 2,
    valueColor: AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
  ),
)

// PrimaryButton
child: SizedBox(
  width: AppComponents.progressIndicatorSize, // 다른 상수 사용
  height: AppComponents.progressIndicatorSize,
  child: CircularProgressIndicator(...),
)
```

**개선**:
```dart
// ButtonLoadingChild에서 통일
AppComponents.progressIndicatorSize 사용 (모든 버튼 동일)
strokeWidth: 2 (모든 버튼 동일)
```

### Phase 3-B: 원시 버튼 마이그레이션 (6-8시간)

#### 우선순위 1: 다이얼로그 액션 (20개 파일, ~60회 사용)

**대상**:
- `TextButton` → `NeutralOutlinedButton` (취소)
- `FilledButton` → `PrimaryButton` (확인)
- `ElevatedButton` → `PrimaryButton` (레거시)

**샘플 파일**:
- `recruitment_management_page.dart` (8회 사용)
- `join_request_section.dart` (4회 사용)
- `recruitment_application_section.dart` (4회 사용)

**변경 전**:
```dart
actions: [
  TextButton(
    onPressed: () => Navigator.pop(context),
    child: const Text('취소'),
  ),
  FilledButton(
    onPressed: () => Navigator.pop(context, true),
    style: FilledButton.styleFrom(backgroundColor: AppColors.brand),
    child: const Text('확인'),
  ),
]
```

**변경 후**:
```dart
actions: [
  NeutralOutlinedButton(
    text: '취소',
    onPressed: () => Navigator.pop(context),
    width: 100,
  ),
  PrimaryButton(
    text: '확인',
    onPressed: () => Navigator.pop(context, true),
    variant: PrimaryButtonVariant.brand,
  ),
]
```

#### 우선순위 2: 폼 제출 버튼 (15개 파일, ~30회 사용)

**대상**: 로딩 상태가 있는 폼 제출 버튼

**변경 전**:
```dart
bool _isSubmitting = false;

FilledButton(
  onPressed: _isSubmitting ? null : _handleSubmit,
  child: _isSubmitting
    ? const CircularProgressIndicator()
    : const Text('제출'),
)
```

**변경 후**:
```dart
PrimaryButton(
  text: '제출',
  onPressed: _handleSubmit,
  isLoading: _isSubmitting, // 로딩 상태 자동 처리
  variant: PrimaryButtonVariant.brand,
)
```

#### 우선순위 3: 네비게이션/기타 버튼 (26개 파일, ~130회 사용)

**대상**: 단순 onClick 처리

**변경 전**:
```dart
OutlinedButton(
  onPressed: onClose,
  style: OutlinedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
  ),
  child: const Text('닫기'),
)
```

**변경 후**:
```dart
OutlinedLinkButton(
  text: '닫기',
  onPressed: onClose,
  variant: ButtonVariant.outlined,
)
```

### Phase 3-C: SnackBar 통합 (1-2시간)

#### 1. 직접 호출 제거

**변경 전**:
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('성공했습니다'),
    backgroundColor: AppColors.success,
  ),
);
```

**변경 후**:
```dart
AppSnackBar.success(context, '성공했습니다');
```

#### 2. AppSnackBar 개선

**현재**: `lib/core/utils/snack_bar_helper.dart` 이미 구현됨

**개선 사항**:
- 액션 버튼 지원 추가 (선택적)
- 다크모드 대응 검증
- 위치 표준화 (모두 하단으로 통일)

---

## 📈 예상 효과

### 코드 절감

1. **ButtonLoadingChild 추출**: ~80줄 절감
2. **원시 버튼 마이그레이션**: ~1,200줄 절감 (222회 × 평균 5줄 스타일 제거)
3. **SnackBar 통합**: ~300줄 절감 (158회 × 평균 2줄 스타일 제거)

**총 예상 절감**: **~1,580줄**

### 유지보수성 향상

- **디자인 시스템 일관성**: 모든 버튼이 AppButtonStyles 사용
- **로딩 UI 통일**: 단일 컴포넌트에서 관리
- **스타일 변경 용이**: 1개 파일 수정으로 전체 적용
- **다크모드 지원 강화**: 자동 테마 적용

### 접근성 개선

- **semanticsLabel 표준화**: 모든 버튼에 접근성 지원
- **키보드 네비게이션**: Focus 관리 통일
- **스크린 리더 지원**: 일관된 레이블 제공

---

## 🗓️ 구현 계획

### Week 1: 내부 로직 통합 (2-3시간)

- [ ] ButtonLoadingChild 컴포넌트 생성
- [ ] PrimaryButton 리팩터링 (적용 + 테스트)
- [ ] ErrorButton 리팩터링
- [ ] NeutralOutlinedButton 리팩터링
- [ ] OutlinedLinkButton 리팩터링

### Week 2: 원시 버튼 마이그레이션 Phase 1 (3-4시간)

- [ ] 다이얼로그 액션 마이그레이션 (20개 파일)
  - recruitment_management_page.dart
  - join_request_section.dart
  - recruitment_application_section.dart
  - 기타 17개 파일

### Week 3: 원시 버튼 마이그레이션 Phase 2 (3-4시간)

- [ ] 폼 제출 버튼 마이그레이션 (15개 파일)
- [ ] 네비게이션 버튼 마이그레이션 (26개 파일)

### Week 4: SnackBar 통합 (1-2시간)

- [ ] AppSnackBar 개선 (액션 버튼 지원)
- [ ] 직접 호출 제거 (42개 파일)
- [ ] 일관성 검증

---

## 🎯 최종 목표

### LoadingButton을 만들지 않는 이유

1. **기존 컴포넌트로 충분**: PrimaryButton, ErrorButton 등이 이미 로딩 지원
2. **과도한 추상화 방지**: LoadingButton은 불필요한 레이어
3. **Toss 디자인 철학**: 단순함, 직관성 우선

### Phase 3의 진짜 목표

1. **원시 버튼 사용 제거**: 재사용 컴포넌트로 전환 (~1,200줄 절감)
2. **로딩 UI 표준화**: ButtonLoadingChild로 통일 (~80줄 절감)
3. **SnackBar 일관성**: AppSnackBar로 통합 (~300줄 절감)

---

## 📝 다음 단계

1. **ButtonLoadingChild 컴포넌트 구현** (우선순위 1)
2. **기존 버튼 4개 리팩터링** (우선순위 2)
3. **원시 버튼 마이그레이션 시작** (우선순위 3)
4. **SnackBar 통합** (우선순위 4)

---

## 🔍 참고 자료

- **기존 버튼 컴포넌트**:
  - `lib/presentation/widgets/buttons/primary_button.dart` (168줄)
  - `lib/presentation/widgets/buttons/error_button.dart` (72줄)
  - `lib/presentation/widgets/buttons/neutral_outlined_button.dart` (71줄)
  - `lib/presentation/widgets/buttons/outlined_link_button.dart` (160줄)

- **스타일 정의**:
  - `lib/core/theme/app_button_styles.dart` (391줄)

- **SnackBar 헬퍼**:
  - `lib/core/utils/snack_bar_helper.dart` (기존 구현됨)

- **원시 버튼 사용처**:
  - 61개 파일, 222회 사용
  - 주요: recruitment_management_page.dart, join_request_section.dart 등

---

**작성자**: Frontend Specialist Agent
**검토 필요**: context-manager에게 문서 업데이트 요청 예정
