import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/presentation/widgets/navigation/responsive_navigation_wrapper.dart';

void main() {
  group('ResponsiveNavigationWrapper', () {
    late List<NavigationItem> testNavigationItems;

    setUp(() {
      testNavigationItems = [
        NavigationItem(
          label: '홈',
          icon: Icons.home,
          isSelected: true,
          onTap: () {},
        ),
        NavigationItem(
          label: '채널',
          icon: Icons.tag,
          isSelected: false,
          onTap: () {},
        ),
        NavigationItem(
          label: '캘린더',
          icon: Icons.calendar_today,
          isSelected: false,
          onTap: () {},
        ),
      ];
    });

    testWidgets('displays mobile drawer on small screens', (tester) async {
      // Build widget with MediaQuery override for mobile size
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(size: Size(400, 800)),
              child: ResponsiveNavigationWrapper(
                navigationItems: testNavigationItems,
                child: const Center(child: Text('Test Content')),
              ),
            ),
          ),
        ),
      );

      // Wait for animations
      await tester.pumpAndSettle();

      // Verify mobile header exists
      expect(find.byIcon(Icons.menu), findsOneWidget);
      expect(find.text('워크스페이스'), findsOneWidget);

      // Verify drawer is not visible initially
      expect(find.text('네비게이션'), findsNothing);

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Verify drawer is now visible
      expect(find.text('네비게이션'), findsOneWidget);
      expect(find.text('홈'), findsOneWidget);
      expect(find.text('채널'), findsOneWidget);
      expect(find.text('캘린더'), findsOneWidget);
    });

    testWidgets('displays desktop navigation on large screens', (tester) async {
      // Set desktop screen size (>= 768px)
      await tester.binding.setSurfaceSize(const Size(1024, 768));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ResponsiveNavigationWrapper(
              navigationItems: testNavigationItems,
              child: const Center(child: Text('Test Content')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify desktop navigation is visible
      expect(find.text('워크스페이스'), findsOneWidget);
      expect(find.text('홈'), findsOneWidget);
      expect(find.text('채널'), findsOneWidget);
      expect(find.text('캘린더'), findsOneWidget);

      // Verify hamburger menu is not present
      expect(find.byIcon(Icons.menu), findsNothing);

      // Reset surface size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('transitions between mobile and desktop layouts', (
      tester,
    ) async {
      // Start with desktop size
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(size: Size(1024, 768)),
              child: ResponsiveNavigationWrapper(
                navigationItems: testNavigationItems,
                child: const Center(child: Text('Test Content')),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify desktop layout
      expect(find.byIcon(Icons.menu), findsNothing);
      expect(find.text('홈'), findsOneWidget);

      // Rebuild with mobile size
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(size: Size(400, 800)),
              child: ResponsiveNavigationWrapper(
                navigationItems: testNavigationItems,
                child: const Center(child: Text('Test Content')),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify mobile layout
      expect(find.byIcon(Icons.menu), findsOneWidget);
    });

    testWidgets('closes drawer after navigation item tap on mobile', (
      tester,
    ) async {
      int tapCount = 0;
      final itemsWithCallback = [
        NavigationItem(
          label: '홈',
          icon: Icons.home,
          isSelected: false,
          onTap: () => tapCount++,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(size: Size(400, 800)),
              child: ResponsiveNavigationWrapper(
                navigationItems: itemsWithCallback,
                child: const Center(child: Text('Test Content')),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Tap navigation item
      await tester.tap(find.text('홈'));
      await tester.pumpAndSettle();

      // Verify callback was called
      expect(tapCount, 1);

      // Verify drawer is closed
      expect(find.text('네비게이션'), findsNothing);
    });

    testWidgets('highlights selected navigation item', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ResponsiveNavigationWrapper(
              navigationItems: testNavigationItems,
              child: const Center(child: Text('Test Content')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the ListTile for '홈' (which is selected)
      final homeTile = find.ancestor(
        of: find.text('홈'),
        matching: find.byType(ListTile),
      );

      expect(homeTile, findsOneWidget);

      // Verify the selected item has special styling
      final listTile = tester.widget<ListTile>(homeTile);
      expect(listTile.selected, true);

      // Reset surface size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('renders child content correctly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ResponsiveNavigationWrapper(
              navigationItems: testNavigationItems,
              child: const Center(child: Text('Custom Child Content')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify child content is rendered
      expect(find.text('Custom Child Content'), findsOneWidget);

      // Reset surface size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('uses custom breakpoint when provided', (tester) async {
      // Set size just below custom breakpoint
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(size: Size(600, 800)),
              child: ResponsiveNavigationWrapper(
                navigationItems: testNavigationItems,
                mobileBreakpoint: 650.0, // Custom breakpoint
                child: const Center(child: Text('Test Content')),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show mobile layout (600 < 650)
      expect(find.byIcon(Icons.menu), findsOneWidget);
    });

    testWidgets('applies fade animation on mount', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ResponsiveNavigationWrapper(
              navigationItems: testNavigationItems,
              child: const Center(child: Text('Test Content')),
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify FadeTransition exists
      expect(find.byType(FadeTransition), findsOneWidget);

      // Reset surface size
      await tester.binding.setSurfaceSize(null);
    });
  });
}
