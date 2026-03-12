import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/channel/domain/entities/channel.dart';
import 'package:frontend/features/channel/domain/repositories/channel_repository.dart';
import 'package:frontend/features/channel/domain/usecases/get_channel_list_usecase.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'get_channel_list_usecase_test.mocks.dart';

@GenerateMocks([ChannelRepository])
void main() {
  group('GetChannelListUseCase Tests', () {
    late GetChannelListUseCase useCase;
    late MockChannelRepository mockRepository;

    setUp(() {
      mockRepository = MockChannelRepository();
      useCase = GetChannelListUseCase(mockRepository);
    });

    test('정상 케이스 - 채널 목록 조회 성공', () async {
      // Given
      final workspaceId = 'workspace-1';
      final channels = [
        Channel(id: 1, name: '공지사항', type: 'ANNOUNCEMENT'),
        Channel(id: 2, name: '자유게시판', type: 'TEXT'),
      ];

      when(
        mockRepository.getChannels(workspaceId),
      ).thenAnswer((_) async => channels);

      // When
      final result = await useCase(workspaceId);

      // Then
      expect(result, equals(channels));
      verify(mockRepository.getChannels(workspaceId)).called(1);
    });

    test('입력 검증 - 빈 workspaceId', () async {
      // Given
      final workspaceId = '';

      // When / Then
      expect(
        () => useCase(workspaceId),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('워크스페이스 ID는 비어있을 수 없습니다'),
          ),
        ),
      );

      verifyNever(mockRepository.getChannels(any));
    });

    test('에러 케이스 - Repository 호출 실패', () async {
      // Given
      final workspaceId = 'workspace-1';
      final exception = Exception('네트워크 에러');

      when(mockRepository.getChannels(workspaceId)).thenThrow(exception);

      // When / Then
      expect(() => useCase(workspaceId), throwsA(isA<Exception>()));
    });

    test('빈 채널 목록 반환', () async {
      // Given
      final workspaceId = 'workspace-2';
      final channels = <Channel>[];

      when(
        mockRepository.getChannels(workspaceId),
      ).thenAnswer((_) async => channels);

      // When
      final result = await useCase(workspaceId);

      // Then
      expect(result, isEmpty);
      verify(mockRepository.getChannels(workspaceId)).called(1);
    });
  });
}
