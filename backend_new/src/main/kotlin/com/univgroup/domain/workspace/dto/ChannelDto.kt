package com.univgroup.domain.workspace.dto

import com.univgroup.domain.workspace.entity.Channel
import com.univgroup.domain.workspace.entity.ChannelType
import java.time.LocalDateTime

/**
 * 채널 응답 DTO
 */
data class ChannelDto(
    val id: Long,
    val workspaceId: Long?,
    val groupId: Long,
    val name: String,
    val description: String?,
    val type: ChannelType,
    val displayOrder: Int,
    val postCount: Int?,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime,
) {
    companion object {
        fun from(
            channel: Channel,
            postCount: Int? = null,
        ): ChannelDto {
            return ChannelDto(
                id = channel.id!!,
                workspaceId = channel.workspace?.id,
                groupId = channel.group.id!!,
                name = channel.name,
                description = channel.description,
                type = channel.type,
                displayOrder = channel.displayOrder,
                postCount = postCount,
                createdAt = channel.createdAt,
                updatedAt = channel.updatedAt,
            )
        }
    }
}

/**
 * 채널 요약 DTO
 */
data class ChannelSummaryDto(
    val id: Long,
    val name: String,
    val type: ChannelType,
    val displayOrder: Int,
) {
    companion object {
        fun from(channel: Channel): ChannelSummaryDto {
            return ChannelSummaryDto(
                id = channel.id!!,
                name = channel.name,
                type = channel.type,
                displayOrder = channel.displayOrder,
            )
        }
    }
}

/**
 * 채널 생성 요청 DTO
 */
data class CreateChannelRequest(
    val name: String,
    val description: String? = null,
    val type: ChannelType = ChannelType.TEXT,
)

/**
 * 채널 수정 요청 DTO
 */
data class UpdateChannelRequest(
    val name: String? = null,
    val description: String? = null,
)

/**
 * 채널 순서 변경 요청 DTO
 */
data class ReorderChannelsRequest(
    val channelIds: List<Long>,
)
