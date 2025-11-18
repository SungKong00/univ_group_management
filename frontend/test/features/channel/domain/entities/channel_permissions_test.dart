import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/channel/domain/entities/channel_permissions.dart';

/// ChannelPermissions Entity 테스트
///
/// 검증 항목:
/// 1. hasPermission() 메서드 테스트
/// 2. canReadPosts, canWritePosts 헬퍼 메서드 테스트
/// 3. canWriteComments, canManageChannel 헬퍼 메서드 테스트
/// 4. 빈 권한 목록 처리
void main() {
  group('ChannelPermissions Entity Tests', () {
    test('hasPermission - 권한이 있는 경우', () {
      // Given
      final permissions = ChannelPermissions(
        permissions: ['POST_READ', 'POST_WRITE'],
      );

      // When / Then
      expect(permissions.hasPermission('POST_READ'), isTrue);
      expect(permissions.hasPermission('POST_WRITE'), isTrue);
    });

    test('hasPermission - 권한이 없는 경우', () {
      // Given
      final permissions = ChannelPermissions(permissions: ['POST_READ']);

      // When / Then
      expect(permissions.hasPermission('POST_WRITE'), isFalse);
      expect(permissions.hasPermission('CHANNEL_MANAGE'), isFalse);
    });

    test('canReadPosts - 읽기 권한 확인', () {
      // Given
      final withRead = ChannelPermissions(permissions: ['POST_READ']);
      final withoutRead = ChannelPermissions(permissions: ['POST_WRITE']);

      // When / Then
      expect(withRead.canReadPosts, isTrue);
      expect(withoutRead.canReadPosts, isFalse);
    });

    test('canWritePosts - 쓰기 권한 확인', () {
      // Given
      final withWrite = ChannelPermissions(permissions: ['POST_WRITE']);
      final withoutWrite = ChannelPermissions(permissions: ['POST_READ']);

      // When / Then
      expect(withWrite.canWritePosts, isTrue);
      expect(withoutWrite.canWritePosts, isFalse);
    });

    test('canWriteComments - 댓글 쓰기 권한 확인', () {
      // Given
      final withComment = ChannelPermissions(permissions: ['COMMENT_WRITE']);
      final withoutComment = ChannelPermissions(permissions: ['POST_READ']);

      // When / Then
      expect(withComment.canWriteComments, isTrue);
      expect(withoutComment.canWriteComments, isFalse);
    });

    test('canManageChannel - 채널 관리 권한 확인', () {
      // Given
      final withManage = ChannelPermissions(permissions: ['CHANNEL_MANAGE']);
      final withoutManage = ChannelPermissions(permissions: ['POST_READ']);

      // When / Then
      expect(withManage.canManageChannel, isTrue);
      expect(withoutManage.canManageChannel, isFalse);
    });

    test('빈 권한 목록 - 모든 권한 없음', () {
      // Given
      final emptyPermissions = ChannelPermissions(permissions: []);

      // When / Then
      expect(emptyPermissions.canReadPosts, isFalse);
      expect(emptyPermissions.canWritePosts, isFalse);
      expect(emptyPermissions.canWriteComments, isFalse);
      expect(emptyPermissions.canManageChannel, isFalse);
    });

    test('모든 권한 보유', () {
      // Given
      final allPermissions = ChannelPermissions(
        permissions: [
          'POST_READ',
          'POST_WRITE',
          'COMMENT_WRITE',
          'CHANNEL_MANAGE',
        ],
      );

      // When / Then
      expect(allPermissions.canReadPosts, isTrue);
      expect(allPermissions.canWritePosts, isTrue);
      expect(allPermissions.canWriteComments, isTrue);
      expect(allPermissions.canManageChannel, isTrue);
    });

    test('동등성 비교 - 동일한 권한', () {
      // Given
      final perm1 = ChannelPermissions(
        permissions: ['POST_READ', 'POST_WRITE'],
      );
      final perm2 = ChannelPermissions(
        permissions: ['POST_READ', 'POST_WRITE'],
      );

      // When / Then
      expect(perm1, equals(perm2));
      expect(perm1.hashCode, equals(perm2.hashCode));
    });
  });
}
