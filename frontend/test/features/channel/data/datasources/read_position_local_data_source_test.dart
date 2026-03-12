import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/channel/data/datasources/read_position_local_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ReadPositionLocalDataSourceImpl Tests', () {
    late ReadPositionLocalDataSourceImpl dataSource;

    setUp(() {
      // SharedPreferences 모킹 초기화
      SharedPreferences.setMockInitialValues({});
      dataSource = ReadPositionLocalDataSourceImpl();
    });

    group('getReadPosition', () {
      test('정상 케이스 - 저장된 읽음 위치 반환', () async {
        // Given
        const channelId = 1;
        const position = 100;
        await dataSource.updateReadPosition(channelId, position);

        // When
        final result = await dataSource.getReadPosition(channelId);

        // Then
        expect(result, position);
      });

      test('정상 케이스 - 존재하지 않는 채널은 null 반환', () async {
        // Given
        const channelId = 999;

        // When
        final result = await dataSource.getReadPosition(channelId);

        // Then
        expect(result, isNull);
      });

      test('캐시 동작 - 두 번째 호출은 캐시에서 반환', () async {
        // Given
        const channelId = 1;
        const position = 150;
        await dataSource.updateReadPosition(channelId, position);

        // When
        final firstCall = await dataSource.getReadPosition(channelId);
        final secondCall = await dataSource.getReadPosition(channelId);

        // Then
        expect(firstCall, position);
        expect(secondCall, position);
      });
    });

    group('updateReadPosition', () {
      test('정상 케이스 - 읽음 위치 저장 및 조회', () async {
        // Given
        const channelId = 1;
        const position = 200;

        // When
        await dataSource.updateReadPosition(channelId, position);
        final result = await dataSource.getReadPosition(channelId);

        // Then
        expect(result, position);
      });

      test('정상 케이스 - 기존 읽음 위치 덮어쓰기', () async {
        // Given
        const channelId = 1;
        const oldPosition = 100;
        const newPosition = 150;

        // When
        await dataSource.updateReadPosition(channelId, oldPosition);
        await dataSource.updateReadPosition(channelId, newPosition);
        final result = await dataSource.getReadPosition(channelId);

        // Then
        expect(result, newPosition);
      });

      test('정상 케이스 - 0으로 업데이트', () async {
        // Given
        const channelId = 1;
        const position = 0;

        // When
        await dataSource.updateReadPosition(channelId, position);
        final result = await dataSource.getReadPosition(channelId);

        // Then
        expect(result, 0);
      });

      test('멀티 채널 - 여러 채널의 읽음 위치 독립적으로 관리', () async {
        // Given
        const channel1 = 1;
        const channel2 = 2;
        const position1 = 100;
        const position2 = 200;

        // When
        await dataSource.updateReadPosition(channel1, position1);
        await dataSource.updateReadPosition(channel2, position2);

        final result1 = await dataSource.getReadPosition(channel1);
        final result2 = await dataSource.getReadPosition(channel2);

        // Then
        expect(result1, position1);
        expect(result2, position2);
      });
    });

    group('영구 저장소 테스트', () {
      test('앱 재시작 시나리오 - 저장된 데이터 복원', () async {
        // Given
        const channelId = 1;
        const position = 300;

        // 1. 데이터 저장
        await dataSource.updateReadPosition(channelId, position);

        // 2. 앱 재시작 시뮬레이션 (새 인스턴스 생성)
        final newDataSource = ReadPositionLocalDataSourceImpl();

        // When
        final result = await newDataSource.getReadPosition(channelId);

        // Then
        expect(result, position);
      });
    });
  });
}
