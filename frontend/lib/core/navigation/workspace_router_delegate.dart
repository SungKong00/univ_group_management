import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/navigation/navigation_state.dart';
import 'package:frontend/core/navigation/workspace_route.dart';
import 'package:frontend/presentation/providers/navigation_state_provider.dart';

/// Custom RouterDelegate for workspace navigation using Navigator 2.0
class WorkspaceRouterDelegate extends RouterDelegate<WorkspaceRoute>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<WorkspaceRoute> {
  final WidgetRef ref;

  @override
  final GlobalKey<NavigatorState> navigatorKey;

  WorkspaceRouterDelegate(this.ref)
      : navigatorKey = GlobalKey<NavigatorState>() {
    // Listen to navigation state changes and notify listeners
    ref.listen<NavigationState>(
      navigationStateProvider,
      (previous, next) {
        notifyListeners();
      },
    );
  }

  NavigationState get _navigationState => ref.read(navigationStateProvider);

  @override
  WorkspaceRoute? get currentConfiguration => _navigationState.current;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: _buildPages(),
      onDidRemovePage: (page) {
        // Pop from navigation state when page is removed
        ref.read(navigationStateProvider.notifier).pop();
      },
    );
  }

  /// Build list of pages from navigation stack
  List<Page> _buildPages() {
    final stack = _navigationState.stack;
    if (stack.isEmpty) {
      // Return a default empty page to satisfy Navigator's requirement
      return [
        const MaterialPage(
          key: ValueKey('empty'),
          child: Scaffold(
            body: Center(child: Text('Loading...')),
          ),
        ),
      ];
    }

    // Only show pages up to currentIndex
    final currentIndex = _navigationState.currentIndex;
    final visibleStack =
        currentIndex >= 0 ? stack.sublist(0, currentIndex + 1) : <WorkspaceRoute>[];

    if (visibleStack.isEmpty) {
      // Return default page if visible stack is empty
      return [
        const MaterialPage(
          key: ValueKey('empty'),
          child: Scaffold(
            body: Center(child: Text('Loading...')),
          ),
        ),
      ];
    }

    return visibleStack.map((route) => _buildPage(route)).toList();
  }

  /// Build a single page from a route
  MaterialPage _buildPage(WorkspaceRoute route) {
    return route.when(
      home: (groupId) => MaterialPage(
        key: ValueKey('home-$groupId'),
        child: _buildHomeView(groupId),
      ),
      channel: (groupId, channelId) => MaterialPage(
        key: ValueKey('channel-$groupId-$channelId'),
        child: _buildChannelView(groupId, channelId),
      ),
      calendar: (groupId) => MaterialPage(
        key: ValueKey('calendar-$groupId'),
        child: _buildCalendarView(groupId),
      ),
      admin: (groupId) => MaterialPage(
        key: ValueKey('admin-$groupId'),
        child: _buildAdminView(groupId),
      ),
      memberManagement: (groupId) => MaterialPage(
        key: ValueKey('member-management-$groupId'),
        child: _buildMemberManagementView(groupId),
      ),
    );
  }

  @override
  Future<bool> popRoute() async {
    final navigationState = ref.read(navigationStateProvider);

    if (navigationState.isAtRoot || !navigationState.canPop) {
      // At root, exit workspace (return false to let system handle it)
      return false;
    } else {
      // Pop to previous view
      ref.read(navigationStateProvider.notifier).pop();
      return true;
    }
  }

  @override
  Future<void> setNewRoutePath(WorkspaceRoute configuration) async {
    // This is called when deep-linking or URL changes
    // For now, we just push the new route
    ref.read(navigationStateProvider.notifier).push(configuration);
  }

  // Placeholder view builders (to be implemented with actual views)
  Widget _buildHomeView(int groupId) {
    return Scaffold(
      appBar: AppBar(title: Text('Home - Group $groupId')),
      body: Center(child: Text('Home View for Group $groupId')),
    );
  }

  Widget _buildChannelView(int groupId, int channelId) {
    return Scaffold(
      appBar: AppBar(title: Text('Channel $channelId - Group $groupId')),
      body: Center(child: Text('Channel View $channelId')),
    );
  }

  Widget _buildCalendarView(int groupId) {
    return Scaffold(
      appBar: AppBar(title: Text('Calendar - Group $groupId')),
      body: Center(child: Text('Calendar View for Group $groupId')),
    );
  }

  Widget _buildAdminView(int groupId) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin - Group $groupId')),
      body: Center(child: Text('Admin View for Group $groupId')),
    );
  }

  Widget _buildMemberManagementView(int groupId) {
    return Scaffold(
      appBar: AppBar(title: Text('Members - Group $groupId')),
      body: Center(child: Text('Member Management for Group $groupId')),
    );
  }
}
