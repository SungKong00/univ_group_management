# TASK

## 작업 목표
- [x] 목표 요약: 그룹 생성 시 발생하는 NumberFormatException 에러 수정
- [x] 성공 기준: 백엔드 컴파일 및 서버 시작 성공, NumberFormatException 해결

## 컨텍스트 요청 (태그, 파일, 영역)
- 태그: backend, auth, group-management, error-fix
- 관련 소스/디렉토리: backend/src/main/kotlin/org/castlekong/backend/controller/GroupController.kt
- 참고 문서: 없음

## 개발 지시 (Claude Code용)
- SYNTHESIZED_CONTEXT.MD를 먼저 읽고 구현 순서를 제안하세요.
- 생성/수정 파일 목록을 제안한 뒤 합의된 순서대로 구현하세요.
- 모든 변경은 본 작업 폴더의 '작업 로그'에 요약을 남기세요.
- 실패/에러는 로그와 함께 Codex 호출을 요청하세요.

## 작업 로그
- 2025-09-12 18:08 [Claude] NumberFormatException 원인 분석 완료
- 2025-09-12 18:08 [Claude] AuthService에서 authentication.name이 이메일로 설정되지만, GroupController에서 toLong() 호출로 에러 발생함을 확인
- 2025-09-12 18:09 [Claude] GroupController에 UserService 의존성 추가 및 getUserByEmail 헬퍼 메서드 구현
- 2025-09-12 18:10 [Claude] 모든 authentication.name.toLong() 호출을 이메일 기반 사용자 조회로 변경
- 2025-09-12 18:11 [Claude] 백엔드 컴파일 성공 확인
- 2025-09-12 18:13 [Claude] Spring Boot 서버 시작 성공

## 변경 사항 요약
- 생성/수정 파일:
  - backend/src/main/kotlin/org/castlekong/backend/controller/GroupController.kt (수정)
- 핵심 로직:
  - UserService 의존성 추가
  - getUserByEmail() 헬퍼 메서드 추가
  - 모든 authentication.name.toLong() 호출을 getUserByEmail(authentication.name).id로 변경
  - 이메일 기반 사용자 인증과 일치하도록 컨트롤러 로직 통일

## 컨텍스트 업데이트 요청
- context/troubleshooting.md에 NumberFormatException 관련 인증 처리 패턴 추가 요청
- metadata.json에 authentication 관련 에러 해결 사례 추가 요청

