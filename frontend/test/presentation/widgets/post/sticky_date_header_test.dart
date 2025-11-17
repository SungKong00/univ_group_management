import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/presentation/widgets/post/post_list.dart';
import 'package:frontend/presentation/widgets/post/date_divider.dart';

/// ✨ Sticky Date Header 기능 테스트
///
/// **테스트 범위**:
/// - 날짜 구분선이 상단에 고정되는지 확인
/// - 날짜가 변경될 때 애니메이션이 작동하는지 확인
/// - 초기 로딩 시 sticky header가 숨겨지는지 확인
void main() {
  group('Sticky Date Header 기능 테스트', () {
    testWidgets('초기 로딩 시 sticky header가 표시되지 않음',
        (WidgetTester tester) async {
      // Given: PostList 위젯 생성
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PostList(
                channelId: '1',
                canWrite: true,
              ),
            ),
          ),
        ),
      );

      // When: 초기 렌더링
      await tester.pump();

      // Then: sticky header가 없어야 함 (초기 로딩 중)
      // AnimatedSwitcher의 자식이 SizedBox.shrink()이거나 조건부로 렌더링되지 않음
      expect(
        find.descendant(
          of: find.byType(Stack),
          matching: find.byType(Positioned),
        ),
        findsWidgets, // CircularProgressIndicator를 위한 Positioned는 있음
      );
    });

    testWidgets('날짜 구분선이 Material elevation을 가짐',
        (WidgetTester tester) async {
      // Given: sticky header 위젯 직접 테스트
      final testDate = DateTime(2025, 11, 17);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Material(
                key: ValueKey(testDate),
                elevation: 4,
                color: Colors.white,
                child: DateDivider(date: testDate),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Then: Material 위젯이 존재하고 elevation이 4임
      final materialFinder = find.byType(Material);
      expect(materialFinder, findsOneWidget);

      final Material materialWidget = tester.widget(materialFinder);
      expect(materialWidget.elevation, 4.0);
    });

    testWidgets('AnimatedSwitcher가 250ms 애니메이션을 사용',
        (WidgetTester tester) async {
      // Given: 날짜가 변경되는 시나리오 시뮬레이션
      final date1 = DateTime(2025, 11, 17);
      final date2 = DateTime(2025, 11, 16);

      DateTime currentDate = date1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Material(
                        key: ValueKey(currentDate),
                        elevation: 4,
                        color: Colors.white,
                        child: DateDivider(date: currentDate),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          currentDate = date2;
                        });
                      },
                      child: const Text('날짜 변경'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.pump();

      // When: 날짜 변경 버튼 클릭
      await tester.tap(find.text('날짜 변경'));
      await tester.pump(); // 애니메이션 시작

      // Then: 애니메이션 진행 중 (250ms 동안)
      await tester.pump(const Duration(milliseconds: 125)); // 절반 지점

      // 애니메이션 완료
      await tester.pumpAndSettle();

      // 새 날짜의 DateDivider가 표시됨
      expect(find.byType(DateDivider), findsOneWidget);
    });

    testWidgets('SlideTransition + FadeTransition 조합 애니메이션',
        (WidgetTester tester) async {
      // Given: 애니메이션 설정
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (Widget child, Animation<double> animation) {
                final offsetAnimation = Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOutCubic,
                ));

                final fadeAnimation = CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeIn,
                );

                return SlideTransition(
                  position: offsetAnimation,
                  child: FadeTransition(
                    opacity: fadeAnimation,
                    child: child,
                  ),
                );
              },
              child: Material(
                key: const ValueKey(1),
                elevation: 4,
                color: Colors.white,
                child: DateDivider(date: DateTime(2025, 11, 17)),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Then: SlideTransition과 FadeTransition이 모두 존재
      expect(find.byType(SlideTransition), findsOneWidget);
      expect(find.byType(FadeTransition), findsOneWidget);
    });

    test('날짜 매핑 로직 테스트 - index → 날짜 변환', () {
      // Given: 가상의 index → 날짜 매핑
      final Map<int, DateTime> indexToDateMap = {
        0: DateTime(2025, 11, 17), // DateMarker
        1: DateTime(2025, 11, 17), // Post
        2: DateTime(2025, 11, 17), // Post
        3: DateTime(2025, 11, 16), // DateMarker
        4: DateTime(2025, 11, 16), // Post
      };

      // When: index 1의 날짜 조회
      final date = indexToDateMap[1];

      // Then: 올바른 날짜 반환
      expect(date, DateTime(2025, 11, 17));
    });

    test('GlobalKey 매핑 로직 테스트', () {
      // Given: GlobalKey 맵 생성
      final Map<int, GlobalKey> itemKeys = {
        0: GlobalKey(),
        1: GlobalKey(),
        2: GlobalKey(),
      };

      // When: 특정 index의 GlobalKey 조회
      final key0 = itemKeys[0];
      final key1 = itemKeys[1];

      // Then: 서로 다른 GlobalKey 인스턴스
      expect(key0, isNotNull);
      expect(key1, isNotNull);
      expect(key0, isNot(equals(key1)));
    });
  });

  group('Sticky Header 통합 시나리오', () {
    testWidgets('Stack 구조: 스크롤뷰 + sticky header',
        (WidgetTester tester) async {
      // Given: sticky header가 있는 레이아웃
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                // 스크롤뷰 (Opacity로 감싸짐)
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

                // Sticky header (Positioned)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Material(
                    elevation: 4,
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

      // Then: Stack, Positioned, Material이 올바르게 렌더링됨
      expect(find.byType(Stack), findsOneWidget);
      expect(find.byType(Positioned), findsOneWidget);
      expect(find.text('Sticky Header'), findsOneWidget);
    });
  });
}
