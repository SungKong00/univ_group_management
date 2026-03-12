package com.univgroup.domain.group.repository

import com.univgroup.domain.group.entity.GroupMember
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository

@Repository
interface GroupMemberRepository : JpaRepository<GroupMember, Long> {
    // ===== 멤버 조회 =====

    fun findByGroupIdAndUserId(
        groupId: Long,
        userId: Long,
    ): GroupMember?

    @Query(
        """
        SELECT gm FROM GroupMember gm
        JOIN FETCH gm.user
        JOIN FETCH gm.role
        WHERE gm.group.id = :groupId
        ORDER BY gm.role.priority DESC, gm.joinedAt ASC
        """,
    )
    fun findByGroupIdWithUserAndRole(
        @Param("groupId") groupId: Long,
    ): List<GroupMember>

    @Query(
        """
        SELECT gm FROM GroupMember gm
        JOIN FETCH gm.user
        JOIN FETCH gm.role
        WHERE gm.group.id = :groupId
        """,
    )
    fun findByGroupIdWithUserAndRole(
        @Param("groupId") groupId: Long,
        pageable: Pageable,
    ): Page<GroupMember>

    // ===== 사용자의 그룹 목록 =====

    @Query(
        """
        SELECT gm FROM GroupMember gm
        JOIN FETCH gm.group
        JOIN FETCH gm.role
        WHERE gm.user.id = :userId
        ORDER BY gm.joinedAt DESC
        """,
    )
    fun findByUserIdWithGroupAndRole(
        @Param("userId") userId: Long,
    ): List<GroupMember>

    // ===== 역할 기준 조회 =====

    fun findByGroupIdAndRoleId(
        groupId: Long,
        roleId: Long,
    ): List<GroupMember>

    @Query(
        """
        SELECT gm FROM GroupMember gm
        JOIN FETCH gm.user
        WHERE gm.group.id = :groupId
        AND gm.role.id = :roleId
        """,
    )
    fun findByGroupIdAndRoleIdWithUser(
        @Param("groupId") groupId: Long,
        @Param("roleId") roleId: Long,
    ): List<GroupMember>

    // ===== 존재 여부 확인 =====

    fun existsByGroupIdAndUserId(
        groupId: Long,
        userId: Long,
    ): Boolean

    // ===== 삭제 =====

    fun deleteByGroupIdAndUserId(
        groupId: Long,
        userId: Long,
    )

    fun deleteAllByGroupId(groupId: Long)

    // ===== 통계 =====

    fun countByGroupId(groupId: Long): Long

    @Query(
        """
        SELECT gm.role.id, COUNT(gm)
        FROM GroupMember gm
        WHERE gm.group.id = :groupId
        GROUP BY gm.role.id
        """,
    )
    fun countByGroupIdGroupByRoleId(
        @Param("groupId") groupId: Long,
    ): List<Array<Any>>
}
