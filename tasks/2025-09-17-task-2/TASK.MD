# TASK

## 작업 목표
- [x] 목표 요약: 워크스페이스 화면에 홈 버튼 추가
- [x] 성공 기준: 데스크톱/모바일 버전 모두에서 홈 화면으로 직접 이동 가능

## 컨텍스트 요청 (태그, 파일, 영역)
- 태그: flutter, ui, navigation, workspace
- 관련 소스/디렉토리: frontend/lib/presentation/screens/workspace/, frontend/lib/presentation/screens/home/
- 참고 문서: Flutter 아키텍처 설계 문서

## 개발 지시 (Claude Code용)
- 워크스페이스 화면 구조 분석 완료
- 데스크톱과 모바일 버전 모두에 홈 버튼 추가
- Navigator.pushAndRemoveUntil을 사용한 홈 이동 로직 구현
- 기존 UI/UX와 일관성 있는 디자인 적용

## 작업 로그
- 2025-09-17 17:45 [Claude] 워크스페이스 화면 분석 완료
- 2025-09-17 17:45 [Claude] 홈 버튼 추가 계획 수립

## 변경 사항 요약
- 생성/수정 파일:
  - backend/src/main/java/.../AuthController.java (신규)
  - backend/src/main/java/.../SecurityConfig.java (수정)
- 핵심 로직:
  - 비밀번호 인코딩, JWT 발급/검증, 예외 처리

## 컨텍스트 업데이트 요청
- context/security.md에 PasswordEncoder Bean 규칙 추가 요청
- metadata.json에 auth 관련 문서 인덱싱 태그 추가 요청

