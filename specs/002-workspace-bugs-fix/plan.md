# Implementation Plan: Workspace Navigation and Scroll Bugs Fix

**Branch**: `002-workspace-bugs-fix` | **Date**: 2025-11-10 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-workspace-bugs-fix/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

This feature fixes two critical workspace bugs: (1) Desktop first-access incorrectly shows channel view instead of group home, and (2) Unread post divider and auto-scroll positioning behave inconsistently. The technical approach involves fixing navigation logic to respect session-scoped snapshots, enforcing post ID-based ordering for unread detection, implementing instant scroll positioning (0ms duration), and updating badge counts only on channel exit.

## Technical Context

**Language/Version**: Dart 3.x (Flutter SDK 3.x)
**Primary Dependencies**: Riverpod (state management), go_router (navigation), scroll_to_index (scroll control), visibility_detector (scroll tracking)
**Storage**: In-memory session state (Navigator 2.0), API-persisted read positions
**Testing**: dart-flutter MCP (run_tests, analyze_files), Widget tests, Integration tests
**Target Platform**: Flutter Web (chrome, desktop viewports + mobile responsive)
**Project Type**: Web application (Flutter frontend + Spring Boot backend)
**Performance Goals**: <500ms auto-positioning, 95%+ correct divider placement, 100% correct first-access navigation
**Constraints**: Session-scoped state (reset on login), instant positioning (no visible animation), post ID ordering (not timestamp)
**Scale/Scope**: Affects workspace navigation (2 views: desktop/mobile), channel entry behavior, read position tracking across all channels

## API Modifications

### Existing APIs Analysis

**APIs to Reuse**:
- `GET /api/read-positions/{channelId}`: Suitable for retrieving last read post ID per channel
- `POST /api/read-positions`: Suitable for saving read position on channel exit
- `GET /api/channels/{channelId}/posts`: Suitable for loading posts (already returns post IDs)

**APIs Requiring Modification**:

| Endpoint | Current Behavior | Required Changes | Breaking Change? | Impact Scope |
|----------|------------------|------------------|------------------|--------------|
| N/A | N/A | No backend API changes required | No | Frontend-only bug fixes |

**New APIs to Create**:
- N/A: All required backend functionality already exists

### Migration Strategy

**For Breaking Changes**:
- N/A: This is a frontend bug fix with no breaking changes

**Testing Plan**:
- [X] No API modifications required
- [X] Frontend integration tests will verify read position save/load behavior
- [X] Widget tests will validate navigation state transitions
- [X] No API documentation updates needed

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Principle I: 3-Layer Architecture ✅ PASS (Frontend)
- **Gate**: Frontend follows presentation/provider/service separation
- **Status**: PASS - Bug fixes confined to presentation layer (workspace_page.dart, workspace_state_provider.dart, post_list.dart)
- **Evidence**: No new service layer needed; existing API calls remain unchanged

### Principle II: Standard Response Format ✅ N/A
- **Gate**: API responses use ApiResponse<T>
- **Status**: N/A - No API changes

### Principle III: RBAC + Override ✅ N/A
- **Gate**: Permission checks present
- **Status**: N/A - Bug fixes do not affect permission logic

### Principle IV: Documentation 100-Line Rule ✅ PASS
- **Gate**: Context docs ≤100 lines (spec/plan/tasks exempt)
- **Status**: PASS - This is a speckit document (exempt), existing docs will be updated only if behavior changes significantly

### Principle V: Test Pyramid 60/30/10 ✅ PASS
- **Gate**: Integration (60%), Unit (30%), E2E (10%)
- **Status**: PASS - Will add widget tests for navigation scenarios, integration tests for scroll positioning

### Principle VI: MCP Usage Standard ✅ PASS
- **Gate**: Use dart-flutter MCP for testing/debugging
- **Status**: PASS - Will use dart-flutter run_tests and analyze_files for validation

### Principle VII: Frontend Integration ✅ PASS
- **Gate**: Riverpod providers, design tokens
- **Status**: PASS - Using existing WorkspaceStateNotifier (Riverpod), no new design tokens needed

### Principle VIII: API Evolution ✅ PASS
- **Gate**: Reuse existing APIs, document modifications
- **Status**: PASS - All existing APIs reused, no modifications needed

**Overall Constitution Check**: ✅ **PASS** - All applicable principles satisfied

## Project Structure

### Documentation (this feature)

```text
specs/002-workspace-bugs-fix/
├── spec.md              # Feature specification (completed)
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (to be created)
├── data-model.md        # Phase 1 output (to be created)
├── quickstart.md        # Phase 1 output (to be created)
├── contracts/           # Phase 1 output (N/A - no new APIs)
├── checklists/
│   └── requirements.md  # Spec quality checklist (completed)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
frontend/lib/
├── presentation/
│   ├── pages/workspace/
│   │   ├── workspace_page.dart                     # [MODIFY] Fix first-access navigation logic
│   │   ├── mixins/
│   │   │   └── workspace_back_navigation_mixin.dart # [REVIEW] Back navigation to global home
│   │   └── widgets/
│   │       ├── mobile_workspace_view.dart          # [REVIEW] Mobile channel list display
│   │       └── desktop_main_content.dart           # [REVIEW] Desktop group home display
│   ├── providers/
│   │   └── workspace_state_provider.dart           # [MODIFY] Session snapshot clearing, first-time logic
│   └── widgets/
│       └── post/
│           ├── post_list.dart                      # [MODIFY] Instant scroll positioning, post ID ordering
│           └── unread_message_divider.dart         # [MODIFY] Divider position based on post ID
├── core/
│   └── utils/
│       └── read_position_helper.dart               # [MODIFY] Post ID-based unread detection
└── test/
    ├── presentation/
    │   └── workspace/
    │       ├── workspace_navigation_test.dart      # [NEW] Desktop/mobile first-access tests
    │       └── workspace_scroll_test.dart          # [NEW] Instant positioning, divider tests
    └── widgets/
        └── post_list_test.dart                     # [EXTEND] Post ID ordering tests
```

**Structure Decision**: Frontend-only bug fix within existing Flutter Web application structure. Primary changes in presentation layer (workspace navigation, post list scroll), with supporting changes in providers and utilities. No backend modifications required.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

N/A - No constitution violations. This is a straightforward bug fix within existing architecture.

---

## Phase 0: Research - ✅ COMPLETE

**Output**: [research.md](./research.md)

**Key Decisions**:
- Session-scoped snapshots with global home clearing
- Post ID authoritative ordering (not timestamp)
- Instant scroll positioning (Duration.zero)
- Badge updates on channel exit only
- Back navigation stack exhaustion detection

**Status**: All technical questions resolved. No unknowns remaining.

---

## Phase 1: Design & Contracts - ✅ COMPLETE

**Outputs**:
- [data-model.md](./data-model.md) - State transitions, lifecycle rules
- [contracts/README.md](./contracts/README.md) - No new APIs (reuse existing)
- [quickstart.md](./quickstart.md) - Development guide

**Key Artifacts**:
- Workspace entry flow diagram (first-time vs cached)
- Channel entry flow diagram (scroll positioning logic)
- Badge update flow diagram (exit-only timing)

**Agent Context**: Updated CLAUDE.md with bug fix technologies (Navigator 2.0, scroll_to_index)

**Re-evaluated Constitution Check**: ✅ **PASS** (no changes from initial assessment)

---

## Phase 2: Task Breakdown - ⏭️ NEXT

**Command**: `/speckit.tasks`

**Expected Output**: Dependency-ordered tasks in `tasks.md` with:
- Navigation fix tasks (session snapshots, first-time detection)
- Scroll positioning tasks (post ID ordering, instant scroll)
- Badge timing tasks (channel exit updates)
- Test tasks (widget tests, integration tests)

**Prerequisites**: Research and design complete (✅), spec clarifications resolved (✅)
