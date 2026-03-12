import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/channel/domain/entities/unread_position_result.dart';

/// UnreadPositionResult Entity 테스트
///
/// 검증 항목:
/// 1. Freezed 불변성
/// 2. 필드 검증
/// 3. 기본값 확인 (@Default)
void main() {
  group('UnreadPositionResult Entity Tests', () {
    test('모든 필드로 UnreadPositionResult 생성', () {
      // Given / When
      final result = UnreadPositionResult(
        unreadIndex: 5,
        totalUnread: 10,
        hasUnread: true,
      );

      // Then
      expect(result.unreadIndex, equals(5));
      expect(result.totalUnread, equals(10));
      expect(result.hasUnread, isTrue);
    });

    test('기본값 확인 - totalUnread 0, hasUnread false', () {
      // Given / When
      final result = UnreadPositionResult(unreadIndex: null);

      // Then
      expect(result.unreadIndex, isNull);
      expect(result.totalUnread, equals(0)); // 기본값
      expect(result.hasUnread, isFalse); // 기본값
    });

    test('읽지 않은 게시글이 있는 경우', () {
      // Given / When
      final result = UnreadPositionResult(
        unreadIndex: 0,
        totalUnread: 15,
        hasUnread: true,
      );

      // Then
      expect(result.unreadIndex, equals(0));
      expect(result.totalUnread, equals(15));
      expect(result.hasUnread, isTrue);
    });

    test('모든 게시글을 읽은 경우', () {
      // Given / When
      final result = UnreadPositionResult(
        unreadIndex: null,
        totalUnread: 0,
        hasUnread: false,
      );

      // Then
      expect(result.unreadIndex, isNull);
      expect(result.totalUnread, equals(0));
      expect(result.hasUnread, isFalse);
    });

    test('동등성 비교', () {
      // Given
      final result1 = UnreadPositionResult(
        unreadIndex: 3,
        totalUnread: 7,
        hasUnread: true,
      );
      final result2 = UnreadPositionResult(
        unreadIndex: 3,
        totalUnread: 7,
        hasUnread: true,
      );

      // When / Then
      expect(result1, equals(result2));
      expect(result1.hashCode, equals(result2.hashCode));
    });
  });
}
