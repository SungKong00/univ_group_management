import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'member_repository.dart';
import 'role_repository.dart';
import 'join_request_repository.dart';

/// Repository Provider들
///
/// MVP: Mock 구현체 제공
/// Phase 2: API 연동 시 실제 구현체로 교체

final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  return MockMemberRepository();
});

final roleRepositoryProvider = Provider<RoleRepository>((ref) {
  return MockRoleRepository();
});

final joinRequestRepositoryProvider = Provider<JoinRequestRepository>((ref) {
  return MockJoinRequestRepository();
});
