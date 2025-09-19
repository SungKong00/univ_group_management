import 'package:dio/dio.dart';

import '../../core/network/dio_client.dart';
import '../models/group_model.dart';
import '../models/workspace_models.dart';

class WorkspaceService {
  final DioClient _dioClient;

  WorkspaceService(this._dioClient);

  /// 새로운 통합 워크스페이스 API 호출 (명세서 요구사항)
  Future<WorkspaceDetailModel> getWorkspaceByGroupNew(int groupId) async {
    try {
      final response = await _dioClient.get('/groups/$groupId/workspace');
      final data = response.data;
      if (data['success'] != true) {
        throw Exception(data['error']?['message'] ?? 'Failed to fetch workspace');
      }

      // 백엔드 WorkspaceDto를 프론트엔드 모델로 변환
      final workspaceDto = WorkspaceDtoModel.fromJson(data['data']);
      return workspaceDto.toWorkspaceDetailModel();
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw WorkspaceAccessException(
          message: e.response?.data is Map<String, dynamic>
              ? (e.response?.data['error']?['message']?.toString() ?? '접근 권한이 없습니다.')
              : '접근 권한이 없습니다.',
          statusCode: 403,
        );
      }
      throw Exception('Failed to load workspace: ${e.message}');
    } catch (e) {
      throw Exception('Failed to load workspace: $e');
    }
  }

  /// 기존 워크스페이스 조회 (하위 호환성을 위해 유지)
  Future<WorkspaceDetailModel> getWorkspaceByGroup(int groupId) async {
    try {
      // 백엔드의 통합 워크스페이스 API를 직접 호출 (권한 확인 포함)
      final response = await _dioClient.get('/groups/$groupId/workspace');
      final data = response.data;
      if (data['success'] != true) {
        throw Exception(data['error']?['message'] ?? 'Failed to fetch workspace');
      }

      // 백엔드 WorkspaceDto를 프론트엔드 모델로 변환
      final workspaceDto = WorkspaceDtoModel.fromJson(data['data']);
      return workspaceDto.toWorkspaceDetailModel();
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw WorkspaceAccessException(
          message: e.response?.data is Map<String, dynamic>
              ? (e.response?.data['error']?['message']?.toString() ?? '접근 권한이 없습니다.')
              : '접근 권한이 없습니다.',
          statusCode: 403,
        );
      }
      throw Exception('Failed to load workspace: ${e.message}');
    } catch (e) {
      throw Exception('Failed to load workspace: $e');
    }
  }

  /// 더 이상 사용하지 않는 복잡한 구현 (참고용으로 보존)
  Future<WorkspaceDetailModel> _getWorkspaceByGroupLegacy(int groupId) async {
    try {
      // 0) 내 멤버십 확인 (비회원 접근 차단)
      GroupMemberModel? myMembership;
      try {
        final meResp = await _dioClient.get('/groups/$groupId/members/me');
        final meJson = meResp.data;
        if (meJson['success'] == true) {
          myMembership = GroupMemberModel.fromJson(meJson['data']);
        } else {
          throw Exception('Not a member');
        }
      } catch (_) {
        throw Exception('이 그룹의 멤버만 워크스페이스에 접근할 수 있습니다.');
      }

      // 1) 그룹 정보
      final groupResp = await _dioClient.get('/groups/$groupId');
      final groupJson = groupResp.data;
      if (groupJson['success'] != true) {
        throw Exception(groupJson['error']?['message'] ?? 'Failed to fetch group');
      }
      final group = GroupModel.fromJson(groupJson['data']);

      // 2) 워크스페이스 목록 (보통 1개)
      final wsResp = await _dioClient.get('/groups/$groupId/workspaces');
      final wsJson = wsResp.data;
      if (wsJson['success'] != true) {
        throw Exception(wsJson['error']?['message'] ?? 'Failed to fetch workspaces');
      }
      final workspaces = (wsJson['data'] as List)
          .map((e) => WorkspaceModel.fromJson(e))
          .toList();
      if (workspaces.isEmpty) {
        throw Exception('No workspace found for this group');
      }
      final workspace = workspaces.first;

      // 3) 채널 목록 (부분 실패 허용)
      List<ChannelModel> channels = [];
      try {
        final chResp = await _dioClient.get('/workspaces/${workspace.id}/channels');
        final chJson = chResp.data;
        if (chJson['success'] == true) {
          channels = (chJson['data'] as List)
              .map((e) => ChannelModel.fromJson(e))
              .toList();
        }
      } on DioException {
        channels = [];
      } catch (_) {
        channels = [];
      }

      // 4) 공지사항(announcement 채널들 포스트) - 부분 실패 허용
      final announcements = <PostModel>[];
      for (final channel in channels.where((c) => c.type == ChannelType.announcement)) {
        try {
          final postsResp = await _dioClient.get('/channels/${channel.id}/posts');
          final postsJson = postsResp.data;
          if (postsJson['success'] == true) {
            announcements.addAll(
              (postsJson['data'] as List).map((e) => PostModel.fromJson(e)),
            );
          }
        } catch (_) {/* ignore per-channel errors */}
      }

      // 5) 멤버 목록 (백엔드 Page 응답 또는 권한 문제를 고려, 부분 실패 허용)
      List<GroupMemberModel> members = [];
      try {
        final memResp = await _dioClient.get('/groups/$groupId/members');
        final memJson = memResp.data;
        if (memJson['success'] == true) {
          final data = memJson['data'];
          final list = data is List
              ? data
              : (data is Map<String, dynamic> && data['content'] is List)
                  ? data['content'] as List
                  : <dynamic>[];
          members = list.map((e) => GroupMemberModel.fromJson(e)).toList();
        }
      } on DioException catch (e) {
        // 403/500 등은 멤버 로드만 생략하고 계속 진행
        if (e.response?.statusCode == 403 || e.response?.statusCode == 401 || e.response?.statusCode == 500) {
          members = [];
        } else {
          members = [];
        }
      } catch (_) {
        members = [];
      }

      return WorkspaceDetailModel(
        workspace: workspace,
        group: group,
        myMembership: myMembership,
        channels: channels,
        announcements: announcements,
        members: members,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw WorkspaceAccessException(
          message: e.response?.data is Map<String, dynamic>
              ? (e.response?.data['error']?['message']?.toString() ?? '접근 권한이 없습니다.')
              : '접근 권한이 없습니다.',
          statusCode: 403,
        );
      }
      throw Exception('Failed to load workspace: ${e.message}');
    } catch (e) {
      throw Exception('Failed to load workspace: $e');
    }
  }

  /// 워크스페이스 내 채널 목록 조회
  Future<List<ChannelModel>> getChannels(int workspaceId) async {
    try {
      final response = await _dioClient.get('/workspaces/$workspaceId/channels');
      final data = response.data;
      if (data['success'] != true) {
        throw Exception(data['error']?['message'] ?? 'Failed to fetch channels');
      }
      return (data['data'] as List).map((e) => ChannelModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load channels: $e');
    }
  }

  /// 채널 생성
  Future<ChannelModel> createChannel({
    required int workspaceId,
    required String name,
    String? description,
    ChannelType type = ChannelType.text,
    bool isPrivate = false,
  }) async {
    try {
      final response = await _dioClient.post('/workspaces/$workspaceId/channels', data: {
        'name': name,
        'description': description,
        'type': type.name.toUpperCase(),
        'isPrivate': isPrivate,
      });
      final data = response.data;
      if (data['success'] != true) {
        throw Exception(data['error']?['message'] ?? 'Failed to create channel');
      }
      return ChannelModel.fromJson(data['data']);
    } catch (e) {
      throw Exception('Failed to create channel: $e');
    }
  }

  /// 채널 수정
  Future<ChannelModel> updateChannel({
    required int channelId,
    String? name,
    String? description,
    ChannelType? type,
    bool? isPrivate,
  }) async {
    try {
      final requestData = <String, dynamic>{};
      if (name != null) requestData['name'] = name;
      if (description != null) requestData['description'] = description;
      if (type != null) requestData['type'] = type.name.toUpperCase();
      if (isPrivate != null) requestData['isPrivate'] = isPrivate;

      final response = await _dioClient.put('/channels/$channelId', data: requestData);
      final data = response.data;
      if (data['success'] != true) {
        throw Exception(data['error']?['message'] ?? 'Failed to update channel');
      }
      return ChannelModel.fromJson(data['data']);
    } catch (e) {
      throw Exception('Failed to update channel: $e');
    }
  }

  /// 채널 삭제
  Future<void> deleteChannel(int channelId) async {
    try {
      final response = await _dioClient.delete('/channels/$channelId');
      final data = response.data;
      if (data['success'] != true) {
        throw Exception(data['error']?['message'] ?? 'Failed to delete channel');
      }
    } catch (e) {
      throw Exception('Failed to delete channel: $e');
    }
  }

  /// 관리자 통계 조회
  Future<Map<String, dynamic>> getAdminStats(int groupId) async {
    try {
      final response = await _dioClient.get('/groups/$groupId/admin/stats');
      final data = response.data;
      if (data['success'] != true) {
        throw Exception(data['error']?['message'] ?? 'Failed to fetch admin stats');
      }
      return data['data'];
    } catch (e) {
      throw Exception('Failed to load admin stats: $e');
    }
  }

  /// 그룹 역할 목록 조회
  Future<List<GroupRoleModel>> getGroupRoles(int groupId) async {
    try {
      final response = await _dioClient.get('/groups/$groupId/roles');
      final data = response.data;
      if (data['success'] != true) {
        throw Exception(data['error']?['message'] ?? 'Failed to fetch roles');
      }
      final List<dynamic> rolesList = data['data'];
      return rolesList.map((role) => GroupRoleModel.fromJson(role)).toList();
    } catch (e) {
      throw Exception('Failed to load roles: $e');
    }
  }

  /// 역할 생성
  Future<Map<String, dynamic>> createRole({
    required int groupId,
    required String name,
    required List<String> permissions,
  }) async {
    try {
      final response = await _dioClient.post('/groups/$groupId/roles', data: {
        'roleName': name,
        'permissions': permissions,
      });
      final data = response.data;
      if (data['success'] != true) {
        throw Exception(data['error']?['message'] ?? 'Failed to create role');
      }
      return data['data'];
    } catch (e) {
      throw Exception('Failed to create role: $e');
    }
  }

  /// 역할 수정
  Future<Map<String, dynamic>> updateRole({
    required int groupId,
    required int roleId,
    required String name,
    required List<String> permissions,
  }) async {
    try {
      final response = await _dioClient.patch('/groups/$groupId/roles/$roleId', data: {
        'roleName': name,
        'permissions': permissions,
      });
      final data = response.data;
      if (data['success'] != true) {
        throw Exception(data['error']?['message'] ?? 'Failed to update role');
      }
      return data['data'];
    } catch (e) {
      throw Exception('Failed to update role: $e');
    }
  }

  /// 역할 삭제
  Future<void> deleteRole({
    required int groupId,
    required int roleId,
  }) async {
    try {
      final response = await _dioClient.delete('/groups/$groupId/roles/$roleId');
      final data = response.data;
      if (data['success'] != true) {
        throw Exception(data['error']?['message'] ?? 'Failed to delete role');
      }
    } catch (e) {
      throw Exception('Failed to delete role: $e');
    }
  }

  /// 가입 대기 멤버 목록 조회
  Future<List<Map<String, dynamic>>> getPendingMembers(int groupId) async {
    try {
      final response = await _dioClient.get('/groups/$groupId/members?status=pending');
      final data = response.data;
      if (data['success'] != true) {
        throw Exception(data['error']?['message'] ?? 'Failed to fetch pending members');
      }
      return List<Map<String, dynamic>>.from(data['data']);
    } catch (e) {
      throw Exception('Failed to load pending members: $e');
    }
  }

  /// 가입 승인/반려
  Future<void> decideMembership({
    required int groupId,
    required int userId,
    required bool approve,
    String? reason,
  }) async {
    try {
      final response = await _dioClient.post('/groups/$groupId/members/$userId/decision', data: {
        'approve': approve,
        'reason': reason,
      });
      final data = response.data;
      if (data['success'] != true) {
        throw Exception(data['error']?['message'] ?? 'Failed to decide membership');
      }
    } catch (e) {
      throw Exception('Failed to decide membership: $e');
    }
  }

  /// 멤버 역할 변경
  Future<void> updateMemberRole({
    required int groupId,
    required int userId,
    required int roleId,
  }) async {
    try {
      final response = await _dioClient.patch('/groups/$groupId/members/$userId/role', data: {
        'roleId': roleId,
      });
      final data = response.data;
      if (data['success'] != true) {
        throw Exception(data['error']?['message'] ?? 'Failed to update member role');
      }
    } catch (e) {
      throw Exception('Failed to update member role: $e');
    }
  }

  /// 멤버 강제 탈퇴
  Future<void> removeMember({
    required int groupId,
    required int userId,
  }) async {
    try {
      final response = await _dioClient.delete('/groups/$groupId/members/$userId');
      final data = response.data;
      if (data['success'] != true) {
        throw Exception(data['error']?['message'] ?? 'Failed to remove member');
      }
    } catch (e) {
      throw Exception('Failed to remove member: $e');
    }
  }

  /// 개인 권한 오버라이드 조회
  Future<Map<String, dynamic>> getMemberPermissions({
    required int groupId,
    required int userId,
  }) async {
    try {
      final response = await _dioClient.get('/groups/$groupId/members/$userId/permissions');
      final data = response.data;
      if (data['success'] != true) {
        throw Exception(data['error']?['message'] ?? 'Failed to fetch member permissions');
      }
      return data['data'];
    } catch (e) {
      throw Exception('Failed to load member permissions: $e');
    }
  }

  /// 개인 권한 오버라이드 설정
  Future<void> setMemberPermissions({
    required int groupId,
    required int userId,
    required Map<String, String> overrides, // ALLOW, DENY, INHERIT
  }) async {
    try {
      final response = await _dioClient.put('/groups/$groupId/members/$userId/permissions', data: {
        'overrides': overrides,
      });
      final data = response.data;
      if (data['success'] != true) {
        throw Exception(data['error']?['message'] ?? 'Failed to set member permissions');
      }
    } catch (e) {
      throw Exception('Failed to set member permissions: $e');
    }
  }

  /// 특정 채널에 대한 현재 사용자의 권한 조회
  Future<List<String>> getChannelPermissions(int channelId) async {
    try {
      final response = await _dioClient.get('/channels/$channelId/permissions/me');
      final data = response.data;
      if (data['success'] != true) {
        throw Exception(data['error']?['message'] ?? 'Failed to fetch channel permissions');
      }

      // 백엔드에서 권한 목록을 반환한다고 가정
      final permissions = (data['data']['permissions'] as List?)
          ?.map((e) => e.toString())
          .toList() ?? [];

      return permissions;
    } catch (e) {
      throw Exception('Failed to load channel permissions: $e');
    }
  }

  /// 그룹 정보 수정
  Future<void> updateGroupInfo({
    required int groupId,
    String? name,
    String? description,
    List<String>? tags,
  }) async {
    try {
      final requestData = <String, dynamic>{};
      if (name != null) requestData['name'] = name;
      if (description != null) requestData['description'] = description;
      if (tags != null) requestData['tags'] = tags;

      final response = await _dioClient.put('/groups/$groupId', data: requestData);
      final data = response.data;
      if (data['success'] != true) {
        throw Exception(data['error']?['message'] ?? 'Failed to update group info');
      }
    } catch (e) {
      throw Exception('Failed to update group info: $e');
    }
  }

  /// 그룹장 위임
  Future<void> delegateLeadership({
    required int groupId,
    required int newLeaderId,
  }) async {
    try {
      final response = await _dioClient.patch('/groups/$groupId/leader', data: {
        'newLeaderId': newLeaderId,
      });
      final data = response.data;
      if (data['success'] != true) {
        throw Exception(data['error']?['message'] ?? 'Failed to delegate leadership');
      }
    } catch (e) {
      throw Exception('Failed to delegate leadership: $e');
    }
  }

  /// 채널의 게시글 목록 조회
  Future<List<PostModel>> getChannelPosts(int channelId) async {
    try {
      final response = await _dioClient.get('/channels/$channelId/posts');
      final data = response.data;
      if (data['success'] != true) {
        throw Exception(data['error']?['message'] ?? 'Failed to fetch posts');
      }
      return (data['data'] as List).map((e) => PostModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load posts: $e');
    }
  }

  /// 게시글 생성
  Future<PostModel> createPost({
    required int channelId,
    required String content,
    PostType type = PostType.general,
    List<String> attachments = const [],
  }) async {
    try {
      final response = await _dioClient.post('/channels/$channelId/posts', data: {
        'content': content,
        'type': type.name.toUpperCase(),
        'attachments': attachments,
      });
      final data = response.data;
      if (data['success'] != true) {
        throw Exception(data['error']?['message'] ?? 'Failed to create post');
      }
      return PostModel.fromJson(data['data']);
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  /// 게시글 수정
  Future<PostModel> updatePost({
    required int postId,
    String? title,
    String? content,
    PostType? type,
    List<String>? attachments,
  }) async {
    try {
      final requestData = <String, dynamic>{};
      if (title != null) requestData['title'] = title;
      if (content != null) requestData['content'] = content;
      if (type != null) requestData['type'] = type.name.toUpperCase();
      if (attachments != null) requestData['attachments'] = attachments;

      final response = await _dioClient.put('/posts/$postId', data: requestData);
      final data = response.data;
      if (data['success'] != true) {
        throw Exception(data['error']?['message'] ?? 'Failed to update post');
      }
      return PostModel.fromJson(data['data']);
    } catch (e) {
      throw Exception('Failed to update post: $e');
    }
  }

  /// 게시글 삭제
  Future<void> deletePost(int postId) async {
    try {
      final response = await _dioClient.delete('/posts/$postId');
      final data = response.data;
      if (data['success'] != true) {
        throw Exception(data['error']?['message'] ?? 'Failed to delete post');
      }
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }

  /// 게시글의 댓글 목록 조회
  Future<List<CommentModel>> getPostComments(int postId) async {
    try {
      final response = await _dioClient.get('/posts/$postId/comments');
      final data = response.data;
      if (data['success'] != true) {
        throw Exception(data['error']?['message'] ?? 'Failed to fetch comments');
      }
      return (data['data'] as List).map((e) => CommentModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load comments: $e');
    }
  }

  /// 댓글 생성
  Future<CommentModel> createComment({
    required int postId,
    required String content,
    int? parentCommentId,
  }) async {
    try {
      final response = await _dioClient.post('/posts/$postId/comments', data: {
        'content': content,
        'parentCommentId': parentCommentId,
      });
      final data = response.data;
      if (data['success'] != true) {
        throw Exception(data['error']?['message'] ?? 'Failed to create comment');
      }
      return CommentModel.fromJson(data['data']);
    } catch (e) {
      throw Exception('Failed to create comment: $e');
    }
  }

  /// 댓글 수정
  Future<CommentModel> updateComment({
    required int commentId,
    required String content,
  }) async {
    try {
      final response = await _dioClient.put('/comments/$commentId', data: {
        'content': content,
      });
      final data = response.data;
      if (data['success'] != true) {
        throw Exception(data['error']?['message'] ?? 'Failed to update comment');
      }
      return CommentModel.fromJson(data['data']);
    } catch (e) {
      throw Exception('Failed to update comment: $e');
    }
  }

  /// 댓글 삭제
  Future<void> deleteComment(int commentId) async {
    try {
      final response = await _dioClient.delete('/comments/$commentId');
      final data = response.data;
      if (data['success'] != true) {
        throw Exception(data['error']?['message'] ?? 'Failed to delete comment');
      }
    } catch (e) {
      throw Exception('Failed to delete comment: $e');
    }
  }

  /// 그룹 가입 신청
  Future<void> requestJoinGroup({
    required int groupId,
    String? message,
  }) async {
    try {
      final resp = await _dioClient.post('/groups/$groupId/join', data: {
        if (message != null) 'message': message,
      });
      final data = resp.data;
      if (data['success'] != true) {
        throw Exception(data['error']?['message'] ?? 'Failed to request group join');
      }
    } catch (e) {
      throw Exception('가입 신청에 실패했습니다: $e');
    }
  }

  /// 공지사항 작성
  Future<void> createAnnouncement({
    required int groupId,
    required String content,
  }) async {
    try {
      // 워크스페이스 정보를 먼저 가져와서 기본 채널 ID 확보
      final workspaceResponse = await _dioClient.get('/groups/$groupId/workspace');
      if (workspaceResponse.data['success'] != true) {
        throw Exception('워크스페이스 정보를 가져올 수 없습니다');
      }

      final channels = workspaceResponse.data['data']['channels'] as List;
      if (channels.isEmpty) {
        throw Exception('공지사항을 작성할 채널이 없습니다');
      }

      // 첫 번째 채널을 공지 채널로 사용 (또는 announcement 타입 채널 찾기)
      final announcementChannel = channels.firstWhere(
        (channel) => channel['type'] == 'ANNOUNCEMENT',
        orElse: () => channels.first,
      );

      final channelId = announcementChannel['id'];

      // 게시글 작성 API 호출
      final response = await _dioClient.post('/channels/$channelId/posts', data: {
        'content': content,
        'type': 'ANNOUNCEMENT',
      });

      final data = response.data;
      if (data['success'] != true) {
        throw Exception(data['error']?['message'] ?? 'Failed to create announcement');
      }
    } catch (e) {
      throw Exception('공지사항 작성에 실패했습니다: $e');
    }
  }

}

class WorkspaceAccessException implements Exception {
  final String message;
  final int? statusCode;

  const WorkspaceAccessException({
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => 'WorkspaceAccessException($statusCode): $message';
}
