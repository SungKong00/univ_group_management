# Quickstart: Navigator 2.0 Implementation Guide

**Feature**: Workspace Navigation Refactoring
**Date**: 2025-11-09
**Phase**: 1 (Design & Contracts)
**Audience**: Frontend developers implementing the navigation system

## Prerequisites

- Dart 3.x / Flutter SDK 3.x installed
- Familiarity with Riverpod state management
- Understanding of `freezed` package for immutable models
- Read `research.md` for architecture decisions
- Read `data-model.md` for state models

---

## Implementation Checklist

### Phase 1: Core Models (1-2 hours)

- [ ] 1.1: Create `WorkspaceRoute` with freezed
- [ ] 1.2: Create `NavigationState` with freezed
- [ ] 1.3: Create `ViewContext` with freezed
- [ ] 1.4: Create `PermissionContext` with freezed
- [ ] 1.5: Run `flutter pub run build_runner build`
- [ ] 1.6: Write unit tests for each model

### Phase 2: State Management (2-3 hours)

- [ ] 2.1: Implement `NavigationStateNotifier`
- [ ] 2.2: Create `navigationStateProvider`
- [ ] 2.3: Implement `PermissionContextNotifier`
- [ ] 2.4: Create `permissionContextProvider`
- [ ] 2.5: Write unit tests for notifiers

### Phase 3: RouterDelegate (3-4 hours)

- [ ] 3.1: Create `WorkspaceRouterDelegate` class
- [ ] 3.2: Implement `build()` method (route → widget)
- [ ] 3.3: Implement `setNewRoutePath()` (if using URLs)
- [ ] 3.4: Implement `popRoute()` for back button
- [ ] 3.5: Add permission checking logic
- [ ] 3.6: Add error handling and fallbacks
- [ ] 3.7: Write widget tests for RouterDelegate

### Phase 4: Integration (2-3 hours)

- [ ] 4.1: Update `workspace_page.dart` to use Navigator 2.0
- [ ] 4.2: Replace imperative navigation calls with provider methods
- [ ] 4.3: Add permission listeners for reactive navigation
- [ ] 4.4: Test browser back button behavior
- [ ] 4.5: Test mobile navigation (responsive)
- [ ] 4.6: Write integration tests

### Phase 5: Edge Cases (1-2 hours)

- [ ] 5.1: Implement permission revocation handling (banner + redirect)
- [ ] 5.2: Implement resource deletion handling (banner + redirect)
- [ ] 5.3: Implement session interruption reset
- [ ] 5.4: Test all edge cases manually

**Total Estimated Time**: 9-14 hours

---

## Navigation Routes

The workspace supports the following routes (as defined in WorkspaceRoute sealed class):

1. **home** - Group overview and announcements (`WorkspaceRoute.home`)
2. **channel** - Channel content with posts and comments (`WorkspaceRoute.channel`)
3. **calendar** - Group calendar and events (`WorkspaceRoute.calendar`)
4. **admin** - Group management (requires admin permissions) (`WorkspaceRoute.admin`)
5. **memberManagement** - Member list and invitations (`WorkspaceRoute.memberManagement`)

**Total**: 5 core routes (plan estimate: 8-12 routes → actual: 5 routes ✅ within scope)

**Mobile Navigation**: On mobile breakpoints (<768px), routes are accessed through a responsive navigation drawer instead of sidebar tabs. The navigation behavior is identical across desktop and mobile.

---

## Step-by-Step Implementation

### Step 1: Create WorkspaceRoute Model

**File**: `frontend/lib/core/navigation/workspace_route.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'workspace_route.freezed.dart';

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

**Test**: `test/core/navigation/workspace_route_test.dart`

```dart
void main() {
  group('WorkspaceRoute', () {
    test('creates home route', () {
      final route = WorkspaceRoute.home(groupId: 1);
      expect(route, isA<HomeRoute>());
      route.when(
        home: (groupId) => expect(groupId, 1),
        orElse: () => fail('Should be HomeRoute'),
      );
    });

    test('creates channel route', () {
      final route = WorkspaceRoute.channel(groupId: 1, channelId: 5);
      expect(route, isA<ChannelRoute>());
      route.when(
        channel: (groupId, channelId) {
          expect(groupId, 1);
          expect(channelId, 5);
        },
        orElse: () => fail('Should be ChannelRoute'),
      );
    });
  });
}
```

---

### Step 2: Create NavigationStateNotifier

**File**: `frontend/lib/presentation/providers/navigation_state_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:your_app/core/navigation/navigation_state.dart';
import 'package:your_app/core/navigation/workspace_route.dart';

class NavigationStateNotifier extends StateNotifier<NavigationState> {
  NavigationStateNotifier() : super(const NavigationState());

  void push(WorkspaceRoute route) {
    final newStack = [...state.stack, route];
    state = NavigationState(
      stack: newStack,
      currentIndex: newStack.length - 1,
    );
  }

  bool pop() {
    if (!state.canPop) return false;

    state = NavigationState(
      stack: state.stack,
      currentIndex: state.currentIndex - 1,
    );
    return true;
  }

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

  void resetToRoot(WorkspaceRoute root) {
    state = NavigationState(
      stack: [root],
      currentIndex: 0,
    );
  }
}

final navigationStateProvider =
    StateNotifierProvider<NavigationStateNotifier, NavigationState>(
  (ref) => NavigationStateNotifier(),
);
```

**Test**: `test/presentation/providers/navigation_state_provider_test.dart`

```dart
void main() {
  group('NavigationStateNotifier', () {
    late NavigationStateNotifier notifier;

    setUp(() {
      notifier = NavigationStateNotifier();
    });

    test('initial state is empty', () {
      expect(notifier.state.stack, isEmpty);
      expect(notifier.state.currentIndex, -1);
    });

    test('push adds route to stack', () {
      notifier.push(WorkspaceRoute.home(groupId: 1));
      expect(notifier.state.stack.length, 1);
      expect(notifier.state.currentIndex, 0);
    });

    test('pop removes route from stack', () {
      notifier.push(WorkspaceRoute.home(groupId: 1));
      notifier.push(WorkspaceRoute.calendar(groupId: 1));
      expect(notifier.pop(), isTrue);
      expect(notifier.state.currentIndex, 0);
    });

    test('pop returns false when at root', () {
      notifier.push(WorkspaceRoute.home(groupId: 1));
      expect(notifier.pop(), isTrue);
      expect(notifier.pop(), isFalse);
    });
  });
}
```

---

### Step 3: Create WorkspaceRouterDelegate

**File**: `frontend/lib/core/navigation/workspace_router_delegate.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:your_app/core/navigation/workspace_route.dart';
import 'package:your_app/presentation/providers/navigation_state_provider.dart';

class WorkspaceRouterDelegate extends RouterDelegate<WorkspaceRoute>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<WorkspaceRoute> {
  final WidgetRef ref;

  @override
  final GlobalKey<NavigatorState> navigatorKey;

  WorkspaceRouterDelegate(this.ref)
      : navigatorKey = GlobalKey<NavigatorState>() {
    // Listen to navigation state changes
    ref.listen<NavigationState>(navigationStateProvider, (previous, next) {
      notifyListeners();
    });
  }

  @override
  Widget build(BuildContext context) {
    final navigationState = ref.watch(navigationStateProvider);

    return Navigator(
      key: navigatorKey,
      pages: _buildPages(navigationState),
      onPopPage: _onPopPage,
    );
  }

  List<Page> _buildPages(NavigationState navigationState) {
    if (navigationState.stack.isEmpty) {
      return [
        MaterialPage(
          key: const ValueKey('empty'),
          child: Container(), // Or loading screen
        ),
      ];
    }

    return navigationState.stack.map((route) {
      return route.when(
        home: (groupId) => MaterialPage(
          key: ValueKey('home-$groupId'),
          child: GroupHomeView(groupId: groupId),
        ),
        channel: (groupId, channelId) => MaterialPage(
          key: ValueKey('channel-$groupId-$channelId'),
          child: ChannelView(groupId: groupId, channelId: channelId),
        ),
        calendar: (groupId) => MaterialPage(
          key: ValueKey('calendar-$groupId'),
          child: CalendarView(groupId: groupId),
        ),
        admin: (groupId) => MaterialPage(
          key: ValueKey('admin-$groupId'),
          child: AdminView(groupId: groupId),
        ),
        memberManagement: (groupId) => MaterialPage(
          key: ValueKey('member-$groupId'),
          child: MemberManagementView(groupId: groupId),
        ),
      );
    }).toList();
  }

  bool _onPopPage(Route<dynamic> route, dynamic result) {
    if (!route.didPop(result)) {
      return false;
    }

    ref.read(navigationStateProvider.notifier).pop();
    return true;
  }

  @override
  Future<bool> popRoute() async {
    final navigationState = ref.read(navigationStateProvider);

    if (navigationState.isAtRoot) {
      // Exit workspace to global home
      return false; // Let system handle (exit app or go to previous route)
    } else {
      // Pop to previous view
      return ref.read(navigationStateProvider.notifier).pop();
    }
  }

  @override
  Future<void> setNewRoutePath(WorkspaceRoute configuration) async {
    // Not needed if not using URL routing
    // ref.read(navigationStateProvider.notifier).push(configuration);
  }
}
```

---

### Step 4: Integrate into WorkspacePage

**File**: `frontend/lib/presentation/pages/workspace/workspace_page.dart`

```dart
class WorkspacePage extends ConsumerWidget {
  final int initialGroupId;

  const WorkspacePage({required this.initialGroupId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize navigation state on first build
    useEffect(() {
      final notifier = ref.read(navigationStateProvider.notifier);
      notifier.resetToRoot(WorkspaceRoute.home(groupId: initialGroupId));
      return null;
    }, [initialGroupId]);

    final routerDelegate = WorkspaceRouterDelegate(ref);

    return Router(
      routerDelegate: routerDelegate,
      backButtonDispatcher: RootBackButtonDispatcher(),
    );
  }
}
```

---

## Common Navigation Patterns

### Pattern 1: Navigate to Channel

```dart
// In any widget
final notifier = ref.read(navigationStateProvider.notifier);
notifier.push(WorkspaceRoute.channel(groupId: groupId, channelId: channelId));
```

### Pattern 2: Context-Aware Group Switch

```dart
Future<void> switchGroup(int newGroupId) async {
  final currentRoute = ref.read(navigationStateProvider).current;
  if (currentRoute == null) return;

  final context = ViewContext.fromRoute(currentRoute);
  WorkspaceRoute targetRoute;

  switch (context.type) {
    case ViewType.channel:
      // Get first channel in new group
      final channels = await fetchChannels(newGroupId);
      targetRoute = WorkspaceRoute.channel(
        groupId: newGroupId,
        channelId: channels.firstOrNull?.id ?? -1,
      );
      if (targetRoute.channelId == -1) {
        // No channels, fallback to home
        targetRoute = WorkspaceRoute.home(groupId: newGroupId);
      }
      break;
    case ViewType.calendar:
      targetRoute = WorkspaceRoute.calendar(groupId: newGroupId);
      break;
    case ViewType.admin:
      // Check permissions first
      final perms = await loadPermissions(newGroupId);
      targetRoute = perms.canAccessAdmin()
          ? WorkspaceRoute.admin(groupId: newGroupId)
          : WorkspaceRoute.home(groupId: newGroupId);
      break;
    default:
      targetRoute = WorkspaceRoute.home(groupId: newGroupId);
  }

  ref.read(navigationStateProvider.notifier).replace(targetRoute);
}
```

### Pattern 3: Permission-Aware Navigation

```dart
Future<void> navigateToAdmin(int groupId) async {
  final perms = ref.read(permissionContextProvider);

  if (perms.canAccessAdmin()) {
    ref.read(navigationStateProvider.notifier).push(
      WorkspaceRoute.admin(groupId: groupId),
    );
  } else {
    showSnackBar('You do not have admin permissions');
  }
}
```

---

## Testing Commands

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/core/navigation/navigation_state_test.dart

# Run with coverage
flutter test --coverage

# Analyze code
flutter analyze

# Format code
dart format lib/ test/
```

---

## Troubleshooting

### Issue: "Navigator pages must have unique keys"
**Solution**: Ensure each MaterialPage has unique ValueKey based on route parameters

### Issue: "popRoute() not being called on back button"
**Solution**: Ensure RouterDelegate mixes in PopNavigatorRouterDelegateMixin and implements popRoute()

### Issue: "Navigation state not updating UI"
**Solution**: Ensure RouterDelegate calls notifyListeners() when state changes, or use ref.listen() pattern

### Issue: "Permission checks too slow"
**Solution**: Cache permissions per group, avoid repeated API calls

---

## Next Steps

After completing this implementation:

1. Run `/speckit.tasks` to generate task breakdown
2. Create feature branch: `git checkout -b 001-workspace-navigation-refactor`
3. Implement Phase 1 (core models)
4. Write tests for each component
5. Iterate on Phase 2-5
6. Use MCP tools for validation: `mcp__dart-flutter__flutter_analyze`

---

## References

- [Flutter Navigator 2.0 Guide](https://docs.flutter.dev/ui/navigation/url-strategies)
- [Riverpod Documentation](https://riverpod.dev)
- [freezed Package](https://pub.dev/packages/freezed)
- Project docs: `docs/implementation/frontend/`
