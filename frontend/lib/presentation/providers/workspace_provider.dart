import 'package:flutter/foundation.dart';
import '../../data/models/workspace_models.dart';
import '../../data/models/admin_models.dart';
import '../../data/services/workspace_service.dart';

class WorkspaceProvider extends ChangeNotifier {
  final WorkspaceService _workspaceService;

  WorkspaceProvider(this._workspaceService);

  // State
  WorkspaceDetailModel? _currentWorkspace;
  bool _isLoading = false;
  String? _error;
  bool _accessDenied = false;

  // Channel and Comments State
  ChannelModel? _currentChannel;
  PostModel? _selectedPostForComments;
  Map<int, List<CommentModel>> _commentsCache = {};

  // Getters
  WorkspaceDetailModel? get currentWorkspace => _currentWorkspace;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAccessDenied => _accessDenied;

  // Channel and Comments Getters
  ChannelModel? get currentChannel => _currentChannel;
  PostModel? get selectedPostForComments => _selectedPostForComments;
  bool get canWriteInCurrentChannel => _currentChannel != null;

  // 현재 워크스페이스의 채널 (정렬됨)
  List<ChannelModel> get channels {
    final channels = List<ChannelModel>.from(_currentWorkspace?.channels ?? []);
    channels.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return channels;
  }

  // 현재 워크스페이스의 멤버 (정렬됨)
  List<GroupMemberModel> get members {
    final members =
        List<GroupMemberModel>.from(_currentWorkspace?.members ?? []);
    members.sort((a, b) => a.joinedAt.compareTo(b.joinedAt));
    return members;
  }

  // 권한 체크
  bool get canManage => _currentWorkspace?.canManage ?? false;
  bool get canManageMembers => _currentWorkspace?.canManageMembers ?? false;
  bool get canManageChannels => _currentWorkspace?.canManageChannels ?? false;

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
      _currentChannel = null;
      _selectedPostForComments = null;
      _commentsCache.clear();
      notifyListeners();

      _currentWorkspace = await _workspaceService.getWorkspaceByGroup(groupId);

      // 첫 번째 채널 자동 선택
      if (autoSelectFirstChannel && channels.isNotEmpty) {
        selectChannel(channels.first);
      }

      _isLoading = false;
      notifyListeners();
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

  /// 에러 초기화
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// 상태 초기화 (다른 워크스페이스로 이동할 때 사용)
  void reset() {
    _currentWorkspace = null;
    _isLoading = false;
    _error = null;
    _accessDenied = false;
    _currentChannel = null;
    _selectedPostForComments = null;
    _commentsCache.clear();
    notifyListeners();
  }

  /// 그룹 가입 신청
  Future<bool> requestJoin(int groupId, {String? message}) async {
    try {
      await _workspaceService.requestJoinGroup(
          groupId: groupId, message: message);
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
        mobileNavigatorVisible: false,
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
      return pendingMembers
          .map((json) => PendingMemberModel.fromJson(json))
          .toList();
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
        mobileNavigatorVisible: false,
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
  bool get canViewAdminPages =>
      canManageMembers || canManageChannels || canManage;

  // === Channel Management Methods ===

  /// 채널 선택
  void selectChannel(ChannelModel channel) {
    _currentChannel = channel;
    notifyListeners();
  }

  /// 채널 생성
  Future<bool> createChannel({
    required String name,
    String? description,
    type,
    bool isPrivate = false,
  }) async {
    try {
      // TODO: Implement channel creation API call
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
      // TODO: Implement channel deletion API call
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// 채널 쓰기 권한 토글
  void toggleChannelWritePermission(int channelId) {
    // TODO: Implement channel write permission toggle
    notifyListeners();
  }

  // === Comments Management Methods ===

  /// 게시글의 댓글 조회
  List<CommentModel> getCommentsForPost(int postId) {
    return _commentsCache[postId] ?? [];
  }

  /// 댓글 사이드바 숨기기
  void hideCommentsSidebar() {
    _selectedPostForComments = null;
    notifyListeners();
  }

  /// 댓글 생성
  Future<bool> createComment({
    required int postId,
    required String content,
  }) async {
    try {
      // TODO: Implement comment creation API call
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// 댓글 삭제
  Future<bool> deleteComment(int commentId, int postId) async {
    try {
      // TODO: Implement comment deletion API call
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
