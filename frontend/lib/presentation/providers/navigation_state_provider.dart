import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';
import '../../core/constants/app_constants.dart';

class NavigationState extends Equatable {
  const NavigationState({
    this.currentRoute = AppConstants.homeRoute,
    this.isWorkspaceCollapsed = false,
    this.navigationHistory = const [AppConstants.homeRoute],
  });

  final String currentRoute;
  final bool isWorkspaceCollapsed;
  final List<String> navigationHistory;

  NavigationState copyWith({
    String? currentRoute,
    bool? isWorkspaceCollapsed,
    List<String>? navigationHistory,
  }) {
    return NavigationState(
      currentRoute: currentRoute ?? this.currentRoute,
      isWorkspaceCollapsed: isWorkspaceCollapsed ?? this.isWorkspaceCollapsed,
      navigationHistory: navigationHistory ?? this.navigationHistory,
    );
  }

  bool get canGoBack => navigationHistory.length > 1;

  @override
  List<Object?> get props => [currentRoute, isWorkspaceCollapsed, navigationHistory];
}

class NavigationStateNotifier extends StateNotifier<NavigationState> {
  NavigationStateNotifier() : super(const NavigationState());

  void setCurrentRoute(String route) {
    final newHistory = List<String>.from(state.navigationHistory);

    // 같은 페이지로 이동하는 경우 히스토리에 추가하지 않음
    if (newHistory.isEmpty || newHistory.last != route) {
      newHistory.add(route);
    }

    state = state.copyWith(
      currentRoute: route,
      navigationHistory: newHistory,
    );
  }

  String? goBack() {
    if (!state.canGoBack) {
      // 뒤로갈 수 없으면 홈으로
      resetToHome();
      return AppConstants.homeRoute;
    }

    final newHistory = List<String>.from(state.navigationHistory);
    newHistory.removeLast();

    final previousRoute = newHistory.last;

    state = state.copyWith(
      currentRoute: previousRoute,
      navigationHistory: newHistory,
    );

    return previousRoute;
  }

  void resetToHome() {
    state = state.copyWith(
      currentRoute: AppConstants.homeRoute,
      navigationHistory: [AppConstants.homeRoute],
    );
  }

  void toggleWorkspaceCollapse() {
    state = state.copyWith(
      isWorkspaceCollapsed: !state.isWorkspaceCollapsed,
    );
  }

  void setWorkspaceCollapsed(bool collapsed) {
    state = state.copyWith(
      isWorkspaceCollapsed: collapsed,
    );
  }

  // 워크스페이스 진입 시 자동 축소
  void enterWorkspace() {
    state = state.copyWith(
      isWorkspaceCollapsed: true,
    );
  }

  // 워크스페이스 벗어날 시 자동 확장
  void exitWorkspace() {
    state = state.copyWith(
      isWorkspaceCollapsed: false,
    );
  }
}

final navigationStateProvider = StateNotifierProvider<NavigationStateNotifier, NavigationState>(
  (ref) => NavigationStateNotifier(),
);