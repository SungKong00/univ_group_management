# TASK

## 작업 목표
- [ ] 목표 요약: Google OAuth2를 사용한 로그인 API 재구현
- [ ] 성공 기준: 기존 로그인 API 삭제 후 Google OAuth2만 지원하는 API 구현 완료

## 컨텍스트 요청 (태그, 파일, 영역)
- 태그: auth, oauth2, google, spring-security, spring-boot
- 관련 소스/디렉토리: backend/src/main/kotlin/org/castlekong/backend/controller/, backend/src/main/kotlin/org/castlekong/backend/security/, backend/src/main/kotlin/org/castlekong/backend/service/
- 참고 문서: context/security.md, context/api-conventions.md, context/requirements.md

## 개발 지시 (Claude Code용)
- SYNTHESIZED_CONTEXT.MD를 먼저 읽고 구현 순서를 제안하세요.
- 생성/수정 파일 목록을 제안한 뒤 합의된 순서대로 구현하세요.
- 모든 변경은 본 작업 폴더의 '작업 로그'에 요약을 남기세요.
- 실패/에러는 로그와 함께 Codex 호출을 요청하세요.

## 작업 로그
- 2025-09-11 11:25 [Claude] 기존 백엔드 로그인 관련 코드 분석 완료
- 2025-09-11 11:26 [Claude] build.gradle에 Google API Client 라이브러리 의존성 추가 완료
- 2025-09-11 11:27 [Claude] AuthDto.kt에 GoogleLoginRequest DTO 추가 완료
- 2025-09-11 11:28 [Claude] AuthController.kt에서 기존 login/register API 삭제 후 /api/auth/google 엔드포인트 구현 완료
- 2025-09-11 11:30 [Claude] AuthService.kt에서 Google 토큰 검증 로직 및 authenticateWithGoogle 메서드 구현 완료
- 2025-09-11 11:32 [Claude] UserService.kt에 findOrCreateUser 메서드 구현 완료
- 2025-09-11 11:34 [Claude] SecurityConfig.kt에서 /api/auth/google만 permitAll로 설정, 기존 PasswordEncoder Bean 삭제 완료
- 2025-09-11 11:36 [Claude] 기존 비밀번호 기반 인증 관련 코드 삭제 및 application.yml에 Google Client ID 설정 추가 완료
- 2025-09-11 11:37 [Claude] 컴파일 검증 완료, Google OAuth2 로그인 API 재구현 완료

## 변경 사항 요약
- 생성/수정 파일:
  - backend/build.gradle (Google API Client 의존성 추가)
  - backend/src/main/kotlin/org/castlekong/backend/dto/AuthDto.kt (GoogleLoginRequest DTO 추가, 기존 DTO 제거)
  - backend/src/main/kotlin/org/castlekong/backend/controller/AuthController.kt (Google OAuth2 API만 구현)
  - backend/src/main/kotlin/org/castlekong/backend/service/AuthService.kt (Google 토큰 검증 로직 구현)
  - backend/src/main/kotlin/org/castlekong/backend/service/UserService.kt (findOrCreateUser 메서드 추가, PasswordEncoder 의존성 제거)
  - backend/src/main/kotlin/org/castlekong/backend/config/SecurityConfig.kt (Google OAuth2만 허용하도록 설정)
  - backend/src/main/resources/application.yml (Google Client ID 설정 추가)
- 핵심 로직:
  - Google OAuth2 토큰 검증 및 사용자 조회/생성
  - JWT 토큰 발급
  - 기존 비밀번호 기반 인증 완전 제거
  - POST /api/auth/google 엔드포인트만 제공

## 컨텍스트 업데이트 요청
- context/security.md에 Google OAuth2 인증 방식 및 JWT 발급 규칙 추가 요청
- context/api-conventions.md에 /api/auth/google 엔드포인트 명세 추가 요청
- metadata.json에 oauth2, google, spring-security 태그 추가 요청

