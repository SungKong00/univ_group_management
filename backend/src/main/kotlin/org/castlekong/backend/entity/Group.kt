package org.castlekong.backend.entity

import jakarta.persistence.*
import java.time.LocalDateTime

@Entity
@Table(name = "groups")
data class Group(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @Column(nullable = false, unique = true, length = 100)
    val name: String,

    @Column(length = 500)
    val description: String? = null,

    @Column(name = "profile_image_url", length = 500)
    val profileImageUrl: String? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "owner_id", nullable = false)
    val owner: User,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    val visibility: GroupVisibility = GroupVisibility.PUBLIC,

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
)

enum class GroupVisibility {
    PUBLIC,
    PRIVATE,
    INVITE_ONLY
}

