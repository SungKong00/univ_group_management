import '../../domain/entities/post.dart';
import '../../domain/entities/pagination.dart';
import '../../domain/repositories/post_repository.dart';
import '../datasources/post_remote_datasource.dart';

/// PostRepository 구현체
///
/// PostRemoteDataSource를 사용하여 API 호출 후 DTO → Entity 변환을 수행합니다.
class PostRepositoryImpl implements PostRepository {
  final PostRemoteDataSource _remoteDataSource;

  PostRepositoryImpl(this._remoteDataSource);

  @override
  Future<(List<Post>, Pagination)> getPosts(
    String channelId, {
    int page = 0,
    int size = 20,
  }) async {
    final responseDto = await _remoteDataSource.fetchPosts(
      channelId,
      page: page,
      size: size,
    );

    return responseDto.toEntity();
  }

  @override
  Future<Post> getPost(int postId) async {
    final postDto = await _remoteDataSource.fetchPost(postId);
    return postDto.toEntity();
  }

  @override
  Future<Post> createPost(String channelId, String content) async {
    final postDto = await _remoteDataSource.createPost(channelId, content);
    return postDto.toEntity();
  }

  @override
  Future<Post> updatePost(int postId, String content) async {
    final postDto = await _remoteDataSource.updatePost(postId, content);
    return postDto.toEntity();
  }

  @override
  Future<void> deletePost(int postId) async {
    await _remoteDataSource.deletePost(postId);
  }
}
