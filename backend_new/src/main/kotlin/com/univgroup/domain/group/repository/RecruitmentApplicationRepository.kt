package com.univgroup.domain.group.repository

import com.univgroup.domain.group.entity.RecruitmentApplication
import com.univgroup.domain.group.entity.RequestStatus
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

/**
 * 모집 지원 Repository
 */
@Repository
interface RecruitmentApplicationRepository : JpaRepository<RecruitmentApplication, Long> {
    /**
     * 모집 공고 ID로 모든 지원 조회
     */
    fun findByRecruitmentId(recruitmentId: Long): List<RecruitmentApplication>

    /**
     * 사용자 ID로 모든 지원 조회
     */
    fun findByUserId(userId: Long): List<RecruitmentApplication>

    /**
     * 모집 공고 ID와 사용자 ID로 지원 조회
     */
    fun findByRecruitmentIdAndUserId(recruitmentId: Long, userId: Long): RecruitmentApplication?

    /**
     * 모집 공고 ID와 상태로 지원 조회
     */
    fun findByRecruitmentIdAndStatus(recruitmentId: Long, status: RequestStatus): List<RecruitmentApplication>

    /**
     * 사용자 ID와 상태로 지원 조회
     */
    fun findByUserIdAndStatus(userId: Long, status: RequestStatus): List<RecruitmentApplication>

    /**
     * 모집 공고와 사용자의 지원 존재 여부 확인
     */
    fun existsByRecruitmentIdAndUserId(recruitmentId: Long, userId: Long): Boolean

    /**
     * 모집 공고와 사용자의 PENDING 상태 지원 존재 여부 확인
     */
    fun existsByRecruitmentIdAndUserIdAndStatus(
        recruitmentId: Long,
        userId: Long,
        status: RequestStatus = RequestStatus.PENDING
    ): Boolean

    /**
     * 모집 공고의 모든 지원 삭제
     */
    fun deleteByRecruitmentId(recruitmentId: Long)
}
