import 'package:flutter/material.dart';
import '../../data/models/group_model.dart';
import 'group_tree_provider.dart';
import 'group_membership_provider.dart';
import 'group_subgroups_provider.dart';

// Simplified GroupProvider that orchestrates other providers
class GroupProvider with ChangeNotifier {
  final GroupTreeProvider _treeProvider;
  final GroupMembershipProvider _membershipProvider;
  final GroupSubgroupsProvider _subgroupsProvider;

  GroupProvider(
    this._treeProvider,
    this._membershipProvider,
    this._subgroupsProvider,
  ) {
    _treeProvider.addListener(_onTreeChanged);
    _membershipProvider.addListener(_onMembershipChanged);
    _subgroupsProvider.addListener(_onSubgroupsChanged);
  }

  @override
  void dispose() {
    _treeProvider.removeListener(_onTreeChanged);
    _membershipProvider.removeListener(_onMembershipChanged);
    _subgroupsProvider.removeListener(_onSubgroupsChanged);
    super.dispose();
  }

  void _onTreeChanged() => notifyListeners();
  void _onMembershipChanged() => notifyListeners();
  void _onSubgroupsChanged() => notifyListeners();

  // Delegate properties and methods to respective providers
  bool get isLoading => _treeProvider.isLoading;
  String? get error => _treeProvider.error;
  List<GroupTreeNode> get groupTree => _treeProvider.groupTree;
  List<GroupHierarchyNode> get hierarchy => _treeProvider.hierarchy;
  Set<int> get myGroupIds => _membershipProvider.myGroupIds;

  bool isMemberOf(int groupId) => _membershipProvider.isMemberOf(groupId);
  bool isSubGroupsLoading(int groupId) => _subgroupsProvider.isSubGroupsLoading(groupId);
  String? subGroupsError(int groupId) => _subgroupsProvider.subGroupsError(groupId);
  List<GroupSummaryModel>? getSubGroupsCached(int groupId) => _subgroupsProvider.getSubGroupsCached(groupId);

  Future<void> loadAllGroups() async {
    await _treeProvider.loadAllGroups();

    // Load membership after tree is loaded
    if (_treeProvider.groupTree.isNotEmpty) {
      final allIds = <int>[];
      void collectIds(List<GroupTreeNode> nodes) {
        for (final n in nodes) {
          allIds.add(n.group.id);
          if (n.children.isNotEmpty) collectIds(n.children);
        }
      }
      collectIds(_treeProvider.groupTree);
      await _membershipProvider.loadMembershipForGroups(allIds);
    }
  }

  Future<void> fetchGroupHierarchy() => _treeProvider.fetchGroupHierarchy();

  void toggleNode(GroupTreeNode node) {
    _treeProvider.toggleNode(node);
    if (node.isExpanded &&
        node.group.groupType == GroupType.department &&
        node.children.isEmpty) {
      loadSubGroups(node.group.id);
    }
  }

  Future<void> loadSubGroups(int groupId) => _subgroupsProvider.loadSubGroups(groupId);

  void expandPathToDepartment(String departmentName) => _treeProvider.expandPathToDepartment(departmentName);
  void expandPathToCollege(String collegeName) => _treeProvider.expandPathToCollege(collegeName);

  void expandToMyAffiliation({bool preferDepartment = true}) {
    if (_treeProvider.groupTree.isEmpty || _membershipProvider.myGroupIds.isEmpty) return;

    GroupTreeNode? _findFirst(bool Function(GroupTreeNode) pred, List<GroupTreeNode> nodes) {
      for (final n in nodes) {
        if (pred(n)) return n;
        final r = _findFirst(pred, n.children);
        if (r != null) return r;
      }
      return null;
    }

    GroupTreeNode? targetNode;
    if (preferDepartment) {
      targetNode = _findFirst((n) => n.group.groupType == GroupType.department && _membershipProvider.myGroupIds.contains(n.group.id), _treeProvider.groupTree);
      targetNode ??= _findFirst((n) => n.group.groupType == GroupType.college && _membershipProvider.myGroupIds.contains(n.group.id), _treeProvider.groupTree);
    } else {
      targetNode = _findFirst((n) => n.group.groupType == GroupType.college && _membershipProvider.myGroupIds.contains(n.group.id), _treeProvider.groupTree);
      targetNode ??= _findFirst((n) => n.group.groupType == GroupType.department && _membershipProvider.myGroupIds.contains(n.group.id), _treeProvider.groupTree);
    }

    if (targetNode != null) {
      _expandParentsToTarget(targetNode);
    }
  }

  void _expandParentsToTarget(GroupTreeNode targetNode) {
    targetNode.isExpanded = true;

    void findAndExpandParent(List<GroupTreeNode> nodes) {
      for (final node in nodes) {
        if (node.children.contains(targetNode)) {
          node.isExpanded = true;
          _expandParentsToTarget(node);
          return;
        }
        if (node.children.isNotEmpty) {
          findAndExpandParent(node.children);
        }
      }
    }

    findAndExpandParent(_treeProvider.groupTree);
    notifyListeners();
  }

  Future<bool> checkGroupMembership(int groupId) => _membershipProvider.checkGroupMembership(groupId);
}

extension _IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
