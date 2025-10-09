import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/auth/profile_setup_page.dart';
import '../../presentation/pages/home/home_page.dart';
import '../../presentation/pages/workspace/workspace_page.dart';
import '../../presentation/pages/calendar/calendar_page.dart';
import '../../presentation/pages/activity/activity_page.dart';
import '../../presentation/pages/profile/profile_page.dart';
import '../../presentation/pages/group/group_admin_page.dart';
import '../../presentation/pages/main/main_layout.dart';
import '../constants/app_constants.dart';
import '../services/auth_service.dart';

/// AuthService 상태 변화를 GoRouter에 알리는 ChangeNotifier
class AuthChangeNotifier extends ChangeNotifier {
  void notifyAuthChanged() {
    notifyListeners();
  }
}

final _authService = AuthService();
final authChangeNotifier = AuthChangeNotifier();

final GoRouter appRouter = GoRouter(
  initialLocation: AppConstants.loginRoute,
  refreshListenable: authChangeNotifier,
  routes: [
    GoRoute(
      path: AppConstants.loginRoute,
      name: 'login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: AppConstants.onboardingRoute,
      name: 'profile-setup',
      builder: (context, state) => const ProfileSetupPage(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainLayout(child: child),
      routes: [
        GoRoute(
          path: AppConstants.homeRoute,
          name: 'home',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: HomePage()),
        ),
        GoRoute(
          path: AppConstants.workspaceRoute,
          name: 'workspace',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: WorkspacePage()),
          routes: [
            GoRoute(
              path: '/:groupId',
              name: 'group-workspace',
              pageBuilder: (context, state) {
                final groupId = state.pathParameters['groupId']!;
                return NoTransitionPage(child: WorkspacePage(groupId: groupId));
              },
              routes: [
                GoRoute(
                  path: '/channel/:channelId',
                  name: 'channel',
                  pageBuilder: (context, state) {
                    final groupId = state.pathParameters['groupId']!;
                    final channelId = state.pathParameters['channelId']!;
                    return NoTransitionPage(
                      child: WorkspacePage(
                        groupId: groupId,
                        channelId: channelId,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: AppConstants.calendarRoute,
          name: 'calendar',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: CalendarPage()),
        ),
        GoRoute(
          path: AppConstants.activityRoute,
          name: 'activity',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ActivityPage()),
        ),
        GoRoute(
          path: AppConstants.profileRoute,
          name: 'profile',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ProfilePage()),
        ),
        GoRoute(
          path: AppConstants.groupAdminRoute,
          name: 'group-admin',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: GroupAdminPage()),
        ),
      ],
    ),
  ],
  redirect: (context, state) {
    final isLoggedIn = _authService.isLoggedIn;
    final currentPath = state.uri.path;
    final isLoginRoute = currentPath == AppConstants.loginRoute;
    final isOnboardingRoute = currentPath == AppConstants.onboardingRoute;
    final isProfileCompleted =
        _authService.currentUser?.profileCompleted ?? false;

    if (!isLoggedIn) {
      return isLoginRoute ? null : AppConstants.loginRoute;
    }

    if (!isProfileCompleted) {
      return isOnboardingRoute ? null : AppConstants.onboardingRoute;
    }

    if (isLoginRoute || isOnboardingRoute) {
      return AppConstants.homeRoute;
    }

    return null;
  },
);
