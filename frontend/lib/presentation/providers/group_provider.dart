import 'package:flutter/material.dart';
import '../../core/network/api_response.dart';
import '../../data/models/group_model.dart';
import '../../domain/repositories/group_repository.dart';

class GroupProvider with ChangeNotifier {
  final GroupRepository _repo;
  GroupProvider(this._repo);

  // --- Overall Group Tree State (for Group Explorer) ---
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  List<GroupTreeNode> _groupTree = [];
  List<GroupTreeNode> get groupTree => _groupTree;

  // --- Subgroup Loading/Error/Cache State (for Group Tree Widget) ---
  final Map<int, bool> _subGroupLoadingStates = {};
  final Map<int, String?> _subGroupErrors = {};
  final Map<int, List<GroupSummaryModel>> _subGroupCache = {};

  bool isSubGroupsLoading(int groupId) => _subGroupLoadingStates[groupId] ?? false;
  String? subGroupsError(int groupId) => _subGroupErrors[groupId];
  List<GroupSummaryModel>? getSubGroupsCached(int groupId) => _subGroupCache[groupId];

  // --- Hierarchy for Onboarding Screen ---
  List<GroupHierarchyNode> _hierarchy = [];
  List<GroupHierarchyNode> get hierarchy => _hierarchy;

  // --- My Membership Cache ---
  final Set<int> _myGroupIds = <int>{};
  Set<int> get myGroupIds => _myGroupIds;
  bool isMemberOf(int groupId) => _myGroupIds.contains(groupId);

  // --- Methods ---

  // Fetches all groups and builds the tree for the explorer screen
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

        // 멤버십 수집: 모든 그룹에 대해 멤버 여부 확인 후 캐시
        _myGroupIds.clear();
        final allIds = <int>[];
        void collectIds(List<GroupTreeNode> nodes) {
          for (final n in nodes) {
            allIds.add(n.group.id);
            if (n.children.isNotEmpty) collectIds(n.children);
          }
        }
        collectIds(_groupTree);
        // 순차 확인(과도한 동시 호출 방지)
        for (final id in allIds) {
          try {
            final ok = await _repo.checkGroupMembership(id);
            if (ok.isSuccess && ok.data == true) {
              _myGroupIds.add(id);
            }
          } catch (_) {}
        }
      } else {
        _error = summaryResponse.error?.message ??
            '그룹 정보를 불러오는데 실패했습니다.';
        _groupTree = [];
        _myGroupIds.clear();
      }
    } catch (e) {
      _error = '그룹 정보를 불러오는 중 오류가 발생했습니다: ${e.toString()}';
      _groupTree = [];
      _myGroupIds.clear();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Fetches flat hierarchy for onboarding screen
  Future<void> fetchGroupHierarchy() async {
    if (_hierarchy.isNotEmpty) return; // Do not fetch if already loaded

    // Use _isLoading for overall loading, but don't block if explorer is loading
    // This is a separate fetch for a different UI
    try {
      final response = await _repo.getGroupHierarchy();
      if (response.isSuccess && response.data != null) {
        _hierarchy = response.data!;
        notifyListeners(); // Notify UI to rebuild with new hierarchy data
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

  // Toggles the expansion state of a node in the tree
  void toggleNode(GroupTreeNode node) {
    node.isExpanded = !node.isExpanded;
    if (node.isExpanded &&
        node.group.groupType == GroupType.department &&
        node.children.isEmpty) {
      // If a department node is expanded and has no children, try to load subgroups
      loadSubGroups(node.group.id);
    }
    notifyListeners();
  }

  // Loads subgroups for a given parent group ID
  Future<void> loadSubGroups(int groupId) async {
    if (_subGroupLoadingStates[groupId] == true) return;
    _subGroupLoadingStates[groupId] = true;
    _subGroupErrors[groupId] = null;
    notifyListeners();

    try {
      final response = await _repo.getSubGroups(groupId);
      if (response.isSuccess && response.data != null) {
        _subGroupCache[groupId] = response.data!;
      } else {
        _subGroupErrors[groupId] =
            response.error?.message ?? '하위 그룹을 불러오는데 실패했습니다.';
        _subGroupCache[groupId] = [];
      }
    } catch (e) {
      _subGroupErrors[groupId] = '하위 그룹을 불러오는 중 오류가 발생했습니다: ${e.toString()}';
      _subGroupCache[groupId] = [];
    }

    _subGroupLoadingStates[groupId] = false;
    notifyListeners();
  }

  // Expands the path to a specific department in the tree
  void expandPathToDepartment(String departmentName) {
    if (_groupTree.isEmpty) return;

    final target = _norm(departmentName);

    // Reset all expanded states first
    _resetExpansion(_groupTree);

    // Find the target node
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

    // Expand all parents of the target node
    if (targetNode != null) {
      _expandParents(targetNode!, _groupTree);
    }

    notifyListeners();
  }
  
  void _expandParents(GroupTreeNode targetNode, List<GroupTreeNode> allNodes) {
    targetNode.isExpanded = true;

    // Find parent and expand it recursively
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

  // Expands the path to a specific college (계열/단과대학) in the tree
  void expandPathToCollege(String collegeName) {
    if (_groupTree.isEmpty) return;

    final target = _norm(collegeName);

    // Reset expansion first to ensure a clean state
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

  // 멤버십 기반 자동 펼침: 학과 멤버십 우선, 없으면 계열 멤버십으로 확장
  void expandToMyAffiliation({bool preferDepartment = true}) {
    if (_groupTree.isEmpty || _myGroupIds.isEmpty) return;

    GroupTreeNode? _findFirst(bool Function(GroupTreeNode) pred, List<GroupTreeNode> nodes) {
      for (final n in nodes) {
        if (pred(n)) return n;
        final r = _findFirst(pred, n.children);
        if (r != null) return r;
      }
      return null;
    }

    // Reset first
    _resetExpansion(_groupTree);

    GroupTreeNode? targetNode;
    if (preferDepartment) {
      targetNode = _findFirst((n) => n.group.groupType == GroupType.department && _myGroupIds.contains(n.group.id), _groupTree);
      targetNode ??= _findFirst((n) => n.group.groupType == GroupType.college && _myGroupIds.contains(n.group.id), _groupTree);
    } else {
      targetNode = _findFirst((n) => n.group.groupType == GroupType.college && _myGroupIds.contains(n.group.id), _groupTree);
      targetNode ??= _findFirst((n) => n.group.groupType == GroupType.department && _myGroupIds.contains(n.group.id), _groupTree);
    }

    if (targetNode != null) {
      _expandParents(targetNode, _groupTree);
      notifyListeners();
    }
  }

  // Checks if the current user is a member of a given group
  Future<bool> checkGroupMembership(int groupId) async {
    try {
      final response = await _repo.checkGroupMembership(groupId);
      return response.isSuccess && response.data == true;
    } catch (e) {
      return false;
    }
  }

  // --- Helper Methods ---

  // Builds the GroupTreeNode hierarchy using parent IDs
  List<GroupTreeNode> _buildGroupTree(
      List<GroupSummaryModel> summaries, List<GroupHierarchyNode> hierarchy) {
    final Map<int, GroupSummaryModel> summaryMap = {
      for (var s in summaries) s.id: s
    };
    final Map<int, GroupTreeNode> nodeMap = {};
    final List<GroupTreeNode> rootNodes = [];

    // Create all nodes first, using hierarchy for structure and summary for data
    for (final hierarchyNode in hierarchy) {
      final summary = summaryMap[hierarchyNode.id];
      if (summary != null) {
        nodeMap[hierarchyNode.id] = GroupTreeNode(group: summary);
      }
    }

    // Assign children using parentId
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

    // Sort children for consistent display
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

  // 이름 정규화: 공백 제거, 소문자화, 한국어 접미사(대학/학부/계열/학과) 제거
  String _norm(String s) => s
      .replaceAll(RegExp(r"\s+"), "")
      .toLowerCase()
      .replaceAll(RegExp(r"(대학|학부|계열|학과)"), "");
}

extension _IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
