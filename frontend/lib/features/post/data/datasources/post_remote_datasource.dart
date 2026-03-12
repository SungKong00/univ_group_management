import 'dart:developer' as developer;
import '../../../../core/models/auth_models.dart';
import '../../../../core/network/dio_client.dart';
import '../models/post_dto.dart';
import '../models/post_list_response_dto.dart';

/// 게시글 원격 데이터 소스
///
/// Dio를 사용하여 게시글 관련 API를 호출합니다.
class PostRemoteDataSource {
  final DioClient _dioClient;

  PostRemoteDataSource(this._dioClient);

  /// GET /channels/{channelId}/posts
  Future<PostListResponseDto> fetchPosts(
    String channelId, {
    int page = 0,
    int size = 20,
  }) async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      '/channels/$channelId/posts',
      queryParameters: {'page': page, 'size': size},
    );
    return _unwrap(response, (json) => PostListResponseDto.fromJson(json));
  }

  /// GET /posts/{postId}
  Future<PostDto> fetchPost(int postId) async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      '/posts/$postId',
    );
    return _unwrap(
      response,
      (json) => PostDto.fromJson(json as Map<String, dynamic>),
    );
  }

  /// POST /channels/{channelId}/posts
  Future<PostDto> createPost(String channelId, String content) async {
    final response = await _dioClient.post<Map<String, dynamic>>(
      '/channels/$channelId/posts',
      data: {'content': content},
    );
    return _unwrap(
      response,
      (json) => PostDto.fromJson(json as Map<String, dynamic>),
    );
  }

  /// PUT /posts/{postId}
  Future<PostDto> updatePost(int postId, String content) async {
    final response = await _dioClient.put<Map<String, dynamic>>(
      '/posts/$postId',
      data: {'content': content},
    );
    return _unwrap(
      response,
      (json) => PostDto.fromJson(json as Map<String, dynamic>),
    );
  }

  /// DELETE /posts/{postId}
  Future<void> deletePost(int postId) async {
    final response = await _dioClient.delete<Map<String, dynamic>>(
      '/posts/$postId',
    );
    _unwrap(response, (json) => null);
  }

  /// ApiResponse 래핑 해제 및 에러 처리
  T _unwrap<T>(dynamic response, T Function(Object? json) fromJson) {
    if (response.data == null) throw Exception('Empty response');

    final apiResponse = ApiResponse.fromJson(response.data!, fromJson);

    if (apiResponse.success && apiResponse.data != null) {
      return apiResponse.data!;
    }

    developer.log(
      'API failed: ${apiResponse.message}',
      name: 'PostRemoteDataSource',
      level: 900,
    );
    throw Exception(apiResponse.message ?? 'API request failed');
  }
}
