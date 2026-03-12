package com.univgroup.domain.calendar.entity

import com.univgroup.domain.group.entity.Group
import jakarta.persistence.*
import java.time.LocalDateTime

/**
 * 장소 엔티티
 *
 * 대학 내 장소(강의실, 동아리방 등)를 나타낸다.
 * 관리 주체 그룹이 장소를 등록하고 관리한다.
 */
@Entity
@Table(
    name = "places",
    uniqueConstraints = [
        UniqueConstraint(columnNames = ["building", "room_number", "deleted_at"])
    ],
    indexes = [
        Index(name = "idx_place_managing_group", columnList = "managing_group_id"),
        Index(name = "idx_place_building", columnList = "building"),
        Index(name = "idx_place_deleted_at", columnList = "deleted_at")
    ]
)
data class Place(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "managing_group_id", nullable = false)
    val managingGroup: Group,

    @Column(nullable = false, length = 100)
    val building: String,

    @Column(name = "room_number", nullable = false, length = 50)
    val roomNumber: String,

    @Column(length = 100)
    val alias: String? = null,

    @Column
    val capacity: Int? = null,

    @Column(name = "deleted_at")
    val deletedAt: LocalDateTime? = null,

    @Column(name = "created_at", nullable = false, updatable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now()
) {
    override fun equals(other: Any?) = other is Place && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()
}
