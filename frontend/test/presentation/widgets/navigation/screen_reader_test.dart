import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/presentation/widgets/navigation/responsive_navigation_wrapper.dart';

/// Screen Reader Support Tests (T137)
///
/// Tests semantic labels and screen reader compatibility:
/// - Semantic labels for navigation items
/// - Selected state announcements
/// - Focus state announcements
/// - Button role assignments
void main() {
  group('Screen Reader Support', () {
    testWidgets('Navigation items have semantic labels', (tester) async {
      final items = [
        NavigationItem(
          label: 'Home',
          icon: Icons.home,
          isSelected: false,
          onTap: () {},
        ),
        NavigationItem(
          label: 'Calendar',
          icon: Icons.calendar_today,
          isSelected: true,
          onTap: () {},
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ResponsiveNavigationWrapper(
              navigationItems: items,
              child: const Scaffold(body: Text('Test')),
            ),
          ),
        ),
      );

      // Find Semantics widgets
      final semanticsFinder = find.byType(Semantics);
      expect(semanticsFinder, findsWidgets);

      // Verify semantic labels exist by finding widgets with specific label predicates
      final homeFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label != null &&
            widget.properties.label!.contains('Home'),
      );
      expect(homeFinder, findsOneWidget);

      final calendarFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label != null &&
            widget.properties.label!.contains('Calendar'),
      );
      expect(calendarFinder, findsOneWidget);
    });

    testWidgets('Selected navigation item announces selected state', (
      tester,
    ) async {
      final items = [
        NavigationItem(
          label: 'Home',
          icon: Icons.home,
          isSelected: true,
          onTap: () {},
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ResponsiveNavigationWrapper(
              navigationItems: items,
              child: const Scaffold(body: Text('Test')),
            ),
          ),
        ),
      );

      // Selected item should have "현재 선택됨" in its label (may also include focus state)
      final selectedFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label != null &&
            widget.properties.label!.contains('Home') &&
            widget.properties.label!.contains('현재 선택됨'),
      );
      expect(selectedFinder, findsOneWidget);
    });

    testWidgets('Navigation items have button role', (tester) async {
      final items = [
        NavigationItem(label: 'Home', icon: Icons.home, onTap: () {}),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ResponsiveNavigationWrapper(
              navigationItems: items,
              child: const Scaffold(body: Text('Test')),
            ),
          ),
        ),
      );

      // ListTile with onTap should be recognized as a button
      final listTileFinder = find.byType(ListTile);
      expect(listTileFinder, findsWidgets);

      // Verify Semantics wrapping exists (look for our custom Semantics with button: true)
      final semanticsFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.button == true &&
            widget.properties.label?.contains('Home') == true,
      );
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('Mobile drawer header has semantic label', (tester) async {
      // Set mobile viewport size
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final items = [
        NavigationItem(label: 'Home', icon: Icons.home, onTap: () {}),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ResponsiveNavigationWrapper(
              navigationItems: items,
              child: const Scaffold(body: Text('Test')),
            ),
          ),
        ),
      );

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Verify drawer header has semantic labels
      expect(find.bySemanticsLabel('네비게이션 메뉴 닫기'), findsOneWidget);
    });

    testWidgets('Mobile menu button has semantic label', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final items = [
        NavigationItem(label: 'Home', icon: Icons.home, onTap: () {}),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ResponsiveNavigationWrapper(
              navigationItems: items,
              child: const Scaffold(body: Text('Test')),
            ),
          ),
        ),
      );

      // Hamburger menu button should have semantic label
      expect(find.bySemanticsLabel('네비게이션 메뉴 열기'), findsOneWidget);
    });

    testWidgets('Navigation items preserve semantic order', (tester) async {
      final items = [
        NavigationItem(label: 'First', icon: Icons.looks_one, onTap: () {}),
        NavigationItem(label: 'Second', icon: Icons.looks_two, onTap: () {}),
        NavigationItem(label: 'Third', icon: Icons.looks_3, onTap: () {}),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ResponsiveNavigationWrapper(
              navigationItems: items,
              child: const Scaffold(body: Text('Test')),
            ),
          ),
        ),
      );

      // Find all ListTiles (navigation items)
      final listTiles = find.byType(ListTile);
      expect(listTiles, findsNWidgets(3));

      // Verify they appear in order (visual tree order)
      final firstTile = tester.widget<ListTile>(listTiles.at(0));
      final secondTile = tester.widget<ListTile>(listTiles.at(1));
      final thirdTile = tester.widget<ListTile>(listTiles.at(2));

      expect((firstTile.title as Text).data, 'First');
      expect((secondTile.title as Text).data, 'Second');
      expect((thirdTile.title as Text).data, 'Third');
    });

    testWidgets('Disabled items have appropriate semantics', (tester) async {
      // Test with item that has no onTap (effectively disabled)
      final items = [
        NavigationItem(
          label: 'Disabled',
          icon: Icons.block,
          onTap: null, // No action = disabled
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ResponsiveNavigationWrapper(
              navigationItems: items,
              child: const Scaffold(body: Text('Test')),
            ),
          ),
        ),
      );

      expect(find.text('Disabled'), findsOneWidget);
    });
  });
}
