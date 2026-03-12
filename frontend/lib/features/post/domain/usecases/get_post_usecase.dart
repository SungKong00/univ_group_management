import '../entities/post.dart';
import '../repositories/post_repository.dart';

/// 단일 게시글의 상세 정보를 조회하는 UseCase
///
/// 비즈니스 규칙:
/// - 게시글 ID는 양수여야 함
class GetPostUseCase {
  final PostRepository _repository;

  GetPostUseCase(this._repository);

  /// 단일 게시글의 상세 정보를 조회
  ///
  /// [postId] 게시글 ID
  ///
  /// Returns: 게시글 Entity
  ///
  /// Throws:
  /// - [ArgumentError] 입력 검증 실패 시
  /// - [Exception] Repository에서 발생한 에러
  Future<Post> call(int postId) async {
    // 입력 검증
    if (postId <= 0) {
      throw ArgumentError('유효하지 않은 게시글 ID입니다');
    }

    // Repository 호출
    return await _repository.getPost(postId);
  }
}
