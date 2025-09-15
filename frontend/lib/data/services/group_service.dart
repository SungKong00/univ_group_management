import 'package:dio/dio.dart';
import '../../core/network/api_response.dart';
import '../../core/network/dio_client.dart';
import '../models/group_model.dart';

class GroupService {
  final DioClient _dio;
  GroupService(this._dio);

  Map<String, dynamic> _ensureMap(dynamic data, String endpoint) {
    if (data is Map<String, dynamic>) return data;
    throw StateError('서버 응답 형식이 올바르지 않습니다: $endpoint');
  }

  ApiResponse<_Page<T>> _parsePageApiResponse<T>(Map<String, dynamic> root, T Function(Object? json) fromJsonT) {
    // 래퍼 형태 { success, data, error } 인 경우
    if (root.containsKey('success') || root.containsKey('data') || root.containsKey('error')) {
      return ApiResponse.fromJson(root, (data) => _Page.fromJson(data as Map<String, dynamic>, fromJsonT));
    }
    // 래퍼 없이 Page가 바로 오는 경우
    return ApiResponse<_Page<T>>(success: true, data: _Page.fromJson(root, fromJsonT));
  }

  Future<ApiResponse<_Page<GroupSummaryModel>>> explore({int page = 0, int size = 10}) async {
    final Response resp = await _dio.dio.get(
      '/groups',
      queryParameters: {
        'page': page,
        'size': size,
        'sort': 'createdAt,desc',
      },
    );
    final json = _ensureMap(resp.data, '/groups');
    return _parsePageApiResponse<GroupSummaryModel>(json, (item) => GroupSummaryModel.fromJson(item as Map<String, dynamic>));
  }

  // 전체 그룹 조회 (트리뷰용)
  Future<ApiResponse<_Page<GroupSummaryModel>>> getAllGroups({
    bool? recruiting,
    String? visibility,
    String? groupType,
    String? university,
    String? college,
    String? department,
    String? query,
    List<String>? tags,
    int page = 0,
    int size = 1000,
  }) async {
    final queryParams = <String, dynamic>{
      if (recruiting != null) 'recruiting': recruiting,
      if (visibility != null) 'visibility': visibility,
      if (groupType != null) 'groupType': groupType,
      if (university != null) 'university': university,
      if (college != null) 'college': college,
      if (department != null) 'department': department,
      if (query != null) 'q': query,
      if (tags != null && tags.isNotEmpty) 'tags': tags.join(','),
      'page': page,
      'size': size,
    };

    final Response resp = await _dio.dio.get(
      '/groups/explore',
      queryParameters: queryParams,
    );

    final json = _ensureMap(resp.data, '/groups/explore');
    return _parsePageApiResponse<GroupSummaryModel>(json, (item) => GroupSummaryModel.fromJson(item as Map<String, dynamic>));
  }

  // 그룹 상세 정보 조회
  Future<ApiResponse<GroupModel>> getGroup(int groupId) async {
    final Response resp = await _dio.dio.get('/groups/$groupId');
    final json = _ensureMap(resp.data, '/groups/$groupId');
    return ApiResponse.fromJson(
      json,
      (data) => GroupModel.fromJson(data as Map<String, dynamic>),
    );
  }

  // 하위 그룹 조회
  Future<ApiResponse<List<GroupSummaryModel>>> getSubGroups(int parentGroupId) async {
    final Response resp = await _dio.dio.get('/groups/$parentGroupId/sub-groups');
    final json = _ensureMap(resp.data, '/groups/$parentGroupId/sub-groups');
    return ApiResponse.fromJson(
      json,
      (data) => (data as List).map((item) =>
          GroupSummaryModel.fromJson(item as Map<String, dynamic>)
      ).toList(),
    );
  }

  // 사용자가 그룹 멤버인지 확인
  Future<bool> isGroupMember(int groupId) async {
    try {
      final Response resp = await _dio.dio.get('/groups/$groupId/me/permissions');
      final json = _ensureMap(resp.data, '/groups/$groupId/me/permissions');
      final apiResponse = ApiResponse.fromJson(
        json,
        (data) => (data as List).map((e) => e.toString()).toSet(),
      );
      return apiResponse.success && (apiResponse.data?.isNotEmpty ?? false);
    } catch (e) {
      return false;
    }
  }
}

class _Page<T> {
  final List<T> content;
  final int totalElements;
  final int totalPages;
  final int number;
  final int size;

  _Page({required this.content, required this.totalElements, required this.totalPages, required this.number, required this.size});

  factory _Page.fromJson(Map<String, dynamic> json, T Function(Object? json) fromJsonT) {
    // json은 이미 ApiResponse의 data 필드에 해당하는 페이지 객체입니다.
    final list = ((json['content'] as List?) ?? []).map(fromJsonT).toList();
    return _Page<T>(
      content: list,
      totalElements: (json['totalElements'] ?? 0) as int,
      totalPages: (json['totalPages'] ?? 0) as int,
      number: (json['number'] ?? 0) as int,
      size: (json['size'] ?? 0) as int,
    );
  }
}
