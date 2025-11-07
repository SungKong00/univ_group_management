# 버튼 디자인 가이드

## 개요

버튼은 사용자 행동의 핵심 트리거입니다. 이 가이드는 일관된 버튼 디자인을 통해 명확한 계층과 상태를 전달하기 위한 원칙과 규칙을 정의합니다.

**관련 문서**: [디자인 원칙](design-principles.md) · [디자인 토큰](design-tokens.md) · [컬러 가이드](color-guide.md)

## 설계 원칙

### 1. 명확한 계층 구조
- 화면당 **Primary 버튼은 1개**로 제한 (사용자 시선 유도)
- Secondary/Tertiary로 보조 행동 구분
- 중요도와 시각 무게가 일치

### 2. 일관된 상태 표현
- **기본(Default)** → **호버(Hover)** → **활성(Active)** → **비활성(Disabled)** 명확
- 색상만으로 상태를 구분하지 않음 (명도/형태/레이어 병행)
- 포커스 상태는 접근성을 위해 필수 (Focus-visible 링)

### 3. 접근성 우선
- 텍스트 대비율: 4.5:1 이상 (대형 텍스트는 3:1)
- 터치 타깃: **44px 이상** (Apple), **48px 이상** (Google)
- 레이블은 행동형 동사 사용 ("제출", "지금 시작" 등)

## 유형 × 중요도

| 유형 | 변형 | 사용 사례 | 예시 |
|------|------|---------|------|
| **Primary** | Filled (채움) | 가장 중요한 행동 | "가입하기", "저장" |
| **Secondary** | Outlined/Ghost | 보조 행동 | "취소", "더보기" |
| **Tertiary** | Link/Subtle | 낮은 중요도 | "자세히 보기", "건너뛰기" |

## 크기 및 타이포그래피

### 텍스트 크기
```
Small (sm):    14px / line-height 22px / font-weight 600
Medium (md):   16px / line-height 24px / font-weight 600
Large (lg):    18px / line-height 26px / font-weight 600
```

### 패딩 규칙
```
paddingX = 2 × paddingY
paddingY ≥ 8px (최소)

Small:   Y=8px  → X=16px
Medium:  Y=10px → X=20px
Large:   Y=12px → X=24px
```

### 시각 높이 범위
```
Small:   38px (8+22+8)
Medium:  44px (10+24+10)
Large:   50px (12+26+12)

권장 범위: 38–60px
```

### 히트 영역(Touch Target)
- 최소 44px (Apple), 48px (Google)
- 시각 높이보다 크거나 같게 유지
- 버튼 주변 마진으로 추가 터치 영역 확보 가능

## 상태(Behaviors)

### Default
기본 스타일. 상호작용 없는 상태.

### Hover
- 명도 변화: ±4–8% (밝음 또는 어두움)
- 그림자 추가: 약한 드롭 섀도우
- 예: `filter: brightness(0.96)`

### Active/Pressed
- 살짝 어두워짐 (호버보다 더)
- 그림자 축소 (눌린 느낌)
- 예: `transform: translateY(1px)` (아래로 1px)

### Disabled
- 대비율 낮춤: `opacity: 0.45`
- 포인터 이벤트 무효화
- 호버/포커스/클릭 무응답

### Focus-visible
- 굵은 포커스 링: 3px 솔리드
- Outline offset: 2px
- 접근성 필수 요소

## 아이콘 규칙

### 크기
- **텍스트와 시각 무게 균형**: 16–24px
  - 14px 텍스트 → 16px 아이콘
  - 16px 텍스트 → 20px 아이콘
  - 18px 텍스트 → 24px 아이콘

### 위치
- 텍스트 좌측: 다운로드, 추가, 이전 등의 방향성 아이콘
- 텍스트 우측: 다음, 외부 링크, 드롭다운 등의 다음 단계 아이콘
- 의미에 따라 위치 일관성 유지

### 아이콘 단독 버튼
- **aria-label 필수** (스크린 리더 지원)
- 예: `<button aria-label="메뉴 열기">`

## 레이아웃

### 버튼 간 간격
- 가로: 8–16px
- 세로: 8–12px
- 일관성 있게 유지

### 화면 레이아웃 규칙
- **한 화면에 Primary는 1개 중심**
- 나머지는 Secondary(약화) 또는 Tertiary(더 약화)
- 시각 계층 명확화

## 레이블 규칙

### 길이
- **1–3단어** 권장
- 행동 + 목적 (예: "가격 보기", "지금 구독")
- "Click here" 지양

### 현지화 고려
- 자동 폭 확장 대비 (번역 시 길이 증가)
- 고정 폭 사용 금지
- 텍스트 오버플로우 시 줄바꿈 또는 말임표(...) 사용

## 접근성 체크리스트

- [ ] 텍스트 대비율 ≥ 4.5:1 (대형 3:1)
- [ ] 터치 타깃 ≥ 44–48px
- [ ] 색만으로 상태 구분 금지 (모양/두께/레이어 병행)
- [ ] 레이블은 행동형 동사 사용
- [ ] Focus-visible 링 구현
- [ ] 아이콘 단독 버튼의 aria-label 제공

## 관련 문서

- **구현 규격**: [버튼 디자인 토큰](button-design-tokens.md)
- **디자인 원칙**: [디자인 원칙](design-principles.md)
- **컴포넌트 구현**: [컴포넌트 구현 가이드](../../implementation/frontend/components.md)
