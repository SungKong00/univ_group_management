package org.castlekong.backend.repository

import org.castlekong.backend.entity.Group
import org.castlekong.backend.entity.GroupMember
import org.castlekong.backend.entity.GroupRole
import org.castlekong.backend.entity.GroupJoinRequest
import org.castlekong.backend.entity.GroupJoinRequestStatus
import org.castlekong.backend.entity.SubGroupRequest
import org.castlekong.backend.entity.SubGroupRequestStatus
import org.castlekong.backend.entity.GroupMemberPermissionOverride
import org.castlekong.backend.entity.GroupVisibility
import org.castlekong.backend.entity.GroupType
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.stereotype.Repository
import java.util.*
import org.springframework.data.repository.query.Param

@Repository
interface GroupRepository : JpaRepository<Group, Long> {
    fun findByParentId(parentId: Long): List<Group>
    fun findByParentIsNull(): List<Group>  // 최상위 그룹 조회
    fun findByUniversityAndCollegeAndDepartment(university: String?, college: String?, department: String?): List<Group>
    fun findByDeletedAtIsNull(pageable: Pageable): Page<Group>

    @Query(
        """
        SELECT DISTINCT g FROM Group g
        LEFT JOIN g.tags t
        WHERE (g.deletedAt IS NULL)
        AND (:recruiting IS NULL OR g.isRecruiting = :recruiting)
        AND (:visibility IS NULL OR g.visibility = :visibility)
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
        """
    )
    fun search(
        @Param("recruiting") recruiting: Boolean?,
        @Param("visibility") visibility: GroupVisibility?,
        @Param("groupType") groupType: GroupType?,
        @Param("university") university: String?,
        @Param("college") college: String?,
        @Param("department") department: String?,
        @Param("q") q: String?,
        @Param("tags") tags: Set<String>,
        @Param("tagsSize") tagsSize: Int,
        pageable: Pageable
    ): Page<Group>
}

@Repository
interface GroupRoleRepository : JpaRepository<GroupRole, Long> {
    fun findByGroupIdAndName(groupId: Long, name: String): Optional<GroupRole>
    fun findByGroupId(groupId: Long): List<GroupRole>
}

@Repository
interface GroupMemberRepository : JpaRepository<GroupMember, Long> {
    fun findByGroupIdAndUserId(groupId: Long, userId: Long): Optional<GroupMember>
    fun countByGroupId(groupId: Long): Long
    fun findByGroupId(groupId: Long, pageable: Pageable): Page<GroupMember>
    fun findByUserId(userId: Long): List<GroupMember>
    
    // 지도교수 관련 메소드 (특정 권한을 가진 멤버 조회)
    @Query("SELECT gm FROM GroupMember gm WHERE gm.group.id = :groupId AND gm.role.name = 'PROFESSOR'")
    fun findProfessorsByGroupId(groupId: Long): List<GroupMember>
    
    // 그룹장 유고시 자동 승계를 위한 후보자 조회 (가입일 오래된 순, 학년 높은 순)
    @Query("""
        SELECT gm FROM GroupMember gm 
        WHERE gm.group.id = :groupId 
        AND gm.role.name != 'OWNER' 
        AND gm.user.globalRole = 'STUDENT'
        ORDER BY gm.user.academicYear DESC NULLS LAST, gm.joinedAt ASC
    """)
    fun findSuccessionCandidates(groupId: Long): List<GroupMember>
}

@Repository
interface GroupJoinRequestRepository : JpaRepository<GroupJoinRequest, Long> {
    fun findByGroupIdAndUserId(groupId: Long, userId: Long): Optional<GroupJoinRequest>
    fun findByGroupIdAndStatus(groupId: Long, status: GroupJoinRequestStatus): List<GroupJoinRequest>
    fun findByUserIdAndStatus(userId: Long, status: GroupJoinRequestStatus): List<GroupJoinRequest>
    fun findByGroupId(groupId: Long): List<GroupJoinRequest>
}

@Repository
interface SubGroupRequestRepository : JpaRepository<SubGroupRequest, Long> {
    fun findByParentGroupIdAndStatus(parentGroupId: Long, status: SubGroupRequestStatus): List<SubGroupRequest>
    fun findByRequesterIdAndStatus(requesterId: Long, status: SubGroupRequestStatus): List<SubGroupRequest>
    fun findByParentGroupId(parentGroupId: Long): List<SubGroupRequest>
}

@Repository
interface GroupMemberPermissionOverrideRepository : JpaRepository<GroupMemberPermissionOverride, Long> {
    fun findByGroupIdAndUserId(groupId: Long, userId: Long): Optional<GroupMemberPermissionOverride>
}
