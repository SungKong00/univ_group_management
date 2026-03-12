package com.univgroup.domain.permission.evaluator

import com.univgroup.domain.permission.ChannelPermission
import com.univgroup.domain.permission.GroupPermission

/**
 * 권한 평가기 인터페이스 (도메인 경계 - Permission 도메인 공개 API)
 *
 * 다른 도메인에서 권한 검증이 필요할 때 이 인터페이스를 통해 접근한다.
 * 역함수 패턴: 데이터 조회 전에 먼저 권한을 확인한다.
 *
 * @see docs/refactor/backend/permission-guard.md
 */
interface IPermissionEvaluator {
    // ========== 그룹 레벨 권한 검증 ==========

    /**
     * 사용자가 특정 그룹에서 특정 권한을 가지고 있는지 확인
     *
     * @param userId 사용자 ID
     * @param groupId 그룹 ID
     * @param permission 확인할 권한
     * @return 권한 보유 여부
     */
    fun hasGroupPermission(
        userId: Long,
        groupId: Long,
        permission: GroupPermission,
    ): Boolean

    /**
     * 사용자가 특정 그룹에서 여러 권한 중 하나라도 가지고 있는지 확인
     *
     * @param userId 사용자 ID
     * @param groupId 그룹 ID
     * @param permissions 확인할 권한들
     * @return 하나라도 보유하면 true
     */
    fun hasAnyGroupPermission(
        userId: Long,
        groupId: Long,
        permissions: Set<GroupPermission>,
    ): Boolean

    /**
     * 사용자가 특정 그룹에서 모든 권한을 가지고 있는지 확인
     *
     * @param userId 사용자 ID
     * @param groupId 그룹 ID
     * @param permissions 확인할 권한들
     * @return 모두 보유하면 true
     */
    fun hasAllGroupPermissions(
        userId: Long,
        groupId: Long,
        permissions: Set<GroupPermission>,
    ): Boolean

    /**
     * 사용자가 특정 그룹에서 가진 모든 권한 조회
     *
     * @param userId 사용자 ID
     * @param groupId 그룹 ID
     * @return 권한 집합 (멤버가 아니면 빈 집합)
     */
    fun getGroupPermissions(
        userId: Long,
        groupId: Long,
    ): Set<GroupPermission>

    // ========== 채널 레벨 권한 검증 ==========

    /**
     * 사용자가 특정 채널에서 특정 권한을 가지고 있는지 확인
     *
     * @param userId 사용자 ID
     * @param channelId 채널 ID
     * @param permission 확인할 권한
     * @return 권한 보유 여부
     */
    fun hasChannelPermission(
        userId: Long,
        channelId: Long,
        permission: ChannelPermission,
    ): Boolean

    /**
     * 사용자가 특정 채널에서 가진 모든 권한 조회
     *
     * @param userId 사용자 ID
     * @param channelId 채널 ID
     * @return 권한 집합
     */
    fun getChannelPermissions(
        userId: Long,
        channelId: Long,
    ): Set<ChannelPermission>

    // ========== 그룹 접근 확인 ==========

    /**
     * 사용자가 특정 그룹의 멤버인지 확인
     *
     * @param userId 사용자 ID
     * @param groupId 그룹 ID
     * @return 멤버 여부
     */
    fun isGroupMember(
        userId: Long,
        groupId: Long,
    ): Boolean

    /**
     * 사용자가 특정 그룹의 소유자(그룹장)인지 확인
     *
     * @param userId 사용자 ID
     * @param groupId 그룹 ID
     * @return 소유자 여부
     */
    fun isGroupOwner(
        userId: Long,
        groupId: Long,
    ): Boolean

    // ========== 권한 검증 + 예외 발생 ==========

    /**
     * 권한 확인 후 없으면 AccessDeniedException 발생
     *
     * @param userId 사용자 ID
     * @param groupId 그룹 ID
     * @param permission 필요한 권한
     * @throws AccessDeniedException 권한이 없을 경우
     */
    fun requireGroupPermission(
        userId: Long,
        groupId: Long,
        permission: GroupPermission,
    )

    /**
     * 채널 권한 확인 후 없으면 AccessDeniedException 발생
     *
     * @param userId 사용자 ID
     * @param channelId 채널 ID
     * @param permission 필요한 권한
     * @throws AccessDeniedException 권한이 없을 경우
     */
    fun requireChannelPermission(
        userId: Long,
        channelId: Long,
        permission: ChannelPermission,
    )
}

/**
 * 권한 검증 결과를 담는 데이터 클래스
 *
 * Controller에서 권한 확인 후 Service로 전달할 때 사용
 */
data class GroupPermissionContext(
    val userId: Long,
    val groupId: Long,
    val permissions: Set<GroupPermission>,
    val isOwner: Boolean,
    val isMember: Boolean,
) {
    fun has(permission: GroupPermission): Boolean = permissions.contains(permission)

    fun hasAny(vararg perms: GroupPermission): Boolean = perms.any { permissions.contains(it) }

    fun hasAll(vararg perms: GroupPermission): Boolean = perms.all { permissions.contains(it) }
}

/**
 * 채널 권한 검증 결과
 */
data class ChannelPermissionContext(
    val userId: Long,
    val channelId: Long,
    val groupId: Long,
    val permissions: Set<ChannelPermission>,
) {
    fun has(permission: ChannelPermission): Boolean = permissions.contains(permission)

    fun canRead(): Boolean = permissions.contains(ChannelPermission.POST_READ)

    fun canWrite(): Boolean = permissions.contains(ChannelPermission.POST_WRITE)
}
