import 'package:flutter/material.dart';
import '../../../core/models/comment_models.dart';
import '../../../core/services/comment_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import 'comment_item.dart';

/// 댓글 목록 위젯
///
/// 게시글의 댓글 목록을 표시하고 관리합니다.
/// - 로딩/에러/빈 상태 처리
/// - 댓글 목록 API 연동
/// - 새로고침 지원
class CommentList extends StatefulWidget {
  final int postId;
  final VoidCallback? onRefresh;

  const CommentList({
    super.key,
    required this.postId,
    this.onRefresh,
  });

  @override
  State<CommentList> createState() => _CommentListState();
}

class _CommentListState extends State<CommentList> {
  final CommentService _commentService = CommentService();
  List<Comment> _comments = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final comments = await _commentService.fetchComments(widget.postId);
      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleRefresh() async {
    await _loadComments();
    widget.onRefresh?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_comments.isEmpty) {
      return _buildEmptyState();
    }

    return _buildCommentList();
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.brand),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              '댓글을 불러올 수 없습니다',
              style: AppTheme.titleMedium.copyWith(
                color: AppColors.neutral900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? '알 수 없는 오류가 발생했습니다',
              style: AppTheme.bodySmall.copyWith(
                color: AppColors.neutral600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _handleRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brand,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: AppColors.neutral400,
            ),
            SizedBox(height: 16),
            Text(
              '아직 댓글이 없습니다',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.neutral600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '첫 번째 댓글을 작성해보세요',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.neutral500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentList() {
    // ListView.builder 사용 + RepaintBoundary로 성능 최적화
    // 댓글과 Divider를 합친 itemCount (댓글 N개 → 아이템 2N-1개)
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _comments.length * 2 - 1,
      itemBuilder: (context, index) {
        // 홀수 인덱스는 Divider
        if (index.isOdd) {
          return const Divider(
            height: 24,
            thickness: 1,
            color: AppColors.neutral200,
          );
        }

        // 짝수 인덱스는 댓글 아이템
        final commentIndex = index ~/ 2;
        final comment = _comments[commentIndex];

        // RepaintBoundary로 각 댓글을 독립적으로 렌더링
        // ValueKey로 댓글 재사용 최적화
        return RepaintBoundary(
          child: CommentItem(
            key: ValueKey(comment.id),
            comment: comment,
            // TODO: 대댓글 기능 추가 시 활성화
            // onTapReply: () {},
            // TODO: 삭제 권한 확인 후 활성화
            // onTapDelete: () {},
          ),
        );
      },
    );
  }
}
