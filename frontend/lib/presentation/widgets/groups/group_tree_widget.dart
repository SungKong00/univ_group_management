import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/group_model.dart';
import '../../providers/group_provider.dart';
import '../../screens/workspace/workspace_screen.dart';

class GroupTreeWidget extends StatelessWidget {
  final List<GroupTreeNode> nodes;
  final Function(GroupTreeNode) onNodeTap;
  final Function(GroupTreeNode) onToggle;
  final String? userDepartment;
  final String? searchQuery;
  final bool showOfficial;
  final bool showAutonomous;

  const GroupTreeWidget({
    super.key,
    required this.nodes,
    required this.onNodeTap,
    required this.onToggle,
    this.userDepartment,
    this.searchQuery,
    required this.showOfficial,
    required this.showAutonomous,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = _filterNodes(nodes, (searchQuery ?? '').trim());
    return Column(
      children: filtered.map((node) =>
          GroupTreeNodeWidget(
            node: node,
            level: 0,
            onNodeTap: onNodeTap,
            onToggle: onToggle,
            userDepartment: userDepartment,
            searchQuery: searchQuery,
            showOfficial: showOfficial,
            showAutonomous: showAutonomous,
          )
      ).toList(),
    );
  }

  List<GroupTreeNode> _filterNodes(List<GroupTreeNode> list, String q) {
    if (q.isEmpty) return list;
    bool matchNode(GroupTreeNode n) {
      final name = n.group.name.toLowerCase();
      final dept = (n.group.department ?? '').toLowerCase();
      final qq = q.toLowerCase();
      return name.contains(qq) || dept.contains(qq);
    }
    GroupTreeNode? filterRec(GroupTreeNode n) {
      final filteredChildren = n.children.map(filterRec).whereType<GroupTreeNode>().toList();
      if (matchNode(n) || filteredChildren.isNotEmpty) {
        return GroupTreeNode(group: n.group, children: filteredChildren, isExpanded: n.isExpanded);
      }
      return null;
    }
    return list.map(filterRec).whereType<GroupTreeNode>().toList();
  }
}

class GroupTreeNodeWidget extends StatelessWidget {
  final GroupTreeNode node;
  final int level;
  final Function(GroupTreeNode) onNodeTap;
  final Function(GroupTreeNode) onToggle;
  final String? userDepartment;
  final String? searchQuery;
  final bool showOfficial;
  final bool showAutonomous;

  const GroupTreeNodeWidget({
    super.key,
    required this.node,
    required this.level,
    required this.onNodeTap,
    required this.onToggle,
    this.userDepartment,
    this.searchQuery,
    required this.showOfficial,
    required this.showAutonomous,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final group = node.group;
    final gp = context.watch<GroupProvider>();

    // 멤버십 판정
    final bool isMyDepartment = group.groupType == GroupType.department && gp.isMemberOf(group.id);
    final bool isMyCollegeSelf = group.groupType == GroupType.college && gp.isMemberOf(group.id);

    bool _hasMyMembershipBelow(GroupTreeNode n) {
      for (final c in n.children) {
        if (gp.isMemberOf(c.group.id)) return true;
        if (_hasMyMembershipBelow(c)) return true;
      }
      return false;
    }
    // College(계열)에서 칩 표시 여부: 본인 멤버십이 있거나, 하위 학과 중 멤버인 경우
    final bool showMyTrackOnCollege = group.groupType == GroupType.college && (isMyCollegeSelf || _hasMyMembershipBelow(node));

    final String typeText = group.groupType == GroupType.university
        ? '대학교'
        : group.groupType == GroupType.college
            ? '단과대학'
            : (group.groupType == GroupType.department ? '학과' : group.typeDisplayName);

    final bool canExpand = node.children.isNotEmpty || group.groupType == GroupType.department;
    final bool isXs = MediaQuery.of(context).size.width < 360;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: canExpand ? () => _handleToggle(context) : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: Material(
                            color: Colors.transparent,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: canExpand ? () => _handleToggle(context) : null,
                              child: Center(
                                child: AnimatedRotation(
                                  turns: node.isExpanded ? 0.25 : 0,
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    Icons.chevron_right,
                                    size: 22,
                                    color: canExpand ? theme.colorScheme.primary : theme.disabledColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _groupLeadingIcon(group.groupType),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    group.name,
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: const Color(0xFF111827)),
                                  ),
                                  _typeBadge(context, typeText),
                                  if (showMyTrackOnCollege) _neutralChip('내 계열'),
                                  if (!showMyTrackOnCollege && isMyDepartment) _neutralChip('내 학과'),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(children: [
                                Icon(Icons.people_outline, size: 14, color: theme.colorScheme.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Text('${group.memberCount}명', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                              ]),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (!isXs)
                  TextButton(
                    onPressed: () => _goToGroupHome(context, group),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: const Size(0, 0)),
                    child: const Text('그룹 홈으로 ›', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w600)),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.more_horiz),
                    onPressed: () => _openMoreSheet(context, group, typeText),
                  ),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, anim) {
              final slide = Tween<Offset>(begin: const Offset(0, -0.05), end: Offset.zero).animate(anim);
              return FadeTransition(opacity: anim, child: SlideTransition(position: slide, child: child));
            },
            child: node.isExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (node.children.isNotEmpty)
                          ...node.children.map((child) => GroupTreeNodeWidget(
                                node: child,
                                level: level + 1,
                                onNodeTap: onNodeTap,
                                onToggle: onToggle,
                                userDepartment: userDepartment,
                                searchQuery: searchQuery,
                                showOfficial: showOfficial,
                                showAutonomous: showAutonomous,
                              )),
                        if (group.groupType == GroupType.department)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: _SubGroupsSection(
                              parent: node, 
                              searchQuery: searchQuery, 
                              showOfficial: showOfficial,
                              showAutonomous: showAutonomous,
                            ),
                          ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _neutralChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: const TextStyle(fontSize: 11, color: Color(0xFF374151), fontWeight: FontWeight.w500)),
    );
  }

  void _goToGroupHome(BuildContext context, GroupSummaryModel group) async {
    final gp = context.read<GroupProvider>();
    final isMember = await gp.checkGroupMembership(group.id);
    if (isMember) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => WorkspaceScreen(
            groupId: group.id,
            groupName: group.name,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('그룹 소개 페이지로 이동 (구현 예정)')));
    }
  }

  void _openMoreSheet(BuildContext context, GroupSummaryModel group, String typeText) {
    final gp = context.read<GroupProvider>();
    final bool isMyDepartment = group.groupType == GroupType.department && gp.isMemberOf(group.id);
    final bool isMyCollege = group.groupType == GroupType.college && gp.isMemberOf(group.id);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.home_outlined),
                  title: const Text('그룹 홈으로'),
                  onTap: () {
                    Navigator.pop(context);
                    _goToGroupHome(context, group);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.star_border),
                  title: const Text('즐겨찾기'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('즐겨찾기 (구현 예정)')));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.share_outlined),
                  title: const Text('공유'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('공유 (구현 예정)')));
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _typeBadge(context, typeText),
                    if (group.groupType == GroupType.college && (isMyCollege)) ...[const SizedBox(width: 6), _miniBadge(context, '내 계열')],
                    if (group.groupType == GroupType.department && isMyDepartment) ...[const SizedBox(width: 6), _miniBadge(context, '내 학과')],
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleToggle(BuildContext context) {
    final gp = context.read<GroupProvider>();
    if (node.group.groupType == GroupType.department) {
      gp.loadSubGroups(node.group.id);
    }
    onToggle(node);
  }

  bool _containsDepartmentNormalized(GroupTreeNode node, String normDept) {
    final g = node.group;
    final current = (g.department ?? g.name);
    String _norm(String s) => s.replaceAll(RegExp(r"\s+"), "").toLowerCase();
    if (_norm(current) == normDept) return true;
    for (final c in node.children) {
      if (_containsDepartmentNormalized(c, normDept)) return true;
    }
    return false;
  }

  bool _containsDepartment(GroupTreeNode node, String dept) {
    // 유지: 이전 시그니처와의 호환. 내부적으로 정규화 비교 사용.
    return _containsDepartmentNormalized(node, dept.replaceAll(RegExp(r"\s+"), "").toLowerCase());
  }

  bool _isTrackNode(GroupSummaryModel group) {
    final text = (group.department ?? group.name);
    return text.contains('계열');
  }

  Widget _groupLeadingIcon(GroupType groupType) {
    IconData icon;
    Color color;
    switch (groupType) {
      case GroupType.university:
        icon = Icons.school;
        color = Colors.blue[600]!;
        break;
      case GroupType.college:
        icon = Icons.apartment;
        color = Colors.green[600]!;
        break;
      case GroupType.department:
        icon = Icons.history_edu;
        color = Colors.orange[600]!;
        break;
      case GroupType.lab:
        icon = Icons.science;
        color = Colors.purple[600]!;
        break;
      case GroupType.official:
        icon = Icons.verified;
        color = Colors.red[600]!;
        break;
      case GroupType.autonomous:
        icon = Icons.groups;
        color = Colors.grey[600]!;
        break;
      case GroupType.unknown: // Handle unknown type
        icon = Icons.help_outline;
        color = Colors.grey[400]!;
        break;
    }
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: color, size: 22),
    );
  }

  Widget _typeBadge(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _miniBadge(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SubGroupsSection extends StatelessWidget {
  final GroupTreeNode parent;
  final String? searchQuery;
  final bool showOfficial;
  final bool showAutonomous;
  const _SubGroupsSection({required this.parent, this.searchQuery, required this.showOfficial, required this.showAutonomous});

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<GroupProvider>();
    final list = gp.getSubGroupsCached(parent.group.id);
    final loading = gp.isSubGroupsLoading(parent.group.id);
    final err = gp.subGroupsError(parent.group.id);

    Widget body;
    if (loading && (list == null || list.isEmpty)) {
      body = const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (err != null) {
      body = Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(height: 8),
          Text(err, style: const TextStyle(color: Colors.grey)),
        ]),
      );
    } else if (list == null || list.isEmpty) {
      body = const SizedBox.shrink();
    } else {
      final q = (searchQuery ?? '').toLowerCase();
      List<GroupSummaryModel> allSubGroups = list;
      if (q.isNotEmpty) {
        allSubGroups = list.where((g) => g.name.toLowerCase().contains(q) || (g.department ?? '').toLowerCase().contains(q)).toList();
      }
      
      // 대학그룹은 항상 표시, 공식/자율 그룹만 필터링
      final universityGroups = allSubGroups.where((g) => [GroupType.university, GroupType.college, GroupType.department].contains((g as GroupSummaryModel).groupType)).toList();
      final officialGroups = allSubGroups.where((g) => (g as GroupSummaryModel).groupType == GroupType.official).toList();
      final autonomousGroups = allSubGroups.where((g) => (g as GroupSummaryModel).groupType == GroupType.autonomous).toList();

      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 대학그룹은 항상 표시
          if (universityGroups.isNotEmpty)
            _section(context, title: '대학 그룹', color: Colors.blue, items: universityGroups),
          // 공식/자율 그룹은 필터에 따라 표시
          if (showOfficial && officialGroups.isNotEmpty)
            _section(context, title: '공식 그룹', color: const Color(0xFF2563EB), items: officialGroups),
          if (showAutonomous && autonomousGroups.isNotEmpty)
            _section(context, title: '자율 그룹', color: Colors.green, items: autonomousGroups),
        ],
      );
    }

    return Container(
      margin: EdgeInsets.only(left: (parent.children.isEmpty ? (parent.group.groupType == GroupType.department ? 16.0 : 0.0) : 0.0)),
      child: body,
    );
  }

  Widget _section(BuildContext context, {required String title, required Color color, required List<GroupSummaryModel> items}) {
    final dot = Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            dot,
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            TextButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('모두 보기 (구현 예정)'))),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: const Size(0, 0)),
              child: const Text('모두 보기'),
            ),
          ]),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (_, i) {
              final g = items[i];
              return SizedBox(
                height: 56,
                child: Row(
                  children: [
                    _subIcon(g),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(g.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text('${g.memberCount}명', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _statusBadge(g),
                  ],
                ),
              );
            },
            separatorBuilder: (_, __) => const Divider(height: 12, color: Color(0xFFF3F4F6)),
            itemCount: items.length.clamp(0, 5),
          )
        ],
      ),
    );
  }

  Widget _subIcon(GroupSummaryModel g) {
    IconData icon = Icons.circle;
    Color color = Colors.grey;
    switch (g.groupType) {
      case GroupType.official:
        icon = Icons.shield_outlined;
        color = Colors.blue;
        break;
      case GroupType.autonomous:
        icon = Icons.lightbulb_outline;
        color = Colors.green;
        break;
      case GroupType.lab:
        icon = Icons.science;
        color = Colors.purple;
        break;
      default:
        icon = Icons.group_outlined;
        color = Colors.grey;
    }
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
      child: Icon(icon, size: 16, color: color),
    );
  }

  Widget _statusBadge(GroupSummaryModel g) {
    // 상태 배지: 활성 / 진행중 / 모집중 / 비공개
    String text;
    Color bg;
    Color fg;
    if (g.visibility == GroupVisibility.private) {
      text = '비공개';
      bg = Colors.grey.shade200;
      fg = Colors.grey.shade700;
    } else if (g.isRecruiting) {
      text = '모집중';
      bg = Colors.orange.shade100;
      fg = Colors.orange.shade800;
    } else {
      text = '활성';
      bg = Colors.green.shade100;
      fg = Colors.green.shade800;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
