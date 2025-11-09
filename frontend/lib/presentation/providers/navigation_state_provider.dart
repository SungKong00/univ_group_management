import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/navigation/navigation_state.dart';
import 'package:frontend/core/navigation/workspace_route.dart';

/// StateNotifier for managing navigation state
class NavigationStateNotifier extends StateNotifier<NavigationState> {
  NavigationStateNotifier() : super(const NavigationState());

  /// Push a new route onto the navigation stack
  void push(WorkspaceRoute route) {
    final newStack = [...state.stack, route];
    state = NavigationState(
      stack: newStack,
      currentIndex: newStack.length - 1,
    );
  }

  /// Pop the current route from the navigation stack
  /// Returns true if pop was successful, false if already at root
  bool pop() {
    if (!state.canPop) {
      return false;
    }

    state = NavigationState(
      stack: state.stack,
      currentIndex: state.currentIndex - 1,
    );
    return true;
  }

  /// Replace the current route with a new route
  /// Used for context-aware group switching
  void replace(WorkspaceRoute route) {
    if (state.stack.isEmpty) {
      push(route);
      return;
    }

    final newStack = List<WorkspaceRoute>.from(state.stack);
    newStack[state.currentIndex] = route;
    state = NavigationState(
      stack: newStack,
      currentIndex: state.currentIndex,
    );
  }

  /// Reset the navigation stack to a single root route
  /// Used when entering a workspace
  void resetToRoot(WorkspaceRoute root) {
    state = NavigationState(
      stack: [root],
      currentIndex: 0,
    );
  }

  /// Clear all navigation state
  /// Used when exiting the workspace
  void clear() {
    state = const NavigationState();
  }
}

/// Provider for navigation state management
final navigationStateProvider =
    StateNotifierProvider<NavigationStateNotifier, NavigationState>(
  (ref) => NavigationStateNotifier(),
);
