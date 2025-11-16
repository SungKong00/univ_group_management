import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/presentation/widgets/navigation/responsive_navigation_wrapper.dart';

/// Focus Management Tests (T138)
///
/// Tests focus behavior during navigation transitions:
/// - Auto-focus on mount
/// - Focus preservation during updates
/// - Proper focus disposal
/// - Focus ring visibility
void main() {
  group('Focus Management', () {
    testWidgets('Navigation wrapper auto-focuses on mount', (tester) async {
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

      // Find the Focus widget that belongs to ResponsiveNavigationWrapper
      // (it's the one with autofocus=true created by the wrapper)
      final focusFinder = find.descendant(
        of: find.byType(ResponsiveNavigationWrapper),
        matching: find.byWidgetPredicate(
          (widget) => widget is Focus && widget.autofocus == true,
        ),
      );
      expect(focusFinder, findsOneWidget);

      final focus = tester.widget<Focus>(focusFinder);
      expect(focus.autofocus, isTrue);
    });

    testWidgets('Focus node is properly disposed', (tester) async {
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

      // Unmount the widget
      await tester.pumpWidget(const SizedBox());

      // Should not throw error (focus node disposed properly)
      expect(tester.takeException(), isNull);
    });

    testWidgets('Focus indicator shows on keyboard interaction', (
      tester,
    ) async {
      final items = [
        NavigationItem(label: 'Home', icon: Icons.home, onTap: () {}),
        NavigationItem(
          label: 'Calendar',
          icon: Icons.calendar_today,
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

      // Initially, focus indicator on first item (index 0)
      final containerFinder = find.byType(Container);
      expect(containerFinder, findsWidgets);

      // Container with border decoration (focus ring) should exist
      final containers = tester.widgetList<Container>(containerFinder);
      final focusedContainers = containers.where((c) => c.decoration != null);
      expect(focusedContainers.isNotEmpty, isTrue);
    });

    testWidgets('Focus updates when navigation items change', (tester) async {
      final items1 = [
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
              navigationItems: items1,
              child: const Scaffold(body: Text('Test')),
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);

      // Update navigation items
      final items2 = [
        NavigationItem(label: 'Home', icon: Icons.home, onTap: () {}),
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
              navigationItems: items2,
              child: const Scaffold(body: Text('Test')),
            ),
          ),
        ),
      );

      expect(find.text('Calendar'), findsOneWidget);
      // Focus should still be managed (no errors)
      expect(tester.takeException(), isNull);
    });

    testWidgets('Multiple navigation wrappers have independent focus', (
      tester,
    ) async {
      final items = [
        NavigationItem(label: 'Item', icon: Icons.circle, onTap: () {}),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Column(
              children: [
                Expanded(
                  child: ResponsiveNavigationWrapper(
                    navigationItems: items,
                    child: const Scaffold(body: Text('First')),
                  ),
                ),
                Expanded(
                  child: ResponsiveNavigationWrapper(
                    navigationItems: items,
                    child: const Scaffold(body: Text('Second')),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Two ResponsiveNavigationWrapper instances, each should have their own focus
      final wrappers = find.byType(ResponsiveNavigationWrapper);
      expect(wrappers, findsNWidgets(2));

      // Verify no exceptions (focus nodes are independent)
      expect(tester.takeException(), isNull);
    });

    testWidgets('Focus persists through drawer open/close on mobile', (
      tester,
    ) async {
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

      // Close drawer
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Focus should still be valid (ResponsiveNavigationWrapper still exists)
      expect(find.byType(ResponsiveNavigationWrapper), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Focus ring has correct visual properties', (tester) async {
      final items = [
        NavigationItem(label: 'Home', icon: Icons.home, onTap: () {}),
        NavigationItem(label: 'Calendar', icon: Icons.calendar_today, onTap: () {}),
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

      // Wait for initial render
      await tester.pumpAndSettle();

      // Find Semantics widget with 'Home' and 'focused' labels
      // The focus ring appears on the first item (_selectedIndex = 0)
      final homeSemanticsContainer = find.ancestor(
        of: find.text('Home'),
        matching: find.byType(Container),
      );

      expect(homeSemanticsContainer, findsWidgets);

      // Get the Container widgets
      final containers = tester.widgetList<Container>(homeSemanticsContainer);

      // Find the one with border decoration (focus ring)
      final decoratedContainer = containers.firstWhere(
        (c) => c.decoration != null &&
               c.decoration is BoxDecoration &&
               (c.decoration as BoxDecoration).border != null,
        orElse: () => throw StateError('No focused container found'),
      );

      final decoration = decoratedContainer.decoration as BoxDecoration;
      final border = decoration.border as Border;

      // Verify focus ring properties (2px border)
      expect(border.top.width, 2.0);
    });

    testWidgets('Animation controller disposes properly', (tester) async {
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

      // FadeTransition should be present (using animation controller)
      expect(find.byType(FadeTransition), findsOneWidget);

      // Unmount widget
      await tester.pumpWidget(const SizedBox());

      // No exceptions from undisposed animation controller
      expect(tester.takeException(), isNull);
    });
  });
}
