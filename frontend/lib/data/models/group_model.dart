enum GroupType {
  autonomous,
  official,
  university,
  college,
  department,
  lab,
  unknown, // Add unknown for safety
}

enum GroupVisibility {
  public,
  private,
  inviteOnly,
}

// For Onboarding
class GroupHierarchyNode {
  final int id;
  final int? parentId;
  final String name;
  final GroupType type;

  GroupHierarchyNode({
    required this.id,
    this.parentId,
    required this.name,
    required this.type,
  });

  factory GroupHierarchyNode.fromJson(Map<String, dynamic> json) {
    return GroupHierarchyNode(
      id: (json['id'] is num) ? (json['id'] as num).toInt() : 0,
      parentId: (json['parentId'] is num) ? (json['parentId'] as num).toInt() : null,
      name: json['name']?.toString() ?? '',
      type: _parseGroupType(json['type']?.toString()),
    );
  }
}

// For Tree View UI
class GroupTreeNode {
  final GroupSummaryModel group;
  final List<GroupTreeNode> children;
  bool isExpanded;

  GroupTreeNode({
    required this.group,
    List<GroupTreeNode> children = const [],
    this.isExpanded = false,
  }) : children = List<GroupTreeNode>.from(children);

  GroupTreeNode copyWith({
    GroupSummaryModel? group,
    List<GroupTreeNode>? children,
    bool? isExpanded,
  }) {
    return GroupTreeNode(
      group: group ?? this.group,
      children: children ?? this.children,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }
}

class GroupModel {
  final int id;
  final String name;
  final String? description;
  final String? profileImageUrl;
  final UserSummaryModel owner;
  final String? university;
  final String? college;
  final String? department;
  final GroupVisibility visibility;
  final GroupType groupType;
  final bool isRecruiting;
  final int? maxMembers;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GroupModel({
    required this.id,
    required this.name,
    this.description,
    this.profileImageUrl,
    required this.owner,
    this.university,
    this.college,
    this.department,
    required this.visibility,
    required this.groupType,
    required this.isRecruiting,
    this.maxMembers,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: (json['id'] ?? 0) as int,
      name: (json['name'] ?? '').toString(),
      description: json['description']?.toString(),
      profileImageUrl: json['profileImageUrl']?.toString(),
      owner: UserSummaryModel.fromJson(json['owner'] ?? {}),
      university: json['university']?.toString(),
      college: json['college']?.toString(),
      department: json['department']?.toString(),
      visibility: _parseVisibility(json['visibility']?.toString()),
      groupType: _parseGroupType(json['groupType']?.toString()),
      isRecruiting: json['isRecruiting'] == true,
      maxMembers: json['maxMembers'] as int?,
      tags: ((json['tags'] as List?) ?? []).map((e) => e.toString()).toList(),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class GroupSummaryModel {
  final int id;
  final String name;
  final String? description;
  final String? profileImageUrl;
  final String? university;
  final String? college;
  final String? department;
  final GroupVisibility visibility;
  final GroupType groupType;
  final bool isRecruiting;
  final int memberCount;
  final List<String> tags;

  const GroupSummaryModel({
    required this.id,
    required this.name,
    this.description,
    this.profileImageUrl,
    this.university,
    this.college,
    this.department,
    required this.visibility,
    required this.groupType,
    required this.isRecruiting,
    required this.memberCount,
    required this.tags,
  });

  factory GroupSummaryModel.fromJson(Map<String, dynamic> json) {
    return GroupSummaryModel(
      id: (json['id'] ?? 0) as int,
      name: (json['name'] ?? '').toString(),
      description: json['description']?.toString(),
      profileImageUrl: json['profileImageUrl']?.toString(),
      university: json['university']?.toString(),
      college: json['college']?.toString(),
      department: json['department']?.toString(),
      visibility: _parseVisibility(json['visibility']?.toString()),
      groupType: _parseGroupType(json['groupType']?.toString()),
      isRecruiting: json['isRecruiting'] == true,
      memberCount: (json['memberCount'] ?? 0) as int,
      tags: ((json['tags'] as List?) ?? []).map((e) => e.toString()).toList(),
    );
  }
  
  // TreeView를 위한 도우미 메소드들
  bool get hasSubGroups => groupType == GroupType.university || 
                          groupType == GroupType.college;
  
  String get typeDisplayName {
    switch (groupType) {
      case GroupType.autonomous:
        return '자율그룹';
      case GroupType.official:
        return '공식그룹';
      case GroupType.university:
        return '대학교';
      case GroupType.college:
        return '단과대학';
      case GroupType.department:
        return '학과';
      case GroupType.lab:
        return '연구실';
      case GroupType.unknown:
        return '알 수 없음';
    }
  }
}

class UserSummaryModel {
  final int id;
  final String name;
  final String email;
  final String? profileImageUrl;

  const UserSummaryModel({
    required this.id,
    required this.name,
    required this.email,
    this.profileImageUrl,
  });

  factory UserSummaryModel.fromJson(Map<String, dynamic> json) {
    return UserSummaryModel(
      id: (json['id'] ?? 0) as int,
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      profileImageUrl: json['profileImageUrl']?.toString(),
    );
  }
}

// Helper functions for parsing enums
GroupVisibility _parseVisibility(String? visibility) {
  switch (visibility?.toUpperCase()) {
    case 'PUBLIC':
      return GroupVisibility.public;
    case 'PRIVATE':
      return GroupVisibility.private;
    case 'INVITE_ONLY':
      return GroupVisibility.inviteOnly;
    default:
      return GroupVisibility.public;
  }
}

GroupType _parseGroupType(String? groupType) {
  switch (groupType?.toUpperCase()) {
    case 'AUTONOMOUS':
      return GroupType.autonomous;
    case 'OFFICIAL':
      return GroupType.official;
    case 'UNIVERSITY':
      return GroupType.university;
    case 'COLLEGE':
      return GroupType.college;
    case 'DEPARTMENT':
      return GroupType.department;
    case 'LAB':
      return GroupType.lab;
    default:
      return GroupType.autonomous;
  }
}