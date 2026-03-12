package com.univgroup.domain.workspace.repository

import com.univgroup.domain.workspace.entity.ChannelReadPosition
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Modifying
import org.springframework.data.jpa.repository.Query
import org.springframework.stereotype.Repository

/**
 * 채널 읽음 위치 Repository
 */
@Repository
interface ChannelReadPositionRepository : JpaRepository<ChannelReadPosition, Long> {
    /**
     * 사용자 ID와 채널 ID로 읽음 위치 조회
     */
    fun findByUserIdAndChannelId(userId: Long, channelId: Long): ChannelReadPosition?

    /**
     * 사용자 ID로 모든 읽음 위치 조회
     */
    fun findByUserId(userId: Long): List<ChannelReadPosition>

    /**
     * 채널 ID로 모든 읽음 위치 조회
     */
    fun findByChannelId(channelId: Long): List<ChannelReadPosition>

    /**
     * 사용자와 채널의 읽음 위치 존재 여부 확인
     */
    fun existsByUserIdAndChannelId(userId: Long, channelId: Long): Boolean

    /**
     * 채널의 모든 읽음 위치 삭제
     */
    fun deleteByChannelId(channelId: Long)

    /**
     * 사용자의 모든 읽음 위치 삭제
     */
    fun deleteByUserId(userId: Long)

    /**
     * 사용자의 채널 읽음 위치 업데이트 또는 생성
     */
    @Modifying
    @Query("""
        INSERT INTO ChannelReadPosition (user, channel, lastReadPostId, updatedAt)
        VALUES (:userId, :channelId, :postId, CURRENT_TIMESTAMP)
        ON DUPLICATE KEY UPDATE
        lastReadPostId = :postId,
        updatedAt = CURRENT_TIMESTAMP
    """, nativeQuery = true)
    fun upsertReadPosition(userId: Long, channelId: Long, postId: Long)
}
