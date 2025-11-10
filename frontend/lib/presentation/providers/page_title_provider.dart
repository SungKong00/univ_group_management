import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/channel_models.dart';
import '../../core/models/page_breadcrumb.dart';
import '../../core/navigation/layout_mode.dart';
import '../../core/navigation/navigation_config.dart';
import 'home_state_provider.dart';
import 'my_groups_provider.dart';
import 'workspace_state_provider.dart';

/// 요청 컨텍스트별로 페이지 브레드크럼을 계산하기 위한 값 객체.
class PageBreadcrumbRequest extends Equatable {
  const PageBreadcrumbRequest({
    required this.routePath,
    required this.layoutMode,
  });

  /// 현재 라우트 경로 (예: `/workspace/1`).
  final String routePath;

  /// 현재 레이아웃 모드. 반응형 전환 시 브레드크럼 표현이 달라진다.
  final LayoutMode layoutMode;

  @override
  List<Object?> get props => [routePath, layoutMode];
}

/// 현재 페이지의 브레드크럼을 제공하는 Provider (경로 기반)
///
/// 라우트 경로와 워크스페이스 상태를 결합하여 동적으로 브레드크럼을 생성합니다.
/// - 일반 페이지: 단순 제목만 표시
/// - 워크스페이스: "워크스페이스 > [그룹명] > [채널명]" 형태로 표시
///
/// autoDispose를 사용하여 라우트 변경 시 캐시를 자동으로 해제합니다.
///
/// 사용 예시:
/// ```dart
/// final breadcrumb = ref.watch(
///   pageBreadcrumbFromPathProvider(
///     const PageBreadcrumbRequest(
///       routePath: '/home',
///       layoutMode: LayoutMode.wide,
///     ),
///   ),
/// );
/// // PageBreadcrumb(title: "홈")
///
/// final breadcrumb = ref.watch(
///   pageBreadcrumbFromPathProvider(
///     const PageBreadcrumbRequest(
///       routePath: '/workspace',
///       layoutMode: LayoutMode.compact,
///     ),
///   ),
/// );
/// // PageBreadcrumb(title: "워크스페이스", path: ["워크스페이스", "컴퓨터공학과", "공지사항"])
/// ```
final pageBreadcrumbFromPathProvider = Provider.autoDispose
    .family<PageBreadcrumb, PageBreadcrumbRequest>((ref, request) {
      final routePath = request.routePath;
      final layoutMode = request.layoutMode;

      // 경로가 비어있으면 기본값
      if (routePath.isEmpty || routePath == '/') {
        return const PageBreadcrumb(title: '대학 그룹 관리');
      }

      // 특수 케이스: 홈
      if (routePath == '/home') {
        final homeView = ref.watch(currentHomeViewProvider);

        switch (homeView) {
          case HomeView.dashboard:
            return const PageBreadcrumb(title: '홈');
          case HomeView.groupExplore:
            return const PageBreadcrumb(title: '홈 > 그룹탐색', path: ['홈', '그룹탐색']);
        }
      }

      // 특수 케이스: 워크스페이스
      if (routePath.startsWith('/workspace')) {
        final currentView = ref.watch(workspaceCurrentViewProvider);
        final mobileView = ref.watch(workspaceMobileViewProvider);
        final isNarrowCommentsFullscreen = ref.watch(
          workspaceIsNarrowDesktopCommentsFullscreenProvider,
        );
        final selectedPostId = ref.watch(workspaceSelectedPostIdProvider);
        final selectedChannelId = ref.watch(currentChannelIdProvider);
        final channels = ref.watch(workspaceChannelsProvider);
        final selectedGroupId = ref.watch(currentGroupIdProvider);

        // 그룹 정보 가져오기
        final groupsAsync = ref.watch(myGroupsProvider);
        final groupName = groupsAsync.maybeWhen(
          data: (groups) {
            if (selectedGroupId == null) return null;
            final currentGroup = groups.firstWhere(
              (g) => g.id.toString() == selectedGroupId,
              orElse: () => groups.first,
            );
            return currentGroup.name;
          },
          orElse: () => null,
        );

        return _buildWorkspaceBreadcrumb(
          context: WorkspaceBreadcrumbContext(
            currentView: currentView,
            mobileView: mobileView,
            isNarrowDesktopCommentsFullscreen: isNarrowCommentsFullscreen,
            selectedPostId: selectedPostId,
            selectedChannelId: selectedChannelId,
            channels: channels,
          ),
          groupName: groupName,
          layoutMode: layoutMode,
        );
      }

      // 특수 케이스: 로그인/온보딩
      if (routePath == '/login') {
        return const PageBreadcrumb(title: '로그인');
      }
      if (routePath == '/onboarding') {
        return const PageBreadcrumb(title: '프로필 설정');
      }

      // 특수 케이스: 모집 공고 상세 페이지
      if (routePath.startsWith('/recruitment/')) {
        return const PageBreadcrumb(title: '모집 공고');
      }

      // 일반 케이스: NavigationConfig에서 제목 가져오기
      final config = NavigationConfig.fromRoute(routePath);
      if (config != null) {
        return PageBreadcrumb(title: config.title);
      }

      // 폴백: 기본 제목
      return const PageBreadcrumb(title: '대학 그룹 관리');
    });

/// 워크스페이스 브레드크럼 생성
///
/// 워크스페이스 상태에 따라 동적으로 경로를 구성합니다.
/// - 데스크톱: "워크스페이스 > 그룹명 (> 채널명)"
/// - 모바일: 뷰 타입별 최적화된 표시 (channelList: "워크스페이스", channelPosts: "그룹명 > 채널명", postComments: "댓글")
PageBreadcrumb _buildWorkspaceBreadcrumb({
  required WorkspaceBreadcrumbContext context,
  String? groupName,
  required LayoutMode layoutMode,
}) {
  final displayGroupName = groupName ?? '그룹';

  if (layoutMode.isCompact) {
    return _buildMobileBreadcrumb(context, displayGroupName);
  }

  return _buildDesktopBreadcrumb(context);
}

/// 데스크톱 브레드크럼 생성: "워크스페이스 > 그룹명"
PageBreadcrumb _buildDesktopBreadcrumb(WorkspaceBreadcrumbContext context) {
  final isCommentOverlayActive =
      context.isNarrowDesktopCommentsFullscreen &&
      context.selectedPostId != null &&
      context.currentView == WorkspaceView.channel;

  if (isCommentOverlayActive) {
    return const PageBreadcrumb(title: '댓글');
  }

  switch (context.currentView) {
    case WorkspaceView.groupAdmin:
      return const PageBreadcrumb(title: '그룹 관리');
    case WorkspaceView.memberManagement:
      return const PageBreadcrumb(title: '멤버 관리');
    case WorkspaceView.channelManagement:
      return const PageBreadcrumb(title: '채널 관리');
    case WorkspaceView.recruitmentManagement:
      return const PageBreadcrumb(title: '모집 관리');
    case WorkspaceView.applicationManagement:
      return const PageBreadcrumb(title: '지원자 관리');
    case WorkspaceView.placeTimeManagement:
      return const PageBreadcrumb(title: '장소 시간 관리');
    case WorkspaceView.calendar:
      return const PageBreadcrumb(title: '캘린더');
    case WorkspaceView.groupHome:
      return const PageBreadcrumb(title: '그룹 홈');
    case WorkspaceView.channel:
      return const PageBreadcrumb(title: '워크스페이스');
  }
}

/// 모바일 브레드크럼 생성: 화면별 최적화된 표시
///
/// - 채널 목록: "워크스페이스"
/// - 게시글 목록: "그룹명 > 채널명/기능명"
/// - 댓글 화면: "댓글"
PageBreadcrumb _buildMobileBreadcrumb(
  WorkspaceBreadcrumbContext context,
  String groupName,
) {
  // 특수 뷰(관리자/멤버/모집 관리)는 전용 타이틀을 우선 표시
  if (context.currentView == WorkspaceView.groupAdmin) {
    return const PageBreadcrumb(title: '그룹 관리', path: ['그룹 관리']);
  }
  if (context.currentView == WorkspaceView.memberManagement) {
    return const PageBreadcrumb(title: '멤버 관리', path: ['멤버 관리']);
  }
  if (context.currentView == WorkspaceView.channelManagement) {
    return const PageBreadcrumb(title: '채널 관리', path: ['채널 관리']);
  }
  if (context.currentView == WorkspaceView.recruitmentManagement) {
    return const PageBreadcrumb(title: '모집 관리', path: ['모집 관리']);
  }
  if (context.currentView == WorkspaceView.applicationManagement) {
    return const PageBreadcrumb(title: '지원자 관리', path: ['지원자 관리']);
  }
  if (context.currentView == WorkspaceView.placeTimeManagement) {
    return const PageBreadcrumb(title: '장소 시간 관리', path: ['장소 시간 관리']);
  }

  // 현재 뷰 타입에 따라 브레드크럼 형식 결정
  switch (context.mobileView) {
    case MobileWorkspaceView.channelList:
      // 채널 목록: "워크스페이스"만 표시
      return const PageBreadcrumb(title: '워크스페이스', path: ['워크스페이스']);

    case MobileWorkspaceView.channelPosts:
      // 채널 게시글 목록: "그룹명 > 채널명/기능명"
      final path = <String>[groupName];

      if (context.currentView == WorkspaceView.groupHome) {
        path.add('홈');
      } else if (context.currentView == WorkspaceView.calendar) {
        path.add('캘린더');
      } else if (context.selectedChannelId != null) {
        // 실제 채널 이름 가져오기
        final channelName = _getChannelName(
          context.channels,
          context.selectedChannelId!,
        );
        if (channelName.isNotEmpty) {
          path.add(channelName);
        }
      }

      return PageBreadcrumb(title: '', path: path);

    case MobileWorkspaceView.postComments:
      // 댓글 화면: "댓글"만 표시
      return const PageBreadcrumb(title: '댓글', path: ['댓글']);
  }
}

/// 채널 ID로 실제 채널 이름 가져오기
String _getChannelName(List<Channel> channels, String channelId) {
  try {
    final channel = channels.firstWhere((ch) => ch.id.toString() == channelId);
    return channel.name;
  } catch (e) {
    // 채널을 찾지 못한 경우 빈 문자열 반환 (경로에 추가되지 않음)
    return '';
  }
}

class WorkspaceBreadcrumbContext {
  const WorkspaceBreadcrumbContext({
    required this.currentView,
    required this.mobileView,
    required this.isNarrowDesktopCommentsFullscreen,
    required this.selectedPostId,
    required this.selectedChannelId,
    required this.channels,
  });

  final WorkspaceView currentView;
  final MobileWorkspaceView mobileView;
  final bool isNarrowDesktopCommentsFullscreen;
  final String? selectedPostId;
  final String? selectedChannelId;
  final List<Channel> channels;
}
