package org.castlekong.backend.repository

import org.castlekong.backend.entity.PlaceUsageGroup
import org.castlekong.backend.entity.UsageStatus
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.util.Optional

/**
 * PlaceUsageGroupRepository
 *
 * 장소 사용 그룹 조회 및 관리를 위한 Repository
 */
@Repository
interface PlaceUsageGroupRepository : JpaRepository<PlaceUsageGroup, Long> {

    /**
     * 장소의 모든 사용 그룹 조회 (그룹 정보 포함)
     */
    @Query("""
        SELECT pug FROM PlaceUsageGroup pug
        JOIN FETCH pug.group
        WHERE pug.place.id = :placeId
        ORDER BY pug.status, pug.createdAt
    """)
    fun findByPlaceIdWithGroup(@Param("placeId") placeId: Long): List<PlaceUsageGroup>

    /**
     * 승인된 사용 그룹만 조회
     */
    @Query("""
        SELECT pug FROM PlaceUsageGroup pug
        WHERE pug.place.id = :placeId
        AND pug.status = 'APPROVED'
    """)
    fun findApprovedByPlaceId(@Param("placeId") placeId: Long): List<PlaceUsageGroup>

    /**
     * 특정 그룹의 장소 사용 권한 조회
     */
    @Query("""
        SELECT pug FROM PlaceUsageGroup pug
        WHERE pug.place.id = :placeId
        AND pug.group.id = :groupId
    """)
    fun findByPlaceIdAndGroupId(
        @Param("placeId") placeId: Long,
        @Param("groupId") groupId: Long
    ): Optional<PlaceUsageGroup>

    /**
     * 그룹이 승인받은 모든 장소 조회 (장소 정보 포함)
     */
    @Query("""
        SELECT pug FROM PlaceUsageGroup pug
        JOIN FETCH pug.place p
        WHERE pug.group.id = :groupId
        AND pug.status = 'APPROVED'
        AND p.deletedAt IS NULL
        ORDER BY p.building, p.roomNumber
    """)
    fun findApprovedPlacesByGroupId(@Param("groupId") groupId: Long): List<PlaceUsageGroup>

    /**
     * 그룹의 모든 사용 신청 조회 (모든 상태 포함)
     */
    @Query("""
        SELECT pug FROM PlaceUsageGroup pug
        JOIN FETCH pug.place
        WHERE pug.group.id = :groupId
        ORDER BY pug.createdAt DESC
    """)
    fun findByGroupIdWithPlace(@Param("groupId") groupId: Long): List<PlaceUsageGroup>

    /**
     * 대기 중인 신청 조회
     */
    @Query("""
        SELECT pug FROM PlaceUsageGroup pug
        JOIN FETCH pug.place
        JOIN FETCH pug.group
        WHERE pug.place.id = :placeId
        AND pug.status = 'PENDING'
        ORDER BY pug.createdAt
    """)
    fun findPendingByPlaceId(@Param("placeId") placeId: Long): List<PlaceUsageGroup>

    /**
     * 그룹이 특정 장소에 대해 승인받았는지 확인
     */
    @Query("""
        SELECT CASE WHEN COUNT(pug) > 0 THEN true ELSE false END
        FROM PlaceUsageGroup pug
        WHERE pug.place.id = :placeId
        AND pug.group.id = :groupId
        AND pug.status = 'APPROVED'
    """)
    fun isApprovedForPlace(
        @Param("placeId") placeId: Long,
        @Param("groupId") groupId: Long
    ): Boolean
}
