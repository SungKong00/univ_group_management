import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/navigation/navigation_state.dart';
import 'package:frontend/core/navigation/workspace_route.dart';
import 'package:frontend/core/navigation/view_context.dart';
import 'package:frontend/presentation/providers/navigation_state_provider.dart';
import 'package:frontend/presentation/widgets/navigation/responsive_navigation_wrapper.dart';

/// Custom RouterDelegate for workspace navigation using Navigator 2.0
class WorkspaceRouterDelegate extends RouterDelegate<WorkspaceRoute>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<WorkspaceRoute> {
  final WidgetRef ref;
  final bool isTestMode;

  @override
  final GlobalKey<NavigatorState> navigatorKey;

  WorkspaceRouterDelegate(this.ref, {this.isTestMode = false})
    : navigatorKey = GlobalKey<NavigatorState>() {
    // Listen to navigation state changes for screen reader announcements
    ref.listen<NavigationState>(navigationStateProvider, (previous, next) {
      if (previous?.current != next.current && next.current != null) {
        _announceNavigationChange(next.current!);
      }
    });
  }

  /// Announce navigation state changes to screen readers
  void _announceNavigationChange(WorkspaceRoute route) {
    final announcement = route.when(
      home: (groupId) => '홈 페이지로 이동했습니다',
      channel: (groupId, channelId) => '채널 $channelId로 이동했습니다',
      calendar: (groupId) => '캘린더 페이지로 이동했습니다',
      admin: (groupId) => '관리 페이지로 이동했습니다',
      memberManagement: (groupId) => '멤버 관리 페이지로 이동했습니다',
    );

    SemanticsService.announce(announcement, TextDirection.ltr);
  }

  @override
  WorkspaceRoute? get currentConfiguration {
    final state = ref.read(navigationStateProvider);
    return state.current;
  }

  @override
  Widget build(BuildContext context) {
    // CRITICAL: Use ref.watch() to automatically rebuild when state changes
    final navigationState = ref.watch(navigationStateProvider);

    // T105: Show loading indicator overlay if loading
    final child = Navigator(
      key: navigatorKey,
      pages: _buildPages(navigationState),
      onDidRemovePage: (page) {
        // Delay provider modification to avoid modifying during build
        Future.microtask(() {
          ref.read(navigationStateProvider.notifier).pop();
        });
      },
    );

    // T105: Wrap with loading indicator
    if (navigationState.isLoading) {
      return Stack(
        children: [
          child,
          // Semi-transparent overlay
          Container(
            color: Colors.black54,
            child: Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        navigationState.loadingMessage ?? '로딩 중...',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      // T106: Cancel button
                      TextButton(
                        onPressed: () {
                          ref
                              .read(navigationStateProvider.notifier)
                              .cancelLoading();
                        },
                        child: const Text('취소'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // T107 & T110: Display error banner with clear user guidance
    if (navigationState.lastError != null) {
      return Stack(
        children: [
          child,
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Material(
              color: Colors.red.shade700,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '네비게이션 오류',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            navigationState.lastError!,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          // T110: Clear user guidance (Korean)
                          Text(
                            navigationState.isOffline
                                ? '인터넷 연결을 확인하고 다시 시도해주세요.'
                                : '다시 시도하거나, 문제가 지속되면 고객 지원에 문의해주세요.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        ref.read(navigationStateProvider.notifier).clearError();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    // T108: Display offline indicator
    if (navigationState.isOffline) {
      return Stack(
        children: [
          child,
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Material(
              color: Colors.orange.shade700,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '오프라인 상태입니다. 일부 기능을 사용할 수 없습니다.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return child;
  }

  /// Build list of pages from navigation stack
  List<Page> _buildPages(NavigationState navigationState) {
    final stack = navigationState.stack;
    if (stack.isEmpty) {
      // Return a default empty page to satisfy Navigator's requirement
      return [
        const MaterialPage(
          key: ValueKey('empty'),
          child: Scaffold(body: Center(child: Text('로딩 중...'))),
        ),
      ];
    }

    // Only show pages up to currentIndex
    final currentIndex = navigationState.currentIndex;
    final visibleStack = currentIndex >= 0
        ? stack.sublist(0, currentIndex + 1)
        : <WorkspaceRoute>[];

    if (visibleStack.isEmpty) {
      // Return default page if visible stack is empty
      return [
        const MaterialPage(
          key: ValueKey('empty'),
          child: Scaffold(body: Center(child: Text('로딩 중...'))),
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

    // T106: If loading, cancel the loading operation instead of popping
    if (navigationState.isLoading) {
      ref.read(navigationStateProvider.notifier).cancelLoading();
      return true; // Consumed the back button press
    }

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

  /// Get current view type from navigation state
  ViewType _getCurrentViewType() {
    final currentRoute = ref.read(navigationStateProvider).current;
    if (currentRoute == null) return ViewType.home;

    return currentRoute.when(
      home: (_) => ViewType.home,
      channel: (_, __) => ViewType.channel,
      calendar: (_) => ViewType.calendar,
      admin: (_) => ViewType.admin,
      memberManagement: (_) => ViewType.memberManagement,
    );
  }

  /// Build navigation items for current group
  List<NavigationItem> _buildNavigationItems(int groupId) {
    final currentViewType = _getCurrentViewType();

    return [
      NavigationItem(
        label: '홈',
        icon: Icons.home,
        isSelected: currentViewType == ViewType.home,
        onTap: () {
          ref
              .read(navigationStateProvider.notifier)
              .push(WorkspaceRoute.home(groupId: groupId));
        },
      ),
      NavigationItem(
        label: '채널',
        icon: Icons.tag,
        isSelected: currentViewType == ViewType.channel,
        onTap: () {
          // Note: This will need actual channel ID in production
          // For now, this is a placeholder
        },
      ),
      NavigationItem(
        label: '캘린더',
        icon: Icons.calendar_today,
        isSelected: currentViewType == ViewType.calendar,
        onTap: () {
          ref
              .read(navigationStateProvider.notifier)
              .push(WorkspaceRoute.calendar(groupId: groupId));
        },
      ),
      NavigationItem(
        label: '관리',
        icon: Icons.settings,
        isSelected: currentViewType == ViewType.admin,
        onTap: () {
          ref
              .read(navigationStateProvider.notifier)
              .push(WorkspaceRoute.admin(groupId: groupId));
        },
      ),
      NavigationItem(
        label: '멤버 관리',
        icon: Icons.people,
        isSelected: currentViewType == ViewType.memberManagement,
        onTap: () {
          ref
              .read(navigationStateProvider.notifier)
              .push(WorkspaceRoute.memberManagement(groupId: groupId));
        },
      ),
    ];
  }

  // View builders with ResponsiveNavigationWrapper
  Widget _buildHomeView(int groupId) {
    final content = Scaffold(
      appBar: AppBar(
        title: Text('Home - Group $groupId'),
        automaticallyImplyLeading:
            false, // Handled by ResponsiveNavigationWrapper
      ),
      body: Center(child: Text('Home View for Group $groupId')),
    );

    if (isTestMode) return content;

    return ResponsiveNavigationWrapper(
      navigationItems: _buildNavigationItems(groupId),
      child: content,
    );
  }

  Widget _buildChannelView(int groupId, int channelId) {
    final content = Scaffold(
      appBar: AppBar(
        title: Text('Channel $channelId - Group $groupId'),
        automaticallyImplyLeading: false,
      ),
      body: Center(child: Text('Channel View $channelId')),
    );

    if (isTestMode) return content;

    return ResponsiveNavigationWrapper(
      navigationItems: _buildNavigationItems(groupId),
      child: content,
    );
  }

  Widget _buildCalendarView(int groupId) {
    final content = Scaffold(
      appBar: AppBar(
        title: Text('Calendar - Group $groupId'),
        automaticallyImplyLeading: false,
      ),
      body: Center(child: Text('Calendar View for Group $groupId')),
    );

    if (isTestMode) return content;

    return ResponsiveNavigationWrapper(
      navigationItems: _buildNavigationItems(groupId),
      child: content,
    );
  }

  Widget _buildAdminView(int groupId) {
    final content = Scaffold(
      appBar: AppBar(
        title: Text('Admin - Group $groupId'),
        automaticallyImplyLeading: false,
      ),
      body: Center(child: Text('Admin View for Group $groupId')),
    );

    if (isTestMode) return content;

    return ResponsiveNavigationWrapper(
      navigationItems: _buildNavigationItems(groupId),
      child: content,
    );
  }

  Widget _buildMemberManagementView(int groupId) {
    final content = Scaffold(
      appBar: AppBar(
        title: Text('Members - Group $groupId'),
        automaticallyImplyLeading: false,
      ),
      body: Center(child: Text('Member Management for Group $groupId')),
    );

    if (isTestMode) return content;

    return ResponsiveNavigationWrapper(
      navigationItems: _buildNavigationItems(groupId),
      child: content,
    );
  }
}
