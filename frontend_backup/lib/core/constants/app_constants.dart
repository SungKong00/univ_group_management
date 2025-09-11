class AppConstants {
  // API 관련 상수
  static const String baseUrl = 'http://localhost:8080/api/v1';
  static const String authEndpoint = '/auth';
  static const String usersEndpoint = '/users';
  static const String groupsEndpoint = '/groups';
  
  // 토큰 관련 상수
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  
  // 네트워크 타임아웃 (밀리초)
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
  static const int sendTimeout = 30000;
  
  // 앱 정보
  static const String appName = '대학 그룹 관리';
  static const String appVersion = '1.0.0';

  // 웹뷰 기본 URL (원하는 주소로 변경하세요)
  // 예: Android 에뮬레이터에서 로컬 서버 접속은 http://10.0.2.2:8080
  static const String webAppUrl = 'https://flutter.dev';
  
  // 페이지네이션
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
}

class ApiEndpoints {
  // 인증 관련
  static const String login = '${AppConstants.authEndpoint}/login';
  static const String register = '${AppConstants.authEndpoint}/register';
  static const String refreshToken = '${AppConstants.authEndpoint}/refresh';
  static const String logout = '${AppConstants.authEndpoint}/logout';
  
  // 사용자 관련
  static const String userProfile = '${AppConstants.usersEndpoint}/profile';
  static const String updateProfile = '${AppConstants.usersEndpoint}/profile';
  
  // 그룹 관련 (향후 추가 예정)
  static const String groups = AppConstants.groupsEndpoint;
  static String groupById(int id) => '${AppConstants.groupsEndpoint}/$id';
  static String groupMembers(int id) => '${AppConstants.groupsEndpoint}/$id/members';
}

class StorageKeys {
  static const String isFirstLaunch = 'is_first_launch';
  static const String themeMode = 'theme_mode';
  static const String languageCode = 'language_code';
}
