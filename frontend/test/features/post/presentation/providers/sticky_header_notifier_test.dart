import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/post/presentation/providers/sticky_header_notifier.dart';

void main() {
  group('StickyHeaderNotifier Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('초기 상태는 date가 null', () {
      // When
      final state = container.read(stickyHeaderProvider);

      // Then
      expect(state.date, isNull);
    });

    test('registerDateHeader() - 날짜 헤더 키 등록', () {
      // Given
      final notifier = container.read(stickyHeaderProvider.notifier);
      final date = DateTime(2025, 1, 15);

      // When
      final key = notifier.registerDateHeader(0, date);

      // Then
      expect(key, isNotNull);
      expect(key, isA<GlobalKey>());
    });

    test('registerDateHeader() - 같은 인덱스는 같은 키 반환', () {
      // Given
      final notifier = container.read(stickyHeaderProvider.notifier);
      final date1 = DateTime(2025, 1, 15);
      final date2 = DateTime(2025, 1, 16);

      // When
      final key1 = notifier.registerDateHeader(0, date1);
      final key2 = notifier.registerDateHeader(0, date2);

      // Then
      expect(key1, equals(key2)); // 같은 인덱스는 키 재사용
    });

    test('registerDateHeader() - 다른 인덱스는 다른 키', () {
      // Given
      final notifier = container.read(stickyHeaderProvider.notifier);
      final date1 = DateTime(2025, 1, 15);
      final date2 = DateTime(2025, 1, 16);

      // When
      final key1 = notifier.registerDateHeader(0, date1);
      final key2 = notifier.registerDateHeader(1, date2);

      // Then
      expect(key1, isNot(equals(key2)));
    });

    testWidgets('updateStickyDate() - 임계값 아래 항목을 Sticky로 설정',
        (tester) async {
      // Given
      final notifier = container.read(stickyHeaderProvider.notifier);
      final date1 = DateTime(2025, 1, 15);
      final date2 = DateTime(2025, 1, 16);

      final key1 = notifier.registerDateHeader(0, date1);
      final key2 = notifier.registerDateHeader(1, date2);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Container(key: key1, height: 50, color: Colors.red),
                Container(key: key2, height: 50, color: Colors.blue),
                const SizedBox(height: 500),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When
      notifier.updateStickyDate(100.0); // 임계값 100px

      // Then
      final state = container.read(stickyHeaderProvider);
      // 첫 번째 Container (50px)가 임계값(100px) 아래에 있음
      expect(state.date, equals(date1));
    });

    testWidgets('updateStickyDate() - 날짜 변경 시에만 상태 업데이트', (tester) async {
      // Given
      final notifier = container.read(stickyHeaderProvider.notifier);
      final date = DateTime(2025, 1, 15);

      final key = notifier.registerDateHeader(0, date);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(key: key, height: 50),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When - 첫 업데이트
      notifier.updateStickyDate(100.0);
      final state1 = container.read(stickyHeaderProvider);

      // When - 동일한 날짜로 다시 업데이트
      notifier.updateStickyDate(100.0);
      final state2 = container.read(stickyHeaderProvider);

      // Then - 같은 인스턴스 (rebuild 안 함)
      expect(state1, equals(state2));
    });

    test('reset() - 모든 상태 초기화', () {
      // Given
      final notifier = container.read(stickyHeaderProvider.notifier);
      final date = DateTime(2025, 1, 15);

      notifier.registerDateHeader(0, date);
      notifier.registerDateHeader(1, DateTime(2025, 1, 16));

      // When
      notifier.reset();

      // Then
      final state = container.read(stickyHeaderProvider);
      expect(state.date, isNull);
    });

    test('dispose 시 키와 날짜 맵 정리', () {
      // Given
      final notifier = container.read(stickyHeaderProvider.notifier);
      notifier.registerDateHeader(0, DateTime(2025, 1, 15));
      notifier.registerDateHeader(1, DateTime(2025, 1, 16));

      // When
      container.dispose();

      // Then - dispose 후에도 에러 없이 종료
      expect(() => container.read(stickyHeaderProvider), throwsStateError);
    });

    testWidgets('복잡한 시나리오 - 여러 날짜 헤더 중 Sticky 선택',
        (tester) async {
      // Given
      final notifier = container.read(stickyHeaderProvider.notifier);
      final date1 = DateTime(2025, 1, 14);
      final date2 = DateTime(2025, 1, 15);
      final date3 = DateTime(2025, 1, 16);

      final key1 = notifier.registerDateHeader(0, date1);
      final key2 = notifier.registerDateHeader(1, date2);
      final key3 = notifier.registerDateHeader(2, date3);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  Container(key: key1, height: 50, color: Colors.red),
                  const SizedBox(height: 100),
                  Container(key: key2, height: 50, color: Colors.green),
                  const SizedBox(height: 100),
                  Container(key: key3, height: 50, color: Colors.blue),
                  const SizedBox(height: 500),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When - 스크롤 전
      notifier.updateStickyDate(100.0);
      final stateBefore = container.read(stickyHeaderProvider);

      // Then - 첫 번째 날짜가 Sticky (50px < 100px 임계값)
      expect(stateBefore.date, equals(date1));

      // When - 스크롤 후
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -150));
      await tester.pumpAndSettle();

      notifier.updateStickyDate(100.0);
      final stateAfter = container.read(stickyHeaderProvider);

      // Then - 스크롤 후에도 유효한 날짜 표시
      expect(stateAfter.date, isNotNull);
      // 스크롤 방향에 따라 date1 또는 date2가 sticky됨
      expect([date1, date2].contains(stateAfter.date), isTrue);
    });

    test('copyWith() - 상태 복사', () {
      // Given
      final state = const StickyHeaderState(date: null);

      // When
      final newDate = DateTime(2025, 1, 15);
      final newState = state.copyWith(date: newDate);

      // Then
      expect(newState.date, equals(newDate));
      expect(state.date, isNull); // 원본 불변
    });
  });
}
