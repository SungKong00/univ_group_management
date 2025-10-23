# Row/Column 레이아웃 체크리스트

> **문서 예외**: 이 문서는 100줄 원칙의 예외로, 자주 발생하는 레이아웃 실수 패턴을 빠르게 참조하기 위한 체크리스트입니다.

## 개요

Flutter에서 Row와 Column 위젯 내부에 자식 위젯을 배치할 때 가장 흔하게 발생하는 에러는 "BoxConstraints forces an infinite width/height" 입니다. 이 문서는 이러한 에러를 사전에 방지하고, 발생 시 빠르게 해결할 수 있도록 구체적인 체크리스트와 패턴을 제공합니다.

## 핵심 원칙

### Row 내부 위젯 규칙
- **모든 자식 위젯은 명시적인 너비 제약이 필요합니다**
- Row는 수평 방향으로 무한한 공간을 제공하므로, 자식 위젯이 스스로 너비를 결정할 수 없으면 에러 발생

### Column 내부 위젯 규칙
- **모든 자식 위젯은 명시적인 높이 제약이 필요합니다**
- Column은 수직 방향으로 무한한 공간을 제공하므로, 자식 위젯이 스스로 높이를 결정할 수 없으면 에러 발생

## 개발 전 필수 체크리스트

### Row 위젯 추가 시
```markdown
□ 각 자식 위젯이 다음 중 하나로 감싸져 있는가?
  □ Expanded (가용 공간을 채움)
  □ Flexible (가용 공간 내에서 유연하게 크기 조정)
  □ SizedBox(width: ...) (고정 너비)
  □ Container(width: ...) (고정 너비)
  □ IntrinsicWidth (자식의 고유 너비 사용, 성능 주의)

□ 자식 위젯이 자체적으로 너비를 가지는가?
  □ Text (자체 너비 있음)
  □ Icon (자체 너비 있음)
  □ Image (width 지정 시)
  □ Button (고정 너비가 아닌 경우 Expanded/Flexible 필요)

□ DropdownMenuItem 내부의 Row인가?
  □ mainAxisSize: MainAxisSize.min 설정했는가?
  □ Expanded 대신 Flexible 사용했는가?
```

### Column 위젯 추가 시
```markdown
□ 각 자식 위젯이 다음 중 하나로 감싸져 있는가?
  □ Expanded (가용 공간을 채움)
  □ Flexible (가용 공간 내에서 유연하게 크기 조정)
  □ SizedBox(height: ...) (고정 높이)
  □ Container(height: ...) (고정 높이)
  □ IntrinsicHeight (자식의 고유 높이 사용, 성능 주의)

□ 자식 위젯이 자체적으로 높이를 가지는가?
  □ Text (자체 높이 있음)
  □ Icon (자체 높이 있음)
  □ Image (height 지정 시)
  □ Button (고정 높이가 아닌 경우 Expanded/Flexible 필요)
```

## 자주 하는 실수 패턴과 해결책

### 패턴 1: Row 내부의 버튼 (가장 흔함)

#### ❌ 잘못된 코드
```dart
Row(
  children: [
    SizedBox(height: 44, child: OutlinedButton(...)),  // 에러 발생!
    ElevatedButton(...),  // 에러 발생!
  ],
)
```

#### ✅ 올바른 해결책 (옵션 1: Expanded)
```dart
Row(
  children: [
    Expanded(
      child: SizedBox(height: 44, child: OutlinedButton(...)),
    ),
    const SizedBox(width: 8),
    Expanded(
      child: ElevatedButton(...),
    ),
  ],
)
```

#### ✅ 올바른 해결책 (옵션 2: Flexible)
```dart
Row(
  children: [
    Flexible(
      child: SizedBox(height: 44, child: OutlinedButton(...)),
    ),
    const SizedBox(width: 8),
    Flexible(
      child: ElevatedButton(...),
    ),
  ],
)
```

#### ✅ 올바른 해결책 (옵션 3: SizedBox)
```dart
Row(
  children: [
    SizedBox(
      width: 120,
      height: 44,
      child: OutlinedButton(...),
    ),
    const SizedBox(width: 8),
    SizedBox(
      width: 120,
      height: 44,
      child: ElevatedButton(...),
    ),
  ],
)
```

### 패턴 2: DropdownMenuItem 내부의 Row (특수 케이스)

#### ❌ 잘못된 코드
```dart
DropdownMenuItem(
  child: Row(
    children: [
      Expanded(child: Text('옵션 1')),  // 에러 발생!
    ],
  ),
)
```

#### ✅ 올바른 해결책
```dart
DropdownMenuItem(
  child: Row(
    mainAxisSize: MainAxisSize.min,  // 필수!
    children: [
      Flexible(child: Text('옵션 1')),  // Expanded 대신 Flexible
    ],
  ),
)
```

### 패턴 3: Column 내부의 리스트

#### ❌ 잘못된 코드
```dart
Column(
  children: [
    ListView(children: [...]),  // 에러 발생!
  ],
)
```

#### ✅ 올바른 해결책 (옵션 1: Expanded)
```dart
Column(
  children: [
    Expanded(
      child: ListView(children: [...]),
    ),
  ],
)
```

#### ✅ 올바른 해결책 (옵션 2: SizedBox)
```dart
Column(
  children: [
    SizedBox(
      height: 300,
      child: ListView(children: [...]),
    ),
  ],
)
```

### 패턴 4: Row 내부의 TextField

#### ❌ 잘못된 코드
```dart
Row(
  children: [
    TextField(),  // 에러 발생!
  ],
)
```

#### ✅ 올바른 해결책
```dart
Row(
  children: [
    Expanded(
      child: TextField(),
    ),
  ],
)
```

### 패턴 5: 중첩된 Row/Column

#### ❌ 잘못된 코드
```dart
Row(
  children: [
    Column(
      children: [
        Row(
          children: [
            Text('제목'),  // 상황에 따라 에러 발생 가능
          ],
        ),
      ],
    ),
  ],
)
```

#### ✅ 올바른 해결책
```dart
Row(
  children: [
    Expanded(  // 바깥 Row에 대한 제약
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(  // 안쪽 Row에 대한 제약
                child: Text('제목'),
              ),
            ],
          ),
        ],
      ),
    ),
  ],
)
```

## 에러 발생 시 진단 프로세스

### 1단계: 에러 메시지 확인
```
"BoxConstraints forces an infinite width"
→ Row 내부의 위젯에 너비 제약 누락

"BoxConstraints forces an infinite height"
→ Column 내부의 위젯에 높이 제약 누락

"RenderFlex children have non-zero flex but incoming width constraints are unbounded"
→ DropdownMenuItem 내부에서 Expanded 사용 (Flexible로 변경 필요)
```

### 2단계: 에러 발생 위치 추적
```markdown
1. 스택 트레이스에서 에러가 발생한 위젯 찾기
2. 해당 위젯의 부모가 Row 또는 Column인지 확인
3. Row/Column의 children 배열 확인
4. 각 자식 위젯이 적절한 제약을 가지고 있는지 검증
```

### 3단계: 적절한 해결책 선택

#### Expanded vs Flexible vs SizedBox
- **Expanded**: 가용 공간을 모두 차지해야 할 때
  - 예: 전체 너비를 채워야 하는 TextField
  - 예: 동일한 비율로 나눠야 하는 버튼들

- **Flexible**: 콘텐츠 크기에 따라 유연하게 조정되어야 할 때
  - 예: 텍스트 길이에 따라 조정되는 라벨
  - 예: 최소 공간만 차지하되 필요 시 확장되는 요소

- **SizedBox**: 고정된 크기가 필요할 때
  - 예: 정확한 너비/높이가 지정된 이미지
  - 예: 디자인 시스템에서 정의된 고정 크기 요소

## 개발 워크플로우 통합

### 코드 작성 전
1. Row나 Column을 사용하기 전에 이 체크리스트를 확인
2. 각 자식 위젯의 제약 전략을 미리 계획
3. DropdownMenuItem 같은 특수 케이스인지 확인

### 코드 작성 중
1. Row/Column 추가 시 즉시 자식 위젯에 제약 추가
2. 중첩된 Row/Column의 경우 각 레벨마다 제약 확인
3. 복잡한 레이아웃은 작은 단위로 나눠서 구현

### 코드 리뷰 전
1. 모든 Row/Column 위젯 검토
2. 제약이 명시적으로 설정되어 있는지 확인
3. 특수 케이스(DropdownMenuItem 등) 올바르게 처리되었는지 확인

## 참고 자료

- [Flutter Layout Cheat Sheet](https://medium.com/flutter-community/flutter-layout-cheat-sheet-5363348d037e)
- [Understanding Constraints](https://docs.flutter.dev/ui/layout/constraints)
- [Design System](../ui-ux/concepts/design-system.md)
