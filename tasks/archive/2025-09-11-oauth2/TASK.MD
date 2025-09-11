# TASK

## 작업 목표
- [x] 목표 요약: OAuth2 로그인 후 회원가입 플로우 버그 수정 - profileCompleted 기반 라우팅 문제 해결
- [부분완료] 성공 기준: Google OAuth2 로그인 후 역할 선택 화면으로 정상 이동 (일부 미해결)

## 컨텍스트 요청 (태그, 파일, 영역)
- 태그: frontend, auth, oauth2, routing, flutter, splash-screen
- 관련 소스/디렉토리: frontend/lib/main.dart, backend/src/main/kotlin/.../service/UserService.kt
- 참고 문서: context/feature-specifications.md, context/frontend-architecture.md

## 개발 지시 (Claude Code용)
- SYNTHESIZED_CONTEXT.MD를 먼저 읽고 구현 순서를 제안하세요.
- 생성/수정 파일 목록을 제안한 뒤 합의된 순서대로 구현하세요.
- 모든 변경은 본 작업 폴더의 '작업 로그'에 요약을 남기세요.
- 실패/에러는 로그와 함께 Codex 호출을 요청하세요.

## 작업 로그
- 2025-09-11 23:30 [Claude] 문제 진단: OAuth2 로그인 후 바로 홈으로 이동하는 문제 분석 시작
- 2025-09-11 23:35 [Claude] 백엔드 AuthController, UserService, User 엔티티 확인 완료
- 2025-09-11 23:40 [Claude] 백엔드에서 profileCompleted = false 명시적 설정 추가
- 2025-09-11 23:45 [Claude] 프론트엔드 디버그 로그 추가: AuthProvider, SplashScreen
- 2025-09-11 23:50 [Claude] 문제 원인 파악: Widget dispose 타이밍 문제로 인한 크래시
- 2025-09-11 23:55 [Claude] SchedulerBinding.addPostFrameCallback으로 안전한 라우팅 구현
- 2025-09-12 00:05 [Claude] AuthProvider 리스너 중복 실행 문제 해결: 네비게이션 후 리스너 제거
- 2025-09-12 00:10 [Claude] 여전히 역할 선택 화면에서 빠르게 홈으로 이동하는 문제 미해결 상태

## 변경 사항 요약
- 수정된 파일:
  - backend/src/main/kotlin/org/castlekong/backend/service/UserService.kt: profileCompleted = false 명시적 설정
  - backend/src/main/kotlin/org/castlekong/backend/controller/AuthController.kt: 디버그 API 추가
  - backend/src/main/kotlin/org/castlekong/backend/service/AuthService.kt: 디버그 메서드 추가
  - frontend/lib/main.dart: SplashScreen 라우팅 로직 개선 (SchedulerBinding, 리스너 제거)
  - frontend/lib/presentation/providers/auth_provider.dart: 디버그 로그 추가
- 핵심 로직:
  - 백엔드: 신규 사용자 생성 시 profileCompleted = false 보장
  - 프론트엔드: Widget 라이프사이클 안전한 네비게이션, 중복 라우팅 방지
- 미해결 문제:
  - 역할 선택 화면이 빠르게 나타났다가 홈 화면으로 이동하는 문제 지속

## 컨텍스트 업데이트 요청
- context/frontend-architecture.md: SplashScreen 라우팅 로직 업데이트 및 Flutter Widget 라이프사이클 문제 해결 내용 추가
- context/troubleshooting.md: OAuth2 회원가입 플로우 디버깅 경험 및 해결 방법 문서화
- .gemini/metadata.json: oauth2-debug, widget-lifecycle, flutter-navigation 태그 추가

