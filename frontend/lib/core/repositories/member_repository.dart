import '../models/member_models.dart';

/// 멤버 관리 Repository
///
/// MVP: Mock 데이터 제공
/// Phase 2: API 연동 시 GroupService와 통합
abstract class MemberRepository {
  Future<List<GroupMember>> getGroupMembers(int groupId);
  Future<GroupMember> updateMemberRole(int groupId, int memberId, String roleId);
  Future<void> removeMember(int groupId, int memberId);
}

/// Mock 구현체
class MockMemberRepository implements MemberRepository {
  // Mock 데이터 저장소
  final Map<int, List<GroupMember>> _membersByGroup = {
    1: [
      GroupMember(
        id: 1,
        userId: 'user001',
        userName: '김철수',
        email: 'kim@example.com',
        profileImageUrl: null,
        roleName: 'Owner',
        roleId: 'owner',
        joinedAt: DateTime(2024, 1, 15),
      ),
      GroupMember(
        id: 2,
        userId: 'user002',
        userName: '이영희',
        email: 'lee@example.com',
        profileImageUrl: null,
        roleName: 'Advisor',
        roleId: 'advisor',
        joinedAt: DateTime(2024, 2, 20),
      ),
      GroupMember(
        id: 3,
        userId: 'user003',
        userName: '박민수',
        email: 'park@example.com',
        profileImageUrl: null,
        roleName: 'Member',
        roleId: 'member',
        joinedAt: DateTime(2024, 3, 10),
      ),
      GroupMember(
        id: 4,
        userId: 'user004',
        userName: '최지혜',
        email: 'choi@example.com',
        profileImageUrl: null,
        roleName: 'Member',
        roleId: 'member',
        joinedAt: DateTime(2024, 3, 15),
      ),
      GroupMember(
        id: 5,
        userId: 'user005',
        userName: '정우성',
        email: 'jung@example.com',
        profileImageUrl: null,
        roleName: 'Member',
        roleId: 'member',
        joinedAt: DateTime(2024, 4, 1),
      ),
    ],
  };

  @override
  Future<List<GroupMember>> getGroupMembers(int groupId) async {
    await Future.delayed(const Duration(milliseconds: 300)); // 네트워크 지연 시뮬레이션
    return _membersByGroup[groupId] ?? [];
  }

  @override
  Future<GroupMember> updateMemberRole(
    int groupId,
    int memberId,
    String roleId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final members = _membersByGroup[groupId];
    if (members == null) {
      throw Exception('Group not found');
    }

    final memberIndex = members.indexWhere((m) => m.id == memberId);
    if (memberIndex == -1) {
      throw Exception('Member not found');
    }

    // 역할 이름 매핑 (간단한 구현)
    final roleNameMap = {
      'owner': 'Owner',
      'advisor': 'Advisor',
      'member': 'Member',
    };

    final updatedMember = members[memberIndex].copyWith(
      roleId: roleId,
      roleName: roleNameMap[roleId] ?? roleId,
    );

    _membersByGroup[groupId]![memberIndex] = updatedMember;
    return updatedMember;
  }

  @override
  Future<void> removeMember(int groupId, int memberId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final members = _membersByGroup[groupId];
    if (members == null) {
      throw Exception('Group not found');
    }

    _membersByGroup[groupId] = members.where((m) => m.id != memberId).toList();
  }
}
