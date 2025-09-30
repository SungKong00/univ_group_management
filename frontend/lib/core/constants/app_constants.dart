import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  static const String appName = 'University Group Management';
  static const String baseUrl = 'http://localhost:8080/api';

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';

  // Routes
  static const String loginRoute = '/login';
  static const String onboardingRoute = '/onboarding';
  static const String homeRoute = '/home';
  static const String workspaceRoute = '/workspace';
  static const String calendarRoute = '/calendar';
  static const String activityRoute = '/activity';
  static const String profileRoute = '/profile';

  // Google Sign-In configuration (loaded from .env file)
  static String get googleServerClientId =>
      dotenv.env['GOOGLE_SERVER_CLIENT_ID'] ?? '';
  static String get googleWebClientId =>
      dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '';
  static String get googleIosClientId =>
      dotenv.env['GOOGLE_IOS_CLIENT_ID'] ?? '';
  static String get googleAndroidClientId =>
      dotenv.env['GOOGLE_ANDROID_CLIENT_ID'] ?? '';

  // UI Constants - Responsive Breakpoints
  // 3단계 레이아웃 모드:
  // COMPACT (0-600px): 모바일 - 하단 네비게이션
  // MEDIUM (601-1024px): 태블릿 - 축소 사이드바
  // WIDE (1025px+): 데스크톱 - 전체 사이드바
  static const double compactBreakpoint = 600; // COMPACT 상한
  static const double mediumBreakpoint = 1024; // MEDIUM 상한

  // 레거시 브레이크포인트 (기존 responsive_framework 호환)
  static const double mobileBreakpoint = 450; // MOBILE 상한
  static const double tabletBreakpoint = 800; // TABLET 상한
  static const double desktopBreakpoint = 1920; // DESKTOP 상한

  // Layout Constants
  static const double maxContentWidth = 1200;
  static const double sidebarWidth = 256;
  static const double sidebarCollapsedWidth = 72;
  static const double backButtonWidth = 72;
  static const double topNavigationHeight = 64;

  // Animation Duration
  static const Duration animationDuration = Duration(milliseconds: 200);
}
