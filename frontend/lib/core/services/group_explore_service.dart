import 'dart:developer' as developer;
import '../models/group_models.dart';
import '../models/auth_models.dart';
import '../models/paged_response.dart';
import '../network/dio_client.dart';

/// Group Explore Service
///
/// Provides API methods for exploring and searching groups with filters.
class GroupExploreService {
  static final GroupExploreService _instance = GroupExploreService._internal();
  factory GroupExploreService() => _instance;
  GroupExploreService._internal();

  final DioClient _dioClient = DioClient();

  /// Get groups with pagination
  ///
  /// GET /api/groups/explore
  ///
  /// Returns paginated groups with filters.
  Future<PagedApiResponse<GroupSummaryResponse>> getGroups({
    int page = 0,
    int size = 20,
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      developer.log(
        'Fetching groups (page: $page, size: $size)',
        name: 'GroupExploreService',
      );

      final params = <String, dynamic>{
        'page': page,
        'size': size,
        ...?queryParams,
      };

      final response = await _dioClient.get<Map<String, dynamic>>(
        '/groups/explore',
        queryParameters: params,
      );

      if (response.data != null) {
        final pagedResponse = PagedApiResponse.fromJson(
          response.data!,
          (json) => GroupSummaryResponse.fromJson(json),
        );

        developer.log(
          'Successfully fetched ${pagedResponse.data.content.length} groups (page ${pagedResponse.data.pagination.page})',
          name: 'GroupExploreService',
        );

        return pagedResponse;
      }

      // Return empty response if no data
      return PagedApiResponse(
        success: false,
        data: PagedData(
          content: [],
          pagination: PaginationInfo(
            page: page,
            size: size,
            totalElements: 0,
            totalPages: 0,
            first: true,
            last: true,
            hasNext: false,
            hasPrevious: false,
          ),
        ),
        timestamp: DateTime.now().toIso8601String(),
      );
    } catch (e) {
      developer.log(
        'Error fetching groups: $e',
        name: 'GroupExploreService',
        level: 900,
      );
      rethrow;
    }
  }

  /// Get all groups without pagination
  ///
  /// GET /api/groups/all
  ///
  /// 모든 그룹을 페이징 없이 조회합니다. (로컬 필터링용)
  /// 초기 로딩 시에만 호출되며, 이후는 로컬 필터링으로만 처리합니다.
  Future<List<GroupSummaryResponse>> getAllGroups() async {
    try {
      developer.log(
        'Fetching all groups (no pagination)',
        name: 'GroupExploreService',
      );
      print('🔍 [DEBUG] getAllGroups() 시작: /groups/all 호출');

      final response = await _dioClient.get<dynamic>(
        '/groups/all',
      );

      print('🔍 [DEBUG] getAllGroups() API 응답: statusCode=${response.statusCode}');
      print('🔍 [DEBUG] getAllGroups() response.data type: ${response.data.runtimeType}');
      print('🔍 [DEBUG] getAllGroups() response.data: ${response.data}');

      if (response.data != null) {
        final List<dynamic> data;

        // Handle different response structures
        if (response.data is Map<String, dynamic>) {
          final map = response.data as Map<String, dynamic>;
          print('🔍 [DEBUG] response.data는 Map, keys: ${map.keys}');

          // 1. Standard ApiResponse wrapper: {success, data, error, timestamp}
          if (map.containsKey('data') && map['data'] is List) {
            data = map['data'] as List<dynamic>;
            print('🔍 [DEBUG] data 키에서 List 추출: ${data.length}개 항목');
          }
          // 2. Spring Data Page response: {content, totalElements, ...}
          else if (map.containsKey('content') && map['content'] is List) {
            data = map['content'] as List<dynamic>;
            print('🔍 [DEBUG] content 키에서 List 추출: ${data.length}개 항목');
          }
          // 3. Other wrapper formats (items, results, etc.)
          else if (map.containsKey('items') && map['items'] is List) {
            data = map['items'] as List<dynamic>;
            print('🔍 [DEBUG] items 키에서 List 추출: ${data.length}개 항목');
          }
          else {
            print('❌ [DEBUG] Map이지만 data/content/items 키가 없거나 List가 아님');
            print('❌ [DEBUG] 사용 가능한 키: ${map.keys.toList()}');
            return [];
          }
        }
        // API가 배열 형태로 직접 반환하는 경우
        else if (response.data is List) {
          data = response.data as List<dynamic>;
          print('🔍 [DEBUG] response.data는 List: ${data.length}개 항목');
        } else {
          print('❌ [DEBUG] response.data가 Map도 List도 아님');
          print('❌ [DEBUG] response.data 타입: ${response.data.runtimeType}');
          return [];
        }

        final groups = data
            .map((item) => GroupSummaryResponse.fromJson(
                item as Map<String, dynamic>))
            .toList();

        print('🔍 [DEBUG] 파싱 완료: ${groups.length}개 그룹');
        developer.log(
          'Successfully fetched ${groups.length} groups',
          name: 'GroupExploreService',
        );
        return groups;
      }

      print('❌ [DEBUG] response.data가 null');
      return [];
    } catch (e, stackTrace) {
      print('❌ [DEBUG] getAllGroups() 에러: $e');
      print('❌ [DEBUG] Stack trace: $stackTrace');
      developer.log(
        'Error fetching all groups: $e',
        name: 'GroupExploreService',
        level: 900,
      );
      rethrow;
    }
  }

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
          queryParams['groupTypes'] = (filters['groupTypes'] as List).join(',');
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

      developer.log(
        'API Request - Query Params: $queryParams',
        name: 'GroupExploreService',
      );

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
