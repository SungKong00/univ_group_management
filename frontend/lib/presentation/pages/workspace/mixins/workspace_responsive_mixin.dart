import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/workspace_state_provider.dart';

/// Workspace 페이지의 반응형 전환 로직을 담당하는 Mixin
///
/// 이 Mixin은 다음과 같은 반응형 전환 시나리오를 처리합니다:
/// - 모바일 ↔ 웹 전환: 뷰 상태 보존 및 복원
/// - Narrow Desktop ↔ Wide Desktop 전환: 댓글 표시 모드 동기화
/// - 초기 로드 시 상태 초기화
mixin WorkspaceResponsiveMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool _previousIsMobile = false;
  bool _previousIsNarrowDesktop = false;
  bool _hasResponsiveLayoutInitialized = false;

  /// 반응형 전환 핸들러: 웹 ↔ 모바일 + Narrow Desktop 전환 시 상태 보존
  void handleResponsiveTransition(
    bool isMobile,
    bool isNarrowDesktop,
    WorkspaceStateNotifier notifier,
  ) {
    // 초회 빌드에서는 전환이 아닌 초기 상태 설정만 수행한다.
    if (!_hasResponsiveLayoutInitialized) {
      _previousIsMobile = isMobile;
      _previousIsNarrowDesktop = isNarrowDesktop;
      _hasResponsiveLayoutInitialized = true;
      return;
    }

    final isCommentsVisible = ref.read(isCommentsVisibleProvider);
    final isNarrowFullscreen = ref.read(
      workspaceIsNarrowDesktopCommentsFullscreenProvider,
    );
    final selectedPostId = ref.read(workspaceSelectedPostIdProvider);

    // 모바일 ↔ 웹 전환 처리
    if (_previousIsMobile != isMobile) {
      if (isMobile) {
        // 웹 → 모바일 전환
        notifier.handleWebToMobileTransition();
      } else {
        // 모바일 → 웹 전환
        notifier.handleMobileToWebTransition();
      }

      _previousIsMobile = isMobile;
    }

    // Narrow Desktop ↔ Wide Desktop 전환 처리
    if (!isMobile && _previousIsNarrowDesktop != isNarrowDesktop) {
      // 댓글이 열려있는 경우 narrow desktop 상태 동기화
      if (isCommentsVisible) {
        if (isNarrowDesktop && !isNarrowFullscreen) {
          // Wide → Narrow: 댓글을 전체 화면 모드로 전환
          if (selectedPostId != null) {
            notifier.showComments(
              selectedPostId,
              isNarrowDesktop: true,
            );
          }
        } else if (!isNarrowDesktop && isNarrowFullscreen) {
          // Narrow → Wide: 댓글을 사이드바 모드로 전환
          if (selectedPostId != null) {
            notifier.showComments(
              selectedPostId,
              isNarrowDesktop: false,
            );
          }
        }
      }

      _previousIsNarrowDesktop = isNarrowDesktop;
    }
  }
}
