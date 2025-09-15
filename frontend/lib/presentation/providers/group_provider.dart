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
      final response = await _repo.getAllGroups();
      if (response.isSuccess && response.data != null) {
        _groupTree = _buildGroupTree(response.data!);

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
        _error = response.error?.message ?? '그룹 정보를 불러오는데 실패했습니다.';
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
    if (node.isExpanded && node.group.groupType == GroupType.department && node.children.isEmpty) {
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
        _subGroupErrors[groupId] = response.error?.message ?? '하위 그룹을 불러오는데 실패했습니다.';
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

    String norm(String s) => s.replaceAll(RegExp(r"\s+"), "").toLowerCase();
    final target = norm(departmentName);

    // Reset all expanded states first
    _resetExpansion(_groupTree);

    bool found = false;
    for (final universityNode in _groupTree) {
      if (universityNode.group.groupType == GroupType.university) {
        for (final collegeNode in universityNode.children) {
          if (collegeNode.group.groupType == GroupType.college) {
            // Check if the department is directly under this college (college name as department)
            final collegeName = collegeNode.group.name;
            final collegeDept = collegeNode.group.department ?? '';
            if (norm(collegeDept) == target || norm(collegeName) == target) {
              universityNode.isExpanded = true;
              collegeNode.isExpanded = true;
              found = true;
              break;
            }
            // Check if department is under a department group (e.g., AI/SW 계열 -> AI시스템반도체학과)
            for (final deptNode in collegeNode.children) {
              if (deptNode.group.groupType == GroupType.department) {
                final dn = deptNode.group.department ?? deptNode.group.name;
                if (norm(dn) == target) {
                  universityNode.isExpanded = true;
                  collegeNode.isExpanded = true;
                  deptNode.isExpanded = true;
                  found = true;
                  break;
                }
              }
            }
          }
          if (found) break;
        }
      }
      if (found) break;
    }
    notifyListeners();
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

  // Builds the GroupTreeNode hierarchy from a flat list of GroupSummaryModel
  List<GroupTreeNode> _buildGroupTree(List<GroupSummaryModel> flatGroups) {
    final Map<int, GroupTreeNode> nodeMap = {};
    final List<GroupTreeNode> rootNodes = [];

    // Create all nodes first
    for (final group in flatGroups) {
      nodeMap[group.id] = GroupTreeNode(group: group);
    }

    // Assign children and identify roots
    for (final group in flatGroups) {
      final node = nodeMap[group.id]!;
      // Find parent by checking group's type and parent's type
      // University has no parent
      // College's parent is University
      // Department's parent is College or Department (for tracks)
      // Lab's parent is Department

      GroupTreeNode? parentNode;
      if (group.groupType == GroupType.college && group.university != null) {
        // Find university node
        parentNode = nodeMap.values.firstWhereOrNull(
            (n) => n.group.groupType == GroupType.university && n.group.name == group.university);
      } else if (group.groupType == GroupType.department && group.college != null) {
        // Find college node
        parentNode = nodeMap.values.firstWhereOrNull(
            (n) => n.group.groupType == GroupType.college && n.group.name == group.college);
      } else if (group.groupType == GroupType.lab && group.department != null) {
        // Find department node
        parentNode = nodeMap.values.firstWhereOrNull(
            (n) => n.group.groupType == GroupType.department && n.group.name == group.department);
      }

      if (parentNode != null) {
        parentNode.children.add(node);
      } else if (group.groupType == GroupType.university) {
        rootNodes.add(node);
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
}

extension _IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
