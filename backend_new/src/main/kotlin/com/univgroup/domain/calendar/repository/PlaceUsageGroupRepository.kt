package com.univgroup.domain.calendar.repository

import com.univgroup.domain.calendar.entity.PlaceUsageGroup
import com.univgroup.domain.calendar.entity.UsageStatus
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

/**
 * 장소 사용 그룹 Repository
 */
@Repository
interface PlaceUsageGroupRepository : JpaRepository<PlaceUsageGroup, Long> {
    /**
     * 장소 ID로 모든 사용 그룹 조회
     */
    fun findByPlaceId(placeId: Long): List<PlaceUsageGroup>

    /**
     * 그룹 ID로 모든 사용 장소 조회
     */
    fun findByGroupId(groupId: Long): List<PlaceUsageGroup>

    /**
     * 장소 ID와 그룹 ID로 사용 권한 조회
     */
    fun findByPlaceIdAndGroupId(placeId: Long, groupId: Long): PlaceUsageGroup?

    /**
     * 장소 ID와 승인 상태로 사용 그룹 조회
     */
    fun findByPlaceIdAndStatus(placeId: Long, status: UsageStatus): List<PlaceUsageGroup>

    /**
     * 장소와 그룹의 승인된 사용 권한 존재 여부 확인
     */
    fun existsByPlaceIdAndGroupIdAndStatus(
        placeId: Long,
        groupId: Long,
        status: UsageStatus = UsageStatus.APPROVED
    ): Boolean

    /**
     * 장소의 모든 사용 그룹 삭제
     */
    fun deleteByPlaceId(placeId: Long)

    /**
     * 그룹의 모든 사용 장소 삭제
     */
    fun deleteByGroupId(groupId: Long)
}
