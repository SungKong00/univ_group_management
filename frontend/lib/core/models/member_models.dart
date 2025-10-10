/// 멤버 관리 데이터 모델
library;

/// MVP: Mock 데이터 기반 UI 구현
/// 향후: API 연동 시 백엔드 응답 구조에 맞춰 수정

/// 그룹 멤버 정보
class GroupMember {
  final int id;
  final String userId;
  final String userName;
  final String email;
  final String? profileImageUrl;
  final String? studentNo;
  final int? academicYear;
  final String roleName;
  final int roleId;
  final DateTime joinedAt;
  final bool isActive;

  GroupMember({
    required this.id,
    required this.userId,
    required this.userName,
    required this.email,
    this.profileImageUrl,
    this.studentNo,
    this.academicYear,
    required this.roleName,
    required this.roleId,
    required this.joinedAt,
    this.isActive = true,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: (json['id'] as num).toInt(),
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      email: json['email'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      studentNo: json['studentNo'] as String?,
      academicYear: (json['academicYear'] as num?)?.toInt(),
      roleName: json['roleName'] as String,
      roleId: (json['roleId'] as num).toInt(),
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'studentNo': studentNo,
      'academicYear': academicYear,
      'roleName': roleName,
      'roleId': roleId,
      'joinedAt': joinedAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  GroupMember copyWith({
    int? id,
    String? userId,
    String? userName,
    String? email,
    String? profileImageUrl,
    String? studentNo,
    int? academicYear,
    String? roleName,
    int? roleId,
    DateTime? joinedAt,
    bool? isActive,
  }) {
    return GroupMember(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      studentNo: studentNo ?? this.studentNo,
      academicYear: academicYear ?? this.academicYear,
      roleName: roleName ?? this.roleName,
      roleId: roleId ?? this.roleId,
      joinedAt: joinedAt ?? this.joinedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// 그룹 역할 정보
class GroupRole {
  final int id;
  final String name;
  final String description;
  final bool isSystemRole;
  final int priority;
  final List<String> permissions;
  final int memberCount; // 해당 역할을 가진 멤버 수

  GroupRole({
    required this.id,
    required this.name,
    required this.description,
    required this.isSystemRole,
    required this.priority,
    required this.permissions,
    this.memberCount = 0,
  });

  factory GroupRole.fromJson(Map<String, dynamic> json) {
    return GroupRole(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      isSystemRole: json['isSystemRole'] as bool? ?? false,
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      permissions:
          (json['permissions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isSystemRole': isSystemRole,
      'priority': priority,
      'permissions': permissions,
      'memberCount': memberCount,
    };
  }

  GroupRole copyWith({
    int? id,
    String? name,
    String? description,
    bool? isSystemRole,
    int? priority,
    List<String>? permissions,
    int? memberCount,
  }) {
    return GroupRole(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isSystemRole: isSystemRole ?? this.isSystemRole,
      priority: priority ?? this.priority,
      permissions: permissions ?? this.permissions,
      memberCount: memberCount ?? this.memberCount,
    );
  }
}

/// 가입 신청 정보
class JoinRequest {
  final int id;
  final String userId;
  final String userName;
  final String email;
  final String? profileImageUrl;
  final String message; // 지원 동기
  final DateTime requestedAt;
  final JoinRequestStatus status;

  JoinRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.email,
    this.profileImageUrl,
    required this.message,
    required this.requestedAt,
    required this.status,
  });

  factory JoinRequest.fromJson(Map<String, dynamic> json) {
    return JoinRequest(
      id: (json['id'] as num).toInt(),
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      email: json['email'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      message: json['message'] as String,
      requestedAt: DateTime.parse(json['requestedAt'] as String),
      status: JoinRequestStatus.fromString(json['status'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'message': message,
      'requestedAt': requestedAt.toIso8601String(),
      'status': status.value,
    };
  }
}

/// 가입 신청 상태
enum JoinRequestStatus {
  pending('PENDING'),
  approved('APPROVED'),
  rejected('REJECTED');

  final String value;
  const JoinRequestStatus(this.value);

  static JoinRequestStatus fromString(String value) {
    return JoinRequestStatus.values.firstWhere(
      (e) => e.value == value.toUpperCase(),
      orElse: () => JoinRequestStatus.pending,
    );
  }
}

/// 멤버 역할 변경 요청
class UpdateMemberRoleRequest {
  final int roleId;

  UpdateMemberRoleRequest({required this.roleId});

  Map<String, dynamic> toJson() {
    return {'roleId': roleId};
  }
}

/// 가입 신청 처리 요청
class ProcessJoinRequestRequest {
  final bool approved;
  final String? roleId; // 승인 시 부여할 역할

  ProcessJoinRequestRequest({required this.approved, this.roleId});

  Map<String, dynamic> toJson() {
    return {'approved': approved, if (roleId != null) 'roleId': roleId};
  }
}
