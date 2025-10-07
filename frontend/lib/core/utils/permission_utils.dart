/// 권한 관련 유틸리티 함수 모음
///
/// 이 파일은 그룹 및 채널 권한 체크를 위한 헬퍼 함수들을 제공합니다.
class PermissionUtils {
  /// 그룹 관리 권한 상수 목록
  ///
  /// ⚠️ 새로운 그룹 관리 권한이 추가되면 이 목록에 반드시 추가해야 합니다.
  /// 자세한 내용은 docs/maintenance/group-management-permissions.md 참조
  static const List<String> groupManagementPermissions = [
    'GROUP_MANAGE',      // 그룹 정보 수정, 그룹 삭제, 소유권 이전 등
    'MEMBER_MANAGE',     // 멤버 역할 변경, 강제 탈퇴, 가입 신청 승인 등
    'CHANNEL_MANAGE',    // 채널 생성, 삭제, 설정 수정 등
    'RECRUITMENT_MANAGE', // 모집 공고 작성, 지원서 심사 등
  ];

  /// 사용자가 그룹 관리 권한 중 하나라도 보유하고 있는지 확인
  ///
  /// [permissions] 사용자의 권한 문자열 리스트
  ///
  /// Returns: 그룹 관리 권한 중 하나라도 있으면 true, 없으면 false
  ///
  /// Example:
  /// ```dart
  /// final userPermissions = ['CHANNEL_MANAGE', 'POST_WRITE'];
  /// final hasAccess = PermissionUtils.hasAnyGroupManagementPermission(userPermissions);
  /// // hasAccess == true (CHANNEL_MANAGE가 있으므로)
  /// ```
  static bool hasAnyGroupManagementPermission(List<String> permissions) {
    return permissions.any(
      (permission) => groupManagementPermissions.contains(permission),
    );
  }

  /// 특정 권한을 보유하고 있는지 확인
  ///
  /// [permissions] 사용자의 권한 문자열 리스트
  /// [requiredPermission] 확인하려는 권한 문자열
  ///
  /// Returns: 해당 권한이 있으면 true, 없으면 false
  static bool hasPermission(List<String> permissions, String requiredPermission) {
    return permissions.contains(requiredPermission);
  }

  /// 여러 권한 중 하나라도 보유하고 있는지 확인
  ///
  /// [permissions] 사용자의 권한 문자열 리스트
  /// [requiredPermissions] 확인하려는 권한 문자열 리스트
  ///
  /// Returns: requiredPermissions 중 하나라도 있으면 true, 없으면 false
  static bool hasAnyPermission(
    List<String> permissions,
    List<String> requiredPermissions,
  ) {
    return permissions.any((p) => requiredPermissions.contains(p));
  }

  /// 모든 권한을 보유하고 있는지 확인
  ///
  /// [permissions] 사용자의 권한 문자열 리스트
  /// [requiredPermissions] 확인하려는 권한 문자열 리스트
  ///
  /// Returns: requiredPermissions를 모두 가지고 있으면 true, 하나라도 없으면 false
  static bool hasAllPermissions(
    List<String> permissions,
    List<String> requiredPermissions,
  ) {
    return requiredPermissions.every((p) => permissions.contains(p));
  }
}
