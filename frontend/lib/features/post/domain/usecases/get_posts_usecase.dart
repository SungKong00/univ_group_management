import '../entities/pagination.dart';
import '../entities/post.dart';
import '../repositories/post_repository.dart';

/// 채널의 게시글 목록을 조회하는 UseCase
///
/// 비즈니스 규칙:
/// - 채널 ID는 필수이며 비어있으면 안 됨
/// - 페이지 번호는 0 이상이어야 함
/// - 페이지 크기는 1~100 사이여야 함
class GetPostsUseCase {
  final PostRepository _repository;

  GetPostsUseCase(this._repository);

  /// 채널의 게시글 목록을 페이지네이션과 함께 조회
  ///
  /// [channelId] 채널 ID
  /// [page] 페이지 번호 (기본값: 0)
  /// [size] 페이지 크기 (기본값: 20)
  ///
  /// Returns: (게시글 리스트, 페이지네이션 정보)
  ///
  /// Throws:
  /// - [ArgumentError] 입력 검증 실패 시
  /// - [Exception] Repository에서 발생한 에러
  Future<(List<Post>, Pagination)> call(
    String channelId, {
    int page = 0,
    int size = 20,
  }) async {
    // 입력 검증
    if (channelId.isEmpty) {
      throw ArgumentError('채널 ID는 비어있을 수 없습니다');
    }

    if (page < 0) {
      throw ArgumentError('페이지 번호는 0 이상이어야 합니다');
    }

    if (size <= 0 || size > 100) {
      throw ArgumentError('페이지 크기는 1에서 100 사이여야 합니다');
    }

    // Repository 호출
    return await _repository.getPosts(
      channelId,
      page: page,
      size: size,
    );
  }
}
