import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/models/group_tree_node.dart';
import '../../../../core/models/group_models.dart';
import '../../../../core/services/group_explore_service.dart';

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

  final GroupExploreService _service = GroupExploreService();

  /// Load full hierarchy
  Future<void> loadHierarchy() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Fetch all groups (we'll build tree from flat list)
      // TODO: If backend provides /api/groups/hierarchy endpoint, use that instead
      final groups = await _service.exploreGroups(
        query: null,
        filters: null,
        page: 0,
        size: 1000, // Large enough to get all groups
      );

      // Build tree structure from flat list
      final tree = _buildTreeFromFlatList(groups);

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

  /// Build tree structure from flat list of groups
  List<GroupTreeNode> _buildTreeFromFlatList(List<GroupSummaryResponse> groups) {
    // Apply filters (University groups are always shown)
    final filteredGroups = _applyFilters(groups);

    // Group by type to create pseudo-hierarchy
    final universities = <GroupTreeNode>[];
    final colleges = <GroupTreeNode>[];
    final departments = <GroupTreeNode>[];
    final others = <GroupTreeNode>[];

    for (final group in filteredGroups) {
      final node = GroupTreeNode.fromGroupSummary(
        group,
        level: _getDepthFromType(group.groupType),
      );

      switch (group.groupType) {
        case GroupType.university:
          universities.add(node);
          break;
        case GroupType.college:
          colleges.add(node);
          break;
        case GroupType.department:
          departments.add(node);
          break;
        default:
          others.add(node);
      }
    }

    // Create hierarchical structure
    // University (level 0) → College (level 1) → Department (level 2) → Others (level 3)
    final result = <GroupTreeNode>[];

    if (universities.isNotEmpty) {
      for (final uni in universities) {
        final uniColleges = colleges.where((c) =>
          c.name.contains(uni.name) || _isRelated(c, uni)
        ).toList();

        final uniWithChildren = uni.copyWith(
          level: 0,
          children: uniColleges.map((college) {
            final collegeDepts = departments.where((d) =>
              d.name.contains(college.name) || _isRelated(d, college)
            ).toList();

            return college.copyWith(
              level: 1,
              parentId: uni.id,
              children: collegeDepts.map((dept) {
                final deptGroups = others.where((o) =>
                  o.name.contains(dept.name) || _isRelated(o, dept)
                ).toList();

                return dept.copyWith(
                  level: 2,
                  parentId: college.id,
                  children: deptGroups.map((group) => group.copyWith(
                    level: 3,
                    parentId: dept.id,
                  )).toList(),
                );
              }).toList(),
            );
          }).toList(),
        );

        result.add(uniWithChildren);
      }
    } else {
      // Fallback: if no hierarchy, just show all groups at root level
      result.addAll(colleges.map((c) => c.copyWith(
        level: 0,
        children: departments.where((d) => _isRelated(d, c)).map((dept) =>
          dept.copyWith(
            level: 1,
            parentId: c.id,
            children: others.where((o) => _isRelated(o, dept)).map((group) =>
              group.copyWith(level: 2, parentId: dept.id)
            ).toList(),
          )
        ).toList(),
      )));

      // Add remaining items
      if (result.isEmpty) {
        result.addAll(groups.map((g) => GroupTreeNode.fromGroupSummary(g, level: 0)));
      }
    }

    return result;
  }

  /// Apply filters to groups list
  /// University groups (대학교, 단과대, 학과) are always shown (always-on)
  List<GroupSummaryResponse> _applyFilters(List<GroupSummaryResponse> groups) {
    final showRecruiting = state.filters['showRecruiting'] == true;
    final showAutonomous = state.filters['showAutonomous'] == true;
    final showOfficial = state.filters['showOfficial'] == true;

    // If no filters are active, show all groups
    if (!showRecruiting && !showAutonomous && !showOfficial) {
      return groups;
    }

    return groups.where((group) {
      // University groups (대학교, 단과대, 학과) are always shown
      final isUniversityGroup = group.groupType == GroupType.university ||
          group.groupType == GroupType.college ||
          group.groupType == GroupType.department;

      if (isUniversityGroup) {
        return true;
      }

      // Apply recruiting filter for non-university groups
      if (showRecruiting && !group.isRecruiting) {
        return false;
      }

      // Apply group type filters for non-university groups
      if (showAutonomous && group.groupType != GroupType.autonomous) {
        return false;
      }

      if (showOfficial && group.groupType != GroupType.official) {
        return false;
      }

      // If no specific type filter is active but recruiting filter is on
      if (showRecruiting && !showAutonomous && !showOfficial) {
        return true;
      }

      // If type filter is active, show matching groups
      if (showAutonomous || showOfficial) {
        return true;
      }

      return false;
    }).toList();
  }

  /// Simple heuristic to check if two groups are related
  bool _isRelated(GroupTreeNode child, GroupTreeNode parent) {
    // This is a placeholder - in real implementation, use actual parent-child relationship
    return child.name.toLowerCase().contains(parent.name.toLowerCase());
  }

  /// Get depth from group type
  int _getDepthFromType(GroupType type) {
    switch (type) {
      case GroupType.university:
        return 0;
      case GroupType.college:
        return 1;
      case GroupType.department:
        return 2;
      case GroupType.lab:
        return 3;
      default:
        return 4;
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
