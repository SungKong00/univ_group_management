import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/network/dio_client.dart';
import 'package:frontend/features/channel/data/datasources/channel_remote_data_source.dart';
import 'package:frontend/features/channel/data/models/channel_dto.dart';
import 'package:frontend/features/channel/data/models/channel_permissions_dto.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'channel_remote_data_source_test.mocks.dart';

@GenerateMocks([DioClient])
void main() {
  group('ChannelRemoteDataSource - getMyPermissions & createChannel', () {
    late ChannelRemoteDataSourceImpl dataSource;
    late MockDioClient mockDioClient;

    setUp(() {
      mockDioClient = MockDioClient();
      dataSource = ChannelRemoteDataSourceImpl(mockDioClient);
    });

    test('getMyPermissions - 권한 조회 성공', () async {
      final apiResponse = {
        'success': true,
        'data': {
          'permissions': ['READ', 'WRITE', 'DELETE'],
        },
      };
      when(mockDioClient.get<Map<String, dynamic>>('/channels/1/permissions/me'))
          .thenAnswer((_) async => Response(
                data: apiResponse,
                statusCode: 200,
                requestOptions: RequestOptions(path: ''),
              ));

      final result = await dataSource.getMyPermissions(1);

      expect(result, isA<ChannelPermissionsDto>());
      expect(result.permissions, ['READ', 'WRITE', 'DELETE']);
    });

    test('createChannel - 채널 생성 성공 (description 포함)', () async {
      final apiResponse = {
        'success': true,
        'data': {
          'id': 3,
          'name': '새 채널',
          'type': 'TEXT',
          'description': '설명',
        },
      };
      when(mockDioClient.post<Map<String, dynamic>>(
        '/workspaces/ws-1/channels',
        data: {'name': '새 채널', 'type': 'TEXT', 'description': '설명'},
      )).thenAnswer((_) async => Response(
            data: apiResponse,
            statusCode: 201,
            requestOptions: RequestOptions(path: ''),
          ));

      final result = await dataSource.createChannel(
        workspaceId: 'ws-1',
        name: '새 채널',
        type: 'TEXT',
        description: '설명',
      );

      expect(result, isA<ChannelDto>());
      expect(result.name, '새 채널');
    });

    test('createChannel - description 없이 생성', () async {
      final apiResponse = {
        'success': true,
        'data': {
          'id': 4,
          'name': '새 채널',
          'type': 'TEXT',
        },
      };
      when(mockDioClient.post<Map<String, dynamic>>(
        '/workspaces/ws-1/channels',
        data: {'name': '새 채널', 'type': 'TEXT'},
      )).thenAnswer((_) async => Response(
            data: apiResponse,
            statusCode: 201,
            requestOptions: RequestOptions(path: ''),
          ));

      final result = await dataSource.createChannel(
        workspaceId: 'ws-1',
        name: '새 채널',
        type: 'TEXT',
      );

      expect(result.description, isNull);
    });
  });
}
