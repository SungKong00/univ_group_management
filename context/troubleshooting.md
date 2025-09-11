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

#### 3.1.1. Gradle 버전 호환성 문제

**증상**: `Could not determine the dependencies of task ':app:compileFlutterBuildDebug'`

**해결방법**:
```gradle
// android/gradle/wrapper/gradle-wrapper.properties
distributionUrl=https\://services.gradle.org/distributions/gradle-8.0.2-all.zip

// android/build.gradle
dependencies {
    classpath 'com.android.tools.build:gradle:8.1.0'
    classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
}
```

#### 3.1.2. 안드로이드 SDK 경로 문제

**증상**: `Android SDK not found`

**해결방법**:
```bash
# Android SDK 경로 설정 확인
echo $ANDROID_HOME
echo $ANDROID_SDK_ROOT

# 경로가 설정되지 않았다면
export ANDROID_HOME=$HOME/Library/Android/sdk  # macOS
export ANDROID_HOME=$HOME/Android/Sdk          # Linux
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools
```

#### 3.1.3. MultiDex 설정 문제 (APK 크기 초과)

**증상**: `The number of method references in a .dex file cannot exceed 64K`

**해결방법**:
```gradle
// android/app/build.gradle
android {
    defaultConfig {
        multiDexEnabled true
    }
}

dependencies {
    implementation 'androidx.multidex:multidex:2.0.1'
}
```

```java
// android/app/src/main/java/.../MainApplication.java
import androidx.multidex.MultiDexApplication;

public class MainApplication extends MultiDexApplication {
    // existing code
}
```

### 3.2. 웹 빌드 최적화

**빌드 명령어**:
```bash
# 개발 빌드
flutter build web

# 프로덕션 빌드 (최적화된)
flutter build web --release --web-renderer canvaskit
```

#### 3.2.1. 웹 빌드 시 메모리 부족 에러

**증상**: `JavaScript heap out of memory`

**해결방법**:
```bash
# Node.js 힙 메모리 크기 증가
export NODE_OPTIONS="--max-old-space-size=8192"
flutter build web --release

# 또는 빌드 옵션으로 최적화
flutter build web --release --tree-shake-icons --split-debug-info=build/debug-info
```

#### 3.2.2. 웹 빌드 시 CORS 에러

**증상**: 빌드는 성공하지만 실행 시 API 호출에서 CORS 에러

**해결방법**:
```bash
# 개발 서버에서 CORS 허용으로 실행
flutter run -d chrome --web-port 3000 --web-browser-flag="--disable-web-security"

# 또는 로컬 웹 서버로 테스트
cd build/web
python -m http.server 8080
```

### 3.3. iOS 빌드 문제

#### 3.3.1. CocoaPods 의존성 충돌

**증상**: `CocoaPods could not find compatible versions for pod`

**해결방법**:
```bash
# 1. Podfile.lock 삭제 및 재설치
cd ios
rm Podfile.lock
rm -rf Pods/
pod deintegrate
pod install

# 2. Flutter 의존성 재설치
cd ..
flutter clean
flutter pub get
cd ios
pod install
```

#### 3.3.2. Xcode 서명 문제

**증상**: `Failed to create provisioning profile`

**해결방법**:
```bash
# 1. 개발용 서명으로 임시 해결
open ios/Runner.xcworkspace

# Xcode에서:
# 1. Runner 타겟 선택
# 2. Signing & Capabilities 탭
# 3. Team을 개발자 계정으로 선택
# 4. Bundle Identifier 변경 (고유한 값)
```

### 3.4. 종속성 충돌 문제

#### 3.4.1. 패키지 버전 충돌

**증상**: `Because project depends on both X and Y, version solving failed`

**진단 방법**:
```bash
# 의존성 트리 확인
flutter pub deps

# 특정 패키지의 의존성 확인
flutter pub deps --style=tree | grep package_name
```

**해결방법**:
```yaml
# pubspec.yaml에서 버전 명시적 지정
dependency_overrides:
  http: ^0.13.5
  meta: ^1.8.0
```

#### 3.4.2. Native 플러그인 충돌

**증상**: Android/iOS에서 중복된 심볼 에러

**해결방법**:
```bash
# 1. 캐시 완전 삭제
flutter clean
flutter pub cache repair
rm -rf ~/.pub-cache

# 2. 의존성 재설치
flutter pub get

# 3. 네이티브 빌드 캐시 삭제 (Android)
cd android
./gradlew clean
cd ..

# 4. iOS 캐시 삭제
cd ios
pod deintegrate
pod install
cd ..
```

### 3.5. 빌드 성능 최적화

#### 3.5.1. 빌드 속도 개선

```bash
# 병렬 빌드 활성화
export FLUTTER_BUILD_PARALLEL=true

# 증분 빌드 활성화 (개발 시)
flutter run --hot

# 릴리즈 빌드 최적화
flutter build apk --release --split-per-abi
```

#### 3.5.2. 빌드 크기 최적화

```bash
# APK 크기 분석
flutter build apk --analyze-size

# 웹 빌드 크기 최적화
flutter build web --release --tree-shake-icons --split-debug-info=build/debug-info --source-maps

# 사용하지 않는 리소스 제거
flutter build apk --release --shrink
```

### 3.6. 빌드 환경별 설정

#### 3.6.1. 개발/스테이징/프로덕션 환경 분리

```dart
// lib/config/environment.dart
enum Environment { development, staging, production }

class Config {
  static Environment _environment = Environment.development;
  
  static String get apiBaseUrl {
    switch (_environment) {
      case Environment.development:
        return 'http://localhost:8080';
      case Environment.staging:
        return 'https://staging-api.example.com';
      case Environment.production:
        return 'https://api.example.com';
    }
  }
}
```

```bash
# 환경별 빌드
flutter build apk --release --dart-define=ENV=production
flutter build web --release --dart-define=ENV=staging
```

### 3.7. CI/CD 빌드 문제

#### 3.7.1. GitHub Actions 빌드 실패

**일반적인 해결 체크리스트**:
```yaml
# .github/workflows/build.yml
- name: Setup Flutter
  uses: subosito/flutter-action@v2
  with:
    flutter-version: '3.10.0'  # 버전 고정
    channel: 'stable'

- name: Get dependencies
  run: flutter pub get

- name: Run tests
  run: flutter test

- name: Build APK
  run: flutter build apk --release
```

#### 3.7.2. 빌드 캐시 문제

```yaml
# 빌드 캐시 설정
- name: Cache Flutter dependencies
  uses: actions/cache@v3
  with:
    path: |
      ~/.pub-cache
      ~/.gradle/caches
      ~/.gradle/wrapper
    key: ${{ runner.os }}-flutter-${{ hashFiles('**/pubspec.lock') }}
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

## 5. OAuth2 회원가입 플로우 문제 (2025-09-11 추가)

### 5.1. OAuth2 로그인 후 바로 홈 화면으로 이동하는 문제

**증상**: Google OAuth2 로그인 후 역할 선택 화면 없이 바로 홈 화면으로 이동합니다.

**진단 과정**:

#### 5.1.1. 백엔드 데이터 확인
```kotlin
// UserService.kt - 신규 사용자 생성 시 profileCompleted 확실히 false로 설정
fun findOrCreateUser(googleUserInfo: GoogleUserInfo): User {
    val existingUser = findByEmail(googleUserInfo.email)
    return if (existingUser != null) {
        println("DEBUG: Found existing user - email: ${existingUser.email}, profileCompleted: ${existingUser.profileCompleted}")
        existingUser
    } else {
        val user = User(
            name = googleUserInfo.name,
            email = googleUserInfo.email,
            password = "",
            globalRole = GlobalRole.STUDENT,
            profileCompleted = false, // 명시적으로 false 설정
        )
        val savedUser = userRepository.save(user)
        println("DEBUG: Created new user - email: ${savedUser.email}, profileCompleted: ${savedUser.profileCompleted}")
        savedUser
    }
}
```

#### 5.1.2. 프론트엔드 디버깅 로그 추가
```dart
// AuthProvider.dart - 로그인 후 사용자 정보 확인
Future<bool> loginWithGoogleTokens({String? idToken, String? accessToken}) async {
  // ... 로그인 로직
  if (result.isSuccess && result.data != null) {
    _currentUser = result.data!.user;
    // 디버그: 사용자 정보 출력
    print('DEBUG: User logged in - profileCompleted: ${_currentUser!.profileCompleted}');
    print('DEBUG: User info - name: ${_currentUser!.name}, email: ${_currentUser!.email}');
    _setState(AuthState.authenticated);
    return true;
  }
}
```

### 5.2. Flutter Widget Dispose 문제

**증상**: `Looking up a deactivated widget's ancestor is unsafe` 에러와 함께 앱이 크래시합니다.

**원인**: SplashScreen에서 AuthProvider 상태 변화를 감지하여 네비게이션을 실행할 때, Widget이 이미 dispose된 상태에서 Navigator를 호출하려고 해서 발생.

**해결방법**:
```dart
// main.dart - SplashScreen 안전한 네비게이션 구현
class _SplashScreenState extends State<SplashScreen> {
  VoidCallback? _authListener;
  
  void _checkAuthStatus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      
      _authListener = () {
        if (authProvider.state != AuthState.loading) {
          if (mounted) {
            // 리스너 제거 - 중복 네비게이션 방지
            authProvider.removeListener(_authListener!);
            
            // 안전한 네비게이션 (Widget dispose 문제 방지)
            SchedulerBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                // 네비게이션 로직
                if (authProvider.isAuthenticated) {
                  final user = authProvider.currentUser;
                  if (user != null && !user.profileCompleted) {
                    Navigator.pushReplacementNamed(context, '/role-selection');
                  } else {
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

**핵심 해결 포인트**:
1. `SchedulerBinding.instance.addPostFrameCallback`으로 다음 프레임에서 네비게이션 실행
2. 네비게이션 실행 전후로 `mounted` 체크
3. AuthProvider 리스너 중복 실행 방지 (네비게이션 후 즉시 제거)
4. `dispose()`에서 리스너 정리

### 5.3. 역할 선택 화면이 빠르게 사라지는 문제 (해결)

**증상**: 역할 선택 화면이 매우 빠르게 나타났다가 홈 화면으로 이동합니다.

**원인**:
- 로그인 화면의 인증 가드가 무조건 `'/home'`으로 리다이렉트하여 Splash/역할 선택 흐름과 충돌(레이스 컨디션)했습니다.

**해결방법**:
1. 로그인 화면의 가드를 `currentUser.profileCompleted` 기준으로 분기하도록 수정
2. 네비게이션 시 `pushNamedAndRemoveUntil` 사용으로 백스택 정리 및 중복 콜백 제거
3. Splash에서는 리스너 제거 후 다음 프레임에서 네비게이션 실행(`SchedulerBinding.instance.addPostFrameCallback`)으로 안전성 확보

**변경 파일**:
- `frontend/lib/presentation/screens/auth/login_screen.dart`
- `frontend/lib/main.dart`

**검증 체크리스트**:
1. 신규 사용자 로그인 → 역할 선택 화면 유지
2. 역할 선택 → 프로필 설정 → 홈 이동
3. 기존 사용자 로그인 → 바로 홈 이동

### 5.4. 프로필 완성 API 호출 시 401/403 (PUT /users/profile)

**증상**: 프로필 설정 화면에서 "프로필 완성" 버튼 클릭 시 권한 없음 메시지가 표시됩니다.

**원인**: 프로필 업데이트 경로를 하드코딩된 `'/api/users/profile'`로 호출하여 `baseUrl`과 중복 결합 또는 규칙 충돌이 발생했습니다.

**해결방법**:
- `AuthService.completeProfile`을 `ApiEndpoints.updateProfile`로 수정하여 상대 경로(`/users/profile`) 사용.
- 인터셉터에서 Authorization 헤더가 정상 주입되는지 로그로 확인.

**변경 파일**: `frontend/lib/data/services/auth_service.dart`

---

## 6. 문제 해결이 안 될 때

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
