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
import jakarta.persistence.OneToOne
import jakarta.persistence.Table
import jakarta.persistence.Version
import java.time.LocalDateTime

/**
 * PlaceReservation (장소 예약)
 *
 * GroupEvent와 1:1 관계로 연결된 장소 예약 정보
 * - GroupEvent는 필수 (독립 예약도 GroupEvent를 통해 생성)
 * - 낙관적 락(@Version)으로 동시성 제어
 * - Hard delete (Soft delete 불필요)
 *
 * **설계 결정사항**:
 * - GroupEvent 삭제 시 CASCADE 삭제
 * - Place 참조는 ON DELETE RESTRICT (예약 확인 필요)
 * - 예약 수정 가능
 * - 취소 권한: 본인 OR 관리 그룹의 CALENDAR_MANAGE
 */
@Entity
@Table(
    name = "place_reservations",
    indexes = [
        Index(name = "idx_reservation_place", columnList = "place_id"),
        Index(name = "idx_reservation_event", columnList = "group_event_id"),
        Index(name = "idx_reservation_user", columnList = "reserved_by"),
    ],
)
class PlaceReservation(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long = 0,
    /**
     * 연결된 그룹 일정 (1:1 관계)
     * - UNIQUE 제약으로 1:1 관계 보장
     * - GroupEvent 삭제 시 CASCADE 삭제
     */
    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "group_event_id", nullable = false, unique = true)
    var groupEvent: GroupEvent,
    /**
     * 예약된 장소 (N:1 관계)
     * - 한 장소는 여러 예약을 가질 수 있음
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "place_id", nullable = false)
    var place: Place,
    /**
     * 예약한 사용자
     * - GroupEvent의 creator와 동일할 수도 있지만 별도 관리
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "reserved_by", nullable = false)
    var reservedBy: User,
    /**
     * 낙관적 락 버전 (동시성 제어)
     * - 동시 예약 충돌 방지
     * - OptimisticLockException 발생 시 충돌 처리
     */
    @Version
    @Column(nullable = false)
    var version: Long = 0,
    @Column(name = "created_at", nullable = false, updatable = false)
    var createdAt: LocalDateTime = LocalDateTime.now(),
    @Column(name = "updated_at", nullable = false)
    var updatedAt: LocalDateTime = LocalDateTime.now(),
) {
    /**
     * 예약 정보 업데이트
     * - Place 변경은 허용하지 않음 (별도 메서드로 분리 가능)
     */
    fun updateReservation(newPlace: Place? = null): PlaceReservation {
        newPlace?.let { this.place = it }
        this.updatedAt = LocalDateTime.now()
        return this
    }

    /**
     * 예약 시간 정보 (GroupEvent 기반)
     */
    fun getStartDateTime(): LocalDateTime = groupEvent.startDate

    fun getEndDateTime(): LocalDateTime = groupEvent.endDate

    fun getTitle(): String = groupEvent.title

    /**
     * 시간대 겹침 확인
     */
    fun overlapsWith(
        startDate: LocalDateTime,
        endDate: LocalDateTime,
    ): Boolean {
        return groupEvent.startDate < endDate && groupEvent.endDate > startDate
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is PlaceReservation) return false
        return id != 0L && id == other.id
    }

    override fun hashCode(): Int = id.hashCode()

    override fun toString(): String {
        return "PlaceReservation(id=$id, placeId=${place.id}, eventId=${groupEvent.id}, version=$version)"
    }
}
