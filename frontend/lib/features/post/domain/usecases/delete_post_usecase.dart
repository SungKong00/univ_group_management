import '../repositories/post_repository.dart';

/// 게시글을 삭제하는 UseCase
///
/// 비즈니스 규칙:
/// - 게시글 ID는 양수여야 함
class DeletePostUseCase {
  final PostRepository _repository;

  DeletePostUseCase(this._repository);

  /// 게시글을 삭제
  ///
  /// [postId] 게시글 ID
  ///
  /// Throws:
  /// - [ArgumentError] 입력 검증 실패 시
  /// - [Exception] Repository에서 발생한 에러
  Future<void> call(int postId) async {
    // 입력 검증
    if (postId <= 0) {
      throw ArgumentError('유효하지 않은 게시글 ID입니다');
    }

    // Repository 호출
    await _repository.deletePost(postId);
  }
}
