import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/navigation/navigation_state.dart';
import 'package:frontend/core/navigation/workspace_route.dart';
import 'package:frontend/presentation/providers/navigation_state_provider.dart';

/// Phase 7: T141.1 - 깊은 네비게이션 스택 성능 테스트
///
/// 요구사항 (NFR-004): 100+ 깊이의 스택에서도 성능 유지 및 메모리 누수 방지
///
/// 테스트 범위:
/// - 100+ 깊이 스택에서의 연산 성능
/// - 메모리 효율성 (스택 크기 증가에 따른 성능 저하 방지)
/// - 대량 pop 연산 성능
/// - 극한 시나리오 (1000+ 깊이)
void main() {
  group('T141.1: Deep Navigation Stack Performance Tests', () {
    late NavigationStateNotifier notifier;

    setUp(() {
      notifier = NavigationStateNotifier();
    });

    tearDown(() {
      notifier.dispose();
    });

    test('100-depth stack creation should complete in reasonable time', () {
      final stopwatch = Stopwatch()..start();

      // 100개 route 스택 생성
      final stack = List.generate(
        100,
        (i) => WorkspaceRoute.channel(groupId: 1, channelId: i),
      );
      notifier.state = NavigationState(stack: stack, currentIndex: 99);

      stopwatch.stop();

      expect(notifier.state.stack.length, 100);
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(100), // 100ms
        reason: '100개 route 스택 생성은 100ms 이내에 완료되어야 합니다',
      );
    });

    test('navigation at 100-depth should maintain <5ms per operation', () {
      // Setup: 100개 route 스택 생성
      final stack = List.generate(
        100,
        (i) => WorkspaceRoute.channel(groupId: 1, channelId: i),
      );
      notifier.state = NavigationState(stack: stack, currentIndex: 99);

      final stopwatch = Stopwatch()..start();

      // 50번 pop 연산 (99 → 49)
      for (int i = 0; i < 50; i++) {
        notifier.pop();
      }

      stopwatch.stop();

      // 50번의 pop이 모두 250ms(5ms * 50) 이내에 완료되어야 함
      expect(
        stopwatch.elapsedMicroseconds,
        lessThan(250000), // 250ms
        reason: '100-depth 스택에서 50번 pop은 250ms 이내에 완료되어야 합니다',
      );

      // 평균 시간도 검증
      final averageTimeMicros = stopwatch.elapsedMicroseconds / 50;
      expect(
        averageTimeMicros,
        lessThan(5000), // 5ms
        reason: '평균 pop 시간은 5ms 이내여야 합니다 (NFR-003)',
      );

      expect(notifier.state.currentIndex, 49);
    });

    test('current getter at 100-depth should maintain <5ms', () {
      // Setup: 100개 route 스택 생성
      final stack = List.generate(
        100,
        (i) => WorkspaceRoute.channel(groupId: 1, channelId: i),
      );
      notifier.state = NavigationState(stack: stack, currentIndex: 99);

      final stopwatch = Stopwatch()..start();

      // 100번 current getter 호출
      for (int i = 0; i < 100; i++) {
        final current = notifier.state.current;
        expect(
          current,
          const WorkspaceRoute.channel(groupId: 1, channelId: 99),
        );
      }

      stopwatch.stop();

      // 100번 호출이 모두 500ms(5ms * 100) 이내에 완료되어야 함
      expect(
        stopwatch.elapsedMicroseconds,
        lessThan(500000), // 500ms
        reason: '100-depth 스택에서 100번 current getter는 500ms 이내에 완료되어야 합니다',
      );

      // 평균 시간도 검증
      final averageTimeMicros = stopwatch.elapsedMicroseconds / 100;
      expect(
        averageTimeMicros,
        lessThan(5000), // 5ms
        reason: '평균 current getter 시간은 5ms 이내여야 합니다 (NFR-003)',
      );
    });

    test('replace at 100-depth should maintain <200ms', () {
      // Setup: 100개 route 스택 생성
      final stack = List.generate(
        100,
        (i) => WorkspaceRoute.channel(groupId: 1, channelId: i),
      );
      notifier.state = NavigationState(stack: stack, currentIndex: 99);

      final stopwatch = Stopwatch()..start();

      // 최상단 route 교체
      notifier.replace(
        const WorkspaceRoute.channel(groupId: 1, channelId: 999),
      );

      stopwatch.stop();

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(200), // 200ms
        reason: '100-depth 스택에서 replace는 200ms 이내에 완료되어야 합니다 (NFR-001)',
      );

      expect(
        notifier.state.stack[99],
        const WorkspaceRoute.channel(groupId: 1, channelId: 999),
      );
    });

    test('extreme depth (500+) should not cause performance degradation', () {
      // Setup: 500개 route 스택 생성
      final stack = List.generate(
        500,
        (i) => WorkspaceRoute.channel(groupId: 1, channelId: i),
      );

      final stopwatch = Stopwatch()..start();

      notifier.state = NavigationState(stack: stack, currentIndex: 499);

      stopwatch.stop();

      expect(notifier.state.stack.length, 500);
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(500), // 500ms
        reason: '500-depth 스택 생성은 500ms 이내에 완료되어야 합니다',
      );

      // 연산 성능 테스트
      final operationStopwatch = Stopwatch()..start();

      // 100번 pop
      for (int i = 0; i < 100; i++) {
        notifier.pop();
      }

      operationStopwatch.stop();

      // 100번의 pop이 모두 500ms(5ms * 100) 이내에 완료되어야 함
      expect(
        operationStopwatch.elapsedMicroseconds,
        lessThan(500000), // 500ms
        reason: '500-depth 스택에서 100번 pop은 500ms 이내에 완료되어야 합니다',
      );

      expect(notifier.state.currentIndex, 399);
    });

    test('stack memory should not grow linearly with operations', () {
      // Setup: 초기 50개 스택
      final initialStack = List.generate(
        50,
        (i) => WorkspaceRoute.channel(groupId: 1, channelId: i),
      );
      notifier.state = NavigationState(stack: initialStack, currentIndex: 49);

      // 49번 pop 연산 (currentIndex: 49 → 0)
      for (int i = 0; i < 49; i++) {
        notifier.pop();
      }

      // 스택은 그대로 50개여야 함 (메모리 증가 없음)
      expect(notifier.state.stack.length, 50);
      expect(notifier.state.currentIndex, 0); // root까지 pop됨

      // 다시 49번 forward (currentIndex만 증가)
      for (int i = 0; i < 49; i++) {
        notifier.state = notifier.state.copyWith(
          currentIndex: notifier.state.currentIndex + 1,
        );
      }

      // 여전히 스택은 50개 (메모리 효율성 검증)
      expect(notifier.state.stack.length, 50);
      expect(notifier.state.currentIndex, 49);
    });

    test('rapid replace operations should maintain performance', () {
      // Setup: 100개 route 스택
      final stack = List.generate(
        100,
        (i) => WorkspaceRoute.channel(groupId: 1, channelId: i),
      );
      notifier.state = NavigationState(stack: stack, currentIndex: 50);

      final stopwatch = Stopwatch()..start();

      // 50번 replace 연산 (currentIndex 50번 교체)
      for (int i = 0; i < 50; i++) {
        notifier.replace(
          WorkspaceRoute.channel(groupId: 1, channelId: 1000 + i),
        );
      }

      stopwatch.stop();

      // 50번의 replace가 모두 10000ms(200ms * 50) 이내에 완료되어야 함
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(10000), // 10초
        reason: '50번의 replace는 10초 이내에 완료되어야 합니다',
      );

      // 평균 시간도 검증
      final averageTimeMillis = stopwatch.elapsedMilliseconds / 50;
      expect(
        averageTimeMillis,
        lessThan(200), // 200ms
        reason: '평균 replace 시간은 200ms 이내여야 합니다 (NFR-001)',
      );

      expect(
        notifier.state.stack[50],
        const WorkspaceRoute.channel(groupId: 1, channelId: 1049),
      );
    });
  });
}
