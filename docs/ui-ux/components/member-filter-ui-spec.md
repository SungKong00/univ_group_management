# 멤버 필터 UI 명세 (Member Filter UI Specification)

멤버 필터 패널의 상세 UI/UX 명세입니다.

## 필터 패널 구조

```
┌─────────────────────────────────────────┐
│ 멤버 필터                                │
├─────────────────────────────────────────┤
│ 역할 (선택 시 단독 필터) ⓘ               │
│ ☐ 그룹장  ☐ 교수  ☐ 멤버                │
├─────────────────────────────────────────┤
│ 소속 그룹 ⓘ                              │
│ ☐ AI 학회  ☐ 프로그래밍 동아리           │
├─────────────────────────────────────────┤
│ 학년 또는 학번 ⓘ                         │
│ ─────────────────────────────────────   │
│ 학년: ☐ 1  ☐ 2  ☐ 3  ☐ 4                │
│ 학번: [24학번 ▼] [25학번 ▼]             │
├─────────────────────────────────────────┤
│ 적용된 필터:                            │
│ [그룹: AI학회 ×] [학년: 2,3 ×]          │
│ [모두 지우기]                           │
├─────────────────────────────────────────┤
│ 결과: 15명                              │
└─────────────────────────────────────────┘
```

## 상호작용 규칙

### 역할 필터 (단독 모드)

**선택 시**:
- 모든 일반 필터(그룹, 학년, 학번) 비활성화 (회색 처리)
- 이미 선택된 일반 필터 자동 초기화
- Tooltip: "역할 선택 시 다른 필터가 비활성화됩니다"

### 일반 필터 (그룹, 학년, 학번)

**선택 시**:
- 역할 필터 비활성화 (회색 처리)
- 역할 필터 선택 해제
- 그룹 + 학년/학번은 AND 관계
- 학년 OR 학번 (같은 섹션 내 OR)

### 학년/학번 그룹

**시각적 구분**:
- 배경색: `AppColors.neutral50`
- 테두리: `AppColors.neutral200`
- 구분선: "또는" 라벨 명시

## 색상 디자인 토큰

### 선택 상태

**미선택**:
- 배경: `AppColors.neutral100`
- 텍스트: `AppColors.neutral700`
- 테두리: `AppColors.neutral300`

**선택**:
- 배경: `AppColors.blue100`
- 텍스트: `AppColors.blue700`
- 테두리: `AppColors.blue500`

**비활성화**:
- 배경: `AppColors.neutral50`
- 텍스트: `AppColors.neutral400`
- Opacity: 0.6

### 구분선 및 배경

- 섹션 구분선: `AppColors.neutral200`
- 학년/학번 그룹 배경: `AppColors.neutral50`
- 적용된 필터 배경: `AppColors.blue50`

## 간격 및 레이아웃

**패딩**:
- 패널 외부: `AppSpacing.lg` (24px)
- 섹션 간격: `AppSpacing.md` (16px)
- 칩 간격: `AppSpacing.xs` (8px)

**타이포그래피**:
- 섹션 제목: `AppTypography.titleMedium` (16px, w600)
- 칩 라벨: `AppTypography.bodyMedium` (14px, w400)
- 결과 카운트: `AppTypography.titleSmall` (14px, w600)

## 반응형 레이아웃

### 데스크톱 (1024px 이상)

좌측 고정 패널 (300px):
```
┌────────────┬─────────────┐
│ 필터 패널   │ 멤버 목록    │
│ (300px)    │ (나머지)     │
└────────────┴─────────────┘
```

### 모바일 (768px 이하)

바텀 시트 또는 전체 화면:
```
┌─────────────────┐
│ [필터 🔽]       │  ← 토글 버튼
├─────────────────┤
│ 멤버 목록        │
└─────────────────┘

↓ 클릭 시

┌─────────────────┐
│ 필터 패널        │  ← 오버레이
│ (전체 화면)      │
│ [적용] [취소]   │
└─────────────────┘
```

## 상태별 UI

### 빈 상태 (결과 0명)

```
┌─────────────────────────┐
│   🔍                    │
│   조건에 맞는 멤버 없음  │
│   [필터 초기화]         │
└─────────────────────────┘
```

### 로딩 상태

필터 패널은 정상, 멤버 목록만 스켈레톤 로더 표시

## 구현 파일

**패널**: `frontend/lib/presentation/pages/member_management/widgets/member_filter_panel.dart`
**칩 바**: `frontend/lib/presentation/pages/group_explore/widgets/group_filter_chip_bar.dart`
**Chip**: `frontend/lib/presentation/widgets/common/app_input_chip.dart`

## 관련 문서

- [멤버 필터 개념](../../concepts/member-list-system.md) - 필터링 로직
- [멤버 필터 구현](../../implementation/frontend/member-list-implementation.md) - Phase 1 구현
- [멤버 필터 고급 기능](../../implementation/frontend/member-filter-advanced-features.md) - Phase 2-3
- [Chip 컴포넌트](../../implementation/frontend/chip-components.md) - AppChip, AppInputChip
- [디자인 시스템](../concepts/design-system.md) - 디자인 토큰
