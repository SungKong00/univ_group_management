import 'dart:developer' as developer;
import '../../../../core/models/auth_models.dart';
import '../../../../core/network/dio_client.dart';
import '../models/comment_dto.dart';

/// 댓글 원격 데이터 소스 추상 클래스
abstract class CommentRemoteDataSource {
  /// GET /posts/{postId}/comments
  Future<List<CommentDto>> getComments(int postId);

  /// POST /posts/{postId}/comments
  Future<CommentDto> createComment({
    required int postId,
    required String content,
    int? parentCommentId,
  });

  /// DELETE /comments/{commentId}
  Future<void> deleteComment(int commentId);
}

/// 댓글 원격 데이터 소스 구현
///
/// Dio를 사용하여 댓글 관련 API를 호출합니다.
class CommentRemoteDataSourceImpl implements CommentRemoteDataSource {
  final DioClient _dioClient;

  CommentRemoteDataSourceImpl(this._dioClient);

  @override
  Future<List<CommentDto>> getComments(int postId) async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      '/posts/$postId/comments',
    );

    return _unwrap(
      response,
      (json) => (json as List)
          .map((item) => CommentDto.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Future<CommentDto> createComment({
    required int postId,
    required String content,
    int? parentCommentId,
  }) async {
    final response = await _dioClient.post<Map<String, dynamic>>(
      '/posts/$postId/comments',
      data: {
        'content': content,
        if (parentCommentId != null) 'parentCommentId': parentCommentId,
      },
    );

    return _unwrap(
      response,
      (json) => CommentDto.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<void> deleteComment(int commentId) async {
    final response = await _dioClient.delete<Map<String, dynamic>>(
      '/comments/$commentId',
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
      name: 'CommentRemoteDataSource',
      level: 900,
    );
    throw Exception(apiResponse.message ?? 'API request failed');
  }
}
