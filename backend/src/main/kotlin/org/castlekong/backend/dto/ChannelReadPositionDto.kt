package org.castlekong.backend.dto

import java.time.LocalDateTime

data class ChannelReadPositionResponse(
    val lastReadPostId: Long,
    val updatedAt: LocalDateTime,
)

data class UpdateReadPositionRequest(
    val lastReadPostId: Long,
)

data class UnreadCountResponse(
    val channelId: Long,
    val unreadCount: Int,
)
