import 'dart:developer' as developer;
import '../models/group_models.dart';
import '../models/auth_models.dart';
import '../network/dio_client.dart';

/// Group Explore Service
///
/// Provides API methods for exploring and searching groups with filters.
class GroupExploreService {
  static final GroupExploreService _instance = GroupExploreService._internal();
  factory GroupExploreService() => _instance;
  GroupExploreService._internal();

  final DioClient _dioClient = DioClient();

  /// Explore groups with search and filters
  ///
  /// GET /api/groups/explore
  /// Query parameters:
  /// - q: search query
  /// - groupType: filter by group type (AUTONOMOUS, OFFICIAL, etc.)
  /// - isRecruiting: filter by recruitment status
  /// - tags: comma-separated tags
  /// - page: page number (default: 0)
  /// - size: page size (default: 20)
  Future<List<GroupSummaryResponse>> exploreGroups({
    String? query,
    Map<String, dynamic>? filters,
    int page = 0,
    int size = 20,
  }) async {
    try {
      developer.log(
        'Exploring groups - query: $query, filters: $filters, page: $page',
        name: 'GroupExploreService',
      );

      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
      };

      // Add search query
      if (query != null && query.isNotEmpty) {
        queryParams['q'] = query;
      }

      // Add filters
      if (filters != null) {
        // Multi-select group types (comma-separated)
        if (filters['groupTypes'] != null && (filters['groupTypes'] as List).isNotEmpty) {
          queryParams['groupType'] = (filters['groupTypes'] as List).join(',');
        }
        // Recruiting filter (use 'recruiting' parameter name)
        if (filters['recruiting'] != null) {
          queryParams['recruiting'] = filters['recruiting'];
        }
        // Tags filter
        if (filters['tags'] != null && (filters['tags'] as List).isNotEmpty) {
          queryParams['tags'] = (filters['tags'] as List).join(',');
        }
      }

      final response = await _dioClient.get<Map<String, dynamic>>(
        '/groups/explore',
        queryParameters: queryParams,
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(response.data!, (json) {
          // API returns { content: [], pagination: {} }
          if (json is Map<String, dynamic> && json.containsKey('content')) {
            final content = json['content'];
            if (content is List) {
              return content
                  .map((item) =>
                      GroupSummaryResponse.fromJson(item as Map<String, dynamic>))
                  .toList();
            }
          }
          // Fallback for direct array response
          if (json is List) {
            return json
                .map((item) =>
                    GroupSummaryResponse.fromJson(item as Map<String, dynamic>))
                .toList();
          }
          return <GroupSummaryResponse>[];
        });

        if (apiResponse.success && apiResponse.data != null) {
          developer.log(
            'Successfully fetched ${apiResponse.data!.length} groups',
            name: 'GroupExploreService',
          );
          return apiResponse.data!;
        } else {
          developer.log(
            'Failed to explore groups: ${apiResponse.message}',
            name: 'GroupExploreService',
            level: 900,
          );
          return [];
        }
      }

      return [];
    } catch (e) {
      developer.log(
        'Error exploring groups: $e',
        name: 'GroupExploreService',
        level: 900,
      );
      rethrow;
    }
  }
}
