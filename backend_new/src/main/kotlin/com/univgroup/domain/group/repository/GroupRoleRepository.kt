package com.univgroup.domain.group.repository

import com.univgroup.domain.group.entity.GroupRole
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository

@Repository
interface GroupRoleRepository : JpaRepository<GroupRole, Long> {
    // ===== 그룹별 역할 조회 =====

    fun findByGroupId(groupId: Long): List<GroupRole>

    @Query(
        """
        SELECT gr FROM GroupRole gr
        WHERE gr.group.id = :groupId
        ORDER BY gr.priority DESC, gr.name ASC
        """,
    )
    fun findByGroupIdOrderByPriorityDesc(
        @Param("groupId") groupId: Long,
    ): List<GroupRole>

    // ===== 특정 역할 조회 =====

    fun findByGroupIdAndName(
        groupId: Long,
        name: String,
    ): GroupRole?

    fun findByGroupIdAndId(
        groupId: Long,
        id: Long,
    ): GroupRole?

    // ===== 시스템 역할 조회 =====

    fun findByGroupIdAndIsSystemRole(
        groupId: Long,
        isSystemRole: Boolean,
    ): List<GroupRole>

    @Query(
        """
        SELECT gr FROM GroupRole gr
        WHERE gr.group.id = :groupId
        AND gr.isSystemRole = true
        AND gr.name = :name
        """,
    )
    fun findSystemRoleByGroupIdAndName(
        @Param("groupId") groupId: Long,
        @Param("name") name: String,
    ): GroupRole?

    // ===== 존재 여부 확인 =====

    fun existsByGroupIdAndName(
        groupId: Long,
        name: String,
    ): Boolean

    // ===== 삭제 =====

    fun deleteAllByGroupId(groupId: Long)

    // ===== 통계 =====

    fun countByGroupId(groupId: Long): Long
}
