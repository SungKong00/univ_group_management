import 'group_models.dart';

/// GroupTreeNode - Tree structure for hierarchical group view
///
/// Supports up to 8 levels of nesting with expand/collapse state.
class GroupTreeNode {
  final int id;
  final String name;
  final String? profileImageUrl;
  final int memberCount;
  final bool isRecruiting;
  final GroupType groupType;
  final int? parentId;
  final int level;
  final List<GroupTreeNode> children;
  final bool isExpanded;

  GroupTreeNode({
    required this.id,
    required this.name,
    this.profileImageUrl,
    required this.memberCount,
    required this.isRecruiting,
    required this.groupType,
    this.parentId,
    required this.level,
    this.children = const [],
    this.isExpanded = false,
  });

  factory GroupTreeNode.fromGroupSummary(
    GroupSummaryResponse summary, {
    int level = 0,
    List<GroupTreeNode> children = const [],
    bool isExpanded = false,
  }) {
    return GroupTreeNode(
      id: summary.id,
      name: summary.name,
      profileImageUrl: summary.profileImageUrl,
      memberCount: summary.memberCount,
      isRecruiting: summary.isRecruiting,
      groupType: summary.groupType,
      parentId: null, // Will be set during tree construction
      level: level,
      children: children,
      isExpanded: isExpanded,
    );
  }

  GroupTreeNode copyWith({
    int? id,
    String? name,
    String? profileImageUrl,
    int? memberCount,
    bool? isRecruiting,
    GroupType? groupType,
    int? parentId,
    int? level,
    List<GroupTreeNode>? children,
    bool? isExpanded,
  }) {
    return GroupTreeNode(
      id: id ?? this.id,
      name: name ?? this.name,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      memberCount: memberCount ?? this.memberCount,
      isRecruiting: isRecruiting ?? this.isRecruiting,
      groupType: groupType ?? this.groupType,
      parentId: parentId ?? this.parentId,
      level: level ?? this.level,
      children: children ?? this.children,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'profileImageUrl': profileImageUrl,
      'memberCount': memberCount,
      'isRecruiting': isRecruiting,
      'groupType': groupType.name,
      'parentId': parentId,
      'level': level,
      'children': children.map((c) => c.toJson()).toList(),
      'isExpanded': isExpanded,
    };
  }

  factory GroupTreeNode.fromJson(Map<String, dynamic> json) {
    return GroupTreeNode(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      memberCount: (json['memberCount'] as num).toInt(),
      isRecruiting: json['isRecruiting'] as bool,
      groupType: GroupType.values.firstWhere(
        (e) => e.name == json['groupType'],
        orElse: () => GroupType.autonomous,
      ),
      parentId: (json['parentId'] as num?)?.toInt(),
      level: (json['level'] as num).toInt(),
      children: (json['children'] as List<dynamic>?)
              ?.map((e) => GroupTreeNode.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isExpanded: json['isExpanded'] as bool? ?? false,
    );
  }

  /// Check if this node has any children
  bool get hasChildren => children.isNotEmpty;

  /// Toggle expand state
  GroupTreeNode toggleExpanded() {
    return copyWith(isExpanded: !isExpanded);
  }

  /// Recursively update a child node by ID
  GroupTreeNode updateChild(int childId, GroupTreeNode Function(GroupTreeNode) updater) {
    if (id == childId) {
      return updater(this);
    }

    return copyWith(
      children: children.map((child) {
        return child.updateChild(childId, updater);
      }).toList(),
    );
  }
}
