import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/channel/domain/repositories/read_position_repository.dart';
import 'package:frontend/features/channel/domain/usecases/get_batch_unread_counts_usecase.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'get_batch_unread_counts_usecase_test.mocks.dart';

@GenerateMocks([ReadPositionRepository])
void main() {
  group('GetBatchUnreadCountsUseCase Tests', () {
    late GetBatchUnreadCountsUseCase useCase;
    late MockReadPositionRepository mockRepository;

    setUp(() {
      mockRepository = MockReadPositionRepository();
      useCase = GetBatchUnreadCountsUseCase(mockRepository);
    });

    test('정상 케이스 - 여러 채널의 읽지 않은 글 개수 반환', () async {
      // Given
      const channelIds = [1, 2, 3];
      when(mockRepository.getUnreadCount(1)).thenAnswer((_) async => 5);
      when(mockRepository.getUnreadCount(2)).thenAnswer((_) async => 10);
      when(mockRepository.getUnreadCount(3)).thenAnswer((_) async => 0);

      // When
      final result = await useCase(channelIds);

      // Then
      expect(result, {1: 5, 2: 10, 3: 0});
      verify(mockRepository.getUnreadCount(1)).called(1);
      verify(mockRepository.getUnreadCount(2)).called(1);
      verify(mockRepository.getUnreadCount(3)).called(1);
    });

    test('정상 케이스 - 빈 리스트 입력 시 빈 Map 반환', () async {
      // Given
      const channelIds = <int>[];

      // When
      final result = await useCase(channelIds);

      // Then
      expect(result, <int, int>{});
      verifyNever(mockRepository.getUnreadCount(any));
    });

    test('에러 처리 - 일부 채널 실패 시 0으로 처리하고 다른 채널 계속 조회', () async {
      // Given
      const channelIds = [1, 2, 3];
      when(mockRepository.getUnreadCount(1)).thenAnswer((_) async => 5);
      when(mockRepository.getUnreadCount(2)).thenThrow(Exception('API 에러'));
      when(mockRepository.getUnreadCount(3)).thenAnswer((_) async => 7);

      // When
      final result = await useCase(channelIds);

      // Then
      expect(result, {1: 5, 2: 0, 3: 7});
      verify(mockRepository.getUnreadCount(1)).called(1);
      verify(mockRepository.getUnreadCount(2)).called(1);
      verify(mockRepository.getUnreadCount(3)).called(1);
    });

    test('정상 케이스 - 단일 채널 조회', () async {
      // Given
      const channelIds = [1];
      when(mockRepository.getUnreadCount(1)).thenAnswer((_) async => 42);

      // When
      final result = await useCase(channelIds);

      // Then
      expect(result, {1: 42});
      verify(mockRepository.getUnreadCount(1)).called(1);
    });

    test('정상 케이스 - 많은 채널 조회', () async {
      // Given
      final channelIds = List.generate(50, (i) => i + 1);
      for (final id in channelIds) {
        when(mockRepository.getUnreadCount(id)).thenAnswer((_) async => id * 2);
      }

      // When
      final result = await useCase(channelIds);

      // Then
      expect(result.length, 50);
      for (final id in channelIds) {
        expect(result[id], id * 2);
      }
    });
  });
}
