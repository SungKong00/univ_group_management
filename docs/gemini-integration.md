# Gemini CLI 통합 가이드

## 목적
- `bin/gemini` 헬퍼 스크립트를 통해 작업 패키지 생성/컨텍스트 종합/아카이빙을 일관화합니다.
- 실제 모델 호출은 환경변수 `GEMINI_CLI`로 지정한 외부 Gemini CLI에 위임합니다.

## 설치/환경 변수
- 실행 권한: `chmod +x bin/gemini`
- PATH 등록(옵션): `export PATH="$(pwd)/bin:$PATH"`
- Gemini CLI 지정: `export GEMINI_CLI=gemini` (로컬에 설치된 명령 이름)

## 명령어
- `gemini task new "<title>"`: `tasks/<date>-<slug>/` 생성, `TASK.MD` 복사
- `gemini task run-context`: `synthesis_input/` 빌드 후 Gemini CLI로 `SYNTHESIZED_CONTEXT.MD` 생성 시도
- `gemini task complete`: 현재 작업 폴더를 `tasks/archive/`로 이동하고 `context/CHANGELOG.md` 기록

## 자동 호출(Claude Code 연동)
- 관례: Claude가 작업 폴더에 진입(TASK.MD 존재) 후 아래를 수행
  1. `gemini task run-context` 실행
  2. `SYNTHESIZED_CONTEXT.MD` 확인 후 개발 진행
  3. 완료 시 `gemini task complete` 실행 제안
- 실패 시 대안: `synthesis_input/PROMPT.md`와 `INPUT_CONTEXT.md`를 사용하여 수동 또는 다른 도구로 컨텍스트 생성

## 입력 구성
- `synthesis_input/CONTEXT_SOURCES.md`: 포함된 정적 컨텍스트 파일 목록
- `synthesis_input/INPUT_CONTEXT.md`: 정적 컨텍스트 병합본
- `synthesis_input/PROMPT.md`: Gemini에게 컨텍스트 생성 지시

## 구성 제어
- `.gemini/metadata.json`의 include/exclude 패턴으로 정적 컨텍스트 범위를 조정하세요.
- 대규모 소스 스캔이 필요하면 `TASK.MD`의 "컨텍스트 요청" 섹션에 명시하고 Claude에게 제한/우선순위를 부여하세요.
