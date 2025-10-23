# 아키텍처 (Architecture)

## 기술 스택

### 핵심 라이브러리

- **Flutter 3.x (Web)**: 크로스플랫폼 프레임워크
- **Riverpod**: 상태 관리 및 의존성 주입
- **GoRouter**: 선언적 라우팅 시스템
- **Google Sign In**: OAuth 2.0 인증
- **Responsive Framework**: 반응형 레이아웃

### 개발 환경 설정

```bash
# Flutter 웹 서버 실행 (반드시 5173 포트)
flutter run -d chrome --web-hostname localhost --web-port 5173

# 환경 변수 (.env 파일)
GOOGLE_WEB_CLIENT_ID=your_web_client_id
GOOGLE_SERVER_CLIENT_ID=your_server_client_id
API_BASE_URL=http://localhost:8080
```

## 디렉토리 구조

```
lib/
├── core/                    # 핵심 공통 모듈
│   ├── theme/              # 디자인 시스템
│   ├── router/             # 라우팅 설정
│   ├── services/           # API, 인증 서비스
│   ├── providers/          # 공통 Provider
│   ├── constants/          # 상수 정의
│   └── models/             # 데이터 모델
├── presentation/           # UI 레이어
│   ├── pages/              # 페이지 컴포넌트
│   ├── widgets/            # 재사용 위젯
│   └── providers/          # 상태 관리 (페이지별)
└── main.dart              # 앱 진입점
```

## 레이어 분리

**3계층 아키텍처**:

- **Presentation**: UI 컴포넌트, 상태 관리 (Riverpod Provider)
- **Core/Services**: 비즈니스 로직, API 통신
- **Core/Models**: 데이터 구조 정의

각 레이어는 명확한 책임을 가지며, 하위 레이어에만 의존합니다.

## API 연동 패턴

HTTP 클라이언트 설정:

```dart
class ApiService {
  static const String baseUrl = 'http://localhost:8080';

  // JWT 토큰 자동 첨부
  // 오류 처리 및 재시도 로직
  // 타입 안전한 API 호출
}
```

**특징**:
- 모든 요청에 JWT 토큰 자동 포함
- 네트워크 오류 자동 재시도
- 타입 안전한 응답 처리

## 라우팅 시스템

**GoRouter 기반 선언적 라우팅**:

- 인증 상태별 자동 리다이렉트
- 온보딩 플로우 지원
- 동적 라우트 파라미터 처리

**파일**: lib/core/router/app_router.dart

라우팅 규칙:
- 미인증 사용자 → 로그인 페이지
- 인증 사용자 → 홈 페이지
- 특정 권한 필요 페이지 → 권한 체크
