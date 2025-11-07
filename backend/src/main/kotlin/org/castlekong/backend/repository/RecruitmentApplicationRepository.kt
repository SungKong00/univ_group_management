package org.castlekong.backend.repository

import org.castlekong.backend.entity.ApplicationStatus
import org.castlekong.backend.entity.RecruitmentApplication
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.util.Optional

@Repository
interface RecruitmentApplicationRepository : JpaRepository<RecruitmentApplication, Long> {
    // 모집별 지원서 조회
    fun findByRecruitmentId(recruitmentId: Long): List<RecruitmentApplication>

    // 모집별 지원서 페이징 조회
    fun findByRecruitmentIdOrderByAppliedAtDesc(
        recruitmentId: Long,
        pageable: Pageable,
    ): Page<RecruitmentApplication>

    // 모집별 상태별 지원서 조회
    fun findByRecruitmentIdAndStatus(
        recruitmentId: Long,
        status: ApplicationStatus,
    ): List<RecruitmentApplication>

    // 사용자별 지원서 조회
    fun findByApplicantIdOrderByAppliedAtDesc(applicantId: Long): List<RecruitmentApplication>

    // 특정 사용자의 특정 모집에 대한 지원서 조회
    fun findByRecruitmentIdAndApplicantId(
        recruitmentId: Long,
        applicantId: Long,
    ): Optional<RecruitmentApplication>

    // 모집별 지원서 수 카운트
    fun countByRecruitmentId(recruitmentId: Long): Long

    // 모집별 상태별 지원서 수 카운트
    fun countByRecruitmentIdAndStatus(
        recruitmentId: Long,
        status: ApplicationStatus,
    ): Long

    // 사용자가 지원한 모집 ID 목록 (중복 지원 방지용)
    @Query(
        """
        SELECT ra.recruitment.id FROM RecruitmentApplication ra
        WHERE ra.applicant.id = :applicantId
        AND ra.status IN ('PENDING', 'APPROVED')
    """,
    )
    fun findActiveRecruitmentIdsByApplicantId(
        @Param("applicantId") applicantId: Long,
    ): List<Long>

    // 심사자별 처리한 지원서 조회
    fun findByReviewedByIdOrderByReviewedAtDesc(reviewedById: Long): List<RecruitmentApplication>

    // 그룹의 모든 모집에 대한 지원서 조회 (그룹 관리자용)
    @Query(
        """
        SELECT ra FROM RecruitmentApplication ra
        JOIN ra.recruitment r
        WHERE r.group.id = :groupId
        ORDER BY ra.appliedAt DESC
    """,
    )
    fun findByGroupId(
        @Param("groupId") groupId: Long,
    ): List<RecruitmentApplication>

    // 대기 중인 지원서 수 (알림용)
    @Query(
        """
        SELECT COUNT(ra) FROM RecruitmentApplication ra
        JOIN ra.recruitment r
        WHERE r.group.id = :groupId
        AND ra.status = 'PENDING'
    """,
    )
    fun countPendingApplicationsByGroupId(
        @Param("groupId") groupId: Long,
    ): Long
}
