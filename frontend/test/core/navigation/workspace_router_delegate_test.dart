import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/navigation/workspace_route.dart';
import 'package:frontend/core/navigation/workspace_router_delegate.dart';
import 'package:frontend/presentation/providers/navigation_state_provider.dart';

/// Wrapper widget to create delegate only once and set up listener
class _TestRouterWrapper extends ConsumerStatefulWidget {
  const _TestRouterWrapper();

  @override
  ConsumerState<_TestRouterWrapper> createState() => _TestRouterWrapperState();
}

class _TestRouterWrapperState extends ConsumerState<_TestRouterWrapper> {
  @override
  Widget build(BuildContext context) {
    // Create delegate in build to ensure it's properly connected to provider scope
    final delegate = WorkspaceRouterDelegate(ref, isTestMode: true);

    return MaterialApp.router(routerDelegate: delegate);
  }
}

void main() {
  group('WorkspaceRouterDelegate', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initializes with empty navigation state', () {
      final state = container.read(navigationStateProvider);
      expect(state.stack, isEmpty);
      expect(state.currentIndex, -1);
    });

    testWidgets('builds Navigator with empty pages when state is empty', (
      tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: _TestRouterWrapper()));

      await tester.pumpAndSettle();

      // Should show loading page
      expect(find.text('로딩 중...'), findsOneWidget);
    });

    testWidgets('builds page for single route', (tester) async {
      late NavigationStateNotifier notifier;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            navigationStateProvider.overrideWith((ref) {
              notifier = NavigationStateNotifier();
              return notifier;
            }),
          ],
          child: const _TestRouterWrapper(),
        ),
      );

      // Push route AFTER widget is built
      notifier.push(const WorkspaceRoute.home(groupId: 1));
      await tester.pump(
        const Duration(milliseconds: 350),
      ); // Wait for debounce (300ms)
      await tester.pumpAndSettle();

      // Verify home view is shown
      expect(find.text('Home View for Group 1'), findsOneWidget);
    });

    testWidgets('builds pages for multiple routes', (tester) async {
      late NavigationStateNotifier notifier;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            navigationStateProvider.overrideWith((ref) {
              notifier = NavigationStateNotifier();
              return notifier;
            }),
          ],
          child: const _TestRouterWrapper(),
        ),
      );

      notifier.push(const WorkspaceRoute.home(groupId: 1));
      await tester.pump(const Duration(milliseconds: 350)); // Wait for debounce
      notifier.push(const WorkspaceRoute.channel(groupId: 1, channelId: 5));
      await tester.pump(const Duration(milliseconds: 350)); // Wait for debounce
      await tester.pumpAndSettle();

      // Current page should be channel view
      expect(find.text('Channel View 5'), findsOneWidget);
    });

    testWidgets('pop removes current page', (tester) async {
      late NavigationStateNotifier notifier;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            navigationStateProvider.overrideWith((ref) {
              notifier = NavigationStateNotifier();
              return notifier;
            }),
          ],
          child: const _TestRouterWrapper(),
        ),
      );

      notifier.push(const WorkspaceRoute.home(groupId: 1));
      await tester.pump(const Duration(milliseconds: 350));
      notifier.push(const WorkspaceRoute.channel(groupId: 1, channelId: 5));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(find.text('Channel View 5'), findsOneWidget);

      // Pop the route
      notifier.pop();
      await tester.pump(); // Trigger rebuild
      await tester.pumpAndSettle(); // Wait for animations

      // Should show home view now
      expect(find.text('Home View for Group 1'), findsOneWidget);
    });
  });
}
