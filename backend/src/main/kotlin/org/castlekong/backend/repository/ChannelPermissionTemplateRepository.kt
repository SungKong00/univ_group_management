package org.castlekong.backend.repository

import org.castlekong.backend.entity.ChannelPermissionTemplate
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository

@Repository
interface ChannelPermissionTemplateRepository : JpaRepository<ChannelPermissionTemplate, Long> {

    /**
     * 특정 그룹의 권한 템플릿 조회
     */
    fun findByGroupId(groupId: Long): List<ChannelPermissionTemplate>

    /**
     * 글로벌 권한 템플릿 조회 (group_id가 null)
     */
    fun findByGroupIsNull(): List<ChannelPermissionTemplate>

    /**
     * 특정 그룹의 템플릿 + 글로벌 템플릿 모두 조회
     */
    @Query("SELECT t FROM ChannelPermissionTemplate t WHERE t.group.id = :groupId OR t.group IS NULL")
    fun findByGroupIdOrGlobal(@Param("groupId") groupId: Long): List<ChannelPermissionTemplate>

    /**
     * 특정 그룹에서 이름으로 템플릿 조회
     */
    fun findByGroupIdAndName(groupId: Long, name: String): ChannelPermissionTemplate?

    /**
     * 글로벌 템플릿에서 이름으로 조회
     */
    fun findByGroupIsNullAndName(name: String): ChannelPermissionTemplate?
}