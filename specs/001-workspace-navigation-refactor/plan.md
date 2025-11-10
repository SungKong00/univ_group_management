# Implementation Plan: Workspace Navigation Refactoring

**Branch**: `001-workspace-navigation-refactor` | **Date**: 2025-11-09 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-workspace-navigation-refactor/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Refactor workspace navigation system to follow Flutter's declarative navigation patterns (Navigator 2.0) with custom RouterDelegate. The current implementation uses imperative navigation that doesn't properly maintain history state, causing inconsistent back navigation and difficulty managing complex context-aware group switching. The new system will provide deterministic navigation history, context-aware group transitions, and unified browser/in-app back button behavior while improving code maintainability by 40%.

**Key Changes**:
- Replace imperative Navigator 1.0 push/pop with declarative Navigator 2.0 + RouterDelegate
- Implement navigation state management using Riverpod providers
- Add permission-aware view resolution with graceful fallbacks
- Handle edge cases: resource deletion, permission revocation, session interruption
- Maintain mobile-responsive navigation with identical behavior across platforms

## Technical Context

**Language/Version**: Dart 3.x (Flutter SDK 3.x)
**Primary Dependencies**:
- Flutter Navigator 2.0 (built-in)
- Riverpod 2.x (state management)
- go_router or custom RouterDelegate (to be researched in Phase 0)
**Storage**: In-memory navigation state (session-scoped), no persistence
**Testing**: Flutter widget tests, integration tests, MCP-based validation (flutter_analyze)
**Target Platform**: Web (Chrome, Safari, Edge), responsive mobile breakpoints
**Project Type**: Flutter Web application (frontend only, no backend changes required)
**Performance Goals**:
- Navigation response time < 200ms (SC-003)
- History stack unlimited depth without performance degradation
- Zero memory leaks from navigation state retention
**Constraints**:
- Must integrate with existing permission system (`GroupPermissionEvaluator`)
- Must work with current Riverpod provider architecture
- Must maintain compatibility with existing workspace UI components
- Session interruption (refresh) resets to workspace entry point
**Scale/Scope**:
- ~8-12 navigation routes (workspace views: home, channels, calendar, admin, member management)
- ~3-5 new state models (NavigationState, ViewContext, PermissionContext)
- ~2-3 core files to refactor (workspace_page.dart, navigation logic)

## API Modifications

**Note**: This is a frontend-only refactoring. No backend API modifications required.

### Existing APIs Analysis

**APIs to Reuse** (No changes):
- `GET /api/groups/:id` - Group details (already used for workspace initialization)
- `GET /api/groups/:id/channels` - Channel list (already used for channel selection)
- `GET /api/groups/:id/members/me/permissions` - User permissions (already used for permission checks)
- `GET /api/groups/:id/members` - Member list (already used for admin pages)

**APIs Requiring Modification**: None

**New APIs to Create**: None

### Migration Strategy

**Frontend Refactoring Only**:
- No API versioning or breaking changes
- All existing API contracts remain unchanged
- Frontend components will be updated to use new navigation system
- Rollback: revert frontend code to previous navigation implementation

**Testing Plan**:
- [x] No backend API tests to update (frontend-only)
- [ ] Add widget tests for new Navigator 2.0 components
- [ ] Add integration tests for navigation flows
- [ ] Update MCP validation with flutter_analyze
- [ ] Manual testing: browser back button, mobile navigation, group switching

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Principle I: 3-Layer Architecture ✅ NOT APPLICABLE
**Status**: PASS - Frontend-only refactoring, no backend layers affected

### Principle II: Standard Response Format (ApiResponse<T>) ✅ NOT APPLICABLE
**Status**: PASS - No API changes, existing ApiResponse parsing unchanged

### Principle III: RBAC + Override Permission System ✅ COMPLIANT
**Status**: PASS - Navigation system will integrate with existing `@PreAuthorize` checks via frontend permission context
**Implementation**: NavigationState will query user permissions before route transitions, respecting existing permission matrix

### Principle IV: Documentation 100-Line Principle ⚠️ ATTENTION REQUIRED
**Status**: REQUIRES MONITORING - This plan and generated artifacts must adhere to 100-line limit
**Action**: Split documentation into multiple files if exceeding limit during Phase 1

### Principle V: Test Pyramid 60/30/10 ✅ COMPLIANT
**Status**: PASS - Will follow Flutter testing best practices:
- 60%: Widget integration tests (Navigator + state providers)
- 30%: Unit tests (navigation logic, state transformations)
- 10%: E2E tests (manual testing via MCP hot reload)

### Principle VI: Flutter MCP Standard ✅ COMPLIANT
**Status**: PASS - All Flutter development will use flutter-mcp-service
**Action**: Use `mcp__dart-flutter__*` tools for analysis, hot reload, testing

### Principle VII: Frontend Integration Principles ✅ COMPLIANT
**Status**: PASS - Will follow established patterns:
- Design tokens: Use existing AppColors, AppSpacing (no new tokens needed)
- State management: Riverpod Unified Provider pattern
- API integration: No changes to existing ApiResponse handling
- Reusable components: Register NavigationStateProvider in docs if reusable

### Principle VIII: API Evolution & Refactoring ✅ COMPLIANT
**Status**: PASS - No API modifications required (frontend-only refactoring)
**Rationale**: Existing backend APIs fully support navigation requirements

### Security & Performance Standards ✅ COMPLIANT
**Status**: PASS
- Security: Permission checks performed before every route transition
- Performance: Navigator 2.0 provides better performance than Navigator 1.0 for complex routing

### Development Workflow ✅ COMPLIANT
**Status**: PASS - Will follow GitHub Flow, Conventional Commits, and context tracking requirements

**GATE RESULT**: ✅ PASS - All constitution principles satisfied or not applicable

## Project Structure

### Documentation (this feature)

```text
specs/001-workspace-navigation-refactor/
├── plan.md              # This file (Phase 0 complete)
├── research.md          # Phase 0: Navigator 2.0 patterns, go_router vs custom
├── data-model.md        # Phase 1: NavigationState, ViewContext models
├── quickstart.md        # Phase 1: Developer guide for new navigation system
└── tasks.md             # Phase 2: Generated by /speckit.tasks (not created yet)
```

### Source Code (repository root)

```text
frontend/
├── lib/
│   ├── core/
│   │   ├── navigation/                    # NEW: Navigation 2.0 infrastructure
│   │   │   ├── router_delegate.dart       # Custom RouterDelegate implementation
│   │   │   ├── route_information_parser.dart  # URL parsing (if using URLs)
│   │   │   ├── navigation_state.dart      # Navigation state model
│   │   │   ├── view_context.dart          # View context model
│   │   │   └── workspace_route.dart       # Route configuration
│   │   └── permissions/
│   │       └── permission_context.dart    # Existing permission integration
│   ├── presentation/
│   │   ├── pages/
│   │   │   └── workspace/
│   │   │       └── workspace_page.dart    # REFACTOR: Use Navigator 2.0
│   │   ├── providers/                     # NEW: Navigation state providers
│   │   │   ├── navigation_state_provider.dart
│   │   │   └── view_context_provider.dart
│   └── domain/
│       └── models/
│           └── workspace_view_type.dart   # Enum: home, channel, calendar, admin
└── test/
    ├── core/
    │   └── navigation/                    # NEW: Navigation tests
    │       ├── router_delegate_test.dart
    │       └── navigation_state_test.dart
    └── presentation/
        └── pages/
            └── workspace/
                └── workspace_page_test.dart  # REFACTOR: Update tests
```

**Structure Decision**: Flutter Web application following existing frontend architecture. New navigation infrastructure added under `core/navigation/` with state management via Riverpod providers. No backend changes required.

## Complexity Tracking

> **No constitution violations requiring justification**

**Rationale**: This refactoring follows all established patterns and improves maintainability without adding architectural complexity. The move from Navigator 1.0 to Navigator 2.0 is a standard Flutter best practice that reduces complexity rather than increasing it.
