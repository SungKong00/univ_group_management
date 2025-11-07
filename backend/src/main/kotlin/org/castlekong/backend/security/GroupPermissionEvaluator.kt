package org.castlekong.backend.security

import org.castlekong.backend.entity.ChannelPermission
import org.castlekong.backend.entity.GroupPermission
import org.castlekong.backend.repository.ChannelRepository
import org.castlekong.backend.repository.ChannelRoleBindingRepository
import org.castlekong.backend.repository.GroupMemberRepository
import org.castlekong.backend.repository.GroupRecruitmentRepository
import org.castlekong.backend.repository.PostRepository
import org.castlekong.backend.repository.RecruitmentApplicationRepository
import org.castlekong.backend.repository.UserRepository
import org.slf4j.LoggerFactory
import org.springframework.security.access.PermissionEvaluator
import org.springframework.security.core.Authentication
import org.springframework.security.core.authority.SimpleGrantedAuthority
import org.springframework.stereotype.Component
import java.io.Serializable

@Component
class GroupPermissionEvaluator(
    private val userRepository: UserRepository,
    private val groupMemberRepository: GroupMemberRepository,
    private val groupRecruitmentRepository: GroupRecruitmentRepository,
    private val recruitmentApplicationRepository: RecruitmentApplicationRepository,
    private val channelRepository: ChannelRepository,
    private val channelRoleBindingRepository: ChannelRoleBindingRepository,
    private val postRepository: PostRepository,
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

        return when (targetType) {
            "GROUP" -> checkGroupPermission(targetId, user.id, permission)
            "CHANNEL" -> checkChannelPermission(targetId, user.id, permission)
            "POST" -> checkPostPermission(targetId, user.id, permission)
            "RECRUITMENT" -> checkRecruitmentPermission(targetId, user.id, permission)
            "APPLICATION" -> checkApplicationPermission(targetId, user.id, permission)
            else -> false
        }
    }

    private fun checkGroupPermission(
        groupId: Long,
        userId: Long,
        permission: String,
    ): Boolean {
        val effective = permissionService.getEffective(groupId, userId, ::systemRolePermissions)
        return effective.any { it.name == permission }
    }

    private fun checkChannelPermission(
        channelId: Long,
        userId: Long,
        permission: String,
    ): Boolean {
        val channel = channelRepository.findById(channelId).orElse(null) ?: return false
        val member =
            groupMemberRepository.findByGroupIdAndUserId(channel.group.id, userId)
                .orElse(null) ?: return false
        val binding =
            channelRoleBindingRepository
                .findByChannelIdAndGroupRoleId(channelId, member.role.id) ?: return false

        return try {
            val channelPermission = ChannelPermission.valueOf(permission)
            binding.permissions.contains(channelPermission)
        } catch (e: IllegalArgumentException) {
            log.warn("Invalid channel permission: $permission", e)
            false
        }
    }

    private fun checkPostPermission(
        postId: Long,
        userId: Long,
        permission: String,
    ): Boolean {
        // Load post and delegate to channel permission check
        val post = postRepository.findById(postId).orElse(null) ?: return false
        return checkChannelPermission(post.channel.id, userId, permission)
    }

    private fun checkRecruitmentPermission(
        recruitmentId: Long,
        userId: Long,
        permission: String,
    ): Boolean {
        val recruitment = groupRecruitmentRepository.findById(recruitmentId).orElse(null) ?: return false
        return checkGroupPermission(recruitment.group.id, userId, permission)
    }

    private fun checkApplicationPermission(
        applicationId: Long,
        userId: Long,
        permission: String,
    ): Boolean {
        val application = recruitmentApplicationRepository.findById(applicationId).orElse(null) ?: return false
        return when (permission) {
            "VIEW" -> {
                // 지원자 본인이거나 모집 관리 권한이 있는 경우
                application.applicant.id == userId ||
                    checkGroupPermission(application.recruitment.group.id, userId, "RECRUITMENT_MANAGE")
            }

            "RECRUITMENT_MANAGE" -> {
                checkGroupPermission(application.recruitment.group.id, userId, "RECRUITMENT_MANAGE")
            }

            else -> false
        }
    }

    private fun systemRolePermissions(roleName: String): Set<GroupPermission> {
        return when (roleName.uppercase()) {
            "그룹장" -> GroupPermission.entries.toSet()
            // 교수: 거의 모든 권한, 단 그룹장 위임 등 제한적 예외만 적용 (MVP에서는 동일)
            "교수" -> GroupPermission.entries.toSet()
            "멤버" -> emptySet() // 멤버는 기본적으로 워크스페이스 접근 가능, 별도 권한 불필요
            else -> emptySet()
        }
    }

    companion object {
        private val log = LoggerFactory.getLogger(GroupPermissionEvaluator::class.java)
    }
}
