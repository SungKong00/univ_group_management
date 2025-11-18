import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/channel/data/datasources/channel_remote_data_source.dart';
import 'package:frontend/features/channel/data/models/channel_dto.dart';
import 'package:frontend/features/channel/data/models/channel_permissions_dto.dart';
import 'package:frontend/features/channel/data/repositories/channel_repository_impl.dart';
import 'package:frontend/features/channel/domain/entities/channel.dart';
import 'package:frontend/features/channel/domain/entities/channel_permissions.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'channel_repository_impl_test.mocks.dart';

@GenerateMocks([ChannelRemoteDataSource])
void main() {
  group('ChannelRepositoryImpl Tests', () {
    late ChannelRepositoryImpl repository;
    late MockChannelRemoteDataSource mockRemoteDataSource;

    setUp(() {
      mockRemoteDataSource = MockChannelRemoteDataSource();
      repository = ChannelRepositoryImpl(mockRemoteDataSource);
    });

    test('getChannels - DTO를 Entity로 변환', () async {
      final dtos = [
        ChannelDto(id: 1, name: '공지사항', type: 'ANNOUNCEMENT'),
        ChannelDto(id: 2, name: '자유게시판', type: 'TEXT'),
      ];
      when(mockRemoteDataSource.getChannels('ws-1'))
          .thenAnswer((_) async => dtos);

      final result = await repository.getChannels('ws-1');

      expect(result, isA<List<Channel>>());
      expect(result.length, 2);
      expect(result[0].name, '공지사항');
    });

    test('getChannels - DataSource 에러 전파', () async {
      when(mockRemoteDataSource.getChannels('ws-1'))
          .thenThrow(Exception('네트워크 에러'));

      expect(() => repository.getChannels('ws-1'), throwsA(isA<Exception>()));
    });

    test('getMyPermissions - DTO를 Entity로 변환', () async {
      final dto = ChannelPermissionsDto(
        permissions: ['READ', 'WRITE', 'DELETE'],
      );
      when(mockRemoteDataSource.getMyPermissions(1))
          .thenAnswer((_) async => dto);

      final result = await repository.getMyPermissions(1);

      expect(result, isA<ChannelPermissions>());
      expect(result.permissions, ['READ', 'WRITE', 'DELETE']);
    });

    test('createChannel - DTO를 Entity로 변환', () async {
      final dto = ChannelDto(
        id: 3,
        name: '새 채널',
        type: 'TEXT',
        description: '설명',
      );
      when(mockRemoteDataSource.createChannel(
        workspaceId: 'ws-1',
        name: '새 채널',
        type: 'TEXT',
        description: '설명',
      )).thenAnswer((_) async => dto);

      final result = await repository.createChannel(
        workspaceId: 'ws-1',
        name: '새 채널',
        type: 'TEXT',
        description: '설명',
      );

      expect(result, isA<Channel>());
      expect(result.name, '새 채널');
    });
  });
}
