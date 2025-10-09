import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme.dart';
import '../comment/comment_list.dart';
import '../comment/comment_composer.dart';
import '../../../core/services/comment_service.dart';
import '../../../core/services/post_service.dart';
import '../../../core/models/channel_models.dart';
import '../../../core/models/post_models.dart';
import '../post/post_preview_card.dart';

/// 모바일 댓글 뷰 (Step 3: 게시글 선택 후 댓글 목록)
class MobilePostCommentsView extends ConsumerStatefulWidget {
  final String postId;
  final String channelId;
  final String groupId;
  final ChannelPermissions? permissions;

  const MobilePostCommentsView({
    super.key,
    required this.postId,
    required this.channelId,
    required this.groupId,
    this.permissions,
  });

  @override
  ConsumerState<MobilePostCommentsView> createState() =>
      _MobilePostCommentsViewState();
}

class _MobilePostCommentsViewState
    extends ConsumerState<MobilePostCommentsView> {
  int _commentListKey = 0;
  final CommentService _commentService = CommentService();
  final PostService _postService = PostService();
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTopButton = false;

  // 게시글 데이터 상태
  Post? _post;
  bool _isLoadingPost = true;
  String? _postErrorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadPost();
  }

  /// 게시글 데이터 로드
  Future<void> _loadPost() async {
    setState(() {
      _isLoadingPost = true;
      _postErrorMessage = null;
    });

    try {
      final postIdInt = int.parse(widget.postId);
      final post = await _postService.getPost(postIdInt);

      setState(() {
        _post = post;
        _isLoadingPost = false;
      });
    } catch (e) {
      setState(() {
        _postErrorMessage = '게시글을 불러올 수 없습니다.';
        _isLoadingPost = false;
      });

      if (kDebugMode) {
        developer.log('게시글 로드 실패: $e', name: 'MobilePostCommentsView');
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // 스크롤 위치가 200px 이상이면 상단 이동 버튼 표시
    if (_scrollController.offset > 200 && !_showScrollToTopButton) {
      setState(() {
        _showScrollToTopButton = true;
      });
    } else if (_scrollController.offset <= 200 && _showScrollToTopButton) {
      setState(() {
        _showScrollToTopButton = false;
      });
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  /// 게시글 미리보기 빌드 (로딩/에러/성공 상태별)
  Widget _buildPostPreview() {
    // 로딩 중
    if (_isLoadingPost) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // 에러 발생
    if (_postErrorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: AppColors.error, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _postErrorMessage!,
                  style: const TextStyle(color: AppColors.error, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 게시글 로드 성공
    if (_post != null) {
      return PostPreviewCard(post: _post!, maxLines: 5);
    }

    // 예상치 못한 상태 (빈 화면)
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            // 게시글 미리보기 (로딩/에러/성공 상태별 처리)
            _buildPostPreview(),

            // 댓글 목록
            Expanded(
              child: CommentList(
                key: ValueKey(
                  'mobile_comment_list_${widget.postId}_$_commentListKey',
                ),
                postId: int.parse(widget.postId),
                scrollController: _scrollController,
              ),
            ),

            // 댓글 작성 입력창
            if (widget.permissions?.canWriteComment ?? false)
              Container(
                padding: EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: AppColors.lightOutline, width: 1),
                  ),
                ),
                child: CommentComposer(
                  canWrite: widget.permissions?.canWriteComment ?? false,
                  isLoading: false,
                  onSubmit: (content) => _handleSubmitComment(content),
                ),
              ),
          ],
        ),

        // 상단 이동 FAB
        if (_showScrollToTopButton)
          Positioned(
            right: 16,
            bottom: widget.permissions?.canWriteComment ?? false ? 80 : 16,
            child: FloatingActionButton.small(
              onPressed: _scrollToTop,
              backgroundColor: AppColors.brand,
              foregroundColor: Colors.white,
              child: const Icon(Icons.arrow_upward, size: 20),
            ),
          ),
      ],
    );
  }

  /// 댓글 작성 핸들러
  Future<void> _handleSubmitComment(String content) async {
    if (content.trim().isEmpty) {
      return;
    }

    try {
      final postIdInt = int.parse(widget.postId);
      await _commentService.createComment(postIdInt, content);

      // 댓글 목록 새로고침
      setState(() {
        _commentListKey++;
      });
    } catch (e) {
      // 에러 처리 (TODO: 사용자에게 에러 메시지 표시)
      if (kDebugMode) {
        developer.log('댓글 작성 실패: $e', name: 'MobilePostCommentsView');
      }
    }
  }
}
