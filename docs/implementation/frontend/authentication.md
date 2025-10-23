# 인증 시스템 (Authentication)

## Google OAuth 구현

### 설정

**파일**: lib/core/services/auth_service.dart

- **웹 클라이언트 ID**: GOOGLE_WEB_CLIENT_ID 환경 변수
- **서버 클라이언트 ID**: GOOGLE_SERVER_CLIENT_ID (백엔드 검증용)
- **플랫폼별 처리**: 웹/모바일 클라이언트 분리 구현

### 로그인 프로세스

1. Google Sign In 버튼 클릭
2. OAuth 2.0 인증 플로우 시작
3. 사용자 ID Token 획득
4. 백엔드로 Token 전달 및 검증
5. JWT 토큰 발급 및 로컬 스토리지 저장

## 자동 로그인

### 비차단 방식 구현

```dart
authService.tryAutoLogin().catchError((error) {
  print('Auto login failed, continuing with manual login...');
});
```

**특징**:
- 앱 시작 시 이전 로그인 정보 자동 복구
- 로그인 실패해도 앱 시작이 차단되지 않음
- 성능 최적화: 약 500ms 단축

## 토큰 관리

### JWT 토큰 저장소

- **형식**: JWT (HS512 알고리즘)
- **저장 위치**: secure_storage (암호화 저장)
- **자동 갱신**: 만료 시 자동 로그인 플로우

### 로컬 스토리지 캐싱

- **토큰**: secure_storage에 암호화 저장
- **사용자 정보**: SharedPreferences에 저장
- **생명주기**: 로그인 유지, 로그아웃 시 제거

## 로그인 페이지 구현

**파일**: lib/presentation/pages/login_page.dart

**기능**:
- Google OAuth 버튼 (SVG 기반, 브랜드 가이드 준수)
- Toss 디자인 4원칙 적용 (단순함, 위계, 여백, 피드백)
- 부드러운 진입 애니메이션
- 오류 처리 및 상세 에러 메시지
- 로딩 상태 표시 (버튼 비활성화, 프로그레스 인디케이터)
- 접근성 최적화 (포커스 링, Semantics)

## 테스트 계정

**개발 단계용 관리자 로그인**:
- 테스트용 이메일로 로그인 가능
- 고정 토큰으로 인증 우회 가능 (개발 환경에서만)
