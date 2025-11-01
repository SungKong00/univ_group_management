# 버튼 디자인 토큰 및 규격

## 개요

버튼의 구현을 위한 구체적인 토큰 값, 컴포넌트 API, 상태 스타일, 체크리스트를 정의합니다.

**상위 문서**: [버튼 디자인 가이드](button-design-guide.md)

## 디자인 토큰

### 크기 규격

```json
{
  "button": {
    "radius": "9999px",
    "size": {
      "sm": {
        "fontSize": "14px",
        "lineHeight": "22px",
        "fontWeight": 600,
        "paddingY": "8px",
        "paddingX": "16px",
        "height": "38px"
      },
      "md": {
        "fontSize": "16px",
        "lineHeight": "24px",
        "fontWeight": 600,
        "paddingY": "10px",
        "paddingX": "20px",
        "height": "44px"
      },
      "lg": {
        "fontSize": "18px",
        "lineHeight": "26px",
        "fontWeight": 600,
        "paddingY": "12px",
        "paddingX": "24px",
        "height": "50px"
      }
    }
  }
}
```

### 간격(Spacing)

```json
{
  "button": {
    "gap": {
      "horizontal": "8px–16px",
      "vertical": "8px–12px"
    },
    "icon": {
      "size": "16px–24px"
    }
  }
}
```

## 컴포넌트 구현 규격 (Flutter/Dart)

### 버튼 파라미터

```dart
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  // 유형 및 중요도
  final ButtonVariant variant; // filled, outlined, link
  final ButtonEmphasis emphasis; // primary, secondary, tertiary

  // 크기
  final ButtonSize size; // sm, md, lg

  // 아이콘
  final IconData? icon;
  final IconPosition iconPosition; // left, right

  // 상태
  final bool disabled;
  final bool isLoading;
  final bool fullWidth;

  // 접근성
  final String? semanticLabel;
}

enum ButtonVariant { filled, outlined, link }
enum ButtonEmphasis { primary, secondary, tertiary }
enum ButtonSize { sm, md, lg }
enum IconPosition { left, right }
```

### 사용 예시

```dart
// Primary, Filled, Medium, 우측 아이콘
AppButton(
  label: '계속하기',
  variant: ButtonVariant.filled,
  emphasis: ButtonEmphasis.primary,
  size: ButtonSize.md,
  icon: Icons.chevron_right,
  iconPosition: IconPosition.right,
  onPressed: () => navigateNext(),
)

// Secondary, Outlined, Small
AppButton(
  label: '취소',
  variant: ButtonVariant.outlined,
  emphasis: ButtonEmphasis.secondary,
  size: ButtonSize.sm,
  onPressed: () => Navigator.pop(context),
)

// Tertiary, Link
AppButton(
  label: '자세히 보기',
  variant: ButtonVariant.link,
  emphasis: ButtonEmphasis.tertiary,
  onPressed: () => openDetails(),
)

// 아이콘 단독
AppButton(
  icon: Icons.menu,
  semanticLabel: '메뉴 열기',
  variant: ButtonVariant.filled,
  emphasis: ButtonEmphasis.primary,
  onPressed: () => openMenu(),
)
```

## 상태 구현 지침 (Flutter)

### Default (기본 상태)
- 기본 색상 및 스타일 적용
- elevation 없음 또는 최소

### Hover / Focus (상호작용 상태)
- **명도 변화**: ±4–8% 밝게 또는 어둡게
- **elevation**: 가벼운 그림자 추가 (elevation 2–4)
- **포커스 링**: Focus 상태에서 두꺼운 외곽선 표시

### Active / Pressed (누른 상태)
- **명도**: Hover보다 어두움 (±8–12%)
- **elevation**: 그림자 축소 (elevation 0)
- **시각적 피드백**: Opacity 변화 또는 스케일 축소

### Disabled (비활성 상태)
- **opacity**: 0.45 (명도 낮춤)
- **포인터 이벤트**: 비활성화
- **시각적 표현**: 회색톤 또는 낮은 채도

### Loading (로딩 상태)
- 로딩 인디케이터 표시 (회전 원 또는 진행도)
- 포인터 이벤트 비활성화
- 텍스트/아이콘은 선택적으로 숨김

## 구현 체크리스트

### 규격
- [ ] `paddingX = 2 × paddingY`
- [ ] `paddingY ≥ 8px` (최소값)
- [ ] 텍스트: 14–20px / line-height ≥ 22px
- [ ] 시각 높이: 38–60px 범위
- [ ] 히트 영역: ≥ 44–48px (터치 타깃)

### 상태 구현
- [ ] Default 스타일 구현
- [ ] Hover 명도/그림자 변화 (±4–8%)
- [ ] Active 어두움/내려앉음 효과
- [ ] Disabled 대비 낮춤 (opacity 0.45)
- [ ] Focus-visible 3px 포커스 링

### 계층 구분
- [ ] Primary (Filled) / Secondary (Outlined) / Tertiary (Link) 명확
- [ ] 화면당 Primary는 1개 중심
- [ ] 나머지는 약화 상태

### 아이콘 통합
- [ ] 아이콘 크기: 16–24px (텍스트와 균형)
- [ ] 위치: 좌/우 의미에 맞게 일관성 유지
- [ ] 아이콘 단독 시 `aria-label` 제공

### 접근성
- [ ] 텍스트 대비: ≥ 4.5:1 (대형 3:1)
- [ ] 터치 타깃: ≥ 44–48px
- [ ] 색 외 추가 신호 (모양/두께/레이어)
- [ ] 레이블은 행동형 동사
- [ ] Focus-visible 링 필수 구현

## Quick Reference (TL;DR)

| 항목 | 규격 |
|------|------|
| 텍스트 크기 | 14–20px |
| 패딩(Y) | ≥ 8px |
| 패딩(X) | = 2 × Y |
| 높이 범위 | 38–60px |
| 히트 영역 | ≥ 44–48px |
| **유형** | **변형** |
| Primary | Filled (채움) |
| Secondary | Outlined/Ghost |
| Tertiary | Link/Subtle |
| **상태** | **표현** |
| Default | 기본 스타일 |
| Hover | 명도/그림자 변화 |
| Active | 어두움/내려앉음 |
| Disabled | 낮은 대비 (0.45) |
| Focus | 3px 포커스 링 |

## 관련 문서

- **디자인 가이드**: [버튼 디자인 가이드](button-design-guide.md)
- **디자인 토큰**: [디자인 토큰](design-tokens.md)
- **컴포넌트 구현**: [컴포넌트 구현 가이드](../../implementation/frontend/components.md)
