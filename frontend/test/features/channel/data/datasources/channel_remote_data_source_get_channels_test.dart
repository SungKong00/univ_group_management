import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/network/dio_client.dart';
import 'package:frontend/features/channel/data/datasources/channel_remote_data_source.dart';
import 'package:frontend/features/channel/data/models/channel_dto.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'channel_remote_data_source_get_channels_test.mocks.dart';

@GenerateMocks([DioClient])
void main() {
  group('ChannelRemoteDataSource - getChannels', () {
    late ChannelRemoteDataSourceImpl dataSource;
    late MockDioClient mockDioClient;

    setUp(() {
      mockDioClient = MockDioClient();
      dataSource = ChannelRemoteDataSourceImpl(mockDioClient);
    });

    test('정상 케이스 - 채널 목록 조회 성공', () async {
      final apiResponse = {
        'success': true,
        'data': [
          {'id': 1, 'name': '공지사항', 'type': 'ANNOUNCEMENT'},
          {'id': 2, 'name': '자유게시판', 'type': 'TEXT'},
        ],
      };
      when(
        mockDioClient.get<Map<String, dynamic>>('/workspaces/ws-1/channels'),
      ).thenAnswer(
        (_) async => Response(
          data: apiResponse,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      final result = await dataSource.getChannels('ws-1');

      expect(result, isA<List<ChannelDto>>());
      expect(result.length, 2);
      expect(result[0].name, '공지사항');
    });

    test('에러 케이스 - Empty response', () async {
      when(
        mockDioClient.get<Map<String, dynamic>>('/workspaces/ws-1/channels'),
      ).thenAnswer(
        (_) async => Response(
          data: null,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      expect(
        () => dataSource.getChannels('ws-1'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Empty response'),
          ),
        ),
      );
    });

    test('에러 케이스 - API failure', () async {
      final apiResponse = {
        'success': false,
        'message': 'Unauthorized',
        'data': null,
      };
      when(
        mockDioClient.get<Map<String, dynamic>>('/workspaces/ws-1/channels'),
      ).thenAnswer(
        (_) async => Response(
          data: apiResponse,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      expect(
        () => dataSource.getChannels('ws-1'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Unauthorized'),
          ),
        ),
      );
    });
  });
}
