import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/auth/profile_setup_page.dart';
import '../../presentation/pages/splash/splash_page.dart';
import '../../presentation/pages/home/home_page.dart';
import '../../presentation/pages/workspace/workspace_page.dart';
import '../../presentation/pages/calendar/calendar_page.dart';
import '../../presentation/pages/activity/activity_page.dart';
import '../../presentation/pages/profile/profile_page.dart';
import '../../presentation/pages/group/group_admin_page.dart';
import '../../presentation/pages/recruitment/recruitment_detail_page.dart';
import '../../presentation/pages/demo_calendar/demo_calendar_page.dart';
import '../../presentation/pages/demo/multi_select_popover_demo_page.dart';
import '../../presentation/pages/main/main_layout.dart';
import '../../presentation/pages/workspace/calendar/group_calendar_page.dart';
import '../constants/app_constants.dart';
import '../../presentation/providers/auth_provider.dart';
import '../models/auth_models.dart';

/// Riverpod Provider를 GoRouter와 연결하는 ChangeNotifier
///
/// currentUserProvider의 변경사항을 listen하여 GoRouter에 알립니다.
class AuthChangeListenable extends ChangeNotifier {
  AuthChangeListenable(this._ref) {
    _ref.listen<AsyncValue<UserInfo?>>(
      currentUserProvider,
      (_, __) => notifyListeners(),
    );
  }

  final Ref _ref;
}

/// GoRouter를 생성하는 Provider
///
/// ProviderScope 내부에서 Ref를 사용할 수 있도록 Provider로 감쌉니다.
final goRouterProvider = Provider<GoRouter>((ref) {
  final authChangeListenable = AuthChangeListenable(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authChangeListenable,
    routes: _routes,
    redirect: (context, state) => _redirect(ref, state),
  );
});

/// GoRouter 라우트 정의
final List<RouteBase> _routes = [
  GoRoute(
    path: '/splash',
    name: 'splash',
    builder: (context, state) => const SplashPage(),
  ),
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
  // TODO: 임시 데모 페이지 - 나중에 제거 (데모 기능 개발 완료 후)
  GoRoute(
    path: '/demo',
    name: 'demo-calendar',
    builder: (context, state) => const DemoCalendarPage(),
  ),
  GoRoute(
    path: '/demo-popover',
    name: 'demo-popover',
    builder: (context, state) => const MultiSelectPopoverDemoPage(),
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
                path: 'calendar',
                name: 'group-calendar',
                pageBuilder: (context, state) {
                  final groupId = int.parse(state.pathParameters['groupId']!);
                  return NoTransitionPage(
                    child: GroupCalendarPage(groupId: groupId),
                  );
                },
              ),
              GoRoute(
                path: 'channel/:channelId',
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
      GoRoute(
        path: '/recruitment/:id',
        name: 'recruitment-detail',
        pageBuilder: (context, state) {
          final recruitmentId = state.pathParameters['id']!;
          return NoTransitionPage(
            child: RecruitmentDetailPage(recruitmentId: recruitmentId),
          );
        },
      ),
    ],
  ),
];

/// GoRouter redirect 로직
///
/// currentUserProvider를 사용하여 인증 상태를 확인합니다.
String? _redirect(Ref ref, GoRouterState state) {
  final userAsync = ref.read(currentUserProvider);
  final currentPath = state.uri.path;
  final isSplashRoute = currentPath == '/splash';
  final isLoginRoute = currentPath == AppConstants.loginRoute;
  final isOnboardingRoute = currentPath == AppConstants.onboardingRoute;

  // 로딩 중일 때는 스플래시 페이지로
  if (userAsync.isLoading && !isSplashRoute) {
    return '/splash';
  }

  final user = userAsync.valueOrNull;
  final isLoggedIn = user != null;
  final isProfileCompleted = user?.profileCompleted ?? false;

  // 스플래시 페이지는 초기화 중에만 표시
  if (isSplashRoute) {
    // 인증 상태에 따라 적절한 페이지로 이동
    if (!isLoggedIn) {
      return AppConstants.loginRoute;
    }
    if (!isProfileCompleted) {
      return AppConstants.onboardingRoute;
    }
    return AppConstants.homeRoute;
  }

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
}

// ===== Legacy Support =====
// 기존 코드가 appRouter를 직접 사용하는 경우를 위해 유지
// 하지만 ProviderScope 없이는 동작하지 않으므로
// main.dart에서 goRouterProvider를 사용하도록 마이그레이션 필요

/// Legacy appRouter (Deprecated)
///
/// 이 변수는 하위 호환성을 위해 유지되지만,
/// Riverpod ProviderScope 없이는 제대로 동작하지 않습니다.
///
/// main.dart에서 goRouterProvider를 사용하도록 업데이트하세요.
@Deprecated('Use goRouterProvider instead')
final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: _routes,
  redirect: (context, state) {
    // Legacy mode: ProviderScope가 없으면 로그인 페이지로 리다이렉트
    return AppConstants.loginRoute;
  },
);
