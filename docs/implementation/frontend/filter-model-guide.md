# FilterModel 구현 가이드

## 개요

FilterModel은 필터링 기능을 구현하는 모든 모델이 따라야 하는 인터페이스입니다.

**핵심 요구사항**:
- ✅ 필터 활성화 여부 확인 (`isActive`)
- ✅ API 쿼리 파라미터 변환 (`toQueryParameters`)
- ✅ **Sentinel Value Pattern을 사용한 copyWith() 구현**

## 구현 체크리스트

### 1단계: 기본 구조
```dart
import '../providers/generic/filter_model.dart';

class MyFilter implements FilterModel {
  final List<int>? someIds;
  final bool? someFlag;

  MyFilter({this.someIds, this.someFlag});
}
```

### 2단계: isActive 구현
```dart
@override
bool get isActive =>
    (someIds?.isNotEmpty ?? false) || someFlag != null;
```

### 3단계: toQueryParameters 구현
```dart
@override
Map<String, dynamic> toQueryParameters() {
  final params = <String, String>{};
  if (someIds != null && someIds!.isNotEmpty) {
    params['someIds'] = someIds!.join(',');
  }
  if (someFlag != null) {
    params['someFlag'] = someFlag.toString();
  }
  return params;
}
```

### 4단계: copyWith 구현 (⚠️ 중요!)
```dart
// ⚠️ 센티널 값 정의 (private static const)
static const _undefined = Object();

@override
MyFilter copyWith({
  Object? someIds = _undefined,  // 기본값: 센티널
  Object? someFlag = _undefined,
}) {
  return MyFilter(
    someIds: someIds == _undefined
        ? this.someIds
        : (someIds as List<int>?),  // ⚠️ nullable 타입 필수!
    someFlag: someFlag == _undefined
        ? this.someFlag
        : (someFlag as bool?),
  );
}
```

## Sentinel Value Pattern

### 문제점: `??` 연산자의 한계

```dart
// ❌ 잘못된 구현
MyFilter copyWith({List<int>? someIds}) {
  return MyFilter(someIds: someIds ?? this.someIds);
}

// 문제: null 전달 시 기존 값 유지됨
filter.copyWith(someIds: null);  // someIds가 null로 설정되지 않음!
```

Dart의 `??` 연산자는 "파라미터 생략"과 "명시적 null 전달"을 구분할 수 없습니다.

### 해결: Sentinel Value

센티널 값으로 세 가지 상태를 구분합니다:
1. **파라미터 생략**: 기본값 `_undefined` → 기존 값 유지
2. **명시적 null 전달**: `null` → null로 설정 (필터 해제)
3. **새로운 값 전달**: 실제 값 → 새 값으로 변경

```dart
// ✅ 올바른 구현
static const _undefined = Object();

MyFilter copyWith({Object? someIds = _undefined}) {
  return MyFilter(
    someIds: someIds == _undefined
        ? this.someIds            // 파라미터 생략 → 기존 값 유지
        : (someIds as List<int>?), // null 포함 새 값 → 변경
  );
}
```

## 테스트 작성

참조: `test/core/models/filter_model_test.dart`

```dart
group('MyFilter copyWith() Tests', () {
  test('nullable 필드를 null로 설정 가능', () {
    final filter = MyFilter(someIds: [1, 2, 3]);
    final result = filter.copyWith(someIds: null);
    expect(result.someIds, isNull);
  });

  test('파라미터 생략 시 기존 값 유지', () {
    final filter = MyFilter(someIds: [1, 2], someFlag: true);
    final result = filter.copyWith(someFlag: false);
    expect(result.someIds, [1, 2]);  // 유지됨
  });

  test('모든 필터를 null로 초기화', () {
    final filter = MyFilter(someIds: [1], someFlag: true);
    final result = filter.copyWith(someIds: null, someFlag: null);
    expect(result.isActive, isFalse);
  });
});
```

## 트러블슈팅

### ❌ 필터를 null로 설정할 수 없음

**원인**: `??` 연산자 사용 (Sentinel Value Pattern 미적용)

**해결**:
```dart
// Before
MyFilter copyWith({List<int>? someIds}) {
  return MyFilter(someIds: someIds ?? this.someIds);
}

// After
static const _undefined = Object();
MyFilter copyWith({Object? someIds = _undefined}) {
  return MyFilter(
    someIds: someIds == _undefined ? this.someIds : (someIds as List<int>?),
  );
}
```

### ❌ Type Cast 에러

**증상**: `type 'Null' is not a subtype of type 'List<int>' in type cast`

**원인**: `as List<int>` 사용 (nullable 타입이어야 함)

**해결**: `as List<int>?` 사용 (nullable 타입)

### ❌ 센티널 값이 public으로 노출됨

**해결**: private으로 변경 (`_undefined`)

## 참조 구현

- `lib/core/models/member_filter.dart` - 올바른 구현 예시
- `lib/core/models/group_explore_filter.dart` - 올바른 구현 예시
- `lib/core/providers/generic/filter_model.dart` - 인터페이스 정의
