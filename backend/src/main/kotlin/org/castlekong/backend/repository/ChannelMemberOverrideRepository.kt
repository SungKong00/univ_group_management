package org.castlekong.backend.repository

import org.castlekong.backend.entity.ChannelMemberOverride
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository

@Repository
interface ChannelMemberOverrideRepository : JpaRepository<ChannelMemberOverride, Long> {

    /**
     * 특정 채널의 모든 멤버 오버라이드 조회
     */
    fun findByChannelId(channelId: Long): List<ChannelMemberOverride>

    /**
     * 특정 사용자의 모든 멤버 오버라이드 조회
     */
    fun findByUserId(userId: Long): List<ChannelMemberOverride>

    /**
     * 특정 채널과 사용자의 오버라이드 조회
     */
    fun findByChannelIdAndUserId(channelId: Long, userId: Long): ChannelMemberOverride?

    /**
     * 특정 채널과 사용자의 오버라이드 존재 여부 확인
     */
    fun existsByChannelIdAndUserId(channelId: Long, userId: Long): Boolean

    /**
     * 특정 채널에서 오버라이드가 설정된 사용자 ID 목록 조회
     */
    @Query("SELECT o.user.id FROM ChannelMemberOverride o WHERE o.channel.id = :channelId")
    fun findUserIdsByChannelId(@Param("channelId") channelId: Long): List<Long>

    /**
     * 특정 사용자에게 오버라이드가 설정된 채널 ID 목록 조회
     */
    @Query("SELECT o.channel.id FROM ChannelMemberOverride o WHERE o.user.id = :userId")
    fun findChannelIdsByUserId(@Param("userId") userId: Long): List<Long>

    /**
     * 특정 채널과 사용자의 오버라이드 삭제
     */
    fun deleteByChannelIdAndUserId(channelId: Long, userId: Long)

    /**
     * 특정 채널의 모든 오버라이드 삭제
     */
    fun deleteByChannelId(channelId: Long)

    /**
     * 특정 사용자의 모든 오버라이드 삭제
     */
    fun deleteByUserId(userId: Long)
}