enum GroupNodeType {
  university,
  college,
  department,
  other,
}

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
  final String visibility;

  GroupMembership({
    required this.id,
    required this.name,
    required this.type,
    required this.level,
    this.parentId,
    required this.role,
    required this.permissions,
    this.profileImageUrl,
    required this.visibility,
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
      visibility: json['visibility'] as String,
    );
  }
}
