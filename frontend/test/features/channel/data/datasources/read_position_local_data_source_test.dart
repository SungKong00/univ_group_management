import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/channel/data/datasources/read_position_local_data_source.dart';

void main() {
  group('ReadPositionLocalDataSource Tests', () {
    late ReadPositionLocalDataSourceImpl dataSource;

    setUp(() {
      dataSource = ReadPositionLocalDataSourceImpl();
    });

    group('getReadPosition', () {
      test('정상 케이스 - 존재하는 위치 반환', () async {
        // Given
        final channelId = 1;
        final position = 100;
        await dataSource.updateReadPosition(channelId, position);

        // When
        final result = await dataSource.getReadPosition(channelId);

        // Then
        expect(result, position);
      });

      test('정상 케이스 - 존재하지 않는 위치 null 반환', () async {
        // Given
        final channelId = 999;

        // When
        final result = await dataSource.getReadPosition(channelId);

        // Then
        expect(result, isNull);
      });

      test('정상 케이스 - 여러 채널의 위치 독립적으로 관리', () async {
        // Given
        final channelId1 = 1;
        final position1 = 100;
        final channelId2 = 2;
        final position2 = 200;

        await dataSource.updateReadPosition(channelId1, position1);
        await dataSource.updateReadPosition(channelId2, position2);

        // When
        final result1 = await dataSource.getReadPosition(channelId1);
        final result2 = await dataSource.getReadPosition(channelId2);

        // Then
        expect(result1, position1);
        expect(result2, position2);
      });
    });

    group('updateReadPosition', () {
      test('정상 케이스 - 위치 저장 및 조회', () async {
        // Given
        final channelId = 1;
        final position = 150;

        // When
        await dataSource.updateReadPosition(channelId, position);
        final result = await dataSource.getReadPosition(channelId);

        // Then
        expect(result, position);
      });

      test('정상 케이스 - 위치 업데이트', () async {
        // Given
        final channelId = 1;
        final oldPosition = 100;
        final newPosition = 200;

        await dataSource.updateReadPosition(channelId, oldPosition);

        // When
        await dataSource.updateReadPosition(channelId, newPosition);
        final result = await dataSource.getReadPosition(channelId);

        // Then
        expect(result, newPosition);
      });

      test('정상 케이스 - 0으로 초기화', () async {
        // Given
        final channelId = 1;
        final initialPosition = 100;
        await dataSource.updateReadPosition(channelId, initialPosition);

        // When
        await dataSource.updateReadPosition(channelId, 0);
        final result = await dataSource.getReadPosition(channelId);

        // Then
        expect(result, 0);
      });
    });
  });
}
