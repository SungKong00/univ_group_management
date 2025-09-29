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

  // Google Sign-In configuration (set via --dart-define at build time)
  static const String googleServerClientId =
      String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '264783921782-imbndkfntp44qurjvjdlrk0r342ojp83.apps.googleusercontent.com',
  );
  static const String googleWebClientId =
      String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', defaultValue: '');
  static const String googleIosClientId =
      String.fromEnvironment('GOOGLE_IOS_CLIENT_ID', defaultValue: '');
  static const String googleAndroidClientId =
      String.fromEnvironment('GOOGLE_ANDROID_CLIENT_ID', defaultValue: '');

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
