# AI Agent 협업 기반 개발 워크플로우 명세서 (v3.0)

## 개요
- Spring Boot(backend)와 Flutter(frontend) 통합 프로젝트의 개발 프로세스 표준화 및 자동화.
- 각 개발 작업은 독립적인 작업 패키지(`tasks/<date>-<slug>/`)로 관리.
- Gemini CLI가 컨텍스트 종합을 담당, Claude Code가 개발, Codex가 디버깅을 지원.

## 주요 구성 요소
- Developer: 작업 지시, 감독, 최종 승인.
- Gemini CLI: 작업 컨텍스트 종합(SYNTHESIZED_CONTEXT.MD), 정적 컨텍스트 인덱싱 관리.
- Claude Code: 개발/리팩토링 수행, 로그 기록.
- Codex: 에러 분석 및 해결책 제시.

## 디렉토리 구조
- `.gemini/metadata.json`: 정적 컨텍스트 인덱스/패턴.
- `context/`: 장기 지식 베이스(아키텍처, 규칙 등).
- `backend/`, `frontend/`: 애플리케이션 소스.
- `tasks/`: 작업 패키지 루트
  - `template.md`: 표준 작업 템플릿
  - `archive/`: 완료 패키지 보관
  - `[current-task]/TASK.MD`: 작업 메인 스레드
  - `[current-task]/SYNTHESIZED_CONTEXT.MD`: Gemini 종합 컨텍스트

## 절차
1) 작업 패키지 생성
- 명령: `gemini task new "feat: JWT 기반 로그인 API 구현"`
- 결과: `tasks/2025-09-10-feat-jwt-login-api/` 생성, `TASK.MD` 초기화.

2) 지능형 컨텍스트 종합
- 명령: 작업 폴더에서 `gemini task run-context`
- 동작: `TASK.MD`와 `context/**/*.md`를 바탕으로 종합 입력 생성, Gemini CLI로 `SYNTHESIZED_CONTEXT.MD` 생성(또는 수동 템플릿).

3) 개발/협업 사이클
- Developer가 `TASK.MD`의 "개발 지시"에 Claude Code 지시.
- Claude Code는 구현/로그 기록, 문제 시 Codex 호출 후 로그 반영.
- 목표 달성 시 "변경 사항 요약" 작성.

4) 완료 및 자산화
- 명령: `gemini task complete`
- 동작: 작업 패키지 아카이빙, `context/CHANGELOG.md` 기록. 정적 문서 갱신은 요청 사항을 기준으로 반영.

## 운영 원칙
- 모든 커뮤니케이션과 결정은 `TASK.MD`에 기록.
- 정적 지식은 `context/`에, 일회성 맥락은 `SYNTHESIZED_CONTEXT.MD`에 유지.
- 코드 스타일/규칙은 `context/` 문서로 집약, 지속적으로 보강.
