package com.univgroup.domain.group.entity

import com.univgroup.domain.user.entity.User
import jakarta.persistence.*
import java.time.LocalDateTime

/**
 * 그룹 엔티티
 *
 * 사용자들이 모여 활동하는 핵심 단위 공간(커뮤니티)을 나타낸다.
 * 계층 구조: 대학교 → 단과대학 → 학과 → 동아리/스터디
 */
@Entity
@Table(name = "groups")
data class Group(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    // 기본 정보
    @Column(nullable = false, length = 100)
    var name: String,

    @Column(length = 500)
    var description: String? = null,

    @Column(name = "profile_image_url", length = 500)
    var profileImageUrl: String? = null,

    // 소유자
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "owner_id", nullable = false)
    val owner: User,

    // 계층 구조 (하위 그룹)
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "parent_id")
    val parent: Group? = null,

    // 대학/학과 정보
    @Column(name = "university", length = 100)
    val university: String? = null,

    @Column(name = "college", length = 100)
    val college: String? = null,

    @Column(name = "department", length = 100)
    val department: String? = null,

    // 그룹 타입
    @Enumerated(EnumType.STRING)
    @Column(name = "group_type", nullable = false, length = 20)
    val groupType: GroupType = GroupType.AUTONOMOUS,

    // 설정
    @Column(name = "max_members")
    var maxMembers: Int? = null,

    @Column(name = "default_channels_created", nullable = false)
    var defaultChannelsCreated: Boolean = false,

    // 태그
    @ElementCollection(targetClass = String::class, fetch = FetchType.EAGER)
    @CollectionTable(name = "group_tags", joinColumns = [JoinColumn(name = "group_id")])
    @Column(name = "tag", nullable = false, length = 50)
    val tags: Set<String> = emptySet(),

    // 감사
    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now(),

    // 소프트 삭제
    @Column(name = "deleted_at")
    val deletedAt: LocalDateTime? = null
) {
    override fun equals(other: Any?) = other is Group && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()
}

/**
 * 그룹 유형
 */
enum class GroupType {
    AUTONOMOUS,    // 자율그룹
    OFFICIAL,      // 공식그룹
    UNIVERSITY,    // 대학교
    COLLEGE,       // 단과대학
    DEPARTMENT,    // 학과/계열
    LAB            // 연구실/랩실
}
