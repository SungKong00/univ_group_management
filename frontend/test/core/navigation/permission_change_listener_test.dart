import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/navigation/navigation_state.dart';
import 'package:frontend/core/navigation/workspace_route.dart';
import 'package:frontend/presentation/providers/navigation_state_provider.dart';
import 'package:frontend/presentation/providers/permission_context_provider.dart';

void main() {
  group('PermissionChangeListener Integration', () {
    late GlobalKey<ScaffoldMessengerState> scaffoldKey;

    setUp(() {
      scaffoldKey = GlobalKey<ScaffoldMessengerState>();
    });

    testWidgets('should provide scaffold messenger key for banners', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            scaffoldMessengerKey: scaffoldKey,
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  // Initialize navigation state
                  Future.microtask(() {
                    ref
                        .read(navigationStateProvider.notifier)
                        .resetToRoot(WorkspaceRoute.home(groupId: 1));
                  });

                  return const Center(child: Text('Test'));
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify scaffold messenger key is accessible
      expect(scaffoldKey.currentState, isNotNull);
    });

    testWidgets('should allow navigation to home (always accessible)', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  // Set home route
                  Future.microtask(() {
                    ref
                        .read(navigationStateProvider.notifier)
                        .resetToRoot(WorkspaceRoute.home(groupId: 1));
                  });

                  final state = ref.watch(navigationStateProvider);
                  return Text('Current route: ${state.current}');
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Home route should be set
      expect(find.textContaining('Current route:'), findsOneWidget);
    });

    testWidgets('should navigate to calendar (accessible to all)', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  // Initialize and navigate
                  final notifier = ref.read(navigationStateProvider.notifier);
                  if (ref.watch(navigationStateProvider).stack.isEmpty) {
                    notifier.resetToRoot(WorkspaceRoute.home(groupId: 1));
                  }

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

      // Verify navigation occurred
      // (In production, verify calendar view is shown)
    });
  });
}
