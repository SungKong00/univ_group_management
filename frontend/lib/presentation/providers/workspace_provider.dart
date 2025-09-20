import 'package:flutter/foundation.dart';
import '../../data/models/workspace_models.dart';
import '../../data/models/auth_models.dart';
import '../../data/services/workspace_service.dart';

class WorkspaceProvider extends ChangeNotifier {
  final WorkspaceService _workspaceService;

  WorkspaceProvider(this._workspaceService);

  // State
  WorkspaceDetailModel? _currentWorkspace;
  bool _isLoading = false;
  String? _error;
  bool _accessDenied = false;

  // Current tab index (0: 공지, 1: 채널, 2: 멤버)
  int _currentTabIndex = 0;

  // Sidebar visibility state
  bool _isSidebarVisible = true;

  // 기본 채널 자동 선택 여부 (첫 로드 한정)
  bool _didAutoSelectChannel = false;

  // 모바일 전용 상태
  bool _isMobileNavigatorVisible = false;

  // Current channel (when in channel detail view)
  ChannelModel? _currentChannel;
  List<PostModel> _currentChannelPosts = [];
  Map<int, List<CommentModel>> _postComments = {};

  // Channel permissions for current user
  Map<int, List<String>> _channelPermissions = {};

  // Getters
  WorkspaceDetailModel? get currentWorkspace => _currentWorkspace;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAccessDenied => _accessDenied;
  int get currentTabIndex => _currentTabIndex;
  bool get isSidebarVisible => _isSidebarVisible;
  ChannelModel? get currentChannel => _currentChannel;
  List<PostModel> get currentChannelPosts => _currentChannelPosts;


  // 현재 워크스페이스의 채널 (정렬됨)
  List<ChannelModel> get channels {
    final channels = List<ChannelModel>.from(_currentWorkspace?.channels ?? []);
    channels.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return channels;
  }

  // 현재 워크스페이스의 멤버 (정렬됨)
  List<GroupMemberModel> get members {
    final members = List<GroupMemberModel>.from(_currentWorkspace?.members ?? []);
    members.sort((a, b) => a.joinedAt.compareTo(b.joinedAt));
    return members;
  }

  // 권한 체크
  bool get canManage => _currentWorkspace?.canManage ?? false;
  bool get canManageMembers => _currentWorkspace?.canManageMembers ?? false;
  bool get canManageChannels => _currentWorkspace?.canManageChannels ?? false;

  bool get isMobileNavigatorVisible => _isMobileNavigatorVisible;

  /// 특정 채널에 대한 권한 확인
  bool hasChannelPermission(int channelId, String permission) {
    final permissions = _channelPermissions[channelId] ?? [];
    return permissions.contains(permission);
  }

  /// 현재 채널에서 글 작성 권한이 있는지 확인
  bool get canWriteInCurrentChannel {
    if (_currentChannel == null) return false;
    return hasChannelPermission(_currentChannel!.id, 'POST_WRITE');
  }

  /// 워크스페이스 로드
  Future<void> loadWorkspace(
    int groupId, {
    bool autoSelectFirstChannel = true,
    bool mobileNavigatorVisible = false,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      _accessDenied = false;
      notifyListeners();

      _currentWorkspace = await _workspaceService.getWorkspaceByGroup(groupId);

      _isMobileNavigatorVisible = mobileNavigatorVisible;
      _isLoading = false;
      notifyListeners();

      // 첫 로드 시 기본 채널 자동 선택
      if (autoSelectFirstChannel && !_didAutoSelectChannel && _currentChannel == null) {
        final ws = _currentWorkspace;
        if (ws != null && ws.channels.isNotEmpty) {
          // displayOrder 기준 정렬 후 첫 번째 채널 선택
          final sorted = List<ChannelModel>.from(ws.channels)
            ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
          ChannelModel defaultChannel = sorted.first;

          _didAutoSelectChannel = true;
          _isMobileNavigatorVisible = false;
          // 비동기로 선택하여 게시글/권한 로드
          await selectChannel(defaultChannel);
        }
      }
    } on WorkspaceAccessException catch (e) {
      _isLoading = false;
      _accessDenied = true;
      _error = e.message;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 탭 변경
  void setTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  /// 사이드바 토글
  void toggleSidebar() {
    _isSidebarVisible = !_isSidebarVisible;
    notifyListeners();
  }

  /// 사이드바 표시/숨김 설정
  void setSidebarVisible(bool visible) {
    if (_isSidebarVisible != visible) {
      _isSidebarVisible = visible;
      notifyListeners();
    }
  }

  /// 채널 선택 및 상세 정보 로드
  Future<void> selectChannel(ChannelModel channel) async {
    try {
      _currentChannel = channel;
      _isMobileNavigatorVisible = false;
      _isLoading = true;
      notifyListeners();

      // 채널 게시글과 권한 정보를 동시에 로드
      final futures = await Future.wait([
        _workspaceService.getChannelPosts(channel.id),
        _loadChannelPermissions(channel.id),
      ]);

      _currentChannelPosts = futures[0] as List<PostModel>;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 채널 권한 정보 로드
  Future<void> _loadChannelPermissions(int channelId) async {
    try {
      // 실제 API 호출로 권한 정보 로드
      final permissions = await _workspaceService.getChannelPermissions(channelId);
      _channelPermissions[channelId] = permissions;
    } catch (e) {
      // API 호출 실패 시 폴백 제거: 서버 권한에만 의존
      print('Failed to load channel permissions: $e');
      _channelPermissions[channelId] = [];
      _error = '권한 정보를 불러오지 못했습니다.';
    }
  }

  /// 테스트용: 특정 채널의 권한 토글 (개발/데모용)
  void toggleChannelWritePermission(int channelId) {
    final currentPermissions = _channelPermissions[channelId] ?? [];
    final hasWritePermission = currentPermissions.contains('POST_WRITE');

    if (hasWritePermission) {
      // 글 작성 권한 제거
      _channelPermissions[channelId] = currentPermissions
          .where((permission) => permission != 'POST_WRITE' && permission != 'FILE_UPLOAD')
          .toList();
    } else {
      // 글 작성 권한 추가
      final updatedPermissions = List<String>.from(currentPermissions);
      if (!updatedPermissions.contains('POST_WRITE')) {
        updatedPermissions.add('POST_WRITE');
      }
      if (!updatedPermissions.contains('FILE_UPLOAD')) {
        updatedPermissions.add('FILE_UPLOAD');
      }
      _channelPermissions[channelId] = updatedPermissions;
    }

    notifyListeners();
  }

  /// 채널 상세에서 나가기
  void exitChannel() {
    _currentChannel = null;
    _currentChannelPosts.clear();
    notifyListeners();
  }

  void showMobileNavigator() {
    if (!_isMobileNavigatorVisible || _currentChannel != null) {
      _currentChannel = null;
      _currentChannelPosts.clear();
      _isMobileNavigatorVisible = true;
      notifyListeners();
    }
  }


  void setMobileNavigatorVisible(bool visible) {
    if (_isMobileNavigatorVisible != visible) {
      _isMobileNavigatorVisible = visible;
      if (visible) {
        _currentChannel = null;
        _currentChannelPosts.clear();
      }
      notifyListeners();
    }
  }


  /// 새 게시글 생성
  Future<void> createPost({
    required int channelId,
    required String content,
    PostType type = PostType.general,
    List<String> attachments = const [],
  }) async {
    try {
      final newPost = await _workspaceService.createPost(
        channelId: channelId,
        content: content,
        type: type,
        attachments: attachments,
      );

      // 현재 채널의 게시글이라면 목록에 추가
      if (_currentChannel?.id == channelId) {
        _currentChannelPosts.add(newPost);
        notifyListeners();
      }

    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 게시글 삭제
  Future<void> deletePost(int postId) async {
    try {
      await _workspaceService.deletePost(postId);

      // 현재 채널 게시글 목록에서 제거
      _currentChannelPosts.removeWhere((post) => post.id == postId);


      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 특정 게시글의 댓글 로드
  Future<void> loadPostComments(int postId) async {
    try {
      final comments = await _workspaceService.getPostComments(postId);
      _postComments[postId] = comments;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 댓글 가져오기
  List<CommentModel> getCommentsForPost(int postId) {
    return _postComments[postId] ?? [];
  }

  /// 새 댓글 생성
  Future<void> createComment({
    required int postId,
    required String content,
    int? parentCommentId,
  }) async {
    try {
      final newComment = await _workspaceService.createComment(
        postId: postId,
        content: content,
        parentCommentId: parentCommentId,
      );

      // 해당 게시글의 댓글 목록에 추가
      if (_postComments.containsKey(postId)) {
        _postComments[postId]!.add(newComment);
      } else {
        _postComments[postId] = [newComment];
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 댓글 삭제
  Future<void> deleteComment(int commentId, int postId) async {
    try {
      await _workspaceService.deleteComment(commentId);

      // 해당 게시글의 댓글 목록에서 제거
      if (_postComments.containsKey(postId)) {
        _postComments[postId]!.removeWhere((comment) => comment.id == commentId);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 새 채널 생성
  Future<bool> createChannel({
    required String name,
    String? description,
    ChannelType type = ChannelType.text,
    bool isPrivate = false,
  }) async {
    try {
      if (_currentWorkspace == null) return false;

      final newChannel = await _workspaceService.createChannel(
        workspaceId: _currentWorkspace!.workspace.id,
        name: name,
        description: description,
        type: type,
        isPrivate: isPrivate,
      );

      // 워크스페이스의 채널 목록에 추가
      final updatedChannels = List<ChannelModel>.from(_currentWorkspace!.channels);
      updatedChannels.add(newChannel);

      _currentWorkspace = WorkspaceDetailModel(
        workspace: _currentWorkspace!.workspace,
        group: _currentWorkspace!.group,
        myMembership: _currentWorkspace!.myMembership,
        channels: updatedChannels,
        members: _currentWorkspace!.members,
      );

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// 채널 삭제
  Future<bool> deleteChannel(int channelId) async {
    try {
      await _workspaceService.deleteChannel(channelId);

      if (_currentWorkspace != null) {
        // 워크스페이스의 채널 목록에서 제거
        final updatedChannels = _currentWorkspace!.channels
            .where((channel) => channel.id != channelId)
            .toList();

        _currentWorkspace = WorkspaceDetailModel(
          workspace: _currentWorkspace!.workspace,
          group: _currentWorkspace!.group,
          myMembership: _currentWorkspace!.myMembership,
          channels: updatedChannels,
          members: _currentWorkspace!.members,
        );

        // 현재 선택된 채널이라면 나가기
        if (_currentChannel?.id == channelId) {
          exitChannel();
        }

        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// 에러 초기화
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// 상태 초기화 (다른 워크스페이스로 이동할 때 사용)
  void reset() {
    _channelPermissions.clear();
    _currentWorkspace = null;
    _currentChannel = null;
    _currentChannelPosts.clear();
    _postComments.clear();
    _currentTabIndex = 0;
    _isSidebarVisible = true;
    _isLoading = false;
    _error = null;
    _accessDenied = false;
    _didAutoSelectChannel = false;
    _isMobileNavigatorVisible = false;
    notifyListeners();
  }

  /// 그룹 가입 신청
  Future<bool> requestJoin(int groupId, {String? message}) async {
    try {
      await _workspaceService.requestJoinGroup(groupId: groupId, message: message);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // === 멤버 관리 메서드 ===

  /// 그룹 역할 목록 조회
  Future<List<GroupRoleModel>> getGroupRoles(int groupId) async {
    try {
      return await _workspaceService.getGroupRoles(groupId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// 멤버 역할 변경
  Future<bool> updateMemberRole({
    required int groupId,
    required int userId,
    required int roleId,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _workspaceService.updateMemberRole(
        groupId: groupId,
        userId: userId,
        roleId: roleId,
      );

      // 현재 워크스페이스의 멤버 목록에서 해당 멤버 업데이트
      if (_currentWorkspace != null) {
        final updatedMembers = _currentWorkspace!.members.map((member) {
          if (member.user.id == userId) {
            return GroupMemberModel(
              id: member.id,
              groupId: member.groupId,
              user: member.user,
              role: GroupRoleModel(
                id: roleId,
                groupId: member.role.groupId,
                name: member.role.name, // 기존 이름 유지, 실제로는 역할 정보를 다시 조회해야 할 수도 있음
                isSystemRole: member.role.isSystemRole,
                permissions: member.role.permissions,
              ),
              joinedAt: member.joinedAt,
            );
          }
          return member;
        }).toList();

        _currentWorkspace = WorkspaceDetailModel(
          workspace: _currentWorkspace!.workspace,
          group: _currentWorkspace!.group,
          myMembership: _currentWorkspace!.myMembership,
          channels: _currentWorkspace!.channels,
          members: updatedMembers,
        );
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// 멤버 강제 탈퇴
  Future<bool> removeMember({
    required int groupId,
    required int userId,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _workspaceService.removeMember(groupId: groupId, userId: userId);

      // 현재 워크스페이스의 멤버 목록에서 해당 멤버 제거
      if (_currentWorkspace != null) {
        final updatedMembers = _currentWorkspace!.members
            .where((member) => member.user.id != userId)
            .toList();

        _currentWorkspace = WorkspaceDetailModel(
          workspace: _currentWorkspace!.workspace,
          group: _currentWorkspace!.group,
          myMembership: _currentWorkspace!.myMembership,
          channels: _currentWorkspace!.channels,
          members: updatedMembers,
        );
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// 그룹장 위임
  Future<bool> delegateLeadership({
    required int groupId,
    required int newLeaderId,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _workspaceService.delegateLeadership(
        groupId: groupId,
        newLeaderId: newLeaderId,
      );

      // 워크스페이스를 다시 로드하여 최신 상태 반영
      await loadWorkspace(
        groupId,
        mobileNavigatorVisible: _isMobileNavigatorVisible,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // === 관리자 기능 메서드 ===

  /// 관리자 통계 조회
  Future<AdminStatsModel> getAdminStats(int groupId) async {
    try {
      final stats = await _workspaceService.getAdminStats(groupId);
      return AdminStatsModel.fromJson(stats);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// 역할 생성
  Future<bool> createRole({
    required int groupId,
    required String name,
    required List<String> permissions,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _workspaceService.createRole(
        groupId: groupId,
        name: name,
        permissions: permissions,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// 역할 수정
  Future<bool> updateRole({
    required int groupId,
    required int roleId,
    required String name,
    required List<String> permissions,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _workspaceService.updateRole(
        groupId: groupId,
        roleId: roleId,
        name: name,
        permissions: permissions,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// 역할 삭제
  Future<bool> deleteRole({
    required int groupId,
    required int roleId,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _workspaceService.deleteRole(
        groupId: groupId,
        roleId: roleId,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// 가입 대기 멤버 목록 조회
  Future<List<PendingMemberModel>> getPendingMembers(int groupId) async {
    try {
      final pendingMembers = await _workspaceService.getPendingMembers(groupId);
      return pendingMembers.map((json) => PendingMemberModel.fromJson(json)).toList();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// 가입 승인/반려
  Future<bool> decideMembership({
    required int groupId,
    required int userId,
    required bool approve,
    String? reason,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _workspaceService.decideMembership(
        groupId: groupId,
        userId: userId,
        approve: approve,
        reason: reason,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// 개인 권한 오버라이드 조회
  Future<Map<String, dynamic>> getMemberPermissions({
    required int groupId,
    required int userId,
  }) async {
    try {
      return await _workspaceService.getMemberPermissions(
        groupId: groupId,
        userId: userId,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// 개인 권한 오버라이드 설정
  Future<bool> setMemberPermissions({
    required int groupId,
    required int userId,
    required Map<String, String> overrides,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _workspaceService.setMemberPermissions(
        groupId: groupId,
        userId: userId,
        overrides: overrides,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// 그룹 정보 수정
  Future<bool> updateGroupInfo({
    required int groupId,
    String? name,
    String? description,
    List<String>? tags,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _workspaceService.updateGroupInfo(
        groupId: groupId,
        name: name,
        description: description,
        tags: tags,
      );

      // 워크스페이스를 다시 로드하여 최신 상태 반영
      await loadWorkspace(
        groupId,
        mobileNavigatorVisible: _isMobileNavigatorVisible,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }


  /// 권한 확인 헬퍼 메서드들
  bool get canManageRoles => canManageMembers; // 멤버 관리 권한이 있으면 역할도 관리 가능
  bool get canViewAdminPages => canManageMembers || canManageChannels || canManage;
}

// 관리자 통계 모델 추가
class AdminStatsModel {
  final int pendingCount;
  final int memberCount;
  final int roleCount;
  final int channelCount;

  AdminStatsModel({
    required this.pendingCount,
    required this.memberCount,
    required this.roleCount,
    required this.channelCount,
  });

  factory AdminStatsModel.fromJson(Map<String, dynamic> json) {
    return AdminStatsModel(
      pendingCount: json['pendingCount'] ?? 0,
      memberCount: json['memberCount'] ?? 0,
      roleCount: json['roleCount'] ?? 0,
      channelCount: json['channelCount'] ?? 0,
    );
  }
}

// 가입 대기 멤버 모델 추가
class PendingMemberModel {
  final UserModel user;
  final DateTime appliedAt;
  final String? message;

  PendingMemberModel({
    required this.user,
    required this.appliedAt,
    this.message,
  });

  factory PendingMemberModel.fromJson(Map<String, dynamic> json) {
    return PendingMemberModel(
      user: UserModel.fromJson(json['user']),
      appliedAt: DateTime.parse(json['appliedAt']),
      message: json['message'],
    );
  }
}
