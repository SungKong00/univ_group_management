import 'dart:developer' as developer;
import '../models/post_models.dart';
import '../models/auth_models.dart';
import '../network/dio_client.dart';

/// Post Service
///
/// Provides API methods for fetching, creating, and managing posts in channels.
class PostService {
  static final PostService _instance = PostService._internal();
  factory PostService() => _instance;
  PostService._internal();

  final DioClient _dioClient = DioClient();

  /// Get posts for a channel
  ///
  /// GET /channels/{channelId}/posts?page={page}&size={size}
  /// Requires POST_READ permission
  Future<PostListResponse> fetchPosts(
    String channelId, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      developer.log(
        'Fetching posts for channel: $channelId (page: $page, size: $size)',
        name: 'PostService',
      );

      final response = await _dioClient.get<Map<String, dynamic>>(
        '/channels/$channelId/posts',
        queryParameters: {
          'page': page,
          'size': size,
        },
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) {
            // Backend returns List<PostResponse> directly, not paginated
            if (json is List) {
              final posts = json.map((item) => Post.fromJson(item as Map<String, dynamic>)).toList();
              // Create simple PostListResponse without pagination info
              return PostListResponse(
                posts: posts,
                totalPages: 1,
                currentPage: 0,
                totalElements: posts.length,
                hasMore: false,
              );
            }
            // If backend returns paginated structure in the future
            return PostListResponse.fromJson(json as Map<String, dynamic>);
          },
        );

        if (apiResponse.success && apiResponse.data != null) {
          developer.log(
            'Successfully fetched ${apiResponse.data!.posts.length} posts',
            name: 'PostService',
          );
          return apiResponse.data!;
        } else {
          developer.log(
            'Failed to fetch posts: ${apiResponse.message}',
            name: 'PostService',
            level: 900,
          );
          throw Exception(apiResponse.message ?? 'Failed to fetch posts');
        }
      }

      throw Exception('Empty response from server');
    } catch (e) {
      developer.log(
        'Error fetching posts: $e',
        name: 'PostService',
        level: 900,
      );
      rethrow;
    }
  }

  /// Create a new post in a channel
  ///
  /// POST /channels/{channelId}/posts
  /// Requires POST_WRITE permission
  Future<Post> createPost(String channelId, String content) async {
    try {
      developer.log(
        'Creating post in channel: $channelId',
        name: 'PostService',
      );

      final request = CreatePostRequest(content: content);

      final response = await _dioClient.post<Map<String, dynamic>>(
        '/channels/$channelId/posts',
        data: request.toJson(),
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => Post.fromJson(json as Map<String, dynamic>),
        );

        if (apiResponse.success && apiResponse.data != null) {
          developer.log(
            'Successfully created post: ${apiResponse.data!.id}',
            name: 'PostService',
          );
          return apiResponse.data!;
        } else {
          developer.log(
            'Failed to create post: ${apiResponse.message}',
            name: 'PostService',
            level: 900,
          );
          throw Exception(apiResponse.message ?? 'Failed to create post');
        }
      }

      throw Exception('Empty response from server');
    } catch (e) {
      developer.log(
        'Error creating post: $e',
        name: 'PostService',
        level: 900,
      );
      rethrow;
    }
  }

  /// Get a single post by ID
  ///
  /// GET /posts/{postId}
  /// Requires POST_READ permission
  Future<Post> getPost(int postId) async {
    try {
      developer.log('Fetching post: $postId', name: 'PostService');

      final response = await _dioClient.get<Map<String, dynamic>>(
        '/posts/$postId',
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => Post.fromJson(json as Map<String, dynamic>),
        );

        if (apiResponse.success && apiResponse.data != null) {
          developer.log(
            'Successfully fetched post: $postId',
            name: 'PostService',
          );
          return apiResponse.data!;
        } else {
          developer.log(
            'Failed to fetch post: ${apiResponse.message}',
            name: 'PostService',
            level: 900,
          );
          throw Exception(apiResponse.message ?? 'Failed to fetch post');
        }
      }

      throw Exception('Empty response from server');
    } catch (e) {
      developer.log(
        'Error fetching post: $e',
        name: 'PostService',
        level: 900,
      );
      rethrow;
    }
  }

  /// Update a post
  ///
  /// PUT /posts/{postId}
  /// Requires being the author or having admin permission
  Future<Post> updatePost(int postId, String content) async {
    try {
      developer.log('Updating post: $postId', name: 'PostService');

      final request = CreatePostRequest(content: content);

      final response = await _dioClient.put<Map<String, dynamic>>(
        '/posts/$postId',
        data: request.toJson(),
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => Post.fromJson(json as Map<String, dynamic>),
        );

        if (apiResponse.success && apiResponse.data != null) {
          developer.log(
            'Successfully updated post: $postId',
            name: 'PostService',
          );
          return apiResponse.data!;
        } else {
          developer.log(
            'Failed to update post: ${apiResponse.message}',
            name: 'PostService',
            level: 900,
          );
          throw Exception(apiResponse.message ?? 'Failed to update post');
        }
      }

      throw Exception('Empty response from server');
    } catch (e) {
      developer.log(
        'Error updating post: $e',
        name: 'PostService',
        level: 900,
      );
      rethrow;
    }
  }

  /// Delete a post
  ///
  /// DELETE /posts/{postId}
  /// Requires being the author or having admin permission
  Future<void> deletePost(int postId) async {
    try {
      developer.log('Deleting post: $postId', name: 'PostService');

      final response = await _dioClient.delete<Map<String, dynamic>>(
        '/posts/$postId',
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => null, // DELETE returns no data
        );

        if (apiResponse.success) {
          developer.log(
            'Successfully deleted post: $postId',
            name: 'PostService',
          );
          return;
        } else {
          developer.log(
            'Failed to delete post: ${apiResponse.message}',
            name: 'PostService',
            level: 900,
          );
          throw Exception(apiResponse.message ?? 'Failed to delete post');
        }
      }

      throw Exception('Empty response from server');
    } catch (e) {
      developer.log(
        'Error deleting post: $e',
        name: 'PostService',
        level: 900,
      );
      rethrow;
    }
  }
}
