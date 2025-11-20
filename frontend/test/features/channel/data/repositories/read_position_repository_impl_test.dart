import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/channel/data/datasources/read_position_local_data_source.dart';
import 'package:frontend/features/channel/data/datasources/read_position_remote_datasource.dart';
import 'package:frontend/features/channel/data/repositories/read_position_repository_impl.dart';
import 'package:frontend/features/channel/data/models/read_position_dto.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'read_position_repository_impl_test.mocks.dart';

@GenerateMocks([ReadPositionLocalDataSource, ReadPositionRemoteDataSource])
void main() {
  group('ReadPositionRepositoryImpl Tests', () {
    late ReadPositionRepositoryImpl repository;
    late MockReadPositionLocalDataSource mockLocalDataSource;
    late MockReadPositionRemoteDataSource mockRemoteDataSource;

    setUp(() {
      mockLocalDataSource = MockReadPositionLocalDataSource();
      mockRemoteDataSource = MockReadPositionRemoteDataSource();
      repository = ReadPositionRepositoryImpl(
        mockLocalDataSource,
        mockRemoteDataSource,
      );
    });

    group('getReadPosition', () {
      test('로컬 캐시 히트 - 원격 API 호출 없음', () async {
        // Given
        final channelId = 1;
        final position = 100;

        when(
          mockLocalDataSource.getReadPosition(channelId),
        ).thenAnswer((_) async => position);

        // When
        final result = await repository.getReadPosition(channelId);

        // Then
        expect(result, position);
        verify(mockLocalDataSource.getReadPosition(channelId)).called(1);
        verifyNever(mockRemoteDataSource.getReadPosition(channelId));
      });

      test('로컬 캐시 미스 - 원격 API 호출 후 캐시 저장', () async {
        // Given
        final channelId = 999;
        final remoteDto = ReadPositionDto(
          channelId: channelId,
          lastReadPostId: 200,
          updatedAt: DateTime.now(),
        );

        when(
          mockLocalDataSource.getReadPosition(channelId),
        ).thenAnswer((_) async => null);

        when(
          mockRemoteDataSource.getReadPosition(channelId),
        ).thenAnswer((_) async => remoteDto);

        when(
          mockLocalDataSource.updateReadPosition(channelId, 200),
        ).thenAnswer((_) async => {});

        // When
        final result = await repository.getReadPosition(channelId);

        // Then
        expect(result, 200);
        verify(mockLocalDataSource.getReadPosition(channelId)).called(1);
        verify(mockRemoteDataSource.getReadPosition(channelId)).called(1);
        verify(
          mockLocalDataSource.updateReadPosition(channelId, 200),
        ).called(1);
      });

      test('로컬/원격 모두 없음 - null 반환', () async {
        // Given
        final channelId = 999;

        when(
          mockLocalDataSource.getReadPosition(channelId),
        ).thenAnswer((_) async => null);

        when(
          mockRemoteDataSource.getReadPosition(channelId),
        ).thenAnswer((_) async => null);

        // When
        final result = await repository.getReadPosition(channelId);

        // Then
        expect(result, isNull);
        verify(mockLocalDataSource.getReadPosition(channelId)).called(1);
        verify(mockRemoteDataSource.getReadPosition(channelId)).called(1);
      });
    });

    group('updateReadPosition', () {
      test('원격 API 호출 + 로컬 캐시 갱신', () async {
        // Given
        final channelId = 1;
        final position = 150;

        when(
          mockRemoteDataSource.updateReadPosition(channelId, position),
        ).thenAnswer((_) async => {});

        when(
          mockLocalDataSource.updateReadPosition(channelId, position),
        ).thenAnswer((_) async => {});

        // When
        await repository.updateReadPosition(channelId, position);

        // Then
        verify(
          mockRemoteDataSource.updateReadPosition(channelId, position),
        ).called(1);
        verify(
          mockLocalDataSource.updateReadPosition(channelId, position),
        ).called(1);
      });
    });
  });
}
