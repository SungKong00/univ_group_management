package org.castlekong.backend.entity

import jakarta.persistence.*
import java.time.LocalDateTime

@Entity
@Table(name = "groups")
data class Group(
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
    @Column(nullable = false, length = 20)
    val visibility: GroupVisibility = GroupVisibility.PUBLIC,

    @Enumerated(EnumType.STRING)
    @Column(name = "group_type", nullable = false, length = 20)
    val groupType: GroupType = GroupType.AUTONOMOUS,

    @Column(name = "is_recruiting", nullable = false)
    val isRecruiting: Boolean = false,

    @Column(name = "max_members")
    val maxMembers: Int? = null,

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
)

enum class GroupVisibility {
    PUBLIC,
    PRIVATE,
    INVITE_ONLY
}

enum class GroupType {
    AUTONOMOUS,     // 자율그룹
    OFFICIAL,       // 공식그룹
    UNIVERSITY,     // 대학교
    COLLEGE,        // 단과대학
    DEPARTMENT,     // 학과/계열
    LAB            // 연구실/랩실
}
