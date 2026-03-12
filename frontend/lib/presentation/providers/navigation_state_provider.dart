import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/navigation/navigation_state.dart';
import 'package:frontend/core/navigation/workspace_route.dart';
import 'package:frontend/core/navigation/view_context.dart';
import 'package:frontend/core/navigation/view_context_resolver.dart';
import 'package:frontend/presentation/providers/permission_context_provider.dart';

/// StateNotifier for managing navigation state
class NavigationStateNotifier extends StateNotifier<NavigationState> {
  final Ref? _ref;
  Timer? _debounceTimer;
  Timer? _loadingTimer; // T105: Timer for showing loading indicator
  bool _isCancelled = false; // T106: Track if loading was cancelled
  static const _debounceDuration = Duration(milliseconds: 300);
  static const _loadingThreshold = Duration(
    seconds: 2,
  ); // T105: Show loading after 2s
  static const _maxPreservedRoutes =
      5; // T111, T112: Maximum preserved scroll/form states

  NavigationStateNotifier([this._ref]) : super(const NavigationState());

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _loadingTimer?.cancel(); // T105: Clean up loading timer
    super.dispose();
  }

  /// T106: Cancel any ongoing loading operation
  void cancelLoading() {
    _isCancelled = true;
    _loadingTimer?.cancel();
    state = state.copyWith(isLoading: false, loadingMessage: null);
  }

  /// T107: Clear error state
  void clearError() {
    state = state.copyWith(lastError: null);
  }

  /// T108: Set offline status
  void setOffline(bool isOffline) {
    state = state.copyWith(isOffline: isOffline);
  }

  /// T107: Handle API error and fallback to last valid state
  void _handleApiError(NavigationState previousState, String errorMessage) {
    // Restore previous valid state
    state = previousState.copyWith(
      isLoading: false,
      loadingMessage: null,
      lastError: errorMessage,
    );
  }

  /// Push a new route onto the navigation stack
  /// Uses debouncing to prevent rapid duplicate navigations
  void push(WorkspaceRoute route) {
    // Cancel any pending navigation
    _debounceTimer?.cancel();

    _debounceTimer = Timer(_debounceDuration, () {
      _executePush(route);
    });
  }

  /// Execute push immediately without debouncing
  void _executePush(WorkspaceRoute route) {
    final newStack = [...state.stack, route];
    state = state.copyWith(stack: newStack, currentIndex: newStack.length - 1);
  }

  /// Pop the current route from the navigation stack
  /// Returns true if pop was successful, false if already at root
  bool pop() {
    if (!state.canPop) {
      return false;
    }

    state = state.copyWith(currentIndex: state.currentIndex - 1);
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
    state = state.copyWith(stack: newStack);
  }

  /// Reset the navigation stack to a single root route
  /// Used when entering a workspace
  ///
  /// IMPORTANT: This intentionally clears ALL preserved state including:
  /// - Scroll positions (scrollPositions)
  /// - Form data (formData)
  /// - Loading state (isLoading, loadingMessage)
  /// - Error state (lastError)
  /// - Offline flag (isOffline)
  ///
  /// This ensures a clean slate when entering a new workspace context.
  void resetToRoot(WorkspaceRoute root) {
    _debounceTimer?.cancel();
    _loadingTimer?.cancel();
    state = NavigationState(stack: [root], currentIndex: 0);
  }

  /// Clear all navigation state
  /// Used when exiting the workspace
  void clear() {
    _debounceTimer?.cancel();
    _loadingTimer?.cancel();
    state = const NavigationState();
  }

  /// T111: Save scroll position for current route
  /// Maintains up to 5 most recent scroll positions (LRU)
  ///
  /// LRU Implementation: When a route is accessed (scroll position updated),
  /// it is moved to the end of the map. When exceeding max size, the first
  /// entry (least recently used) is evicted.
  void saveScrollPosition(double offset) {
    final currentRoute = state.current;
    if (currentRoute == null) return;

    final routeHash = currentRoute.hashCode;
    final updatedPositions = Map<int, double>.from(state.scrollPositions);

    // Remove existing entry to ensure re-insertion updates order (LRU)
    updatedPositions.remove(routeHash);
    // Re-insert at the end (most recently used)
    updatedPositions[routeHash] = offset;

    // Keep only most recent positions (LRU eviction)
    if (updatedPositions.length > _maxPreservedRoutes) {
      final oldestKey = updatedPositions.keys.first;
      updatedPositions.remove(oldestKey);
    }

    state = state.copyWith(scrollPositions: updatedPositions);
  }

  /// T111: Get scroll position for current route
  /// Returns null if no position saved
  double? getScrollPosition() {
    final currentRoute = state.current;
    if (currentRoute == null) return null;

    final routeHash = currentRoute.hashCode;
    return state.scrollPositions[routeHash];
  }

  /// T112: Save form data for current route
  /// Maintains up to 5 most recent form states (LRU)
  ///
  /// LRU Implementation: When a route is accessed (form data updated),
  /// it is moved to the end of the map. When exceeding max size, the first
  /// entry (least recently used) is evicted.
  void saveFormData(Map<String, dynamic> data) {
    final currentRoute = state.current;
    if (currentRoute == null) return;

    final routeHash = currentRoute.hashCode;
    final updatedFormData = Map<int, Map<String, dynamic>>.from(state.formData);

    // Remove existing entry to ensure re-insertion updates order (LRU)
    updatedFormData.remove(routeHash);
    // Re-insert at the end (most recently used)
    updatedFormData[routeHash] = Map<String, dynamic>.from(data);

    // Keep only most recent form states (LRU eviction)
    if (updatedFormData.length > _maxPreservedRoutes) {
      final oldestKey = updatedFormData.keys.first;
      updatedFormData.remove(oldestKey);
    }

    state = state.copyWith(formData: updatedFormData);
  }

  /// T112: Get form data for current route
  /// Returns null if no form data saved
  Map<String, dynamic>? getFormData() {
    final currentRoute = state.current;
    if (currentRoute == null) return null;

    final routeHash = currentRoute.hashCode;
    return state.formData[routeHash];
  }

  /// T112: Clear form data for current route
  void clearFormData() {
    final currentRoute = state.current;
    if (currentRoute == null) return;

    final routeHash = currentRoute.hashCode;
    final updatedFormData = Map<int, Map<String, dynamic>>.from(state.formData);
    updatedFormData.remove(routeHash);

    state = state.copyWith(formData: updatedFormData);
  }

  /// Switch to a different group while maintaining view context
  ///
  /// This method implements context-aware group switching:
  /// - Maintains the current view type (e.g., channel → channel)
  /// - Handles permission-based fallbacks
  /// - Replaces the current route in the navigation stack
  /// - T105: Shows loading indicator if operation takes >2s
  /// - T106: Supports cancellation via cancelLoading()
  /// - T107: API failure fallback to last valid state
  /// - T108: Prevents navigation when offline
  ///
  /// Throws an exception if _ref is null (should be provided in provider constructor)
  Future<void> switchGroup(int targetGroupId) async {
    if (_ref == null) {
      throw StateError(
        'NavigationStateNotifier requires Ref for switchGroup(). '
        'Ensure provider is created with: (ref) => NavigationStateNotifier(ref)',
      );
    }

    // T108: Check if offline before starting
    if (state.isOffline) {
      state = state.copyWith(lastError: '오프라인 상태에서는 그룹을 전환할 수 없습니다');
      return;
    }

    // T107: Save current state for fallback
    final previousState = state;

    // T105: Start loading timer to show indicator after 2s
    _isCancelled = false;
    _loadingTimer = Timer(_loadingThreshold, () {
      if (!_isCancelled && mounted) {
        state = state.copyWith(isLoading: true, loadingMessage: '그룹 전환 중...');
      }
    });

    try {
      final currentRoute = state.current;
      if (currentRoute == null) {
        // No current route, just push home
        push(WorkspaceRoute.home(groupId: targetGroupId));
        return;
      }

      // T106: Check if cancelled
      if (_isCancelled) return;

      // Extract view context from current route
      final context = ViewContext.fromRoute(currentRoute);

      // Load permissions for target group
      await _ref
          .read(permissionContextProvider.notifier)
          .loadPermissions(targetGroupId);

      // T106: Check if cancelled
      if (_isCancelled) return;

      final permissions = _ref.read(permissionContextProvider);

      // Resolve target route based on context
      final resolver = _ref.read(viewContextResolverProvider);
      final targetRoute = await resolver.resolveTargetRoute(
        context,
        targetGroupId,
        permissions,
      );

      // T106: Check if cancelled
      if (_isCancelled) return;

      // Replace current route with target route
      replace(targetRoute);

      // T107: Clear any previous errors on success
      if (mounted) {
        state = state.copyWith(lastError: null);
      }
    } catch (error) {
      // T107: Fallback to previous state on API failure
      // Debug info preserved in error.toString() but user message in Korean
      _handleApiError(previousState, '그룹 전환에 실패했습니다 (${error.toString()})');
    } finally {
      // T105: Clear loading state
      _loadingTimer?.cancel();
      if (mounted && state.lastError == null) {
        // Only clear loading if no error occurred
        state = state.copyWith(isLoading: false, loadingMessage: null);
      }
    }
  }
}

/// Provider for navigation state management
final navigationStateProvider =
    StateNotifierProvider<NavigationStateNotifier, NavigationState>(
      (ref) => NavigationStateNotifier(ref),
    );
