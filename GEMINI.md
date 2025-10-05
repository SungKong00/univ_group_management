# Gemini Agent: Master Workflow

## 1. 개요 (Overview)

이 문서는 Gemini 에이전트가 `문서 업데이트` 및 `커밋` 요청을 처리하는 표준 워크플로우를 정의합니다. 에이전트는 단순 실행을 넘어, 프로젝트의 모든 규칙과 컨텍스트를 동적으로 분석하여 코드와 문서의 완전한 동기화를 달성하고, 최종적으로 표준화된 커밋을 생성하는 것을 목표로 합니다.

## 2. 핵심 원칙 (Core Principles)

-   **문서 중심 (Docs-Driven):** 모든 코드 변경은 `docs/`에 정의된 개념, 아키텍처, UI/UX 가이드를 준수해야 합니다. 문서는 코드의 '설계도'입니다.
-   **검증 후 실행 (Verify then Commit):** 모든 작업은 자동화된 검증을 거치며, 커밋은 워크플로우의 가장 마지막 단계입니다. 이를 통해 오류와 불일치를 최소화합니다.
-   **사용자 확인 (User Confirmation):** 에이전트는 분석, 계획, 최종 실행안(수정될 파일 내역, 커밋 메시지 등)을 사용자에게 제시하고, 명시적인 승인을 받은 후에만 실제 파일 시스템 변경 및 커밋을 실행합니다.

## 3. 주요 명령어 워크플로우 (Key Command Workflows)

### A. "문서 업데이트" 요청 처리 (Handling "Update Documentation" Request)

사용자가 코드 변경 후 문서 동기화를 명시적으로 요청할 때 이 워크플로우를 따릅니다.
시작 전, `docs/concepts/domain-overview.md` 를 통해 전체적인 프로젝트 개요를 파악합니다.

## A-1. 핵심 참조 문서 (Key Reference Documents)

에이전트는 다음 문서들을 항상 최신 상태로 참조하여 워크플로우를 수행합니다.

-   **마스터 워크플로우**: `GEMINI.md` (현재 파일)
-   **마크다운 가이드**: `markdown-guidelines.md`
-   **Git/커밋/PR 컨벤션**: `docs/conventions/`
-   **컨텍스트 추적 시스템**: `docs/context-tracking/`
-   **구현 가이드**: `docs/implementation/`
-   **핵심 개념**: `docs/concepts/`

#### **1단계: 변경 사항 식별 (Identify Changes)**

-   **Action:** `git diff --staged` 및 `git diff` 명령을 실행하여 최근 코드 변경사항(Staged & Unstaged)을 모두 파악합니다.
-   **Purpose:** 어떤 파일이, 어떻게 변경되었는지 분석하여 문서 업데이트의 범위를 설정합니다.

#### **2단계: 문서 영향도 분석 (Analyze Documentation Impact)**

-   **Action:**
    1.  **컨텍스트 추적 시스템 확인 (Check Context Tracking System):**
        -   **`docs/context-tracking/sync-status.md`** 와 **`docs/context-tracking/pending-updates.md`** 파일을 가장 먼저 확인합니다.
        -   `❌ 업데이트 필요`로 표시된 문서나, 이전에 누락되어 `pending-updates`에 기록된 문서가 있는지 파악하여 이번 업데이트 범위에 우선적으로 포함시킵니다.

    2.  **코드 변경 기반 분석 (Analyze Based on Code Changes):**
        -   **경로 기반 매핑**: 변경된 파일의 경로를 기준으로 관련 문서를 추론합니다.
            -   `backend/src/**/auth/**` → `docs/concepts/permission-system.md`
            -   `frontend/lib/presentation/**` → `docs/ui-ux/pages/*.md`
            -   `build.gradle` 또는 `pubspec.yaml` → `docs/implementation/*-guide.md`
        -   **키워드 기반 검색**: 변경된 코드 내용에서 'API', '권한', 'UI', '데이터베이스' 등의 키워드를 추출하여 `docs/` 전체에서 관련 문서를 추가로 검색합니다.

-   **Purpose:** 과거에 누락된 업데이트를 포함하여, 현재 코드 변경과 관련된 모든 잠재적 문서 변경 대상을 포괄적으로 식별합니다.

#### **3단계: 문서 내용 검증 및 동기화 (Verify & Synchronize Documents)**

-   **Action:** 식별된 각 문서의 내용을 코드 변경사항과 비교하여 동기화합니다.
    -   **API/DB 문서**: `api-reference.md`, `database-reference.md`의 엔드포인트, 스키마 정보 등을 최신 코드로 업데이트합니다.
    -   **개념 문서**: `docs/concepts/*.md`의 내용이 변경된 비즈니스 로직과 일치하는지 확인하고 수정합니다.
    -   **UI/UX 문서**: `docs/ui-ux/**/*.md`의 페이지 명세나 컴포넌트 가이드가 실제 구현과 일치하도록 업데이트합니다.
-   **Purpose:** 모든 문서가 코드의 현재 상태를 정확히 반영하도록 보장합니다.

#### **4단계: 신규 문서 초안 생성 (Draft New Documents)**

-   **Action:** 검증 과정에서 새로운 기능(API, UI 컴포넌트, 도메인 로직 등)이 추가되었으나 이를 설명하는 문서가 없다면, `markdown-guidelines.md`의 템플릿에 따라 해당 명세를 담은 새 `.md` 파일의 초안을 자동으로 생성합니다.
-   **Purpose:** 모든 기능이 문서화되도록 유도하여 지식 베이스의 누락을 방지합니다.

#### **5단계: 컨텍스트 추적 시스템 업데이트 (Update Context Tracking System)**

-   **Action:** 문서 동기화 작업의 결과를 `docs/context-tracking/` 디렉토리의 파일들에 기록합니다.
    -   `context-update-log.md`: 어떤 커밋(예정)에서 어떤 문서가 왜 업데이트되었는지 로그를 추가합니다.
    -   `sync-status.md`: 업데이트된 문서의 상태를 `✅ 최신`으로 변경하고, 동기화율을 재계산합니다.
    -   `pending-updates.md`: 이번 작업으로 인해 새로 업데이트가 필요해진 문서가 있다면 목록에 추가합니다.
-   **Purpose:** 프로젝트의 문서 상태를 항상 최신으로 유지하고 추적 가능하게 합니다.

#### **6단계: 최종 계획 보고 및 사용자 승인 (Report and Confirm)**

-   **Action:** 아래 내용을 포함한 최종 계획을 사용자에게 보고합니다.
    -   수정/생성될 문서 목록
    -   각 문서의 주요 변경 내용 요약
-   **Purpose:** 사용자에게 변경 내용을 명확히 알리고, 실행에 대한 최종 동의를 구합니다. 승인 시에만 실제 파일 변경을 진행합니다.

### B. "커밋" 요청 처리 (Handling "Commit" Request)

사용자가 "커밋해줘"라고 요청할 때, 위의 **"문서 업데이트" 워크플로우(A)를 먼저 수행**한 후, 아래 단계를 순차적으로 진행합니다.

#### **7단계: 최종 검증 (Final Verification)**

-   **Action:** 문서 동기화가 완료된 후, 프로젝트의 빌드, 테스트, 린트(Linter)를 실행하여 모든 것이 정상적인지 최종 확인합니다.
-   **Purpose:** 기술적 오류가 없는 안정적인 상태에서만 커밋을 진행하기 위함입니다.

#### **8단계: 커밋 메시지 생성 (Generate Commit Message)**

-   **Action:** `docs/conventions/commit-conventions.md` 규칙에 따라 커밋 메시지를 자동으로 생성합니다.
    -   **Process**:
        1.  1단계에서 분석한 코드 변경사항과 3단계에서 수정한 문서 내역을 종합합니다.
        2.  변경 내용에 가장 적합한 커밋 타입(`feat`, `fix`, `docs` 등)과 스코프를 결정합니다.
        3.  표준 형식에 맞춰 제목, 본문, 푸터가 포함된 완벽한 메시지 초안을 작성합니다.
-   **Purpose:** 일관되고 명확한 커밋 히스토리를 유지합니다.

#### **9단계: 최종 보고 및 사용자 승인 (Final Report and Approval)**

-   **Action:** 아래 내용을 포함한 최종 실행 계획을 사용자에게 보고합니다.
    -   수정/생성된 모든 파일 목록 (`git status` 결과)
    -   생성된 커밋 메시지 초안
-   **Purpose:** 사용자에게 최종 검토 기회를 제공하고, 명시적인 승인("yes", "y" 등)을 받기 전까지 대기합니다.

#### **10단계: 커밋 실행 (Execute Commit)**

-   **Action:** 사용자의 승인이 완료되면, 준비된 `git add .` 및 `git commit` 명령어를 실행하여 커밋을 완료합니다.
-   **Feedback:** 커밋 성공 여부와 커밋 해시(hash)를 사용자에게 알리고 워크플로우를 종료합니다.

