# Frontend Workspace & Navigation Guide

This guide captures the architectural patterns, state-management rules, and UX conventions required when extending the workspace experience (channels, comments, admin pages) in the Flutter frontend. Reference it whenever you create or modify screens that live under `WorkspacePage`, navigation widgets, or related providers.

## 1. Layout & Page Structure

- **Desktop layout** uses `DesktopWorkspaceLayout`, which composes:
  - Left channel/navigation rail (`ChannelNavigation`)
  - Main content area (channel view, group home, calendar, admin, etc.)
  - Right sliding comment panel (`SlidePanel` + `PostPreviewWidget`)
- **Mobile layout** follows a 3-step flow managed by `workspaceMobileViewProvider`:
  - `channelList` → `channelPosts` → `postComments`
  - Switching between steps must go through notifier methods (`selectChannelForMobile`, `showCommentsForMobile`, `handleMobileBack`).
- Always use `ResponsiveLayoutHelper` for breakpoint decisions instead of duplicating `MediaQuery.of` logic.

### Adding a new workspace view
1. Add a case to `WorkspaceView` enum if it represents a new top-level view.
2. Implement a navigation method on `WorkspaceStateNotifier` (e.g., `showGroupAdminPage`, `showApplicationManagementPage`) that clears transient channel/comment state and sets `previousView` when needed.
3. Update `_buildMainContent` in `workspace_page.dart` to render the new view.
4. Update `page_title_provider.dart` (desktop + mobile breadcrumb) to return the correct title/path.
5. Extend `ChannelNavigation` or other widgets only if the new view needs entry points in the left rail.
6. Ensure back-handling (`handleWebBack` / `handleMobileBack`) recognizes the new view so users can exit gracefully.

## 2. State Management Patterns

- `workspace_state_provider.dart` owns the canonical `WorkspaceState`. Use the provided selectors (e.g., `workspaceCurrentViewProvider`, `workspaceChannelPermissionsProvider`) instead of `ref.watch(workspaceStateProvider)` to avoid unnecessary rebuilds.
- `WorkspaceStateNotifier.enterWorkspace` **must await** `myGroupsProvider.future` before loading channels so group membership & permissions are ready on the very first render. Never mutate workspace state directly from the page before this future resolves.
- When you need new derived data, add a provider near the existing ones. Do **not** expose mutable state outside the notifier.
- Keep all view transitions inside the notifier to guarantee atomic updates (channel/id, comment visibility, history, previous view).
- Reset transient flags (e.g., `isNarrowDesktopCommentsFullscreen`) whenever switching to non-channel views so breadcrumbs and overlays stay in sync.

### copyWith tips
- The standard `copyWith` assumes `null` means “clear the field”. If you need to explicitly keep a field `null`, call `copyWith(field: null)`.
- For collections, pass the new list/map; avoid mutating existing references.

## 3. Navigation & Back Handling

- `WorkspaceStateNotifier.handleWebBack()` prioritizes:
  1. Returning from special views via `previousView`
  2. Closing comments
  3. Channel history (stack of previous channel IDs)
  4. Signalling the router to exit workspace
- `handleMobileBack()` mirrors the mobile 3-step flow and clears comment indicators from `workspaceContext`.
- When adding new flows, ensure back handlers either return `true` (handled) or defer to navigation history appropriately.
- `TopNavigation` delegates workspace back actions to these handlers before falling back to the global navigation controller.

## 4. Breadcrumb & Top Bar Rules

- `page_title_provider.dart` produces `PageBreadcrumb` for both desktop and mobile.
  - Desktop shows `Workspace > ...` unless the narrow comment overlay is active (then display “댓글”).
  - Mobile path depends on `workspaceMobileViewProvider`; extend this logic if new views need explicit labels.
- `TopNavigation` displays the breadcrumb and current group role. Any new role or state display should reuse the existing selectors (`workspaceCurrentGroupRoleProvider`).

## 5. Channel Navigation & Permissions

- `ChannelNavigation` relies on:
  - `workspaceHasAnyGroupPermissionProvider` to gate the admin button.
  - `currentGroupNameProvider` and `workspaceChannelsProvider` for data.
- When adding buttons (e.g., to new views), use `_buildTopButton` to maintain styling and update the notifier method you call.
- Channel selection reset must clear comment state and update history via `selectChannel`.

## 6. Comments & Post Panels

- `ChannelContentView` loads posts based on `channelPermissions`; it calls `showComments()` with `isNarrowDesktop` so the comment overlay adopts the right mode.
- `PostPreviewWidget` + `CommentList` live inside the comment panel; ensure they read `workspaceSelectedPostIdProvider` and refresh keys when needed.
- Always close comments via `hideComments()` when leaving channel context to avoid residual overlays.

## 7. Extensibility Checklist

When adding a new workspace-related page or feature:

1. **State**: Decide if additional state belongs in `WorkspaceState` or a feature-specific provider. Keep workspace-related transitions centralized.
2. **Navigation entry**: Add button/icon where appropriate (ChannelNavigation, top nav, etc.) respecting permission checks.
3. **Breadcrumb**: Update desktop/mobile logic for titles. Include group/tabs if user context demands it. For tab-level breadcrumbs, expose tab state via provider before referencing it here.
4. **Back handling**: Confirm the new flow integrates with `handleWebBack` / `handleMobileBack`—particularly for modal overlays or multi-step wizards.
5. **Responsive behavior**: Validate narrow desktop and mobile flows. Use `ResponsiveLayoutHelper` for breakpoints.
6. **Design system**: Reuse existing widgets (`ActionCard`, `WorkspaceEmptyState`, buttons) and spacing constants.
7. **Permissions**: Use `workspaceChannelPermissionsProvider` (for channel-level) or group membership data to gate UI.
8. **Testing**: Check both first-load and re-entry scenarios (e.g., switching groups, returning from admin to channel) to ensure state resets correctly.

## 8. Debugging Tips

- **Unexpected rebuilds**: Scan for `ref.watch(workspaceStateProvider)` in widgets; migrate to selectors.
- **Breadcrumb stuck on “댓글”**: Verify `isNarrowDesktopCommentsFullscreen` resets and `currentView` is updated.
- **Back navigation loops**: Inspect `channelHistory` and `previousView` logic in notifier; ensure you pop history when leaving channel context.
- **Permission mismatches**: Confirm `loadChannelPermissions` completes and watch `workspaceChannelPermissionsProvider` before enabling actions.

## 9. References & Further Reading

- `frontend/lib/presentation/pages/workspace/workspace_page.dart`
- `frontend/lib/presentation/providers/workspace_state_provider.dart`
- `frontend/lib/presentation/widgets/workspace/`
- `docs/ui-ux/pages/workspace-pages.md`
- `docs/implementation/workspace-refactoring-status.md`
- `docs/implementation/frontend-guide.md`

Keep this guide updated as we introduce new workspace features (e.g., calendars, recruitment, dashboards) so future agents have a single source of truth for the workspace stack.
