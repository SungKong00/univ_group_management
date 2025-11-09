import 'package:freezed_annotation/freezed_annotation.dart';
import 'workspace_route.dart';

part 'navigation_state.freezed.dart';
part 'navigation_state.g.dart';

/// Maintains the navigation history stack and current position
@freezed
class NavigationState with _$NavigationState {
  const factory NavigationState({
    @Default([])
    @JsonKey(fromJson: _stackFromJson, toJson: _stackToJson)
    List<WorkspaceRoute> stack,
    @Default(-1) int currentIndex,
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

// JSON converters for WorkspaceRoute list
List<WorkspaceRoute> _stackFromJson(List<dynamic> json) {
  return json.map((e) => WorkspaceRoute.fromJson(e as Map<String, dynamic>)).toList();
}

List<dynamic> _stackToJson(List<WorkspaceRoute> stack) {
  return stack.map((e) => e.toJson()).toList();
}
