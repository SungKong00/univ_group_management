package org.castlekong.backend.repository

import org.castlekong.backend.entity.ChannelRoleBinding
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Modifying
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository

@Repository
interface ChannelRoleBindingRepository : JpaRepository<ChannelRoleBinding, Long> {

    /**
     * 특정 채널의 모든 역할 바인딩 조회
     */
    fun findByChannelId(channelId: Long): List<ChannelRoleBinding>

    /**
     * 특정 채널에서 특정 역할들의 바인딩 조회
     */
    fun findByChannelIdAndGroupRoleIdIn(channelId: Long, groupRoleIds: List<Long>): List<ChannelRoleBinding>

    /**
     * 특정 채널에 바인딩된 역할 ID 목록 조회
     */
    @Query("SELECT b.groupRole.id FROM ChannelRoleBinding b WHERE b.channel.id = :channelId")
    fun findRoleIdsByChannelId(@Param("channelId") channelId: Long): List<Long>


    /**
     * 특정 그룹의 역할들이 바인딩된 모든 채널 ID 조회
     */
    @Query("SELECT DISTINCT b.channel.id FROM ChannelRoleBinding b WHERE b.groupRole.group.id = :groupId")
    fun findChannelIdsByGroupRoleInGroup(@Param("groupId") groupId: Long): List<Long>

    /**
     * 특정 채널과 역할의 바인딩 존재 여부 확인
     */
    fun existsByChannelIdAndGroupRoleId(channelId: Long, groupRoleId: Long): Boolean

    /**
     * 특정 채널과 역할의 바인딩 조회
     */
    fun findByChannelIdAndGroupRoleId(channelId: Long, groupRoleId: Long): ChannelRoleBinding?

    /**
     * 특정 채널에서 바인딩 삭제
     */
    fun deleteByChannelIdAndGroupRoleId(channelId: Long, groupRoleId: Long)

    /**
     * 특정 채널의 모든 바인딩 삭제
     */
    fun deleteByChannelId(channelId: Long)

    /**
     * 채널 ID 다건에 대한 바인딩 일괄 삭제
     */
    @Modifying
    @Query("DELETE FROM ChannelRoleBinding b WHERE b.channel.id IN :channelIds")
    fun deleteByChannelIds(@Param("channelIds") channelIds: List<Long>): Int
}