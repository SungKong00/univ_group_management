package org.castlekong.backend.entity

import jakarta.persistence.CollectionTable
import jakarta.persistence.Column
import jakarta.persistence.ElementCollection
import jakarta.persistence.Entity
import jakarta.persistence.EnumType
import jakarta.persistence.Enumerated
import jakarta.persistence.FetchType
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import jakarta.persistence.Id
import jakarta.persistence.JoinColumn
import jakarta.persistence.ManyToOne
import jakarta.persistence.Table
import java.time.LocalDateTime

@Entity
@Table(name = "groups")
class Group(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,
    @Column(nullable = false, length = 100)
    val name: String,
    @Column(length = 500)
    val description: String? = null,
    @Column(name = "profile_image_url", length = 500)
    val profileImageUrl: String? = null,
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "owner_id", nullable = false)
    val owner: User,
    // 하위 그룹 관계를 위한 parent 필드 추가
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "parent_id")
    val parent: Group? = null,
    // 대학/학과 정보 필드 추가
    @Column(name = "university", length = 100)
    val university: String? = null,
    @Column(name = "college", length = 100)
    val college: String? = null,
    @Column(name = "department", length = 100)
    val department: String? = null,
    @Enumerated(EnumType.STRING)
    @Column(name = "group_type", nullable = false, length = 20)
    val groupType: GroupType = GroupType.AUTONOMOUS,
    @Column(name = "max_members")
    val maxMembers: Int? = null,
    @Column(name = "default_channels_created", nullable = false)
    var defaultChannelsCreated: Boolean = false,
    @ElementCollection(targetClass = String::class, fetch = FetchType.EAGER)
    @CollectionTable(name = "group_tags", joinColumns = [JoinColumn(name = "group_id")])
    @Column(name = "tag", nullable = false, length = 50)
    val tags: Set<String> = emptySet(),
    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),
    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now(),
    // 소프트 삭제(보존 기간) 지원을 위한 필드
    @Column(name = "deleted_at")
    val deletedAt: LocalDateTime? = null,
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is Group) return false
        return id != 0L && id == other.id
    }

    override fun hashCode(): Int = id.hashCode()
}

enum class GroupType {
    AUTONOMOUS, // 자율그룹
    OFFICIAL, // 공식그룹
    UNIVERSITY, // 대학교
    COLLEGE, // 단과대학
    DEPARTMENT, // 학과/계열
    LAB, // 연구실/랩실
}
