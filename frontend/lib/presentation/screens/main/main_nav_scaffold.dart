import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/nav_provider.dart';
import '../../widgets/professor_pending_banner.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../../data/services/group_service.dart';
import '../../../data/models/group_model.dart';
import '../groups/group_explorer_screen.dart';
import '../workspace/workspace_screen.dart';

class MainNavScaffold extends StatefulWidget {
  const MainNavScaffold({super.key});

  @override
  State<MainNavScaffold> createState() => _MainNavScaffoldState();
}

class _MainNavScaffoldState extends State<MainNavScaffold> {
  int _currentIndex = 0;

  static const _titles = ['홈', '워크스페이스', '나의 활동', '프로필'];

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const HomeTabNavigator(),
      const _WorkspaceTab(),
      const _ActivityTab(),
      const _ProfileTab(),
    ];

    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // AuthState가 unauthenticated가 되면 로그인 페이지로 이동
        if (auth.state == AuthState.unauthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
          });
        }

        return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
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
          Expanded(child: IndexedStack(index: _currentIndex, children: pages)),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: context.watch<NavProvider>().index,
        onTap: (i) {
          context.read<NavProvider>().setIndex(i);
          setState(() => _currentIndex = i);
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

// 하단바 유지용: 홈 탭 전용 중첩 네비게이터
class HomeTabNavigator extends StatelessWidget {
  const HomeTabNavigator({super.key});
  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) {
        return MaterialPageRoute(builder: (_) => const _HomeTab());
      },
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            _GroupSwitcherCard(),
            SizedBox(height: 16),
            _SectionListSkeleton(title: '최근 활동'),
            SizedBox(height: 12),
            _SectionListSkeleton(title: '인기 그룹'),
            SizedBox(height: 12),
            _SectionListSkeleton(title: '내 워크스페이스'),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

Widget _skeletonTile() {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(8))),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(height: 12, color: Colors.black12),
            const SizedBox(height: 6),
            Container(height: 10, width: 140, color: Colors.black12),
          ]),
        )
      ],
    ),
  );
}

Widget _bigBottomCard() {
  return SizedBox(
    width: double.infinity,
    height: 200,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 16, width: 180, color: Colors.black12),
            const SizedBox(height: 12),
            Expanded(child: Container(color: Colors.black12)),
          ],
        ),
      ),
    ),
  );
}

class _ExploreList extends StatefulWidget {
  const _ExploreList();
  @override
  State<_ExploreList> createState() => _ExploreListState();
}

class _ExploreListState extends State<_ExploreList> {
  late final GroupService _service;
  List<GroupSummaryModel> _groups = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // Build a DioClient using shared prefs storage so JWT is attached
    _service = GroupService(DioClient(SharedPrefsTokenStorage()));
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _service.explore(page: 0, size: 10);
      if (!mounted) return;
      if (res.isSuccess && res.data != null) {
        setState(() {
          _groups = res.data!.content;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Column(
        children: List.generate(6, (_) => _skeletonTile()),
      );
    }
    if (_groups.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('표시할 그룹이 없습니다'),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _groups.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final g = _groups[index];
        return ListTile(
          leading: g.profileImageUrl != null
              ? CircleAvatar(backgroundImage: NetworkImage(g.profileImageUrl!))
              : const CircleAvatar(child: Icon(Icons.groups)),
          title: Text(g.name),
          subtitle: Text(g.description ?? '${g.university ?? ''} ${g.college ?? ''} ${g.department ?? ''}'),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            if (g.isRecruiting)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                child: const Text('모집중', style: TextStyle(color: Colors.green)),
              ),
            const SizedBox(width: 8),
            Text('${g.memberCount}명'),
          ]),
          onTap: () {},
        );
      },
    );
  }
}

// --- Group card with swipe between "내 그룹" and "추천" ---
class _GroupSwitcherCard extends StatefulWidget {
  const _GroupSwitcherCard();
  @override
  State<_GroupSwitcherCard> createState() => _GroupSwitcherCardState();
}

class _GroupSwitcherCardState extends State<_GroupSwitcherCard> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('그룹', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const GroupExplorerScreen()),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: const Text('전체 그룹 보기 ›'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Optional segmented switch for accessibility
            SizedBox(
              height: 32,
              child: Row(
                children: [
                  _seg('내 그룹', 0),
                  const SizedBox(width: 8),
                  _seg('추천', 1),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 96,
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _index = i),
                children: const [
                  _MyGroupsPage(),
                  _RecommendPage(),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _dot(active: _index == 0),
                  const SizedBox(width: 6),
                  _dot(active: _index == 1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _seg(String label, int idx) {
    final active = _index == idx;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() => _index = idx);
          _controller.animateToPage(idx, duration: const Duration(milliseconds: 180), curve: Curves.easeOut);
        },
        child: Container(
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? const Color(0x142563EB) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Text(label, style: TextStyle(color: active ? const Color(0xFF2563EB) : const Color(0xFF111827), fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ),
    );
  }

  static Widget _dot({required bool active}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? const Color(0xFF2563EB) : const Color(0xFFD1D5DB),
      ),
    );
  }
}

class _MyGroupsPage extends StatelessWidget {
  const _MyGroupsPage();
  @override
  Widget build(BuildContext context) {
    // Skeleton state (no data wired yet) — compact within 84px height
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('내가 속한 그룹을 빠르게 확인해요.', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            itemBuilder: (_, i) => _chipSkeleton(),
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemCount: 5,
          ),
        ),
        const SizedBox(height: 8),
        _activitySkeleton('새 게시 3 · 2시간 전'),
      ],
    );
  }

  Widget _chipSkeleton() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(width: 24, height: 24, decoration: const BoxDecoration(color: Color(0xFFD1D5DB), shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Container(width: 72, height: 12, color: const Color(0xFFD1D5DB)),
        ],
      ),
    );
  }

  Widget _activitySkeleton(String meta) {
    return SizedBox(
      height: 20,
      child: Row(
        children: [
          const Icon(Icons.bolt_outlined, size: 20, color: Color(0xFF6B7280)),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(height: 12, width: 160, color: const Color(0xFFD1D5DB)),
            ),
          )
        ],
      ),
    );
  }
}

class _RecommendPage extends StatelessWidget {
  const _RecommendPage();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('관심사에 맞춰 골라 보세요.', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        const SizedBox(height: 8),
        // Compact: 2 tiles to avoid overflow
        _recommendTileSkeleton(joined: false),
        const SizedBox(height: 4),
        _recommendTileSkeleton(joined: true),
      ],
    );
  }

  Widget _recommendTileSkeleton({bool joined = false}) {
    return SizedBox(
      height: 24,
      child: Row(
      children: [
        const CircleAvatar(radius: 12, backgroundColor: Color(0xFFD1D5DB)),
        const SizedBox(width: 12),
        Expanded(
          child: Row(children: const [
            Expanded(child: SizedBox(height: 12, width: 180)),
            SizedBox(width: 8),
            Text('주 2회 · 124명', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          ]),
        ),
        if (joined)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(8)),
            child: const Text('가입됨', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          ),
        const SizedBox(width: 8),
        const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
      ],
      ),
    );
  }
}

class _SectionListSkeleton extends StatelessWidget {
  final String title;
  const _SectionListSkeleton({required this.title});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.04),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE5E7EB))),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF2563EB), padding: const EdgeInsets.symmetric(horizontal: 8)),
                  child: const Text('모두 보기'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...List.generate(3, (_) => _skeletonTile()),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceTab extends StatefulWidget {
  const _WorkspaceTab();
  @override
  State<_WorkspaceTab> createState() => _WorkspaceTabState();
}

class _WorkspaceTabState extends State<_WorkspaceTab> {
  late final GroupService _service;
  List<GroupSummaryModel> _myGroups = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service = GroupService(DioClient(SharedPrefsTokenStorage()));
    _loadMyGroups();
  }

  Future<void> _loadMyGroups() async {
    try {
      // TODO: 내가 속한 그룹 목록을 가져오는 API 호출
      // 현재는 모든 그룹을 가져옴 (임시)
      final res = await _service.explore(page: 0, size: 20);
      if (!mounted) return;
      if (res.isSuccess && res.data != null) {
        setState(() {
          _myGroups = res.data!.content;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myGroups.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.workspaces_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              '아직 참여한 그룹이 없습니다',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '그룹 탐색에서 원하는 그룹을 찾아보세요',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final group = _myGroups[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: group.profileImageUrl != null
                ? NetworkImage(group.profileImageUrl!)
                : null,
            child: group.profileImageUrl == null
                ? const Icon(Icons.group_work)
                : null,
          ),
          title: Text(group.name),
          subtitle: Text(group.description ?? '${group.university ?? ''} ${group.department ?? ''}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (group.isRecruiting)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '모집중',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 10,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
          onTap: () {
            // 워크스페이스 화면으로 이동
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WorkspaceScreen(groupId: group.id),
              ),
            );
          },
        );
      },
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemCount: _myGroups.length,
    );
  }
}

class _ActivityTab extends StatelessWidget {
  const _ActivityTab();
  @override
  Widget build(BuildContext context) {
    // Skeleton list of recent activities
    final activities = List.generate(12, (i) => '활동 항목 ${i + 1}');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        return ListTile(
          leading: const Icon(Icons.notifications_none),
          title: Text(activities[index]),
          subtitle: const Text('최근 알림/변경사항에 대한 설명'),
          onTap: () {},
        );
      },
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemCount: activities.length,
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('프로필'),
    );
  }
}
