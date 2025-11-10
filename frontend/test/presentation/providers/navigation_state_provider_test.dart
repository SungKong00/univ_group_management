import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/navigation/workspace_route.dart';
import 'package:frontend/presentation/providers/navigation_state_provider.dart';

void main() {
  group('NavigationStateNotifier', () {
    late NavigationStateNotifier notifier;

    setUp(() {
      notifier = NavigationStateNotifier();
    });

    test('initializes with empty navigation state', () {
      expect(notifier.state.stack, isEmpty);
      expect(notifier.state.currentIndex, -1);
      expect(notifier.state.current, isNull);
    });

    test('push adds route to stack', () async {
      const route = WorkspaceRoute.home(groupId: 1);

      notifier.push(route);

      // Wait for debouncing (300ms + margin)
      await Future.delayed(const Duration(milliseconds: 350));

      expect(notifier.state.stack, hasLength(1));
      expect(notifier.state.stack.first, equals(route));
      expect(notifier.state.currentIndex, 0);
      expect(notifier.state.current, equals(route));
    });

    test('push multiple routes builds stack', () async {
      const route1 = WorkspaceRoute.home(groupId: 1);
      const route2 = WorkspaceRoute.channel(groupId: 1, channelId: 5);
      const route3 = WorkspaceRoute.calendar(groupId: 1);

      notifier.push(route1);
      await Future.delayed(const Duration(milliseconds: 350));

      notifier.push(route2);
      await Future.delayed(const Duration(milliseconds: 350));

      notifier.push(route3);
      await Future.delayed(const Duration(milliseconds: 350));

      expect(notifier.state.stack, hasLength(3));
      expect(notifier.state.currentIndex, 2);
      expect(notifier.state.current, equals(route3));
      expect(notifier.state.stack[0], equals(route1));
      expect(notifier.state.stack[1], equals(route2));
      expect(notifier.state.stack[2], equals(route3));
    });

    test('pop removes current route from stack', () async {
      const route1 = WorkspaceRoute.home(groupId: 1);
      const route2 = WorkspaceRoute.channel(groupId: 1, channelId: 5);

      notifier.push(route1);
      await Future.delayed(const Duration(milliseconds: 350));

      notifier.push(route2);
      await Future.delayed(const Duration(milliseconds: 350));

      final result = notifier.pop();

      expect(result, isTrue);
      expect(notifier.state.stack, hasLength(2));
      expect(notifier.state.currentIndex, 0);
      expect(notifier.state.current, equals(route1));
    });

    test('pop returns false when at root', () async {
      const route = WorkspaceRoute.home(groupId: 1);

      notifier.push(route);
      await Future.delayed(const Duration(milliseconds: 350));

      final result = notifier.pop();

      expect(result, isFalse);
      expect(notifier.state.currentIndex, 0);
      expect(notifier.state.current, equals(route));
    });

    test('pop returns false when stack is empty', () {
      final result = notifier.pop();

      expect(result, isFalse);
      expect(notifier.state.stack, isEmpty);
      expect(notifier.state.currentIndex, -1);
    });

    test('replace replaces current route', () async {
      const route1 = WorkspaceRoute.home(groupId: 1);
      const route2 = WorkspaceRoute.channel(groupId: 1, channelId: 5);
      const replacement = WorkspaceRoute.calendar(groupId: 1);

      notifier.push(route1);
      await Future.delayed(const Duration(milliseconds: 350));

      notifier.push(route2);
      await Future.delayed(const Duration(milliseconds: 350));

      notifier.replace(replacement);

      expect(notifier.state.stack, hasLength(2));
      expect(notifier.state.currentIndex, 1);
      expect(notifier.state.current, equals(replacement));
      expect(notifier.state.stack[0], equals(route1));
      expect(notifier.state.stack[1], equals(replacement));
    });

    test('replace pushes when stack is empty', () async {
      const route = WorkspaceRoute.home(groupId: 1);

      notifier.replace(route);
      await Future.delayed(const Duration(milliseconds: 350));

      expect(notifier.state.stack, hasLength(1));
      expect(notifier.state.currentIndex, 0);
      expect(notifier.state.current, equals(route));
    });

    test('resetToRoot replaces entire stack with single route', () async {
      const route1 = WorkspaceRoute.home(groupId: 1);
      const route2 = WorkspaceRoute.channel(groupId: 1, channelId: 5);
      const newRoot = WorkspaceRoute.home(groupId: 2);

      notifier.push(route1);
      await Future.delayed(const Duration(milliseconds: 350));

      notifier.push(route2);
      await Future.delayed(const Duration(milliseconds: 350));

      notifier.resetToRoot(newRoot);

      expect(notifier.state.stack, hasLength(1));
      expect(notifier.state.currentIndex, 0);
      expect(notifier.state.current, equals(newRoot));
    });

    test('clear empties the navigation stack', () async {
      const route1 = WorkspaceRoute.home(groupId: 1);
      const route2 = WorkspaceRoute.channel(groupId: 1, channelId: 5);

      notifier.push(route1);
      await Future.delayed(const Duration(milliseconds: 350));

      notifier.push(route2);
      await Future.delayed(const Duration(milliseconds: 350));

      notifier.clear();

      expect(notifier.state.stack, isEmpty);
      expect(notifier.state.currentIndex, -1);
      expect(notifier.state.current, isNull);
    });

    test('maintains stack immutability', () async {
      const route1 = WorkspaceRoute.home(groupId: 1);
      const route2 = WorkspaceRoute.channel(groupId: 1, channelId: 5);

      notifier.push(route1);
      await Future.delayed(const Duration(milliseconds: 350));
      final firstState = notifier.state;

      notifier.push(route2);
      await Future.delayed(const Duration(milliseconds: 350));
      final secondState = notifier.state;

      // Original state should be unchanged
      expect(firstState.stack, hasLength(1));
      expect(firstState.currentIndex, 0);

      // New state should have both routes
      expect(secondState.stack, hasLength(2));
      expect(secondState.currentIndex, 1);
    });
  });
}
