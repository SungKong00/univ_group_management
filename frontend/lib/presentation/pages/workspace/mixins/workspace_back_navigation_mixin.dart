import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/workspace_state_provider.dart';
import '../../../../core/navigation/layout_mode.dart';
import '../../../utils/responsive_layout_helper.dart';

/// Workspace 페이지의 뒤로가기 네비게이션 로직을 담당하는 Mixin
///
/// 이 Mixin은 다음과 같은 뒤로가기 시나리오를 처리합니다:
/// - 모바일: 채널 목록 ↔ 게시글 목록 ↔ 댓글 뷰 네비게이션
/// - Narrow Desktop: 댓글 전체화면 ↔ 일반 뷰, 특수 뷰 네비게이션
/// - Wide Desktop: 특수 뷰 → 댓글 → 채널 히스토리 순서 처리
/// - Tablet: Wide Desktop과 동일한 로직
mixin WorkspaceBackNavigationMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  /// 모바일 뒤로가기 가능 여부 확인
  bool canHandleMobileBack() {
    final currentView = ref.read(workspaceCurrentViewProvider);
    final mobileView = ref.read(workspaceMobileViewProvider);
    // 특수 뷰(그룹 관리자, 멤버관리, 그룹 홈, 캘린더 등)에서는 내부적으로 뒤로가기를 처리
    if (currentView != WorkspaceView.channel) {
      return true;
    }
    // channelList 상태에서는 뒤로가기를 허용 (홈으로 이동)
    // 나머지 상태에서는 내부적으로 처리
    return mobileView != MobileWorkspaceView.channelList;
  }

  /// 모바일 뒤로가기 처리
  void handleMobileBackPress(WorkspaceStateNotifier notifier) {
    // handleMobileBack()이 true를 반환하면 내부적으로 처리됨
    // false를 반환하면 시스템 뒤로가기 허용
    notifier.handleMobileBack();
  }

  /// Narrow Desktop 뒤로가기 가능 여부 확인
  bool canHandleNarrowDesktopBack() {
    final isCommentFullscreen = ref.read(
      workspaceIsNarrowDesktopCommentsFullscreenProvider,
    );
    final currentView = ref.read(workspaceCurrentViewProvider);
    final previousView = ref.read(workspacePreviousViewProvider);

    // 1. 댓글 전체화면일 때
    if (isCommentFullscreen) {
      return true;
    }

    // 2. 특수 뷰(groupAdmin, memberManagement 등)일 때
    if (currentView != WorkspaceView.channel && previousView != null) {
      return true;
    }

    return false;
  }

  /// Narrow Desktop 뒤로가기 처리
  void handleNarrowDesktopBackPress(WorkspaceStateNotifier notifier) {
    final currentView = ref.read(workspaceCurrentViewProvider);
    final isCommentFullscreen = ref.read(
      workspaceIsNarrowDesktopCommentsFullscreenProvider,
    );

    // 특수 뷰에서는 handleWebBack() 호출
    if (currentView != WorkspaceView.channel) {
      notifier.handleWebBack();
      return;
    }

    // 댓글 전체화면에서는 댓글 닫기
    if (isCommentFullscreen) {
      notifier.hideComments();
    }
  }

  /// Wide Desktop 뒤로가기 가능 여부 확인
  bool canHandleWideDesktopBack() {
    final navigationHistory = ref.read(workspaceNavigationHistoryProvider);
    return navigationHistory.isNotEmpty;
  }

  /// Wide Desktop 뒤로가기 처리
  void handleWideDesktopBackPress(WorkspaceStateNotifier notifier) {
    // handleWebBack()이 모든 뒤로가기 로직을 처리함
    // (특수 뷰 → 댓글 → 채널 히스토리 순서)
    notifier.handleWebBack();
  }

  /// Tablet (MEDIUM) 뒤로가기 가능 여부 확인
  bool canHandleTabletBack() {
    final navigationHistory = ref.read(workspaceNavigationHistoryProvider);
    return navigationHistory.isNotEmpty;
  }

  /// Tablet (MEDIUM) 뒤로가기 처리
  void handleTabletBackPress(WorkspaceStateNotifier notifier) {
    // Wide Desktop과 동일한 로직 (사이드바는 항상 축소 상태)
    notifier.handleWebBack();
  }

  /// LayoutMode 기반 뒤로가기 가능 여부 확인
  bool canHandleBackForMode(LayoutMode mode) {
    switch (mode) {
      case LayoutMode.compact:
        return canHandleMobileBack();
      case LayoutMode.medium:
        return canHandleTabletBack();
      case LayoutMode.wide:
        // Wide 모드 내에서는 ResponsiveLayoutHelper로 Narrow/Wide 구분
        final responsive = ResponsiveLayoutHelper(
          context: context,
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width,
          ),
        );
        return responsive.isNarrowDesktop
            ? canHandleNarrowDesktopBack()
            : canHandleWideDesktopBack();
    }
  }

  /// LayoutMode 기반 뒤로가기 처리
  void handleBackPressForMode(LayoutMode mode, WorkspaceStateNotifier notifier) {
    switch (mode) {
      case LayoutMode.compact:
        handleMobileBackPress(notifier);
        break;
      case LayoutMode.medium:
        handleTabletBackPress(notifier);
        break;
      case LayoutMode.wide:
        // Wide 모드 내에서는 ResponsiveLayoutHelper로 Narrow/Wide 구분
        final responsive = ResponsiveLayoutHelper(
          context: context,
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width,
          ),
        );
        if (responsive.isNarrowDesktop) {
          handleNarrowDesktopBackPress(notifier);
        } else {
          handleWideDesktopBackPress(notifier);
        }
        break;
    }
  }
}
