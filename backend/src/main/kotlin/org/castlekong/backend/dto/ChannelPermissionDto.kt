package org.castlekong.backend.dto

import org.castlekong.backend.entity.ChannelPermission

/**
 * 채널 권한 관련 DTO들 (MVP 단순화 버전)
 * 개인 오버라이드 및 복잡한 템플릿 시스템 제거
 */

/**
 * 채널 역할 바인딩 생성 요청
 */
data class CreateChannelRoleBindingRequest(
    val groupRoleId: Long,
    val permissions: Set<ChannelPermission> = emptySet(),
)

/**
 * 채널 역할 바인딩 수정 요청
 */
data class UpdateChannelRoleBindingRequest(
    val permissions: Set<ChannelPermission>? = null,
)

/**
 * 채널 역할 바인딩 응답
 */
data class ChannelRoleBindingResponse(
    val id: Long,
    val channelId: Long,
    val groupRoleId: Long,
    val groupRoleName: String,
    val permissions: Set<ChannelPermission>,
)

/**
 * 권한 검증 응답
 */
data class PermissionCheckResponse(
    val hasPermission: Boolean,
    val reason: String? = null,
)
