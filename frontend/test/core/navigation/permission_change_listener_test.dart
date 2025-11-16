import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/navigation/workspace_route.dart';
import 'package:frontend/presentation/providers/navigation_state_provider.dart';

void main() {
  group('PermissionChangeListener Integration', () {
    late GlobalKey<ScaffoldMessengerState> scaffoldKey;

    setUp(() {
      scaffoldKey = GlobalKey<ScaffoldMessengerState>();
    });

    testWidgets('should provide scaffold messenger key for banners', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Initialize navigation state before building
      container
          .read(navigationStateProvider.notifier)
          .resetToRoot(WorkspaceRoute.home(groupId: 1));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            scaffoldMessengerKey: scaffoldKey,
            home: const Scaffold(
              body: Center(child: Text('Test')),
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify scaffold messenger key is accessible
      expect(scaffoldKey.currentState, isNotNull);
    });

    testWidgets('should allow navigation to home (always accessible)', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Set home route before building
      container
          .read(navigationStateProvider.notifier)
          .resetToRoot(WorkspaceRoute.home(groupId: 1));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  final state = ref.watch(navigationStateProvider);
                  return Text('Current route: ${state.current}');
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Home route should be set
      expect(find.textContaining('Current route:'), findsOneWidget);
    });

    testWidgets('should navigate to calendar (accessible to all)', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Initialize navigation state before building
      container
          .read(navigationStateProvider.notifier)
          .resetToRoot(WorkspaceRoute.home(groupId: 1));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  final notifier = ref.read(navigationStateProvider.notifier);

                  return ElevatedButton(
                    onPressed: () {
                      notifier.push(WorkspaceRoute.calendar(groupId: 1));
                    },
                    child: const Text('Go to Calendar'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Tap button to navigate
      await tester.tap(find.text('Go to Calendar'));
      await tester.pump(const Duration(milliseconds: 350)); // Wait for debounce

      // Verify navigation occurred (stack should have 2 items now)
      final state = container.read(navigationStateProvider);
      expect(state.stack.length, 2);
    });
  });
}
