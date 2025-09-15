package org.castlekong.backend.security

import org.castlekong.backend.repository.GroupRepository
import org.castlekong.backend.repository.UserRepository
import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.stereotype.Component

@Component("security")
class SecurityExpressionHelper(
    private val groupPermissionEvaluator: GroupPermissionEvaluator,
    private val groupRepository: GroupRepository,
    private val userRepository: UserRepository,
) {
    fun hasGroupPerm(groupId: Long, permission: String): Boolean {
        val auth = SecurityContextHolder.getContext().authentication
        return groupPermissionEvaluator.hasPermission(auth, groupId, "GROUP", permission)
    }

    fun isOwner(groupId: Long): Boolean {
        val auth = SecurityContextHolder.getContext().authentication
        val email = auth?.name ?: return false
        val user = userRepository.findByEmail(email).orElse(null) ?: return false
        val group = groupRepository.findById(groupId).orElse(null) ?: return false
        return group.owner.id == user.id
    }
}
