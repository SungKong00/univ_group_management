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
  // 내부 워크스페이스 전환을 위한 선택적 콜백
  final void Function(int groupId, String groupName)? onNavigateToWorkspace;

  const GroupTreeWidget({
    super.key,
    required this.nodes,
    required this.onNodeTap,
    required this.onToggle,
    this.userDepartment,
    this.searchQuery,
    required this.showOfficial,
    required this.showAutonomous,
    this.onNavigateToWorkspace,
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
            onNavigateToWorkspace: onNavigateToWorkspace,
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
  // 내부 워크스페이스 전환 콜백 전달
  final void Function(int groupId, String groupName)? onNavigateToWorkspace;

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
    this.onNavigateToWorkspace,
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
                                onNavigateToWorkspace: onNavigateToWorkspace,
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
      // 내부 전환 콜백이 있으면 우선 사용 (상단/하단바 유지)
      if (onNavigateToWorkspace != null) {
        onNavigateToWorkspace!(group.id, group.name);
        return;
      }
      // 폴백: 기존 네비게이션 (전체 화면 라우트)
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
                  onTap: () async {
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
      child: Icon(icon, color: color),
    );
  }

  Widget _typeBadge(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.25)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _miniBadge(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF6B7280),
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

  const _SubGroupsSection({
    required this.parent,
    required this.searchQuery,
    required this.showOfficial,
    required this.showAutonomous,
  });

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<GroupProvider>();

    // 캐시된 하위 그룹 조회
    final cached = gp.getSubGroupsCached(parent.group.id);
    final isLoading = gp.isSubGroupsLoading(parent.group.id);
    final error = gp.subGroupsError(parent.group.id);

    // 아직 로드되지 않았으면 최초 로드 트리거
    if (cached == null && !isLoading && error == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<GroupProvider>().loadSubGroups(parent.group.id);
      });
    }

    if (isLoading && cached == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    if (error != null && cached == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(error, style: const TextStyle(color: Colors.red))),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => context.read<GroupProvider>().loadSubGroups(parent.group.id),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    final List<GroupSummaryModel> list = cached ?? const <GroupSummaryModel>[];

    List<GroupSummaryModel> filtered = list;
    final q = (searchQuery ?? '').trim().toLowerCase();
    if (q.isNotEmpty) {
      filtered = filtered.where((g) {
        final name = g.name.toLowerCase();
        final dept = (g.department ?? '').toLowerCase();
        return name.contains(q) || dept.contains(q);
      }).toList();
    }

    // 타입 필터링
    filtered = filtered.where((g) {
      if (g.groupType == GroupType.official && !showOfficial) return false;
      if (g.groupType == GroupType.autonomous && !showAutonomous) return false;
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: const Text('표시할 하위 그룹이 없습니다', style: TextStyle(color: Color(0xFF9CA3AF))),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: filtered.map((g) => _SubGroupChip(group: g)).toList(),
        ),
      ],
    );
  }
}

class _SubGroupChip extends StatelessWidget {
  final GroupSummaryModel group;

  const _SubGroupChip({required this.group});

  @override
  Widget build(BuildContext context) {
    final gp = context.read<GroupProvider>();

    return ActionChip(
      avatar: const Icon(Icons.group_outlined, size: 16),
      label: Text(group.name),
      onPressed: () async {
        final isMember = await gp.checkGroupMembership(group.id);
        if (isMember) {
          // 탐색 시트 없이 직접 이동
          // 여기서는 트리노드와 동일한 내부 전환을 시도하고, 없으면 폴백
          final scaffoldNode = context.findAncestorWidgetOfExactType<GroupTreeNodeWidget>();
          if (scaffoldNode?.onNavigateToWorkspace != null) {
            scaffoldNode!.onNavigateToWorkspace!(group.id, group.name);
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => WorkspaceScreen(
                  groupId: group.id,
                  groupName: group.name,
                ),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('그룹 소개 페이지로 이동 (구현 예정)')));
        }
      },
    );
  }
}
