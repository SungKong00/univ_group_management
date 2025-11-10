import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/navigation/navigation_state.dart';
import 'package:frontend/core/navigation/workspace_route.dart';
import 'package:frontend/presentation/providers/navigation_state_provider.dart';

/// Phase 7: T141 - 히스토리 스택 연산 성능 테스트
///
/// 요구사항 (NFR-003): 히스토리 스택 연산은 5ms 이내에 완료되어야 함
///
/// 테스트 범위:
/// - currentIndex 업데이트 성능
/// - canPop 체크 성능
/// - current getter 성능
/// - 대량 스택에서의 연산 성능
void main() {
  group('T141: History Stack Performance Tests', () {
    late NavigationStateNotifier notifier;

    setUp(() {
      notifier = NavigationStateNotifier();
    });

    tearDown(() {
      notifier.dispose();
    });

    test('currentIndex update should complete in <5ms', () {
      // Setup: 스택 준비
      notifier.state = NavigationState(
        stack: [
          const WorkspaceRoute.home(groupId: 1),
          const WorkspaceRoute.channel(groupId: 1, channelId: 10),
        ],
        currentIndex: 1,
      );

      final stopwatch = Stopwatch()..start();

      // currentIndex 변경 (pop 연산)
      notifier.pop();

      stopwatch.stop();

      expect(
        stopwatch.elapsedMicroseconds,
        lessThan(5000), // 5ms = 5,000μs
        reason: 'currentIndex 업데이트는 5ms 이내에 완료되어야 합니다 (NFR-003)',
      );

      expect(notifier.state.currentIndex, 0);
    });

    test('canPop check should complete in <5ms', () {
      // Setup: 스택 준비
      notifier.state = NavigationState(
        stack: [
          const WorkspaceRoute.home(groupId: 1),
          const WorkspaceRoute.channel(groupId: 1, channelId: 10),
        ],
        currentIndex: 1,
      );

      final stopwatch = Stopwatch()..start();

      // 100번 canPop 체크
      for (int i = 0; i < 100; i++) {
        final canPop = notifier.state.canPop;
        expect(canPop, isTrue);
      }

      stopwatch.stop();

      // 100번 체크가 모두 500ms(5ms * 100) 이내에 완료되어야 함
      expect(
        stopwatch.elapsedMicroseconds,
        lessThan(500000), // 500ms = 500,000μs
        reason: '100번의 canPop 체크는 총 500ms 이내에 완료되어야 합니다',
      );

      // 평균 시간도 검증
      final averageTimeMicros = stopwatch.elapsedMicroseconds / 100;
      expect(
        averageTimeMicros,
        lessThan(5000), // 5ms
        reason: '평균 canPop 체크 시간은 5ms 이내여야 합니다 (NFR-003)',
      );
    });

    test('current getter should complete in <5ms', () {
      // Setup: 스택 준비
      notifier.state = NavigationState(
        stack: [
          const WorkspaceRoute.home(groupId: 1),
          const WorkspaceRoute.channel(groupId: 1, channelId: 10),
          const WorkspaceRoute.channel(groupId: 1, channelId: 20),
        ],
        currentIndex: 2,
      );

      final stopwatch = Stopwatch()..start();

      // 100번 current getter 호출
      for (int i = 0; i < 100; i++) {
        final current = notifier.state.current;
        expect(
            current, const WorkspaceRoute.channel(groupId: 1, channelId: 20));
      }

      stopwatch.stop();

      // 100번 호출이 모두 500ms(5ms * 100) 이내에 완료되어야 함
      expect(
        stopwatch.elapsedMicroseconds,
        lessThan(500000), // 500ms
        reason: '100번의 current getter 호출은 총 500ms 이내에 완료되어야 합니다',
      );

      // 평균 시간도 검증
      final averageTimeMicros = stopwatch.elapsedMicroseconds / 100;
      expect(
        averageTimeMicros,
        lessThan(5000), // 5ms
        reason: '평균 current getter 시간은 5ms 이내여야 합니다 (NFR-003)',
      );
    });

    test('navigation in large stack should maintain performance', () {
      // Setup: 50개 route 스택 생성
      final largeStack = List.generate(
        50,
        (i) => WorkspaceRoute.channel(groupId: 1, channelId: i),
      );
      notifier.state = NavigationState(
        stack: largeStack,
        currentIndex: 49,
      );

      final stopwatch = Stopwatch()..start();

      // 20번 pop 연산 (49 → 29)
      for (int i = 0; i < 20; i++) {
        notifier.pop();
      }

      stopwatch.stop();

      // 20번의 pop이 모두 100ms(5ms * 20) 이내에 완료되어야 함
      expect(
        stopwatch.elapsedMicroseconds,
        lessThan(100000), // 100ms
        reason: '20번의 pop 연산은 총 100ms 이내에 완료되어야 합니다',
      );

      // 평균 시간도 검증
      final averageTimeMicros = stopwatch.elapsedMicroseconds / 20;
      expect(
        averageTimeMicros,
        lessThan(5000), // 5ms
        reason: '평균 pop 시간은 5ms 이내여야 합니다 (NFR-003)',
      );

      expect(notifier.state.currentIndex, 29);
    });

    test('rapid navigation (forward/backward) should maintain performance', () {
      // Setup: 30개 route 스택 생성
      final stack = List.generate(
        30,
        (i) => WorkspaceRoute.channel(groupId: 1, channelId: i),
      );
      notifier.state = NavigationState(
        stack: stack,
        currentIndex: 15,
      );

      final stopwatch = Stopwatch()..start();

      // 전진 5번, 후진 5번, 전진 3번, 후진 3번 (총 16번 연산)
      for (int i = 0; i < 5; i++) {
        notifier.state = notifier.state.copyWith(
          currentIndex: notifier.state.currentIndex + 1,
        ); // forward
      }

      for (int i = 0; i < 5; i++) {
        notifier.pop(); // backward
      }

      for (int i = 0; i < 3; i++) {
        notifier.state = notifier.state.copyWith(
          currentIndex: notifier.state.currentIndex + 1,
        ); // forward
      }

      for (int i = 0; i < 3; i++) {
        notifier.pop(); // backward
      }

      stopwatch.stop();

      // 16번의 연산이 모두 80ms(5ms * 16) 이내에 완료되어야 함
      expect(
        stopwatch.elapsedMicroseconds,
        lessThan(80000), // 80ms
        reason: '16번의 네비게이션 연산은 총 80ms 이내에 완료되어야 합니다',
      );

      // 평균 시간도 검증
      final averageTimeMicros = stopwatch.elapsedMicroseconds / 16;
      expect(
        averageTimeMicros,
        lessThan(5000), // 5ms
        reason: '평균 네비게이션 시간은 5ms 이내여야 합니다 (NFR-003)',
      );

      expect(notifier.state.currentIndex, 15); // 15 + 5 - 5 + 3 - 3 = 15
    });

    test('isAtRoot check should complete in <5ms', () {
      // Setup: 스택 준비
      notifier.state = NavigationState(
        stack: [
          const WorkspaceRoute.home(groupId: 1),
          const WorkspaceRoute.channel(groupId: 1, channelId: 10),
        ],
        currentIndex: 0,
      );

      final stopwatch = Stopwatch()..start();

      // 100번 isAtRoot 체크
      for (int i = 0; i < 100; i++) {
        final isAtRoot = notifier.state.isAtRoot;
        expect(isAtRoot, isTrue);
      }

      stopwatch.stop();

      // 100번 체크가 모두 500ms(5ms * 100) 이내에 완료되어야 함
      expect(
        stopwatch.elapsedMicroseconds,
        lessThan(500000), // 500ms
        reason: '100번의 isAtRoot 체크는 총 500ms 이내에 완료되어야 합니다',
      );

      // 평균 시간도 검증
      final averageTimeMicros = stopwatch.elapsedMicroseconds / 100;
      expect(
        averageTimeMicros,
        lessThan(5000), // 5ms
        reason: '평균 isAtRoot 체크 시간은 5ms 이내여야 합니다 (NFR-003)',
      );
    });
  });
}
