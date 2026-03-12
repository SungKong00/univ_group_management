package com.univgroup.domain.permission.entity

import com.univgroup.domain.user.entity.User
import jakarta.persistence.*
import java.time.LocalDateTime

/**
 * 이메일 인증 엔티티
 *
 * 사용자의 이메일 인증 코드를 관리한다.
 */
@Entity
@Table(name = "email_verifications")
data class EmailVerification(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    val user: User,

    @Column(nullable = false, length = 100)
    val email: String,

    @Column(nullable = false, length = 6)
    val code: String,

    @Column(name = "expires_at", nullable = false)
    val expiresAt: LocalDateTime,

    @Column(name = "verified", nullable = false)
    val verified: Boolean = false,

    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now()
) {
    override fun equals(other: Any?) = other is EmailVerification && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()
}
