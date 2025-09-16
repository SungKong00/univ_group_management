package org.castlekong.backend.controller

import org.castlekong.backend.dto.*
import org.castlekong.backend.entity.ChannelPermission
import org.castlekong.backend.service.ChannelPermissionManagementService
import org.castlekong.backend.service.ChannelPermissionService
import org.springframework.http.ResponseEntity
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.web.bind.annotation.*

/**
 * 채널 권한 관리 API 컨트롤러
 */
@RestController
@RequestMapping("/api/channels/{channelId}/permissions")
class ChannelPermissionController(
    private val permissionService: ChannelPermissionService,
    private val managementService: ChannelPermissionManagementService
) {

    /**
     * 채널의 모든 역할 바인딩 조회
     */
    @GetMapping("/role-bindings")
    @PreAuthorize("@security.isGroupMember(@channelPermissionService.getChannelGroupId(#channelId))")
    fun getChannelRoleBindings(@PathVariable channelId: Long): ResponseEntity<List<ChannelRoleBindingResponse>> {
        val bindings = managementService.getChannelRoleBindings(channelId)
        return ResponseEntity.ok(bindings)
    }

    /**
     * 채널에 역할 바인딩 추가
     */
    @PostMapping("/role-bindings")
    @PreAuthorize("@security.hasChannelPermission(#channelId, 'CHANNEL_MANAGE')")
    fun createChannelRoleBinding(
        @PathVariable channelId: Long,
        @RequestBody request: CreateChannelRoleBindingRequest
    ): ResponseEntity<ChannelRoleBindingResponse> {
        val binding = managementService.createChannelRoleBinding(channelId, request)
        return ResponseEntity.ok(binding)
    }

    /**
     * 채널 역할 바인딩 수정
     */
    @PutMapping("/role-bindings/{bindingId}")
    @PreAuthorize("@security.hasChannelPermission(#channelId, 'CHANNEL_MANAGE')")
    fun updateChannelRoleBinding(
        @PathVariable channelId: Long,
        @PathVariable bindingId: Long,
        @RequestBody request: UpdateChannelRoleBindingRequest
    ): ResponseEntity<ChannelRoleBindingResponse> {
        val binding = managementService.updateChannelRoleBinding(bindingId, request)
        return ResponseEntity.ok(binding)
    }

    /**
     * 채널 역할 바인딩 삭제
     */
    @DeleteMapping("/role-bindings/{bindingId}")
    @PreAuthorize("@security.hasChannelPermission(#channelId, 'CHANNEL_MANAGE')")
    fun deleteChannelRoleBinding(
        @PathVariable channelId: Long,
        @PathVariable bindingId: Long
    ): ResponseEntity<Void> {
        managementService.deleteChannelRoleBinding(bindingId)
        return ResponseEntity.noContent().build()
    }

    /**
     * 채널의 모든 멤버 오버라이드 조회
     */
    @GetMapping("/member-overrides")
    @PreAuthorize("@security.hasChannelPermission(#channelId, 'CHANNEL_MANAGE')")
    fun getChannelMemberOverrides(@PathVariable channelId: Long): ResponseEntity<List<MemberOverrideResponse>> {
        val overrides = managementService.getChannelMemberOverrides(channelId)
        return ResponseEntity.ok(overrides)
    }

    /**
     * 특정 멤버에 오버라이드 설정
     */
    @PutMapping("/member-overrides/{userId}")
    @PreAuthorize("@security.hasChannelPermission(#channelId, 'CHANNEL_MANAGE')")
    fun setMemberOverride(
        @PathVariable channelId: Long,
        @PathVariable userId: Long,
        @RequestBody request: MemberOverrideRequest
    ): ResponseEntity<MemberOverrideResponse> {
        val override = managementService.setMemberOverride(channelId, userId, request)
        return ResponseEntity.ok(override)
    }

    /**
     * 멤버 오버라이드 삭제
     */
    @DeleteMapping("/member-overrides/{userId}")
    @PreAuthorize("@security.hasChannelPermission(#channelId, 'CHANNEL_MANAGE')")
    fun deleteMemberOverride(
        @PathVariable channelId: Long,
        @PathVariable userId: Long
    ): ResponseEntity<Void> {
        managementService.deleteMemberOverride(channelId, userId)
        return ResponseEntity.noContent().build()
    }

    /**
     * 사용자의 채널 권한 조회
     */
    @GetMapping("/users/{userId}")
    @PreAuthorize("@security.isGroupMember(@channelPermissionService.getChannelGroupId(#channelId))")
    fun getUserChannelPermissions(
        @PathVariable channelId: Long,
        @PathVariable userId: Long
    ): ResponseEntity<UserChannelPermissionsResponse> {
        val permissions = managementService.getUserChannelPermissions(channelId, userId)
        return ResponseEntity.ok(permissions)
    }

    /**
     * 현재 사용자의 채널 권한 조회
     */
    @GetMapping("/me")
    @PreAuthorize("@security.isGroupMember(@channelPermissionService.getChannelGroupId(#channelId))")
    fun getMyChannelPermissions(@PathVariable channelId: Long): ResponseEntity<UserChannelPermissionsResponse> {
        val permissions = managementService.getCurrentUserChannelPermissions(channelId)
        return ResponseEntity.ok(permissions)
    }

    /**
     * 권한 검증
     */
    @PostMapping("/check")
    @PreAuthorize("@security.isGroupMember(@channelPermissionService.getChannelGroupId(#channelId))")
    fun checkPermission(
        @PathVariable channelId: Long,
        @RequestBody request: PermissionCheckRequest
    ): ResponseEntity<PermissionCheckResponse> {
        val result = managementService.checkCurrentUserPermission(channelId, request.permission)
        return ResponseEntity.ok(result)
    }
}

/**
 * 권한 템플릿 관리 API 컨트롤러
 */
@RestController
@RequestMapping("/api/permission-templates")
class PermissionTemplateController(
    private val managementService: ChannelPermissionManagementService
) {

    /**
     * 모든 권한 템플릿 조회
     */
    @GetMapping
    @PreAuthorize("isAuthenticated()")
    fun getAllTemplates(): ResponseEntity<List<PermissionTemplateResponse>> {
        val templates = managementService.getAllPermissionTemplates()
        return ResponseEntity.ok(templates)
    }

    /**
     * 권한 템플릿 조회
     */
    @GetMapping("/{templateId}")
    @PreAuthorize("isAuthenticated()")
    fun getTemplate(@PathVariable templateId: Long): ResponseEntity<PermissionTemplateResponse> {
        val template = managementService.getPermissionTemplate(templateId)
        return ResponseEntity.ok(template)
    }

    /**
     * 권한 템플릿 생성
     */
    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    fun createTemplate(@RequestBody request: CreatePermissionTemplateRequest): ResponseEntity<PermissionTemplateResponse> {
        val template = managementService.createPermissionTemplate(request)
        return ResponseEntity.ok(template)
    }

    /**
     * 권한 템플릿 수정
     */
    @PutMapping("/{templateId}")
    @PreAuthorize("hasRole('ADMIN')")
    fun updateTemplate(
        @PathVariable templateId: Long,
        @RequestBody request: UpdatePermissionTemplateRequest
    ): ResponseEntity<PermissionTemplateResponse> {
        val template = managementService.updatePermissionTemplate(templateId, request)
        return ResponseEntity.ok(template)
    }

    /**
     * 권한 템플릿 삭제
     */
    @DeleteMapping("/{templateId}")
    @PreAuthorize("hasRole('ADMIN')")
    fun deleteTemplate(@PathVariable templateId: Long): ResponseEntity<Void> {
        managementService.deletePermissionTemplate(templateId)
        return ResponseEntity.noContent().build()
    }
}