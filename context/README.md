# Project Static Context

이 디렉토리는 장기적으로 유지되는 프로젝트의 정적 지식(아키텍처 원칙, 코드 규칙, API 규약 등)을 담습니다. `tasks` 내 작업 패키지에서 도출된 새로운 인사이트는 작업 완료 시 이곳 문서에 반영됩니다.

구성 권장안:
- architecture.md: 시스템 아키텍처 개요, 구성요소, 의존성 지도
- api-conventions.md: REST API/DTO 규칙, 에러 포맷, 버전 정책
- coding-standards.md: 패키징, 네이밍, 로그/예외 처리 규칙
- security.md: 인증/인가, 암호화, 시크릿 관리
- testing.md: 테스트 전략, 계층, 픽스처 규칙

운영 규칙:
- 문서명은 소문자-kebab-case로 작성합니다.
- 큰 변경사항은 CHANGELOG.md에 항목을 추가합니다.
- `.gemini/metadata.json`의 include/exclude 패턴으로 인덱싱 범위를 제어합니다.
