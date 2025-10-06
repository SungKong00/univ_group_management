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
    // Handle nested role structure from backend (GroupMemberResponse)
    // Backend returns: { user: {...}, role: { name: "...", permissions: [...] } }
    // We need to extract: userId from user.id, roleName from role.name, permissions from role.permissions

    final int userId;
    final String roleName;
    final List<String>? permissions;

    if (json['user'] != null && json['role'] != null) {
      // Backend GroupMemberResponse structure (nested)
      userId = (json['user']['id'] as num).toInt();
      roleName = json['role']['name'] as String? ?? '';
      permissions = (json['role']['permissions'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList();
    } else {
      // Fallback to flat structure for backward compatibility
      userId = (json['userId'] as num).toInt();
      roleName = json['roleName'] as String? ?? '';
      permissions = (json['permissions'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList();
    }

    final membership = MembershipInfo(
      userId: userId,
      roleName: roleName,
      permissions: permissions,
    );

    return membership;
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

/// ChannelPermissions model
///
/// Represents user's permissions within a specific channel.
/// Used for checking channel-level permissions like POST_WRITE, COMMENT_WRITE, FILE_UPLOAD.
class ChannelPermissions {
  final List<String> permissions;

  const ChannelPermissions({
    required this.permissions,
  });

  factory ChannelPermissions.fromJson(Map<String, dynamic> json) {
    return ChannelPermissions(
      permissions: (json['permissions'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
    );
  }

  /// Check if user has POST_WRITE permission
  /// Required to enable the message input field
  bool get canWritePost => permissions.contains('POST_WRITE');

  /// Check if user has COMMENT_WRITE permission
  /// Required to enable the comment input field
  bool get canWriteComment => permissions.contains('COMMENT_WRITE');

  /// Check if user has FILE_UPLOAD permission
  /// Required to show/enable the file attachment button
  bool get canUploadFile => permissions.contains('FILE_UPLOAD');

  /// Check if user has POST_READ permission
  /// Required to view posts in the channel
  bool get canReadPost => permissions.contains('POST_READ');

  /// Check if user has CHANNEL_VIEW permission
  /// Required to view the channel itself
  bool get canViewChannel => permissions.contains('CHANNEL_VIEW');

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChannelPermissions &&
        permissions.length == other.permissions.length &&
        permissions.every((p) => other.permissions.contains(p));
  }

  @override
  int get hashCode => permissions.hashCode;
}