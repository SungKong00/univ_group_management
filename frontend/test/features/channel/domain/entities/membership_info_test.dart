import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/channel/domain/entities/membership_info.dart';

/// MembershipInfo Entity 테스트
///
/// 검증 항목:
/// 1. 역할 헬퍼 메서드 (isOwner, isAdmin, isMember)
/// 2. 권한 헬퍼 메서드 (canManageMembers, canManageChannels)
/// 3. hasPermission() 메서드 테스트
void main() {
  group('MembershipInfo Entity Tests', () {
    test('isOwner - 그룹장 역할 확인', () {
      // Given
      final owner = MembershipInfo(groupId: 1, role: 'OWNER', permissions: []);
      final admin = MembershipInfo(groupId: 1, role: 'ADMIN', permissions: []);

      // When / Then
      expect(owner.isOwner, isTrue);
      expect(admin.isOwner, isFalse);
    });

    test('isAdmin - 관리자 역할 확인', () {
      // Given
      final admin = MembershipInfo(groupId: 1, role: 'ADMIN', permissions: []);
      final member = MembershipInfo(
        groupId: 1,
        role: 'MEMBER',
        permissions: [],
      );

      // When / Then
      expect(admin.isAdmin, isTrue);
      expect(member.isAdmin, isFalse);
    });

    test('isMember - 일반 멤버 역할 확인', () {
      // Given
      final member = MembershipInfo(
        groupId: 1,
        role: 'MEMBER',
        permissions: [],
      );
      final owner = MembershipInfo(groupId: 1, role: 'OWNER', permissions: []);

      // When / Then
      expect(member.isMember, isTrue);
      expect(owner.isMember, isFalse);
    });

    test('hasPermission - 권한 확인', () {
      // Given
      final membershipWithPerm = MembershipInfo(
        groupId: 1,
        role: 'ADMIN',
        permissions: ['MEMBER_MANAGE', 'CHANNEL_MANAGE'],
      );

      // When / Then
      expect(membershipWithPerm.hasPermission('MEMBER_MANAGE'), isTrue);
      expect(membershipWithPerm.hasPermission('CHANNEL_MANAGE'), isTrue);
      expect(membershipWithPerm.hasPermission('GROUP_DELETE'), isFalse);
    });

    test('canManageMembers - 멤버 관리 권한', () {
      // Given
      final withManage = MembershipInfo(
        groupId: 1,
        role: 'ADMIN',
        permissions: ['MEMBER_MANAGE'],
      );
      final withoutManage = MembershipInfo(
        groupId: 1,
        role: 'MEMBER',
        permissions: [],
      );

      // When / Then
      expect(withManage.canManageMembers, isTrue);
      expect(withoutManage.canManageMembers, isFalse);
    });

    test('canManageChannels - 채널 관리 권한', () {
      // Given
      final withManage = MembershipInfo(
        groupId: 1,
        role: 'ADMIN',
        permissions: ['CHANNEL_MANAGE'],
      );
      final withoutManage = MembershipInfo(
        groupId: 1,
        role: 'MEMBER',
        permissions: [],
      );

      // When / Then
      expect(withManage.canManageChannels, isTrue);
      expect(withoutManage.canManageChannels, isFalse);
    });

    test('빈 권한 목록 - 모든 권한 없음', () {
      // Given
      final emptyPermissions = MembershipInfo(
        groupId: 1,
        role: 'MEMBER',
        permissions: [],
      );

      // When / Then
      expect(emptyPermissions.canManageMembers, isFalse);
      expect(emptyPermissions.canManageChannels, isFalse);
    });

    test('동등성 비교 - 동일한 정보', () {
      // Given
      final info1 = MembershipInfo(
        groupId: 1,
        role: 'ADMIN',
        permissions: ['MEMBER_MANAGE'],
      );
      final info2 = MembershipInfo(
        groupId: 1,
        role: 'ADMIN',
        permissions: ['MEMBER_MANAGE'],
      );

      // When / Then
      expect(info1, equals(info2));
      expect(info1.hashCode, equals(info2.hashCode));
    });

    test('동등성 비교 - 다른 그룹 ID', () {
      // Given
      final info1 = MembershipInfo(
        groupId: 1,
        role: 'ADMIN',
        permissions: ['MEMBER_MANAGE'],
      );
      final info2 = MembershipInfo(
        groupId: 2,
        role: 'ADMIN',
        permissions: ['MEMBER_MANAGE'],
      );

      // When / Then
      expect(info1, isNot(equals(info2)));
    });
  });
}
