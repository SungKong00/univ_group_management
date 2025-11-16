import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'core/theme/theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/services/local_storage.dart';
import 'core/constants/app_constants.dart';
import 'core/lifecycle/app_lifecycle_observer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 스플래시 최소 표시 시간 보장 (깜빡임 방지)
  final splashStartTime = DateTime.now();
  const minSplashDuration = Duration(milliseconds: 1000);

  try {
    // Load environment variables
    await dotenv.load(fileName: '.env');

    // 웹 환경에서 폰트 프리로드 (FOUC 방지)
    // 비차단 방식: Regular(400)만 백그라운드 로드, 앱 시작 차단 방지
    if (kIsWeb) {
      developer.log(
        'Starting Noto Sans KR Regular font preload (non-blocking)...',
        name: 'main',
      );
      // await 제거! 백그라운드에서 로드
      GoogleFonts.pendingFonts([
            GoogleFonts.notoSansKr(), // Regular(400)만 프리로드
          ])
          .then((_) {
            developer.log(
              'Noto Sans KR Regular font loaded successfully',
              name: 'main',
            );
          })
          .catchError((e) {
            developer.log(
              'Font preloading failed (continuing anyway): $e',
              name: 'main',
              level: 900,
            );
          });
    }

    // Initialize Korean locale for date formatting
    await initializeDateFormatting('ko_KR', null);

    // Initialize LocalStorage with eager loading (부트 타임 최적화)
    // access token만 즉시 로드하고 나머지는 백그라운드에서 프리로드
    await LocalStorage.instance.initEagerData();

    // ✅ Phase 2: AuthService 제거
    // Auto login은 currentUserProvider의 build()에서 자동으로 실행됩니다.
    // 더 이상 main()에서 수동으로 tryAutoLogin()을 호출할 필요가 없습니다.
    developer.log(
      'Auto login will be handled by currentUserProvider',
      name: 'main',
    );
  } catch (error) {
    developer.log('Initialization error: $error', name: 'main');
    // 초기화 실패해도 앱은 실행
  }

  // 최소 스플래시 표시 시간 보장
  final elapsedTime = DateTime.now().difference(splashStartTime);
  if (elapsedTime < minSplashDuration) {
    await Future.delayed(minSplashDuration - elapsedTime);
  }

  runApp(const ProviderScope(child: UniversityGroupApp()));
}

class UniversityGroupApp extends ConsumerStatefulWidget {
  const UniversityGroupApp({super.key});

  @override
  ConsumerState<UniversityGroupApp> createState() => _UniversityGroupAppState();
}

class _UniversityGroupAppState extends ConsumerState<UniversityGroupApp> {
  late final AppLifecycleObserver _lifecycleObserver;

  @override
  void initState() {
    super.initState();

    // Phase 3: Register AppLifecycleObserver for app termination handling
    _lifecycleObserver = AppLifecycleObserver(ref);
    WidgetsBinding.instance.addObserver(_lifecycleObserver);

    developer.log(
      'AppLifecycleObserver registered',
      name: 'UniversityGroupApp',
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    _lifecycleObserver.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 테마 모드 감시 (다크모드 전환 대응)
    final themeMode = ref.watch(themeModeProvider);

    // ✅ Phase 2: goRouterProvider 사용
    // currentUserProvider와 연결된 GoRouter를 사용합니다.
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: AppConstants.appName,

      // 테마 설정 (라이트/다크 모드 지원)
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode, // 현재 선택된 테마 모드

      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: child!,
        breakpoints: [
          const Breakpoint(start: 0, end: 600, name: MOBILE),
          const Breakpoint(start: 601, end: 800, name: TABLET),
          const Breakpoint(start: 801, end: 1920, name: DESKTOP),
          const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
        ],
      ),
    );
  }
}
