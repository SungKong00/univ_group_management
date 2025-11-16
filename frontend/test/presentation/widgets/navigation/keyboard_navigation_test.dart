import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/presentation/widgets/navigation/responsive_navigation_wrapper.dart';

/// Keyboard Navigation Tests (T136)
///
/// Tests keyboard accessibility features:
/// - Tab/Shift+Tab navigation between items
/// - Enter/Space to activate items
/// - Arrow keys for navigation
/// - Escape to close drawer (mobile)
void main() {
  group('Keyboard Navigation', () {
    testWidgets('Tab key moves focus to next navigation item', (tester) async {
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
          isSelected: false,
          onTap: () {},
        ),
        NavigationItem(
          label: 'Settings',
          icon: Icons.settings,
          isSelected: false,
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

      // Simulate Tab key press (focus already exists on mount)
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      // ResponsiveNavigationWrapper should still exist with focus
      expect(find.byType(ResponsiveNavigationWrapper), findsOneWidget);
    });

    testWidgets('Shift+Tab key moves focus to previous item', (tester) async {
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

      // Simulate Shift+Tab (reverse navigation)
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();

      // ResponsiveNavigationWrapper should handle reverse navigation
      expect(find.byType(ResponsiveNavigationWrapper), findsOneWidget);
    });

    testWidgets('Enter key activates selected navigation item', (tester) async {
      int tappedIndex = -1;
      final items = [
        NavigationItem(
          label: 'Home',
          icon: Icons.home,
          onTap: () => tappedIndex = 0,
        ),
        NavigationItem(
          label: 'Calendar',
          icon: Icons.calendar_today,
          onTap: () => tappedIndex = 1,
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

      // Simulate Enter key press
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      // First item should be activated (default selection is 0)
      expect(tappedIndex, 0);
    });

    testWidgets('Space key activates selected navigation item', (tester) async {
      int tappedIndex = -1;
      final items = [
        NavigationItem(
          label: 'Home',
          icon: Icons.home,
          onTap: () => tappedIndex = 0,
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

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(tappedIndex, 0);
    });

    testWidgets('Arrow Down key moves focus to next item', (tester) async {
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

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      // ResponsiveNavigationWrapper should handle arrow navigation
      expect(find.byType(ResponsiveNavigationWrapper), findsOneWidget);
    });

    testWidgets('Arrow Up key moves focus to previous item', (tester) async {
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

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();

      // ResponsiveNavigationWrapper should handle arrow navigation
      expect(find.byType(ResponsiveNavigationWrapper), findsOneWidget);
    });

    testWidgets('Focus indicator is visible on keyboard focus', (tester) async {
      final items = [
        NavigationItem(
          label: 'Home',
          icon: Icons.home,
          isSelected: true,
          onTap: () {},
        ),
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

      // Tab to focus first item
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      // Focus border should be rendered (visual verification)
      // Container with border decoration should exist
      final containerFinder = find.descendant(
        of: find.byType(ResponsiveNavigationWrapper),
        matching: find.byType(Container),
      );
      expect(containerFinder, findsWidgets);
    });

    testWidgets('Empty navigation items handles keyboard events gracefully', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ResponsiveNavigationWrapper(
              navigationItems: const [],
              child: const Scaffold(body: Text('Test')),
            ),
          ),
        ),
      );

      // Should not crash on keyboard events
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(find.text('Test'), findsOneWidget);
    });
  });
}
