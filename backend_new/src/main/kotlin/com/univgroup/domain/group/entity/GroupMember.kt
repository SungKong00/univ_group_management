package com.univgroup.domain.group.entity

import com.univgroup.domain.user.entity.User
import jakarta.persistence.*
import java.time.LocalDateTime

/**
 * 그룹 멤버 엔티티 (조인 테이블)
 *
 * User와 Group의 다대다(N:M) 관계를 연결한다.
 * 각 멤버는 그룹 내에서 하나의 역할(GroupRole)을 가진다.
 */
@Entity
@Table(
    name = "group_members",
    uniqueConstraints = [
        UniqueConstraint(columnNames = ["group_id", "user_id"])
    ]
)
data class GroupMember(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "group_id", nullable = false)
    val group: Group,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    val user: User,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "role_id", nullable = false)
    var role: GroupRole,

    @Column(name = "joined_at", nullable = false)
    val joinedAt: LocalDateTime = LocalDateTime.now()
) {
    override fun equals(other: Any?) = other is GroupMember && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()
}
