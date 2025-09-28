import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/network/dio_client.dart';
import 'core/constants/app_constants.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize DioClient
  DioClient().init();

  runApp(
    const ProviderScope(
      child: UniversityGroupApp(),
    ),
  );
}

class UniversityGroupApp extends ConsumerWidget {
  const UniversityGroupApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: child!,
        breakpoints: [
          const Breakpoint(start: 0, end: 450, name: MOBILE),
          const Breakpoint(start: 451, end: 800, name: TABLET),
          const Breakpoint(start: 801, end: 1920, name: DESKTOP),
          const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
        ],
      ),
    );
  }
}
