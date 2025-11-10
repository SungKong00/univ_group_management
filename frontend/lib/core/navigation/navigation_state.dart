import 'package:freezed_annotation/freezed_annotation.dart';
import 'workspace_route.dart';

part 'navigation_state.freezed.dart';
part 'navigation_state.g.dart';

/// Maintains the navigation history stack and current position
@freezed
class NavigationState with _$NavigationState {
  const factory NavigationState({
    @Default([]) List<WorkspaceRoute> stack,
    @Default(-1) int currentIndex,

    /// T105: Loading indicator for slow navigation operations (>2s)
    @Default(false) bool isLoading,

    /// T105: Optional message to display during loading
    String? loadingMessage,

    /// T107: Last error message for API failures
    String? lastError,

    /// T108: Offline detection flag
    @Default(false) bool isOffline,

    /// T111: Scroll positions for each route (key: route hash, value: scroll offset)
    /// Stores up to 5 most recent positions
    @Default({}) Map<int, double> scrollPositions,

    /// T112: Form data for each route (key: route hash, value: form data)
    /// Stores up to 5 most recent form states
    @Default({}) Map<int, Map<String, dynamic>> formData,
  }) = _NavigationState;

  const NavigationState._();

  /// Returns the current active route, or null if stack is empty
  WorkspaceRoute? get current =>
      stack.isNotEmpty && currentIndex >= 0 && currentIndex < stack.length
      ? stack[currentIndex]
      : null;

  /// Returns true if we can pop to a previous route
  bool get canPop => currentIndex > 0;

  /// Returns true if we are at the root of the navigation stack
  bool get isAtRoot => currentIndex == 0;

  factory NavigationState.fromJson(Map<String, dynamic> json) =>
      _$NavigationStateFromJson(json);
}
