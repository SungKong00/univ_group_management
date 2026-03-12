import '../entities/post.dart';
import '../repositories/post_repository.dart';

/// 새로운 게시글을 작성하는 UseCase
///
/// 비즈니스 규칙:
/// - 채널 ID는 필수이며 비어있으면 안 됨
/// - 게시글 내용은 필수이며 비어있으면 안 됨
/// - 게시글 길이는 10,000자를 초과할 수 없음
class CreatePostUseCase {
  final PostRepository _repository;

  CreatePostUseCase(this._repository);

  /// 새로운 게시글을 작성
  ///
  /// [channelId] 채널 ID
  /// [content] 게시글 내용
  ///
  /// Returns: 생성된 게시글 Entity
  ///
  /// Throws:
  /// - [ArgumentError] 입력 검증 실패 시
  /// - [Exception] Repository에서 발생한 에러
  Future<Post> call(String channelId, String content) async {
    // 입력 검증
    if (channelId.isEmpty) {
      throw ArgumentError('채널 ID는 비어있을 수 없습니다');
    }

    final trimmedContent = content.trim();

    if (trimmedContent.isEmpty) {
      throw ArgumentError('게시글 내용을 입력해주세요');
    }

    if (trimmedContent.length > 10000) {
      throw ArgumentError('게시글은 10,000자를 초과할 수 없습니다');
    }

    // Repository 호출
    return await _repository.createPost(channelId, trimmedContent);
  }
}
