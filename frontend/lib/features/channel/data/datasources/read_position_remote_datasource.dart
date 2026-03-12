import 'dart:developer' as developer;
import '../../../../core/models/auth_models.dart';
import '../../../../core/network/dio_client.dart';
import '../models/read_position_dto.dart';

/// 읽음 위치 원격 데이터 소스 추상 클래스
abstract class ReadPositionRemoteDataSource {
  /// GET /api/channels/{channelId}/read-position
  Future<ReadPositionDto?> getReadPosition(int channelId);

  /// PUT /api/channels/{channelId}/read-position
  Future<void> updateReadPosition(int channelId, int postId);

  /// GET /api/channels/{channelId}/unread-count
  Future<int> getUnreadCount(int channelId);

  /// GET /api/channels/unread-counts?channelIds=1,2,3
  Future<Map<int, int>> getBatchUnreadCounts(List<int> channelIds);
}

/// 읽음 위치 원격 데이터 소스 구현
///
/// Dio를 사용하여 읽음 위치 관련 API를 호출합니다.
class ReadPositionRemoteDataSourceImpl implements ReadPositionRemoteDataSource {
  final DioClient _dioClient;

  ReadPositionRemoteDataSourceImpl(this._dioClient);

  @override
  Future<ReadPositionDto?> getReadPosition(int channelId) async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      '/channels/$channelId/read-position',
    );

    return _unwrapNullable(
      response,
      (json) => ReadPositionDto.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<void> updateReadPosition(int channelId, int postId) async {
    final response = await _dioClient.put<Map<String, dynamic>>(
      '/channels/$channelId/read-position',
      data: {'lastReadPostId': postId},
    );

    _unwrap(response, (json) => null);
  }

  @override
  Future<int> getUnreadCount(int channelId) async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      '/channels/$channelId/unread-count',
    );

    return _unwrap(
      response,
      (json) => (json as Map<String, dynamic>)['count'] as int,
    );
  }

  @override
  Future<Map<int, int>> getBatchUnreadCounts(List<int> channelIds) async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      '/channels/unread-counts',
      queryParameters: {'channelIds': channelIds.join(',')},
    );

    return _unwrap(
      response,
      (json) => (json as Map<String, dynamic>).map(
        (key, value) => MapEntry(int.parse(key), value as int),
      ),
    );
  }

  /// ApiResponse 래핑 해제 (null 허용)
  T? _unwrapNullable<T>(dynamic response, T Function(Object? json) fromJson) {
    if (response.data == null) return null;

    final apiResponse = ApiResponse.fromJson(response.data!, fromJson);
    return apiResponse.success ? apiResponse.data : null;
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
      name: 'ReadPositionRemoteDataSource',
      level: 900,
    );
    throw Exception(apiResponse.message ?? 'API request failed');
  }
}
