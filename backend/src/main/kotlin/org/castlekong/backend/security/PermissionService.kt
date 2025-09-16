package org.castlekong.backend.security

import com.github.benmanes.caffeine.cache.Caffeine
import org.castlekong.backend.entity.GroupPermission
import org.castlekong.backend.exception.BusinessException
import org.castlekong.backend.exception.ErrorCode
import org.castlekong.backend.repository.GroupMemberPermissionOverrideRepository
import org.castlekong.backend.repository.GroupMemberRepository
import org.castlekong.backend.repository.GroupRepository
import org.springframework.stereotype.Service
import java.time.Duration

@Service
class PermissionService(
    private val groupRepository: GroupRepository,
    private val groupMemberRepository: GroupMemberRepository,
    private val overrideRepository: GroupMemberPermissionOverrideRepository,
) {
    private val cache =
        Caffeine.newBuilder()
            .expireAfterWrite(Duration.ofSeconds(60))
            .maximumSize(10_000)
            .build<String, Set<GroupPermission>>()

    fun getEffective(
        groupId: Long,
        userId: Long,
        systemRolePermissions: (String) -> Set<GroupPermission>,
    ): Set<GroupPermission> {
        val key = "$groupId:$userId"
        return cache.get(key) {
            computeEffective(groupId, userId, systemRolePermissions)
        }
    }

    fun invalidate(
        groupId: Long,
        userId: Long,
    ) {
        cache.invalidate("$groupId:$userId")
    }

    fun invalidateGroup(groupId: Long) {
        val prefix = "$groupId:"
        val keys = cache.asMap().keys.filter { it.startsWith(prefix) }
        cache.invalidateAll(keys)
    }

    private fun computeEffective(
        groupId: Long,
        userId: Long,
        systemRolePermissions: (String) -> Set<GroupPermission>,
    ): Set<GroupPermission> {
        groupRepository.findById(groupId).orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }
        val member =
            groupMemberRepository.findByGroupIdAndUserId(groupId, userId)
                .orElseThrow { BusinessException(ErrorCode.GROUP_MEMBER_NOT_FOUND) }
        val base = if (member.role.isSystemRole) systemRolePermissions(member.role.name) else member.role.permissions
        val override = overrideRepository.findByGroupIdAndUserId(groupId, userId).orElse(null)
        return if (override != null) base.plus(override.allowedPermissions).minus(override.deniedPermissions) else base
    }
}
