import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/navigation/navigation_state.dart';
import 'package:frontend/core/navigation/workspace_route.dart';
import 'package:frontend/core/navigation/workspace_router_delegate.dart';
import 'package:frontend/presentation/providers/navigation_state_provider.dart';

/// Wrapper widget to create delegate only once
class TestRouterApp extends ConsumerStatefulWidget {
  const TestRouterApp({super.key});

  @override
  ConsumerState<TestRouterApp> createState() => _TestRouterAppState();
}

class _TestRouterAppState extends ConsumerState<TestRouterApp> {
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
  group('Workspace Navigation Integration Tests', () {
    testWidgets(
        'T053: Multi-step navigation (home → channel → calendar → back → back)',
        (tester) async {
      late NavigationStateNotifier notifier;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            navigationStateProvider.overrideWith((ref) {
              notifier = NavigationStateNotifier();
              return notifier;
            }),
          ],
          child: const TestRouterApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Initially empty (loading page)
      expect(find.text('Loading...'), findsOneWidget);

      // Step 1: Navigate to home
      notifier.push(const WorkspaceRoute.home(groupId: 1));
      await tester.pumpAndSettle();
      expect(find.text('Home View for Group 1'), findsOneWidget);
      expect(notifier.state.stack.length, 1);
      expect(notifier.state.currentIndex, 0);

      // Step 2: Navigate to channel
      notifier.push(const WorkspaceRoute.channel(groupId: 1, channelId: 5));
      await tester.pumpAndSettle();
      expect(find.text('Channel View 5'), findsOneWidget);
      expect(notifier.state.stack.length, 2);
      expect(notifier.state.currentIndex, 1);

      // Step 3: Navigate to calendar
      notifier.push(const WorkspaceRoute.calendar(groupId: 1));
      await tester.pumpAndSettle();
      expect(find.text('Calendar View for Group 1'), findsOneWidget);
      expect(notifier.state.stack.length, 3);
      expect(notifier.state.currentIndex, 2);

      // Step 4: Go back to channel
      notifier.pop();
      await tester.pump(); // Trigger rebuild
      await tester.pumpAndSettle(); // Wait for animations
      expect(find.text('Channel View 5'), findsOneWidget);
      expect(notifier.state.currentIndex, 1);

      // Step 5: Go back to home
      notifier.pop();
      await tester.pump(); // Trigger rebuild
      await tester.pumpAndSettle(); // Wait for animations
      expect(find.text('Home View for Group 1'), findsOneWidget);
      expect(notifier.state.currentIndex, 0);

      // Verify we're at root
      expect(notifier.state.isAtRoot, isTrue);
      expect(notifier.state.canPop, isFalse);
    });

    testWidgets('T054: Exiting workspace from root returns false',
        (tester) async {
      late NavigationStateNotifier notifier;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            navigationStateProvider.overrideWith((ref) {
              notifier = NavigationStateNotifier();
              // Start with home route (at root)
              notifier.push(const WorkspaceRoute.home(groupId: 1));
              return notifier;
            }),
          ],
          child: const TestRouterApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify we're at root
      expect(find.text('Home View for Group 1'), findsOneWidget);
      expect(notifier.state.isAtRoot, isTrue);
      expect(notifier.state.canPop, isFalse);

      // Try to pop from root - should not change state
      // (In real app, this would be handled by system back button)
      final canPop = notifier.pop();
      expect(canPop, isFalse,
          reason: 'pop should return false at root');

      // Verify state unchanged
      expect(notifier.state.isAtRoot, isTrue);
      expect(notifier.state.currentIndex, 0);
    });

    testWidgets('popRoute returns true when not at root', (tester) async {
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
          child: const TestRouterApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify we're on channel view (not at root)
      expect(find.text('Channel View 5'), findsOneWidget);
      expect(notifier.state.isAtRoot, isFalse);
      expect(notifier.state.canPop, isTrue);

      // Pop should return true and go back
      final result = notifier.pop();
      expect(result, isTrue,
          reason: 'pop should return true when navigation can pop');

      await tester.pump(); // Trigger rebuild
      await tester.pumpAndSettle(); // Wait for animations

      // Verify we're back to home
      expect(find.text('Home View for Group 1'), findsOneWidget);
      expect(notifier.state.isAtRoot, isTrue);
    });

    testWidgets('Replace route updates current page', (tester) async {
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
          child: const TestRouterApp(),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Channel View 5'), findsOneWidget);

      // Replace current route with different channel
      notifier.replace(const WorkspaceRoute.channel(groupId: 1, channelId: 10));
      await tester.pump(); // Trigger rebuild
      await tester.pumpAndSettle(); // Wait for animations

      expect(find.text('Channel View 10'), findsOneWidget);
      expect(notifier.state.stack.length, 2); // Stack size unchanged
      expect(notifier.state.currentIndex, 1); // Still at index 1
    });

    testWidgets('ResetToRoot clears stack and sets new root', (tester) async {
      late NavigationStateNotifier notifier;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            navigationStateProvider.overrideWith((ref) {
              notifier = NavigationStateNotifier();
              notifier.push(const WorkspaceRoute.home(groupId: 1));
              notifier.push(const WorkspaceRoute.channel(groupId: 1, channelId: 5));
              notifier.push(const WorkspaceRoute.calendar(groupId: 1));
              return notifier;
            }),
          ],
          child: const TestRouterApp(),
        ),
      );

      await tester.pumpAndSettle();
      expect(notifier.state.stack.length, 3);

      // Reset to new group's home
      notifier.resetToRoot(const WorkspaceRoute.home(groupId: 2));
      await tester.pump(); // Trigger rebuild
      await tester.pumpAndSettle(); // Wait for animations

      expect(find.text('Home View for Group 2'), findsOneWidget);
      expect(notifier.state.stack.length, 1);
      expect(notifier.state.currentIndex, 0);
      expect(notifier.state.isAtRoot, isTrue);
    });
  });
}
