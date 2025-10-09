package org.castlekong.backend.repository

import org.castlekong.backend.entity.Group
import org.castlekong.backend.entity.GroupJoinRequest
import org.castlekong.backend.entity.GroupJoinRequestStatus
import org.castlekong.backend.entity.GroupMember
import org.castlekong.backend.entity.GroupRole
import org.castlekong.backend.entity.GroupType
import org.castlekong.backend.entity.SubGroupRequest
import org.castlekong.backend.entity.SubGroupRequestStatus
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Modifying
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.util.Optional

@Repository
interface GroupRepository : JpaRepository<Group, Long> {
    fun findByParentId(parentId: Long): List<Group>

    fun findByParentIsNull(): List<Group> // 최상위 그룹 조회

    fun findByUniversityAndCollegeAndDepartment(
        university: String?,
        college: String?,
        department: String?,
    ): List<Group>

    fun findByDeletedAtIsNull(pageable: Pageable): Page<Group>

    @Query(
        """
        SELECT DISTINCT g FROM Group g
        LEFT JOIN g.tags t
        WHERE (g.deletedAt IS NULL)
        AND (:recruiting IS NULL OR g.isRecruiting = :recruiting)
        AND (:groupType IS NULL OR g.groupType = :groupType)
        AND (:university IS NULL OR g.university = :university)
        AND (:college IS NULL OR g.college = :college)
        AND (:department IS NULL OR g.department = :department)
        AND (
            :q IS NULL OR LOWER(g.name) LIKE LOWER(CONCAT('%', :q, '%')) OR LOWER(g.description) LIKE LOWER(CONCAT('%', :q, '%'))
        )
        AND (
            :tagsSize = 0 OR t IN :tags
        )
        """,
    )
    fun search(
        @Param("recruiting") recruiting: Boolean?,
        @Param("groupType") groupType: GroupType?,
        @Param("university") university: String?,
        @Param("college") college: String?,
        @Param("department") department: String?,
        @Param("q") q: String?,
        @Param("tags") tags: Set<String>,
        @Param("tagsSize") tagsSize: Int,
        pageable: Pageable,
    ): Page<Group>

    // 배치 삭제 메서드들
    @Modifying
    @Query("UPDATE Group g SET g.deletedAt = CURRENT_TIMESTAMP WHERE g.id IN :groupIds")
    fun softDeleteByIds(
        @Param("groupIds") groupIds: List<Long>,
    ): Int

    // H2 호환 버전 - 최대 3단계 하위 그룹 조회
    @Query(
        """
        SELECT DISTINCT g.id FROM groups g WHERE
        g.parent_id = :groupId
        OR g.parent_id IN (SELECT g1.id FROM groups g1 WHERE g1.parent_id = :groupId)
        OR g.parent_id IN (
            SELECT g2.id FROM groups g2
            INNER JOIN groups g1 ON g2.parent_id = g1.id
            WHERE g1.parent_id = :groupId
        )
        ORDER BY g.id
    """,
        nativeQuery = true,
    )
    fun findAllDescendantIds(
        @Param("groupId") groupId: Long,
    ): List<Long>
}

@Repository
interface GroupRoleRepository : JpaRepository<GroupRole, Long> {
    fun findByGroupIdAndName(
        groupId: Long,
        name: String,
    ): Optional<GroupRole>

    fun findByGroupId(groupId: Long): List<GroupRole>

    // 배치 삭제 메서드
    @Modifying
    @Query("DELETE FROM GroupRole gr WHERE gr.group.id IN :groupIds")
    fun deleteByGroupIds(
        @Param("groupIds") groupIds: List<Long>,
    ): Int
}

@Repository
interface GroupMemberRepository : JpaRepository<GroupMember, Long> {
    fun findByGroupIdAndUserId(
        groupId: Long,
        userId: Long,
    ): Optional<GroupMember>

    fun countByGroupId(groupId: Long): Long

    fun countByRoleId(roleId: Long): Long

    fun findByGroupId(
        groupId: Long,
        pageable: Pageable,
    ): Page<GroupMember>

    fun findByUserId(userId: Long): List<GroupMember>

    // 내 그룹 목록 조회 (워크스페이스 자동 진입용) - JOIN FETCH 최적화
    @Query(
        """
        SELECT gm FROM GroupMember gm
        JOIN FETCH gm.group g
        JOIN FETCH gm.role r
        LEFT JOIN FETCH r.permissions
        WHERE gm.user.id = :userId
        ORDER BY g.id ASC
    """,
    )
    fun findByUserIdWithDetails(
        @Param("userId") userId: Long,
    ): List<GroupMember>

    // 지도교수 관련 메소드 (특정 권한을 가진 멤버 조회)
    @Query("SELECT gm FROM GroupMember gm WHERE gm.group.id = :groupId AND gm.role.name = '교수'")
    fun findAdvisorsByGroupId(groupId: Long): List<GroupMember>

    // 그룹장 유고시 자동 승계를 위한 후보자 조회 (가입일 오래된 순, 학년 높은 순)
    @Query(
        """
        SELECT gm FROM GroupMember gm
        WHERE gm.group.id = :groupId
        AND gm.role.name != '그룹장'
        AND gm.user.globalRole = 'STUDENT'
        ORDER BY gm.user.academicYear DESC NULLS LAST, gm.joinedAt ASC
    """,
    )
    fun findSuccessionCandidates(groupId: Long): List<GroupMember>

    // 계층구조 포함 멤버 수 집계 (H2 호환 버전)
    @Query(
        """
        SELECT COUNT(DISTINCT gm.user_id)
        FROM group_members gm
        WHERE gm.group_id = :groupId
        OR gm.group_id IN (
            SELECT g1.id FROM groups g1 WHERE g1.parent_id = :groupId
            UNION ALL
            SELECT g2.id FROM groups g2
            INNER JOIN groups g1 ON g2.parent_id = g1.id
            WHERE g1.parent_id = :groupId
            UNION ALL
            SELECT g3.id FROM groups g3
            INNER JOIN groups g2 ON g3.parent_id = g2.id
            INNER JOIN groups g1 ON g2.parent_id = g1.id
            WHERE g1.parent_id = :groupId
        )
    """,
        nativeQuery = true,
    )
    fun countMembersWithHierarchy(groupId: Long): Long

    // 특정 그룹의 모든 상위 그룹 조회 (최대 3단계)
    @Query(
        """
        SELECT DISTINCT g.id FROM groups g WHERE
        (g.id = (SELECT parent_id FROM groups WHERE id = :groupId))
        OR (g.id = (SELECT g2.parent_id FROM groups g2
                    INNER JOIN groups g1 ON g2.id = g1.parent_id
                    WHERE g1.id = :groupId))
        OR (g.id = (SELECT g3.parent_id FROM groups g3
                    INNER JOIN groups g2 ON g3.id = g2.parent_id
                    INNER JOIN groups g1 ON g2.id = g1.parent_id
                    WHERE g1.id = :groupId))
        ORDER BY g.id
    """,
        nativeQuery = true,
    )
    fun findParentGroupIds(groupId: Long): List<Long>

    fun findByGroupIdOrderByJoinedAtAsc(groupId: Long): List<GroupMember>

    // 배치 삭제 메서드
    @Modifying
    @Query("DELETE FROM GroupMember gm WHERE gm.group.id IN :groupIds")
    fun deleteByGroupIds(
        @Param("groupIds") groupIds: List<Long>,
    ): Int

    // 배치 가입을 위한 유틸리티 메서드들
    @Query("SELECT gm.group.id FROM GroupMember gm WHERE gm.user.id = :userId AND gm.group.id IN :groupIds")
    fun findExistingMemberships(
        @Param("userId") userId: Long,
        @Param("groupIds") groupIds: List<Long>,
    ): List<Long>
}

@Repository
interface GroupJoinRequestRepository : JpaRepository<GroupJoinRequest, Long> {
    fun findByGroupIdAndUserId(
        groupId: Long,
        userId: Long,
    ): Optional<GroupJoinRequest>

    fun findByGroupIdAndStatus(
        groupId: Long,
        status: GroupJoinRequestStatus,
    ): List<GroupJoinRequest>

    fun findByUserIdAndStatus(
        userId: Long,
        status: GroupJoinRequestStatus,
    ): List<GroupJoinRequest>

    fun findByGroupId(groupId: Long): List<GroupJoinRequest>

    // 추가: 상태별 개수 카운트
    fun countByGroupIdAndStatus(
        groupId: Long,
        status: GroupJoinRequestStatus,
    ): Long

    // 배치 삭제 메서드
    @Modifying
    @Query("DELETE FROM GroupJoinRequest gjr WHERE gjr.group.id IN :groupIds")
    fun deleteByGroupIds(
        @Param("groupIds") groupIds: List<Long>,
    ): Int
}

@Repository
interface SubGroupRequestRepository : JpaRepository<SubGroupRequest, Long> {
    fun findByParentGroupIdAndStatus(
        parentGroupId: Long,
        status: SubGroupRequestStatus,
    ): List<SubGroupRequest>

    fun findByRequesterIdAndStatus(
        requesterId: Long,
        status: SubGroupRequestStatus,
    ): List<SubGroupRequest>

    fun findByParentGroupId(parentGroupId: Long): List<SubGroupRequest>

    // 배치 삭제 메서드
    @Modifying
    @Query("DELETE FROM SubGroupRequest sgr WHERE sgr.parentGroup.id IN :groupIds")
    fun deleteByParentGroupIds(
        @Param("groupIds") groupIds: List<Long>,
    ): Int
}
