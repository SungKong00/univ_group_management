import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/navigation/navigation_state.dart';
import 'package:frontend/core/navigation/workspace_route.dart';
import 'package:frontend/core/navigation/workspace_router_delegate.dart';
import 'package:frontend/presentation/providers/navigation_state_provider.dart';

/// Wrapper widget to create delegate only once and set up listener
class _TestRouterWrapper extends ConsumerStatefulWidget {
  const _TestRouterWrapper({super.key});

  @override
  ConsumerState<_TestRouterWrapper> createState() => _TestRouterWrapperState();
}

class _TestRouterWrapperState extends ConsumerState<_TestRouterWrapper> {
  @override
  Widget build(BuildContext context) {
    // Create delegate in build to ensure it's properly connected to provider scope
    final delegate = WorkspaceRouterDelegate(ref);

    return MaterialApp.router(
      routerDelegate: delegate,
    );
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

    testWidgets('builds Navigator with empty pages when state is empty',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: _TestRouterWrapper(),
        ),
      );

      await tester.pumpAndSettle();

      // Should show loading page
      expect(find.text('Loading...'), findsOneWidget);
    });

    testWidgets('builds page for single route', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            navigationStateProvider.overrideWith((ref) {
              final notifier = NavigationStateNotifier();
              notifier.push(const WorkspaceRoute.home(groupId: 1));
              return notifier;
            }),
          ],
          child: const _TestRouterWrapper(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify home view is shown
      expect(find.text('Home View for Group 1'), findsOneWidget);
    });

    testWidgets('builds pages for multiple routes', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            navigationStateProvider.overrideWith((ref) {
              final notifier = NavigationStateNotifier();
              notifier.push(const WorkspaceRoute.home(groupId: 1));
              notifier.push(const WorkspaceRoute.channel(groupId: 1, channelId: 5));
              return notifier;
            }),
          ],
          child: const _TestRouterWrapper(),
        ),
      );

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
              notifier.push(const WorkspaceRoute.home(groupId: 1));
              notifier.push(const WorkspaceRoute.channel(groupId: 1, channelId: 5));
              return notifier;
            }),
          ],
          child: _TestRouterWrapper(),
        ),
      );

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
