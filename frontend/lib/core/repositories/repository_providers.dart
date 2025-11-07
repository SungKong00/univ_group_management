import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'member_repository.dart';
import 'role_repository.dart';
import 'join_request_repository.dart';

/// Repository Provider들
///
/// API 연동 구현체 사용
/// Mock 구현체는 개발/테스트 시에만 사용

final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  // 실제 API 연동 구현체 사용
  return ApiMemberRepository();

  // Mock 데이터가 필요한 경우:
  // return MockMemberRepository();
});

final roleRepositoryProvider = Provider<RoleRepository>((ref) {
  // 실제 API 연동 구현체 사용
  return ApiRoleRepository();

  // Mock 데이터가 필요한 경우:
  // return MockRoleRepository();
});

final joinRequestRepositoryProvider = Provider<JoinRequestRepository>((ref) {
  // 실제 API 연동 구현체 사용
  return ApiJoinRequestRepository();

  // Mock 데이터가 필요한 경우:
  // return MockJoinRequestRepository();
});
