# Quick Start: Workspace Navigation and Scroll Bugs Fix

**Feature**: 002-workspace-bugs-fix
**Branch**: `002-workspace-bugs-fix`
**Date**: 2025-11-10

## Overview

Fix two critical workspace bugs: (1) Desktop first-access shows channel instead of group home, (2) Unread post divider and scroll positioning behave inconsistently. This is a frontend-only bug fix with no backend changes.

## Prerequisites

- Flutter SDK 3.x installed
- Project cloned and dependencies installed (`flutter pub get`)
- Running development server (backend) on expected port
- dart-flutter MCP configured for testing

## Development Setup

### 1. Checkout Feature Branch

```bash
git checkout 002-workspace-bugs-fix
flutter pub get
```

### 2. Verify Current Bug Behavior (Optional)

**Bug 1: Desktop Navigation**
1. Open app in desktop viewport (width > 1024px)
2. Navigate to workspace tab (first time in session)
3. **Expected**: Group home view
4. **Actual** (bug): Channel view appears

**Bug 2: Scroll Positioning**
1. Open a channel with unread posts
2. **Expected**: Instant positioning to oldest unread (no animation), divider above oldest unread
3. **Actual** (bug): Inconsistent divider placement, visible scroll animation

### 3. Key Files to Modify

**Navigation Fix**:
- `frontend/lib/presentation/pages/workspace/workspace_page.dart` - First-access logic
- `frontend/lib/presentation/providers/workspace_state_provider.dart` - Snapshot clearing

**Scroll Fix**:
- `frontend/lib/presentation/widgets/post/post_list.dart` - Instant positioning, post ID ordering
- `frontend/lib/presentation/widgets/post/unread_message_divider.dart` - Divider placement
- `frontend/lib/core/utils/read_position_helper.dart` - Unread detection

**Tests** (Create New):
- `frontend/test/presentation/workspace/workspace_navigation_test.dart`
- `frontend/test/presentation/workspace/workspace_scroll_test.dart`

## Implementation Guide

### Phase 1: Navigation Fix (Desktop First-Access)

**Goal**: Show group home (not channel) on first desktop access

**Changes**:
1. **workspace_state_provider.dart**: Modify `_determineNavigationTarget()` logic
   - Ensure "no snapshot" condition respects global home return
   - Add snapshot clearing on `exitWorkspace()` when `canPop() == false`

2. **workspace_page.dart**: Review `_initializeWorkspace()` timing
   - Verify first-time detection works correctly
   - Ensure mobile channel list behavior remains unchanged

**Test Manually**:
```bash
# Restart app (clear session)
# Navigate to workspace → Verify group home on desktop
# Switch to mobile viewport → Verify channel list
```

### Phase 2: Scroll Positioning Fix

**Goal**: Instant scroll to oldest unread (by post ID), no animation

**Changes**:
1. **read_position_helper.dart**: Enforce post ID ordering
   ```dart
   // Before (buggy): Mixed timestamp/ID comparison
   // After (fixed): Always use post.id comparison
   final unreadPosts = posts.where((p) => p.id > lastReadPostId);
   final oldestUnread = unreadPosts.reduce((a, b) => a.id < b.id ? a : b);
   ```

2. **post_list.dart**: Change scroll animation duration
   ```dart
   // Before: await _scrollController.scrollToIndex(targetIndex, duration: Duration(milliseconds: 300));
   // After: await _scrollController.scrollToIndex(targetIndex, duration: Duration.zero);
   ```

3. **unread_message_divider.dart**: Position based on post ID
   - Calculate divider index using post ID comparison only

**Test Manually**:
```bash
# Open channel with unread posts
# Verify: Content appears instantly at oldest unread (no scroll animation)
# Verify: Divider appears immediately above oldest unread post
```

### Phase 3: Badge Update Timing

**Goal**: Update badge counts on channel exit only

**Changes**:
1. **workspace_state_provider.dart**: Move badge update to `selectChannel()`
   ```dart
   Future<void> selectChannel(String channelId) async {
     if (state.selectedChannelId != null) {
       await saveReadPosition(state.selectedChannelId!, currentVisiblePostId);
       // Update badge here (on exit), not during scrolling
     }
     // ... load new channel
   }
   ```

**Test Manually**:
```bash
# Open channel with unread posts
# Scroll through posts → Badge should NOT change yet
# Switch to different channel → Badge should now update
```

## Testing

### Run Widget Tests

```bash
# Use dart-flutter MCP (preferred)
mcp__dart-flutter__run_tests --roots '[{"root": "file:///path/to/project"}]'

# Or manual (not recommended)
cd frontend
flutter test test/presentation/workspace/
```

### Run Integration Tests

```bash
# Full test suite
mcp__dart-flutter__run_tests --roots '[{"root": "file:///path/to/project"}]'

# Specific test file
flutter test test/presentation/workspace/workspace_navigation_test.dart
```

### Run Code Analysis

```bash
# Use dart-flutter MCP (preferred)
mcp__dart-flutter__analyze_files

# Or manual
cd frontend
flutter analyze
```

## Manual Validation Checklist

### Navigation Tests
- [ ] Desktop: First workspace access shows group home
- [ ] Desktop: Group switching with no snapshot shows group home
- [ ] Desktop: Group switching with snapshot restores cached view
- [ ] Mobile: First workspace access shows channel list
- [ ] Mobile: Channel list preserved during layout transitions
- [ ] Back navigation to global home clears snapshots

### Scroll Tests
- [ ] Channel with unread posts: Instant positioning to oldest unread (no animation)
- [ ] Channel with unread posts: Divider appears immediately above oldest unread
- [ ] Channel with no unread posts: Instant positioning to latest post
- [ ] Channel with one post: Handles correctly (read/unread cases)
- [ ] Rapid channel switching: No race conditions or flicker

### Badge Tests
- [ ] Badge counts correct on channel list
- [ ] Badge updates only when switching channels (not during scroll)
- [ ] Badge updates on workspace exit
- [ ] Badge counts use post ID ordering (not timestamp)

## Common Issues

### Issue: Scroll animation still visible
**Solution**: Ensure `Duration.zero` is used in ALL scroll operations, including `jumpTo()` and `scrollToIndex()`

### Issue: Divider in wrong position
**Solution**: Verify all unread detection uses `post.id > lastReadPostId` comparison, never timestamps

### Issue: Desktop still shows channel on first access
**Solution**: Check `_determineNavigationTarget()` logic - ensure snapshot null check happens before view selection

### Issue: Mobile channel list broken
**Solution**: Verify regression tests pass - mobile behavior should remain unchanged

## Rollback Plan

If bugs introduced:
1. Revert commit(s) from this branch
2. Return to `develop` branch
3. File issue with test failure details
4. Use `git revert` to safely undo changes

## Success Criteria

Before merging:
- ✅ All dart-flutter MCP tests pass (100%)
- ✅ Manual validation checklist complete
- ✅ No new lint warnings
- ✅ Mobile channel navigation regression tests pass
- ✅ Desktop/mobile first-access behavior correct
- ✅ Scroll positioning instant (no visible animation)
- ✅ Badge updates on channel exit only

## References

- [Specification](./spec.md)
- [Implementation Plan](./plan.md)
- [Research](./research.md)
- [Data Model](./data-model.md)
