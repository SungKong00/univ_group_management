import 'user_models.dart';

enum GroupNodeType { university, college, department, official, autonomous, other }

enum GroupType {
  autonomous, // AUTONOMOUS
  official, // OFFICIAL
  university, // UNIVERSITY
  college, // COLLEGE
  department, // DEPARTMENT
  lab, // LAB
}

class GroupHierarchyNode {
  GroupHierarchyNode({
    required this.id,
    required this.name,
    required this.type,
    this.parentId,
    this.isRecruiting = false,
    this.memberCount = 0,
  });

  factory GroupHierarchyNode.fromJson(Map<String, dynamic> json) {
    final String typeString = (json['type'] as String? ?? '').toUpperCase();

    return GroupHierarchyNode(
      id: (json['id'] as num).toInt(),
      parentId: (json['parentId'] as num?)?.toInt(),
      name: json['name'] as String? ?? '',
      type: _parseType(typeString),
      isRecruiting: json['isRecruiting'] as bool? ?? false,
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
    );
  }

  final int id;
  final int? parentId;
  final String name;
  final GroupNodeType type;
  final bool isRecruiting;
  final int memberCount;

  static GroupNodeType _parseType(String value) {
    switch (value) {
      case 'UNIVERSITY':
        return GroupNodeType.university;
      case 'COLLEGE':
        return GroupNodeType.college;
      case 'DEPARTMENT':
        return GroupNodeType.department;
      case 'OFFICIAL':
        return GroupNodeType.official;
      case 'AUTONOMOUS':
        return GroupNodeType.autonomous;
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

/// CreateSubgroupRequest model for POST /api/groups/{parentId}/sub-groups/requests
///
/// Maps to backend CreateSubGroupRequest DTO with 'requested' prefix
class CreateSubgroupRequest {
  final String name;
  final String? description;
  final String groupType;
  final int? maxMembers;

  CreateSubgroupRequest({
    required this.name,
    this.description,
    required this.groupType,
    this.maxMembers,
  });

  Map<String, dynamic> toJson() {
    return {
      'requestedGroupName': name,
      'requestedGroupDescription': description,
      'requestedGroupType': groupType,
      'requestedMaxMembers': maxMembers,
    };
  }
}

class GroupSummaryResponse {
  GroupSummaryResponse({
    required this.id,
    required this.name,
    this.description,
    this.profileImageUrl,
    this.university,
    this.college,
    this.department,
    required this.groupType,
    required this.isRecruiting,
    required this.memberCount,
    required this.tags,
  });

  factory GroupSummaryResponse.fromJson(Map<String, dynamic> json) {
    return GroupSummaryResponse(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      university: json['university'] as String?,
      college: json['college'] as String?,
      department: json['department'] as String?,
      groupType: _parseGroupType(json['groupType'] as String),
      isRecruiting: json['isRecruiting'] as bool,
      memberCount: (json['memberCount'] as num).toInt(),
      tags: Set<String>.from(json['tags'] as List),
    );
  }

  final int id;
  final String name;
  final String? description;
  final String? profileImageUrl;
  final String? university;
  final String? college;
  final String? department;
  final GroupType groupType;
  final bool isRecruiting;
  final int memberCount;
  final Set<String> tags;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'description': description,
      'profileImageUrl': profileImageUrl,
      'university': university,
      'college': college,
      'department': department,
      'groupType': _serializeGroupType(groupType),
      'isRecruiting': isRecruiting,
      'memberCount': memberCount,
      'tags': tags.toList(),
    };
  }

  static GroupType _parseGroupType(String value) {
    return GroupType.values.firstWhere(
      (e) => e.name.toUpperCase() == value,
      orElse: () => throw ArgumentError('Unknown GroupType: $value'),
    );
  }

  static String _serializeGroupType(GroupType type) {
    return type.name.toUpperCase();
  }
}

/// SubGroupRequestResponse model for GET /api/groups/{groupId}/sub-groups/requests
///
/// Maps to backend SubGroupRequestResponse DTO
class SubGroupRequestResponse {
  final int id;
  final UserSummaryResponse requester;
  final GroupSummaryResponse parentGroup;
  final String requestedGroupName;
  final String? requestedGroupDescription;
  final String? requestedUniversity;
  final String? requestedCollege;
  final String? requestedDepartment;
  final GroupType requestedGroupType;
  final int? requestedMaxMembers;
  final String status; // "PENDING", "APPROVED", "REJECTED"
  final String? responseMessage;
  final UserSummaryResponse? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  SubGroupRequestResponse({
    required this.id,
    required this.requester,
    required this.parentGroup,
    required this.requestedGroupName,
    this.requestedGroupDescription,
    this.requestedUniversity,
    this.requestedCollege,
    this.requestedDepartment,
    required this.requestedGroupType,
    this.requestedMaxMembers,
    required this.status,
    this.responseMessage,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubGroupRequestResponse.fromJson(Map<String, dynamic> json) {
    return SubGroupRequestResponse(
      id: (json['id'] as num).toInt(),
      requester: UserSummaryResponse.fromJson(json['requester'] as Map<String, dynamic>),
      parentGroup: GroupSummaryResponse.fromJson(json['parentGroup'] as Map<String, dynamic>),
      requestedGroupName: json['requestedGroupName'] as String,
      requestedGroupDescription: json['requestedGroupDescription'] as String?,
      requestedUniversity: json['requestedUniversity'] as String?,
      requestedCollege: json['requestedCollege'] as String?,
      requestedDepartment: json['requestedDepartment'] as String?,
      requestedGroupType: GroupSummaryResponse._parseGroupType(json['requestedGroupType'] as String),
      requestedMaxMembers: (json['requestedMaxMembers'] as num?)?.toInt(),
      status: json['status'] as String,
      responseMessage: json['responseMessage'] as String?,
      reviewedBy: json['reviewedBy'] != null
          ? UserSummaryResponse.fromJson(json['reviewedBy'] as Map<String, dynamic>)
          : null,
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.parse(json['reviewedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

/// ReviewSubGroupRequestRequest model for PATCH /api/groups/{groupId}/sub-groups/requests/{requestId}
class ReviewSubGroupRequestRequest {
  final String action; // "APPROVE" or "REJECT"
  final String? responseMessage;

  ReviewSubGroupRequestRequest({
    required this.action,
    this.responseMessage,
  });

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      if (responseMessage != null) 'responseMessage': responseMessage,
    };
  }
}
