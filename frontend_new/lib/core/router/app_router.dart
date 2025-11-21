import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/component_showcase/presentation/pages/component_showcase_page.dart';
import '../../features/component_showcase/presentation/pages/v2_components_page.dart';

/// 앱 라우터 설정
final appRouter = GoRouter(
  initialLocation: '/component',
  routes: [
    GoRoute(
      path: '/component',
      name: 'component',
      pageBuilder: (context, state) =>
          const MaterialPage(child: ComponentShowcasePage()),
    ),
    GoRoute(
      path: '/v2',
      name: 'v2',
      pageBuilder: (context, state) =>
          const MaterialPage(child: V2ComponentsPage()),
    ),
  ],
  errorBuilder: (context, state) =>
      Scaffold(body: Center(child: Text('Page not found: ${state.uri}'))),
);
