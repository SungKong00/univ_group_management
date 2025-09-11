# TASK

## 작업 목표
- [ ] 목표 요약: Flutter 앱의 인증 상태 지속성 문제 해결 및 로그아웃 기능 수정
- [ ] 성공 기준: 뒤로가기, 새로고침, 로그아웃 시에도 인증 상태가 정상적으로 관리됨

## 컨텍스트 요청 (태그, 파일, 영역)
- 태그: (예: auth, jwt, spring-security)
- 관련 소스/디렉토리: (예: backend/src/main/java, frontend/lib)
- 참고 문서: (예: context/security.md, context/api-conventions.md)

## 개발 지시 (Claude Code용)
- SYNTHESIZED_CONTEXT.MD를 먼저 읽고 구현 순서를 제안하세요.
- 생성/수정 파일 목록을 제안한 뒤 합의된 순서대로 구현하세요.
- 모든 변경은 본 작업 폴더의 '작업 로그'에 요약을 남기세요.
- 실패/에러는 로그와 함께 Codex 호출을 요청하세요.

## 작업 로그
- 2025-09-11 18:15 [Claude] 인증 상태 관리 문제 분석 완료
- 2025-09-11 18:20 [Claude] SplashScreen 리스너 메모리 누수 문제 수정
- 2025-09-11 18:25 [Claude] 홈 화면 뒤로가기 처리 및 앱 종료 확인 다이얼로그 추가
- 2025-09-11 18:30 [Claude] 로그아웃 기능 개선: pushNamedAndRemoveUntil 사용으로 화면 스택 완전 정리
- 2025-09-11 18:35 [Claude] 로그인/홈 화면에서 인증 상태 재확인 로직 추가
- 2025-09-11 18:40 [Claude] 화면 전환 시 자동 인증 상태 감지 및 페이지 이동 구현

## 변경 사항 요약
- 생성/수정 파일:
  - frontend/lib/main.dart (수정): SplashScreen 리스너 수명 주기 관리 개선
  - frontend/lib/presentation/screens/home/home_screen.dart (수정): 뒤로가기 처리, 로그아웃 개선, 인증 상태 재확인
  - frontend/lib/presentation/screens/auth/login_screen.dart (수정): 인증 상태 재확인 및 자동 화면 전환
- 핵심 로직:
  - 인증 상태 지속성 문제 해결: 화면 진입 시마다 checkAuthStatus() 호출
  - 로그아웃 후 완전한 화면 스택 정리: pushNamedAndRemoveUntil 사용
  - 메모리 누수 방지: AuthProvider 리스너 적절한 해제
  - 뒤로가기 시 앱 종료 확인 다이얼로그 제공

## 컨텍스트 업데이트 요청
- Flutter 앱 인증 상태 관리 개선 사항을 context/frontend-architecture.md에 문서화 요청
- 인증 관련 버그 해결 가이드를 context/troubleshooting.md에 추가 요청

