# Flutter Frontend Architecture

**⚠️ 현재 구현 상태**: Flutter 프로젝트가 완전히 구현되었으며, Google OAuth 인증 시스템이 백엔드와 연동 완료되었습니다.

이 문서는 Flutter 앱의 상세한 아키텍처와 구현 상태를 설명합니다.

---

## 1. 프로젝트 구조 (Clean Architecture)

### 1.1. 디렉토리 구조 ✅
```
lib/
├── main.dart                          # 앱 진입점
├── injection/                         # 의존성 주입 설정
│   └── injection.dart
├── core/                             # 핵심 유틸리티
│   ├── auth/
│   │   └── google_signin.dart        # Google OAuth 서비스
│   ├── constants/
│   │   └── app_constants.dart        # 앱 전역 상수
│   ├── network/
│   │   ├── dio_client.dart           # HTTP 클라이언트
│   │   ├── api_response.dart         # API 응답 모델
│   │   └── api_response.g.dart       # 자동 생성 코드
│   └── storage/
│       └── token_storage.dart        # 토큰 저장소
├── domain/                           # 비즈니스 레이어
│   └── repositories/
│       └── auth_repository.dart      # 인증 저장소 인터페이스
├── data/                            # 데이터 레이어
│   ├── models/
│   │   ├── user_model.dart          # 사용자 모델 (확장됨)
│   │   └── user_model.g.dart        # 자동 생성 코드
│   ├── services/
│   │   └── auth_service.dart        # 인증 API 서비스 (프로필 완성 API 포함)
│   └── repositories/
│       └── auth_repository_impl.dart # 인증 저장소 구현체
└── presentation/                    # 프레젠테이션 레이어
    ├── providers/
    │   └── auth_provider.dart       # 인증 상태 관리
    ├── screens/
    │   ├── auth/
    │   │   ├── login_screen.dart    # 로그인 화면
    │   │   ├── register_screen.dart # 회원가입 화면
    │   │   ├── role_selection_screen.dart # 역할 선택 화면 (학생/교수)
    │   │   └── profile_setup_screen.dart  # 프로필 설정 화면
    │   ├── home/
    │   │   └── home_screen.dart     # 홈 화면
    │   └── webview/
    │       └── webview_screen.dart  # 웹뷰 화면
    └── theme/
        └── app_theme.dart           # 앱 테마 설정
```

### 1.2. Architecture Layers

**Core Layer** (최하위): 외부 의존성과 인프라 관련 코드
- 네트워크 클라이언트, 저장소, 외부 서비스 연동

**Data Layer**: 데이터 접근과 변환 담당
- API 서비스, 모델, Repository 구현체

**Domain Layer**: 비즈니스 로직 추상화
- Repository 인터페이스, 비즈니스 엔티티

**Presentation Layer**: UI와 상태 관리
- 화면, 위젯, 상태 관리 Provider

---

## 2. 기술 스택 및 의존성

### 2.1. 핵심 의존성 ✅
```yaml
dependencies:
  # HTTP 통신
  dio: ^5.3.2
  
  # 상태 관리 & 의존성 주입
  provider: ^6.0.5              # 상태 관리 (Riverpod 대신)
  get_it: ^7.6.4               # 의존성 주입
  
  # 인증 & 저장
  google_sign_in: ^6.2.1       # Google OAuth
  shared_preferences: ^2.2.2    # 일반 저장소
  flutter_secure_storage: ^9.0.0 # 보안 저장소
  
  # 유틸리티
  json_annotation: ^4.8.1      # JSON 직렬화
  equatable: ^2.0.5            # 객체 비교
  webview_flutter: ^4.7.0      # 웹뷰
```

### 2.2. 개발 의존성
```yaml
dev_dependencies:
  # 코드 생성
  json_serializable: ^6.7.1    # JSON 모델 자동 생성
  build_runner: ^2.4.7         # 빌드 도구
  
  # 테스트 & 품질
  flutter_lints: ^3.0.0        # 린팅
  mockito: ^5.4.2              # 목킹
```

---

## 3. 인증 시스템 (완전 구현됨) ✅

### 3.1. Google OAuth 인증 흐름

```dart
// 1. Google Sign-In 서비스
class GoogleSignInService {
  Future<GoogleTokens?> signInAndGetTokens() async {
    final account = await _googleSignIn.signIn();
    if (account == null) return null;
    
    final auth = await account.authentication;
    return GoogleTokens(
      idToken: auth.idToken,
      accessToken: auth.accessToken
    );
  }
}

// 2. 백엔드 API 호출
class AuthService {
  Future<ApiResponse<Map<String, dynamic>>> loginWithGoogle(String idToken) async {
    return await _dioClient.dio.post(ApiEndpoints.googleLogin, data: {
      'googleAuthToken': idToken,
    });
  }

  Future<ApiResponse<UserModel>> completeProfile(ProfileUpdateRequest request) async {
    // 표준 엔드포인트 상수 사용: PUT /users/profile
    return await _dioClient.dio.put(ApiEndpoints.updateProfile, data: request.toJson());
  }
}

// 3. 상태 관리
class AuthProvider extends ChangeNotifier {
  Future<bool> loginWithGoogleTokens({String? idToken, String? accessToken}) async {
    // 토큰 검증 및 JWT 저장
    // 인증 상태 업데이트
    // UI 리스너 알림
  }
  
  // 4. 프로필 완성 (새로 추가됨)
  Future<bool> completeProfile({
    required String nickname,
    required String globalRole,
    String? profileImageUrl,
    String? bio,
  }) async {
    // 프로필 완성 API 호출 → 사용자 정보 업데이트 → profileCompleted 상태 업데이트
  }
}
```

### 3.2. 토큰 관리 시스템

**JWT 토큰 저장**:
```dart
abstract class TokenStorage {
  Future<void> saveAccessToken(String token);
  Future<String?> getAccessToken();
  Future<void> clearTokens();
}

class SecureTokenStorage implements TokenStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  // 암호화된 저장소 사용
}
```

**자동 토큰 주입**:
```dart
class DioClient {
  void _setupInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _tokenStorage.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }
}
```

### 3.3. 인증 상태 관리 (개선됨)

```dart
enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  AuthState _state = AuthState.initial;
  UserModel? _currentUser;
  String? _errorMessage;

  // Splash에서 인증 상태 관찰 후 안전한 네비게이션: 리스너 제거 + next frame에서 Navigator 호출
  // 로그인/회원가입 화면에서도 isAuthenticated 시 profileCompleted 여부에 따라
  // '/role-selection' 또는 '/home'으로 pushNamedAndRemoveUntil로 스택 정리하여 레이스 컨디션 방지.
  
  // 자동 인증 상태 확인 (개선된 에러 처리)
  Future<void> checkAuthStatus() async {
    try {
      _setState(AuthState.loading);
      final isLoggedIn = await _authRepository.isLoggedIn();
      
      if (isLoggedIn) {
        final user = await _authRepository.getCurrentUser();
        _currentUser = user;
        _setState(AuthState.authenticated);
      } else {
        _setState(AuthState.unauthenticated);
      }
    } catch (e) {
      _setError('인증 상태 확인 실패: ${e.toString()}');
    }
  }
  
  // 상태 관리 개선 사항
  void _setState(AuthState newState) {
    _state = newState;
    _errorMessage = null; // 새 상태로 변경 시 에러 초기화
    notifyListeners();
  }
  
  void _setError(String error) {
    _state = AuthState.error;
    _errorMessage = error;
    notifyListeners();
  }
  
  // 로그아웃 개선 (완전한 상태 초기화)
  Future<void> logout() async {
    try {
      _setState(AuthState.loading);
      await _authRepository.logout();
      await _tokenStorage.clearTokens();
      _currentUser = null;
      _setState(AuthState.unauthenticated);
    } catch (e) {
      _setError('로그아웃 실패: ${e.toString()}');
    }
  }
}
```

#### 3.3.1. 인증 상태 관리 개선 사항

**개선된 에러 처리**:
- 모든 인증 관련 작업에 try-catch 블록 적용
- 사용자 친화적 에러 메시지 제공
- 에러 상태와 메시지를 분리하여 UI에서 선택적 표시 가능

**상태 전환 일관성**:
- `_setState()` 메서드를 통한 일관된 상태 변경
- 상태 변경 시 이전 에러 메시지 자동 초기화
- 로딩 상태의 적절한 표시

**완전한 로그아웃 처리**:
- 토큰 삭제와 상태 초기화를 원자적으로 처리
- 사용자 정보 완전 삭제
- 에러 발생 시에도 안전한 상태 유지

**자동 토큰 갱신 준비**:
- 향후 refresh token 구현을 위한 구조적 기반 마련
- 토큰 만료 감지 및 처리 로직 개선

### 3.4. 향상된 회원가입 플로우 (2025-09-11 추가) ✅

**신규 사용자 회원가입 단계**:
```dart
// 1. Google OAuth 인증 완료 후
// 2. profileCompleted가 false인 경우 단계별 진행

class SignupFlowManager {
  // Step 1: 역할 선택
  static void navigateToRoleSelection(BuildContext context) {
    Navigator.pushNamed(context, '/role-selection');
  }
  
  // Step 2: 프로필 설정
  static void navigateToProfileSetup(BuildContext context, String role) {
    Navigator.pushNamed(context, '/profile-setup', arguments: {'role': role});
  }
  
  // Step 3: 프로필 완성 및 홈으로 이동
  static Future<void> completeSignupAndNavigateHome(
    BuildContext context, 
    AuthProvider authProvider, 
    ProfileData profileData
  ) async {
    final success = await authProvider.completeProfile(
      nickname: profileData.nickname,
      globalRole: profileData.role,
      profileImageUrl: profileData.profileImageUrl,
      bio: profileData.bio,
    );
    
    if (success) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
  }
}
```

**새로운 화면 컴포넌트**:
- **RoleSelectionScreen**: 학생/교수 역할 선택 UI
- **ProfileSetupScreen**: 닉네임, 프로필사진, 자기소개 입력 UI
- **교수 선택 시 안내**: 승인 필요 메시지 표시

**상태 관리 개선**:
```dart
class AuthProvider extends ChangeNotifier {
  bool get isProfileCompleted => _currentUser?.profileCompleted ?? false;
  
  Future<bool> completeProfile({
    required String nickname,
    required String globalRole,
    String? profileImageUrl,
    String? bio,
  }) async {
    try {
      final success = await _authRepository.completeProfile(
        nickname: nickname,
        globalRole: globalRole,
        profileImageUrl: profileImageUrl,
        bio: bio,
      );
      
      if (success) {
        // 사용자 정보 갱신
        await _loadUserProfile();
        notifyListeners();
      }
      
      return success;
    } catch (e) {
      _setError('프로필 완성 실패: ${e.toString()}');
      return false;
    }
  }
}

---

## 4. 네트워크 레이어

### 4.1. HTTP 클라이언트 구성 ✅

```dart
class DioClient {
  late final Dio _dio;
  
  DioClient(TokenStorage tokenStorage) {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,           // "http://localhost:8080"
      connectTimeout: Duration(milliseconds: 5000),
      receiveTimeout: Duration(milliseconds: 10000),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    _setupInterceptors();  // 자동 토큰 주입 & 로깅
  }
}
```

### 4.2. API 응답 모델 ✅

```dart
@JsonSerializable(genericArgumentFactories: true)
class ApiResponse<T> {
  final bool success;
  final T? data;
  final ApiError? error;
  
  // 자동 JSON 직렬화/역직렬화
}
```

**✅ 백엔드 API 응답 형태 일치 완료**: AuthService가 백엔드의 표준 ApiResponse 래퍼 형태 `{ "success": true, "data": {...} }`를 정확히 파싱하도록 수정됨. Google 로그인 API의 응답을 LoginResponse 객체로 직접 변환하여 처리하며, AuthRepository, AuthProvider 전체 레이어에서 타입 일치성이 확보됨. 향후 다른 API 엔드포인트들도 동일한 표준 형태로 수정할 때 이 구조를 참고할 수 있음.

### 4.3. 에러 처리

- **401 Unauthorized**: 토큰 만료 처리 (향후 리프레시 토큰 구현 예정)
- **Network Errors**: 연결 실패, 타임아웃 처리
- **Server Errors**: 5xx 에러 처리
- **Business Logic Errors**: 백엔드 비즈니스 예외 처리

---

## 5. 상태 관리 패턴

### 5.1. Provider + GetIt 조합 ✅

**Provider**: UI 상태 관리 및 리스너 패턴
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider<AuthProvider>(
      create: (_) => getIt<AuthProvider>()..checkAuthStatus(),
    ),
  ],
  child: MaterialApp(...),
)
```

**GetIt**: 의존성 주입 컨테이너
```dart
Future<void> setupDependencyInjection() async {
  // Singleton 등록
  getIt.registerLazySingleton<TokenStorage>(() => SecureTokenStorage());
  getIt.registerLazySingleton<DioClient>(() => DioClient(getIt<TokenStorage>()));
  
  // Factory 등록
  getIt.registerFactory<AuthProvider>(() => AuthProvider(getIt<AuthRepository>()));
}
```

### 5.2. 상태 흐름

```
User Action (로그인 버튼 클릭)
    ↓
AuthProvider.loginWithGoogleTokens()
    ↓
AuthRepository.loginWithGoogle()
    ↓
AuthService.loginWithGoogle()
    ↓
DioClient (자동 토큰 주입)
    ↓
Backend API Call
    ↓
TokenStorage.saveAccessToken()
    ↓
AuthProvider.notifyListeners()
    ↓
UI Update (Navigator.pushNamed('/home'))
```

---

## 6. UI 및 화면 구조

### 6.1. 구현된 화면들 ✅

**SplashScreen**: 초기 로딩 및 인증 상태 확인 (개선됨) ✅
- AuthProvider 초기화 및 상태 변화 감지
- 자동 로그인 여부 확인
- profileCompleted 기반 스마트 라우팅:
  - 비인증 사용자: /login으로 이동
  - 신규 사용자 (profileCompleted: false): /role-selection으로 이동
  - 기존 사용자 (profileCompleted: true): /home으로 이동
- **Flutter Widget 라이프사이클 문제 해결 (2025-09-11)**:
  - SchedulerBinding.addPostFrameCallback으로 안전한 네비게이션 구현
  - AuthProvider 리스너 중복 실행 방지 (네비게이션 후 리스너 자동 제거)
  - "Looking up a deactivated widget's ancestor is unsafe" 에러 해결

**LoginScreen**: Google OAuth 로그인
- Google Sign-In 버튼
- 에러 메시지 표시
- 로딩 상태 관리
- 프로필 완성 여부에 따른 라우팅 분기

**RegisterScreen**: 회원가입 (기본 구조만)
- 추가 정보 입력 예정
- 현재는 스켈레톤 구조만

**RoleSelectionScreen**: 역할 선택 화면 ✅
- 학생/교수 역할 선택 UI
- 교수 선택 시 승인 필요 안내 메시지
- 선택 완료 후 프로필 설정으로 자동 이동

**ProfileSetupScreen**: 프로필 설정 화면 ✅
- 닉네임 입력 (필수)
- 프로필 이미지 URL 입력 (선택)
- 자기소개 입력 (선택)
- 프로필 완성 API 연동 및 상태 관리

**HomeScreen**: 인증 후 메인 화면
- 로그아웃 기능
- 사용자 정보 표시
- 그룹 관리 기능 연결점 (향후 구현)

**WebViewScreen**: 외부 링크 표시용

### 6.2. 테마 시스템 ✅

```dart
class AppTheme {
  static const Color primaryColor = Color(0xFF1976D2);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color textPrimaryColor = Color(0xFF212121);
  static const Color textSecondaryColor = Color(0xFF757575);
  
  static ThemeData get lightTheme => ThemeData(
    primarySwatch: Colors.blue,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    // 통일된 색상과 폰트 적용
  );
}
```

### 6.3. 라우팅 시스템 (업데이트됨) ✅

**Named Routes 사용**:
```dart
MaterialApp(
  initialRoute: '/',  // SplashScreen부터 시작
  routes: {
    '/': (context) => const SplashScreen(),
    '/login': (context) => const LoginScreen(),
    '/register': (context) => const RegisterScreen(),
    '/role-selection': (context) => const RoleSelectionScreen(),
    '/profile-setup': (context) => const ProfileSetupScreen(),
    '/home': (context) => const HomeScreen(),
    '/webview': (context) => const WebViewScreen(),
  },
)
```

**SplashScreen 라우팅 로직 (2025-09-11 업데이트)**:
```dart
class _SplashScreenState extends State<SplashScreen> {
  VoidCallback? _authListener;
  
  void _checkAuthStatus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      
      // AuthProvider 상태 변화 감지 - 한 번만 실행
      _authListener = () {
        if (authProvider.state != AuthState.loading) {
          if (mounted) {
            // 리스너 제거 - 중복 네비게이션 방지
            authProvider.removeListener(_authListener!);
            
            // 안전한 네비게이션 (Widget dispose 문제 방지)
            SchedulerBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                if (authProvider.isAuthenticated) {
                  final user = authProvider.currentUser;
                  if (user != null && !user.profileCompleted) {
                    // 신규 사용자: 역할 선택부터 시작
                    Navigator.pushReplacementNamed(context, '/role-selection');
                  } else {
                    // 기존 사용자: 홈 화면으로 이동
                    Navigator.pushReplacementNamed(context, '/home');
                  }
                } else {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              }
            });
          }
        }
      };
      authProvider.addListener(_authListener!);
    });
  }
  
  @override
  void dispose() {
    if (_authListener != null) {
      final authProvider = context.read<AuthProvider>();
      authProvider.removeListener(_authListener!);
    }
    super.dispose();
  }
}
```

**주요 해결사항**:
- `SchedulerBinding.addPostFrameCallback`으로 Widget 라이프사이클 안전성 확보
- AuthProvider 리스너 중복 실행 방지 (네비게이션 후 즉시 제거)
- `mounted` 체크로 dispose된 Widget에서 Navigator 호출 방지

---

## 7. 보안 고려사항

### 7.1. 토큰 저장 ✅
- **Flutter Secure Storage** 사용하여 암호화된 저장소에 JWT 저장
- 앱 제거 시 자동 삭제
- 루팅/탈옥 디바이스에서도 상대적으로 안전

### 7.2. 네트워크 보안
- HTTPS 통신 (프로덕션)
- Certificate Pinning (향후 추가 예정)
- API 요청 로깅 (개발 환경에서만)

### 7.3. 인증 보안
- Google OAuth 표준 준수
- JWT 토큰 만료 처리
- 자동 로그아웃 (토큰 무효시)

---

## 8. 현재 한계점 및 향후 개선사항

### 8.1. 미구현 기능 ❌
- **Refresh Token**: 자동 토큰 갱신
- **Offline Support**: 오프라인 모드
- **Push Notifications**: 실시간 알림
- **Deep Linking**: URL 기반 화면 이동
- **Internationalization**: 다국어 지원

### 8.2. 성능 최적화 필요
- **이미지 캐싱**: 프로필 이미지 등
- **무한 스크롤**: 리스트 성능
- **상태 지속성**: 앱 재시작 시 상태 복원

### 8.3. 테스트 부재 ❌
- Unit Tests
- Widget Tests
- Integration Tests
- 모든 테스트가 미구현 상태

---

## 9. 빌드 및 배포

### 9.1. 웹 빌드 ✅
```bash
flutter build web
# build/web/ 폴더에 정적 파일 생성
# Spring Boot static 폴더로 복사하여 통합 배포
```

### 9.2. 환경별 설정
- **Development**: localhost:8080
- **Production**: AWS EC2 서버 주소
- AppConstants.dart에서 환경별 분리 관리

---

## 10. 결론

Flutter 프론트엔드는 **Google OAuth 인증 시스템을 중심으로 완전히 구현**되었습니다. Clean Architecture를 기반으로 한 확장 가능한 구조를 가지고 있으며, 백엔드 API와의 완전한 연동이 완료된 상태입니다.

다음 단계에서는 그룹 관리, 멤버십, 게시글 등의 핵심 비즈니스 기능들을 이 견고한 아키텍처 기반 위에 구현할 수 있습니다.
