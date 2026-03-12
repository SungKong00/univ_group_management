package com.univgroup.domain.group.entity

import jakarta.persistence.*
import java.time.LocalDateTime

/**
 * 그룹 모집 공고 엔티티
 *
 * 그룹이 새로운 멤버를 모집하기 위한 공고를 나타낸다.
 */
@Entity
@Table(name = "group_recruitments")
data class GroupRecruitment(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "group_id", nullable = false)
    val group: Group,

    @Column(nullable = false, length = 200)
    val title: String,

    @Column(columnDefinition = "TEXT")
    val description: String? = null,

    @Column(name = "max_applicants")
    val maxApplicants: Int? = null,

    @Column(name = "deadline")
    val deadline: LocalDateTime? = null,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    val status: RecruitmentStatus = RecruitmentStatus.OPEN,

    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now()
) {
    override fun equals(other: Any?) = other is GroupRecruitment && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()
}

/**
 * 모집 상태
 */
enum class RecruitmentStatus {
    OPEN,      // 모집 중
    CLOSED,    // 마감
    CANCELLED  // 취소
}
