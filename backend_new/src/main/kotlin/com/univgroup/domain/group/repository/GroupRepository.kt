package com.univgroup.domain.group.repository

import com.univgroup.domain.group.entity.Group
import com.univgroup.domain.group.entity.GroupType
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository

@Repository
interface GroupRepository : JpaRepository<Group, Long> {
    // ===== 기본 조회 =====

    fun findByIdAndOwnerId(
        id: Long,
        ownerId: Long,
    ): Group?

    // ===== 계층 구조 조회 =====

    fun findByParentId(parentId: Long): List<Group>

    fun findByParentIdIsNull(): List<Group>

    @Query(
        """
        SELECT g FROM Group g
        WHERE g.parent.id = :parentId
        ORDER BY g.name
        """,
    )
    fun findChildrenOrderByName(
        @Param("parentId") parentId: Long,
    ): List<Group>

    // ===== 검색 =====

    @Query(
        """
        SELECT g FROM Group g
        WHERE (
            LOWER(g.name) LIKE LOWER(CONCAT('%', :keyword, '%'))
            OR LOWER(g.description) LIKE LOWER(CONCAT('%', :keyword, '%'))
        )
        ORDER BY g.name
        """,
    )
    fun searchByKeyword(
        @Param("keyword") keyword: String,
        pageable: Pageable,
    ): Page<Group>

    // ===== 대학 구조 조회 =====

    fun findByUniversityAndGroupType(
        university: String,
        groupType: GroupType,
    ): List<Group>

    @Query(
        """
        SELECT g FROM Group g
        WHERE g.university = :university
        AND g.college = :college
        AND g.groupType = :groupType
        """,
    )
    fun findByUniversityAndCollegeAndGroupType(
        @Param("university") university: String,
        @Param("college") college: String,
        @Param("groupType") groupType: GroupType,
    ): List<Group>

    // ===== 소유자 기준 조회 =====

    fun findByOwnerId(ownerId: Long): List<Group>

    @Query(
        """
        SELECT g FROM Group g
        WHERE g.owner.id = :ownerId
        ORDER BY g.createdAt DESC
        """,
    )
    fun findByOwnerIdOrderByCreatedAtDesc(
        @Param("ownerId") ownerId: Long,
    ): List<Group>

    // ===== 존재 여부 확인 =====

    fun existsByParentIdAndName(
        parentId: Long?,
        name: String,
    ): Boolean
}
