# TASK

## 작업 목표
- [ ] 목표 요약: Flutter 앱 개발 - 백엔드 Spring Boot API와 연동하는 대학 그룹 관리 모바일 앱
- [ ] 성공 기준: 
  - JWT 기반 로그인/회원가입 기능 완성
  - 그룹 생성/조회/참여/탈퇴 기능 완성
  - 백엔드 API와 완전한 연동 확인
  - 앱 빌드 및 실행 성공

## 컨텍스트 요청 (태그, 파일, 영역)
- 태그: flutter, mobile, api-integration, jwt, group-management
- 관련 소스/디렉토리: 
  - backend/src/main/kotlin/org/castlekong/backend/ (백엔드 API 구조 파악)
  - frontend/ (새로 생성할 Flutter 프로젝트)
- 참고 문서: 
  - context/security.md (인증 관련 규칙)
  - context/api-conventions.md (API 설계 규칙)
  - backend/src/main/resources/application.yml (백엔드 설정)

## 개발 지시 (Claude Code용)
- SYNTHESIZED_CONTEXT.MD를 먼저 읽고 구현 순서를 제안하세요.
- 백엔드 API 구조를 먼저 분석한 후 Flutter 앱 구조를 설계하세요.
- Flutter 프로젝트 초기 설정부터 시작하여 순차적으로 구현하세요.
- HTTP 통신, 상태 관리, 화면 구성 순서로 진행하세요.
- 모든 변경은 본 작업 폴더의 '작업 로그'에 요약을 남기세요.
- 빌드 에러나 API 연동 실패 시 로그와 함께 상세히 기록하세요.

## 작업 로그
- 2025-09-11 03:20 [Claude] TASK.MD 작성 완료.
- 2025-09-11 03:25 [Claude] SYNTHESIZED_CONTEXT.MD 수동 작성 완료 - 백엔드 API 분석 및 Flutter 개발 전략 수립.
- 2025-09-11 03:30 [Claude] Flutter 프로젝트 기본 구조 생성 완료 (pubspec.yaml, 폴더 구조).
- 2025-09-11 03:35 [Claude] 코어 설정 파일 구현 완료 (상수, 네트워크 클라이언트, 토큰 저장소).
- 2025-09-11 03:40 [Claude] 데이터 모델 및 API 서비스 구현 완료 (User 모델, AuthService, Repository 패턴).
- 2025-09-11 03:45 [Claude] 상태 관리 Provider 구현 완료 (AuthProvider, 의존성 주입 설정).
- 2025-09-11 03:50 [Claude] UI 테마 및 공통 위젯 구현 완료 (미니멀 디자인, 재사용 컴포넌트).
- 2025-09-11 03:55 [Claude] 인증 화면 구현 완료 (로그인, 회원가입, 스플래시, 홈 화면).
- 2025-09-11 04:00 [Claude] Android/iOS 기본 설정 및 README 작성 완료.

## 변경 사항 요약
- 생성/수정 파일:
  - frontend/pubspec.yaml (신규) - Flutter 프로젝트 의존성 설정
  - frontend/lib/core/constants/app_constants.dart (신규) - API 엔드포인트 및 앱 상수 정의
  - frontend/lib/core/network/dio_client.dart (신규) - HTTP 클라이언트 설정 및 인터셉터
  - frontend/lib/core/network/api_response.dart (신규) - API 응답 표준 형식 정의
  - frontend/lib/core/storage/token_storage.dart (신규) - JWT 토큰 안전 저장소
  - frontend/lib/data/models/user_model.dart (신규) - 사용자 데이터 모델 및 인증 DTO
  - frontend/lib/data/services/auth_service.dart (신규) - 인증 API 서비스 로직
  - frontend/lib/domain/repositories/auth_repository.dart (신규) - 인증 Repository 인터페이스
  - frontend/lib/data/repositories/auth_repository_impl.dart (신규) - 인증 Repository 구현체
  - frontend/lib/injection/injection.dart (신규) - GetIt 의존성 주입 설정
  - frontend/lib/presentation/providers/auth_provider.dart (신규) - 인증 상태 관리 Provider
  - frontend/lib/presentation/theme/app_theme.dart (신규) - 미니멀 디자인 테마 설정
  - frontend/lib/presentation/widgets/ (신규) - 공통 UI 컴포넌트 (버튼, 입력필드, 로딩)
  - frontend/lib/presentation/screens/auth/ (신규) - 인증 화면 (로그인, 회원가입)
  - frontend/lib/presentation/screens/home/home_screen.dart (신규) - 메인 홈 화면
  - frontend/lib/main.dart (신규) - Flutter 앱 진입점 및 라우팅 설정
  - frontend/android/app/src/main/AndroidManifest.xml (신규) - Android 앱 설정
  - frontend/android/app/build.gradle (신규) - Android 빌드 설정
  - frontend/ios/Runner/Info.plist (신규) - iOS 앱 설정
  - frontend/README.md (신규) - Flutter 프로젝트 문서화

- 핵심 로직:
  - JWT 기반 인증 시스템 (로그인/회원가입/자동 로그인)
  - Clean Architecture 패턴 적용 (Domain, Data, Presentation 계층 분리)
  - Provider 패턴 상태 관리 및 의존성 주입
  - Dio HTTP 클라이언트 및 인터셉터를 통한 API 통신
  - Flutter Secure Storage를 활용한 토큰 안전 저장
  - 미니멀하고 모던한 UI/UX 디자인 (토스 스타일 적용)
  - 에러 처리 및 사용자 친화적 메시지 표시
  - 반응형 디자인 및 크로스 플랫폼 호환성 (Android/iOS)

## 컨텍스트 업데이트 요청
- context/flutter-conventions.md 신규 생성 요청 (Flutter 개발 규칙 및 패턴)
- context/mobile-ui-patterns.md 신규 생성 요청 (모바일 UI/UX 패턴)
- metadata.json에 flutter, mobile 관련 태그 추가 요청

