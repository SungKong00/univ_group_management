# TASK

## 작업 목표
- [ ] 목표 요약: (예: JWT 기반 로그인 API 구현)
- [ ] 성공 기준: (예: 통합 테스트 통과, 문서 반영)

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
- YYYY-MM-DD HH:MM [Claude] 초기 세팅 완료.
- YYYY-MM-DD HH:MM [Codex] 에러 원인 분석 및 수정 제안.

## 변경 사항 요약
- 생성/수정 파일:
  - backend/src/main/java/.../AuthController.java (신규)
  - backend/src/main/java/.../SecurityConfig.java (수정)
- 핵심 로직:
  - 비밀번호 인코딩, JWT 발급/검증, 예외 처리

## 컨텍스트 업데이트 요청
- context/security.md에 PasswordEncoder Bean 규칙 추가 요청
- metadata.json에 auth 관련 문서 인덱싱 태그 추가 요청

