import 'dart:developer' as developer;
import '../models/comment_models.dart';
import '../models/auth_models.dart';
import '../network/dio_client.dart';

/// Comment Service
///
/// Provides API methods for fetching, creating, and managing comments.
class CommentService {
  static final CommentService _instance = CommentService._internal();
  factory CommentService() => _instance;
  CommentService._internal();

  final DioClient _dioClient = DioClient();

  /// Get comments for a post
  ///
  /// GET /posts/{postId}/comments
  Future<List<Comment>> fetchComments(int postId) async {
    try {
      developer.log(
        'Fetching comments for post: $postId',
        name: 'CommentService',
      );

      final response = await _dioClient.get<Map<String, dynamic>>(
        '/posts/$postId/comments',
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(response.data!, (json) {
          if (json is List) {
            return json
                .map((item) => Comment.fromJson(item as Map<String, dynamic>))
                .toList();
          }
          return <Comment>[];
        });

        if (apiResponse.success && apiResponse.data != null) {
          developer.log(
            'Successfully fetched ${apiResponse.data!.length} comments',
            name: 'CommentService',
          );
          return apiResponse.data!;
        } else {
          developer.log(
            'Failed to fetch comments: ${apiResponse.message}',
            name: 'CommentService',
            level: 900,
          );
          throw Exception(apiResponse.message ?? 'Failed to fetch comments');
        }
      }

      throw Exception('Empty response from server');
    } catch (e) {
      developer.log(
        'Error fetching comments: $e',
        name: 'CommentService',
        level: 900,
      );
      rethrow;
    }
  }

  /// Create a new comment
  ///
  /// POST /posts/{postId}/comments
  /// Requires COMMENT_WRITE permission
  Future<Comment> createComment(
    int postId,
    String content, {
    int? parentCommentId,
  }) async {
    try {
      developer.log(
        'Creating comment for post: $postId',
        name: 'CommentService',
      );

      final request = CreateCommentRequest(
        content: content,
        parentCommentId: parentCommentId,
      );

      final response = await _dioClient.post<Map<String, dynamic>>(
        '/posts/$postId/comments',
        data: request.toJson(),
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => Comment.fromJson(json as Map<String, dynamic>),
        );

        if (apiResponse.success && apiResponse.data != null) {
          developer.log(
            'Successfully created comment: ${apiResponse.data!.id}',
            name: 'CommentService',
          );
          return apiResponse.data!;
        } else {
          developer.log(
            'Failed to create comment: ${apiResponse.message}',
            name: 'CommentService',
            level: 900,
          );
          throw Exception(apiResponse.message ?? 'Failed to create comment');
        }
      }

      throw Exception('Empty response from server');
    } catch (e) {
      developer.log(
        'Error creating comment: $e',
        name: 'CommentService',
        level: 900,
      );
      rethrow;
    }
  }

  /// Update a comment
  ///
  /// PUT /comments/{commentId}
  /// Requires being the author or having admin permission
  Future<Comment> updateComment(int commentId, String content) async {
    try {
      developer.log('Updating comment: $commentId', name: 'CommentService');

      final request = CreateCommentRequest(content: content);

      final response = await _dioClient.put<Map<String, dynamic>>(
        '/comments/$commentId',
        data: request.toJson(),
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => Comment.fromJson(json as Map<String, dynamic>),
        );

        if (apiResponse.success && apiResponse.data != null) {
          developer.log(
            'Successfully updated comment: $commentId',
            name: 'CommentService',
          );
          return apiResponse.data!;
        } else {
          developer.log(
            'Failed to update comment: ${apiResponse.message}',
            name: 'CommentService',
            level: 900,
          );
          throw Exception(apiResponse.message ?? 'Failed to update comment');
        }
      }

      throw Exception('Empty response from server');
    } catch (e) {
      developer.log(
        'Error updating comment: $e',
        name: 'CommentService',
        level: 900,
      );
      rethrow;
    }
  }

  /// Delete a comment
  ///
  /// DELETE /comments/{commentId}
  /// Requires being the author or having admin permission
  Future<void> deleteComment(int commentId) async {
    try {
      developer.log('Deleting comment: $commentId', name: 'CommentService');

      final response = await _dioClient.delete<Map<String, dynamic>>(
        '/comments/$commentId',
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => null, // DELETE returns no data
        );

        if (apiResponse.success) {
          developer.log(
            'Successfully deleted comment: $commentId',
            name: 'CommentService',
          );
          return;
        } else {
          developer.log(
            'Failed to delete comment: ${apiResponse.message}',
            name: 'CommentService',
            level: 900,
          );
          throw Exception(apiResponse.message ?? 'Failed to delete comment');
        }
      }

      throw Exception('Empty response from server');
    } catch (e) {
      developer.log(
        'Error deleting comment: $e',
        name: 'CommentService',
        level: 900,
      );
      rethrow;
    }
  }
}
