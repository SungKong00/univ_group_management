class AppConstants {
  // Base API path. Backend serves Flutter Web under same host.
  // In Flutter web dev (port 5173), absolute URL avoids 404 from the dev server.
  // Adjust host/port if your backend differs.
  static const String baseUrl = 'http://localhost:8080/api';

  // Keys for local storage
  static const String accessTokenKey = 'access_token';
  static const String userDataKey = 'user_data';

  // App strings
  static const String appName = '대학 그룹 관리';

  // Google OAuth (Web) Client ID
  // Provided by user for this project
  static const String googleWebClientId =
      '264783921782-imbndkfntp44qurjvjdlrk0r342ojp83.apps.googleusercontent.com';

  // Feature flags for email verification/OTP (MVP: mocked)
  static const bool requireEmailOtp = false; // when true, block submit until verified
  static const bool mockEmailVerification = true; // when true, bypass network and always succeed
}

class ApiEndpoints {
  // Auth (Google OAuth2)
  static const String googleCallback = '/auth/google/callback';
  static const String googleFallback = '/auth/google';
  static const String logout = '/auth/logout';

  // Users
  static const String users = '/users';
  static const String me = '/me';
  static String nicknameCheck(String nickname) =>
      '/users/nickname-check?nickname=$nickname';

  // Email verification (OTP)
  static const String emailSend = '/email/verification/send';
  static const String emailVerify = '/email/verification/verify';
}

class ResponsiveBreakpoints {
  // 반응형 브레이크포인트
  static const double mobile = 768.0;
  static const double tablet = 1024.0;
  static const double desktop = 1440.0;

  // 댓글 사이드바 관련 상수
  static const double commentsSidebarWidth = 400.0;
  static const double commentsSidebarMinWidth = 300.0;
  static const double commentsSidebarMaxWidth = 500.0;

  // 애니메이션 지속시간
  static const Duration sidebarAnimationDuration = Duration(milliseconds: 300);

  // 댓글 UI 관련 상수
  static const double commentAvatarSize = 32.0;
  static const double commentPadding = 16.0;
  static const double commentInputHeight = 56.0;
  static const double commentMaxInputHeight = 120.0;
}

class UIConstants {
  // 일반적인 UI 상수
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  // 댓글 관련 UI 상수
  static const double commentBorderRadius = 12.0;
  static const double commentSpacing = 12.0;

  // 그림자 및 elevation
  static const double defaultElevation = 2.0;
  static const double sidebarElevation = 8.0;
}
