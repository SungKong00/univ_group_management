import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/channel/domain/entities/channel.dart';
import 'package:frontend/features/channel/domain/usecases/get_channel_list_usecase.dart';
import 'package:frontend/features/channel/presentation/providers/channel_list_notifier.dart';
import 'package:frontend/features/channel/presentation/providers/channel_providers.dart';
import 'package:frontend/presentation/providers/workspace_state_provider.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'channel_list_notifier_test.mocks.dart';

@GenerateMocks([GetChannelListUseCase])
void main() {
  group('ChannelListNotifier Tests', () {
    late MockGetChannelListUseCase mockUseCase;
    late ProviderContainer container;

    setUp(() {
      mockUseCase = MockGetChannelListUseCase();
    });

    tearDown(() {
      container.dispose();
    });

    ProviderContainer createContainer(String? groupId) {
      return ProviderContainer(
        overrides: [
          getChannelListUseCaseProvider.overrideWithValue(mockUseCase),
          currentGroupIdProvider.overrideWith((ref) => groupId),
        ],
      );
    }

    test('초기 로딩 - groupId가 null이면 빈 리스트 반환', () async {
      // Given
      container = createContainer(null);

      // When
      final state = await container.read(channelListProvider.future);

      // Then
      expect(state, isEmpty);
      verifyNever(mockUseCase(any));
    });

    test('초기 로딩 - groupId가 있으면 UseCase 호출', () async {
      // Given
      final channels = [
        Channel(id: 1, name: 'General', type: 'TEXT'),
        Channel(id: 2, name: 'Announcements', type: 'TEXT'),
      ];
      when(mockUseCase('group-1')).thenAnswer((_) async => channels);
      container = createContainer('group-1');

      // When
      final state = await container.read(channelListProvider.future);

      // Then
      expect(state, channels);
      verify(mockUseCase('group-1')).called(1);
    });

    test('refresh() - 데이터 재로딩', () async {
      // Given
      final initialChannels = [Channel(id: 1, name: 'Channel 1', type: 'TEXT')];
      final refreshedChannels = [
        Channel(id: 1, name: 'Channel 1', type: 'TEXT'),
        Channel(id: 2, name: 'Channel 2', type: 'TEXT'),
      ];
      when(mockUseCase('group-1')).thenAnswer((_) async => initialChannels);
      container = createContainer('group-1');

      await container.read(channelListProvider.future);

      // When
      when(mockUseCase('group-1')).thenAnswer((_) async => refreshedChannels);
      await container.read(channelListProvider.notifier).refresh();

      // Then
      final state = container.read(channelListProvider);
      expect(state.value, refreshedChannels);
      verify(mockUseCase('group-1')).called(2); // build + refresh
    });

    test('addChannel() - 낙관적 업데이트', () async {
      // Given
      final initialChannels = [Channel(id: 1, name: 'Channel 1', type: 'TEXT')];
      when(mockUseCase('group-1')).thenAnswer((_) async => initialChannels);
      container = createContainer('group-1');

      await container.read(channelListProvider.future);

      // When
      final newChannel = Channel(id: 2, name: 'New Channel', type: 'TEXT');
      container.read(channelListProvider.notifier).addChannel(newChannel);

      // Then
      final state = container.read(channelListProvider);
      expect(state.value, [
        Channel(id: 1, name: 'Channel 1', type: 'TEXT'),
        Channel(id: 2, name: 'New Channel', type: 'TEXT'),
      ]);
    });

    test('removeChannel() - 낙관적 업데이트', () async {
      // Given
      final channels = [
        Channel(id: 1, name: 'Channel 1', type: 'TEXT'),
        Channel(id: 2, name: 'Channel 2', type: 'TEXT'),
      ];
      when(mockUseCase('group-1')).thenAnswer((_) async => channels);
      container = createContainer('group-1');

      await container.read(channelListProvider.future);

      // When
      container.read(channelListProvider.notifier).removeChannel(1);

      // Then
      final state = container.read(channelListProvider);
      expect(state.value, [Channel(id: 2, name: 'Channel 2', type: 'TEXT')]);
    });

    test('에러 케이스 - UseCase 실패 시 AsyncError 상태', () async {
      // Given
      when(mockUseCase('group-1')).thenThrow(Exception('Network error'));
      container = createContainer('group-1');

      // When
      final stateFuture = container.read(channelListProvider.future);

      // Then
      await expectLater(stateFuture, throwsA(isA<Exception>()));
    });
  });
}
