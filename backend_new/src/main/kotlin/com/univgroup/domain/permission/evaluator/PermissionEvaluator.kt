package com.univgroup.domain.permission.evaluator

import com.univgroup.domain.permission.ChannelPermission
import com.univgroup.domain.permission.GroupPermission
import com.univgroup.domain.permission.service.AuditLogger
import com.univgroup.domain.permission.service.PermissionCacheManager
import com.univgroup.shared.dto.ErrorCode
import com.univgroup.shared.exception.AccessDeniedException
import org.springframework.stereotype.Component

/**
 * 권한 평가기 구현체
 *
 * 역함수 패턴을 적용하여 권한을 먼저 확인하고, 그 결과에 따라 데이터 접근을 결정한다.
 * 캐싱을 통해 성능을 최적화하고, 감사 로깅을 통해 보안을 강화한다.
 *
 * @see docs/refactor/backend/permission-guard.md
 */
@Component
class PermissionEvaluator(
    private val permissionLoader: PermissionLoader,
    private val cacheManager: PermissionCacheManager,
    private val auditLogger: AuditLogger,
) : IPermissionEvaluator {
    // ========== 그룹 레벨 권한 검증 ==========

    override fun hasGroupPermission(
        userId: Long,
        groupId: Long,
        permission: GroupPermission,
    ): Boolean {
        val permissions = getGroupPermissions(userId, groupId)
        val hasPermission = permissions.contains(permission)

        if (hasPermission) {
            auditLogger.logPermissionGranted(
                userId = userId,
                resourceType = "GROUP",
                resourceId = groupId,
                action = permission.name,
                permissions = listOf(permission.name),
            )
        }

        return hasPermission
    }

    override fun hasAnyGroupPermission(
        userId: Long,
        groupId: Long,
        permissions: Set<GroupPermission>,
    ): Boolean {
        val userPermissions = getGroupPermissions(userId, groupId)
        return permissions.any { userPermissions.contains(it) }
    }

    override fun hasAllGroupPermissions(
        userId: Long,
        groupId: Long,
        permissions: Set<GroupPermission>,
    ): Boolean {
        val userPermissions = getGroupPermissions(userId, groupId)
        return permissions.all { userPermissions.contains(it) }
    }

    override fun getGroupPermissions(
        userId: Long,
        groupId: Long,
    ): Set<GroupPermission> {
        return cacheManager.getOrLoadGroupPermissions(userId, groupId) {
            permissionLoader.loadGroupPermissions(userId, groupId)
        }
    }

    // ========== 채널 레벨 권한 검증 ==========

    override fun hasChannelPermission(
        userId: Long,
        channelId: Long,
        permission: ChannelPermission,
    ): Boolean {
        val permissions = getChannelPermissions(userId, channelId)
        val hasPermission = permissions.contains(permission)

        if (hasPermission) {
            auditLogger.logPermissionGranted(
                userId = userId,
                resourceType = "CHANNEL",
                resourceId = channelId,
                action = permission.name,
                permissions = listOf(permission.name),
            )
        }

        return hasPermission
    }

    override fun getChannelPermissions(
        userId: Long,
        channelId: Long,
    ): Set<ChannelPermission> {
        return cacheManager.getOrLoadChannelPermissions(userId, channelId) {
            permissionLoader.loadChannelPermissions(userId, channelId)
        }
    }

    // ========== 그룹 접근 확인 ==========

    override fun isGroupMember(
        userId: Long,
        groupId: Long,
    ): Boolean {
        val cached = cacheManager.getMembership(userId, groupId)
        if (cached != null) {
            return cached
        }

        val isMember = permissionLoader.isMember(userId, groupId)
        cacheManager.putMembership(userId, groupId, isMember)
        auditLogger.logMembershipCheck(userId, groupId, isMember)

        return isMember
    }

    override fun isGroupOwner(
        userId: Long,
        groupId: Long,
    ): Boolean {
        return permissionLoader.isOwner(userId, groupId)
    }

    // ========== 권한 검증 + 예외 발생 ==========

    override fun requireGroupPermission(
        userId: Long,
        groupId: Long,
        permission: GroupPermission,
    ) {
        if (!hasGroupPermission(userId, groupId, permission)) {
            auditLogger.logPermissionDenied(
                userId = userId,
                resourceType = "GROUP",
                resourceId = groupId,
                action = permission.name,
                reason = "Permission not granted",
            )
            throw AccessDeniedException(
                ErrorCode.PERMISSION_DENIED,
                "권한이 없습니다: ${permission.name}",
            )
        }
    }

    override fun requireChannelPermission(
        userId: Long,
        channelId: Long,
        permission: ChannelPermission,
    ) {
        if (!hasChannelPermission(userId, channelId, permission)) {
            auditLogger.logPermissionDenied(
                userId = userId,
                resourceType = "CHANNEL",
                resourceId = channelId,
                action = permission.name,
                reason = "Permission not granted",
            )
            throw AccessDeniedException(
                ErrorCode.PERMISSION_DENIED,
                "채널 권한이 없습니다: ${permission.name}",
            )
        }
    }

    // ========== 편의 메서드 ==========

    /**
     * 그룹 권한 컨텍스트 생성
     * Controller에서 권한 확인 후 Service로 전달할 때 사용
     */
    fun getGroupPermissionContext(
        userId: Long,
        groupId: Long,
    ): GroupPermissionContext {
        val permissions = getGroupPermissions(userId, groupId)
        return GroupPermissionContext(
            userId = userId,
            groupId = groupId,
            permissions = permissions,
            isOwner = isGroupOwner(userId, groupId),
            isMember = isGroupMember(userId, groupId),
        )
    }

    /**
     * 채널 권한 컨텍스트 생성
     */
    fun getChannelPermissionContext(
        userId: Long,
        channelId: Long,
        groupId: Long,
    ): ChannelPermissionContext {
        val permissions = getChannelPermissions(userId, channelId)
        return ChannelPermissionContext(
            userId = userId,
            channelId = channelId,
            groupId = groupId,
            permissions = permissions,
        )
    }

    // ========== 캐시 관리 ==========

    /**
     * 사용자의 그룹 권한 캐시 무효화
     * 역할 변경, 멤버 추가/제거 시 호출
     */
    fun invalidateUserPermissions(
        userId: Long,
        groupId: Long,
    ) {
        cacheManager.invalidateUser(userId, groupId)
    }

    /**
     * 그룹의 모든 권한 캐시 무효화
     * 역할 정의 변경 시 호출
     */
    fun invalidateGroupPermissions(groupId: Long) {
        cacheManager.invalidateGroup(groupId)
    }

    /**
     * 채널의 권한 캐시 무효화
     * 채널 권한 바인딩 변경 시 호출
     */
    fun invalidateChannelPermissions(channelId: Long) {
        cacheManager.invalidateChannel(channelId)
    }
}
