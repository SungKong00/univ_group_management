import 'package:flutter/foundation.dart';
import '../../core/network/api_response.dart';
import '../../data/models/group_model.dart';
import '../../domain/repositories/group_repository.dart';

class GroupTreeProvider extends ChangeNotifier {
  final GroupRepository _repo;

  GroupTreeProvider(this._repo);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  List<GroupTreeNode> _groupTree = [];
  List<GroupTreeNode> get groupTree => _groupTree;

  List<GroupHierarchyNode> _hierarchy = [];
  List<GroupHierarchyNode> get hierarchy => _hierarchy;

  Future<void> loadAllGroups() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Ensure hierarchy is loaded, or fetch it now.
      if (_hierarchy.isEmpty) {
        await fetchGroupHierarchy();
      }

      final summaryResponse = await _repo.getAllGroups();

      if (summaryResponse.isSuccess &&
          summaryResponse.data != null &&
          _hierarchy.isNotEmpty) {
        final summaries = summaryResponse.data!;
        _groupTree = _buildGroupTree(summaries, _hierarchy);
      } else {
        _error = summaryResponse.error?.message ??
            '그룹 정보를 불러오는데 실패했습니다.';
        _groupTree = [];
      }
    } catch (e) {
      _error = '그룹 정보를 불러오는 중 오류가 발생했습니다: ${e.toString()}';
      _groupTree = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchGroupHierarchy() async {
    if (_hierarchy.isNotEmpty) return;

    try {
      final response = await _repo.getGroupHierarchy();
      if (response.isSuccess && response.data != null) {
        _hierarchy = response.data!;
        notifyListeners();
      } else {
        _error = response.error?.message ?? '계열/학과 정보를 불러오는데 실패했습니다.';
        _hierarchy = [];
        notifyListeners();
      }
    } catch (e) {
      _error = '계열/학과 정보를 불러오는 중 오류가 발생했습니다: ${e.toString()}';
      _hierarchy = [];
      notifyListeners();
    }
  }

  void toggleNode(GroupTreeNode node) {
    node.isExpanded = !node.isExpanded;
    notifyListeners();
  }

  void expandPathToDepartment(String departmentName) {
    if (_groupTree.isEmpty) return;

    final target = _norm(departmentName);
    _resetExpansion(_groupTree);

    GroupTreeNode? targetNode;

    void findNode(List<GroupTreeNode> nodes) {
      for (final node in nodes) {
        final dn = node.group.department ?? node.group.name;
        if (_norm(dn).contains(target)) {
          targetNode = node;
          return;
        }
        if (node.children.isNotEmpty) {
          findNode(node.children);
        }
        if (targetNode != null) return;
      }
    }

    findNode(_groupTree);

    if (targetNode != null) {
      _expandParents(targetNode!, _groupTree);
    }

    notifyListeners();
  }

  void expandPathToCollege(String collegeName) {
    if (_groupTree.isEmpty) return;

    final target = _norm(collegeName);
    _resetExpansion(_groupTree);

    GroupTreeNode? targetNode;

    void findCollege(List<GroupTreeNode> nodes) {
      for (final node in nodes) {
        if (node.group.groupType == GroupType.college) {
          final name = node.group.college ?? node.group.name;
          if (_norm(name).contains(target)) {
            targetNode = node;
            return;
          }
        }
        if (node.children.isNotEmpty) findCollege(node.children);
        if (targetNode != null) return;
      }
    }

    findCollege(_groupTree);

    if (targetNode != null) {
      _expandParents(targetNode!, _groupTree);
      notifyListeners();
    }
  }

  void _expandParents(GroupTreeNode targetNode, List<GroupTreeNode> allNodes) {
    targetNode.isExpanded = true;

    for (final node in allNodes) {
      if (node.children.contains(targetNode)) {
        _expandParents(node, _groupTree);
        return;
      }
      if (node.children.isNotEmpty) {
        _expandParents(targetNode, node.children);
      }
    }
  }

  List<GroupTreeNode> _buildGroupTree(
      List<GroupSummaryModel> summaries, List<GroupHierarchyNode> hierarchy) {
    final Map<int, GroupSummaryModel> summaryMap = {
      for (var s in summaries) s.id: s
    };
    final Map<int, GroupTreeNode> nodeMap = {};
    final List<GroupTreeNode> rootNodes = [];

    for (final hierarchyNode in hierarchy) {
      final summary = summaryMap[hierarchyNode.id];
      if (summary != null) {
        nodeMap[hierarchyNode.id] = GroupTreeNode(group: summary);
      }
    }

    for (final hierarchyNode in hierarchy) {
      final node = nodeMap[hierarchyNode.id];
      if (node != null) {
        if (hierarchyNode.parentId != null) {
          final parentNode = nodeMap[hierarchyNode.parentId];
          parentNode?.children.add(node);
        } else {
          rootNodes.add(node);
        }
      }
    }

    for (final node in nodeMap.values) {
      node.children.sort((a, b) => a.group.name.compareTo(b.group.name));
    }

    return rootNodes;
  }

  void _resetExpansion(List<GroupTreeNode> nodes) {
    for (final node in nodes) {
      node.isExpanded = false;
      _resetExpansion(node.children);
    }
  }

  String _norm(String s) => s
      .replaceAll(RegExp(r"\s+"), "")
      .toLowerCase()
      .replaceAll(RegExp(r"(대학|학부|계열|학과)"), "");
}