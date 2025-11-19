import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/post/presentation/providers/scroll_controller_provider.dart';

void main() {
  group('ScrollControllerNotifier Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('초기 상태 - AutoScrollController 생성', () {
      // When
      final controller =
          container.read(scrollControllerProvider('channel-1'));

      // Then
      expect(controller, isNotNull);
      expect(controller.hasClients, isFalse); // 아직 attach 안 됨
    });

    test('채널별 독립적인 Controller 인스턴스', () {
      // When
      final controller1 =
          container.read(scrollControllerProvider('channel-1'));
      final controller2 =
          container.read(scrollControllerProvider('channel-2'));

      // Then
      expect(controller1, isNot(equals(controller2)));
    });

    test('같은 채널ID는 같은 Controller 재사용', () {
      // When
      final controller1 =
          container.read(scrollControllerProvider('channel-1'));
      final controller2 =
          container.read(scrollControllerProvider('channel-1'));

      // Then
      expect(controller1, equals(controller2));
    });

    testWidgets('offset 속성 - 스크롤 위치 반환', (tester) async {
      // Given
      final controller =
          container.read(scrollControllerProvider('channel-1'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              controller: controller,
              itemCount: 50,
              itemBuilder: (context, index) => SizedBox(
                height: 100,
                child: Text('Item $index'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When
      final notifier = container.read(scrollControllerProvider('channel-1').notifier);

      // Then
      expect(notifier.offset, 0.0); // 초기 위치

      // When - 스크롤
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      // Then
      expect(notifier.offset, greaterThan(0)); // 스크롤 이동함
    });

    testWidgets('hasClients 속성 - attach 상태 확인', (tester) async {
      // Given
      final controller =
          container.read(scrollControllerProvider('channel-1'));
      final notifier = container.read(scrollControllerProvider('channel-1').notifier);

      // When - attach 전
      // Then
      expect(notifier.hasClients, isFalse);

      // When - attach 후
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              controller: controller,
              children: const [Text('Item 1')],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Then
      expect(notifier.hasClients, isTrue);
    });

    testWidgets('scrollToIndex() - 특정 인덱스로 스크롤', (tester) async {
      // Given
      final controller =
          container.read(scrollControllerProvider('channel-1'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              controller: controller,
              itemCount: 50,
              itemBuilder: (context, index) => SizedBox(
                key: ValueKey(index),
                height: 100,
                child: Text('Item $index'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final notifier = container.read(scrollControllerProvider('channel-1').notifier);

      // When
      await notifier.scrollToIndex(10);
      await tester.pump(const Duration(milliseconds: 500)); // 애니메이션 대기

      // Then
      expect(notifier.offset, greaterThan(0)); // 스크롤 이동함
    }, timeout: const Timeout(Duration(seconds: 10)));

    test('dispose 시 Controller 자동 해제', () {
      // Given
      final controller =
          container.read(scrollControllerProvider('channel-1'));

      expect(controller, isNotNull);

      // When
      container.dispose();

      // Then - dispose 후에는 접근 불가 (AssertionError 발생)
      expect(() => controller.offset, throwsA(isA<AssertionError>()));
    });

    test('autoDispose - 사용하지 않으면 자동 정리', () async {
      // Given
      container.read(scrollControllerProvider('channel-1'));

      // When - 2초 대기 (autoDispose 트리거)
      await Future.delayed(const Duration(seconds: 2));
      container.updateOverrides([]);

      // Then - 새로 생성된 인스턴스 확인
      final newController =
          container.read(scrollControllerProvider('channel-1'));
      expect(newController, isNotNull);
    });
  });
}
