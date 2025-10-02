import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/page_breadcrumb.dart';
import '../../core/navigation/navigation_config.dart';
import 'workspace_state_provider.dart';

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
      return _buildWorkspaceBreadcrumb(workspaceState);
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
/// - 그룹만 선택: ["워크스페이스", "그룹명"]
/// - 그룹 + 채널: ["워크스페이스", "그룹명", "채널명"]
PageBreadcrumb _buildWorkspaceBreadcrumb(WorkspaceState state) {
  final path = <String>['워크스페이스'];

  // 그룹 이름 추가 (향후 그룹 Provider에서 실제 이름 가져오기)
  if (state.selectedGroupId != null) {
    // TODO: 그룹 Provider 구현 후 실제 그룹 이름으로 대체
    final groupName = state.workspaceContext['groupName'] as String? ?? '그룹';
    path.add(groupName);
  }

  // 채널 이름 추가 (향후 채널 Provider에서 실제 이름 가져오기)
  if (state.selectedChannelId != null) {
    // TODO: 채널 Provider 구현 후 실제 채널 이름으로 대체
    final channelName = state.workspaceContext['channelName'] as String? ?? '채널';
    path.add(channelName);
  }

  return PageBreadcrumb(
    title: '워크스페이스',
    path: path,
  );
}
