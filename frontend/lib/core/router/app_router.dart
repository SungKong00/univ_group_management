import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/home/home_page.dart';
import '../../presentation/pages/workspace/workspace_page.dart';
import '../../presentation/pages/calendar/calendar_page.dart';
import '../../presentation/pages/activity/activity_page.dart';
import '../../presentation/pages/profile/profile_page.dart';
import '../../presentation/pages/main/main_layout.dart';
import '../constants/app_constants.dart';
import '../services/auth_service.dart';

final _authService = AuthService();

final GoRouter appRouter = GoRouter(
  initialLocation: AppConstants.loginRoute,
  routes: [
    GoRoute(
      path: AppConstants.loginRoute,
      name: 'login',
      builder: (context, state) => const LoginPage(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainLayout(child: child),
      routes: [
        GoRoute(
          path: AppConstants.homeRoute,
          name: 'home',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: AppConstants.workspaceRoute,
          name: 'workspace',
          builder: (context, state) => const WorkspacePage(),
          routes: [
            GoRoute(
              path: '/:groupId',
              name: 'group-workspace',
              builder: (context, state) {
                final groupId = state.pathParameters['groupId']!;
                return WorkspacePage(groupId: groupId);
              },
              routes: [
                GoRoute(
                  path: '/channel/:channelId',
                  name: 'channel',
                  builder: (context, state) {
                    final groupId = state.pathParameters['groupId']!;
                    final channelId = state.pathParameters['channelId']!;
                    return WorkspacePage(
                      groupId: groupId,
                      channelId: channelId,
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
          builder: (context, state) => const CalendarPage(),
        ),
        GoRoute(
          path: AppConstants.activityRoute,
          name: 'activity',
          builder: (context, state) => const ActivityPage(),
        ),
        GoRoute(
          path: AppConstants.profileRoute,
          name: 'profile',
          builder: (context, state) => const ProfilePage(),
        ),
      ],
    ),
  ],
  redirect: (context, state) {
    final isLoggedIn = _authService.isLoggedIn;
    final currentPath = state.uri.toString();
    final isLoginRoute = currentPath == AppConstants.loginRoute;

    // 로그인하지 않은 경우 로그인 페이지로
    if (!isLoggedIn && !isLoginRoute) {
      return AppConstants.loginRoute;
    }

    // 이미 로그인한 경우 로그인 페이지 접근시 홈으로
    if (isLoggedIn && isLoginRoute) {
      return AppConstants.homeRoute;
    }

    return null;
  },
);