import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/channel/domain/entities/channel.dart';
import 'package:frontend/features/channel/domain/entities/channel_entry_result.dart';
import 'package:frontend/features/channel/domain/entities/channel_permissions.dart';
import 'package:frontend/features/post/domain/entities/author.dart';
import 'package:frontend/features/post/domain/entities/post.dart';

/// ChannelEntryResult Entity 테스트
///
/// 검증 항목:
/// 1. Freezed 불변성
/// 2. 필드 검증
void main() {
  group('ChannelEntryResult Entity Tests', () {
    test('모든 필드로 ChannelEntryResult 생성', () {
      // Given
      final channel = Channel(id: 1, name: '테스트 채널', type: 'TEXT');
      final permissions = ChannelPermissions(
        permissions: ['POST_READ', 'POST_WRITE'],
      );
      final posts = [
        Post(
          id: 1,
          content: '첫 게시글',
          author: Author(id: 1, name: '작성자'),
          createdAt: DateTime.now(),
        ),
      ];
      final readPosition = 1;

      // When
      final result = ChannelEntryResult(
        channel: channel,
        permissions: permissions,
        posts: posts,
        readPosition: readPosition,
      );

      // Then
      expect(result.channel, equals(channel));
      expect(result.permissions, equals(permissions));
      expect(result.posts, equals(posts));
      expect(result.readPosition, equals(1));
    });

    test('readPosition null인 경우', () {
      // Given
      final channel = Channel(id: 2, name: '채널', type: 'TEXT');
      final permissions = ChannelPermissions(permissions: ['POST_READ']);
      final posts = <Post>[];

      // When
      final result = ChannelEntryResult(
        channel: channel,
        permissions: permissions,
        posts: posts,
        readPosition: null,
      );

      // Then
      expect(result.readPosition, isNull);
    });

    test('동등성 비교', () {
      // Given
      final channel = Channel(id: 3, name: '채널', type: 'TEXT');
      final permissions = ChannelPermissions(permissions: ['POST_READ']);
      final posts = <Post>[];

      final result1 = ChannelEntryResult(
        channel: channel,
        permissions: permissions,
        posts: posts,
        readPosition: null,
      );
      final result2 = ChannelEntryResult(
        channel: channel,
        permissions: permissions,
        posts: posts,
        readPosition: null,
      );

      // When / Then
      expect(result1, equals(result2));
      expect(result1.hashCode, equals(result2.hashCode));
    });
  });
}
