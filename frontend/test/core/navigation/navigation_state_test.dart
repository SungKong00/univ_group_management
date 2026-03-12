import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/navigation/navigation_state.dart';
import 'package:frontend/core/navigation/workspace_route.dart';

void main() {
  group('NavigationState', () {
    test('creates empty navigation state by default', () {
      const state = NavigationState();

      expect(state.stack, isEmpty);
      expect(state.currentIndex, -1);
      expect(state.current, isNull);
      expect(state.canPop, isFalse);
      expect(state.isAtRoot, isFalse);
    });

    test('current returns null when stack is empty', () {
      const state = NavigationState();

      expect(state.current, isNull);
    });

    test('current returns the route at currentIndex', () {
      const route1 = WorkspaceRoute.home(groupId: 1);
      const route2 = WorkspaceRoute.channel(groupId: 1, channelId: 5);
      const state = NavigationState(stack: [route1, route2], currentIndex: 1);

      expect(state.current, equals(route2));
    });

    test('canPop returns false when at index 0 or less', () {
      const route = WorkspaceRoute.home(groupId: 1);

      const stateAtRoot = NavigationState(stack: [route], currentIndex: 0);
      expect(stateAtRoot.canPop, isFalse);

      const stateEmpty = NavigationState();
      expect(stateEmpty.canPop, isFalse);
    });

    test('canPop returns true when currentIndex > 0', () {
      const route1 = WorkspaceRoute.home(groupId: 1);
      const route2 = WorkspaceRoute.channel(groupId: 1, channelId: 5);
      const state = NavigationState(stack: [route1, route2], currentIndex: 1);

      expect(state.canPop, isTrue);
    });

    test('isAtRoot returns true when currentIndex is 0', () {
      const route = WorkspaceRoute.home(groupId: 1);
      const state = NavigationState(stack: [route], currentIndex: 0);

      expect(state.isAtRoot, isTrue);
    });

    test('isAtRoot returns false when currentIndex is not 0', () {
      const route1 = WorkspaceRoute.home(groupId: 1);
      const route2 = WorkspaceRoute.channel(groupId: 1, channelId: 5);
      const state = NavigationState(stack: [route1, route2], currentIndex: 1);

      expect(state.isAtRoot, isFalse);
    });

    test('current returns null when currentIndex is out of bounds', () {
      const route = WorkspaceRoute.home(groupId: 1);
      const state = NavigationState(stack: [route], currentIndex: 5);

      expect(state.current, isNull);
    });

    test('supports equality comparison', () {
      const route = WorkspaceRoute.home(groupId: 1);
      const state1 = NavigationState(stack: [route], currentIndex: 0);
      const state2 = NavigationState(stack: [route], currentIndex: 0);
      const state3 = NavigationState(stack: [route], currentIndex: -1);

      expect(state1, equals(state2));
      expect(state1, isNot(equals(state3)));
    });

    test('supports JSON serialization', () {
      const route = WorkspaceRoute.home(groupId: 1);
      const state = NavigationState(stack: [route], currentIndex: 0);
      final json = state.toJson();
      final decoded = NavigationState.fromJson(json);

      expect(decoded, equals(state));
    });
  });
}
