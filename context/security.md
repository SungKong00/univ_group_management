# 보안 설정 가이드

## 1. 인증 및 권한 부여

### JWT 기반 인증
- JWT 토큰을 사용한 Stateless 인증 방식 채택
- Google OAuth2와 연동하여 외부 인증 공급자 활용
- JwtAuthenticationFilter를 통한 토큰 검증

### 권한 관리
- Spring Security의 Method-level 보안 활용 (@PreAuthorize)
- GlobalRole과 GroupRole을 통한 역할 기반 접근 제어 (RBAC)
- CustomPermissionEvaluator를 통한 세밀한 권한 검증

## 2. 패스워드 보안

### PasswordEncoder Bean 설정 규칙
프로젝트에서 패스워드 암호화가 필요한 경우, 다음 규칙을 따라 PasswordEncoder Bean을 설정해야 합니다:

```kotlin
@Bean
fun passwordEncoder(): PasswordEncoder {
    return BCryptPasswordEncoder()
}
```

**규칙 및 권장사항:**
- **필수**: BCryptPasswordEncoder 사용 (Spring Security 권장)
- **금지**: PlainTextPasswordEncoder, MD5, SHA-1 등 취약한 알고리즘 사용 금지
- **위치**: SecurityConfig 클래스 내 Bean으로 정의
- **용도**: 사용자 패스워드 저장 시 암호화, 로그인 시 패스워드 검증
- **주의사항**: 현재 프로젝트는 Google OAuth2 전용으로, 직접 패스워드 저장/검증 기능은 없음

### 패스워드 정책
향후 직접 회원가입 기능 추가 시 적용할 패스워드 정책:
- 최소 8자 이상
- 영문 대/소문자, 숫자, 특수문자 중 3종류 이상 포함
- 연속된 문자 3자리 이상 금지
- 사용자 정보(이름, 이메일 등)와 유사한 패스워드 금지

## 3. CORS 설정

### 개발 환경
- localhost의 모든 포트 허용 (패턴 기반)
- 모든 HTTP 메서드 및 헤더 허용
- Credentials 비활성화 (JWT 토큰 기반으로 충분)

### 운영 환경 (향후 적용)
- 특정 도메인만 허용
- 필요한 메서드/헤더만 허용
- 보안 헤더 강화

## 4. 세션 관리

- **Stateless**: SessionCreationPolicy.STATELESS 설정
- **JWT 토큰**: 클라이언트 측에서 토큰 저장 및 관리
- **토큰 만료**: 적절한 만료 시간 설정으로 보안성 확보

## 5. API 엔드포인트 보안

### Public 엔드포인트
- `/api/auth/google` - Google OAuth2 인증
- `/swagger-ui/**`, `/v3/api-docs/**` - API 문서
- `/h2-console/**` - 개발용 H2 데이터베이스 콘솔
- `OPTIONS` 메서드 - CORS preflight 요청

### Protected 엔드포인트
- 위 Public 엔드포인트를 제외한 모든 API
- JWT 토큰을 통한 인증 필수
- Method-level 보안을 통한 세밀한 권한 제어

## 6. 보안 헤더

### 현재 설정
- `X-Frame-Options: SAMEORIGIN` - H2 Console 사용을 위해 설정

### 향후 강화 예정
- Content Security Policy (CSP)
- X-Content-Type-Options: nosniff
- X-XSS-Protection: 1; mode=block
- Strict-Transport-Security (HTTPS 적용 시)

## 7. 개발 vs 운영 환경 보안 차이

### 개발 환경 (현재)
- H2 Console 접근 허용
- 넓은 범위의 CORS 설정
- 상세한 오류 메시지 노출

### 운영 환경 (향후)
- H2 Console 비활성화
- 제한적 CORS 설정
- 오류 메시지 최소화
- HTTPS 강제 적용
- 보안 헤더 강화

## 8. 모니터링 및 로깅

### 보안 이벤트 로깅
- 인증 실패 시도
- 권한 없는 리소스 접근 시도
- 토큰 관련 오류

### 모니터링 대상
- 비정상적인 API 호출 패턴
- 반복된 인증 실패
- 권한 상승 시도