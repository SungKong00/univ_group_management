# TASK

## 작업 목표
- [ ] 목표 요약: JWT 기반 로그인 API 구현 (Spring Boot + Kotlin)
- [ ] 성공 기준: 
  - 사용자 인증 및 JWT 토큰 발급 API 완성
  - Spring Security 설정 및 보안 규칙 적용
  - 통합 테스트 통과
  - API 문서 작성 및 반영

## 컨텍스트 요청 (태그, 파일, 영역)
- 태그: auth, jwt, spring-security, login, authentication
- 관련 소스/디렉토리: 
  - backend/src/main/kotlin (컨트롤러, 서비스, 엔티티)
  - backend/src/main/resources (설정 파일)
- 참고 문서: 
  - context/security.md (보안 정책 및 JWT 설정)
  - context/api-conventions.md (API 설계 표준)
  - context/coding-standards.md (Kotlin 코딩 표준)

## 개발 지시 (Claude Code용)
- SYNTHESIZED_CONTEXT.MD를 먼저 읽고 구현 순서를 제안하세요.
- 생성/수정 파일 목록을 제안한 뒤 합의된 순서대로 구현하세요.
- 모든 변경은 본 작업 폴더의 '작업 로그'에 요약을 남기세요.
- 실패/에러는 로그와 함께 Codex 호출을 요청하세요.

## 작업 로그
- 2025-09-10 17:00 [Claude] 로그인 API 작업 패키지 생성 및 TASK.MD 설정 완료.
- 2025-09-10 17:05 [Claude] JWT 의존성 및 기본 패키지 구조 생성 완료.
- 2025-09-10 17:10 [Claude] User 엔티티 및 Repository 구현 완료.
- 2025-09-10 17:15 [Claude] JWT 토큰 유틸리티 (JwtTokenProvider, JwtAuthenticationFilter) 구현 완료.
- 2025-09-10 17:20 [Claude] Spring Security 설정 및 보안 규칙 적용 완료.
- 2025-09-10 17:25 [Claude] 로그인/회원가입 API 컨트롤러 및 서비스 계층 구현 완료.
- 2025-09-10 17:30 [Claude] application.yml 설정 및 JPA Auditing 활성화 완료.
- 2025-09-10 17:35 [Claude] Spring Boot 애플리케이션 빌드 및 실행 성공.
- 2025-09-10 17:40 [Claude] 로그인/회원가입 API 테스트 성공 확인.

## 변경 사항 요약

### 생성된 파일
- **build.gradle**: JWT 라이브러리 의존성 추가 (jjwt 0.12.6)
- **User.kt**: 사용자 엔티티 클래스 (JPA, UserRole enum 포함)
- **UserRepository.kt**: 사용자 데이터 액세스 인터페이스
- **JwtTokenProvider.kt**: JWT 토큰 생성/검증 유틸리티
- **JwtAuthenticationFilter.kt**: JWT 기반 인증 필터
- **SecurityConfig.kt**: Spring Security 설정 (BCrypt, JWT 필터 체인)
- **AuthController.kt**: 로그인/회원가입 REST API 컨트롤러
- **AuthDto.kt**: 로그인/회원가입 요청/응답 DTO 클래스
- **ApiResponse.kt**: 공통 API 응답 형식 정의
- **UserService.kt**: 사용자 관리 비즈니스 로직
- **AuthService.kt**: 인증 비즈니스 로직
- **JpaConfig.kt**: JPA Auditing 활성화 설정
- **application.yml**: 애플리케이션 설정 (DB, JWT, 로깅, Swagger)

### 구현된 핵심 기능
- **사용자 인증 시스템**: 이메일/비밀번호 기반 로그인
- **JWT 토큰 관리**: Access Token(24시간), Refresh Token(7일) 발급
- **비밀번호 보안**: BCrypt 암호화 (강도 12)
- **사용자 권한 관리**: GUEST, USER, MODERATOR, ADMIN 역할
- **API 보안**: Spring Security + JWT 기반 Stateless 인증
- **입력 검증**: Bean Validation을 통한 요청 데이터 검증
- **에러 처리**: 구조화된 에러 응답 및 HTTP 상태 코드
- **API 문서화**: Swagger/OpenAPI 3.0 자동 생성

### 테스트 결과
- **회원가입 API**: POST /api/v1/auth/register ✅
- **로그인 API**: POST /api/v1/auth/login ✅  
- **JWT 토큰 발급**: Access/Refresh Token 정상 생성 ✅
- **Spring Boot 애플리케이션**: http://localhost:8080 실행 성공 ✅

## 컨텍스트 업데이트 요청
- context/security.md에 PasswordEncoder Bean 규칙 추가 요청
- metadata.json에 auth 관련 문서 인덱싱 태그 추가 요청

