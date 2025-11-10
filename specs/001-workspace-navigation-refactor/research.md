# Research: Navigator 2.0 Implementation Patterns

**Feature**: Workspace Navigation Refactoring
**Date**: 2025-11-09
**Phase**: 0 (Research & Decision Making)

## Research Questions

1. **Should we use go_router package or implement custom RouterDelegate?**
2. **How to integrate Navigator 2.0 with Riverpod state management?**
3. **How to handle browser back button in Flutter Web?**
4. **Best practices for permission-aware routing?**
5. **How to maintain navigation state without persistence?**

---

## Question 1: go_router vs Custom RouterDelegate

### Decision: **Custom RouterDelegate**

### Rationale
1. **Full Control**: Custom implementation gives complete control over navigation logic, which is critical for complex workspace navigation requirements (context-aware group switching, permission-based fallbacks)
2. **Simpler Dependencies**: Avoid additional package dependency when Navigator 2.0 built-in APIs are sufficient
3. **Learning Value**: Team gains deep understanding of Navigator 2.0 architecture
4. **Flexibility**: Easier to adapt to project-specific requirements (permission checks, view context preservation)

### Alternatives Considered
- **go_router** (rejected):
  - Pros: Batteries-included, URL routing, type-safe routes
  - Cons: Additional dependency, less flexible for custom navigation logic, overkill for single-page workspace app
  - Why rejected: Project doesn't need URL-based routing (workspace is single-entry, in-memory state). Custom logic for context-aware switching would fight against go_router's conventions.

- **auto_route** (rejected):
  - Pros: Code generation, type-safe navigation
  - Cons: Build complexity, steeper learning curve
  - Why rejected: Same reasons as go_router + adds build step overhead

### Implementation Approach
- **RouterDelegate**: Manage navigation stack, handle back button
- **RouteInformationParser**: Optional (not needed if no URL routing)
- **State Management**: Riverpod providers for NavigationState

---

## Question 2: Navigator 2.0 + Riverpod Integration

### Decision: **StateNotifierProvider for NavigationState**

### Rationale
1. **Mutable State**: Navigation stack requires push/pop operations, StateNotifier provides clean API
2. **Reactive UI**: Automatic rebuild when navigation state changes
3. **Testability**: Easy to test state transitions in isolation
4. **Existing Pattern**: Project already uses Riverpod extensively

### Pattern
```dart
// NavigationState model
@freezed
class NavigationState with _$NavigationState {
  const factory NavigationState({
    required List<WorkspaceRoute> stack,
    required int currentIndex,
  }) = _NavigationState;
}

// StateNotifier
class NavigationStateNotifier extends StateNotifier<NavigationState> {
  NavigationStateNotifier() : super(NavigationState(stack: [], currentIndex: -1));

  void push(WorkspaceRoute route) { /* ... */ }
  void pop() { /* ... */ }
  void replace(WorkspaceRoute route) { /* ... */ }
  void resetToRoot() { /* ... */ }
}

// Provider
final navigationStateProvider = StateNotifierProvider<NavigationStateNotifier, NavigationState>(
  (ref) => NavigationStateNotifier(),
);
```

### Alternatives Considered
- **Provider<NavigationState>** (rejected): Immutable only, awkward for stack operations
- **ChangeNotifierProvider** (rejected): Not recommended in Riverpod, less testable
- **StateProvider** (rejected): Too simple for complex navigation state

---

## Question 3: Browser Back Button Handling

### Decision: **SystemNavigator.pop() + RouterDelegate.popRoute()**

### Rationale
1. **Built-in Support**: Navigator 2.0 automatically intercepts browser back via `RouterDelegate.popRoute()`
2. **Consistent Behavior**: Same logic handles both browser back and in-app back
3. **Exit Workspace**: Can detect root navigation and call `SystemNavigator.pop()` to exit to global home

### Implementation
```dart
class WorkspaceRouterDelegate extends RouterDelegate<WorkspaceRoute>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<WorkspaceRoute> {

  @override
  Future<bool> popRoute() async {
    final navigationState = ref.read(navigationStateProvider);

    if (navigationState.stack.length == 1) {
      // At root, exit workspace to global home
      SystemNavigator.pop();
      return true;
    } else {
      // Pop to previous view
      ref.read(navigationStateProvider.notifier).pop();
      return true;
    }
  }
}
```

### Alternatives Considered
- **Manual URL handling** (rejected): Unnecessary complexity for single-page app
- **WillPopScope** (rejected): Navigator 1.0 pattern, incompatible with Navigator 2.0

---

## Question 4: Permission-Aware Routing

### Decision: **Pre-navigation Permission Checks in RouterDelegate**

### Rationale
1. **Security First**: Validate permissions before route transition, not after
2. **Graceful Fallback**: Redirect to home view if permission denied
3. **Centralized Logic**: Single place to handle all permission checks
4. **Reactive Permissions**: Listen to permission changes and redirect if revoked

### Pattern
```dart
class WorkspaceRouterDelegate extends RouterDelegate<WorkspaceRoute> {

  Future<void> navigate(WorkspaceRoute route) async {
    // Check permissions before navigation
    if (route.requiresAdmin) {
      final hasPermission = await _checkAdminPermission(route.groupId);
      if (!hasPermission) {
        // Fallback to group home
        route = WorkspaceRoute.home(groupId: route.groupId);
      }
    }

    ref.read(navigationStateProvider.notifier).push(route);
  }

  void _listenToPermissionChanges() {
    ref.listen(permissionProvider, (previous, next) {
      final currentRoute = ref.read(navigationStateProvider).current;
      if (currentRoute.requiresAdmin && !next.hasAdminPermission) {
        // Permission revoked, show banner and redirect
        _showPermissionRevokedBanner();
        Future.delayed(Duration(seconds: 3), () {
          navigate(WorkspaceRoute.home(groupId: currentRoute.groupId));
        });
      }
    });
  }
}
```

### Alternatives Considered
- **Post-navigation checks in UI** (rejected): Can cause flash of unauthorized content
- **Route guards in go_router** (rejected): Not using go_router

---

## Question 5: Navigation State Without Persistence

### Decision: **In-Memory Only, Reset on Session Interruption**

### Rationale
1. **Security**: Don't persist potentially stale permission state
2. **Simplicity**: No need for localStorage serialization/deserialization
3. **User Expectation**: Users expect "fresh start" after refresh (clarified in spec)
4. **Performance**: Faster initialization without storage I/O

### Implementation
- Navigation state stored in Riverpod provider (memory)
- On app restart/refresh: reset to workspace entry point (top-level group home)
- No `localStorage.setItem()` or similar persistence

### Alternatives Considered
- **localStorage persistence** (rejected): Security risk, complexity, contradicts clarification decision
- **URL-based state** (rejected): Not needed for single-page workspace, adds URL clutter

---

## Best Practices Summary

1. **RouterDelegate Structure**:
   - Implement `RouterDelegate<WorkspaceRoute>`
   - Mix in `ChangeNotifier` for UI updates
   - Mix in `PopNavigatorRouterDelegateMixin` for back button support

2. **State Management**:
   - Use `StateNotifierProvider` for navigation state
   - Use `freezed` for immutable state models
   - Listen to permission changes reactively

3. **Error Handling**:
   - Pre-validate permissions before navigation
   - Show banners for permission/resource changes
   - Graceful fallback to group home

4. **Testing**:
   - Unit test: NavigationStateNotifier state transitions
   - Widget test: RouterDelegate navigation flows
   - Integration test: Permission-based navigation, browser back button

5. **Performance**:
   - Avoid rebuilding entire workspace on navigation
   - Use `const` constructors where possible
   - Debounce rapid navigation actions

---

## Technology Stack (Final)

- **Navigator 2.0**: Built-in Flutter declarative navigation
- **Custom RouterDelegate**: Full control over navigation logic
- **Riverpod StateNotifierProvider**: Reactive navigation state
- **freezed**: Immutable state models
- **No additional packages**: Avoid dependencies for routing

---

## Next Steps (Phase 1)

1. Define `NavigationState` and `WorkspaceRoute` models in `data-model.md`
2. Create `WorkspaceRouterDelegate` class structure
3. Implement `NavigationStateNotifier` with push/pop/replace operations
4. Write developer quickstart guide in `quickstart.md`
