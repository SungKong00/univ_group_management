import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/page_breadcrumb.dart';
import '../../core/navigation/layout_mode.dart';
import '../../core/navigation/navigation_config.dart';
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
final pageBreadcrumbFromPathProvider =
    Provider.autoDispose.family<PageBreadcrumb, PageBreadcrumbRequest>(
  (ref, request) {
    final routePath = request.routePath;
    final layoutMode = request.layoutMode;

    // 경로가 비어있으면 기본값
    if (routePath.isEmpty || routePath == '/') {
      return const PageBreadcrumb(title: '대학 그룹 관리');
    }

    // 특수 케이스: 워크스페이스
    if (routePath.startsWith('/workspace')) {
      final workspaceState = ref.watch(workspaceStateProvider);
      // 그룹 정보 가져오기
      final groupsAsync = ref.watch(myGroupsProvider);
      final groupName = groupsAsync.maybeWhen(
        data: (groups) {
          if (workspaceState.selectedGroupId == null) return null;
          final currentGroup = groups.firstWhere(
            (g) => g.id.toString() == workspaceState.selectedGroupId,
            orElse: () => groups.first,
          );
          return currentGroup.name;
        },
        orElse: () => null,
      );

      return _buildWorkspaceBreadcrumb(
        state: workspaceState,
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

    // 일반 케이스: NavigationConfig에서 제목 가져오기
    final config = NavigationConfig.fromRoute(routePath);
    if (config != null) {
      return PageBreadcrumb(title: config.title);
    }

    // 폴백: 기본 제목
    return const PageBreadcrumb(title: '대학 그룹 관리');
  },
);

/// 워크스페이스 브레드크럼 생성
///
/// 워크스페이스 상태에 따라 동적으로 경로를 구성합니다.
/// - 데스크톱: "워크스페이스 > 그룹명 (> 채널명)"
/// - 모바일: 뷰 타입별 최적화된 표시 (channelList: "워크스페이스", channelPosts: "그룹명 > 채널명", postComments: "댓글")
PageBreadcrumb _buildWorkspaceBreadcrumb({
  required WorkspaceState state,
  String? groupName,
  required LayoutMode layoutMode,
}) {
  final displayGroupName = groupName ?? '그룹';

  if (layoutMode.isCompact) {
    return _buildMobileBreadcrumb(state, displayGroupName);
  }

  return _buildDesktopBreadcrumb(state);
}

/// 데스크톱 브레드크럼 생성: "워크스페이스 > 그룹명"
PageBreadcrumb _buildDesktopBreadcrumb(WorkspaceState state) {
  if (state.isNarrowDesktopCommentsFullscreen && state.selectedPostId != null) {
    return const PageBreadcrumb(title: '댓글');
  }

  switch (state.currentView) {
    case WorkspaceView.groupAdmin:
      return const PageBreadcrumb(title: '그룹 관리');
    case WorkspaceView.memberManagement:
      return const PageBreadcrumb(title: '멤버 관리');
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
PageBreadcrumb _buildMobileBreadcrumb(WorkspaceState state, String groupName) {
  // 현재 뷰 타입에 따라 브레드크럼 형식 결정
  switch (state.mobileView) {
    case MobileWorkspaceView.channelList:
      // 채널 목록: "워크스페이스"만 표시
      return const PageBreadcrumb(
        title: '워크스페이스',
        path: ['워크스페이스'],
      );

    case MobileWorkspaceView.channelPosts:
      // 채널 게시글 목록: "그룹명 > 채널명/기능명"
      final path = <String>[groupName];

      if (state.currentView == WorkspaceView.groupHome) {
        path.add('홈');
      } else if (state.currentView == WorkspaceView.calendar) {
        path.add('캘린더');
      } else if (state.selectedChannelId != null) {
        // 실제 채널 이름 가져오기
        final channelName = _getChannelName(state, state.selectedChannelId!);
        if (channelName.isNotEmpty) {
          path.add(channelName);
        }
      }

      return PageBreadcrumb(
        title: '',
        path: path,
      );

    case MobileWorkspaceView.postComments:
      // 댓글 화면: "댓글"만 표시
      return const PageBreadcrumb(
        title: '댓글',
        path: ['댓글'],
      );
  }
}

/// 채널 ID로 실제 채널 이름 가져오기
String _getChannelName(WorkspaceState state, String channelId) {
  try {
    final channel = state.channels.firstWhere(
      (ch) => ch.id.toString() == channelId,
    );
    return channel.name;
  } catch (e) {
    // 채널을 찾지 못한 경우 빈 문자열 반환 (경로에 추가되지 않음)
    return '';
  }
}
