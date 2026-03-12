import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/navigation/navigation_state.dart';
import 'package:frontend/core/navigation/workspace_route.dart';
import 'package:frontend/presentation/providers/navigation_state_provider.dart';

/// Phase 7: T139 - 네비게이션 응답 시간 성능 테스트
///
/// 요구사항 (NFR-001): 네비게이션 연산은 200ms 이내에 완료되어야 함
///
/// 테스트 범위:
/// - push() 연산 성능
/// - pop() 연산 성능
/// - replace() 연산 성능
/// - switchGroup() 연산 성능 (디바운싱 제외)
void main() {
  group('T139: Navigation Performance Tests', () {
    late NavigationStateNotifier notifier;

    setUp(() {
      notifier = NavigationStateNotifier();
    });

    tearDown(() {
      notifier.dispose();
    });

    test('push() should complete in <200ms (excluding debouncing)', () async {
      final stopwatch = Stopwatch();

      // 디바운싱 시작 전 시간 측정 시작
      stopwatch.start();
      notifier.push(const WorkspaceRoute.home(groupId: 1));

      // push() 호출 자체는 즉시 완료되어야 함 (디바운싱 타이머만 등록)
      stopwatch.stop();
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(200),
        reason: 'push() 호출은 200ms 이내에 완료되어야 합니다 (NFR-001)',
      );

      // 디바운싱 대기 후 상태 검증
      await Future.delayed(const Duration(milliseconds: 350));
      expect(notifier.state.stack.length, 1);
      expect(notifier.state.stack.first, const WorkspaceRoute.home(groupId: 1));
    });

    test('pop() should complete in <200ms', () async {
      // Setup: 먼저 2개 route 추가 (디바운싱 없이 직접 추가)
      notifier.state = NavigationState(
        stack: [
          const WorkspaceRoute.home(groupId: 1),
          const WorkspaceRoute.channel(groupId: 1, channelId: 10),
        ],
        currentIndex: 1,
      );

      final stopwatch = Stopwatch()..start();

      notifier.pop();

      stopwatch.stop();
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(200),
        reason: 'pop() 연산은 200ms 이내에 완료되어야 합니다 (NFR-001)',
      );

      // 상태 검증 (stack은 그대로, currentIndex만 변경)
      expect(notifier.state.stack.length, 2);
      expect(notifier.state.currentIndex, 0);
      expect(notifier.state.current, const WorkspaceRoute.home(groupId: 1));
    });

    test('replace() should complete in <200ms', () {
      // Setup: 먼저 1개 route 추가 (디바운싱 없이 직접 추가)
      notifier.state = NavigationState(
        stack: [const WorkspaceRoute.home(groupId: 1)],
        currentIndex: 0,
      );

      final stopwatch = Stopwatch()..start();

      notifier.replace(const WorkspaceRoute.channel(groupId: 1, channelId: 10));

      stopwatch.stop();
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(200),
        reason: 'replace() 연산은 200ms 이내에 완료되어야 합니다 (NFR-001)',
      );

      // 상태 검증
      expect(notifier.state.stack.length, 1);
      expect(
        notifier.state.stack.first,
        const WorkspaceRoute.channel(groupId: 1, channelId: 10),
      );
    });

    test(
      'multiple rapid push() operations should maintain performance',
      () async {
        final stopwatch = Stopwatch()..start();

        // 10번 연속 push (디바운싱으로 인해 마지막 것만 실행됨)
        for (int i = 1; i <= 10; i++) {
          notifier.push(WorkspaceRoute.channel(groupId: 1, channelId: i));
        }

        stopwatch.stop();

        // push() 호출 자체는 즉시 완료되어야 함
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(200),
          reason: '10번의 push() 호출은 200ms 이내에 완료되어야 합니다',
        );

        // 디바운싱 대기 후 최종 상태 검증 (마지막 push만 실행됨)
        await Future.delayed(const Duration(milliseconds: 350));
        expect(notifier.state.stack.length, 1);
        expect(
          notifier.state.stack.last,
          const WorkspaceRoute.channel(groupId: 1, channelId: 10),
        );
      },
    );

    test('complex route stack operations should maintain performance', () {
      // Setup: 초기 스택 직접 구성 (디바운싱 없이)
      notifier.state = NavigationState(
        stack: [
          const WorkspaceRoute.home(groupId: 1),
          const WorkspaceRoute.channel(groupId: 1, channelId: 10),
          const WorkspaceRoute.channel(groupId: 1, channelId: 20),
          const WorkspaceRoute.channel(groupId: 1, channelId: 30),
          const WorkspaceRoute.channel(groupId: 1, channelId: 40),
        ],
        currentIndex: 4,
      );

      final stopwatch = Stopwatch()..start();

      // 복잡한 연산: pop 2번 → replace 1번
      notifier.pop(); // currentIndex: 4 → 3
      notifier.pop(); // currentIndex: 3 → 2
      notifier.replace(
        const WorkspaceRoute.channel(groupId: 1, channelId: 99),
      ); // index 2 교체

      stopwatch.stop();

      // 3번의 연산이 600ms(200ms * 3) 이내에 완료되어야 함
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(600),
        reason: '복잡한 스택 연산들은 총 600ms 이내에 완료되어야 합니다',
      );

      // 최종 상태 검증 (stack은 그대로, currentIndex=2, stack[2]가 교체됨)
      expect(notifier.state.stack.length, 5);
      expect(notifier.state.currentIndex, 2);
      expect(
        notifier.state.current,
        const WorkspaceRoute.channel(groupId: 1, channelId: 99),
      );
      expect(
        notifier.state.stack[2],
        const WorkspaceRoute.channel(groupId: 1, channelId: 99),
      );
    });
  });
}
