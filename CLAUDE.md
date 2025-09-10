# CLAUDE.md - AI Agent 협업 워크플로우 설정

## 1. Gemini CLI 통합 및 작업 패키지 시스템

### 기본 원칙
- 모든 개발 작업은 `tasks/` 폴더 내 독립적인 작업 패키지에서 수행
- Gemini CLI가 생성한 `SYNTHESIZED_CONTEXT.MD`를 기반으로 개발 수행
- `TASK.MD`에 모든 작업 과정을 실시간으로 기록

### 작업 패키지 감지 및 활용
```bash
# 작업 패키지 자동 감지 로직
1. 현재 디렉토리에 TASK.MD 파일이 있는가? -> 해당 디렉토리가 작업 패키지
2. 없다면 tasks/ 폴더에서 활성 작업 패키지 검색
3. 작업 패키지가 없다면 새로운 작업 패키지 생성 안내
```

## 2. 작업 시작 전 필수 확인 사항

### 작업 패키지 확인 절차
1. **작업 패키지 존재 확인**: `TASK.MD` 파일 존재 여부 확인
2. **컨텍스트 파일 확인**: `SYNTHESIZED_CONTEXT.MD` 파일 존재 여부 확인
3. **미완료 시 안내**: 
   ```
   작업을 시작하기 전에 다음 명령어를 실행해주세요:
   - 새 작업: gemini task new "작업 제목"
   - 컨텍스트 생성: gemini task run-context
   ```

## 3. 개발 워크플로우 자동화

### A. SYNTHESIZED_CONTEXT.MD 기반 개발
```markdown
개발 시작 전 필수 단계:
1. SYNTHESIZED_CONTEXT.MD를 먼저 읽고 분석
2. 프로젝트 구조, 규칙, 제약사항 파악
3. 구현 계획 수립 및 순서 제안
4. 사용자와 구현 계획 합의 후 개발 시작
```

### B. 실시간 작업 로그 업데이트
- 모든 주요 작업은 `TASK.MD`의 "작업 로그" 섹션에 기록
- 로그 형식: `YYYY-MM-DD HH:MM [Claude] 작업 내용`
- 기록해야 할 내용:
  - 파일 생성/수정 완료
  - 주요 기능 구현 완료
  - 테스트 실행 결과
  - 에러 발생 및 해결 과정

### C. 에러 처리 및 Codex 연동
```markdown
에러 발생 시 처리 절차:
1. 에러 로그와 상황을 TASK.MD에 기록
2. SYNTHESIZED_CONTEXT.MD와 함께 분석
3. 해결책 제시 및 적용
4. 해결 과정을 작업 로그에 상세히 기록
```

## 4. 작업 완료 시 처리

### 변경 사항 요약 작성
작업 완료 시 `TASK.MD`의 "변경 사항 요약" 섹션에 다음 내용 기록:
- **생성/수정 파일 목록**: 파일 경로와 변경 내용
- **핵심 로직**: 구현한 주요 기능과 로직
- **테스트 결과**: 실행한 테스트와 결과

### 컨텍스트 업데이트 요청
새로운 지식이나 규칙이 도출된 경우 "컨텍스트 업데이트 요청" 섹션에:
- 업데이트할 context 파일 및 내용
- metadata.json 인덱싱 태그 추가 요청

## 5. Gemini CLI 사용 가이드 (For Claude Code)

Claude Code는 이 프로젝트의 워크플로우를 관리하기 위해 `gemini`라는 터미널 명령어를 사용할 수 있습니다. 모든 명령어는 zsh 셸 환경에서 실행해야 합니다.

### 1. 작업 시작
새로운 작업을 시작할 때, 다음 형식으로 명령어를 실행하세요:

```bash
gemini task new "작업에 대한 간결한 설명"
```

### 2. 컨텍스트 종합
TASK.MD 작성이 완료된 후, 해당 작업 폴더로 이동하여 아래 명령어를 실행해야 합니다:

```bash
# 먼저 작업 폴더로 이동
cd tasks/YYYY-MM-DD-작업-폴더-이름

# 컨텍스트 생성 명령어 실행
gemini task run-context
```

### 3. 작업 완료
모든 코딩 작업이 끝나고 사용자가 승인하면, 현재 작업 폴더 내에서 다음 명령어를 실행하여 작업을 아카이빙합니다:

```bash
gemini task complete
```

### 기존 Gemini CLI 명령어 요약
- `gemini task new "제목"`: 새 작업 패키지 생성
- `gemini task run-context`: 컨텍스트 종합 및 SYNTHESIZED_CONTEXT.MD 생성
- `gemini task complete`: 작업 완료 및 아카이빙

## 6. 프로젝트 구조 이해
```
univ_group_management/
├── .gemini/metadata.json      # 정적 컨텍스트 인덱스
├── context/                   # 프로젝트 정적 지식베이스
├── tasks/                     # 작업 패키지 저장소
│   ├── template.md           # 작업 템플릿
│   ├── archive/              # 완료된 작업 보관
│   └── [작업폴더]/           # 현재 작업 패키지
├── backend/                  # Spring Boot 소스
├── frontend/                 # Flutter 소스
└── bin/gemini               # Gemini CLI 스크립트
```

## 7. 코딩 규칙 및 제약사항

### 기본 원칙
- context/ 디렉토리의 규칙과 제약사항 준수
- 기존 코드 스타일과 패턴 유지
- 보안 모범 사례 적용

### 테스트 및 품질 보증
- 구현 완료 후 관련 테스트 실행
- 빌드 및 컴파일 오류 해결
- 코드 품질 도구 실행 (가능한 경우)

## 8. 사용자 상호작용 가이드

### 작업 시작 시 확인 메시지
```
현재 작업 패키지를 확인 중입니다...
- TASK.MD: [존재/없음]
- SYNTHESIZED_CONTEXT.MD: [존재/없음]

[필요시] 작업 패키지가 준비되지 않았습니다. 다음을 실행해주세요:
1. gemini task new "작업 제목"
2. TASK.MD에서 작업 목표와 컨텍스트 요청 작성
3. gemini task run-context
```

### 개발 진행 중 상황 보고
- 주요 단계 완료 시 간단한 진행 상황 보고
- 에러 발생 시 상황 설명 및 해결 과정 공유
- 작업 완료 시 결과 요약 제시

이 설정을 통해 Claude Code는 Gemini CLI 워크플로우와 완벽하게 통합되어 효율적인 AI Agent 협업 개발을 수행할 수 있습니다.