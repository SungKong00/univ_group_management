import '../../core/network/dio_client.dart';
import '../../core/network/api_response.dart';
import '../../domain/repositories/group_repository.dart';
import '../models/group_model.dart';

class GroupRepositoryImpl implements GroupRepository {
  final DioClient _client;
  GroupRepositoryImpl(this._client);

  @override
  Future<ApiResponse<List<GroupHierarchyNode>>> getGroupHierarchy() async {
    return _client.getWithParser(
      '/groups/hierarchy',
      (data) {
        final items = data as List<dynamic>;
        return items.map((item) => GroupHierarchyNode.fromJson(item as Map<String, dynamic>)).toList();
      },
    );
  }

  @override
  Future<ApiResponse<List<GroupSummaryModel>>> getAllGroups() async {
    // Page<ApiResponse> 형태를 받아 content만 추출해 List로 반환
    return _client.getWithParser(
      '/groups/explore',
      (data) {
        final page = data as Map<String, dynamic>; // { content, totalElements, ... }
        final content = (page['content'] as List<dynamic>? ?? [])
            .map((item) => GroupSummaryModel.fromJson(item as Map<String, dynamic>))
            .toList();
        // 안정적 표시를 위해 그룹 타입 우선순위 + 이름으로 정렬
        content.sort((a, b) {
          int order(GroupType t) {
            switch (t) {
              case GroupType.university:
                return 0;
              case GroupType.college:
                return 1;
              case GroupType.department:
                return 2;
              case GroupType.lab:
                return 3;
              case GroupType.official:
                return 4;
              case GroupType.autonomous:
                return 5;
              case GroupType.unknown:
                return 6;
            }
          }
          final byType = order(a.groupType).compareTo(order(b.groupType));
          if (byType != 0) return byType;
          return a.name.compareTo(b.name);
        });
        return content;
      },
      queryParameters: const {
        'page': 0,
        'size': 1000,
      },
    );
  }

  @override
  Future<ApiResponse<List<GroupSummaryModel>>> getSubGroups(int parentId) async {
    return _client.getWithParser(
      '/groups/$parentId/sub-groups',
      (data) {
        final items = data as List<dynamic>;
        return items.map((item) => GroupSummaryModel.fromJson(item as Map<String, dynamic>)).toList();
      },
    );
  }

  @override
  Future<ApiResponse<bool>> checkGroupMembership(int groupId) async {
    return _client.getWithParser(
      '/groups/$groupId/membership/check',
      (data) => data as bool,
    );
  }

  @override
  Future<ApiResponse<Map<int, bool>>> checkBatchGroupMembership(List<int> groupIds) async {
    return _client.postWithParser(
      '/groups/membership/check',
      groupIds,
      (data) {
        final Map<String, dynamic> rawMap = data as Map<String, dynamic>;
        final Map<int, bool> result = {};
        rawMap.forEach((key, value) {
          result[int.parse(key)] = value as bool;
        });
        return result;
      },
    );
  }
}
