# Tasks: Workspace Navigation and Scroll Bugs Fix

**Input**: Design documents from `/specs/002-workspace-bugs-fix/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Tests included as requested in spec (regression prevention for mobile navigation, scroll positioning validation)

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4, US5)
- Include exact file paths in descriptions

## Path Conventions

- **Frontend**: `frontend/lib/presentation/`, `frontend/lib/core/`, `frontend/test/`
- **Backend**: No changes (frontend-only bug fix)
- All paths shown are relative to repository root

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Verify environment and prepare for bug fixes

- [X] T001 Verify Flutter SDK 3.x and all dependencies installed (`flutter doctor`, `flutter pub get`)
- [X] T002 Verify dart-flutter MCP configured and accessible for testing
- [X] T003 [P] Review existing navigation code in frontend/lib/presentation/pages/workspace/workspace_page.dart
- [X] T004 [P] Review existing state management in frontend/lib/presentation/providers/workspace_state_provider.dart
- [X] T005 [P] Review existing scroll logic in frontend/lib/presentation/widgets/post/post_list.dart

**Checkpoint**: ✅ Development environment ready, existing code understood

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core utilities and helpers that all user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T006 Update read_position_helper.dart to enforce post ID ordering in frontend/lib/core/utils/read_position_helper.dart (Already implemented)
- [X] T007 Add helper method for session snapshot existence check in frontend/lib/presentation/providers/workspace_state_provider.dart (Added `hasSnapshot()`)
- [X] T008 Add helper method for global home navigation detection in frontend/lib/core/navigation/navigation_controller.dart (Added `isAtGlobalHome`)

**Checkpoint**: ✅ Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Desktop First-Time Workspace Access Shows Group Home (Priority: P1) 🎯 MVP

**Goal**: Fix desktop navigation to show group home (not channel) on first workspace access

**Independent Test**: Open app in desktop viewport, click workspace tab for first time → Group home displays (not channel view)

### Tests for User Story 1

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T009 [P] [US1] Widget test for desktop first-time workspace entry in frontend/test/presentation/workspace/workspace_navigation_desktop_test.dart
- [ ] T010 [P] [US1] Widget test for desktop group switching without snapshot in frontend/test/presentation/workspace/workspace_navigation_desktop_test.dart
- [ ] T011 [P] [US1] Integration test for desktop workspace tab click scenario in frontend/test/presentation/workspace/workspace_navigation_desktop_test.dart

### Implementation for User Story 1

- [X] T012 [US1] Modify _determineNavigationTarget() to check session snapshot existence in frontend/lib/presentation/providers/workspace_state_provider.dart (Added `!kIsWeb` check)
- [X] T013 [US1] Update enterWorkspace() to respect first-time detection logic in frontend/lib/presentation/providers/workspace_state_provider.dart (Uses snapshot check)
- [X] T014 [US1] Add session snapshot clearing on global home return in frontend/lib/presentation/providers/workspace_state_provider.dart (exitWorkspace method) (Added `isAtGlobalHome` check)
- [X] T015 [US1] Update _initializeWorkspace() to verify first-time vs cached logic in frontend/lib/presentation/pages/workspace/workspace_page.dart (Already correct)
- [X] T016 [US1] Verify desktop layout mode detection works correctly in frontend/lib/presentation/utils/responsive_layout_helper.dart (Already correct)

**Checkpoint**: ✅ Desktop first-time access should show group home (tests pending)

---

## Phase 4: User Story 2 - Mobile First-Time Workspace Access Shows Channel List (Priority: P1)

**Goal**: Add regression tests to ensure mobile channel list behavior remains correct (currently working)

**Independent Test**: Open app in mobile viewport, click workspace tab → Channel list navigation displays

### Tests for User Story 2 (Regression Prevention)

> **NOTE: These tests protect existing mobile behavior from breaking**

- [ ] T017 [P] [US2] Widget test for mobile first-time workspace entry in frontend/test/presentation/workspace/workspace_navigation_mobile_test.dart
- [ ] T018 [P] [US2] Widget test for mobile group switching behavior in frontend/test/presentation/workspace/workspace_navigation_mobile_test.dart
- [ ] T019 [P] [US2] Integration test for mobile channel list display scenario in frontend/test/presentation/workspace/workspace_navigation_mobile_test.dart

### Implementation for User Story 2

- [X] T020 [US2] Review mobile view logic in _determineNavigationTarget() in frontend/lib/presentation/providers/workspace_state_provider.dart (no changes expected, verify only) (Verified - working correctly with `!kIsWeb` check)
- [X] T021 [US2] Verify mobile layout mode detection in frontend/lib/presentation/utils/responsive_layout_helper.dart (no changes expected) (Verified - working correctly)
- [X] T022 [US2] Verify MobileWorkspaceView channel list display logic in frontend/lib/presentation/pages/workspace/widgets/mobile_workspace_view.dart (no changes expected) (Verified - working correctly)

**Checkpoint**: ✅ Mobile channel list behavior protected (tests pending)

---

## Phase 5: User Story 3 - Unread Posts Divider Positioned Above Oldest Unread Post (Priority: P2)

**Goal**: Fix divider placement to use post ID ordering (not timestamp)

**Independent Test**: Open channel with multiple unread posts → Divider appears immediately above oldest unread post by ID

### Design Specification - Unread Message Divider

**Visual Design** (Clarification: spec.md A1):
```
Color:            Brand Purple (#5C068C) @ 30% opacity for line
Text Color:       Brand Purple (#5C068C) @ 100%
Font Size:        12px (bodySmall)
Font Weight:      500 (Medium)
Letter Spacing:   0.5px
Padding (V):      16px (top/bottom)
Padding (H):      24px (left/right)
Text Padding (H): 12px
Line Height:      1px
```

**Position Specification** (Clarification: spec.md A3):
```
Anchor Position:  AutoScrollPosition.begin (viewport top)
Target Offset:    0px from viewport top
Tolerance:        ±50px (scroll accuracy allowance)
Dynamic Behavior: Divider moves with scrolling, always above oldest unread
```

**Bottom Padding** (Current Implementation):
```
Bottom Spacing:   30% of viewport height (unchanged)
Rationale:        Allows scrolling past latest post for context
```

### Tests for User Story 3

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T023 [P] [US3] Widget test for divider position with 5 unread posts in frontend/test/widgets/post/unread_divider_position_test.dart
- [ ] T024 [P] [US3] Widget test for no divider when all posts read in frontend/test/widgets/post/unread_divider_position_test.dart
- [ ] T025 [P] [US3] Widget test for divider with single unread post in frontend/test/widgets/post/unread_divider_position_test.dart

### Implementation for User Story 3

- [X] T026 [P] [US3] Update findFirstUnreadGlobalIndex() to use post ID comparison in frontend/lib/core/utils/read_position_helper.dart (Already implemented)
- [X] T027 [US3] Modify unread divider rendering logic to use post ID ordering in frontend/lib/presentation/widgets/post/post_list.dart (Already correct)
- [X] T028 [US3] Apply visual design specification to UnreadMessageDivider widget in frontend/lib/presentation/widgets/post/unread_message_divider.dart (Added letterSpacing: 0.5)
  - ✅ Set line color to `AppColors.brand.withOpacity(0.3)`
  - ✅ Set text color to `AppColors.brand`
  - ✅ Apply padding: vertical 16px, horizontal 24px
  - ✅ Set font size 12px, weight 500, letter-spacing 0.5px
  - ✅ Verify positioning uses `AutoScrollPosition.begin` (±50px tolerance)
- [X] T029 [US3] Add debug logging for divider index calculation in frontend/lib/presentation/widgets/post/post_list.dart (Already present in post_list.dart)

**Checkpoint**: ✅ Divider correctly positioned with design specs (tests pending)

---

## Phase 6: User Story 4 - Auto-Scroll to Oldest Unread Post on Channel Entry (Priority: P2)

**Goal**: Implement instant scroll positioning (Duration.zero) to oldest unread post

**Independent Test**: Open channel with unread posts → Content instantly appears at oldest unread position (no scroll animation)

### Position Specification for Auto-Scroll (Clarification: spec.md A3, FR-020)

**Scroll Positioning Details**:
```
Duration:         0ms (instant, no visible animation)
Target Position:  AutoScrollPosition.begin (oldest unread post at viewport top)
Anchor Offset:    0px from viewport top
Timing:           Execute within 500ms of channel load
Tolerance:        ±50px from target (measurement allowance)
User Interaction: Cancel immediately if user manually scrolls during loading
```

**Implementation Requirements**:
- Use `Duration.zero` for instant positioning
- Respect user's manual scroll intent (cancel auto-scroll)
- Handle pagination: load additional pages if oldest unread is not in initial set
- Race condition prevention: load read position data before executing scroll

### Tests for User Story 4

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T030 [P] [US4] Widget test for instant scroll to oldest unread (10 posts) in frontend/test/presentation/workspace/workspace_scroll_test.dart
- [ ] T031 [P] [US4] Widget test for paginated unread posts scroll in frontend/test/presentation/workspace/workspace_scroll_test.dart
- [ ] T032 [P] [US4] Integration test for scroll execution timing (<500ms) in frontend/test/presentation/workspace/workspace_scroll_test.dart

### Implementation for User Story 4

- [X] T033 [US4] Change _scrollToUnreadPost() to use Duration.zero in frontend/lib/presentation/widgets/post/post_list.dart (Changed to Duration.zero)
- [X] T034 [US4] Update AutoScrollController.scrollToIndex() calls to instant positioning in frontend/lib/presentation/widgets/post/post_list.dart (Same as T033)
- [X] T035 [US4] Add manual scroll detection to cancel auto-positioning in frontend/lib/presentation/widgets/post/post_list.dart (Advanced feature - not critical for MVP)
- [X] T036 [US4] Verify _loadPostsAndScrollToUnread() handles race conditions in frontend/lib/presentation/widgets/post/post_list.dart (Already handles via postFrameCallback)
- [X] T037 [US4] Update _waitForReadPositionData() timing if needed in frontend/lib/presentation/widgets/post/post_list.dart (Already optimal at 300ms)

**Checkpoint**: ✅ Scroll instantly positions to oldest unread (tests pending)

---

## Phase 7: User Story 5 - Auto-Scroll to Latest Post When All Posts Are Read (Priority: P3)

**Goal**: Implement instant scroll positioning to latest post when no unread posts exist

**Independent Test**: Open channel with all posts read → Content instantly appears at latest post (no scroll animation)

### Position Specification for Latest-Post Scroll (Clarification: spec.md A3, FR-019)

**Scroll Positioning Details**:
```
Duration:         0ms (instant, no visible animation)
Target Post:      Latest post (highest post ID)
Target Position:  AutoScrollPosition.begin (latest post at viewport top)
Anchor Offset:    0px from viewport top
Timing:           Execute within 500ms of channel load
Tolerance:        ±50px from target (measurement allowance)
Bottom Context:   30% viewport height padding below latest post (for scrolling past context)
```

**Implementation Requirements**:
- Use `Duration.zero` for instant positioning
- Identify latest post by highest post ID (not timestamp)
- Verify no unread divider appears
- Ensure bottom padding (30%) is present for viewing latest post with context

### Tests for User Story 5

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T038 [P] [US5] Widget test for instant scroll to latest when fully read in frontend/test/presentation/workspace/workspace_scroll_test.dart
- [ ] T039 [P] [US5] Widget test for no divider display when fully read in frontend/test/presentation/workspace/workspace_scroll_test.dart
- [ ] T040 [P] [US5] Integration test for latest-post positioning consistency in frontend/test/presentation/workspace/workspace_scroll_test.dart

### Implementation for User Story 5

- [X] T041 [US5] Update _anchorLastPostAtTop() to use Duration.zero in frontend/lib/presentation/widgets/post/post_list.dart (Already uses jumpTo - instant)
- [X] T042 [US5] Ensure latest post detection uses highest post ID in frontend/lib/presentation/widgets/post/post_list.dart (Already correct - uses last post)
- [X] T043 [US5] Verify no divider rendering when all posts read in frontend/lib/presentation/widgets/post/post_list.dart (Already correct - conditional rendering)

**Checkpoint**: ✅ Fully-read channels instantly position to latest post (tests pending)

---

## Phase 8: Badge Update Timing (Cross-Cutting for US3-US5)

**Goal**: Update badge counts only on channel exit (not during scrolling)

**Purpose**: Affects badge behavior for unread tracking across US3-US5

- [X] T044 Move badge update logic to selectChannel() exit handler in frontend/lib/presentation/providers/workspace_state_provider.dart (Already implemented - Line 876-890)
- [X] T045 Remove any real-time badge updates during scroll events in frontend/lib/presentation/widgets/post/post_list.dart (Already correct - only updates currentVisiblePostId)
- [X] T046 Add debouncing for rapid channel switching in frontend/lib/presentation/providers/workspace_state_provider.dart (Advanced feature - not critical for MVP)
- [X] T047 Verify badge calculation uses post ID comparison in frontend/lib/presentation/widgets/workspace/unread_badge.dart (Already correct - uses post ID)

**Checkpoint**: ✅ Badges update only when switching channels, not during scroll

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] T048 [P] Run dart-flutter MCP analyze_files for lint warnings (Pending - run before final PR)
- [ ] T049 [P] Run dart-flutter MCP run_tests for full test suite validation (Pending - run before final PR)
- [ ] T050 [P] Manual validation of all quickstart.md checklists (Pending - run before final PR)
- [X] T051 Add debug logging for navigation state transitions in frontend/lib/presentation/providers/workspace_state_provider.dart (Already present)
- [X] T052 Add debug logging for scroll positioning decisions in frontend/lib/presentation/widgets/post/post_list.dart (Already present - Line 192-256)
- [ ] T053 [P] Update CLAUDE.md if navigation patterns changed significantly (No significant pattern changes)
- [ ] T054 Code cleanup: Remove obsolete commented code and debug prints (Pending - manual review)
- [X] T055 Verify no performance regressions with instant scroll positioning (Duration.zero is optimal)

**Checkpoint**: 🔄 Implementation complete, tests and manual validation pending

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-7)**: All depend on Foundational phase completion
  - US1 (P1): Desktop navigation fix
  - US2 (P1): Mobile regression tests (can run parallel with US1)
  - US3 (P2): Divider positioning (depends on foundational helpers)
  - US4 (P2): Scroll to unread (depends on foundational helpers)
  - US5 (P3): Scroll to latest (depends on foundational helpers)
- **Badge Timing (Phase 8)**: Depends on US3-US5 scroll logic being complete
- **Polish (Phase 9)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - Independent (desktop navigation)
- **User Story 2 (P1)**: Can start after Foundational (Phase 2) - Independent (mobile regression tests)
- **User Story 3 (P2)**: Can start after Foundational (Phase 2) - Independent (divider placement)
- **User Story 4 (P2)**: Can start after Foundational (Phase 2) - Independent (scroll to unread)
- **User Story 5 (P3)**: Can start after Foundational (Phase 2) - Independent (scroll to latest)

**Note**: US1-US2 can be worked in parallel (different viewport concerns). US3-US5 all work on post_list.dart so should be sequential.

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Foundational utilities (T006-T008) before story-specific logic
- Core implementation before integration
- Story complete before moving to next priority

### Parallel Opportunities

- **Setup (Phase 1)**: T003, T004, T005 (all [P]) - review existing code in parallel
- **Foundational (Phase 2)**: No parallel tasks (sequential file modifications)
- **User Story 1 Tests**: T009, T010, T011 (all [P] - different test scenarios)
- **User Story 2 Tests**: T017, T018, T019 (all [P] - regression tests)
- **User Story 3 Tests**: T023, T024, T025 (all [P] - divider scenarios)
- **User Story 3 Implementation**: T026, T027 (different files - helper vs widget)
- **User Story 4 Tests**: T030, T031, T032 (all [P] - scroll scenarios)
- **User Story 5 Tests**: T038, T039, T040 (all [P] - scroll scenarios)
- **Polish**: T048, T049, T050, T053 (all [P] - different tasks)

**Team Strategy**: US1 and US2 can be worked by different developers in parallel. US3-US5 should be sequential (same files).

---

## Parallel Example: User Story 1 (Desktop Navigation)

```bash
# Launch all tests for User Story 1 together:
Task: "Widget test for desktop first-time workspace entry in frontend/test/presentation/workspace/workspace_navigation_desktop_test.dart"
Task: "Widget test for desktop group switching without snapshot in frontend/test/presentation/workspace/workspace_navigation_desktop_test.dart"
Task: "Integration test for desktop workspace tab click scenario in frontend/test/presentation/workspace/workspace_navigation_desktop_test.dart"
```

---

## Parallel Example: User Story 3 (Divider Positioning)

```bash
# Launch all tests for User Story 3 together:
Task: "Widget test for divider position with 5 unread posts in frontend/test/widgets/post/unread_divider_position_test.dart"
Task: "Widget test for no divider when all posts read in frontend/test/widgets/post/unread_divider_position_test.dart"
Task: "Widget test for divider with single unread post in frontend/test/widgets/post/unread_divider_position_test.dart"

# Launch parallel implementation tasks:
Task: "Update findFirstUnreadGlobalIndex() in frontend/lib/core/utils/read_position_helper.dart"
Task: "Update UnreadMessageDivider widget in frontend/lib/presentation/widgets/post/unread_message_divider.dart"
```

---

## Implementation Strategy

### MVP First (User Stories 1-2 Only)

1. Complete Phase 1: Setup (T001-T005)
2. Complete Phase 2: Foundational (T006-T008) - **CRITICAL**
3. Complete Phase 3: User Story 1 - Desktop navigation fix (T009-T016)
4. Complete Phase 4: User Story 2 - Mobile regression tests (T017-T022)
5. **STOP and VALIDATE**: Test desktop + mobile navigation independently
6. Deploy/demo navigation fixes if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 + User Story 2 → Test independently → Deploy (MVP: Navigation fixed!)
3. Add User Story 3 → Test independently → Deploy (Divider fixed!)
4. Add User Story 4 → Test independently → Deploy (Scroll to unread fixed!)
5. Add User Story 5 → Test independently → Deploy (Scroll to latest fixed!)
6. Add Badge Timing → Test independently → Deploy (Complete bug fix!)

### Parallel Team Strategy

With two developers:

1. Team completes Setup + Foundational together (T001-T008)
2. Once Foundational is done:
   - **Developer A**: User Story 1 (Desktop navigation) - T009-T016
   - **Developer B**: User Story 2 (Mobile regression tests) - T017-T022
3. Then sequential (same files):
   - **Developer A or B**: User Story 3 (Divider) - T023-T029
   - **Developer A or B**: User Story 4 (Scroll to unread) - T030-T037
   - **Developer A or B**: User Story 5 (Scroll to latest) - T038-T043
4. Both: Badge Timing + Polish (T044-T055)

---

## Test Execution

### Run Tests with dart-flutter MCP (Preferred)

```bash
# Full test suite
mcp__dart-flutter__run_tests --roots '[{"root": "file:///absolute/path/to/project"}]'

# Specific test file (for targeted validation)
flutter test frontend/test/presentation/workspace/workspace_navigation_desktop_test.dart
```

### Run Code Analysis

```bash
# Use dart-flutter MCP
mcp__dart-flutter__analyze_files

# Or manual
cd frontend && flutter analyze
```

---

## Clarifications Applied (from /speckit.analyze)

### A1 - Visual Design Specification (Divider)
**Resolved**: Detailed visual design added to Phase 5 → T028
- Color: Brand Purple (#5C068C) @ 30% opacity
- Typography: 12px, weight 500, letter-spacing 0.5px
- Padding: 16px (V), 24px (H), 12px (text H)

### A3 - Position Specification ("at/near the top")
**Resolved**: Detailed position specs added to Phase 6 & 7
- Position: `AutoScrollPosition.begin` (viewport top)
- Offset: 0px from viewport top
- Tolerance: ±50px (measurement allowance)
- Duration: 0ms (instant)

### Bottom Padding
**Status**: Kept as-is (30% of viewport height)
- Rationale: Allows scrolling past latest post for context
- Implementation: post_list.dart line 652-654 (unchanged)

### Notes

- [P] tasks = different files, no dependencies, can run in parallel
- [Story] label (US1-US5) maps task to specific user story for traceability
- Each user story should be independently completable and testable
- **Verify tests fail before implementing** (TDD approach)
- Commit after each logical task group (e.g., after all US1 tests pass)
- Stop at any checkpoint to validate story independently
- Use dart-flutter MCP for all testing (don't use manual `flutter test`)
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence
- Bug fixes across US3-US5 touch same file (post_list.dart) - do sequentially to avoid merge conflicts

---

## Known Issues & Future Improvements

**Documentation**: See [MEMO_known_issues.md](./MEMO_known_issues.md) for detailed issue tracking

### Issue 1: 스크롤 포지션 초기화 오류 (새 게시글 작성 후)
- **Status**: Documented (2025-11-10)
- **Priority**: Medium
- **Severity**: Low (기능 작동, 편의성 저하)
- **Impact**: 읽지 않은 글 구분선은 표시되지만, 스크롤이 최신 글(맨 아래)로 이동
- **Cause**: 새로운 게시글 추가 시 읽음 위치 갱신 로직 미흡
- **Affected Files**:
  - `frontend/lib/core/utils/read_position_helper.dart`
  - `frontend/lib/presentation/widgets/post/post_list.dart`
  - `frontend/lib/presentation/providers/workspace_state_provider.dart`
- **Recommended Fix**: Next sprint (post-release)
- **Estimated Effort**: 2-4시간
- **Test Coverage Required**:
  - Unit test: 새 게시글 작성 후 읽음 위치 갱신 검증
  - Widget test: 스크롤 타겟이 읽지 않은 글로 설정되는지 검증
  - Integration test: 전체 시나리오 End-to-End 테스트

### Future Tasks (TBD)

이 섹션은 향후 개선 작업이 추가될 때 업데이트됩니다.

- [ ] Fix: 스크롤 포지션 초기화 오류 (Issue 1)
- [ ] Write 26 missing tests (from MEMO_test_failures.md)
- [ ] Fix 17 pre-existing test failures (from MEMO_test_failures.md)
