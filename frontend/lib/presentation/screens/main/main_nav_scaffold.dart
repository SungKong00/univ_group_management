import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/nav_provider.dart';
import '../../widgets/professor_pending_banner.dart';
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
            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
          });
        }

        return Scaffold(
      appBar: AppBar(
        title: Text(_titles[nav.index]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: auth.isLoading ? null : () => _showLogoutDialog(context, auth),
            tooltip: '로그아웃',
          ),
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(Icons.notifications_none),
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE5E7EB)),
        ),
      ),
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
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.workspaces_outline), label: '워크스페이스'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: '나의 활동'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: '프로필'),
        ],
      ),
    );
      },
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
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
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












