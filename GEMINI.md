# Gemini Commit Agent: 워크플로우 명세서

## 1. 개요 (Overview)

이 문서는 `git commit` 프로세스를 자동화하고, 프로젝트의 일관성과 문서 최신성을 유지하기 위한 Gemini Agent의 행동 워크플로우를 정의합니다. 본 에이전트는 커밋 요청 시, 단순 실행을 넘어 프로젝트의 규칙과 명세를 기반으로 변경 사항을 검증하고, 관련 문서를 업데이트하며, 최종적으로 표준화된 커밋 메시지를 생성하는 역할을 수행합니다.

## 2. 핵심 원칙 (Core Principles)

-   **문서 중심 (Docs-Driven):** 모든 코드 변경은 `docs/`에 정의된 개념, 아키텍처, UI/UX 가이드를 준수해야 합니다. 문서는 코드의 '설계도'입니다.
-   **검증 후 실행 (Verify then Commit):** 커밋은 워크플로우의 마지막 단계입니다. 그전까지 철저한 자동 검증을 통해 잠재적인 오류와 불일치를 최소화합니다.
-   **사용자 확인 (User Confirmation):** 에이전트는 모든 분석과 검증, 커밋 메시지 생성을 완료한 후, 최종 실행 전 반드시 사용자의 승인을 받습니다. 모든 제어권은 사용자에게 있습니다.

## 3. 커밋 워크플로우 (Commit Workflow)

사용자가 `git commit` 명령어를 실행하면, 아래의 워크플로우가 순차적으로 진행됩니다.

### 단계 1: 변경 사항 분석 (`git diff`)

-   **Action:** `git diff --staged` 명령어를 실행하여 Staging Area에 있는 변경 사항의 전체 내용을 파악합니다.
-   **Purpose:** 어떤 파일이, 어떻게 변경되었는지에 대한 초기 컨텍스트를 확보합니다.

### 단계 2: 문서 기반 검증 (Documentation-Based Verification)

-   **Action:** 변경된 코드를 `docs/`의 관련 문서들과 대조하여 준수 여부를 검증합니다.
    -   **기능 변경 검증:**
        -   **Target:** `backend/` 또는 `frontend/lib/domain/` 내의 로직 변경
        -   **Reference:** `docs/concepts/*.md`
        -   **Checklist:** 변경된 기능이 해당 도메인의 원칙과 규칙을 위반하지 않는지 확인합니다.
    -   **UI/UX 변경 검증:**
        -   **Target:** `frontend/lib/presentation/` 내의 위젯 또는 페이지 변경
        -   **Reference:** `docs/ui-ux/concepts/*.md`, `docs/ui-ux/pages/*.md`
        -   **Checklist:** 디자인 시스템(색상, 폰트, 컴포넌트), 페이지 흐름, 반응형 가이드라인을 준수하는지 확인합니다.

### 단계 3: 구현 가이드 검증 및 최신화 (Implementation Guide Verification & Update)

-   **Action:** `docs/implementation/`의 문서들을 확인하고, 필요시 업데이트합니다.
    -   **Reference:** `api-reference.md`, `database-reference.md`, `backend-guide.md` 등
    -   **Checklist:**
        1.  API 엔드포인트, 데이터베이스 스키마 등의 변경 사항이 문서에 명시된 표준을 따르는지 검증합니다.
        2.  검증 후, 변경된 내용을 해당 문서에 자동으로 반영하여 최신 상태를 유지합니다.

### 단계 4: 문서 초안 자동 생성 (신규 기능 감지 시)

-   **Action:** 단계 2, 3의 검증 과정에서 새로운 API, UI 컴포넌트, 도메인 로직 등이 추가되었으나 이를 설명하는 문서가 `docs/`에 존재하지 않는 경우, 에이전트는 해당 명세를 담은 문서 파일(`.md`)의 초안을 자동으로 생성합니다.
-   **Purpose:** 개발자의 문서화 부담을 줄이고, 모든 기능이 문서화되도록 유도하여 지식 베이스의 누락을 방지합니다. 생성된 파일 경로를 사용자에게 알려주어 내용을 채우도록 안내합니다.

### 단계 5: 상태 및 로그 업데이트 (Status & Log Updates)

-   **Action:** 프로젝트의 컨텍스트 추적 및 트러블슈팅 기록을 업데이트합니다.
    -   **`context-tracking` 업데이트:**
        -   **Target:** `docs/context-tracking/pending-updates.md`, `context-update-log.md`
        -   **Purpose:** 현재 변경 사항으로 인해 다른 부분에 영향을 줄 수 있는 내용을 `pending-updates.md`에 기록하고, 완료된 작업은 `context-update-log.md`에 추가합니다.
    -   **`troubleshooting` 정리:**
        -   **Target:** `docs/troubleshooting/`
        -   **Purpose:** 이번 변경 과정에서 해결된 특정 에러나 문제가 있었다면, 원인과 해결 방법을 간결하게 정리하여 관련 문서에 추가합니다.

### 단계 6: 커밋 메시지 생성 (Commit Message Generation)

-   **Action:** `docs/conventions/commit-conventions.md`의 규칙에 따라 커밋 메시지를 자동으로 생성합니다.
-   **Process:**
    1.  지금까지 분석한 변경 사항(기능, UI, DB 등)의 내용을 종합합니다.
    2.  커밋 타입(feat, fix, docs, style, refactor 등), 스코프, 제목, 본문, 꼬리말 형식을 완벽하게 준수하여 메시지 초안을 작성합니다.

### 단계 7: 사용자 확인 및 승인 (User Confirmation & Approval)

-   **Action:** 생성된 커밋 메시지와 에이전트가 수행할 최종 `git commit` 명령어를 사용자에게 보여줍니다.
-   **Purpose:** 사용자에게 최종 검토 기회를 제공하고, 명시적인 승인("yes", "y" 등)을 받기 전까지 대기합니다. 사용자가 거부할 경우 워크플로우를 중단합니다.

### 단계 8: 커밋 실행 (Execute Commit)

-   **Action:** 사용자의 승인이 떨어지면, 준비된 `git commit` 명령어를 실행하여 커밋을 완료합니다.
-   **Feedback:** 커밋 성공 여부를 사용자에게 알리고 워크플로우를 종료합니다.
