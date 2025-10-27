# 버그 수정 요약 (2025-10-26)

## 수정된 버그

### 버그 #1: CompactChip - 칩 폭이 너무 큼

**문제**:
- `Center` + `IntrinsicWidth` 래핑으로 인해 칩이 불필요하게 넓어짐
- `AnimatedContainer`가 이미 고정 높이(24px)와 패딩(horizontal: 8)을 가지고 있는데, 추가 래핑이 텍스트 크기 최적화를 방해함

**원인**:
```dart
// Before (문제 코드)
child: Center(
  child: IntrinsicWidth(
    child: Text(label, ...),
  ),
),
```
- `Center`가 부모의 전체 너비를 차지하여 `IntrinsicWidth`가 무의미함
- 텍스트 길이에 맞게 자동 조정되지 않음

**해결**:
```dart
// After (수정 코드)
child: Text(
  label,
  style: TextStyle(...),
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  textAlign: TextAlign.center,
),
```
- 불필요한 래핑 제거
- `AnimatedContainer`의 패딩이 자연스럽게 텍스트를 중앙 정렬
- 텍스트 길이에 맞게 자동 조정

**파일**: `frontend/lib/presentation/components/chips/compact_chip.dart`
**라인**: 92-104

---

### 버그 #2: MultiSelectPopover - 칩 선택 시 버튼이 실시간으로 업데이트되지 않음

**문제**:
- 팝오버 내부에서 칩을 클릭하여 선택/해제할 때, 버튼에 표시되는 선택 개수가 즉시 업데이트되지 않음
- `_toggleItem()`의 `setState()`가 팝오버 내부만 리빌드하고, 버튼은 리빌드하지 않음

**원인**:
```dart
void _toggleItem(T item) {
  setState(() {
    if (_draftSelection.contains(item)) {
      _draftSelection.remove(item);
    } else {
      _draftSelection.add(item);
    }
  });
  // 버튼이 리빌드되지 않음!
}
```

**해결 방법**: `ValueNotifier` 사용
1. `_draftCountNotifier: ValueNotifier<int>` 추가
2. `_toggleItem()` 시 notifier 업데이트
3. `_buildButton()`을 `ValueListenableBuilder`로 감싸기

**구체적인 수정**:

```dart
// 1. 필드 추가
late ValueNotifier<int> _draftCountNotifier;

@override
void initState() {
  super.initState();
  _draftSelection = List.from(widget.selectedItems);
  _draftCountNotifier = ValueNotifier<int>(_draftSelection.length);
}

@override
void dispose() {
  _closePopover();
  _draftCountNotifier.dispose(); // 메모리 누수 방지
  super.dispose();
}
```

```dart
// 2. 항목 토글 시 notifier 업데이트
void _toggleItem(T item) {
  setState(() {
    if (_draftSelection.contains(item)) {
      _draftSelection.remove(item);
    } else {
      _draftSelection.add(item);
    }
    // 버튼 실시간 업데이트
    _draftCountNotifier.value = _draftSelection.length;
  });
}
```

```dart
// 3. 버튼을 ValueListenableBuilder로 감싸기
Widget _buildButton() {
  return ValueListenableBuilder<int>(
    valueListenable: _draftCountNotifier,
    builder: (context, draftCount, child) {
      // 팝오버가 열려있으면 draft 선택을 반영, 아니면 확정된 선택 사용
      final displayCount = _isOpen ? draftCount : widget.selectedItems.length;
      final displayText = displayCount == 0
          ? '${widget.label}: ${widget.emptyLabel}'
          : '${widget.label} ($displayCount)';

      return InkWell(
        onTap: _togglePopover,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Container(
          // ... 버튼 UI
        ),
      );
    },
  );
}
```

**파일**: `frontend/lib/presentation/components/popovers/multi_select_popover.dart`
**라인**:
- 69-76: `_draftCountNotifier` 초기화
- 88-92: `dispose()` 수정
- 205-216: `_toggleItem()` 수정
- 226-278: `_buildButton()` 수정

---

## 테스트 방법

### CompactChip
1. 멤버 필터 페이지 열기
2. "역할" 팝오버 열기
3. **확인**: 칩의 너비가 텍스트 길이에 맞게 최소화되어야 함
4. 다양한 길이의 라벨 테스트 (짧은 라벨: "멤버", 긴 라벨: "시스템 관리자")

### MultiSelectPopover
1. 멤버 필터 페이지 열기
2. "역할" 팝오버 열기
3. 칩 클릭하여 선택/해제
4. **확인**: 버튼의 선택 개수 `(N)`이 즉시 업데이트되어야 함
5. 팝오버 외부 클릭하여 닫기
6. **확인**: 버튼에 확정된 선택 개수가 표시되어야 함

---

## 성능 영향

### CompactChip
- **개선**: 불필요한 위젯 래핑 제거로 빌드 성능 향상
- **측정**: 위젯 트리 깊이 2단계 감소

### MultiSelectPopover
- **개선**: `ValueListenableBuilder` 사용으로 필요한 부분만 리빌드
- **효율성**: 전체 위젯 트리 리빌드 대신 버튼만 업데이트
- **메모리**: `dispose()`에서 notifier 해제로 메모리 누수 방지

---

## 추가 개선 사항

### 고려할 만한 개선
1. **CompactChip 애니메이션**: 선택 시 scale 애니메이션 추가 (선택 사항)
2. **MultiSelectPopover 키보드 지원**: 스페이스바로 선택/해제 (접근성 개선)
3. **리팩토링**: `_buildButton()` 메서드가 길어짐 → 별도 위젯으로 분리 고려

### 성능 모니터링
- Flutter DevTools로 리빌드 횟수 확인
- 위젯 트리 깊이 모니터링
- 메모리 사용량 추적

---

## 결론

두 버그 모두 성공적으로 수정되었습니다:

1. **CompactChip**: 불필요한 래핑 제거로 칩 크기 최적화
2. **MultiSelectPopover**: `ValueNotifier` 패턴으로 버튼 실시간 업데이트

수정 후 Hot Reload로 즉시 테스트 가능하며, 사용자 경험이 크게 개선되었습니다.
