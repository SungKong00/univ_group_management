import 'package:flutter/foundation.dart';
import '../../data/models/workspace_models.dart';
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

  // Current channel (when in channel detail view)
  ChannelModel? _currentChannel;
  List<PostModel> _currentChannelPosts = [];
  Map<int, List<CommentModel>> _postComments = {};

  // Getters
  WorkspaceDetailModel? get currentWorkspace => _currentWorkspace;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAccessDenied => _accessDenied;
  int get currentTabIndex => _currentTabIndex;
  bool get isSidebarVisible => _isSidebarVisible;
  ChannelModel? get currentChannel => _currentChannel;
  List<PostModel> get currentChannelPosts => _currentChannelPosts;

  // 현재 워크스페이스의 공지사항 (정렬됨)
  List<PostModel> get announcements {
    final announcements = List<PostModel>.from(_currentWorkspace?.announcements ?? []);
    announcements.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return announcements;
  }

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
  bool get canCreateAnnouncements => _currentWorkspace?.canCreateAnnouncements ?? false;

  /// 워크스페이스 로드
  Future<void> loadWorkspace(int groupId) async {
    try {
      _isLoading = true;
      _error = null;
      _accessDenied = false;
      notifyListeners();

      _currentWorkspace = await _workspaceService.getWorkspaceByGroup(groupId);

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
      _isLoading = true;
      notifyListeners();

      _currentChannelPosts = await _workspaceService.getChannelPosts(channel.id);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 채널 상세에서 나가기
  void exitChannel() {
    _currentChannel = null;
    _currentChannelPosts.clear();
    notifyListeners();
  }

  /// 새 게시글 생성
  Future<void> createPost({
    required int channelId,
    required String title,
    required String content,
    PostType type = PostType.general,
    List<String> attachments = const [],
  }) async {
    try {
      final newPost = await _workspaceService.createPost(
        channelId: channelId,
        title: title,
        content: content,
        type: type,
        attachments: attachments,
      );

      // 현재 채널의 게시글이라면 목록에 추가
      if (_currentChannel?.id == channelId) {
        _currentChannelPosts.insert(0, newPost);
        notifyListeners();
      }

      // 공지사항이라면 워크스페이스 공지사항에도 추가
      if (type == PostType.announcement && _currentWorkspace != null) {
        final updatedAnnouncements = List<PostModel>.from(_currentWorkspace!.announcements);
        updatedAnnouncements.insert(0, newPost);
        _currentWorkspace = WorkspaceDetailModel(
          workspace: _currentWorkspace!.workspace,
          group: _currentWorkspace!.group,
          myMembership: _currentWorkspace!.myMembership,
          channels: _currentWorkspace!.channels,
          announcements: updatedAnnouncements,
          members: _currentWorkspace!.members,
        );
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

      // 공지사항 목록에서도 제거
      if (_currentWorkspace != null) {
        final updatedAnnouncements = _currentWorkspace!.announcements
            .where((post) => post.id != postId)
            .toList();
        _currentWorkspace = WorkspaceDetailModel(
          workspace: _currentWorkspace!.workspace,
          group: _currentWorkspace!.group,
          myMembership: _currentWorkspace!.myMembership,
          channels: _currentWorkspace!.channels,
          announcements: updatedAnnouncements,
          members: _currentWorkspace!.members,
        );
      }

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
        announcements: _currentWorkspace!.announcements,
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
          announcements: _currentWorkspace!.announcements,
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
    _currentWorkspace = null;
    _currentChannel = null;
    _currentChannelPosts.clear();
    _postComments.clear();
    _currentTabIndex = 0;
    _isSidebarVisible = true;
    _isLoading = false;
    _error = null;
    _accessDenied = false;
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

      final updatedMember = await _workspaceService.updateMemberRole(
        groupId: groupId,
        userId: userId,
        roleId: roleId,
      );

      // 현재 워크스페이스의 멤버 목록에서 해당 멤버 업데이트
      if (_currentWorkspace != null) {
        final updatedMembers = _currentWorkspace!.members.map((member) {
          if (member.user.id == userId) {
            return updatedMember;
          }
          return member;
        }).toList();

        _currentWorkspace = WorkspaceDetailModel(
          workspace: _currentWorkspace!.workspace,
          group: _currentWorkspace!.group,
          myMembership: _currentWorkspace!.myMembership,
          channels: _currentWorkspace!.channels,
          announcements: _currentWorkspace!.announcements,
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
          announcements: _currentWorkspace!.announcements,
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
      await loadWorkspace(groupId);

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
}
