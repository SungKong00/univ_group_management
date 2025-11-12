import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/navigation/workspace_route.dart';
import 'package:frontend/presentation/providers/navigation_state_provider.dart';

void main() {
  group('NavigationStateNotifier Debouncing', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should debounce rapid navigation actions', () async {
      final notifier = container.read(navigationStateProvider.notifier);

      // Initialize with home
      notifier.resetToRoot(WorkspaceRoute.home(groupId: 1));

      // Rapid fire multiple push operations
      notifier.push(WorkspaceRoute.channel(groupId: 1, channelId: 1));
      notifier.push(WorkspaceRoute.channel(groupId: 1, channelId: 2));
      notifier.push(WorkspaceRoute.channel(groupId: 1, channelId: 3));
      notifier.push(WorkspaceRoute.calendar(groupId: 1));

      // Wait for debounce timer (300ms + margin)
      await Future.delayed(const Duration(milliseconds: 350));

      // Only the last push should have executed
      final state = container.read(navigationStateProvider);
      expect(state.stack.length, 2); // home + calendar
      expect(state.current, isA<CalendarRoute>());
    });

    test('should execute push after debounce delay', () async {
      final notifier = container.read(navigationStateProvider.notifier);

      // Initialize with home
      notifier.resetToRoot(WorkspaceRoute.home(groupId: 1));

      // Single push
      notifier.push(WorkspaceRoute.channel(groupId: 1, channelId: 1));

      // Immediately check - should not have executed yet
      var state = container.read(navigationStateProvider);
      expect(state.stack.length, 1); // Only home

      // Wait for debounce
      await Future.delayed(const Duration(milliseconds: 350));

      // Now should be executed
      state = container.read(navigationStateProvider);
      expect(state.stack.length, 2); // home + channel
      expect(state.current, isA<ChannelRoute>());
    });

    test('should cancel pending navigation when new push arrives', () async {
      final notifier = container.read(navigationStateProvider.notifier);

      // Initialize with home
      notifier.resetToRoot(WorkspaceRoute.home(groupId: 1));

      // First push
      notifier.push(WorkspaceRoute.channel(groupId: 1, channelId: 1));

      // Wait 100ms (less than debounce delay)
      await Future.delayed(const Duration(milliseconds: 100));

      // Second push (should cancel first)
      notifier.push(WorkspaceRoute.calendar(groupId: 1));

      // Wait for debounce
      await Future.delayed(const Duration(milliseconds: 350));

      // Only calendar should be pushed
      final state = container.read(navigationStateProvider);
      expect(state.stack.length, 2); // home + calendar
      expect(state.current, isA<CalendarRoute>());
    });

    test('should allow sequential navigations after debounce', () async {
      final notifier = container.read(navigationStateProvider.notifier);

      // Initialize with home
      notifier.resetToRoot(WorkspaceRoute.home(groupId: 1));

      // First push
      notifier.push(WorkspaceRoute.channel(groupId: 1, channelId: 1));
      await Future.delayed(const Duration(milliseconds: 350));

      // Second push after debounce
      notifier.push(WorkspaceRoute.calendar(groupId: 1));
      await Future.delayed(const Duration(milliseconds: 350));

      // Both should execute
      final state = container.read(navigationStateProvider);
      expect(state.stack.length, 3); // home + channel + calendar
      expect(state.current, isA<CalendarRoute>());
    });

    test('should preserve non-push operations (pop, replace, clear)', () async {
      final notifier = container.read(navigationStateProvider.notifier);

      // Initialize with home + channel
      notifier.resetToRoot(WorkspaceRoute.home(groupId: 1));
      notifier.push(WorkspaceRoute.channel(groupId: 1, channelId: 1));
      await Future.delayed(const Duration(milliseconds: 350));

      // Pop should work immediately
      final result = notifier.pop();
      expect(result, isTrue);

      final state = container.read(navigationStateProvider);
      expect(state.stack.length, 2);
      expect(state.currentIndex, 0); // Back to home
    });
  });
}
