# Data Model: Workspace Navigation and Scroll Bugs Fix

**Feature**: 002-workspace-bugs-fix
**Date**: 2025-11-10

## Overview

This bug fix primarily involves state management and UI behavior rather than new data structures. This document describes the existing entities involved and any modifications to their behavior.

## Existing Entities (No Schema Changes)

### WorkspaceSnapshot (In-Memory State)

**Purpose**: Session-scoped cache of user's last position within a group

**Fields**:
- `selectedGroupId: String?` - Currently active group
- `selectedChannelId: String?` - Currently active channel
- `selectedPostId: int?` - Currently selected post for comments
- `currentView: WorkspaceView` - Desktop view (groupHome, channel, calendar, admin)
- `mobileView: MobileWorkspaceView` - Mobile view (channelList, channelView)
- `isCommentsVisible: bool` - Comments sidebar state
- `previousView: WorkspaceView?` - For back navigation
- `navigationHistory: List<NavigationHistoryEntry>` - Stack for back button

**Lifecycle** (Bug Fix Target):
- **Created**: When user first enters a group in current session
- **Updated**: On channel switch, view change, layout transition
- **Cleared**: On logout, session end, **OR when user returns to global home via back navigation** ⬅️ FIX

**Validation Rules**:
- Session-scoped: Not persisted across login/logout
- Per-group: Each group has independent snapshot
- Null on first-time: Indicates "first workspace access" for this group

### ReadPosition (API-Persisted)

**Purpose**: Track last read post ID per user per channel (for unread detection)

**Fields**:
- `userId: Long` - User identifier
- `channelId: Long` - Channel identifier
- `lastReadPostId: Long` - **Post ID (not timestamp)** of last read post ⬅️ FIX
- `updatedAt: Instant` - When position was last saved

**Lifecycle** (Bug Fix Target):
- **Created**: First time user views a channel
- **Updated**: **On channel exit/switch** (not during scrolling) ⬅️ FIX
- **Deleted**: Never (historic data)

**Validation Rules**:
- Unique per (userId, channelId) pair
- lastReadPostId must reference existing Post.id
- Updated only on channel exit (not real-time during scroll)

### NavigationState (Transient UI State)

**Purpose**: Manages current navigation context and layout mode

**Fields**:
- `layoutMode: LayoutMode` - Desktop, Mobile, NarrowDesktop
- `canHandleBack: bool` - Whether workspace can handle back press
- `currentRoute: String` - Current route path

**Lifecycle**:
- **Created**: On app initialization
- **Updated**: On viewport resize, navigation events
- **Cleared**: Never (persists while app running)

**Validation Rules**:
- LayoutMode determined by MediaQuery breakpoints
- canHandleBack determined by navigation stack depth

## State Transitions (Bug Fix Logic)

### Workspace Entry Flow

```
User Action: Click workspace tab / Enter group URL
  ↓
Check: Does session snapshot exist for this groupId?
  ├─ NO  → First-time access
  │   ├─ Desktop: Show group home (WorkspaceView.groupHome)
  │   └─ Mobile: Show channel list (MobileWorkspaceView.channelList)
  └─ YES → Returning to cached state
      ├─ Restore: selectedChannelId, currentView, mobileView
      └─ Apply: Cached scroll position, comments visibility
```

**Bug Fix**: Ensure "NO" branch triggers when user returns from global home via back navigation.

### Channel Entry Flow (Scroll Positioning)

```
User Action: Select channel
  ↓
Load: Posts from API (GET /api/channels/{id}/posts)
  ↓
Load: ReadPosition from API (GET /api/read-positions/{channelId})
  ↓
Calculate: First unread post index
  ├─ Compare: post.id > lastReadPostId (use ID, not timestamp) ⬅️ FIX
  ├─ Sort: By post.id ascending (oldest first)
  └─ Find: Min(post.id) where post.id > lastReadPostId
  ↓
Position: Scroll instantly (duration: 0ms) ⬅️ FIX
  ├─ Unread posts exist → Scroll to oldest unread (viewport top)
  └─ All posts read → Scroll to latest post (viewport top)
  ↓
Display: Unread divider above oldest unread (by post ID) ⬅️ FIX
```

**Bug Fix**: Use post ID for all ordering, instant scroll positioning, divider placement.

### Channel Exit Flow (Badge Update)

```
User Action: Switch to different channel / Exit workspace
  ↓
Capture: Current visible post ID (highest post.id in viewport)
  ↓
Save: ReadPosition to API (POST /api/read-positions)
  ├─ Body: { channelId, lastReadPostId: visiblePostId }
  └─ Async: Fire-and-forget (don't block navigation)
  ↓
Update: Unread badge count in channel list ⬅️ FIX (timing)
  └─ Calculate: COUNT(posts WHERE post.id > lastReadPostId)
```

**Bug Fix**: Badge update happens on exit only, not during scrolling.

### Back Navigation to Global Home

```
User Action: Press back repeatedly
  ↓
Check: Navigation stack depth
  ↓
Is stack exhausted? (Navigator.canPop() == false)
  ├─ YES → Exiting to global home
  │   ├─ Clear: All workspace snapshots for all groups
  │   └─ Effect: Next workspace entry is "first-time"
  └─ NO → Normal back within workspace
      └─ Restore: Previous navigation state from history
```

**Bug Fix**: Detect global home return and clear session snapshots.

## Constraints and Rules

### Post ID Ordering (Authoritative)
- **Rule**: All "oldest unread" calculations use `post.id < other.id`, never timestamps
- **Rationale**: IDs are monotonic, immune to clock skew, definitive insertion order
- **Impact**: Divider placement, scroll target, unread count

### Session-Scoped Snapshots
- **Rule**: WorkspaceSnapshot cleared on logout, session end, global home return
- **Rationale**: Users expect fresh start after full exit
- **Impact**: First-time navigation behavior

### Instant Scroll Positioning
- **Rule**: All auto-scroll operations use `Duration.zero` (no animation)
- **Rationale**: User should perceive content already at target position
- **Impact**: UX feels "instant navigation" not "animated scrolling"

### Badge Update Timing
- **Rule**: Unread badge updates only on channel exit/switch
- **Rationale**: Performance (no real-time updates), matches mental model
- **Impact**: Badge changes not visible until user switches channels

## No Database Schema Changes

This bug fix requires **zero database migrations**. All entities already exist:
- `ReadPosition` table: Already has `lastReadPostId` column
- `Post` table: Already has auto-increment `id` column
- Frontend state: Already has WorkspaceSnapshot in-memory structure

Changes are purely logic-level in Dart code.
