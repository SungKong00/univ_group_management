# 대학 그룹 관리 Flutter 앱

백엔드 Spring Boot API와 연동하는 대학 그룹 관리 모바일 애플리케이션입니다.

## 프로젝트 개요

### 주요 기능
- 🔐 JWT 기반 사용자 인증 (로그인/회원가입)
- 👥 그룹 생성 및 관리 (향후 구현 예정)
- 📱 미니멀하고 모던한 UI/UX 디자인
- 🔄 백엔드 API와 실시간 연동

### 기술 스택
- **Framework**: Flutter 3.x
- **Language**: Dart
- **State Management**: Provider
- **HTTP Client**: Dio
- **Local Storage**: SharedPreferences, Flutter Secure Storage
- **Dependency Injection**: GetIt
- **UI/UX**: Material Design 3, 커스텀 테마

## 프로젝트 구조

```
lib/
├── main.dart                   # 앱 진입점
├── core/                      # 핵심 설정 및 유틸리티
│   ├── constants/            # 상수 정의
│   ├── network/              # HTTP 클라이언트 설정
│   ├── storage/              # 로컬 저장소 관리
│   └── utils/                # 유틸리티 함수
├── data/                     # 데이터 계층
│   ├── models/               # 데이터 모델
│   ├── repositories/         # Repository 구현체
│   └── services/             # API 서비스
├── domain/                   # 도메인 계층
│   ├── entities/             # 도메인 엔티티
│   └── repositories/         # Repository 인터페이스
├── presentation/             # UI 계층
│   ├── providers/            # 상태 관리 Provider
│   ├── screens/              # 화면 위젯
│   ├── widgets/              # 재사용 위젯
│   └── theme/                # 앱 테마 설정
└── injection/                # 의존성 주입 설정
```

## 시작하기

### 사전 요구사항
- Flutter SDK 3.0 이상
- Dart SDK 3.0 이상
- Android Studio / VS Code
- iOS 개발을 위한 Xcode (macOS에서만)

### 설치 및 실행

1. **의존성 설치**
   ```bash
   flutter pub get
   ```

2. **코드 생성 (JSON 직렬화)**
   ```bash
   flutter packages pub run build_runner build
   ```

3. **앱 실행**
   ```bash
   # 개발 모드로 실행
   flutter run
   
   # 특정 디바이스에서 실행
   flutter run -d <device_id>
   ```

### 백엔드 연동 설정

1. **백엔드 서버 실행**
   - Spring Boot 백엔드 서버가 `http://localhost:8080`에서 실행되어야 합니다.
   - 백엔드 프로젝트의 README를 참조하여 서버를 먼저 실행해주세요.

2. **API 엔드포인트 확인**
   - `lib/core/constants/app_constants.dart`에서 `baseUrl` 확인
   - 필요시 백엔드 서버 주소에 맞게 수정

## 주요 화면

### 1. 인증 화면
- **스플래시 화면**: 앱 로딩 및 인증 상태 확인
- **로그인 화면**: 이메일/비밀번호 로그인
- **회원가입 화면**: 이름, 이메일, 비밀번호 입력

### 2. 메인 화면
- **홈 화면**: 사용자 환영 메시지 및 주요 기능 접근
- **그룹 관리**: 그룹 생성, 검색, 관리 (향후 구현)

## 디자인 시스템

### 디자인 철학
- **미니멀리즘**: 여백 많고 요소 적게, 깔끔하고 직관적인 인터페이스
- **모던/플랫**: 그림자·그라데이션 최소화, 선명한 색상과 단순한 형태
- **토스식**: 흰 배경 + 심플한 폰트 + 데이터 중심의 레이아웃
- **머티리얼 디자인**: 구글 가이드라인 기반, 버튼·카드·모션 일관성
- **애플 스타일**: 부드러운 곡선, 정제된 폰트, 여백 강조

### 색상 팔레트
- **Primary**: #2563EB (블루)
- **Secondary**: #10B981 (그린)
- **Background**: #FFFFFF (화이트)
- **Surface**: #F8FAFC (라이트 그레이)
- **Error**: #EF4444 (레드)

## API 연동

### 인증 API
```dart
// 로그인
POST /api/v1/auth/login
{
  "email": "user@example.com",
  "password": "password123"
}

// 회원가입
POST /api/v1/auth/register
{
  "name": "사용자 이름",
  "email": "user@example.com", 
  "password": "Password123!@#"
}
```

### 에러 처리
- 네트워크 오류 자동 처리
- 사용자 친화적 에러 메시지 표시
- 토큰 만료 시 자동 갱신 (향후 구현)

## 상태 관리

### AuthProvider
```dart
// 로그인 상태 확인
authProvider.isAuthenticated

// 현재 사용자 정보
authProvider.currentUser

// 로그인 실행
await authProvider.login(email, password)

// 로그아웃 실행
await authProvider.logout()
```

## 테스트

### 단위 테스트 실행
```bash
flutter test
```

### 테스트 커버리지 확인
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## 빌드

### Android APK 빌드
```bash
flutter build apk --release
```

### iOS IPA 빌드 (macOS만 가능)
```bash
flutter build ios --release
```

## 향후 개발 계획

### Phase 1 (완료)
- ✅ Flutter 프로젝트 초기 설정
- ✅ 인증 시스템 구현
- ✅ 기본 UI/UX 구현

### Phase 2 (예정)
- 🔄 그룹 생성 및 관리 기능
- 🔄 그룹 멤버 관리
- 🔄 알림 시스템

### Phase 3 (예정)
- 🔄 실시간 채팅
- 🔄 파일 공유
- 🔄 일정 관리

## 문제 해결

### 일반적인 문제들

1. **의존성 오류**
   ```bash
   flutter clean
   flutter pub get
   ```

2. **코드 생성 오류**
   ```bash
   flutter packages pub run build_runner clean
   flutter packages pub run build_runner build --delete-conflicting-outputs
   ```

3. **네트워크 연결 오류**
   - 백엔드 서버가 실행 중인지 확인
   - `app_constants.dart`의 `baseUrl` 확인
   - 네트워크 권한 확인 (AndroidManifest.xml)

## 기여하기

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 라이센스

이 프로젝트는 MIT 라이센스 하에 있습니다.

## 연락처

프로젝트 관련 문의사항이 있으시면 이슈를 생성해주세요.