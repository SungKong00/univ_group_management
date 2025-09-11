package org.castlekong.backend.security

import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.stereotype.Component

@Component("security")
class SecurityExpressionHelper(
    private val groupPermissionEvaluator: GroupPermissionEvaluator,
) {
    fun hasGroupPerm(groupId: Long, permission: String): Boolean {
        val auth = SecurityContextHolder.getContext().authentication
        return groupPermissionEvaluator.hasPermission(auth, groupId, "GROUP", permission)
    }
}

