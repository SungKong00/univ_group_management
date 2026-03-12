import '../entities/post.dart';
import '../repositories/post_repository.dart';

/// 기존 게시글을 수정하는 UseCase
///
/// 비즈니스 규칙:
/// - 게시글 ID는 양수여야 함
/// - 게시글 내용은 필수이며 비어있으면 안 됨
/// - 게시글 길이는 10,000자를 초과할 수 없음
class UpdatePostUseCase {
  final PostRepository _repository;

  UpdatePostUseCase(this._repository);

  /// 기존 게시글을 수정
  ///
  /// [postId] 게시글 ID
  /// [content] 수정할 내용
  ///
  /// Returns: 수정된 게시글 Entity
  ///
  /// Throws:
  /// - [ArgumentError] 입력 검증 실패 시
  /// - [Exception] Repository에서 발생한 에러
  Future<Post> call(int postId, String content) async {
    // 입력 검증
    if (postId <= 0) {
      throw ArgumentError('유효하지 않은 게시글 ID입니다');
    }

    final trimmedContent = content.trim();

    if (trimmedContent.isEmpty) {
      throw ArgumentError('게시글 내용을 입력해주세요');
    }

    if (trimmedContent.length > 10000) {
      throw ArgumentError('게시글은 10,000자를 초과할 수 없습니다');
    }

    // Repository 호출
    return await _repository.updatePost(postId, trimmedContent);
  }
}
