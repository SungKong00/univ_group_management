import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/channel/domain/entities/channel.dart';
import 'package:frontend/features/channel/domain/entities/channel_entry_result.dart';
import 'package:frontend/features/channel/domain/entities/channel_permissions.dart';
import 'package:frontend/features/channel/domain/usecases/enter_channel_usecase.dart';
import 'package:frontend/features/channel/presentation/providers/channel_entry_notifier.dart';
import 'package:frontend/features/channel/presentation/providers/channel_providers.dart';
import 'package:frontend/features/post/domain/entities/author.dart';
import 'package:frontend/features/post/domain/entities/post.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'channel_entry_notifier_test.mocks.dart';

@GenerateMocks([EnterChannelUseCase])
void main() {
  group('ChannelEntryNotifier Tests', () {
    late MockEnterChannelUseCase mockUseCase;
    late ProviderContainer container;

    setUp(() {
      mockUseCase = MockEnterChannelUseCase();
    });

    tearDown(() {
      container.dispose();
    });

    ProviderContainer createContainer() {
      return ProviderContainer(
        overrides: [enterChannelUseCaseProvider.overrideWithValue(mockUseCase)],
      );
    }

    test('초기 로딩 - EnterChannelUseCase 호출 및 결과 반환', () async {
      // Given
      final channel = Channel(id: 1, name: 'General', type: 'TEXT');
      final result = ChannelEntryResult(
        channel: channel,
        permissions: ChannelPermissions(permissions: ['POST_READ']),
        posts: [
          Post(
            id: 1,
            content: 'Test Post',
            author: Author(id: 1, name: 'User'),
            createdAt: DateTime.now(),
          ),
        ],
        readPosition: null,
      );

      when(mockUseCase(channel)).thenAnswer((_) async => result);
      container = createContainer();

      // When
      final state = await container.read(channelEntryProvider(channel).future);

      // Then
      expect(state, result);
      verify(mockUseCase(channel)).called(1);
    });

    test('Family 패턴 - Channel별 독립적 인스턴스', () async {
      // Given
      final channel1 = Channel(id: 1, name: 'Channel 1', type: 'TEXT');
      final channel2 = Channel(id: 2, name: 'Channel 2', type: 'TEXT');

      final result1 = ChannelEntryResult(
        channel: channel1,
        permissions: ChannelPermissions(permissions: ['POST_READ']),
        posts: [],
        readPosition: null,
      );
      final result2 = ChannelEntryResult(
        channel: channel2,
        permissions: ChannelPermissions(permissions: ['POST_WRITE']),
        posts: [],
        readPosition: 5,
      );

      when(mockUseCase(channel1)).thenAnswer((_) async => result1);
      when(mockUseCase(channel2)).thenAnswer((_) async => result2);
      container = createContainer();

      // When
      final state1 = await container.read(
        channelEntryProvider(channel1).future,
      );
      final state2 = await container.read(
        channelEntryProvider(channel2).future,
      );

      // Then
      expect(state1, result1);
      expect(state2, result2);
      expect(state1.readPosition, isNull);
      expect(state2.readPosition, 5);
      verify(mockUseCase(channel1)).called(1);
      verify(mockUseCase(channel2)).called(1);
    });

    test('refresh() - 데이터 재로딩', () async {
      // Given
      final channel = Channel(id: 1, name: 'Test', type: 'TEXT');
      final initialResult = ChannelEntryResult(
        channel: channel,
        permissions: ChannelPermissions(permissions: ['POST_READ']),
        posts: [],
        readPosition: null,
      );
      final refreshedResult = ChannelEntryResult(
        channel: channel,
        permissions: ChannelPermissions(
          permissions: ['POST_READ', 'POST_WRITE'],
        ),
        posts: [
          Post(
            id: 1,
            content: 'New Post',
            author: Author(id: 1, name: 'User'),
            createdAt: DateTime.now(),
          ),
        ],
        readPosition: 1,
      );

      when(mockUseCase(channel)).thenAnswer((_) async => initialResult);
      container = createContainer();

      await container.read(channelEntryProvider(channel).future);

      // When
      when(mockUseCase(channel)).thenAnswer((_) async => refreshedResult);
      await container.read(channelEntryProvider(channel).notifier).refresh();

      // Then
      final state = container.read(channelEntryProvider(channel));
      expect(state.value, refreshedResult);
      expect(state.value!.posts.length, 1);
      verify(mockUseCase(channel)).called(2); // build + refresh
    });

    test('updateReadPosition() - 낙관적 업데이트', () async {
      // Given
      final channel = Channel(id: 1, name: 'Test', type: 'TEXT');
      final initialResult = ChannelEntryResult(
        channel: channel,
        permissions: ChannelPermissions(permissions: ['POST_READ']),
        posts: [],
        readPosition: null,
      );

      when(mockUseCase(channel)).thenAnswer((_) async => initialResult);
      container = createContainer();

      await container.read(channelEntryProvider(channel).future);

      // When
      container
          .read(channelEntryProvider(channel).notifier)
          .updateReadPosition(5);

      // Then
      final state = container.read(channelEntryProvider(channel));
      expect(state.value!.readPosition, 5);
      expect(state.value!.channel, channel);
    });

    test('에러 케이스 - UseCase 실패 시 AsyncError 상태', () async {
      // Given
      final channel = Channel(id: 1, name: 'Test', type: 'TEXT');
      when(mockUseCase(channel)).thenThrow(Exception('채널 진입 실패'));
      container = createContainer();

      // When
      final stateFuture = container.read(channelEntryProvider(channel).future);

      // Then
      await expectLater(stateFuture, throwsA(isA<Exception>()));
    });
  });
}
