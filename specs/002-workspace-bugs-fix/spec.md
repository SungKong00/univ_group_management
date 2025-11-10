# Feature Specification: Workspace Navigation and Scroll Bugs Fix

**Feature Branch**: `002-workspace-bugs-fix`
**Created**: 2025-11-10
**Status**: Draft
**Input**: User description: "워크스페이스의 몇가지 버그를 수정할거야.
우선, 워크스페이스 첫 접속시 채널이 보이고 있어. 원래대로라면 그룹 홈이 보이는게 맞아. 모바일에서는 채널 네비게이션이 보여야해. 혹시 첫 접속시 채널을 보여주는 로직이 어딘가에 남아있는지 먼저 체크해줘.

두번째 버그는 읽지 않은 글 구분선과 스크롤이야.
우선 읽지 않은 글을 체크하는 로직이 제대로 작동하나 확인해줘.
그리고 구분선이 읽지 않은 글 중 가장 오래 된글의 위에 보이도록 해줘.
또한, 채널에 접속하면 스크롤의 위치가 읽지 않은 글 중 가장 오래 된 글이 화면 상단에 보이도록 스크롤 위치를 세팅해주고, 읽지 않은 글이 없다면 가장 최신 글이 화면 상단에 위치하도록 스크롤 위치를 옮겨줘.
지금 이 동작들이 일관되게 동작이 안되고 있어.
이런 동작을 만들기 위해 코드를 짰던거라 코드 분석을 해보면 의도가 어느정도 파악이 될거야."

## Clarifications

### Session 2025-11-10

- Q: When exactly should the unread badge count update? → A: Update badge only when user exits/switches away from the channel
- Q: Since mobile channel navigation is currently working correctly, what level of protection/validation should we ensure? → A: Add explicit test coverage for mobile channel list behavior to prevent regressions
- Q: When determining the "oldest unread post" for divider placement, what should be the authoritative ordering? → A: Use post ID (auto-increment) as authoritative ordering
- Q: How should the system determine if this is a "first-time" workspace access versus returning to a cached state? → A: First-time = no workspace snapshot exists in current session (session-scoped, reset on login). Additionally, if user navigates back through entire navigation stack to global home and then re-enters workspace, treat as first-time access (clear session snapshot)
- Q: What should happen when a user manually scrolls while auto-scroll is preparing to execute or is executing? → A: Use instant positioning (duration: 0ms, no visible scroll animation) so user sees content already at target position. If user manually scrolls during loading, cancel auto-positioning and respect user's scroll intent

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Desktop First-Time Workspace Access Shows Group Home (Priority: P1)

When a user clicks the workspace tab or accesses a group for the first time on desktop, the system should display the group home view as the default landing page, not a specific channel view.

**Why this priority**: This is the primary navigation bug that affects all desktop users' initial workspace experience. Incorrectly showing a channel view breaks the expected navigation flow and creates confusion about the workspace structure.

**Independent Test**: Can be fully tested by clicking workspace tab on desktop and verifying the group home view appears, delivering correct initial navigation state.

**Acceptance Scenarios**:

1. **Given** user is on desktop layout, **When** user clicks workspace tab for the first time, **Then** group home view is displayed
2. **Given** user is on desktop layout, **When** user directly accesses workspace URL without channel ID, **Then** group home view is displayed
3. **Given** user switches to a different group on desktop, **When** no previous workspace state exists for that group, **Then** group home view is displayed

---

### User Story 2 - Mobile First-Time Workspace Access Shows Channel List (Priority: P1)

When a user accesses a workspace for the first time on mobile devices, the system should display the channel navigation list, allowing users to select which channel to view. **Note**: This behavior is currently working correctly; this story ensures regression prevention through explicit test coverage.

**Why this priority**: Mobile UX requires different navigation patterns due to limited screen space. Channel list should be the entry point for mobile users to choose their destination. While currently functional, explicit test coverage is critical to prevent regressions during the desktop navigation bug fix.

**Independent Test**: Can be fully tested by accessing workspace on mobile viewport and verifying channel list navigation appears, delivering appropriate mobile-first navigation. Test coverage must include automated tests to catch regressions.

**Acceptance Scenarios**:

1. **Given** user is on mobile layout, **When** user clicks workspace tab for the first time, **Then** channel list navigation is displayed
2. **Given** user is on mobile layout, **When** user switches to a different group, **Then** channel list is displayed instead of directly showing a channel
3. **Given** user is on mobile layout, **When** user returns from a channel to workspace, **Then** channel list is shown

---

### User Story 3 - Unread Posts Divider Positioned Above Oldest Unread Post (Priority: P2)

When a channel contains unread posts, the system displays a visual divider line immediately above the oldest unread post, clearly marking where new content begins.

**Why this priority**: Visual indication of unread content is essential for user orientation within long post lists. The divider helps users quickly identify where they left off.

**Independent Test**: Can be fully tested by creating test posts, simulating read positions, and verifying the divider appears exactly above the oldest unread post.

**Acceptance Scenarios**:

1. **Given** user has 5 unread posts in a channel, **When** user opens the channel, **Then** divider appears immediately above the oldest unread post (not the newest)
2. **Given** user has read all posts, **When** user opens the channel, **Then** no unread divider is displayed
3. **Given** user has one unread post, **When** user opens the channel, **Then** divider appears above that single post

---

### User Story 4 - Auto-Scroll to Oldest Unread Post on Channel Entry (Priority: P2)

When a user enters a channel with unread posts, the scroll position automatically moves so that the oldest unread post appears at the top of the viewport, allowing users to read chronologically from where they left off.

**Why this priority**: Automatic scroll positioning saves users from manual scrolling and ensures they don't miss content. Combined with the divider, it provides seamless content consumption.

**Independent Test**: Can be tested independently by entering channels with various unread post counts and verifying scroll position places oldest unread at viewport top.

**Acceptance Scenarios**:

1. **Given** channel has 10 unread posts, **When** user enters the channel, **Then** scroll position shows oldest unread post at top of viewport
2. **Given** channel has unread posts beyond initial load (pagination), **When** user enters the channel, **Then** system loads necessary pages and scrolls to oldest unread
3. **Given** scroll happens immediately on entry, **When** user hasn't manually scrolled, **Then** auto-scroll executes within 500ms of channel load

---

### User Story 5 - Auto-Scroll to Latest Post When All Posts Are Read (Priority: P3)

When a user enters a channel where all posts have been read (no unread posts), the scroll position automatically moves to show the most recent post at the top of the viewport.

**Why this priority**: Provides consistent scroll behavior regardless of read status. Users should always land in a predictable position that shows relevant content.

**Independent Test**: Can be tested by marking all posts as read and verifying scroll positions to latest post on channel entry.

**Acceptance Scenarios**:

1. **Given** all posts in channel are read, **When** user enters the channel, **Then** scroll position shows most recent post at top of viewport
2. **Given** user returns to a fully-read channel, **When** no new posts exist, **Then** scroll maintains latest-post-at-top positioning
3. **Given** channel has been marked as fully read, **When** user re-enters, **Then** no unread divider appears and scroll is at latest post

---

### Edge Cases

- What happens when unread posts are in the middle of a long conversation spanning multiple dates?
- How does system handle rapid channel switching before scroll animation completes?
- What happens if user manually scrolls during auto-scroll execution?
- How does system behave when unread post was deleted between read position save and channel re-entry?
- What happens on slow network connections where posts load slowly?
- How does system handle channels with only one post (both read and unread cases)?
- What happens when user switches between mobile and desktop layouts while in a channel?

## Requirements *(mandatory)*

### Functional Requirements

#### Navigation Requirements

- **FR-001**: System MUST display group home view as default landing page when user first accesses workspace on desktop layout (first-time = no workspace snapshot in current session)
- **FR-002**: System MUST display channel list as default view when user first accesses workspace on mobile layout (first-time = no workspace snapshot in current session)
- **FR-003**: System MUST NOT automatically select or display a specific channel view when user enters workspace without explicit channel selection
- **FR-004**: System MUST preserve the intended navigation target (group home vs channel list) across layout mode transitions during initial workspace access
- **FR-005**: System MUST distinguish between "first-time access" (no session-scoped workspace snapshot for the group) and "returning to cached state" (session snapshot exists) for navigation behavior
- **FR-005a**: System MUST clear workspace session snapshot and treat as first-time access when user navigates back through entire navigation stack to global home, then re-enters workspace

#### Unread Posts Detection Requirements

- **FR-006**: System MUST accurately track the last read post ID for each channel
- **FR-007**: System MUST persist read position data across user sessions
- **FR-008**: System MUST identify all posts newer than the last read post as unread (using post ID as authoritative ordering, not timestamp)
- **FR-009**: System MUST handle cases where last read post has been deleted (treat next oldest post by ID as reference)
- **FR-010**: System MUST support read position tracking for paginated post lists
- **FR-011**: System MUST update unread badge counts in channel list only when user exits or switches away from the current channel (not in real-time during scrolling)

#### Visual Divider Requirements

- **FR-012**: System MUST display an unread message divider when unread posts exist in a channel
- **FR-013**: Divider MUST be positioned immediately above the oldest unread post (determined by post ID ordering, not timestamp or display order)
- **FR-014**: Divider MUST be visually distinct and labeled to indicate unread content boundary
- **FR-015**: Divider MUST NOT appear when all posts have been read
- **FR-016**: System MUST recalculate divider position when read status changes

#### Auto-Scroll Requirements

- **FR-017**: System MUST automatically position view to oldest unread post (determined by post ID ordering) when user enters a channel with unread content
- **FR-018**: Auto-positioning MUST place the target post at or near the top of the viewport
- **FR-019**: System MUST automatically position view to latest post (highest post ID) when user enters a channel with no unread posts
- **FR-020**: Auto-positioning MUST be instant (duration: 0ms, no visible scroll animation) so user sees content already at target position from the moment channel loads
- **FR-021**: System MUST handle scroll positioning consistently across different viewport sizes
- **FR-022**: System MUST immediately cancel auto-positioning if user manually scrolls during channel loading/initialization
- **FR-023**: System MUST load additional pages if oldest unread post is not in the initially loaded set

#### Consistency Requirements

- **FR-024**: Navigation behavior (desktop/mobile) MUST be consistent across all entry points (tab click, URL access, group switching)
- **FR-025**: Scroll positioning MUST be consistent and predictable for users (always unread-first or latest-first)
- **FR-026**: System MUST not exhibit race conditions between read position loading and scroll execution
- **FR-027**: System MUST maintain scroll positioning logic during orientation changes on mobile devices

### Key Entities *(include if feature involves data)*

- **Read Position**: Tracks the last post ID a user has seen in each channel, used to determine unread status
- **Navigation State**: Contains current view mode (group home, channel list, channel view) and layout context (desktop, mobile)
- **Workspace Snapshot**: Session-scoped cached state of user's last position within a group, including selected channel and scroll position (reset on login/session start)
- **Unread Post Index**: Calculated position within grouped post list identifying first unread post for scroll targeting (based on post ID ordering)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users accessing workspace on desktop see group home view 100% of the time on first access (no channel auto-selection)
- **SC-002**: Users accessing workspace on mobile see channel list 100% of the time on first access
- **SC-003**: Unread post divider appears in correct position (above oldest unread by post ID) in 95% of cases within 500ms of channel load
- **SC-004**: Channel content displays with oldest unread post already at viewport top (instant positioning, no visible scroll animation) in 95% of channel entries with unread content
- **SC-005**: Channel content displays with latest post already at viewport top (instant positioning, no visible scroll animation) in 95% of channel entries with no unread content
- **SC-006**: Zero observable race conditions between read position data loading and scroll positioning during normal usage
- **SC-007**: User testing shows 90% task completion rate for "find where you left off in a conversation" without perceiving any scroll motion
- **SC-008**: Navigation behavior remains consistent across layout transitions (0 incidents of incorrect view after responsive breakpoint change)
- **SC-009**: Workspace session snapshot correctly clears when user returns to global home via back navigation, ensuring fresh group home view on re-entry in 100% of cases
