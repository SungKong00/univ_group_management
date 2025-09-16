package org.castlekong.backend.service

import org.castlekong.backend.dto.*
import org.castlekong.backend.entity.*
import org.castlekong.backend.event.*
import org.castlekong.backend.repository.*
import org.springframework.context.ApplicationEventPublisher
import org.springframework.data.repository.findByIdOrNull
import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDateTime

/**
 * 채널 권한 관리 서비스
 * CRUD 작업과 비즈니스 로직 처리
 */
@Service
@Transactional
class ChannelPermissionManagementService(
    private val channelRepository: ChannelRepository,
    private val groupRoleRepository: GroupRoleRepository,
    private val groupMemberRepository: GroupMemberRepository,
    private val permissionTemplateRepository: ChannelPermissionTemplateRepository,
    private val channelRoleBindingRepository: ChannelRoleBindingRepository,
    private val channelMemberOverrideRepository: ChannelMemberOverrideRepository,
    private val userRepository: UserRepository,
    private val permissionService: ChannelPermissionService,
    private val eventPublisher: ApplicationEventPublisher
) {

    // === 채널 역할 바인딩 관리 ===

    @Transactional(readOnly = true)
    fun getChannelRoleBindings(channelId: Long): List<ChannelRoleBindingResponse> {
        val bindings = channelRoleBindingRepository.findByChannelId(channelId)
        return bindings.map { binding ->
            ChannelRoleBindingResponse(
                id = binding.id,
                channelId = binding.channel.id,
                groupRoleId = binding.groupRole.id,
                groupRoleName = binding.groupRole.name,
                templateId = binding.template?.id,
                templateName = binding.template?.name,
                allowPermissions = ChannelPermission.fromMask(binding.allowPermissionsMask),
                denyPermissions = ChannelPermission.fromMask(binding.denyPermissionsMask),
                effectivePermissions = binding.getEffectivePermissions()
            )
        }
    }

    fun createChannelRoleBinding(channelId: Long, request: CreateChannelRoleBindingRequest): ChannelRoleBindingResponse {
        val channel = channelRepository.findByIdOrNull(channelId)
            ?: throw IllegalArgumentException("Channel not found: $channelId")

        val groupRole = groupRoleRepository.findByIdOrNull(request.groupRoleId)
            ?: throw IllegalArgumentException("Group role not found: ${request.groupRoleId}")

        val template = request.templateId?.let { templateId ->
            permissionTemplateRepository.findByIdOrNull(templateId)
                ?: throw IllegalArgumentException("Permission template not found: $templateId")
        }

        // 권한 충돌 검증
        val allowMask = ChannelPermission.toMask(request.allowPermissions)
        val denyMask = ChannelPermission.toMask(request.denyPermissions)
        permissionService.validateNoConflict(allowMask, denyMask)
        permissionService.validateInheritanceConsistency(allowMask, denyMask)

        // 중복 바인딩 확인
        val existingBinding = channelRoleBindingRepository.findByChannelIdAndGroupRoleId(channelId, request.groupRoleId)
        if (existingBinding != null) {
            throw IllegalArgumentException("Role binding already exists for role ${request.groupRoleId} in channel $channelId")
        }

        val binding = ChannelRoleBinding(
            channel = channel,
            groupRole = groupRole,
            template = template,
            allowPermissionsMask = allowMask,
            denyPermissionsMask = denyMask
        )

        val savedBinding = channelRoleBindingRepository.save(binding)

        // 이벤트 발행
        eventPublisher.publishEvent(
            RoleBindingChangedEvent(
                source = this,
                channelId = channelId,
                groupRoleId = request.groupRoleId,
                action = RoleBindingChangedEvent.BindingAction.CREATED
            )
        )

        return ChannelRoleBindingResponse(
            id = savedBinding.id,
            channelId = savedBinding.channel.id,
            groupRoleId = savedBinding.groupRole.id,
            groupRoleName = savedBinding.groupRole.name,
            templateId = savedBinding.template?.id,
            templateName = savedBinding.template?.name,
            allowPermissions = ChannelPermission.fromMask(savedBinding.allowPermissionsMask),
            denyPermissions = ChannelPermission.fromMask(savedBinding.denyPermissionsMask),
            effectivePermissions = savedBinding.getEffectivePermissions()
        )
    }

    fun updateChannelRoleBinding(bindingId: Long, request: UpdateChannelRoleBindingRequest): ChannelRoleBindingResponse {
        val binding = channelRoleBindingRepository.findByIdOrNull(bindingId)
            ?: throw IllegalArgumentException("Channel role binding not found: $bindingId")

        // 새로운 템플릿 결정
        val newTemplate = if (request.templateId != null) {
            if (request.templateId == 0L) null else {
                permissionTemplateRepository.findByIdOrNull(request.templateId)
                    ?: throw IllegalArgumentException("Permission template not found: ${request.templateId}")
            }
        } else binding.template

        // 새로운 권한 마스크 결정
        val newAllowMask = request.allowPermissions?.let { ChannelPermission.toMask(it) } ?: binding.allowPermissionsMask
        val newDenyMask = request.denyPermissions?.let { ChannelPermission.toMask(it) } ?: binding.denyPermissionsMask

        // 권한 충돌 검증
        permissionService.validateNoConflict(newAllowMask, newDenyMask)
        permissionService.validateInheritanceConsistency(newAllowMask, newDenyMask)

        // 새로운 바인딩 생성 (copy 사용)
        val updatedBinding = binding.copy(
            template = newTemplate,
            allowPermissionsMask = newAllowMask,
            denyPermissionsMask = newDenyMask,
            updatedAt = LocalDateTime.now()
        )

        val savedBinding = channelRoleBindingRepository.save(updatedBinding)

        // 이벤트 발행
        eventPublisher.publishEvent(
            RoleBindingChangedEvent(
                source = this,
                channelId = savedBinding.channel.id,
                groupRoleId = savedBinding.groupRole.id,
                action = RoleBindingChangedEvent.BindingAction.UPDATED
            )
        )

        return ChannelRoleBindingResponse(
            id = savedBinding.id,
            channelId = savedBinding.channel.id,
            groupRoleId = savedBinding.groupRole.id,
            groupRoleName = savedBinding.groupRole.name,
            templateId = savedBinding.template?.id,
            templateName = savedBinding.template?.name,
            allowPermissions = ChannelPermission.fromMask(savedBinding.allowPermissionsMask),
            denyPermissions = ChannelPermission.fromMask(savedBinding.denyPermissionsMask),
            effectivePermissions = savedBinding.getEffectivePermissions()
        )
    }

    fun deleteChannelRoleBinding(bindingId: Long) {
        val binding = channelRoleBindingRepository.findByIdOrNull(bindingId)
            ?: throw IllegalArgumentException("Channel role binding not found: $bindingId")

        val channelId = binding.channel.id
        val groupRoleId = binding.groupRole.id

        channelRoleBindingRepository.delete(binding)

        // 이벤트 발행
        eventPublisher.publishEvent(
            RoleBindingChangedEvent(
                source = this,
                channelId = channelId,
                groupRoleId = groupRoleId,
                action = RoleBindingChangedEvent.BindingAction.DELETED
            )
        )
    }

    // === 멤버 오버라이드 관리 ===

    @Transactional(readOnly = true)
    fun getChannelMemberOverrides(channelId: Long): List<MemberOverrideResponse> {
        val overrides = channelMemberOverrideRepository.findByChannelId(channelId)
        return overrides.map { override ->
            MemberOverrideResponse(
                id = override.id,
                channelId = override.channel.id,
                userId = override.user.id,
                userEmail = override.user.email,
                allowPermissions = ChannelPermission.fromMask(override.allowPermissionsMask),
                denyPermissions = ChannelPermission.fromMask(override.denyPermissionsMask)
            )
        }
    }

    fun setMemberOverride(channelId: Long, userId: Long, request: MemberOverrideRequest): MemberOverrideResponse {
        val channel = channelRepository.findByIdOrNull(channelId)
            ?: throw IllegalArgumentException("Channel not found: $channelId")

        val user = userRepository.findByIdOrNull(userId)
            ?: throw IllegalArgumentException("User not found: $userId")

        // 권한 충돌 검증
        val allowMask = ChannelPermission.toMask(request.allowPermissions)
        val denyMask = ChannelPermission.toMask(request.denyPermissions)
        permissionService.validateNoConflict(allowMask, denyMask)
        permissionService.validateInheritanceConsistency(allowMask, denyMask)

        // 기존 오버라이드 조회 또는 새로 생성
        val existingOverride = channelMemberOverrideRepository.findByChannelIdAndUserId(channelId, userId)

        val updatedOverride = if (existingOverride != null) {
            existingOverride.copy(
                allowPermissionsMask = allowMask,
                denyPermissionsMask = denyMask,
                updatedAt = LocalDateTime.now()
            )
        } else {
            ChannelMemberOverride(
                channel = channel,
                user = user,
                allowPermissionsMask = allowMask,
                denyPermissionsMask = denyMask
            )
        }

        val savedOverride = channelMemberOverrideRepository.save(updatedOverride)

        // 이벤트 발행
        eventPublisher.publishEvent(
            MemberOverrideChangedEvent(
                source = this,
                channelId = channelId,
                userId = userId,
                action = MemberOverrideChangedEvent.OverrideAction.UPDATED
            )
        )

        return MemberOverrideResponse(
            id = savedOverride.id,
            channelId = savedOverride.channel.id,
            userId = savedOverride.user.id,
            userEmail = savedOverride.user.email,
            allowPermissions = ChannelPermission.fromMask(savedOverride.allowPermissionsMask),
            denyPermissions = ChannelPermission.fromMask(savedOverride.denyPermissionsMask)
        )
    }

    fun deleteMemberOverride(channelId: Long, userId: Long) {
        val override = channelMemberOverrideRepository.findByChannelIdAndUserId(channelId, userId)
            ?: throw IllegalArgumentException("Member override not found for user $userId in channel $channelId")

        channelMemberOverrideRepository.delete(override)

        // 이벤트 발행
        eventPublisher.publishEvent(
            MemberOverrideChangedEvent(
                source = this,
                channelId = channelId,
                userId = userId,
                action = MemberOverrideChangedEvent.OverrideAction.DELETED
            )
        )
    }

    // === 권한 템플릿 관리 ===

    @Transactional(readOnly = true)
    fun getAllPermissionTemplates(): List<PermissionTemplateResponse> {
        val templates = permissionTemplateRepository.findAll()
        return templates.map { template ->
            val usageCount = channelRoleBindingRepository.countByTemplateId(template.id)
            PermissionTemplateResponse(
                id = template.id,
                name = template.name,
                description = template.description,
                permissions = ChannelPermission.fromMask(template.permissionsMask),
                usageCount = usageCount
            )
        }
    }

    @Transactional(readOnly = true)
    fun getPermissionTemplate(templateId: Long): PermissionTemplateResponse {
        val template = permissionTemplateRepository.findByIdOrNull(templateId)
            ?: throw IllegalArgumentException("Permission template not found: $templateId")

        val usageCount = channelRoleBindingRepository.countByTemplateId(templateId)

        return PermissionTemplateResponse(
            id = template.id,
            name = template.name,
            description = template.description,
            permissions = ChannelPermission.fromMask(template.permissionsMask),
            usageCount = usageCount
        )
    }

    fun createPermissionTemplate(request: CreatePermissionTemplateRequest): PermissionTemplateResponse {
        val template = ChannelPermissionTemplate(
            name = request.name,
            description = request.description,
            permissionsMask = ChannelPermission.toMask(request.permissions)
        )

        val savedTemplate = permissionTemplateRepository.save(template)

        // 이벤트 발행
        eventPublisher.publishEvent(
            TemplateChangedEvent(
                source = this,
                templateId = savedTemplate.id,
                action = TemplateChangedEvent.TemplateAction.CREATED
            )
        )

        return PermissionTemplateResponse(
            id = savedTemplate.id,
            name = savedTemplate.name,
            description = savedTemplate.description,
            permissions = ChannelPermission.fromMask(savedTemplate.permissionsMask),
            usageCount = 0
        )
    }

    fun updatePermissionTemplate(templateId: Long, request: UpdatePermissionTemplateRequest): PermissionTemplateResponse {
        val template = permissionTemplateRepository.findByIdOrNull(templateId)
            ?: throw IllegalArgumentException("Permission template not found: $templateId")

        val updatedTemplate = template.copy(
            name = request.name ?: template.name,
            description = request.description ?: template.description,
            permissionsMask = request.permissions?.let { ChannelPermission.toMask(it) } ?: template.permissionsMask,
            updatedAt = LocalDateTime.now()
        )

        val savedTemplate = permissionTemplateRepository.save(updatedTemplate)

        // 이벤트 발행
        eventPublisher.publishEvent(
            TemplateChangedEvent(
                source = this,
                templateId = templateId,
                action = TemplateChangedEvent.TemplateAction.UPDATED
            )
        )

        val usageCount = channelRoleBindingRepository.countByTemplateId(templateId)

        return PermissionTemplateResponse(
            id = savedTemplate.id,
            name = savedTemplate.name,
            description = savedTemplate.description,
            permissions = ChannelPermission.fromMask(savedTemplate.permissionsMask),
            usageCount = usageCount
        )
    }

    fun deletePermissionTemplate(templateId: Long) {
        val template = permissionTemplateRepository.findByIdOrNull(templateId)
            ?: throw IllegalArgumentException("Permission template not found: $templateId")

        // 사용 중인 템플릿인지 확인
        val usageCount = channelRoleBindingRepository.countByTemplateId(templateId)
        if (usageCount > 0) {
            throw IllegalStateException("Cannot delete template that is currently in use (used by $usageCount bindings)")
        }

        permissionTemplateRepository.delete(template)

        // 이벤트 발행
        eventPublisher.publishEvent(
            TemplateChangedEvent(
                source = this,
                templateId = templateId,
                action = TemplateChangedEvent.TemplateAction.DELETED
            )
        )
    }

    // === 사용자 권한 조회 ===

    @Transactional(readOnly = true)
    fun getUserChannelPermissions(channelId: Long, userId: Long): UserChannelPermissionsResponse {
        val channel = channelRepository.findByIdOrNull(channelId)
            ?: throw IllegalArgumentException("Channel not found: $channelId")

        val user = userRepository.findByIdOrNull(userId)
            ?: throw IllegalArgumentException("User not found: $userId")

        val allPermissions = permissionService.getUserChannelPermissions(channelId, userId)
        val override = channelMemberOverrideRepository.findByChannelIdAndUserId(channelId, userId)

        // 역할 기반 권한 계산 (오버라이드 제외)
        val roleBasedPermissions = if (override != null) {
            // 오버라이드가 있는 경우, 역할 권한만 계산
            calculateRoleBasedPermissions(channelId, userId)
        } else {
            allPermissions
        }

        return UserChannelPermissionsResponse(
            channelId = channelId,
            channelName = channel.name,
            userId = userId,
            userEmail = user.email,
            permissions = allPermissions,
            hasOverride = override != null,
            roleBasedPermissions = roleBasedPermissions,
            overridePermissions = override?.let {
                ChannelPermission.fromMask(it.allowPermissionsMask) - ChannelPermission.fromMask(it.denyPermissionsMask)
            }
        )
    }

    @Transactional(readOnly = true)
    fun getCurrentUserChannelPermissions(channelId: Long): UserChannelPermissionsResponse {
        val currentUser = getCurrentUser()
        return getUserChannelPermissions(channelId, currentUser.id)
    }

    @Transactional(readOnly = true)
    fun checkCurrentUserPermission(channelId: Long, permission: ChannelPermission): PermissionCheckResponse {
        val currentUser = getCurrentUser()
        val hasPermission = permissionService.hasChannelPermission(channelId, currentUser.id, permission)

        val reason = if (!hasPermission) {
            "User ${currentUser.email} does not have $permission permission in channel $channelId"
        } else null

        return PermissionCheckResponse(
            hasPermission = hasPermission,
            reason = reason
        )
    }

    // === 유틸리티 메소드들 ===

    private fun getCurrentUser(): User {
        val authentication = SecurityContextHolder.getContext().authentication
        val email = authentication.name
        return userRepository.findByEmail(email).orElseThrow {
            IllegalStateException("Current user not found: $email")
        }
    }

    private fun calculateRoleBasedPermissions(channelId: Long, userId: Long): Set<ChannelPermission> {
        // 이 메소드는 오버라이드를 제외한 순수 역할 기반 권한만 계산
        // ChannelPermissionService의 로직을 재사용하되 오버라이드 단계를 제외

        val userRoles = getUserRolesInChannel(channelId, userId)
        val boundRoles = getBoundRoles(channelId, userRoles)

        if (boundRoles.isEmpty()) {
            return if (isPublicChannel(channelId)) {
                setOf(ChannelPermission.CHANNEL_VIEW)
            } else emptySet()
        }

        val roleMask = computeRoleMask(boundRoles)
        val finalMask = ChannelPermission.applyInheritance(roleMask)

        return ChannelPermission.fromMask(finalMask)
    }

    private fun getUserRolesInChannel(channelId: Long, userId: Long): List<Long> {
        val channel = channelRepository.findByIdOrNull(channelId) ?: return emptyList()
        val groupId = channel.group.id

        val membership = groupMemberRepository.findByGroupIdAndUserId(groupId, userId).orElse(null)
            ?: return emptyList()

        return listOf(membership.role.id)
    }

    private fun getBoundRoles(channelId: Long, userRoleIds: List<Long>): List<ChannelRoleBinding> {
        if (userRoleIds.isEmpty()) return emptyList()
        return channelRoleBindingRepository.findByChannelIdAndGroupRoleIdIn(channelId, userRoleIds)
    }

    private fun computeRoleMask(bindings: List<ChannelRoleBinding>): Long {
        var acc = 0L
        for (binding in bindings) {
            val templateMask = binding.template?.permissionsMask ?: 0L
            val allow = binding.allowPermissionsMask
            val deny = binding.denyPermissionsMask

            val perBinding = ChannelPermission.applyDenyPolicy(templateMask or allow, deny)
            acc = acc or perBinding
        }
        return acc
    }

    private fun isPublicChannel(channelId: Long): Boolean {
        return channelRepository.findByIdOrNull(channelId)?.isPublic ?: false
    }
}