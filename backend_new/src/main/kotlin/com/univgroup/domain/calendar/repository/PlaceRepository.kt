package com.univgroup.domain.calendar.repository

import com.univgroup.domain.calendar.entity.Place
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.stereotype.Repository

/**
 * 장소 Repository
 */
@Repository
interface PlaceRepository : JpaRepository<Place, Long> {
    /**
     * 관리 그룹 ID로 모든 장소 조회
     */
    fun findByManagedByGroupId(managedByGroupId: Long): List<Place>

    /**
     * 장소명으로 검색
     */
    fun findByNameContaining(name: String): List<Place>

    /**
     * 활성화된 장소만 조회
     */
    @Query("SELECT p FROM Place p WHERE p.deletedAt IS NULL")
    fun findAllActive(): List<Place>

    /**
     * 그룹이 관리하는 활성화된 장소 조회
     */
    @Query("SELECT p FROM Place p WHERE p.managedByGroup.id = :groupId AND p.deletedAt IS NULL")
    fun findActiveByGroupId(groupId: Long): List<Place>

    /**
     * 장소가 삭제되지 않았는지 확인
     */
    @Query("SELECT CASE WHEN p.deletedAt IS NULL THEN true ELSE false END FROM Place p WHERE p.id = :id")
    fun isActive(id: Long): Boolean
}
