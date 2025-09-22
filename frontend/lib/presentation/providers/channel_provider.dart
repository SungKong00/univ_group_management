import 'package:flutter/foundation.dart';
import '../../data/models/workspace_models.dart';
import '../../data/services/workspace_service.dart';

class ChannelProvider extends ChangeNotifier {
  final WorkspaceService _workspaceService;

  ChannelProvider(this._workspaceService);

  // Current channel (when in channel detail view)
  ChannelModel? _currentChannel;
  List<PostModel> _currentChannelPosts = [];
  Map<int, List<CommentModel>> _postComments = {};

  // Channel permissions for current user
  Map<int, List<String>> _channelPermissions = {};

  // Loading and error states
  bool _isLoading = false;
  String? _error;

  // Getters
  ChannelModel? get currentChannel => _currentChannel;
  List<PostModel> get currentChannelPosts => _currentChannelPosts;
  bool get isLoading => _isLoading;
  String? get error => _error;

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

  /// 채널 선택 및 상세 정보 로드
  Future<void> selectChannel(ChannelModel channel) async {
    try {
      _currentChannel = channel;
      // 채널 전환 직후 기존 목록/댓글 캐시를 비워 화면에 섞여 보이지 않게 함
      _currentChannelPosts.clear();
      _postComments.clear();
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
      final latest = comments.isNotEmpty ? comments.last.createdAt : null;
      _updatePostCommentMetadata(
        postId,
        commentCount: comments.length,
        lastCommentedAt: latest,
        updateLastCommentedAt: true,
      );
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

      final currentCount = _findPostById(postId)?.commentCount ?? 0;
      _updatePostCommentMetadata(
        postId,
        commentCount: currentCount + 1,
        lastCommentedAt: newComment.createdAt,
        updateLastCommentedAt: true,
      );

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
      }

      final currentCount = _findPostById(postId)?.commentCount ?? 0;
      DateTime? latest;
      bool shouldUpdateLast = false;
      if (_postComments.containsKey(postId)) {
        final commentsForPost = _postComments[postId]!;
        if (commentsForPost.isNotEmpty) {
          latest = commentsForPost.last.createdAt;
        }
        shouldUpdateLast = true;
      }
      _updatePostCommentMetadata(
        postId,
        commentCount: currentCount - 1,
        lastCommentedAt: latest,
        updateLastCommentedAt: shouldUpdateLast,
      );

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 새 채널 생성 (워크스페이스와 함께 사용되므로 워크스페이스 ID 필요)
  Future<ChannelModel?> createChannel({
    required int workspaceId,
    required String name,
    String? description,
    ChannelType type = ChannelType.text,
    bool isPrivate = false,
  }) async {
    try {
      final newChannel = await _workspaceService.createChannel(
        workspaceId: workspaceId,
        name: name,
        description: description,
        type: type,
        isPrivate: isPrivate,
      );

      return newChannel;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// 채널 삭제
  Future<bool> deleteChannel(int channelId) async {
    try {
      await _workspaceService.deleteChannel(channelId);

      // 현재 선택된 채널이라면 나가기
      if (_currentChannel?.id == channelId) {
        exitChannel();
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

  /// 상태 초기화
  void reset() {
    _channelPermissions.clear();
    _currentChannel = null;
    _currentChannelPosts.clear();
    _postComments.clear();
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  /// 게시글 찾기 헬퍼 메서드
  PostModel? _findPostById(int postId) {
    for (final post in _currentChannelPosts) {
      if (post.id == postId) {
        return post;
      }
    }
    return null;
  }

  /// 게시글 댓글 메타데이터 업데이트
  void _updatePostCommentMetadata(
    int postId, {
    int? commentCount,
    DateTime? lastCommentedAt,
    bool updateLastCommentedAt = false,
  }) {
    final sanitizedCount = commentCount != null && commentCount < 0 ? 0 : commentCount;
    final index = _currentChannelPosts.indexWhere((post) => post.id == postId);
    if (index != -1) {
      final updatedPost = _currentChannelPosts[index].copyWith(
        commentCount: sanitizedCount,
        lastCommentedAt: lastCommentedAt,
        updateLastCommentedAt: updateLastCommentedAt,
      );
      _currentChannelPosts[index] = updatedPost;
    }
  }

  /// 선택된 포스트 업데이트 (UI State Provider가 사용할 수 있도록 노출)
  void updateSelectedPost(PostModel updatedPost) {
    final index = _currentChannelPosts.indexWhere((post) => post.id == updatedPost.id);
    if (index != -1) {
      _currentChannelPosts[index] = updatedPost;
      notifyListeners();
    }
  }

  /// 안전한 채널 데이터 로드 (반응형 전환에서 사용)
  Future<void> loadChannelDataSafely(ChannelModel channel) async {
    try {
      _currentChannel = channel;
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
}