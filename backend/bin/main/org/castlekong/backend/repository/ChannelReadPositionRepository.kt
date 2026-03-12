package org.castlekong.backend.repository

import org.castlekong.backend.entity.ChannelReadPosition
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository

@Repository
interface ChannelReadPositionRepository : JpaRepository<ChannelReadPosition, Long> {
    fun findByUserIdAndChannelId(
        userId: Long,
        channelId: Long,
    ): ChannelReadPosition?

    @Query("SELECT crp FROM ChannelReadPosition crp WHERE crp.userId = :userId AND crp.channelId IN :channelIds")
    fun findAllByUserIdAndChannelIdIn(
        @Param("userId") userId: Long,
        @Param("channelIds") channelIds: List<Long>,
    ): List<ChannelReadPosition>
}
