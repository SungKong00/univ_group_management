# 프론트엔드 구현 가이드 (Frontend Implementation Guide)

## 개요 (Overview)
Flutter 기반 대학 그룹 관리 시스템의 프론트엔드 아키텍처와 구현 가이드. Toss 디자인 철학을 기반으로 한 프로덕션급 웹 앱 구현.

## 관련 문서
- [디자인 시스템](../ui-ux/design-system.md) - Toss 기반 디자인 토큰
- [컴포넌트 재사용성 가이드](component-reusability-guide.md) - 재사용 가능한 코드 작성 패턴
- [API 참조](api-reference.md) - 백엔드 연동 가이드
- [도메인 개요](../concepts/domain-overview.md) - 시스템 전체 구조

## 기술 스택 및 아키텍처

### 핵심 기술
```dart
Flutter 3.x (Web)        // 크로스플랫폼 프레임워크
Riverpod                // 상태 관리
GoRouter                // 라우팅 시스템
Google Sign In          // OAuth 인증
Responsive Framework    // 반응형 레이아웃
```

### 개발 환경 설정
```bash
# 필수 포트 설정
flutter run -d chrome --web-hostname localhost --web-port 5173

# 환경 변수 (.env 파일)
GOOGLE_WEB_CLIENT_ID=your_web_client_id
GOOGLE_SERVER_CLIENT_ID=your_server_client_id
API_BASE_URL=http://localhost:8080
```

## 아키텍처 패턴

### 디렉토리 구조
```
lib/
├── core/                    # 핵심 공통 모듈
│   ├── theme/              # 디자인 시스템
│   ├── router/             # 라우팅 설정
│   ├── services/           # API, 인증 서비스
│   ├── constants/          # 상수 정의
│   └── models/             # 데이터 모델
├── presentation/           # UI 레이어
│   ├── pages/              # 페이지 컴포넌트
│   ├── widgets/            # 재사용 위젯
│   └── providers/          # 상태 관리
└── main.dart              # 앱 진입점
```

### 레이어 분리
- **Presentation**: UI 컴포넌트, 상태 관리
- **Core/Services**: 비즈니스 로직, API 통신
- **Core/Models**: 데이터 구조 정의

## 재사용성 원칙

### DRY (Don't Repeat Yourself)
동일한 UI 패턴을 반복하지 말고 재사용 가능한 컴포넌트로 분리하세요.

**4단계 재사용 전략:**
1. **하드코딩** (85줄) - 모든 코드를 한 곳에 작성
2. **디자인 토큰화** (60줄) - 스타일을 theme.dart로 분리
3. **컴포넌트화** (35줄) - 위젯으로 분리
4. **완전한 재사용** (3줄) - 헬퍼 함수 + 독립 위젯

**실전 예시:** 로그아웃 다이얼로그 85줄 → 3줄 감소 (96% 코드 감소)

상세 가이드: [컴포넌트 재사용성 가이드](component-reusability-guide.md)

## 완성된 구현 현황

### ✅ 인증 시스템
- **Google OAuth**: 웹/모바일 플랫폼별 클라이언트 설정
- **자동 로그인**: 비차단 방식으로 앱 시작 성능 최적화
- **테스트 계정**: 개발 단계용 관리자 로그인
- **토큰 관리**: JWT 기반 인증, 자동 갱신

```dart
// 인증 서비스 초기화 (main.dart)
authService.tryAutoLogin().catchError((error) {
  print('Auto login failed, continuing with manual login: $error');
});
```

### ✅ 디자인 시스템
- **완전한 토큰 시스템**: AppColors, AppSpacing, AppTypography
- **4가지 버튼 스타일**: Primary, Tonal, Outlined, Google
- **반응형 레이아웃**: 768px 기준 적응형 디자인
- **접근성 최적화**: 포커스 링, Semantics, 키보드 네비게이션

### ✅ 로그인 페이지
- **Toss 디자인 적용**: 4대 원칙 기반 UI 구현
- **부드러운 애니메이션**: 진입 효과, 상태 전환
- **오류 처리**: 상세한 에러 메시지, 사용자 피드백
- **로딩 상태**: 비활성화 버튼, 프로그레스 인디케이터

### ✅ 성능 최적화
- **즉시 로딩**: LocalStorage eager 초기화
- **비차단 인증**: tryAutoLogin으로 앱 시작 속도 개선
- **반응형 최적화**: 화면 크기별 최적화된 레이아웃

## 주요 컴포넌트 구현

### 테마 시스템 (theme.dart)
```dart
// 완성된 디자인 토큰 활용
class AppTheme {
  static ThemeData get lightTheme => _buildLightTheme();

  // 컬러, 타이포그래피, 컴포넌트 테마 정의
  // 4가지 버튼 스타일 지원
  // 접근성 최적화된 포커스 스타일
}
```

### 로그인 페이지 (login_page.dart)
```dart
class LoginPage extends StatefulWidget {
  // Google OAuth 구현
  // 플랫폼별 클라이언트 ID 처리
  // 애니메이션 및 상태 관리
  // 접근성 최적화
}
```

### 라우터 설정 (app_router.dart)
```dart
// GoRouter 기반 선언적 라우팅
// 인증 상태별 리다이렉트
// 온보딩 플로우 지원
```

### 계층적 네비게이션 시스템
```dart
// 페이지별 동적 브레드크럼
// - 일반 페이지: BreadcrumbWidget (단순 제목)
// - 워크스페이스: WorkspaceHeader (그룹/채널 + 드롭다운 지원)

// Provider 기반 경로 계산
final breadcrumb = ref.watch(
  pageBreadcrumbFromPathProvider(routePath)
);
```

- `NavigationController`는 `NavigationEntry` 구조체로 탭별 히스토리를 유지한다.
  - 라우트와 복원용 컨텍스트(Map)를 함께 기록해 이후 화면 복구가 가능하다.
  - 워크스페이스 탭에서 루트(그룹 미선택)로 되돌아오면 홈으로 이동해 빈 화면을 피한다.

## 상태 관리 패턴

### Riverpod 활용
```dart
// Provider 기반 상태 관리
// 의존성 주입 패턴
// 테스트 가능한 구조
```

### 인증 상태 관리
```dart
class AuthService {
  Future<LoginResponse> loginWithGoogle({
    String? idToken,
    String? accessToken,
  });

  Future<void> tryAutoLogin();
  Future<void> logout();
}
```

## 반응형 디자인 구현

### 브레이크포인트 시스템
```dart
ResponsiveBreakpoints.builder(
  breakpoints: [
    const Breakpoint(start: 0, end: 450, name: MOBILE),
    const Breakpoint(start: 451, end: 800, name: TABLET),
    const Breakpoint(start: 801, end: 1920, name: DESKTOP),
    const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
  ],
)
```

### 적응형 레이아웃
```dart
// 화면 크기별 패딩 조정
final horizontalPadding = isWide ? AppTheme.spacing32 : AppTheme.spacing16;
final verticalPadding = isWide ? AppTheme.spacing120 : AppTheme.spacing96;
```

## 성능 최적화 전략

### 앱 시작 성능
```dart
// 즉시 필요한 데이터만 로드
await LocalStorage.instance.initEagerData();

// 비차단 방식 자동 로그인
authService.tryAutoLogin().catchError((error) => {});
```

### 현재 성능 지표
- **초기 로드 시간**: ~13.6초 (최적화 여지 있음)
- **핫 리로드**: < 1초
- **메모리 사용량**: 최적화됨

### 개선 계획
- 폰트 및 SVG 자산 최적화
- 코드 분할 및 지연 로딩
- 이미지 최적화 및 캐싱

## API 연동 패턴

### HTTP 클라이언트 설정
```dart
class ApiService {
  static const String baseUrl = 'http://localhost:8080';

  // JWT 토큰 자동 첨부
  // 오류 처리 및 재시도 로직
  // 타입 안전한 API 호출
}
```

### 인증 토큰 관리
```dart
// 자동 토큰 갱신
// 로컬 스토리지 캐싱
// 만료 시 재로그인 플로우
```

## 테스트 전략

### 단위 테스트
```dart
// 서비스 레이어 테스트
// 모델 검증 테스트
// 유틸리티 함수 테스트
```

### 위젯 테스트
```dart
// 컴포넌트 렌더링 테스트
// 사용자 인터랙션 테스트
// 상태 변경 테스트
```

## 개발 가이드라인

### 코딩 컨벤션
- **네이밍**: 카멜케이스, 명확한 의미
- **파일 구조**: 기능별 디렉토리 분리
- **주석**: 복잡한 로직에 한해 영어 주석

### Git 워크플로우
```bash
# 기능 브랜치 생성
git checkout -b feature/new-feature

# 커밋 메시지 규칙
git commit -m "feat(auth): add Google login functionality"
```

## 다음 구현 예정

### 🚧 진행 중
- 워크스페이스 화면 개발
- 그룹 관리 UI 구현

### ❌ 미구현
- 그룹 모집 시스템 프론트엔드
- 실시간 알림 시스템
- 관리자 대시보드

## 트러블슈팅

### 일반적인 문제
1. **포트 충돌**: 반드시 5173 포트 사용
2. **환경 변수**: .env 파일 설정 확인
3. **CORS 이슈**: 백엔드 CORS 설정 점검
4. **빌드 에러**: flutter clean 후 재실행
