/// Channel model
///
/// Represents a communication channel within a workspace.
class Channel {
  final int id;
  final String name;
  final String type; // 'ANNOUNCEMENT', 'TEXT'
  final String? description;

  const Channel({
    required this.id,
    required this.name,
    required this.type,
    this.description,
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'TEXT',
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'description': description,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Channel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// MembershipInfo model
///
/// Contains user's role and permissions within a group.
/// Used for checking group-level permissions like GROUP_MANAGE.
class MembershipInfo {
  final int userId;
  final String roleName;
  final List<String>? permissions; // GroupPermission list

  const MembershipInfo({
    required this.userId,
    required this.roleName,
    this.permissions,
  });

  factory MembershipInfo.fromJson(Map<String, dynamic> json) {
    return MembershipInfo(
      userId: (json['userId'] as num).toInt(),
      roleName: json['roleName'] as String? ?? '',
      permissions: (json['permissions'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  /// Check if user has any group-level permission
  /// Used to determine if admin page button should be shown
  bool get hasAnyGroupPermission {
    if (permissions == null || permissions!.isEmpty) return false;

    // Group management permissions that indicate admin access
    const adminPermissions = [
      'GROUP_MANAGE',
      'WORKSPACE_MANAGE',
      'ADMIN_MANAGE',
      'RECRUITMENT_MANAGE',
    ];

    return permissions!.any((p) => adminPermissions.contains(p));
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MembershipInfo && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}
