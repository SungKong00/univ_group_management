import 'group_model.dart';

/// 워크스페이스 모델
class WorkspaceModel {
  final int id;
  final int groupId;
  final String name;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WorkspaceModel({
    required this.id,
    required this.groupId,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WorkspaceModel.fromJson(Map<String, dynamic> json) {
    return WorkspaceModel(
      id: (json['id'] ?? 0) as int,
      groupId: (json['groupId'] ?? 0) as int,
      name: (json['name'] ?? '').toString(),
      description: json['description']?.toString(),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

/// 채널 타입
enum ChannelType {
  text,
  voice,
  announcement,
  fileShare,
}

/// 채널 모델
class ChannelModel {
  final int id;
  final int groupId;
  final String name;
  final String? description;
  final ChannelType type;
  final bool isPrivate;
  final int displayOrder;
  final UserSummaryModel createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChannelModel({
    required this.id,
    required this.groupId,
    required this.name,
    this.description,
    required this.type,
    required this.isPrivate,
    required this.displayOrder,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChannelModel.fromJson(Map<String, dynamic> json) {
    return ChannelModel(
      id: (json['id'] ?? 0) as int,
      groupId: (json['groupId'] ?? 0) as int,
      name: (json['name'] ?? '').toString(),
      description: json['description']?.toString(),
      type: _parseChannelType(json['type']?.toString()),
      isPrivate: json['isPrivate'] == true,
      displayOrder: (json['displayOrder'] ?? 0) as int,
      createdBy: UserSummaryModel.fromJson(json['createdBy'] ?? {}),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'name': name,
      'description': description,
      'type': type.name.toUpperCase(),
      'isPrivate': isPrivate,
      'displayOrder': displayOrder,
      'createdBy': createdBy.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get typeDisplayName {
    switch (type) {
      case ChannelType.text:
        return '텍스트';
      case ChannelType.voice:
        return '음성';
      case ChannelType.announcement:
        return '공지';
      case ChannelType.fileShare:
        return '파일공유';
    }
  }
}

/// 게시글 타입
enum PostType {
  general,
  announcement,
  question,
  poll,
  fileShare,
}

/// 게시글 모델
class PostModel {
  final int id;
  final int channelId;
  final UserSummaryModel author;
  final String title;
  final String content;
  final PostType type;
  final bool isPinned;
  final int viewCount;
  final int likeCount;
  final List<String> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PostModel({
    required this.id,
    required this.channelId,
    required this.author,
    required this.title,
    required this.content,
    required this.type,
    required this.isPinned,
    required this.viewCount,
    required this.likeCount,
    required this.attachments,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: (json['id'] ?? 0) as int,
      channelId: (json['channelId'] ?? 0) as int,
      author: UserSummaryModel.fromJson(json['author'] ?? {}),
      title: (json['title'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      type: _parsePostType(json['type']?.toString()),
      isPinned: json['isPinned'] == true,
      viewCount: (json['viewCount'] ?? 0) as int,
      likeCount: (json['likeCount'] ?? 0) as int,
      attachments: ((json['attachments'] as List?) ?? [])
          .map((e) => e.toString())
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'channelId': channelId,
      'author': author.toJson(),
      'title': title,
      'content': content,
      'type': type.name.toUpperCase(),
      'isPinned': isPinned,
      'viewCount': viewCount,
      'likeCount': likeCount,
      'attachments': attachments,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get typeDisplayName {
    switch (type) {
      case PostType.general:
        return '일반';
      case PostType.announcement:
        return '공지';
      case PostType.question:
        return '질문';
      case PostType.poll:
        return '투표';
      case PostType.fileShare:
        return '파일공유';
    }
  }
}

/// 댓글 모델
class CommentModel {
  final int id;
  final int postId;
  final UserSummaryModel author;
  final String content;
  final int? parentCommentId;
  final int likeCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CommentModel({
    required this.id,
    required this.postId,
    required this.author,
    required this.content,
    this.parentCommentId,
    required this.likeCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: (json['id'] ?? 0) as int,
      postId: (json['postId'] ?? 0) as int,
      author: UserSummaryModel.fromJson(json['author'] ?? {}),
      content: (json['content'] ?? '').toString(),
      parentCommentId: json['parentCommentId'] as int?,
      likeCount: (json['likeCount'] ?? 0) as int,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'author': author.toJson(),
      'content': content,
      'parentCommentId': parentCommentId,
      'likeCount': likeCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isReply => parentCommentId != null;
}

/// 그룹 멤버 역할 모델
class GroupRoleModel {
  final int id;
  final int groupId;
  final String name;
  final bool isSystemRole;
  final List<String> permissions;

  const GroupRoleModel({
    required this.id,
    required this.groupId,
    required this.name,
    required this.isSystemRole,
    required this.permissions,
  });

  factory GroupRoleModel.fromJson(Map<String, dynamic> json) {
    return GroupRoleModel(
      id: (json['id'] ?? 0) as int,
      groupId: (json['groupId'] ?? 0) as int,
      name: (json['name'] ?? '').toString(),
      isSystemRole: json['isSystemRole'] == true,
      permissions: ((json['permissions'] as List?) ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'name': name,
      'isSystemRole': isSystemRole,
      'permissions': permissions,
    };
  }
}

/// 그룹 멤버 모델
class GroupMemberModel {
  final int id;
  final int groupId;
  final UserSummaryModel user;
  final GroupRoleModel role;
  final DateTime joinedAt;

  const GroupMemberModel({
    required this.id,
    required this.groupId,
    required this.user,
    required this.role,
    required this.joinedAt,
  });

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    return GroupMemberModel(
      id: (json['id'] ?? 0) as int,
      groupId: (json['groupId'] ?? 0) as int,
      user: UserSummaryModel.fromJson(json['user'] ?? {}),
      role: GroupRoleModel.fromJson(json['role'] ?? {}),
      joinedAt: DateTime.parse(json['joinedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'user': user.toJson(),
      'role': role.toJson(),
      'joinedAt': joinedAt.toIso8601String(),
    };
  }
}

/// 백엔드 WorkspaceDto에 대응하는 모델 (명세서 요구사항)
class WorkspaceDtoModel {
  final int groupId;
  final String groupName;
  final String myRole;
  final List<PostModel> notices;
  final List<ChannelModel> channels;
  final List<GroupMemberModel> members;

  const WorkspaceDtoModel({
    required this.groupId,
    required this.groupName,
    required this.myRole,
    required this.notices,
    required this.channels,
    required this.members,
  });

  factory WorkspaceDtoModel.fromJson(Map<String, dynamic> json) {
    return WorkspaceDtoModel(
      groupId: (json['groupId'] ?? 0) as int,
      groupName: (json['groupName'] ?? '').toString(),
      myRole: (json['myRole'] ?? 'MEMBER').toString(),
      notices: ((json['notices'] as List?) ?? [])
          .map((e) => PostModel.fromJson(e))
          .toList(),
      channels: ((json['channels'] as List?) ?? [])
          .map((e) => ChannelModel.fromJson(e))
          .toList(),
      members: ((json['members'] as List?) ?? [])
          .map((e) => GroupMemberModel.fromJson(e))
          .toList(),
    );
  }

  /// WorkspaceDetailModel로 변환
  WorkspaceDetailModel toWorkspaceDetailModel() {
    // members 배열에서 내 멤버십을 찾아서 실제 권한 정보 가져오기
    GroupMemberModel? actualMyMembership;

    // 현재 사용자의 실제 멤버십을 members 리스트에서 찾기
    // myRole을 기준으로 해당하는 멤버를 찾거나, 첫 번째 멤버를 내 멤버십으로 가정
    if (members.isNotEmpty) {
      // 역할 이름이 일치하는 멤버를 찾기
      actualMyMembership = members.firstWhere(
        (member) => member.role.name == myRole,
        orElse: () => members.first, // 찾지 못하면 첫 번째 멤버 사용 (임시)
      );
    }

    return WorkspaceDetailModel(
      workspace: WorkspaceModel(
        id: 0, // 워크스페이스 ID는 별도 조회 필요
        groupId: groupId,
        name: groupName,
        description: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      group: GroupModel(
        id: groupId,
        name: groupName,
        description: null,
        owner: UserSummaryModel(id: 0, name: '', email: ''),
        visibility: GroupVisibility.public,
        groupType: GroupType.autonomous,
        isRecruiting: false,
        tags: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      myMembership: actualMyMembership ?? GroupMemberModel(
        id: 0,
        groupId: groupId,
        user: UserSummaryModel(id: 0, name: '', email: ''),
        role: GroupRoleModel(
          id: 0,
          groupId: groupId,
          name: myRole,
          isSystemRole: true,
          // 기본 관리자 권한을 부여 (임시)
          permissions: myRole == 'OWNER' || myRole == '그룹장' || myRole == 'ADMIN'
            ? ['GROUP_MANAGE', 'MEMBER_APPROVE', 'MEMBER_KICK', 'CHANNEL_MANAGE', 'ROLE_MANAGE']
            : [],
        ),
        joinedAt: DateTime.now(),
      ),
      channels: channels,
      announcements: notices,
      members: members,
    );
  }
}

/// 워크스페이스 전체 정보 (3개 탭 데이터 포함)
class WorkspaceDetailModel {
  final WorkspaceModel workspace;
  final GroupModel group;
  final GroupMemberModel? myMembership;
  final List<ChannelModel> channels;
  final List<PostModel> announcements;
  final List<GroupMemberModel> members;

  const WorkspaceDetailModel({
    required this.workspace,
    required this.group,
    this.myMembership,
    required this.channels,
    required this.announcements,
    required this.members,
  });

  factory WorkspaceDetailModel.fromJson(Map<String, dynamic> json) {
    return WorkspaceDetailModel(
      workspace: WorkspaceModel.fromJson(json['workspace'] ?? {}),
      group: GroupModel.fromJson(json['group'] ?? {}),
      myMembership: json['myMembership'] != null
          ? GroupMemberModel.fromJson(json['myMembership'])
          : null,
      channels: ((json['channels'] as List?) ?? [])
          .map((e) => ChannelModel.fromJson(e))
          .toList(),
      announcements: ((json['announcements'] as List?) ?? [])
          .map((e) => PostModel.fromJson(e))
          .toList(),
      members: ((json['members'] as List?) ?? [])
          .map((e) => GroupMemberModel.fromJson(e))
          .toList(),
    );
  }

  /// 내가 가진 권한 확인
  bool hasPermission(String permission) {
    return myMembership?.role.permissions.contains(permission) ?? false;
  }

  /// 관리 권한 여부
  bool get canManage => hasPermission('GROUP_MANAGE');

  /// 멤버 관리 권한 여부
  bool get canManageMembers => hasPermission('MEMBER_APPROVE') || hasPermission('MEMBER_KICK');

  /// 채널 관리 권한 여부
  bool get canManageChannels => hasPermission('CHANNEL_MANAGE');

  /// 역할 관리 권한 여부
  bool get canManageRoles => canManageMembers; // 멤버 관리 권한이 있으면 역할도 관리 가능

  /// 공지 작성 권한 여부
  bool get canCreateAnnouncements => hasPermission('POST_CREATE') &&
      (myMembership?.role.name == '그룹장' || myMembership?.role.name == '지도교수');
}

// Helper functions for parsing enums
ChannelType _parseChannelType(String? type) {
  switch (type?.toUpperCase()) {
    case 'TEXT':
      return ChannelType.text;
    case 'VOICE':
      return ChannelType.voice;
    case 'ANNOUNCEMENT':
      return ChannelType.announcement;
    case 'FILE_SHARE':
      return ChannelType.fileShare;
    default:
      return ChannelType.text;
  }
}

PostType _parsePostType(String? type) {
  switch (type?.toUpperCase()) {
    case 'GENERAL':
      return PostType.general;
    case 'ANNOUNCEMENT':
      return PostType.announcement;
    case 'QUESTION':
      return PostType.question;
    case 'POLL':
      return PostType.poll;
    case 'FILE_SHARE':
      return PostType.fileShare;
    default:
      return PostType.general;
  }
}
