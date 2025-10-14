package org.castlekong.backend.repository

import org.castlekong.backend.entity.Place
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.util.Optional

/**
 * PlaceRepository
 *
 * 장소 조회 및 관리를 위한 Repository
 * - Soft delete 지원 (deletedAt IS NULL 조건 활용)
 * - 건물별, 관리 주체별 조회 지원
 */
@Repository
interface PlaceRepository : JpaRepository<Place, Long> {
    /**
     * 활성 장소만 조회 (Soft delete 제외)
     */
    @Query("SELECT p FROM Place p WHERE p.deletedAt IS NULL ORDER BY p.building, p.roomNumber")
    fun findAllActive(): List<Place>

    /**
     * 건물별 활성 장소 조회
     */
    @Query(
        """
        SELECT p FROM Place p
        WHERE p.building = :building
        AND p.deletedAt IS NULL
        ORDER BY p.roomNumber
    """,
    )
    fun findActiveByBuilding(
        @Param("building") building: String,
    ): List<Place>

    /**
     * 관리 주체 그룹으로 조회
     */
    @Query(
        """
        SELECT p FROM Place p
        JOIN FETCH p.managingGroup
        WHERE p.managingGroup.id = :groupId
        AND p.deletedAt IS NULL
        ORDER BY p.building, p.roomNumber
    """,
    )
    fun findByManagingGroupIdWithGroup(
        @Param("groupId") groupId: Long,
    ): List<Place>

    /**
     * 건물-방번호로 조회 (중복 체크용)
     */
    @Query(
        """
        SELECT p FROM Place p
        WHERE p.building = :building
        AND p.roomNumber = :roomNumber
        AND p.deletedAt IS NULL
    """,
    )
    fun findByBuildingAndRoomNumber(
        @Param("building") building: String,
        @Param("roomNumber") roomNumber: String,
    ): Optional<Place>

    /**
     * ID로 활성 장소 조회 (Soft delete 제외)
     */
    @Query("SELECT p FROM Place p WHERE p.id = :id AND p.deletedAt IS NULL")
    fun findActiveById(
        @Param("id") id: Long,
    ): Optional<Place>

    /**
     * ID로 장소 조회 (관리 주체 포함, Fetch Join)
     */
    @Query(
        """
        SELECT p FROM Place p
        JOIN FETCH p.managingGroup
        WHERE p.id = :id
        AND p.deletedAt IS NULL
    """,
    )
    fun findActiveByIdWithManagingGroup(
        @Param("id") id: Long,
    ): Optional<Place>

    /**
     * 건물 목록 조회 (중복 제거)
     */
    @Query(
        """
        SELECT DISTINCT p.building FROM Place p
        WHERE p.deletedAt IS NULL
        ORDER BY p.building
    """,
    )
    fun findAllBuildings(): List<String>

    /**
     * 특정 그룹이 예약 가능한 장소 목록 조회 (사용 승인 또는 직접 관리)
     */
    @Query(
        """
        SELECT p FROM Place p WHERE p.id IN (
            SELECT ug.place.id FROM PlaceUsageGroup ug
            WHERE ug.group.id = :groupId
            AND ug.status = org.castlekong.backend.entity.UsageStatus.APPROVED
            AND ug.place.deletedAt IS NULL
        ) OR p.id IN (
            SELECT p2.id FROM Place p2
            WHERE p2.managingGroup.id = :groupId
            AND p2.deletedAt IS NULL
        )
        ORDER BY p.building, p.roomNumber
    """,
    )
    fun findReservablePlacesByGroupId(
        @Param("groupId") groupId: Long,
    ): List<Place>
}
