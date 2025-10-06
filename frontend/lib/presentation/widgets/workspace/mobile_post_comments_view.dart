import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../../../core/theme/app_colors.dart';
import '../comment/comment_list.dart';
import '../comment/comment_composer.dart';
import '../../../core/services/comment_service.dart';
import '../../../core/models/channel_models.dart';

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
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTopButton = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            // 댓글 목록
            Expanded(
              child: CommentList(
                key: ValueKey('mobile_comment_list_${widget.postId}_$_commentListKey'),
                postId: int.parse(widget.postId),
                scrollController: _scrollController,
              ),
            ),

            // 댓글 작성 입력창
            if (widget.permissions?.canWriteComment ?? false)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: AppColors.lightOutline,
                      width: 1,
                    ),
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
