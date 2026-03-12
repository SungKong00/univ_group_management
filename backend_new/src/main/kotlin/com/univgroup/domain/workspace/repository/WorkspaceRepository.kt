package com.univgroup.domain.workspace.repository

import com.univgroup.domain.workspace.entity.Workspace
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository

@Repository
interface WorkspaceRepository : JpaRepository<Workspace, Long> {
    // ===== 그룹별 조회 =====

    fun findByGroupId(groupId: Long): List<Workspace>

    @Query(
        """
        SELECT w FROM Workspace w
        WHERE w.group.id = :groupId
        ORDER BY w.displayOrder ASC
        """,
    )
    fun findByGroupIdOrderByDisplayOrder(
        @Param("groupId") groupId: Long,
    ): List<Workspace>

    // ===== 특정 워크스페이스 조회 =====

    fun findByGroupIdAndName(
        groupId: Long,
        name: String,
    ): Workspace?

    // ===== 기본 워크스페이스 =====

    fun findByGroupIdAndIsDefault(
        groupId: Long,
        isDefault: Boolean,
    ): Workspace?

    // ===== 존재 여부 =====

    fun existsByGroupIdAndName(
        groupId: Long,
        name: String,
    ): Boolean

    // ===== 삭제 =====

    fun deleteAllByGroupId(groupId: Long)

    // ===== 통계 =====

    fun countByGroupId(groupId: Long): Long
}
