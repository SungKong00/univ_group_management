import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/post/presentation/providers/read_position_notifier.dart';

void main() {
  group('ReadPositionNotifier Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('초기 상태는 null', () {
      // When
      final state = container.read(readPositionProvider);

      // Then
      expect(state, isNull);
    });

    test('updateVisibility() - 게시글이 보이면 visiblePostIds에 추가', () async {
      // Given
      final notifier = container.read(readPositionProvider.notifier);

      // When
      notifier.updateVisibility(1, true);
      await Future.delayed(const Duration(milliseconds: 250)); // 디바운스 대기

      // Then
      final state = container.read(readPositionProvider);
      expect(state, 1); // Riverpod state 검증
      expect(notifier.highestReadId, 1); // 내부 상태 검증
    });

    test('updateVisibility() - 여러 게시글 중 최대값이 읽음 위치', () async {
      // Given
      final notifier = container.read(readPositionProvider.notifier);

      // When
      notifier.updateVisibility(1, true);
      notifier.updateVisibility(3, true);
      notifier.updateVisibility(2, true);
      await Future.delayed(const Duration(milliseconds: 250)); // 디바운스 대기

      // Then
      final state = container.read(readPositionProvider);
      expect(state, 3);
      expect(notifier.highestReadId, 3);
    });

    test('updateVisibility() - 200ms 디바운스 동작', () async {
      // Given
      final notifier = container.read(readPositionProvider.notifier);
      int callCount = 0;
      notifier.setOnReadPositionUpdate((postId) {
        callCount++;
      });

      // When
      notifier.updateVisibility(1, true);
      notifier.updateVisibility(2, true);
      notifier.updateVisibility(3, true);
      await Future.delayed(const Duration(milliseconds: 100)); // 디바운스 중간

      // Then
      expect(callCount, 0); // 아직 호출되지 않음

      // When
      await Future.delayed(const Duration(milliseconds: 150)); // 총 250ms

      // Then
      expect(callCount, 1); // 1번만 호출됨
      expect(notifier.highestReadId, 3);
    });

    test('updateVisibility() - 가시성 false이면 visiblePostIds에서 제거', () async {
      // Given
      final notifier = container.read(readPositionProvider.notifier);

      notifier.updateVisibility(1, true);
      notifier.updateVisibility(2, true);
      await Future.delayed(const Duration(milliseconds: 250));

      var state = container.read(readPositionProvider);
      expect(state, 2);
      expect(notifier.highestReadId, 2);

      // When
      notifier.updateVisibility(2, false); // 2번 제거
      notifier.updateVisibility(3, true); // 3번 추가
      await Future.delayed(const Duration(milliseconds: 250));

      // Then
      state = container.read(readPositionProvider);
      expect(state, 3); // 최대값이 3
      expect(notifier.highestReadId, 3);
    });

    test('highestReadId - 절대 감소하지 않음', () async {
      // Given
      final notifier = container.read(readPositionProvider.notifier);

      // When
      notifier.updateVisibility(5, true);
      await Future.delayed(const Duration(milliseconds: 250));

      var state = container.read(readPositionProvider);
      expect(state, 5);
      expect(notifier.highestReadId, 5);

      notifier.updateVisibility(5, false); // 5번 제거
      notifier.updateVisibility(3, true); // 3번 추가 (더 작은 값)
      await Future.delayed(const Duration(milliseconds: 250));

      // Then
      state = container.read(readPositionProvider);
      expect(state, 5); // 여전히 5 (감소 안 함)
      expect(notifier.highestReadId, 5);
    });

    test('setOnReadPositionUpdate() - 콜백 호출 확인', () async {
      // Given
      final notifier = container.read(readPositionProvider.notifier);
      int? capturedPostId;

      notifier.setOnReadPositionUpdate((postId) {
        capturedPostId = postId;
      });

      // When
      notifier.updateVisibility(7, true);
      await Future.delayed(const Duration(milliseconds: 250));

      // Then
      final state = container.read(readPositionProvider);
      expect(state, 7);
      expect(capturedPostId, 7);
    });

    test('reset() - 모든 상태 초기화', () async {
      // Given
      final notifier = container.read(readPositionProvider.notifier);

      notifier.updateVisibility(1, true);
      notifier.updateVisibility(2, true);
      await Future.delayed(const Duration(milliseconds: 250));

      var state = container.read(readPositionProvider);
      expect(state, 2);
      expect(notifier.highestReadId, 2);

      // When
      notifier.reset();

      // Then
      state = container.read(readPositionProvider);
      expect(state, isNull);
      expect(notifier.highestReadId, isNull);
    });

    test('dispose 시 타이머 정리', () async {
      // Given
      final notifier = container.read(readPositionProvider.notifier);

      notifier.updateVisibility(1, true);
      await Future.delayed(const Duration(milliseconds: 100));

      // When
      container.dispose();

      // Then - dispose 후에도 에러 없이 종료
      await Future.delayed(const Duration(milliseconds: 200));
      // 타이머가 정리되어 콜백이 호출되지 않음
    });
  });
}
