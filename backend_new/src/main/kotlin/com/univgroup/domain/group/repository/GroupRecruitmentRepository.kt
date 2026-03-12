package com.univgroup.domain.group.repository

import com.univgroup.domain.group.entity.GroupRecruitment
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.stereotype.Repository
import java.time.LocalDateTime

/**
 * 그룹 모집 공고 Repository
 */
@Repository
interface GroupRecruitmentRepository : JpaRepository<GroupRecruitment, Long> {
    /**
     * 그룹 ID로 모든 모집 공고 조회
     */
    fun findByGroupId(groupId: Long): List<GroupRecruitment>

    /**
     * 그룹 ID와 활성화 상태로 모집 공고 조회
     */
    fun findByGroupIdAndIsActive(groupId: Long, isActive: Boolean): List<GroupRecruitment>

    /**
     * 활성화된 모든 모집 공고 조회
     */
    fun findByIsActive(isActive: Boolean): List<GroupRecruitment>

    /**
     * 모집 기간 내의 활성화된 공고 조회
     */
    @Query("""
        SELECT r FROM GroupRecruitment r
        WHERE r.isActive = true
        AND r.startDate <= :now
        AND r.endDate >= :now
    """)
    fun findActiveRecruitments(now: LocalDateTime): List<GroupRecruitment>

    /**
     * 그룹의 활성화된 모집 공고 존재 여부 확인
     */
    fun existsByGroupIdAndIsActive(groupId: Long, isActive: Boolean): Boolean

    /**
     * 그룹의 모든 모집 공고 삭제
     */
    fun deleteByGroupId(groupId: Long)
}
