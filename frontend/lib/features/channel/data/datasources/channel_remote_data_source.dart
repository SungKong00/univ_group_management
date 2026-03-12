import 'dart:developer' as developer;
import '../../../../core/models/auth_models.dart';
import '../../../../core/network/dio_client.dart';
import '../models/channel_dto.dart';
import '../models/channel_permissions_dto.dart';

/// 채널 원격 데이터 소스 추상 클래스
abstract class ChannelRemoteDataSource {
  /// GET /workspaces/{workspaceId}/channels
  Future<List<ChannelDto>> getChannels(String workspaceId);

  /// GET /channels/{channelId}/permissions/me
  Future<ChannelPermissionsDto> getMyPermissions(int channelId);

  /// POST /workspaces/{workspaceId}/channels
  Future<ChannelDto> createChannel({
    required String workspaceId,
    required String name,
    required String type,
    String? description,
  });
}

/// 채널 원격 데이터 소스 구현
///
/// Dio를 사용하여 채널 관련 API를 호출합니다.
class ChannelRemoteDataSourceImpl implements ChannelRemoteDataSource {
  final DioClient _dioClient;

  ChannelRemoteDataSourceImpl(this._dioClient);

  @override
  Future<List<ChannelDto>> getChannels(String workspaceId) async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      '/workspaces/$workspaceId/channels',
    );

    return _unwrap(
      response,
      (json) => (json as List)
          .map((item) => ChannelDto.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Future<ChannelPermissionsDto> getMyPermissions(int channelId) async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      '/channels/$channelId/permissions/me',
    );

    return _unwrap(
      response,
      (json) => ChannelPermissionsDto.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ChannelDto> createChannel({
    required String workspaceId,
    required String name,
    required String type,
    String? description,
  }) async {
    final response = await _dioClient.post<Map<String, dynamic>>(
      '/workspaces/$workspaceId/channels',
      data: {
        'name': name,
        'type': type,
        if (description != null) 'description': description,
      },
    );

    return _unwrap(
      response,
      (json) => ChannelDto.fromJson(json as Map<String, dynamic>),
    );
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
      name: 'ChannelRemoteDataSource',
      level: 900,
    );
    throw Exception(apiResponse.message ?? 'API request failed');
  }
}
