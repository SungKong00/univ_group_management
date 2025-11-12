import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/presentation/providers/navigation_state_provider.dart';

/// Phase 7: T145.1 - 시각 피드백 애니메이션 테스트
///
/// 요구사항:
/// - T105: 로딩 인디케이터 표시 (2초 threshold)
/// - T106: 로딩 취소 기능
/// - 상태 전환 성능 (<200ms)
///
/// 테스트 범위:
/// - 로딩 상태 관리
/// - 로딩 메시지 설정
/// - 로딩 취소 기능
/// - 상태 전환 성능
void main() {
  group('T145.1: Visual Feedback Animation Tests', () {
    late NavigationStateNotifier notifier;

    setUp(() {
      notifier = NavigationStateNotifier();
    });

    tearDown(() {
      notifier.dispose();
    });

    test('loading state should be set correctly', () {
      // 초기 상태: 로딩 없음
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.loadingMessage, isNull);

      // T105: 로딩 시작
      notifier.state = notifier.state.copyWith(
        isLoading: true,
        loadingMessage: '그룹 전환 중...',
      );

      expect(notifier.state.isLoading, isTrue);
      expect(notifier.state.loadingMessage, '그룹 전환 중...');
    });

    test('loading message can be customized', () {
      // 커스텀 메시지 테스트
      notifier.state = notifier.state.copyWith(
        isLoading: true,
        loadingMessage: '권한 확인 중...',
      );

      expect(notifier.state.isLoading, isTrue);
      expect(notifier.state.loadingMessage, '권한 확인 중...');
    });

    test('T106: loading can be cancelled', () {
      // 로딩 시작
      notifier.state = notifier.state.copyWith(
        isLoading: true,
        loadingMessage: '데이터 로딩 중...',
      );

      expect(notifier.state.isLoading, isTrue);

      // T106: 로딩 취소
      notifier.cancelLoading();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.loadingMessage, isNull);
    });

    test('loading state transition should complete in <200ms', () {
      final stopwatch = Stopwatch()..start();

      // 로딩 상태 10번 전환
      for (int i = 0; i < 10; i++) {
        notifier.state = notifier.state.copyWith(
          isLoading: true,
          loadingMessage: '처리 중 $i...',
        );

        notifier.state = notifier.state.copyWith(
          isLoading: false,
          loadingMessage: null,
        );
      }

      stopwatch.stop();

      // 10번의 상태 전환 (20번의 copyWith)이 2000ms(200ms * 10) 이내에 완료되어야 함
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(2000), // 2초
        reason: '10번의 로딩 상태 전환은 총 2초 이내에 완료되어야 합니다',
      );

      // 평균 시간도 검증
      final averageTimeMillis = stopwatch.elapsedMilliseconds / 10;
      expect(
        averageTimeMillis,
        lessThan(200), // 200ms
        reason: '평균 상태 전환 시간은 200ms 이내여야 합니다',
      );
    });

    test('rapid loading state changes should maintain performance', () {
      final stopwatch = Stopwatch()..start();

      // 50번 연속 로딩 상태 변경
      for (int i = 0; i < 50; i++) {
        notifier.state = notifier.state.copyWith(
          isLoading: !notifier.state.isLoading,
          loadingMessage: notifier.state.isLoading ? null : '처리 중 $i...',
        );
      }

      stopwatch.stop();

      // 50번의 상태 변경이 모두 5초(100ms * 50) 이내에 완료되어야 함
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(5000), // 5초
        reason: '50번의 상태 변경은 5초 이내에 완료되어야 합니다',
      );

      // 평균 시간도 검증
      final averageTimeMillis = stopwatch.elapsedMilliseconds / 50;
      expect(
        averageTimeMillis,
        lessThan(100), // 100ms
        reason: '평균 상태 변경 시간은 100ms 이내여야 합니다',
      );
    });

    test('cancelLoading should reset both isLoading and loadingMessage', () {
      // 로딩 상태 설정
      notifier.state = notifier.state.copyWith(
        isLoading: true,
        loadingMessage: '복잡한 작업 처리 중...',
      );

      expect(notifier.state.isLoading, isTrue);
      expect(notifier.state.loadingMessage, isNotNull);

      // 취소
      notifier.cancelLoading();

      // 모두 초기화되어야 함
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.loadingMessage, isNull);
    });

    test('multiple consecutive cancelLoading calls should be safe', () {
      // 로딩 상태 설정
      notifier.state = notifier.state.copyWith(
        isLoading: true,
        loadingMessage: '작업 중...',
      );

      // 여러 번 취소 호출 (안전성 검증)
      notifier.cancelLoading();
      notifier.cancelLoading();
      notifier.cancelLoading();

      // 상태는 여전히 초기화되어 있어야 함
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.loadingMessage, isNull);
    });
  });
}
