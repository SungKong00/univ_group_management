import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/channel/domain/entities/channel.dart';

/// Channel Entity 테스트
///
/// 검증 항목:
/// 1. Freezed 불변성 (copyWith, ==, hashCode)
/// 2. 필수 필드 테스트 (id, name, type)
/// 3. 선택적 필드 테스트 (description, createdAt)
void main() {
  group('Channel Entity Tests', () {
    test('필수 필드로 Channel 생성', () {
      // Given / When
      final channel = Channel(id: 1, name: '공지사항', type: 'ANNOUNCEMENT');

      // Then
      expect(channel.id, 1);
      expect(channel.name, '공지사항');
      expect(channel.type, 'ANNOUNCEMENT');
      expect(channel.description, isNull);
      expect(channel.createdAt, isNull);
    });

    test('선택적 필드 포함하여 Channel 생성', () {
      // Given
      final now = DateTime.now();

      // When
      final channel = Channel(
        id: 2,
        name: '자유게시판',
        type: 'TEXT',
        description: '자유롭게 소통하는 공간입니다',
        createdAt: now,
      );

      // Then
      expect(channel.id, 2);
      expect(channel.name, '자유게시판');
      expect(channel.type, 'TEXT');
      expect(channel.description, '자유롭게 소통하는 공간입니다');
      expect(channel.createdAt, now);
    });

    test('copyWith - 이름 변경', () {
      // Given
      final original = Channel(id: 3, name: '원래 이름', type: 'TEXT');

      // When
      final updated = original.copyWith(name: '새로운 이름');

      // Then
      expect(updated.id, 3);
      expect(updated.name, '새로운 이름');
      expect(updated.type, 'TEXT');
    });

    test('copyWith - 설명 추가', () {
      // Given
      final original = Channel(id: 4, name: '테스트 채널', type: 'TEXT');

      // When
      final updated = original.copyWith(description: '새 설명');

      // Then
      expect(updated.description, '새 설명');
      expect(updated.name, '테스트 채널');
    });

    test('동등성 비교 - 동일한 필드', () {
      // Given
      final channel1 = Channel(id: 5, name: '채널A', type: 'TEXT');
      final channel2 = Channel(id: 5, name: '채널A', type: 'TEXT');

      // When / Then
      expect(channel1, equals(channel2));
      expect(channel1.hashCode, equals(channel2.hashCode));
    });

    test('동등성 비교 - 다른 ID', () {
      // Given
      final channel1 = Channel(id: 6, name: '채널', type: 'TEXT');
      final channel2 = Channel(id: 7, name: '채널', type: 'TEXT');

      // When / Then
      expect(channel1, isNot(equals(channel2)));
    });
  });
}
