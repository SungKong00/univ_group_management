import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/models/group_tree_node.dart';
import '../../../../core/models/group_models.dart';
import '../../../../core/services/group_service.dart';

/// Group Tree State
class GroupTreeState extends Equatable {
  const GroupTreeState({
    this.rootNodes = const [],
    this.isLoading = false,
    this.errorMessage,
    this.filters = const {},
  });

  final List<GroupTreeNode> rootNodes;
  final bool isLoading;
  final String? errorMessage;
  final Map<String, dynamic> filters; // showRecruiting, showAutonomous, showOfficial

  GroupTreeState copyWith({
    List<GroupTreeNode>? rootNodes,
    bool? isLoading,
    String? errorMessage,
    Map<String, dynamic>? filters,
  }) {
    return GroupTreeState(
      rootNodes: rootNodes ?? this.rootNodes,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      filters: filters ?? this.filters,
    );
  }

  @override
  List<Object?> get props => [rootNodes, isLoading, errorMessage, filters];
}

/// Group Tree State Notifier
class GroupTreeStateNotifier extends StateNotifier<GroupTreeState> {
  GroupTreeStateNotifier() : super(const GroupTreeState());

  final GroupService _groupService = GroupService();

  /// Load full hierarchy
  Future<void> loadHierarchy() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Fetch hierarchy from backend (uses /api/groups/hierarchy)
      final hierarchyNodes = await _groupService.getHierarchy();

      // Build tree structure from hierarchy nodes
      final tree = _buildTreeFromHierarchyNodes(hierarchyNodes);

      state = state.copyWith(
        rootNodes: tree,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '계층 구조를 불러오는데 실패했습니다.',
      );
    }
  }

  /// Toggle node expansion state
  void toggleNode(int nodeId) {
    final updatedNodes = _updateNodeRecursive(state.rootNodes, nodeId);
    state = state.copyWith(rootNodes: updatedNodes);
  }

  /// Toggle filter
  void toggleFilter(String filterKey) {
    final newFilters = Map<String, dynamic>.from(state.filters);
    newFilters[filterKey] = !(newFilters[filterKey] == true);
    state = state.copyWith(filters: newFilters);
    // Reload with filters
    loadHierarchy();
  }

  /// Build tree structure from hierarchy nodes (with parentId)
  List<GroupTreeNode> _buildTreeFromHierarchyNodes(List<GroupHierarchyNode> nodes) {
    if (nodes.isEmpty) return [];

    // Find root nodes (nodes with no parent)
    final rootNodes = nodes.where((n) => n.parentId == null).toList();

    // Build tree recursively from each root
    return rootNodes.map((root) => _buildNodeRecursive(root, nodes)).toList();
  }

  /// Recursively build a tree node with its children
  GroupTreeNode _buildNodeRecursive(GroupHierarchyNode node, List<GroupHierarchyNode> allNodes) {
    // Find direct children of this node
    final children = allNodes.where((n) => n.parentId == node.id).toList();

    // Calculate level (depth in tree)
    final level = _calculateLevel(node, allNodes);

    // Recursively build children
    final childNodes = children.map((child) => _buildNodeRecursive(child, allNodes)).toList();

    // Convert to GroupTreeNode
    return GroupTreeNode(
      id: node.id,
      name: node.name,
      groupType: _convertNodeTypeToGroupType(node.type),
      memberCount: node.memberCount, // 실제 백엔드 데이터 사용
      isRecruiting: node.isRecruiting, // 실제 백엔드 데이터 사용
      level: level,
      parentId: node.parentId,
      children: childNodes,
      isExpanded: false,
    );
  }

  /// Calculate the level (depth) of a node in the tree
  int _calculateLevel(GroupHierarchyNode node, List<GroupHierarchyNode> allNodes) {
    int level = 0;
    int? currentParentId = node.parentId;

    // Traverse up the tree to count depth
    while (currentParentId != null) {
      level++;
      final parent = allNodes.firstWhere(
        (n) => n.id == currentParentId,
        orElse: () => GroupHierarchyNode(
          id: -1,
          parentId: null,
          name: '',
          type: GroupNodeType.other,
        ),
      );
      currentParentId = parent.parentId;
    }

    return level;
  }

  /// Convert GroupNodeType to GroupType
  GroupType _convertNodeTypeToGroupType(GroupNodeType nodeType) {
    switch (nodeType) {
      case GroupNodeType.university:
        return GroupType.university;
      case GroupNodeType.college:
        return GroupType.college;
      case GroupNodeType.department:
        return GroupType.department;
      case GroupNodeType.other:
        return GroupType.autonomous; // Default to autonomous for unknown types
    }
  }


  /// Recursively update a node's expansion state
  List<GroupTreeNode> _updateNodeRecursive(List<GroupTreeNode> nodes, int targetId) {
    return nodes.map((node) {
      if (node.id == targetId) {
        return node.toggleExpanded();
      }

      if (node.hasChildren) {
        return node.copyWith(
          children: _updateNodeRecursive(node.children, targetId),
        );
      }

      return node;
    }).toList();
  }

  /// Initialize: load hierarchy on first access
  Future<void> initialize() async {
    if (state.rootNodes.isEmpty && !state.isLoading) {
      await loadHierarchy();
    }
  }

  /// Reset state
  void reset() {
    state = const GroupTreeState();
  }
}

// State Provider
final groupTreeStateProvider =
    StateNotifierProvider<GroupTreeStateNotifier, GroupTreeState>(
  (ref) => GroupTreeStateNotifier(),
);

// Selective Providers
final treeRootNodesProvider = Provider<List<GroupTreeNode>>((ref) {
  return ref.watch(groupTreeStateProvider.select((s) => s.rootNodes));
});

final treeIsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(groupTreeStateProvider.select((s) => s.isLoading));
});

final treeErrorMessageProvider = Provider<String?>((ref) {
  return ref.watch(groupTreeStateProvider.select((s) => s.errorMessage));
});

final treeFiltersProvider = Provider<Map<String, dynamic>>((ref) {
  return ref.watch(groupTreeStateProvider.select((s) => s.filters));
});

/// Filtered root nodes provider - 필터를 적용한 트리 노드 제공
final filteredTreeRootNodesProvider = Provider<List<GroupTreeNode>>((ref) {
  final rootNodes = ref.watch(treeRootNodesProvider);
  final filters = ref.watch(treeFiltersProvider);

  // 필터가 모두 비활성화된 경우 전체 트리 반환
  final showRecruiting = filters['showRecruiting'] == true;
  final showAutonomous = filters['showAutonomous'] == true;
  final showOfficial = filters['showOfficial'] == true;

  if (!showRecruiting && !showAutonomous && !showOfficial) {
    return rootNodes;
  }

  // 필터 적용: 재귀적으로 노드 필터링
  return rootNodes.map((node) => _filterNodeRecursive(node, filters)).where((node) => node != null).cast<GroupTreeNode>().toList();
});

/// 재귀적으로 노드와 자식 노드를 필터링
GroupTreeNode? _filterNodeRecursive(GroupTreeNode node, Map<String, dynamic> filters) {
  final showRecruiting = filters['showRecruiting'] == true;
  final showAutonomous = filters['showAutonomous'] == true;
  final showOfficial = filters['showOfficial'] == true;

  // 대학 그룹(UNIVERSITY, COLLEGE, DEPARTMENT)은 항상 표시
  final isUniversityGroup = node.groupType == GroupType.university ||
      node.groupType == GroupType.college ||
      node.groupType == GroupType.department;

  if (isUniversityGroup) {
    // 대학 그룹은 항상 표시하지만 자식 노드는 필터링
    final filteredChildren = node.children
        .map((child) => _filterNodeRecursive(child, filters))
        .where((child) => child != null)
        .cast<GroupTreeNode>()
        .toList();

    return node.copyWith(children: filteredChildren);
  }

  // 자율/공식 그룹은 필터 적용
  bool shouldShow = false;

  if (showRecruiting && node.isRecruiting) {
    shouldShow = true;
  }

  if (showAutonomous && node.groupType == GroupType.autonomous) {
    shouldShow = true;
  }

  if (showOfficial && node.groupType == GroupType.official) {
    shouldShow = true;
  }

  // 필터에 맞지 않으면 null 반환 (제외)
  if (!shouldShow) {
    return null;
  }

  // 자식 노드도 재귀적으로 필터링
  final filteredChildren = node.children
      .map((child) => _filterNodeRecursive(child, filters))
      .where((child) => child != null)
      .cast<GroupTreeNode>()
      .toList();

  return node.copyWith(children: filteredChildren);
}
