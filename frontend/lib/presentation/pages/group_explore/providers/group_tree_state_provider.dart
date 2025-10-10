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
      memberCount: 0, // Hierarchy API doesn't provide member count
      isRecruiting: false, // Hierarchy API doesn't provide recruiting status
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
