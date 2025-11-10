# Research: Workspace Navigation and Scroll Bugs Fix

**Feature**: 002-workspace-bugs-fix
**Date**: 2025-11-10
**Status**: Complete

## Overview

This research document consolidates technical decisions and best practices for fixing workspace navigation and scroll positioning bugs. Since this is a bug fix rather than a new feature, research focuses on understanding current implementation patterns and identifying root causes.

## Research Topics

### 1. Session-Scoped Workspace Snapshots

**Decision**: Use in-memory WorkspaceSnapshot with explicit lifecycle management tied to navigation events

**Rationale**:
- Current implementation already uses session-scoped snapshots (ref: `workspace_state_provider.dart:_NavigationTarget`)
- Bug is in snapshot clearing logic when returning to global home via back navigation
- Session scope (vs persistent storage) is correct for UX - users expect fresh start after logout/login

**Implementation Pattern**:
```dart
// Clear snapshot on global home return
if (userNavigatedBackToGlobalHome) {
  _workspaceSnapshots.remove(groupId);
  // Next workspace entry will be "first-time"
}
```

**Alternatives Considered**:
- **Persistent snapshots** (LocalStorage/SharedPreferences): Rejected - would persist across sessions, breaking expected first-time behavior
- **Always fresh (no snapshots)**: Rejected - users lose position when switching groups within session
- **URL-based state**: Rejected - Navigator 2.0 already manages declarative routing

### 2. Post ID vs Timestamp Ordering

**Decision**: Use post ID (auto-increment integer) as authoritative ordering for "oldest unread"

**Rationale**:
- Post IDs are guaranteed monotonically increasing (database auto-increment)
- Immune to timezone issues, clock skew, or manual timestamp edits
- Current inconsistent divider placement likely due to mixing ID and timestamp sorting

**Implementation Pattern**:
```dart
// Find oldest unread by post ID, not creation timestamp
final unreadPosts = allPosts.where((p) => p.id > lastReadPostId).toList();
final oldestUnread = unreadPosts.reduce((a, b) => a.id < b.id ? a : b);
```

**Alternatives Considered**:
- **Timestamp-based**: Rejected - subject to clock skew and timezone ambiguity
- **Display order**: Rejected - UI grouping by date doesn't reflect actual post order
- **Last modified timestamp**: Rejected - post edits would change "unread" detection

### 3. Instant Scroll Positioning (Zero Animation)

**Decision**: Use `duration: Duration.zero` with pre-rendering strategy to hide scroll motion

**Rationale**:
- User should perceive content already at correct position (not see scrolling animation)
- Reduces jarring UX and cognitive load ("where am I scrolling to?")
- Matches native app behavior (instant navigation to bookmarked position)

**Implementation Pattern**:
```dart
// Option A: Instant scroll after content rendered
WidgetsBinding.instance.addPostFrameCallback((_) {
  _scrollController.jumpTo(targetOffset); // No animation
});

// Option B: AutoScrollController with duration: 0ms
await _scrollController.scrollToIndex(
  targetIndex,
  duration: Duration.zero, // Instant
  preferPosition: AutoScrollPosition.begin,
);
```

**Alternatives Considered**:
- **Fast animation (100-200ms)**: Rejected - still visible to user, conflicts with "instant" requirement
- **Opacity fade**: Rejected - adds complexity, user still perceives loading state
- **Preload offscreen**: Rejected - would require extensive ListView changes, performance impact

### 4. Badge Update Timing (Channel Exit Only)

**Decision**: Update unread badge counts in channel list only when user exits/switches channels, not during scrolling

**Rationale**:
- Avoids performance overhead of real-time badge updates on every scroll event
- Matches user mental model: "I'm still reading" until I leave the channel
- Prevents badge flicker during rapid scrolling

**Implementation Pattern**:
```dart
// In workspace_state_provider.dart
Future<void> selectChannel(String channelId) async {
  final previousChannelId = state.selectedChannelId;

  if (previousChannelId != null) {
    // Save read position and update badge on exit
    await saveReadPosition(previousChannelId, currentVisiblePostId);
    await _updateUnreadBadge(previousChannelId);
  }

  // Now load new channel...
}
```

**Alternatives Considered**:
- **Real-time updates**: Rejected - too expensive, causes UI jank
- **Debounced updates (2-3s)**: Rejected - adds complexity, still not aligned with "channel exit" mental model
- **Manual mark-as-read button**: Rejected - violates implicit read tracking UX

### 5. Back Navigation Stack Exhaustion

**Decision**: Detect navigation stack depth and clear workspace snapshot when returning to global home

**Rationale**:
- User pressing back repeatedly until global home indicates "I want to start fresh"
- Prevents stale channel view from reappearing after full exit
- Navigator 2.0 provides canPop() and route stack inspection

**Implementation Pattern**:
```dart
// In workspace navigation logic
void exitWorkspace() {
  final isReturnToGlobalHome = !Navigator.of(context).canPop();

  if (isReturnToGlobalHome) {
    // Clear all workspace snapshots - next entry is fresh
    _workspaceNotifier.clearNavigationHistory();
  }

  _workspaceNotifier.exitWorkspace();
}
```

**Alternatives Considered**:
- **Never clear snapshots**: Rejected - causes reported bug (channel shows instead of group home)
- **Timer-based expiry**: Rejected - arbitrary timeout doesn't match user intent
- **Global home route listener**: Rejected - too indirect, relies on route name matching

## Testing Strategy

### Widget Tests (30%)
- Navigation state transitions (first-time vs cached)
- Mobile/desktop layout switching preservation
- Back navigation clearing session snapshots

### Integration Tests (60%)
- Full workspace entry flow (global home → workspace → group home/channel list)
- Channel switching with read position save/restore
- Scroll positioning with post ID ordering
- Badge count updates on channel exit

### Manual Validation (10%)
- Visual confirmation of instant positioning (no scroll animation visible)
- Edge case: rapid channel switching before badge update completes
- Edge case: deleted unread post handling

## Dependencies Analysis

### Existing Packages (No Changes Needed)
- `flutter_riverpod: ^2.x`: State management (WorkspaceStateNotifier)
- `go_router: ^13.x`: Declarative routing (Navigator 2.0)
- `scroll_to_index: ^3.x`: AutoScrollController for indexed scrolling
- `visibility_detector: ^0.4.x`: Track visible posts for read position

### No New Dependencies Required
All required functionality exists in current packages. Bug fix is implementation-level only.

## Risk Assessment

### Low Risk
- Session snapshot clearing: Isolated change in `workspace_state_provider.dart`
- Post ID ordering: Simple comparison change in `read_position_helper.dart`

### Medium Risk
- Instant scroll positioning: Requires careful timing (postFrameCallback) to avoid flicker
- Badge update on exit: Must handle rapid channel switching edge case (debounce saves)

### Mitigation
- Comprehensive widget tests for navigation state machine
- Integration tests for scroll positioning under various post counts
- dart-flutter MCP test execution before PR merge

## Open Questions (Resolved)

All technical questions resolved through clarification session:
- ✅ Badge timing: Channel exit only
- ✅ Mobile regression: Explicit test coverage
- ✅ Post ordering: Post ID authoritative
- ✅ First-time definition: Session-scoped + global home return
- ✅ Scroll animation: Instant (0ms)

## References

- Current implementation: `frontend/lib/presentation/providers/workspace_state_provider.dart`
- Current scroll logic: `frontend/lib/presentation/widgets/post/post_list.dart`
- Navigator 2.0 docs: https://docs.flutter.dev/ui/navigation
- AutoScrollController: https://pub.dev/packages/scroll_to_index
