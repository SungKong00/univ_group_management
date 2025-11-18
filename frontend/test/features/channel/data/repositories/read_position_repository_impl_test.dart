import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/channel/data/datasources/read_position_local_data_source.dart';
import 'package:frontend/features/channel/data/repositories/read_position_repository_impl.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'read_position_repository_impl_test.mocks.dart';

@GenerateMocks([ReadPositionLocalDataSource])
void main() {
  group('ReadPositionRepositoryImpl Tests', () {
    late ReadPositionRepositoryImpl repository;
    late MockReadPositionLocalDataSource mockLocalDataSource;

    setUp(() {
      mockLocalDataSource = MockReadPositionLocalDataSource();
      repository = ReadPositionRepositoryImpl(mockLocalDataSource);
    });

    group('getReadPosition', () {
      test('정상 케이스 - DataSource 위임', () async {
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
      });

      test('정상 케이스 - 존재하지 않는 위치 null 반환', () async {
        // Given
        final channelId = 999;

        when(
          mockLocalDataSource.getReadPosition(channelId),
        ).thenAnswer((_) async => null);

        // When
        final result = await repository.getReadPosition(channelId);

        // Then
        expect(result, isNull);
        verify(mockLocalDataSource.getReadPosition(channelId)).called(1);
      });
    });

    group('updateReadPosition', () {
      test('정상 케이스 - DataSource 위임', () async {
        // Given
        final channelId = 1;
        final position = 150;

        when(
          mockLocalDataSource.updateReadPosition(channelId, position),
        ).thenAnswer((_) async => {});

        // When
        await repository.updateReadPosition(channelId, position);

        // Then
        verify(
          mockLocalDataSource.updateReadPosition(channelId, position),
        ).called(1);
      });

      test('정상 케이스 - 0으로 업데이트', () async {
        // Given
        final channelId = 1;
        final position = 0;

        when(
          mockLocalDataSource.updateReadPosition(channelId, position),
        ).thenAnswer((_) async => {});

        // When
        await repository.updateReadPosition(channelId, position);

        // Then
        verify(
          mockLocalDataSource.updateReadPosition(channelId, position),
        ).called(1);
      });
    });
  });
}
