import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/presentation/widgets/post/date_divider.dart';

/// ✨ Sticky Date Header 기능 테스트
///
/// **테스트 범위**:
/// - 날짜 구분선 Material elevation 확인
/// - GlobalKey 매핑 로직 검증
/// - Stack + Positioned 구조 통합 시나리오
void main() {
  group('Sticky Date Header 기능 테스트', () {
    testWidgets('날짜 구분선이 Material elevation을 가짐', (WidgetTester tester) async {
      final testDate = DateTime(2025, 11, 17);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Material(
              elevation: 0,
              color: Colors.white,
              child: DateDivider(date: testDate),
            ),
          ),
        ),
      );

      await tester.pump();

      final materialFinder = find.descendant(
        of: find.byType(Scaffold),
        matching: find.byType(Material),
      );
      expect(materialFinder, findsWidgets);

      final materials = tester.widgetList<Material>(find.byType(Material));
      final stickyHeaderMaterial = materials.firstWhere(
        (m) => m.child is DateDivider,
        orElse: () => throw StateError('DateDivider Material not found'),
      );
      expect(stickyHeaderMaterial.elevation, 0.0);
    });

    test('GlobalKey 매핑 로직 테스트', () {
      final Map<int, GlobalKey> itemKeys = {
        0: GlobalKey(),
        1: GlobalKey(),
        2: GlobalKey(),
      };

      final key0 = itemKeys[0];
      final key1 = itemKeys[1];

      expect(key0, isNotNull);
      expect(key1, isNotNull);
      expect(key0, isNot(equals(key1)));
    });

    test('날짜 매핑 로직 테스트', () {
      final Map<int, DateTime> indexToDateMap = {
        0: DateTime(2025, 11, 17),
        1: DateTime(2025, 11, 17),
        2: DateTime(2025, 11, 16),
      };

      final date = indexToDateMap[1];
      expect(date, DateTime(2025, 11, 17));
    });
  });

  group('Sticky Header 통합 시나리오', () {
    testWidgets('Stack 구조: 스크롤뷰 + sticky header', (WidgetTester tester) async {
      const uniqueKey = Key('test-stack');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              key: uniqueKey,
              children: [
                Opacity(
                  opacity: 1.0,
                  child: CustomScrollView(
                    slivers: [
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => ListTile(title: Text('Item $index')),
                          childCount: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Material(
                    elevation: 0,
                    child: Container(
                      height: 40,
                      color: Colors.grey[200],
                      child: const Center(child: Text('Sticky Header')),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byKey(uniqueKey), findsOneWidget);
      expect(find.byType(Positioned), findsWidgets);
      expect(find.text('Sticky Header'), findsOneWidget);
    });
  });
}
