# Development Process and Conventions

**⚠️ 현재 상태**: 자동화된 AI Agent 협업 워크플로우가 완전히 가동되는 상태입니다. Claude는 사용자 지시에 따라 자동으로 Gemini CLI 명령을 실행합니다.

This document summarizes the AI agent-based development workflow, roles, and conventions for this project. It is synthesized from `ai-agent-workflow.md`, `gemini-integration.md`, and `tasks-conventions.md`.

## 1. Core Principles

- **Task-Centric**: All development work is managed within isolated task packages located at `tasks/<date>-<slug>/`.
- **Single Source of Truth**: `TASK.MD` within each package is the central hub for all instructions, logs, and decisions related to a task.
- **Knowledge Separation**:
    - **Static Knowledge**: Long-term knowledge like architecture, standards, and conventions are stored in the `context/` directory.
    - **Dynamic Context**: Task-specific, synthesized context is generated into `SYNTHESIZED_CONTEXT.MD` for one-time use.
- **AI Agent Collaboration**: The workflow relies on a team of specialized AI agents orchestrated by the developer.

## 2. AI Agent Roles

- **Developer**: Oversees the entire process, defines tasks, provides instructions, and gives final approval.
- **Gemini CLI (Orchestrator)**: Manages the task lifecycle and synthesizes context. Its primary role is to create `SYNTHESIZED_CONTEXT.MD` based on `TASK.MD` and the `context/` knowledge base.
- **Claude Code (Implementer)**: Executes development and refactoring tasks as instructed in `TASK.MD`.
- **Codex (Debugger)**: Analyzes errors and suggests solutions when Claude is blocked.

## 3. Development Workflow Lifecycle

The development process follows a four-step lifecycle managed by the `gemini` helper script.

### Step 1: Task Creation
- **Command**: `gemini task new "<descriptive-task-title>"`
- **Action**: Creates a new directory `tasks/<date>-<slug>/` and initializes it with a `TASK.MD` file from the template.

### Step 2: Context Synthesis
- **Command**: `gemini task run-context` (executed within the task directory)
- **Action**: Gemini CLI analyzes the `TASK.MD`, gathers relevant static knowledge from `context/` (guided by `.gemini/metadata.json`), and generates a tailored `SYNTHESIZED_CONTEXT.MD` file for the current task.

### Step 3: Development Cycle
1.  The **Developer** provides specific instructions to Claude Code in the "개발 지시" (Development Instruction) section of `TASK.MD`.
2.  **Claude Code** executes the instructions, logging all activities, progress, and issues in the "작업 로그" (Work Log).
3.  If errors occur, **Codex** is invoked to analyze the problem and provide a solution, which is also logged.

### Step 4: Task Completion & Knowledge Assetization
1.  Once the goal is achieved, the **Developer** fills out the "변경 사항 요약" (Summary of Changes) and "컨텍스트 업데이트 요청" (Context Update Request) sections in `TASK.MD`.
2.  **Command**: `gemini task complete`
3.  **Action**: The task package is moved to `tasks/archive/`, and a record is appended to `context/CHANGELOG.md`. Any requested updates to the static knowledge base (`context/` files) are then performed based on the "컨텍스트 업데이트 요청".

## 4. Key Artifact: TASK.MD Structure

The `TASK.MD` file is the operational center of every task and contains the following sections:
- **작업 목표 (Task Goal)**: A clear, measurable objective.
- **컨텍스트 요청 (Context Request)**: Specifies the required static and dynamic context.
- **개발 지시 (Development Instruction)**: Concrete instructions for Claude Code.
- **작업 로그 (Work Log)**: A complete record of all actions, results, and errors.
- **변경 사항 요약 (Summary of Changes)**: A detailed summary of code modifications upon completion.
- **컨텍스트 업데이트 요청 (Context Update Request)**: Specifies what new knowledge should be integrated into the `context/` base.
- **최종 검토 (Final Review)**: Developer's final approval and feedback.
