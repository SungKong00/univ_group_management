import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/auth_service.dart';
import 'core/services/local_storage.dart';
import 'core/constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize LocalStorage with eager loading (부트 타임 최적화)
  // access token만 즉시 로드하고 나머지는 백그라운드에서 프리로드
  await LocalStorage.instance.initEagerData();

  // Initialize services
  final authService = AuthService();
  authService.initialize();

  // Try auto login
  await authService.tryAutoLogin();

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
