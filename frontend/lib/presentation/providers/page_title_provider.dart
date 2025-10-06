import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/page_breadcrumb.dart';
import '../../core/navigation/navigation_config.dart';
import 'workspace_state_provider.dart';
import 'my_groups_provider.dart';

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
/// final breadcrumb = ref.watch(pageBreadcrumbFromPathProvider('/home'));
/// // PageBreadcrumb(title: "홈")
///
/// final breadcrumb = ref.watch(pageBreadcrumbFromPathProvider('/workspace'));
/// // PageBreadcrumb(title: "워크스페이스", path: ["워크스페이스", "컴퓨터공학과", "공지사항"])
/// ```
final pageBreadcrumbFromPathProvider =
    Provider.autoDispose.family<PageBreadcrumb, String>(
  (ref, routePath) {
    // 워크스페이스 상태 가져오기 (변경 시 자동 재계산)
    final workspaceState = ref.watch(workspaceStateProvider);

    // 경로가 비어있으면 기본값
    if (routePath.isEmpty || routePath == '/') {
      return const PageBreadcrumb(title: '대학 그룹 관리');
    }

    // 특수 케이스: 워크스페이스
    if (routePath.startsWith('/workspace')) {
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

      return _buildWorkspaceBreadcrumb(workspaceState, groupName);
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
PageBreadcrumb _buildWorkspaceBreadcrumb(WorkspaceState state, String? groupName) {
  // 그룹 이름 fallback
  final displayGroupName = groupName ?? '그룹';

  // 모바일 뷰인 경우: 뷰 타입별 최적화된 브레드크럼 생성
  // _buildMobileBreadcrumb 내부에서 모든 모바일 뷰 타입을 처리하므로 조건 없이 호출
  return _buildMobileBreadcrumb(state, displayGroupName);

  // 데스크톱 뷰는 현재 구현되지 않음 (향후 확장 시 조건 추가 필요)
  // return _buildDesktopBreadcrumb(state, displayGroupName);
}

/// 데스크톱 브레드크럼 생성: "워크스페이스 > 그룹명"
/// 현재는 모바일 우선 구현이라 데스크톱 함수가 사용되지 않음
// ignore: unused_element
PageBreadcrumb _buildDesktopBreadcrumb(WorkspaceState state, String groupName) {
  final path = <String>['워크스페이스'];

  // 그룹 이름 추가
  if (state.selectedGroupId != null) {
    path.add(groupName);
  }

  // 채널 이름 추가 (실제 채널 이름 가져오기)
  if (state.selectedChannelId != null) {
    final channelName = _getChannelName(state, state.selectedChannelId!);
    if (channelName.isNotEmpty) {
      path.add(channelName);
    }
  }

  return PageBreadcrumb(
    title: '워크스페이스',
    path: path,
  );
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
