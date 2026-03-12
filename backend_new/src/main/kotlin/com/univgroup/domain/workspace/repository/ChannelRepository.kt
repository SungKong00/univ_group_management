package com.univgroup.domain.workspace.repository

import com.univgroup.domain.workspace.entity.Channel
import com.univgroup.domain.workspace.entity.ChannelType
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository

@Repository
interface ChannelRepository : JpaRepository<Channel, Long> {
    // ===== 워크스페이스별 조회 =====

    fun findByWorkspaceId(workspaceId: Long): List<Channel>

    @Query(
        """
        SELECT c FROM Channel c
        WHERE c.workspace.id = :workspaceId
        ORDER BY c.displayOrder ASC
        """,
    )
    fun findByWorkspaceIdOrderByDisplayOrder(
        @Param("workspaceId") workspaceId: Long,
    ): List<Channel>

    // ===== 그룹별 조회 =====

    fun findByGroupId(groupId: Long): List<Channel>

    @Query(
        """
        SELECT c FROM Channel c
        JOIN FETCH c.workspace
        WHERE c.group.id = :groupId
        ORDER BY c.workspace.displayOrder, c.displayOrder
        """,
    )
    fun findByGroupIdWithWorkspace(
        @Param("groupId") groupId: Long,
    ): List<Channel>

    // ===== 특정 채널 조회 =====

    fun findByWorkspaceIdAndName(
        workspaceId: Long,
        name: String,
    ): Channel?

    fun findByWorkspaceIdAndType(
        workspaceId: Long,
        type: ChannelType,
    ): List<Channel>

    // ===== 존재 여부 =====

    fun existsByWorkspaceIdAndName(
        workspaceId: Long,
        name: String,
    ): Boolean

    fun existsByGroupIdAndName(
        groupId: Long,
        name: String,
    ): Boolean

    // ===== 삭제 =====

    fun deleteAllByWorkspaceId(workspaceId: Long)

    // ===== 통계 =====

    fun countByWorkspaceId(workspaceId: Long): Long

    fun countByGroupId(groupId: Long): Long
}
