import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/nav_provider.dart';
import '../../widgets/professor_pending_banner.dart';
import '../../widgets/global_sidebar.dart';
import '../home/home_tab.dart';
import '../home/workspace_tab.dart';
import '../home/activity_tab.dart';
import '../home/profile_tab.dart';

class MainNavScaffold extends StatefulWidget {
  const MainNavScaffold({super.key});

  @override
  State<MainNavScaffold> createState() => _MainNavScaffoldState();
}

class _MainNavScaffoldState extends State<MainNavScaffold> {
  static const _titles = ['홈', '워크스페이스', '나의 활동', '프로필'];

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const HomeTab(),
      const WorkspaceTab(),
      const ActivityTab(),
      const ProfileTab(),
    ];

    return Consumer2<AuthProvider, NavProvider>(
      builder: (context, auth, nav, _) {
        // AuthState가 unauthenticated가 되면 로그인 페이지로 이동
        if (auth.state == AuthState.unauthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushNamedAndRemoveUntil(
                context, '/login', (route) => false);
          });
        }

        final isDesktop = MediaQuery.of(context).size.width >= 900;

        if (isDesktop) {
          // 데스크톱: 글로벌 사이드바 + 메인 컨텐츠
          return Scaffold(
            body: Row(
              children: [
                // 글로벌 사이드바
                const GlobalSidebar(),
                // 메인 컨텐츠 영역
                Expanded(
                  child: Column(
                    children: [
                      // 상단바
                      _buildDesktopAppBar(context, nav),
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
          );
        } else {
          // 모바일: 기존 하단 네비게이션바 방식
          return Scaffold(
            appBar: _buildMobileAppBar(context, auth, nav),
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

  Widget _buildDesktopAppBar(BuildContext context, NavProvider nav) {
    return Container(
      height: 53, // 52 + 1px border
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Text(
              _titles[nav.index],
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
            ),
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
    );
  }

  PreferredSizeWidget _buildMobileAppBar(BuildContext context, AuthProvider auth, NavProvider nav) {
    return AppBar(
      toolbarHeight: 52,
      titleSpacing: 16,
      title: Text(
        _titles[nav.index],
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
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
}
