package com.univgroup.domain.permission.repository

import com.univgroup.domain.permission.entity.ChannelRoleBinding
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.stereotype.Repository

/**
 * 채널 역할 바인딩 Repository
 */
@Repository
interface ChannelRoleBindingRepository : JpaRepository<ChannelRoleBinding, Long> {
    /**
     * 채널 ID로 모든 역할 바인딩 조회
     */
    fun findByChannelId(channelId: Long): List<ChannelRoleBinding>

    /**
     * 채널 ID와 그룹 역할 ID로 바인딩 조회
     */
    fun findByChannelIdAndGroupRoleId(channelId: Long, groupRoleId: Long): ChannelRoleBinding?

    /**
     * 채널 ID와 그룹 역할 ID 리스트로 바인딩 조회
     */
    fun findByChannelIdAndGroupRoleIdIn(channelId: Long, groupRoleIds: List<Long>): List<ChannelRoleBinding>

    /**
     * 그룹 역할로 모든 바인딩 조회
     */
    fun findByGroupRoleId(groupRoleId: Long): List<ChannelRoleBinding>

    /**
     * 채널과 그룹 역할의 바인딩 존재 여부 확인
     */
    fun existsByChannelIdAndGroupRoleId(channelId: Long, groupRoleId: Long): Boolean

    /**
     * 채널의 모든 바인딩 삭제
     */
    fun deleteByChannelId(channelId: Long)

    /**
     * 그룹 역할의 모든 바인딩 삭제
     */
    fun deleteByGroupRoleId(groupRoleId: Long)

    /**
     * 채널 ID로 바인딩된 그룹 역할 ID 목록 조회
     */
    @Query("SELECT crb.groupRole.id FROM ChannelRoleBinding crb WHERE crb.channel.id = :channelId")
    fun findGroupRoleIdsByChannelId(channelId: Long): List<Long>
}
