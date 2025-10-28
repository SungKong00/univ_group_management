# 저장방식 선택 페이지 UI 개선

**날짜**: 2025-10-27
**대상 파일**: `frontend/lib/presentation/pages/member_management/selection_method_page.dart`

## 변경 사항

### 1. 레이아웃 개선: 반응형 좌우 배치

**변경 전**: 카드가 세로로 배치 (Column)
```dart
Column(
  children: [
    _buildDynamicCard(...),
    SizedBox(height: AppSpacing.md),
    _buildStaticCard(...),
  ],
)
```

**변경 후**: 화면 너비에 따라 반응형 레이아웃
```dart
final isWide = size.width > 450;

if (isWide)
  IntrinsicHeight(
    child: Row(
      children: [
        Expanded(child: _buildDynamicCard(...)),
        SizedBox(width: AppSpacing.md),
        Expanded(child: _buildStaticCard(...)),
      ],
    ),
  )
else
  Column(
    children: [
      _buildDynamicCard(...),
      SizedBox(height: AppSpacing.md),
      _buildStaticCard(...),
    ],
  )
```

**효과**:
- 모바일 (≤450px): 세로 배치 유지 (공간 효율)
- 태블릿/데스크톱 (>450px): 좌우 배치로 비교 용이
- `IntrinsicHeight`로 두 카드 높이 동일하게 유지

### 2. 문구 개선: Toss 디자인 원칙 적용

#### DYNAMIC 카드 (자동 업데이트)

**변경 전**:
- 타이틀: "조건으로 저장 (DYNAMIC)"
- 설명: 없음
- 혜택:
  - 신규 멤버 자동 포함
  - 조건 변경 시 자동 업데이트
  - 실시간 동기화

**변경 후**:
- **타이틀**: "자동 업데이트"
- **설명**: "조건에 맞는 멤버 자동 관리"
- **혜택**:
  - 신규 멤버 자동 포함
  - 조건 변경 시 즉시 반영

**개선 포인트**:
- ✅ **Simplicity First**: "DYNAMIC" 기술 용어 제거
- ✅ **Value First**: "자동 업데이트"라는 가치를 먼저 제시
- ✅ **Easy to Answer**: 사용자가 얻는 이점이 명확
- ✅ **Title + Description**: 2단계 구조로 위계와 친근함 동시 제공
- ✅ 혜택 3개 → 2개로 축약 (중복 제거)
- ✅ 배경색 추가로 시각적 강조 (success 색상의 0.1 투명도)

#### STATIC 카드 (직접 선택)

**변경 전**:
- 타이틀: "명단으로 저장 (STATIC)"
- 설명: 없음
- 혜택:
  - ⚠ 고정 명단 (수동 관리)
  - → 다음 단계에서 편집 가능
  - ℹ 특정 인원만 선택 시 유용

**변경 후**:
- **타이틀**: "직접 선택"
- **설명**: "명단을 직접 편집하고 관리"
- **혜택**:
  - 다음 단계에서 직접 편집
  - 특정 인원만 선택 가능

**개선 포인트**:
- ✅ **Simplicity First**: "STATIC" 기술 용어 제거
- ✅ **Value First**: "직접 선택"이라는 행동 중심 표현
- ✅ **Easy to Answer**: 부정적 느낌 제거 (⚠ 고정 명단 → 직접 편집)
- ✅ **Title + Description**: 2단계 구조로 설명 명확화
- ✅ 혜택 아이콘 변경: 경고/화살표/정보 → 편집/사람 제거 아이콘 (직관적)
- ✅ 배경색 추가로 시각적 강조 (brand 색상의 0.05 투명도)

### 3. 시각적 개선

1. **타이포그래피 강화**:
   - 인원수 표시: `bodyLarge` → `headlineSmall` (더 강조)
   - 타이틀: `fontWeight: w600` 명시적 적용

2. **배경색 추가**:
   - DYNAMIC: `AppColors.success.withValues(alpha: 0.1)` (녹색 계열)
   - STATIC: `AppColors.brand.withValues(alpha: 0.05)` (보라색 계열)

3. **샘플 텍스트 개선**:
   - 변경 전: "홍길동, 김철수 ..."
   - 변경 후: "홍길동, 김철수 외 13명"
   - 더 구체적인 정보 제공

4. **구조 개선**:
   - Divider 제거
   - 혜택 리스트를 배경색 박스로 그룹화
   - 더 깔끔한 시각적 계층 구조

## 적용된 디자인 원칙

### Toss 디자인 철학
- ✅ **Simplicity First**: 기술 용어(DYNAMIC/STATIC) 제거
- ✅ **Easy to Answer**: 선택지가 명확하고 이해하기 쉬움
- ✅ **Value First**: 가치를 먼저 제시 (자동 업데이트, 직접 선택)
- ✅ **Title + Description 패턴**: 위계와 친근함 동시 제공

### 반응형 디자인
- ✅ 450px 브레이크포인트 사용
- ✅ 모바일: 세로 배치 (공간 효율)
- ✅ 태블릿/데스크톱: 좌우 배치 (비교 용이)

## 테스트 확인

```bash
flutter analyze
# 94 issues found (기존 이슈만 존재, 새로운 에러 없음)
```

## 관련 문서

- [docs/features/member-selection-flow.md](docs/features/member-selection-flow.md) - 멤버 선택 플로우
- [docs/ui-ux/concepts/design-principles.md](docs/ui-ux/concepts/design-principles.md) - Toss 디자인 원칙
- [docs/implementation/frontend/responsive-design.md](docs/implementation/frontend/responsive-design.md) - 반응형 디자인 가이드

## 향후 권장 사항

1. **모바일 실기기 테스트**: 450px 브레이크포인트가 적절한지 확인
2. **A/B 테스트**: 새로운 문구가 사용자 이해도를 높였는지 검증
3. **접근성 검증**: 색상 대비, 터치 영역 확인
4. **다국어 대응**: 영어 번역 시 문구 길이 고려
