import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/nav_provider.dart';
import '../../providers/workspace_provider.dart';
import '../../widgets/professor_pending_banner.dart';
import '../../widgets/global_sidebar.dart';
import '../home/home_tab.dart';
import '../home/workspace_tab.dart';
import '../home/activity_tab.dart';
import '../home/profile_tab.dart';
import '../workspace/workspace_screen.dart';

class MainNavScaffold extends StatefulWidget {
  const MainNavScaffold({super.key});

  @override
  State<MainNavScaffold> createState() => _MainNavScaffoldState();
}

class _MainNavScaffoldState extends State<MainNavScaffold> {
  static const _titles = ['홈', '워크스페이스', '나의 활동', '프로필'];

  // 홈 탭의 그룹 탐색 상태 관리
  bool _showGroupExplorer = false;

  // 홈 탭의 워크스페이스 진입 상태 관리 (교내 그룹 탐색에서 진입)
  bool _showHomeWorkspace = false;
  int? _homeWorkspaceGroupId;
  String? _homeWorkspaceGroupName;

  // 워크스페이스 탭의 워크스페이스 진입 상태 관리
  bool _showWorkspace = false;
  int? _workspaceGroupId;
  String? _workspaceGroupName;

  void _navigateToGroupExplorer() {
    setState(() {
      _showGroupExplorer = true;
    });
  }

  void _navigateBackToHome() {
    setState(() {
      _showGroupExplorer = false;
      _showHomeWorkspace = false;
      _homeWorkspaceGroupId = null;
      _homeWorkspaceGroupName = null;
    });
  }

  void _navigateBackToHomeFromWorkspace() {
    setState(() {
      _showHomeWorkspace = false;
      _homeWorkspaceGroupId = null;
      _homeWorkspaceGroupName = null;
      // 그룹 탐색으로 복귀
      _showGroupExplorer = true;
    });
  }

  void _navigateToWorkspace(int groupId, String groupName) {
    setState(() {
      _showWorkspace = true;
      _workspaceGroupId = groupId;
      _workspaceGroupName = groupName;
    });
  }

  void _navigateToWorkspaceFromGroupExplorer(int groupId, String groupName) {
    setState(() {
      // 그룹 탐색 모드 종료
      _showGroupExplorer = false;
      // 홈 탭 내에서 워크스페이스 모드 활성화 (탭 전환 없음)
      _showHomeWorkspace = true;
      _homeWorkspaceGroupId = groupId;
      _homeWorkspaceGroupName = groupName;
    });
  }

  void _navigateBackToWorkspaceList() {
    setState(() {
      _showWorkspace = false;
      _workspaceGroupId = null;
      _workspaceGroupName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeTab(
        showGroupExplorer: _showGroupExplorer,
        showWorkspace: _showHomeWorkspace,
        workspaceGroupId: _homeWorkspaceGroupId,
        workspaceGroupName: _homeWorkspaceGroupName,
        onNavigateToGroupExplorer: _navigateToGroupExplorer,
        onNavigateBackToHome: _navigateBackToHome,
        onNavigateToWorkspace: _navigateToWorkspaceFromGroupExplorer,
        onNavigateBackFromWorkspace: _navigateBackToHomeFromWorkspace,
      ),
      WorkspaceTab(
        showWorkspace: _showWorkspace,
        workspaceGroupId: _workspaceGroupId,
        workspaceGroupName: _workspaceGroupName,
        onNavigateToWorkspace: _navigateToWorkspace,
        onNavigateBackToWorkspaceList: _navigateBackToWorkspaceList,
      ),
      const ActivityTab(),
      const ProfileTab(),
    ];

    return Consumer3<AuthProvider, NavProvider, WorkspaceProvider>(
      builder: (context, auth, nav, workspace, _) {
        // AuthState가 unauthenticated가 되면 로그인 페이지로 이동
        if (auth.state == AuthState.unauthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushNamedAndRemoveUntil(
                context, '/login', (route) => false);
          });
        }

        final isDesktop = MediaQuery.of(context).size.width >= 900;

        if (isDesktop) {
          // 데스크톱: Column으로 상단바 아래에 사이드바 배치
          return Scaffold(
            body: Column(
              children: [
                // 상단바 (전체 화면 너비)
                _buildDesktopAppBar(context, nav, workspace),
                // 하단 영역: 글로벌 사이드바 + 메인 컨텐츠
                Expanded(
                  child: Row(
                    children: [
                      // 글로벌 사이드바
                      const GlobalSidebar(),
                      // 메인 컨텐츠 영역
                      Expanded(
                        child: (nav.index == 1 && _showWorkspace && _workspaceGroupId != null) ||
                               (nav.index == 0 && _showHomeWorkspace && _homeWorkspaceGroupId != null)
                            ? _buildWorkspaceLayout()
                            : Column(
                                children: [
                                  // 페이지 컨텐츠
                                  const ProfessorPendingBanner(),
                                  Expanded(
                                    child: IndexedStack(
                                      index: nav.index,
                                      children: pages,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          // 모바일: 기존 하단 네비게이션바 방식
          return Scaffold(
            appBar: _buildMobileAppBar(context, auth, nav, workspace),
            body: Column(
              children: [
                const ProfessorPendingBanner(),
                Expanded(child: IndexedStack(index: nav.index, children: pages)),
              ],
            ),
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: nav.index,
              onTap: (i) {
                context.read<NavProvider>().setIndex(i);
              },
              selectedItemColor: const Color(0xFF2563EB),
              unselectedItemColor: const Color(0xFF6B7280),
              showUnselectedLabels: false,
              items: const [
                BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined), label: '홈'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.workspaces_outline), label: '워크스페이스'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.history), label: '나의 활동'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline), label: '프로필'),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildDesktopAppBar(BuildContext context, NavProvider nav, WorkspaceProvider workspace) {
    // 뒤로가기 버튼을 숨겨야 하는 경우: 홈 탭의 기본 상태
    final isHomeDefaultState = nav.index == 0 && !_showGroupExplorer && !_showHomeWorkspace;
    final shouldShowBackButton = !isHomeDefaultState;

    // 현재 상태 판별을 위한 조건들
    final isGroupExplorerMode = nav.index == 0 && _showGroupExplorer;
    final isWorkspaceMode = (nav.index == 1 && _showWorkspace) || (nav.index == 0 && _showHomeWorkspace);
    final isHomeWorkspaceMode = nav.index == 0 && _showHomeWorkspace;

    return Container(
      height: 53, // 52 + 1px border
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      child: Row(
        children: [
          // 뒤로가기 버튼
          if (shouldShowBackButton)
            Container(
              width: 60, // GlobalSidebar.width와 동일
              child: IconButton(
                icon: const Icon(Icons.arrow_back, size: 20),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                onPressed: isGroupExplorerMode
                    ? _navigateBackToHome
                    : isHomeWorkspaceMode
                        ? _navigateBackToHomeFromWorkspace
                        : isWorkspaceMode
                            ? _navigateBackToWorkspaceList
                            : () => nav.setIndex(0),
                tooltip: isGroupExplorerMode
                    ? '홈으로'
                    : isHomeWorkspaceMode
                        ? '그룹 탐색으로'
                        : isWorkspaceMode
                            ? '워크스페이스로'
                            : '홈으로',
              ),
            )
          else
            const SizedBox(width: 60), // 공간 확보

          // 메인 컨텐츠 영역
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (isGroupExplorerMode) ...[
                    // 그룹 탐색 모드 제목
                    Text(
                      '교내 그룹 탐색',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(width: 16),
                    // 그룹 탐색 설명
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '그룹 관계를 이해하고',
                          style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                        ),
                        Text(
                          '새로운 그룹을 찾아보세요',
                          style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ] else if (isWorkspaceMode) ...[
                    // 워크스페이스 사이드바 영역 (그룹명 표시)
                    Container(
                      width: 200, // workspaceSidebarWidth와 동일
                      child: Row(
                        children: [
                          Icon(
                            Icons.groups,
                            size: 16,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isHomeWorkspaceMode ? (_homeWorkspaceGroupName ?? '') : (_workspaceGroupName ?? ''),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).primaryColor,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 워크스페이스 메인 타이틀 (현재 채널에 따라 동적 변경)
                    Text(
                      workspace.currentChannel?.name ?? '공지사항',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ] else ...[
                    // 기본 모드 제목
                    Text(
                      _titles[nav.index],
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.notifications_none, size: 20),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    onPressed: () {},
                    tooltip: '알림',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildMobileAppBar(BuildContext context, AuthProvider auth, NavProvider nav, WorkspaceProvider workspace) {
    // 뒤로가기 버튼을 숨겨야 하는 경우: 홈 탭의 기본 상태
    final isHomeDefaultState = nav.index == 0 && !_showGroupExplorer && !_showHomeWorkspace;
    final shouldShowBackButton = !isHomeDefaultState;

    // 현재 상태 판별을 위한 조건들
    final isGroupExplorerMode = nav.index == 0 && _showGroupExplorer;
    final isHomeWorkspaceMode = nav.index == 0 && _showHomeWorkspace;
    final isWorkspaceTabMode = nav.index == 1 && _showWorkspace;
    final isWorkspaceMode = isHomeWorkspaceMode || isWorkspaceTabMode;

    // 워크스페이스 모드일 때 제목 결정
    String getTitle() {
      if (isGroupExplorerMode) {
        return '교내 그룹 탐색';
      } else if (isWorkspaceMode) {
        final groupName = isHomeWorkspaceMode ? _homeWorkspaceGroupName : _workspaceGroupName;
        final channelName = workspace.currentChannel?.name ?? '공지사항';
        return '$groupName > $channelName';
      } else {
        return _titles[nav.index];
      }
    }

    return AppBar(
      toolbarHeight: 52,
      titleSpacing: 16,
      automaticallyImplyLeading: false,
      leading: shouldShowBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back, size: 20),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: isGroupExplorerMode
                  ? _navigateBackToHome
                  : isHomeWorkspaceMode
                      ? _navigateBackToHomeFromWorkspace
                      : isWorkspaceTabMode
                          ? _navigateBackToWorkspaceList
                          : () => nav.setIndex(0),
              tooltip: isGroupExplorerMode
                  ? '홈으로'
                  : isHomeWorkspaceMode
                      ? '그룹 탐색으로'
                      : isWorkspaceTabMode
                          ? '워크스페이스로'
                          : '홈으로',
            )
          : null,
      title: Text(
        getTitle(),
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: IconButton(
            icon: const Icon(Icons.logout, size: 20),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: auth.isLoading
                ? null
                : () => _showLogoutDialog(context, auth),
            tooltip: '로그아웃',
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(right: 14, left: 4, top: 12, bottom: 12),
          child: Icon(Icons.notifications_none, size: 20),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFE5E7EB)),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await auth.logout();
              if (success && context.mounted) {
                // 로그아웃 성공 시 즉시 로그인 페이지로 이동
                Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (route) => false);
              } else if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(auth.error ?? '로그아웃에 실패했습니다.'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            },
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspaceLayout() {
    // 홈 워크스페이스와 워크스페이스 탭 워크스페이스를 구분하여 처리
    final isHomeWorkspace = _showHomeWorkspace && _homeWorkspaceGroupId != null;
    final groupId = isHomeWorkspace ? _homeWorkspaceGroupId! : _workspaceGroupId!;
    final groupName = isHomeWorkspace ? _homeWorkspaceGroupName : _workspaceGroupName;
    final onBack = isHomeWorkspace ? _navigateBackToHomeFromWorkspace : _navigateBackToWorkspaceList;

    return Column(
      children: [
        // 페이지 컨텐츠
        const ProfessorPendingBanner(),
        Expanded(
          child: WorkspaceContent(
            groupId: groupId,
            groupName: groupName,
            onBack: onBack,
          ),
        ),
      ],
    );
  }
}
