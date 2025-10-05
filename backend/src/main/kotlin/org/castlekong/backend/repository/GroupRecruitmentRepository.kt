package org.castlekong.backend.repository

import org.castlekong.backend.entity.GroupRecruitment
import org.castlekong.backend.entity.RecruitmentStatus
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.time.LocalDateTime

@Repository
interface GroupRecruitmentRepository : JpaRepository<GroupRecruitment, Long> {

    // ID로 조회 (연관 엔티티 FETCH JOIN)
    @Query("""
        SELECT r FROM GroupRecruitment r
        JOIN FETCH r.group
        JOIN FETCH r.createdBy
        WHERE r.id = :id
    """)
    fun findByIdWithRelations(@Param("id") id: Long): GroupRecruitment?

    // 그룹별 모집 게시글 조회
    fun findByGroupId(groupId: Long): List<GroupRecruitment>

    // 그룹별 모집 게시글 페이징 조회
    @Query("""
        SELECT DISTINCT r FROM GroupRecruitment r
        JOIN FETCH r.group g
        JOIN FETCH r.createdBy
        WHERE g.id = :groupId
        AND r.status = :status
        ORDER BY r.createdAt DESC
    """,
    countQuery = """
        SELECT COUNT(DISTINCT r) FROM GroupRecruitment r
        WHERE r.group.id = :groupId
        AND r.status = :status
    """)
    fun findByGroupIdAndStatus(
        @Param("groupId") groupId: Long,
        @Param("status") status: RecruitmentStatus,
        pageable: Pageable
    ): Page<GroupRecruitment>

    // 활성 모집 게시글 조회 (현재 모집 중)
    @Query("""
        SELECT r FROM GroupRecruitment r
        WHERE r.status = 'OPEN'
        AND r.recruitmentStartDate <= :now
        AND (r.recruitmentEndDate IS NULL OR r.recruitmentEndDate > :now)
        ORDER BY r.createdAt DESC
    """)
    fun findActiveRecruitments(@Param("now") now: LocalDateTime = LocalDateTime.now()): List<GroupRecruitment>

    // 전체 모집 게시글 탐색 (공개)
    @Query("""
        SELECT DISTINCT r FROM GroupRecruitment r
        JOIN FETCH r.group g
        JOIN FETCH r.createdBy
        WHERE r.status = 'OPEN'
        AND g.visibility = 'PUBLIC'
        AND r.recruitmentStartDate <= :now
        AND (r.recruitmentEndDate IS NULL OR r.recruitmentEndDate > :now)
        ORDER BY r.createdAt DESC
    """)
    fun findPublicActiveRecruitments(
        @Param("now") now: LocalDateTime = LocalDateTime.now(),
        pageable: Pageable
    ): Page<GroupRecruitment>

    // 키워드 검색
    @Query("""
        SELECT DISTINCT r FROM GroupRecruitment r
        JOIN FETCH r.group g
        JOIN FETCH r.createdBy
        WHERE r.status = 'OPEN'
        AND g.visibility = 'PUBLIC'
        AND r.recruitmentStartDate <= :now
        AND (r.recruitmentEndDate IS NULL OR r.recruitmentEndDate > :now)
        AND (
            LOWER(r.title) LIKE LOWER(CONCAT('%', :keyword, '%')) OR
            LOWER(r.content) LIKE LOWER(CONCAT('%', :keyword, '%')) OR
            LOWER(g.name) LIKE LOWER(CONCAT('%', :keyword, '%'))
        )
        ORDER BY r.createdAt DESC
    """)
    fun searchActiveRecruitments(
        @Param("keyword") keyword: String,
        @Param("now") now: LocalDateTime = LocalDateTime.now(),
        pageable: Pageable
    ): Page<GroupRecruitment>

    // 생성자별 모집 게시글 조회
    fun findByCreatedByIdOrderByCreatedAtDesc(createdById: Long): List<GroupRecruitment>

    // 마감 예정 모집 게시글 조회 (알림용)
    @Query("""
        SELECT r FROM GroupRecruitment r
        WHERE r.status = 'OPEN'
        AND r.recruitmentEndDate IS NOT NULL
        AND r.recruitmentEndDate BETWEEN :start AND :end
    """)
    fun findRecruitmentsDueSoon(
        @Param("start") start: LocalDateTime,
        @Param("end") end: LocalDateTime
    ): List<GroupRecruitment>
}