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

  // UI Constants
  static const double mobileBreakpoint = 768;
  static const double maxContentWidth = 1200;
  static const double sidebarWidth = 256;
  static const double sidebarCollapsedWidth = 72;
  static const double backButtonWidth = 72;
  static const double topNavigationHeight = 64;

  // Animation Duration
  static const Duration animationDuration = Duration(milliseconds: 200);
}
