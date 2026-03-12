import '../entities/pagination.dart';
import '../entities/post.dart';

/// 게시글 데이터 접근을 위한 Repository 인터페이스
///
/// 도메인 레이어에서 정의하고, 데이터 레이어에서 구현합니다.
/// HTTP, JSON 등 기술적 세부사항은 숨기고 도메인 용어만 사용합니다.
abstract class PostRepository {
  /// 채널의 게시글 목록을 페이지네이션과 함께 조회
  ///
  /// [channelId] 채널 고유 ID
  /// [page] 페이지 번호 (0부터 시작, 기본값: 0)
  /// [size] 페이지당 게시글 수 (기본값: 20)
  ///
  /// Returns: (게시글 리스트, 페이지네이션 정보) 튜플
  ///
  /// Throws:
  /// - [Exception] 네트워크 오류 또는 서버 오류 발생 시
  Future<(List<Post>, Pagination)> getPosts(
    String channelId, {
    int page = 0,
    int size = 20,
  });

  /// 단일 게시글의 상세 정보를 조회
  ///
  /// [postId] 게시글 고유 ID
  ///
  /// Returns: 게시글 Entity
  ///
  /// Throws:
  /// - [Exception] 게시글을 찾을 수 없거나 권한이 없는 경우
  Future<Post> getPost(int postId);

  /// 새로운 게시글을 작성
  ///
  /// [channelId] 채널 고유 ID
  /// [content] 게시글 내용
  ///
  /// Returns: 생성된 게시글 Entity
  ///
  /// Throws:
  /// - [Exception] 권한이 없거나 서버 오류 발생 시
  Future<Post> createPost(String channelId, String content);

  /// 기존 게시글을 수정
  ///
  /// [postId] 게시글 고유 ID
  /// [content] 수정할 내용
  ///
  /// Returns: 수정된 게시글 Entity
  ///
  /// Throws:
  /// - [Exception] 권한이 없거나 게시글을 찾을 수 없는 경우
  Future<Post> updatePost(int postId, String content);

  /// 게시글을 삭제
  ///
  /// [postId] 게시글 고유 ID
  ///
  /// Throws:
  /// - [Exception] 권한이 없거나 게시글을 찾을 수 없는 경우
  Future<void> deletePost(int postId);
}
