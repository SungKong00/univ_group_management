import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/navigation/navigation_state.dart';
import 'package:frontend/core/navigation/workspace_route.dart';
import 'package:frontend/core/navigation/view_context.dart';
import 'package:frontend/core/navigation/view_context_resolver.dart';
import 'package:frontend/core/navigation/permission_context.dart';
import 'package:frontend/presentation/providers/permission_context_provider.dart';

/// StateNotifier for managing navigation state
class NavigationStateNotifier extends StateNotifier<NavigationState> {
  final Ref? _ref;

  NavigationStateNotifier([this._ref]) : super(const NavigationState());

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

  /// Switch to a different group while maintaining view context
  ///
  /// This method implements context-aware group switching:
  /// - Maintains the current view type (e.g., channel → channel)
  /// - Handles permission-based fallbacks
  /// - Replaces the current route in the navigation stack
  ///
  /// Throws an exception if _ref is null (should be provided in provider constructor)
  Future<void> switchGroup(int targetGroupId) async {
    if (_ref == null) {
      throw StateError(
        'NavigationStateNotifier requires Ref for switchGroup(). '
        'Ensure provider is created with: (ref) => NavigationStateNotifier(ref)',
      );
    }

    final currentRoute = state.current;
    if (currentRoute == null) {
      // No current route, just push home
      push(WorkspaceRoute.home(groupId: targetGroupId));
      return;
    }

    // Extract view context from current route
    final context = ViewContext.fromRoute(currentRoute);

    // Load permissions for target group
    await _ref!.read(permissionContextProvider.notifier).loadPermissions(targetGroupId);
    final permissions = _ref!.read(permissionContextProvider);

    // Resolve target route based on context
    final resolver = _ref!.read(viewContextResolverProvider);
    final targetRoute = await resolver.resolveTargetRoute(
      context,
      targetGroupId,
      permissions,
    );

    // Replace current route with target route
    replace(targetRoute);
  }
}

/// Provider for navigation state management
final navigationStateProvider =
    StateNotifierProvider<NavigationStateNotifier, NavigationState>(
  (ref) => NavigationStateNotifier(ref),
);
