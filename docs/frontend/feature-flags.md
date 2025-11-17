# Feature Flags 사용 가이드

## 개요

Feature Flag는 새로운 기능을 안전하게 배포하고 점진적으로 전환하기 위한 메커니즘입니다.

**목적**:
- 새 구현을 기존 코드와 병행 운영
- 문제 발생 시 즉시 롤백 (코드 수정 없이)
- A/B 테스트 및 점진적 마이그레이션

**파일**: `lib/core/config/feature_flags.dart`

---

## 현재 Flag 목록

### useAsyncNotifierPattern

**기능**: AsyncNotifier 패턴으로 게시글 로딩

**상태**: ✅ 활성화 (기본값: true)

**설명**:
- `true`: Provider가 데이터 로딩 제어 (Clean Architecture 준수)
- `false`: Widget이 데이터 로딩 제어 (구 방식, Race Condition)

**적용 범위**:
- `lib/presentation/widgets/post/post_list.dart`
- `lib/features/post/presentation/providers/post_list_notifier.dart`

**전환 계획**:
- Phase 1 (현재): 신규 구현 병행, Feature Flag로 제어
- Phase 2 (안정화 후): Flag 제거, 구 코드 삭제
- Phase 3 (확장): 다른 목록 위젯 적용

---

## 사용 방법

### 1. Feature Flag 정의

```dart
// lib/core/config/feature_flags.dart
class FeatureFlags {
  /// 기능 설명
  ///
  /// - true: 새 방식 설명
  /// - false: 구 방식 설명
  static const bool flagName = true;
}
```

### 2. 코드에서 사용

```dart
import '../../../core/config/feature_flags.dart';

if (FeatureFlags.flagName) {
  // 신규 구현
  _newImplementation();
} else {
  // 기존 구현
  _oldImplementation();
}
```

### 3. Widget에서 분기

```dart
@override
void initState() {
  super.initState();

  if (FeatureFlags.useAsyncNotifierPattern) {
    // 신 방식: Provider 자동 로딩
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreScrollPosition();
    });
  } else {
    // 구 방식: Widget이 로딩 제어
    Future.microtask(() {
      _loadPosts();
    });
  }
}
```

---

## 모범 사례

### DO ✅

1. **명확한 주석**: Flag의 의미와 영향 범위 설명
2. **점진적 전환**: 신구 코드 병행 운영
3. **제거 계획**: Flag의 생명주기 명시
4. **테스트**: 양쪽 분기 모두 테스트

### DON'T ❌

1. **장기 유지**: 안정화 후 즉시 제거
2. **중첩 분기**: Flag 내부에 다른 Flag 사용
3. **비즈니스 로직**: 단순 기술 전환에만 사용
4. **런타임 변경**: const로 고정 (컴파일 타임 최적화)

---

## 관련 문서

- [아키텍처 가이드](../implementation/frontend/architecture.md)
- [Post Phase 3 완료 보고서](../workflows/post-phase3-completion.md)
