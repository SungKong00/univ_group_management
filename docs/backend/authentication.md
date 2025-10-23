# 인증 시스템

Google OAuth2 + JWT 기반의 Stateless 인증 구조입니다.

## 개요

**로그인 흐름:** Google ID Token → JWT 발급 → API 요청 시 JWT 검증

**특징:**
- Stateless (세션 없음)
- JWT에 사용자 정보 및 globalRole 포함
- 권한 캐싱으로 성능 최적화

## 인증 흐름도

```
1. 최초 로그인
Frontend --[Google ID Token]--> /api/auth/google
                                      ↓
                          AuthService.authenticateWithGoogle()
                          1. Google 토큰 검증
                          2. User 생성/조회
                          3. JWT 생성
                                      ↓
Backend --[JWT + userInfo]--> Frontend

2. API 요청
Frontend --[Header: Authorization: Bearer JWT]--> Any API
                                                       ↓
                                       JwtAuthenticationFilter
                                       1. JWT 추출
                                       2. 토큰 검증
                                       3. SecurityContext 설정
                                                       ↓
                                          @PreAuthorize 권한 검사
```

## 핵심 컴포넌트

### 설정
- `SecurityConfig` - Stateless 세션 정책, 필터 체인 구성

### 인증 처리
- `AuthController` - `/api/auth/google` 엔드포인트
- `AuthService` - Google 토큰 검증, JWT 생성 로직
- `JwtTokenProvider` - JWT 생성/검증

### 필터
- `JwtAuthenticationFilter` - 모든 요청의 JWT 검증
- 위치: `UsernamePasswordAuthenticationFilter` 이전 (먼저 실행)

## 주요 기능

1. **Google 토큰 검증**: `verifyGoogleToken(token)`
2. **사용자 자동 생성**: 신규 사용자 첫 로그인 시 User 엔티티 생성
3. **JWT 발급**: `JwtTokenProvider.generateAccessToken(authentication)`
4. **온보딩 상태**: `profileCompleted` 필드로 추가 정보 입력 여부 관리

## 코드 참조

**설정:**
- `backend/src/main/kotlin/org/castlekong/backend/config/SecurityConfig.kt`

**서비스:**
- `backend/src/main/kotlin/org/castlekong/backend/service/AuthService.kt`

**JWT 처리:**
- `backend/src/main/kotlin/org/castlekong/backend/security/JwtTokenProvider.kt`
- `backend/src/main/kotlin/org/castlekong/backend/security/JwtAuthenticationFilter.kt`

**엔티티:**
- `backend/src/main/kotlin/org/castlekong/backend/entity/User.kt` - `profileCompleted`, `globalRole`

## 관련 문서

- [권한 시스템](../concepts/permission-system.md) - JWT 이후의 권한 검증
- [API 참조](../implementation/api-reference.md#인증) - 인증 API 명세
- [개발 가이드](../implementation/backend/README.md) - 보안 구현 패턴
