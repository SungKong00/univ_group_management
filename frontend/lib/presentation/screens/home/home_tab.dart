import 'package:flutter/material.dart';
import '../../widgets/common/skeleton_ui.dart';
import '../../widgets/common/section_card.dart';
import '../groups/group_explorer_screen.dart';
import '../workspace/workspace_screen.dart';

class HomeTab extends StatelessWidget {
  final bool showGroupExplorer;
  final bool showWorkspace;
  final int? workspaceGroupId;
  final String? workspaceGroupName;
  final VoidCallback? onNavigateToGroupExplorer;
  final VoidCallback? onNavigateBackToHome;
  final void Function(int groupId, String groupName)? onNavigateToWorkspace;
  final VoidCallback? onNavigateBackFromWorkspace;

  const HomeTab({
    super.key,
    required this.showGroupExplorer,
    required this.showWorkspace,
    this.workspaceGroupId,
    this.workspaceGroupName,
    this.onNavigateToGroupExplorer,
    this.onNavigateBackToHome,
    this.onNavigateToWorkspace,
    this.onNavigateBackFromWorkspace,
  });

  @override
  Widget build(BuildContext context) {
    if (showGroupExplorer) {
      return GroupExplorerContent(
        onBack: onNavigateBackToHome,
        onNavigateToWorkspace: onNavigateToWorkspace,
      );
    }

    if (showWorkspace && workspaceGroupId != null) {
      return WorkspaceContent(
        groupId: workspaceGroupId!,
        groupName: workspaceGroupName,
        onBack: onNavigateBackFromWorkspace,
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GroupSwitcherCard(onNavigateToGroupExplorer: onNavigateToGroupExplorer),
            const SizedBox(height: 16),
            const SectionCard(
              title: '최근 활동',
              isLoading: true,
              skeletonCount: 3,
            ),
            const SizedBox(height: 12),
            const SectionCard(
              title: '인기 그룹',
              isLoading: true,
              skeletonCount: 3,
            ),
            const SizedBox(height: 12),
            const SectionCard(
              title: '내 워크스페이스',
              isLoading: true,
              skeletonCount: 3,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class GroupSwitcherCard extends StatefulWidget {
  final VoidCallback? onNavigateToGroupExplorer;

  const GroupSwitcherCard({super.key, this.onNavigateToGroupExplorer});

  @override
  State<GroupSwitcherCard> createState() => _GroupSwitcherCardState();
}

class _GroupSwitcherCardState extends State<GroupSwitcherCard> {
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
                  child: Text(
                    '그룹',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: widget.onNavigateToGroupExplorer,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: const Text('전체 그룹 보기 ›'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Segmented switch for accessibility
            SizedBox(
              height: 32,
              child: Row(
                children: [
                  _buildSegment('내 그룹', 0),
                  const SizedBox(width: 8),
                  _buildSegment('추천', 1),
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
                  SkeletonUI.dot(active: _index == 0),
                  const SizedBox(width: 6),
                  SkeletonUI.dot(active: _index == 1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegment(String label, int idx) {
    final active = _index == idx;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() => _index = idx);
          _controller.animateToPage(
            idx,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
          );
        },
        child: Container(
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? const Color(0x142563EB) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? const Color(0xFF2563EB) : const Color(0xFF111827),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _MyGroupsPage extends StatelessWidget {
  const _MyGroupsPage();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '내가 속한 그룹을 빠르게 확인해요.',
          style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            itemBuilder: (_, i) => SkeletonUI.chipSkeleton(),
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemCount: 5,
          ),
        ),
        const SizedBox(height: 8),
        SkeletonUI.activitySkeleton('새 게시 3 · 2시간 전'),
      ],
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
        const Text(
          '관심사에 맞춰 골라 보세요.',
          style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 8),
        _buildRecommendTile(joined: false),
        const SizedBox(height: 4),
        _buildRecommendTile(joined: true),
      ],
    );
  }

  Widget _buildRecommendTile({bool joined = false}) {
    return SizedBox(
      height: 24,
      child: Row(
        children: [
          const CircleAvatar(radius: 12, backgroundColor: Color(0xFFD1D5DB)),
          const SizedBox(width: 12),
          const Expanded(
            child: SizedBox(height: 12, width: 180),
          ),
          const SizedBox(width: 8),
          const Text(
            '주 2회 · 124명',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          if (joined)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '가입됨',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
        ],
      ),
    );
  }
}