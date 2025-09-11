# Troubleshooting Guide

이 문서는 프로젝트에서 발생할 수 있는 일반적인 문제들과 해결 방법을 안내합니다.

---

## 1. 인증 관련 문제 해결

### 1.1. Google OAuth 로그인 실패

**증상**: Google 로그인 버튼을 눌러도 로그인이 진행되지 않거나 실패합니다.

**원인 및 해결방법**:

#### 1.1.1. Google Services 설정 문제
```bash
# Android의 경우
android/app/google-services.json 파일 확인
- Firebase 프로젝트에서 올바른 파일을 다운로드했는지 확인
- package name이 일치하는지 확인

# iOS의 경우  
ios/Runner/GoogleService-Info.plist 파일 확인
- Bundle ID가 일치하는지 확인
```

#### 1.1.2. 개발 환경에서의 SHA-1 지문 미등록
```bash
# Android 개발용 SHA-1 지문 생성
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Firebase Console에서 해당 SHA-1 지문 등록 필요
```

#### 1.1.3. 권한 설정 문제
```yaml
# android/app/src/main/AndroidManifest.xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

### 1.2. 토큰 저장/로드 실패

**증상**: 로그인은 성공하지만 앱을 재시작하면 로그아웃 상태가 됩니다.

**디버깅 방법**:
```dart
// TokenStorage 디버깅
Future<void> debugTokenStorage() async {
  final storage = getIt<TokenStorage>();
  
  // 토큰 저장 테스트
  await storage.saveAccessToken('test_token');
  final savedToken = await storage.getAccessToken();
  
  print('Token saved successfully: ${savedToken == 'test_token'}');
  
  // 토큰 삭제 테스트
  await storage.clearTokens();
  final clearedToken = await storage.getAccessToken();
  
  print('Token cleared successfully: ${clearedToken == null}');
}
```

**해결방법**:
1. **Android 키 관리 문제**: 앱 재설치 시 SecureStorage 키가 변경될 수 있음
2. **iOS Keychain 권한**: Info.plist에 Keychain 접근 권한 확인
3. **에뮬레이터 제한**: 실제 디바이스에서 테스트 필요할 수 있음

### 1.3. 인증 상태가 올바르게 업데이트되지 않음

**증상**: 로그인 후에도 UI가 인증되지 않은 상태로 표시됩니다.

**원인 및 해결방법**:

#### 1.3.1. Provider 리스너 누락
```dart
// 올바른 사용 예시
Consumer<AuthProvider>(
  builder: (context, authProvider, child) {
    switch (authProvider.state) {
      case AuthState.loading:
        return CircularProgressIndicator();
      case AuthState.authenticated:
        return HomeScreen();
      case AuthState.unauthenticated:
        return LoginScreen();
      case AuthState.error:
        return ErrorScreen(message: authProvider.errorMessage);
      default:
        return SplashScreen();
    }
  },
)
```

#### 1.3.2. notifyListeners() 호출 누락
```dart
// AuthProvider에서 상태 변경 시 반드시 호출
void _setState(AuthState newState) {
  _state = newState;
  notifyListeners(); // 이 부분이 누락되면 UI가 업데이트되지 않음
}
```

### 1.4. API 호출 시 401 Unauthorized 에러

**증상**: 로그인 후 API 호출 시 401 에러가 발생합니다.

**디버깅 단계**:
```dart
// 1. 토큰이 실제로 저장되어 있는지 확인
final token = await getIt<TokenStorage>().getAccessToken();
print('Current token: $token');

// 2. DioClient의 인터셉터가 토큰을 주입하는지 확인
_dio.interceptors.add(LogInterceptor(
  request: true,
  requestHeader: true,
  requestBody: true,
  responseHeader: false,
  responseBody: true,
  error: true,
));
```

**해결방법**:
1. **토큰 형식 확인**: `Bearer ` 접두사가 올바르게 추가되는지 확인
2. **토큰 만료**: 백엔드에서 토큰 만료 시간 확인
3. **백엔드 엔드포인트**: API 엔드포인트가 올바른지 확인

### 1.5. 앱 백그라운드 복귀 시 인증 상태 초기화

**증상**: 앱을 백그라운드로 보냈다가 다시 돌아오면 로그아웃 상태가 됩니다.

**해결방법**:
```dart
// main.dart에서 앱 라이프사이클 관리
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 앱이 포그라운드로 복귀했을 때 인증 상태 재확인
      context.read<AuthProvider>().checkAuthStatus();
    }
  }
}
```

---

## 2. 네트워크 관련 문제

### 2.1. 개발 서버 연결 실패

**증상**: Flutter 웹에서 백엔드 API 호출 시 CORS 에러나 연결 실패가 발생합니다.

**해결방법**:
1. **백엔드 CORS 설정 확인**:
   ```kotlin
   // Spring Boot WebConfig
   @CrossOrigin(origins = ["http://localhost:3000", "http://localhost:8080"])
   ```

2. **Flutter 웹 개발 서버 실행**:
   ```bash
   flutter run -d chrome --web-port 3000
   ```

### 2.2. 타임아웃 에러

**증상**: API 호출이 오래 걸리거나 타임아웃됩니다.

**설정 조정**:
```dart
Dio(BaseOptions(
  connectTimeout: Duration(milliseconds: 10000), // 연결 타임아웃 증가
  receiveTimeout: Duration(milliseconds: 15000), // 응답 타임아웃 증가
))
```

---

## 3. 빌드 관련 문제

### 3.1. Android 빌드 실패

**일반적인 해결방법**:
```bash
# 1. 클린 빌드
flutter clean
flutter pub get

# 2. Android 프로젝트 클린
cd android
./gradlew clean
cd ..

# 3. 빌드 재시도
flutter build apk
```

### 3.2. 웹 빌드 최적화

**빌드 명령어**:
```bash
# 개발 빌드
flutter build web

# 프로덕션 빌드 (최적화된)
flutter build web --release --web-renderer canvaskit
```

---

## 4. 개발 도구 및 디버깅

### 4.1. Flutter Inspector 활용

**유용한 디버깅 명령어**:
```bash
# 디바이스별 로그 확인
flutter logs

# 특정 디바이스 로그
flutter logs -d <device-id>

# 성능 프로파일링
flutter run --profile
```

### 4.2. 네트워크 요청 모니터링

**Dio 로깅 설정**:
```dart
if (kDebugMode) {
  _dio.interceptors.add(LogInterceptor(
    request: true,
    requestHeader: true,
    requestBody: true,
    responseBody: true,
    error: true,
  ));
}
```

---

## 5. 문제 해결이 안 될 때

### 5.1. 이슈 보고 전 체크리스트

1. **Flutter 버전 확인**: `flutter --version`
2. **의존성 업데이트**: `flutter pub upgrade`
3. **로그 수집**: 에러 발생 시점의 상세한 로그
4. **재현 단계**: 문제가 발생하는 정확한 단계들
5. **환경 정보**: 디바이스, OS 버전, 빌드 타겟 등

### 5.2. 추가 리소스

- **Flutter 공식 문서**: https://docs.flutter.dev
- **Stack Overflow**: flutter 태그로 검색
- **GitHub Issues**: 사용 중인 패키지들의 이슈 트래커 확인

---

이 가이드는 프로젝트 진행에 따라 지속적으로 업데이트될 예정입니다.