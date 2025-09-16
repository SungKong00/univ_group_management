package org.castlekong.backend.dto

import org.castlekong.backend.entity.ChannelPermission

/**
 * 채널 권한 관련 DTO들
 */

/**
 * 채널 역할 바인딩 생성 요청
 */
data class CreateChannelRoleBindingRequest(
    val groupRoleId: Long,
    val templateId: Long? = null,
    val allowPermissions: Set<ChannelPermission> = emptySet(),
    val denyPermissions: Set<ChannelPermission> = emptySet()
)

/**
 * 채널 역할 바인딩 수정 요청
 */
data class UpdateChannelRoleBindingRequest(
    val templateId: Long? = null,
    val allowPermissions: Set<ChannelPermission>? = null,
    val denyPermissions: Set<ChannelPermission>? = null
)

/**
 * 채널 역할 바인딩 응답
 */
data class ChannelRoleBindingResponse(
    val id: Long,
    val channelId: Long,
    val groupRoleId: Long,
    val groupRoleName: String,
    val templateId: Long?,
    val templateName: String?,
    val allowPermissions: Set<ChannelPermission>,
    val denyPermissions: Set<ChannelPermission>,
    val effectivePermissions: Set<ChannelPermission>
)

/**
 * 멤버 오버라이드 생성/수정 요청
 */
data class MemberOverrideRequest(
    val allowPermissions: Set<ChannelPermission> = emptySet(),
    val denyPermissions: Set<ChannelPermission> = emptySet()
)

/**
 * 멤버 오버라이드 응답
 */
data class MemberOverrideResponse(
    val id: Long,
    val channelId: Long,
    val userId: Long,
    val userEmail: String,
    val allowPermissions: Set<ChannelPermission>,
    val denyPermissions: Set<ChannelPermission>
)

/**
 * 권한 템플릿 생성 요청
 */
data class CreatePermissionTemplateRequest(
    val name: String,
    val description: String?,
    val permissions: Set<ChannelPermission>
)

/**
 * 권한 템플릿 수정 요청
 */
data class UpdatePermissionTemplateRequest(
    val name: String?,
    val description: String?,
    val permissions: Set<ChannelPermission>?
)

/**
 * 권한 템플릿 응답
 */
data class PermissionTemplateResponse(
    val id: Long,
    val name: String,
    val description: String?,
    val permissions: Set<ChannelPermission>,
    val usageCount: Int
)

/**
 * 사용자 채널 권한 조회 응답
 */
data class UserChannelPermissionsResponse(
    val channelId: Long,
    val channelName: String,
    val userId: Long,
    val userEmail: String,
    val permissions: Set<ChannelPermission>,
    val hasOverride: Boolean,
    val roleBasedPermissions: Set<ChannelPermission>,
    val overridePermissions: Set<ChannelPermission>?
)

/**
 * 권한 검증 요청
 */
data class PermissionCheckRequest(
    val permission: ChannelPermission
)

/**
 * 권한 검증 응답
 */
data class PermissionCheckResponse(
    val hasPermission: Boolean,
    val reason: String? = null
)