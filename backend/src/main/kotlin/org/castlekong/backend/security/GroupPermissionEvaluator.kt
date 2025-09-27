package org.castlekong.backend.security

import org.castlekong.backend.entity.GroupPermission
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

        val effective = permissionService.getEffective(targetId, user.id, ::systemRolePermissions)
        return effective.any { it.name == permission }
    }

    private fun systemRolePermissions(roleName: String): Set<GroupPermission> {
        return when (roleName.uppercase()) {
            "OWNER" -> GroupPermission.entries.toSet()
            // ADVISOR: 거의 모든 권한, 단 그룹장 위임 등 제한적 예외만 적용 (MVP에서는 동일)
            "ADVISOR" -> GroupPermission.entries.toSet()
            "MEMBER" -> emptySet() // 멤버는 기본적으로 워크스페이스 접근 가능, 별도 권한 불필요
            else -> emptySet()
        }
    }
}
