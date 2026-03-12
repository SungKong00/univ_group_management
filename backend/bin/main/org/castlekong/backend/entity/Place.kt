package org.castlekong.backend.entity

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.FetchType
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import jakarta.persistence.Id
import jakarta.persistence.Index
import jakarta.persistence.JoinColumn
import jakarta.persistence.ManyToOne
import jakarta.persistence.Table
import jakarta.persistence.UniqueConstraint
import java.time.LocalDateTime

/**
 * Place (장소)
 *
 * 대학 내 장소(강의실, 동아리방 등)를 나타내는 엔티티
 * - 관리 주체 그룹이 장소를 등록하고 관리
 * - Soft delete 지원 (삭제 시 deletedAt 설정)
 * - 건물-방 번호로 고유 식별
 */
@Entity
@Table(
    name = "places",
    uniqueConstraints = [
        UniqueConstraint(
            name = "uk_place_location",
            columnNames = ["building", "room_number", "deleted_at"],
        ),
    ],
    indexes = [
        Index(name = "idx_place_managing_group", columnList = "managing_group_id"),
        Index(name = "idx_place_building", columnList = "building"),
        Index(name = "idx_place_deleted_at", columnList = "deleted_at"),
    ],
)
class Place(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long = 0,
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "managing_group_id", nullable = false)
    var managingGroup: Group,
    @Column(nullable = false, length = 100)
    var building: String,
    @Column(name = "room_number", nullable = false, length = 50)
    var roomNumber: String,
    @Column(length = 100)
    var alias: String? = null,
    @Column(nullable = true)
    var capacity: Int? = null,
    @Column(name = "deleted_at")
    var deletedAt: LocalDateTime? = null,
    @Column(name = "created_at", nullable = false, updatable = false)
    var createdAt: LocalDateTime = LocalDateTime.now(),
    @Column(name = "updated_at", nullable = false)
    var updatedAt: LocalDateTime = LocalDateTime.now(),
) {
    /**
     * Soft delete 여부 확인
     */
    fun isDeleted(): Boolean = deletedAt != null

    /**
     * 장소 표시명 (별칭 우선)
     * 예: "AISC랩실 (60주년 기념관-18203)" or "60주년 기념관-18203"
     */
    fun getDisplayName(): String {
        val location = "$building-$roomNumber"
        return if (alias != null) "$alias ($location)" else location
    }

    /**
     * Soft delete 처리
     */
    fun markAsDeleted(): Place {
        this.deletedAt = LocalDateTime.now()
        return this
    }

    /**
     * 장소 정보 업데이트
     */
    fun updateInfo(
        alias: String?,
        capacity: Int?,
    ): Place {
        this.alias = alias
        this.capacity = capacity
        this.updatedAt = LocalDateTime.now()
        return this
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is Place) return false
        return id != 0L && id == other.id
    }

    override fun hashCode(): Int = id.hashCode()

    override fun toString(): String {
        return "Place(id=$id, building='$building', roomNumber='$roomNumber', alias=$alias)"
    }
}
