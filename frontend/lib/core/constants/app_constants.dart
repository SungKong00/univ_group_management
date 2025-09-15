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

  // Users
  static const String users = '/users';
  static const String me = '/me';
  static String nicknameCheck(String nickname) =>
      '/users/nickname-check?nickname=$nickname';

  // Email verification (OTP)
  static const String emailSend = '/email/verification/send';
  static const String emailVerify = '/email/verification/verify';
}
