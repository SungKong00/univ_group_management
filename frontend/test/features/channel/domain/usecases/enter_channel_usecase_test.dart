import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/channel/domain/entities/channel.dart';
import 'package:frontend/features/channel/domain/entities/channel_permissions.dart';
import 'package:frontend/features/channel/domain/repositories/channel_repository.dart';
import 'package:frontend/features/channel/domain/repositories/read_position_repository.dart';
import 'package:frontend/features/channel/domain/usecases/calculate_unread_position_usecase.dart';
import 'package:frontend/features/channel/domain/usecases/enter_channel_usecase.dart';
import 'package:frontend/features/post/domain/entities/author.dart';
import 'package:frontend/features/post/domain/entities/pagination.dart';
import 'package:frontend/features/post/domain/entities/post.dart';
import 'package:frontend/features/post/domain/repositories/post_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'enter_channel_usecase_test.mocks.dart';

@GenerateMocks([ChannelRepository, ReadPositionRepository, PostRepository])
void main() {
  group('EnterChannelUseCase Tests', () {
    late EnterChannelUseCase useCase;
    late MockChannelRepository mockChannelRepository;
    late MockReadPositionRepository mockReadPositionRepository;
    late MockPostRepository mockPostRepository;
    late CalculateUnreadPositionUseCase calculateUnreadPositionUseCase;

    setUp(() {
      mockChannelRepository = MockChannelRepository();
      mockReadPositionRepository = MockReadPositionRepository();
      mockPostRepository = MockPostRepository();
      calculateUnreadPositionUseCase = CalculateUnreadPositionUseCase();
      useCase = EnterChannelUseCase(
        mockChannelRepository,
        mockReadPositionRepository,
        mockPostRepository,
        calculateUnreadPositionUseCase,
      );
    });

    test('정상 케이스 - 병렬 로딩 성공', () async {
      // Given
      final channel = Channel(id: 1, name: '테스트 채널', type: 'TEXT');
      final permissions = ChannelPermissions(
        permissions: ['POST_READ', 'POST_WRITE'],
      );
      final readPosition = 5;
      final posts = [
        Post(
          id: 1,
          content: '게시글 1',
          author: Author(id: 1, name: '작성자'),
          createdAt: DateTime.now(),
        ),
        Post(
          id: 2,
          content: '게시글 2',
          author: Author(id: 1, name: '작성자'),
          createdAt: DateTime.now(),
        ),
      ];
      final pagination = Pagination(
        currentPage: 0,
        totalPages: 1,
        totalElements: 2,
        hasMore: false,
      );

      // Mock 설정
      when(
        mockChannelRepository.getMyPermissions(channel.id),
      ).thenAnswer((_) async => permissions);
      when(
        mockReadPositionRepository.getReadPosition(channel.id),
      ).thenAnswer((_) async => readPosition);
      when(
        mockPostRepository.getPosts(channel.id.toString()),
      ).thenAnswer((_) async => (posts, pagination));

      // When
      final result = await useCase(channel);

      // Then
      expect(result.channel, equals(channel));
      expect(result.permissions, equals(permissions));
      expect(result.posts, equals(posts));
      expect(result.readPosition, equals(readPosition));

      // 병렬 호출 검증
      verify(mockChannelRepository.getMyPermissions(channel.id)).called(1);
      verify(mockReadPositionRepository.getReadPosition(channel.id)).called(1);
      verify(mockPostRepository.getPosts(channel.id.toString())).called(1);
    });

    test('readPosition null인 경우', () async {
      // Given
      final channel = Channel(id: 2, name: '채널', type: 'TEXT');
      final permissions = ChannelPermissions(permissions: ['POST_READ']);
      final posts = <Post>[];
      final pagination = Pagination(
        currentPage: 0,
        totalPages: 1,
        totalElements: 0,
        hasMore: false,
      );

      when(
        mockChannelRepository.getMyPermissions(channel.id),
      ).thenAnswer((_) async => permissions);
      when(
        mockReadPositionRepository.getReadPosition(channel.id),
      ).thenAnswer((_) async => null);
      when(
        mockPostRepository.getPosts(channel.id.toString()),
      ).thenAnswer((_) async => (posts, pagination));

      // When
      final result = await useCase(channel);

      // Then
      expect(result.readPosition, isNull);
      expect(result.posts, isEmpty);
    });

    test('에러 케이스 - Repository 호출 실패 시 예외 전파', () async {
      // Given
      final channel = Channel(id: 3, name: '채널', type: 'TEXT');
      final exception = Exception('권한 조회 실패');

      when(
        mockChannelRepository.getMyPermissions(channel.id),
      ).thenThrow(exception);

      // When / Then
      expect(() => useCase(channel), throwsA(isA<Exception>()));
    });

    test('에러 케이스 - ReadPositionRepository 실패', () async {
      // Given
      final channel = Channel(id: 4, name: '채널', type: 'TEXT');
      final permissions = ChannelPermissions(permissions: ['POST_READ']);
      final exception = Exception('읽은 위치 조회 실패');

      when(
        mockChannelRepository.getMyPermissions(channel.id),
      ).thenAnswer((_) async => permissions);
      when(
        mockReadPositionRepository.getReadPosition(channel.id),
      ).thenThrow(exception);

      // When / Then
      expect(() => useCase(channel), throwsA(isA<Exception>()));
    });

    test('에러 케이스 - PostRepository 실패', () async {
      // Given
      final channel = Channel(id: 5, name: '채널', type: 'TEXT');
      final permissions = ChannelPermissions(permissions: ['POST_READ']);
      final exception = Exception('게시글 조회 실패');

      when(
        mockChannelRepository.getMyPermissions(channel.id),
      ).thenAnswer((_) async => permissions);
      when(
        mockReadPositionRepository.getReadPosition(channel.id),
      ).thenAnswer((_) async => null);
      when(
        mockPostRepository.getPosts(channel.id.toString()),
      ).thenThrow(exception);

      // When / Then
      expect(() => useCase(channel), throwsA(isA<Exception>()));
    });
  });
}
