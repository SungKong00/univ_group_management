# Data Model: Navigation State Architecture

**Feature**: Workspace Navigation Refactoring
**Date**: 2025-11-09
**Phase**: 1 (Design & Contracts)

## Overview

This document defines the core data models for the declarative navigation system. All models use `freezed` for immutability and `json_serializable` for potential debugging (not for persistence).

---

## Core Models

### 1. WorkspaceRoute

**Purpose**: Represents a single navigable location in the workspace

**File**: `frontend/lib/core/navigation/workspace_route.dart`

```dart
@freezed
class WorkspaceRoute with _$WorkspaceRoute {
  const factory WorkspaceRoute.home({
    required int groupId,
  }) = HomeRoute;

  const factory WorkspaceRoute.channel({
    required int groupId,
    required int channelId,
  }) = ChannelRoute;

  const factory WorkspaceRoute.calendar({
    required int groupId,
  }) = CalendarRoute;

  const factory WorkspaceRoute.admin({
    required int groupId,
  }) = AdminRoute;

  const factory WorkspaceRoute.memberManagement({
    required int groupId,
  }) = MemberManagementRoute;
}
```

**Relationships**:
- Each route contains `groupId` (required for all views)
- `channelId` only for channel routes
- No circular dependencies

**Validation Rules**:
- `groupId` must be > 0
- `channelId` must be > 0 (if present)
- No null values (enforced by `required` keyword)

**State Transitions**:
- Any route → Any route (via navigation methods)
- No automatic transitions (user-initiated only)

---

### 2. NavigationState

**Purpose**: Maintains the navigation history stack and current position

**File**: `frontend/lib/core/navigation/navigation_state.dart`

```dart
@freezed
class NavigationState with _$NavigationState {
  const factory NavigationState({
    @Default([]) List<WorkspaceRoute> stack,
    @Default(-1) int currentIndex,
  }) = _NavigationState;

  const NavigationState._();

  // Computed properties
  WorkspaceRoute? get current =>
      stack.isNotEmpty && currentIndex >= 0 ? stack[currentIndex] : null;

  bool get canPop => currentIndex > 0;

  bool get isAtRoot => currentIndex == 0;
}
```

**Relationships**:
- Contains list of `WorkspaceRoute` (history stack)
- `currentIndex` points to active route in stack

**Validation Rules**:
- `stack.length` must be ≥ 0
- `currentIndex` must be -1 (empty) or in range [0, stack.length - 1]
- Invariant: `stack.isEmpty ⇔ currentIndex == -1`

**State Transitions**:
```
Initial: stack=[], currentIndex=-1
↓ push(route1)
stack=[route1], currentIndex=0
↓ push(route2)
stack=[route1, route2], currentIndex=1
↓ pop()
stack=[route1], currentIndex=0
↓ pop() [at root]
→ exit workspace
```

---

### 3. ViewContext

**Purpose**: Captures the type and metadata of the current view for context-aware switching

**File**: `frontend/lib/core/navigation/view_context.dart`

```dart
enum ViewType {
  home,
  channel,
  calendar,
  admin,
  memberManagement,
}

@freezed
class ViewContext with _$ViewContext {
  const factory ViewContext({
    required ViewType type,
    int? channelId,  // Only for ViewType.channel
    Map<String, dynamic>? metadata,  // Optional additional context
  }) = _ViewContext;

  const ViewContext._();

  // Factory from WorkspaceRoute
  factory ViewContext.fromRoute(WorkspaceRoute route) {
    return route.when(
      home: (groupId) => ViewContext(type: ViewType.home),
      channel: (groupId, channelId) => ViewContext(
        type: ViewType.channel,
        channelId: channelId,
      ),
      calendar: (groupId) => ViewContext(type: ViewType.calendar),
      admin: (groupId) => ViewContext(type: ViewType.admin),
      memberManagement: (groupId) => ViewContext(type: ViewType.memberManagement),
    );
  }
}
```

**Relationships**:
- Derived from `WorkspaceRoute`
- Used for context-aware group switching

**Validation Rules**:
- `channelId` must be present if `type == ViewType.channel`
- `channelId` must be null otherwise

**Usage**:
```dart
// When switching groups, use context to determine target view
final context = ViewContext.fromRoute(currentRoute);
final targetRoute = await resolveTargetRoute(newGroupId, context);
```

---

### 4. PermissionContext

**Purpose**: Encapsulates user permissions for the current group (integration with existing permission system)

**File**: `frontend/lib/core/navigation/permission_context.dart`

```dart
@freezed
class PermissionContext with _$PermissionContext {
  const factory PermissionContext({
    required int groupId,
    required Set<String> permissions,  // e.g., {"GROUP_MANAGE", "MEMBER_KICK"}
    required bool isAdmin,  // Shortcut for admin role check
    @Default(false) bool isLoading,
  }) = _PermissionContext;

  const PermissionContext._();

  bool hasPermission(String permission) => permissions.contains(permission);

  bool canAccessAdmin() => isAdmin || permissions.contains('GROUP_MANAGE');
}
```

**Relationships**:
- Loaded from backend API: `GET /api/groups/:id/members/me/permissions`
- Cached per group (avoid repeated API calls)

**Validation Rules**:
- `groupId` must be > 0
- `permissions` non-null (can be empty set)

**State Transitions**:
```
Initial: isLoading=true, permissions={}
↓ API response
isLoading=false, permissions={loaded}
↓ Permission revoked (reactive)
→ Trigger navigation fallback
```

---

## State Management Architecture

### NavigationStateNotifier

**File**: `frontend/lib/presentation/providers/navigation_state_provider.dart`

```dart
class NavigationStateNotifier extends StateNotifier<NavigationState> {
  NavigationStateNotifier() : super(const NavigationState());

  // Push new route to stack
  void push(WorkspaceRoute route) {
    final newStack = [...state.stack, route];
    state = NavigationState(
      stack: newStack,
      currentIndex: newStack.length - 1,
    );
  }

  // Pop current route
  bool pop() {
    if (!state.canPop) return false;

    state = NavigationState(
      stack: state.stack,
      currentIndex: state.currentIndex - 1,
    );
    return true;
  }

  // Replace current route (for context-aware switching)
  void replace(WorkspaceRoute route) {
    if (state.stack.isEmpty) {
      push(route);
      return;
    }

    final newStack = [...state.stack];
    newStack[state.currentIndex] = route;
    state = NavigationState(
      stack: newStack,
      currentIndex: state.currentIndex,
    );
  }

  // Reset to root (workspace entry point)
  void resetToRoot(WorkspaceRoute root) {
    state = NavigationState(
      stack: [root],
      currentIndex: 0,
    );
  }

  // Clear all navigation state
  void clear() {
    state = const NavigationState();
  }
}

// Provider
final navigationStateProvider = StateNotifierProvider<NavigationStateNotifier, NavigationState>(
  (ref) => NavigationStateNotifier(),
);
```

---

## Permission Integration

### PermissionContextNotifier

**File**: `frontend/lib/presentation/providers/permission_context_provider.dart`

```dart
class PermissionContextNotifier extends StateNotifier<PermissionContext> {
  final Ref ref;

  PermissionContextNotifier(this.ref)
      : super(const PermissionContext(
          groupId: -1,
          permissions: {},
          isAdmin: false,
          isLoading: true,
        ));

  Future<void> loadPermissions(int groupId) async {
    state = state.copyWith(isLoading: true);

    try {
      final response = await ref.read(apiServiceProvider).get(
        '/api/groups/$groupId/members/me/permissions',
      );

      final permissions = (response.data['permissions'] as List)
          .map((p) => p.toString())
          .toSet();
      final isAdmin = response.data['isAdmin'] as bool;

      state = PermissionContext(
        groupId: groupId,
        permissions: permissions,
        isAdmin: isAdmin,
        isLoading: false,
      );
    } catch (e) {
      // Handle error
      state = PermissionContext(
        groupId: groupId,
        permissions: {},
        isAdmin: false,
        isLoading: false,
      );
    }
  }

  void clear() {
    state = const PermissionContext(
      groupId: -1,
      permissions: {},
      isAdmin: false,
      isLoading: false,
    );
  }
}

// Provider (auto-dispose when group changes)
final permissionContextProvider =
    StateNotifierProvider.autoDispose<PermissionContextNotifier, PermissionContext>(
  (ref) => PermissionContextNotifier(ref),
);
```

---

## Navigation Flow Examples

### Example 1: Simple Navigation

```dart
// User clicks on a channel
final notifier = ref.read(navigationStateProvider.notifier);
notifier.push(WorkspaceRoute.channel(groupId: 1, channelId: 5));

// User presses back button
notifier.pop();
```

### Example 2: Context-Aware Group Switching

```dart
// User switches from Group A (viewing calendar) to Group B
final currentRoute = ref.read(navigationStateProvider).current;
final context = ViewContext.fromRoute(currentRoute!);

// Determine target route based on context
WorkspaceRoute targetRoute;
if (context.type == ViewType.calendar) {
  targetRoute = WorkspaceRoute.calendar(groupId: newGroupId);
} else if (context.type == ViewType.channel) {
  // Get first channel in new group
  final channels = await fetchChannels(newGroupId);
  targetRoute = WorkspaceRoute.channel(
    groupId: newGroupId,
    channelId: channels.first.id,
  );
} else {
  targetRoute = WorkspaceRoute.home(groupId: newGroupId);
}

// Replace current route with target
ref.read(navigationStateProvider.notifier).replace(targetRoute);
```

### Example 3: Permission-Based Fallback

```dart
// User tries to access admin page
final permissionContext = ref.read(permissionContextProvider);

WorkspaceRoute route;
if (permissionContext.canAccessAdmin()) {
  route = WorkspaceRoute.admin(groupId: groupId);
} else {
  // Fallback to home
  route = WorkspaceRoute.home(groupId: groupId);
  showSnackBar('You do not have admin permissions');
}

ref.read(navigationStateProvider.notifier).push(route);
```

---

## Testing Strategy

### Unit Tests

1. **NavigationState**: Test push/pop/replace operations
2. **ViewContext**: Test fromRoute() factory and permission checks
3. **NavigationStateNotifier**: Test state transitions

### Widget Tests

1. **RouterDelegate**: Test route building based on NavigationState
2. **Permission fallback**: Test admin route redirects to home

### Integration Tests

1. **Full navigation flow**: Test user journey through multiple views
2. **Browser back button**: Test popRoute() behavior
3. **Group switching**: Test context-aware route resolution

---

## Files to Create

| File Path | Purpose | Lines (est.) |
|-----------|---------|--------------|
| `core/navigation/workspace_route.dart` | Route definitions | ~40 |
| `core/navigation/navigation_state.dart` | Navigation state model | ~30 |
| `core/navigation/view_context.dart` | View context model | ~40 |
| `core/navigation/permission_context.dart` | Permission context model | ~30 |
| `presentation/providers/navigation_state_provider.dart` | Navigation state notifier | ~80 |
| `presentation/providers/permission_context_provider.dart` | Permission context notifier | ~60 |

**Total**: ~280 lines (excluding tests)
