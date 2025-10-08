import '../models/member_models.dart';

/// 가입 신청 관리 Repository
///
/// MVP: Mock 데이터 제공
/// Phase 2: API 연동 시 GroupService와 통합
abstract class JoinRequestRepository {
  Future<List<JoinRequest>> getPendingRequests(int groupId);
  Future<void> approveRequest(int groupId, int requestId, String roleId);
  Future<void> rejectRequest(int groupId, int requestId);
}

/// Mock 구현체
class MockJoinRequestRepository implements JoinRequestRepository {
  // Mock 데이터 저장소
  final Map<int, List<JoinRequest>> _requestsByGroup = {
    1: [
      JoinRequest(
        id: 1,
        userId: 'user010',
        userName: '강민준',
        email: 'kang@example.com',
        profileImageUrl: null,
        message: '컴퓨터공학과 학생입니다. 알고리즘 스터디에 참여하고 싶습니다.',
        requestedAt: DateTime(2024, 10, 1),
        status: JoinRequestStatus.pending,
      ),
      JoinRequest(
        id: 2,
        userId: 'user011',
        userName: '서연우',
        email: 'seo@example.com',
        profileImageUrl: null,
        message: '프로젝트 경험을 쌓고 싶어 지원합니다.',
        requestedAt: DateTime(2024, 10, 3),
        status: JoinRequestStatus.pending,
      ),
      JoinRequest(
        id: 3,
        userId: 'user012',
        userName: '윤지호',
        email: 'yoon@example.com',
        profileImageUrl: null,
        message: '같은 학과 학생으로서 함께 성장하고 싶습니다.',
        requestedAt: DateTime(2024, 10, 5),
        status: JoinRequestStatus.pending,
      ),
    ],
  };

  @override
  Future<List<JoinRequest>> getPendingRequests(int groupId) async {
    await Future.delayed(const Duration(milliseconds: 250));

    final requests = _requestsByGroup[groupId] ?? [];
    return requests.where((r) => r.status == JoinRequestStatus.pending).toList();
  }

  @override
  Future<void> approveRequest(int groupId, int requestId, String roleId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final requests = _requestsByGroup[groupId];
    if (requests == null) {
      throw Exception('Group not found');
    }

    final requestIndex = requests.indexWhere((r) => r.id == requestId);
    if (requestIndex == -1) {
      throw Exception('Request not found');
    }

    // 상태를 승인으로 변경 (실제로는 멤버 목록에 추가되어야 함)
    requests.removeAt(requestIndex);
  }

  @override
  Future<void> rejectRequest(int groupId, int requestId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final requests = _requestsByGroup[groupId];
    if (requests == null) {
      throw Exception('Group not found');
    }

    final requestIndex = requests.indexWhere((r) => r.id == requestId);
    if (requestIndex == -1) {
      throw Exception('Request not found');
    }

    // 요청 제거
    requests.removeAt(requestIndex);
  }
}
