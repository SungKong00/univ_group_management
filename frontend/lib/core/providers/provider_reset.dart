import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/calendar_events_provider.dart';
import '../../presentation/providers/calendar_view_provider.dart';
import '../../presentation/providers/focused_date_provider.dart';
import '../../presentation/providers/group_calendar_provider.dart';
import '../../presentation/providers/home_state_provider.dart';
import '../../presentation/providers/my_groups_provider.dart';
import '../../presentation/providers/timetable_provider.dart';
import '../../presentation/providers/workspace_state_provider.dart';
import '../../presentation/pages/group/providers/subgroup_request_provider.dart';
import '../providers/unified_group_provider.dart';
import '../../presentation/pages/member_management/providers/join_request_provider.dart';
import '../../presentation/pages/member_management/providers/member_actions_provider.dart';
import '../../presentation/pages/member_management/providers/role_management_provider.dart';
import '../../presentation/providers/recruitment_providers.dart';
import '../../presentation/providers/recruiting_groups_provider.dart';

typedef LogoutResetCallback = void Function(Ref ref);

/// 중앙 Provider 초기화 시스템
///
/// 이 파일은 로그아웃 시 초기화해야 할 모든 사용자 데이터 관련 Provider를 관리합니다.
///
/// ### 사용 방법
/// 1. 새로운 사용자 데이터 Provider 생성 시 [_providersToInvalidateOnLogout] 리스트에 추가
/// 2. 로그아웃 시 [resetAllUserDataProviders] 함수 호출
///
/// ### 예시
/// ```dart
/// // 새로운 Provider 추가 시
/// final _providersToInvalidateOnLogout = [
///   myGroupsProvider,
///   myNewUserDataProvider,  // ← 여기에 추가
/// ];
/// ```
///
/// ### 주의사항
/// - FutureProvider, Provider 등 일반 Provider만 이 리스트에 추가
/// - StateNotifierProvider는 [resetAllUserDataProviders] 함수 내부에서 별도 처리
/// - 사용자 데이터와 무관한 앱 설정 Provider는 추가하지 않음

/// 로그아웃 시 자동으로 invalidate할 Provider 목록
///
/// 이 리스트에 포함된 Provider는 logout 시 `ref.invalidate` 되어
/// 다음 로그인에서 새 상태를 로드합니다.
///
/// ⚠️ Phase 4-1 변경사항:
/// currentUserProvider 의존성이 추가된 Provider는 자동으로 무효화되므로
/// 이 리스트에서 제거되었습니다:
/// - recruitmentDetailProvider (자동 무효화)
/// - applicationProvider (자동 무효화)
/// - joinRequestListProvider (자동 무효화)
/// - subGroupRequestListProvider (자동 무효화)
///
/// ⚠️ Phase 4-2 변경사항:
/// 추가로 currentUser 의존성이 추가된 Provider:
/// - activeRecruitmentProvider (자동 무효화)
/// - archivedRecruitmentsProvider (자동 무효화)
/// - applicationListProvider (자동 무효화)
/// - filteredGroupMembersProvider (자동 무효화)
/// - allGroupMembersProvider (자동 무효화)
/// - roleListProvider (자동 무효화)
final _providersToInvalidateOnLogout = <ProviderOrFamily>[
  myGroupsProvider,
  homeStateProvider,
  calendarEventsProvider,
  calendarViewProvider,
  focusedDateProvider,
  timetableStateProvider,
  unifiedGroupProvider,
  workspaceStateProvider,
  groupCalendarProvider,
  createRecruitmentProvider,
  updateRecruitmentProvider,
  closeRecruitmentProvider,
  deleteRecruitmentProvider,
  reviewApplicationProvider,
  approveSubGroupRequestProvider,
  rejectSubGroupRequestProvider,
  approveJoinRequestProvider,
  rejectJoinRequestProvider,
  updateMemberRoleProvider,
  removeMemberProvider,
  createRoleProvider,
  updateRoleProvider,
  deleteRoleProvider,
  recruitingGroupsProvider,
];

/// 로그아웃 시 실행할 사용자 정의 초기화 콜백
///
/// Provider invalidate만으로 정리되지 않는 in-memory snapshot 등을 여기서 처리합니다.
final _customLogoutCallbacks = <LogoutResetCallback>[
  (ref) => ref.read(workspaceStateProvider.notifier).forceClearForLogout(),
  (ref) => ref.read(homeStateProvider.notifier).clearSnapshots(),
  (ref) => ref.read(calendarEventsProvider.notifier).clearSnapshots(),
];

/// 모든 사용자 데이터 관련 Provider를 초기화합니다.
///
/// 이 함수는 로그아웃 시 호출되어야 하며, 다음 작업을 수행합니다:
/// 1. [_customLogoutCallbacks]에 등록된 in-memory 정리 실행
/// 2. currentUserProvider 완료 대기 (순환 참조 방지)
/// 3. [_providersToInvalidateOnLogout]에 등록된 모든 Provider의 캐시 invalidate
///
/// ### 사용 예시
/// ```dart
/// Future<void> logout() async {
///   await _authService.logout();
///   await resetAllUserDataProviders(ref);  // ← 비동기로 변경 (await 필수)
///   // ... 나머지 로그아웃 처리
/// }
/// ```
///
/// ### 매개변수
/// - [ref]: Riverpod ProviderRef 객체 (Provider 내부에서 사용 가능)
///
/// ### 순환 참조 방지
/// - currentUserProvider가 AsyncLoading 상태에서 myGroupsProvider를 invalidate하면
///   myGroupsProvider가 ref.read(currentUserProvider.future)를 호출하여 순환 참조 발생
/// - 따라서 invalidate 전에 currentUserProvider 완료를 명시적으로 대기
Future<void> resetAllUserDataProviders(Ref ref) async {
  // 1. In-memory snapshot 및 사용자 정의 정리 로직 먼저 수행
  for (final callback in _customLogoutCallbacks) {
    callback(ref);
  }

  // 2. currentUserProvider 완료 대기는 제거 (자기참조 순환 방지)
  //    - CurrentUserNotifier.logout()에서 이미 state = AsyncData(null) 처리 후 호출됨

  // 3. Provider 일괄 invalidate
  for (final provider in _providersToInvalidateOnLogout) {
    ref.invalidate(provider);
  }

  // 4. keepAlive Provider도 invalidate로 즉시 재평가됨. 별도 refresh 호출 불필요
}
