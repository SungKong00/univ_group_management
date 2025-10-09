enum GroupNodeType { university, college, department, other }

class GroupHierarchyNode {
  GroupHierarchyNode({
    required this.id,
    required this.name,
    required this.type,
    this.parentId,
  });

  factory GroupHierarchyNode.fromJson(Map<String, dynamic> json) {
    final String typeString = (json['type'] as String? ?? '').toUpperCase();

    return GroupHierarchyNode(
      id: (json['id'] as num).toInt(),
      parentId: (json['parentId'] as num?)?.toInt(),
      name: json['name'] as String? ?? '',
      type: _parseType(typeString),
    );
  }

  final int id;
  final int? parentId;
  final String name;
  final GroupNodeType type;

  static GroupNodeType _parseType(String value) {
    switch (value) {
      case 'UNIVERSITY':
        return GroupNodeType.university;
      case 'COLLEGE':
        return GroupNodeType.college;
      case 'DEPARTMENT':
        return GroupNodeType.department;
      default:
        return GroupNodeType.other;
    }
  }
}

/// GroupMembership model for /api/me/groups response
class GroupMembership {
  final int id;
  final String name;
  final String type;
  final int level;
  final int? parentId;
  final String role;
  final List<String> permissions;
  final String? profileImageUrl;

  GroupMembership({
    required this.id,
    required this.name,
    required this.type,
    required this.level,
    this.parentId,
    required this.role,
    required this.permissions,
    this.profileImageUrl,
  });

  factory GroupMembership.fromJson(Map<String, dynamic> json) {
    return GroupMembership(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      type: json['type'] as String,
      level: (json['level'] as num).toInt(),
      parentId: (json['parentId'] as num?)?.toInt(),
      role: json['role'] as String,
      permissions: (json['permissions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      profileImageUrl: json['profileImageUrl'] as String?,
    );
  }
}

/// UpdateGroupRequest model for PUT /api/groups/{id}
class UpdateGroupRequest {
  final String? name;
  final String? description;
  final String? profileImageUrl;
  final String? groupType;
  final bool? isRecruiting;
  final int? maxMembers;
  final Set<String>? tags;

  UpdateGroupRequest({
    this.name,
    this.description,
    this.profileImageUrl,
    this.groupType,
    this.isRecruiting,
    this.maxMembers,
    this.tags,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    if (name != null) json['name'] = name;
    if (description != null) json['description'] = description;
    if (profileImageUrl != null) json['profileImageUrl'] = profileImageUrl;
    if (groupType != null) json['groupType'] = groupType;
    if (isRecruiting != null) json['isRecruiting'] = isRecruiting;
    if (maxMembers != null) json['maxMembers'] = maxMembers;
    if (tags != null) json['tags'] = tags?.toList();
    return json;
  }
}
