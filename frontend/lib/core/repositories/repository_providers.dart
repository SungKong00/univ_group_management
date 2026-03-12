import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_storage.dart';
import '../network/dio_client.dart';
import 'auth_repository.dart';
import 'member_repository.dart';
import 'role_repository.dart';
import 'join_request_repository.dart';

/// Repository Provider들
///
/// API 연동 구현체 사용
/// Mock 구현체는 개발/테스트 시에만 사용

/// LocalStorage Provider
final localStorageProvider = Provider<LocalStorage>((ref) {
  return LocalStorage.instance;
});

/// DioClient Provider
final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient();
});

/// AuthRepository Provider
///
/// 인증 관련 비즈니스 로직을 담당합니다.
/// - 유저 정보 저장 경로를 Repository로 단일화
/// - 3-Layer Architecture 준수
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return ApiAuthRepository(
    localStorage: ref.watch(localStorageProvider),
    dioClient: ref.watch(dioClientProvider),
  );
});

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
