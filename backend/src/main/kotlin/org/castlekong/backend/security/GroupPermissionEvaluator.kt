package org.castlekong.backend.security

import org.castlekong.backend.entity.GroupPermission
import org.castlekong.backend.repository.GroupMemberPermissionOverrideRepository
import org.castlekong.backend.repository.GroupMemberRepository
import org.castlekong.backend.repository.UserRepository
import org.springframework.security.access.PermissionEvaluator
import org.springframework.security.core.Authentication
import org.springframework.security.core.authority.SimpleGrantedAuthority
import org.springframework.stereotype.Component
import java.io.Serializable

@Component
class GroupPermissionEvaluator(
    private val userRepository: UserRepository,
    private val groupMemberRepository: GroupMemberRepository,
    private val overrideRepository: GroupMemberPermissionOverrideRepository,
    private val permissionService: PermissionService,
) : PermissionEvaluator {
    override fun hasPermission(
        authentication: Authentication?,
        targetDomainObject: Any?,
        permission: Any?,
    ): Boolean {
        // Not used in our design; use the (Serializable targetId, String targetType, permission) variant
        return false
    }

    override fun hasPermission(
        authentication: Authentication?,
        targetId: Serializable?,
        targetType: String?,
        permission: Any?,
    ): Boolean {
        if (authentication == null || targetId !is Long || permission !is String) return false

        // Global ADMIN short-circuit
        if (authentication.authorities.any { it == SimpleGrantedAuthority("ROLE_ADMIN") }) return true

        val email = authentication.name ?: return false
        val user = userRepository.findByEmail(email).orElse(null) ?: return false

        // Currently only GROUP targetType is supported
        if (targetType != null && targetType != "GROUP") return false

        val member = groupMemberRepository.findByGroupIdAndUserId(targetId, user.id).orElse(null) ?: return false

        val effective = permissionService.getEffective(targetId, user.id, ::systemRolePermissions)
        return effective.any { it.name == permission }
    }

    private fun systemRolePermissions(roleName: String): Set<GroupPermission> {
        return when (roleName.uppercase()) {
            "OWNER" -> GroupPermission.entries.toSet()
            // ADVISOR: Full moderation and channel manage, but no group/role/member/recruitment management
            "ADVISOR" ->
                GroupPermission.entries
                    .toSet()
                    .minus(
                        setOf(
                            GroupPermission.GROUP_MANAGE,
                            GroupPermission.ROLE_MANAGE,
                            GroupPermission.MEMBER_APPROVE,
                            GroupPermission.MEMBER_KICK,
                            GroupPermission.RECRUITMENT_CREATE,
                            GroupPermission.RECRUITMENT_UPDATE,
                            GroupPermission.RECRUITMENT_DELETE,
                        ),
                    )
            "MEMBER" ->
                setOf(
                    GroupPermission.CHANNEL_READ,
                    GroupPermission.POST_READ,
                    GroupPermission.POST_CREATE,
                    GroupPermission.COMMENT_READ,
                    GroupPermission.COMMENT_CREATE,
                    GroupPermission.POST_UPDATE_OWN,
                    GroupPermission.POST_DELETE_OWN,
                )
            else -> emptySet()
        }
    }
}
