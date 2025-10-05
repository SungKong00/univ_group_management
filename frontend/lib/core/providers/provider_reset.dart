import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/providers/my_groups_provider.dart';
import '../../presentation/providers/workspace_state_provider.dart';

/// 중앙 Provider 초기화 시스템
///
/// 이 파일은 로그아웃 시 초기화해야 할 모든 사용자 데이터 관련 Provider를 관리합니다.
///
/// ### 사용 방법
/// 1. 새로운 사용자 데이터 Provider 생성 시 [providersToResetOnLogout] 리스트에 추가
/// 2. 로그아웃 시 [resetAllUserDataProviders] 함수 호출
///
/// ### 예시
/// ```dart
/// // 새로운 Provider 추가 시
/// final providersToResetOnLogout = [
///   myGroupsProvider,
///   myNewUserDataProvider,  // ← 여기에 추가
/// ];
/// ```
///
/// ### 주의사항
/// - FutureProvider, Provider 등 일반 Provider만 이 리스트에 추가
/// - StateNotifierProvider는 [resetAllUserDataProviders] 함수 내부에서 별도 처리
/// - 사용자 데이터와 무관한 앱 설정 Provider는 추가하지 않음

/// 로그아웃 시 자동으로 invalidate될 Provider 목록
///
/// 이 리스트에 포함된 모든 Provider는 로그아웃 시 캐시가 초기화되어
/// 다음 로그인 시 새로운 데이터를 가져옵니다.
final providersToResetOnLogout = <ProviderOrFamily>[
  myGroupsProvider,
  // 향후 추가될 사용자 데이터 Provider들을 여기에 등록하세요
  // 예: myNotificationsProvider,
  //     myProfileProvider,
];

/// 모든 사용자 데이터 관련 Provider를 초기화합니다.
///
/// 이 함수는 로그아웃 시 호출되어야 하며, 다음 작업을 수행합니다:
/// 1. [providersToResetOnLogout]에 등록된 모든 Provider의 캐시 invalidate
/// 2. StateNotifierProvider들의 상태 초기화
///
/// ### 사용 예시
/// ```dart
/// Future<void> logout() async {
///   await _authService.logout();
///   resetAllUserDataProviders(ref);  // ← 로그아웃 로직에서 호출
///   // ... 나머지 로그아웃 처리
/// }
/// ```
///
/// ### 매개변수
/// - [ref]: Riverpod ProviderRef 객체 (Provider 내부에서 사용 가능)
void resetAllUserDataProviders(Ref ref) {
  // FutureProvider 및 일반 Provider 일괄 초기화
  for (final provider in providersToResetOnLogout) {
    ref.invalidate(provider);
  }

  // StateNotifierProvider는 별도 처리
  // exitWorkspace()는 workspaceStateProvider의 상태를 초기값으로 리셋
  ref.read(workspaceStateProvider.notifier).exitWorkspace();
}
