import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/nav_provider.dart';
import '../../widgets/groups/group_tree_widget.dart';
import '../../../data/models/group_model.dart';
import '../workspace/workspace_screen.dart';
import '../workspace/workspace_desktop_skeleton.dart';

class GroupExplorerScreen extends StatefulWidget {
  const GroupExplorerScreen({super.key});

  @override
  State<GroupExplorerScreen> createState() => _GroupExplorerScreenState();
}

// 디버그: 먼저 간단한 화면으로 테스트
class SimpleGroupExplorerScreen extends StatelessWidget {
  const SimpleGroupExplorerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('전체그룹 둘러보기'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups, size: 64),
            SizedBox(height: 16),
            Text(
              '전체그룹 둘러보기 화면',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 8),
            Text('화면이 성공적으로 로드되었습니다!'),
          ],
        ),
      ),
    );
  }
}

class _GroupExplorerScreenState extends State<GroupExplorerScreen> {
  String _query = '';
  int? _prevTabIndex;
  
  // New filter state
  bool _isOfficialFilterActive = false;
  bool _isAutonomousFilterActive = false;

  // Derived state for the "All" filter
  bool get _isAllFilterActive => !_isOfficialFilterActive && !_isAutonomousFilterActive;

  @override
  void initState() {
    super.initState();
    // 화면 로드 시 그룹 데이터 가져오기 후 사용자 학과/계열 경로 자동 펼침
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final groupProvider = context.read<GroupProvider>();
      final auth = context.read<AuthProvider>();
      final dept = auth.user?.department;
      final college = auth.user?.college;
      groupProvider.loadAllGroups().then((_) {
        if (dept != null && dept.isNotEmpty) {
          groupProvider.expandPathToDepartment(dept);
        } else if (college != null && college.isNotEmpty) {
          groupProvider.expandPathToCollege(college);
        } else {
          // 학과/계열 텍스트 정보가 없을 때, 내 멤버십 기준으로 자동 펼침 (계열 우선)
          groupProvider.expandToMyAffiliation(preferDepartment: false);
        }
      });
      // 하단 탭바에서 워크스페이스 탭 활성 표시
      try {
        _prevTabIndex = context.read<NavProvider>().index;
        context.read<NavProvider>().setIndex(1);
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    // 이전 탭 복구
    if (_prevTabIndex != null) {
      try { context.read<NavProvider>().setIndex(_prevTabIndex!); } catch (_) {}
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 상단 헤더: 뒤로가기 + 중앙 제목 + 우측 보조 카피
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: () => Navigator.of(context).maybePop(),
                          borderRadius: BorderRadius.circular(999),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.arrow_back_ios_new, size: 18),
                                SizedBox(width: 4),
                                Text('뒤로가기'),
                              ],
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Center(
                            child: Text('내 그룹 전체보기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: const [
                            Text('그룹 관계를 이해하고', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                            SizedBox(height: 2),
                            Text('새로운 그룹을 찾아보세요', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 검색 인풋
                    SizedBox(
                      height: 48,
                      child: TextField(
                        onChanged: (v) => setState(() => _query = v.trim()),
                        decoration: InputDecoration(
                          hintText: '그룹 검색…',
                          prefixIcon: const Icon(Icons.search),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF2563EB)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 필터 칩
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildFilterChip('전체', _isAllFilterActive, (selected) {
                          setState(() {
                            _isOfficialFilterActive = false;
                            _isAutonomousFilterActive = false;
                          });
                        }),
                        _buildFilterChip('공식', _isOfficialFilterActive, (selected) {
                          setState(() {
                            _isOfficialFilterActive = selected;
                          });
                        }),
                        _buildFilterChip('자율', _isAutonomousFilterActive, (selected) {
                          setState(() {
                            _isAutonomousFilterActive = selected;
                          });
                        }),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            // 본문: 바깥 파란 테두리, 중첩 카드는 위젯에서 처리
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Consumer<GroupProvider>(
                  builder: (context, groupProvider, child) {
                    if (groupProvider.isLoading) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    if (groupProvider.error != null) {
                      return Column(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(height: 8),
                          Text(groupProvider.error!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(onPressed: () => groupProvider.loadAllGroups(), icon: const Icon(Icons.refresh), label: const Text('다시 시도')),
                        ],
                      );
                    }
                    if (groupProvider.groupTree.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text('등록된 그룹이 없습니다', style: TextStyle(color: Colors.grey)),
                      );
                    }
                    // 루트 컨테이너: 파란 아웃라인 박스
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF2563EB)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: GroupTreeWidget(
                        nodes: groupProvider.groupTree,
                        onNodeTap: (node) => _handleGroupTap(context, node),
                        onToggle: (node) => groupProvider.toggleNode(node),
                        userDepartment: context.watch<AuthProvider>().user?.department,
                        searchQuery: _query,
                        showOfficial: _isOfficialFilterActive,
                        showAutonomous: _isAutonomousFilterActive,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, ValueChanged<bool> onSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      labelStyle: TextStyle(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF111827), fontWeight: FontWeight.w600),
      backgroundColor: Colors.white,
      selectedColor: const Color(0x142563EB),
      shape: StadiumBorder(side: BorderSide(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB))),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  void _handleGroupTap(BuildContext context, GroupTreeNode node) {
    // 그룹 정보를 보여주는 모달 표시
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => GroupDetailBottomSheet(node: node),
    );
  }
}

class GroupDetailBottomSheet extends StatelessWidget {
  final GroupTreeNode node;

  const GroupDetailBottomSheet({
    super.key,
    required this.node,
  });

  @override
  Widget build(BuildContext context) {
    final group = node.group;
    
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Group Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      group.name.isNotEmpty ? group.name[0] : '?',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          group.typeDisplayName,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (group.isRecruiting)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '모집중',
                        style: TextStyle(
                          color: Colors.green[800],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Group Info
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    if (group.description != null) ...[
                      _InfoRow(
                        icon: Icons.description_outlined,
                        title: '설명',
                        content: group.description!,
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    _InfoRow(
                      icon: Icons.people_outline,
                      title: '멤버 수',
                      content: '${group.memberCount}명',
                    ),
                    
                    if (group.university != null) ...[
                      const SizedBox(height: 16),
                      _InfoRow(
                        icon: Icons.school_outlined,
                        title: '대학교',
                        content: group.university!,
                      ),
                    ],
                    
                    if (group.college != null) ...[
                      const SizedBox(height: 16),
                      _InfoRow(
                        icon: Icons.business_outlined,
                        title: '단과대학',
                        content: group.college!,
                      ),
                    ],
                    
                    if (group.department != null) ...[
                      const SizedBox(height: 16),
                      _InfoRow(
                        icon: Icons.category_outlined,
                        title: '학과/계열',
                        content: group.department!,
                      ),
                    ],
                    
                    if (group.tags.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _InfoRow(
                        icon: Icons.tag_outlined,
                        title: '태그',
                        content: group.tags.join(', '),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Action Buttons
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToGroupHome(context, group.id),
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('그룹 홈으로 이동'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }

  void _navigateToGroupHome(BuildContext context, int groupId) async {
    final groupProvider = context.read<GroupProvider>();
    final isMember = await groupProvider.checkGroupMembership(groupId);

    Navigator.of(context).pop(); // 모달 닫기

    if (isMember) {
      // 멤버라면 워크스페이스로 이동
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const WorkspaceDesktopSkeleton(),
        ),
      );
    } else {
      // 비멤버라면 그룹 소개 페이지(미구현)로 안내
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('그룹 소개 페이지로 이동 (구현 예정)')),
      );
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
