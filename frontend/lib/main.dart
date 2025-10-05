import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'core/theme/theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/services/auth_service.dart';
import 'core/services/local_storage.dart';
import 'core/constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load environment variables
    await dotenv.load(fileName: '.env');

    // Initialize Korean locale for date formatting
    await initializeDateFormatting('ko_KR', null);

    // Initialize LocalStorage with eager loading (부트 타임 최적화)
    // access token만 즉시 로드하고 나머지는 백그라운드에서 프리로드
    await LocalStorage.instance.initEagerData();

    // Initialize services
    final authService = AuthService();
    authService.initialize();

    // Try auto login (non-blocking, 실패해도 앱은 계속 실행)
    authService.tryAutoLogin().catchError((error) {
      developer.log('Auto login failed, continuing with manual login: $error', name: 'main');
      return false; // Return false to indicate auto login failed
    });
  } catch (error) {
    developer.log('Initialization error: $error', name: 'main');
    // 초기화 실패해도 앱은 실행
  }

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
    // 테마 모드 감시 (다크모드 전환 대응)
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConstants.appName,

      // 테마 설정 (라이트/다크 모드 지원)
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode, // 현재 선택된 테마 모드

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
