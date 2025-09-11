package org.castlekong.backend.entity

import jakarta.persistence.*
import org.springframework.data.annotation.CreatedDate
import org.springframework.data.annotation.LastModifiedDate
import org.springframework.data.jpa.domain.support.AuditingEntityListener
import java.time.LocalDateTime

@Entity
@Table(name = "users")
@EntityListeners(AuditingEntityListener::class)
data class User(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,
    @Column(nullable = false, length = 50)
    val name: String,
    @Column(nullable = false, unique = true, length = 100)
    val email: String,
    @Column(name = "password_hash", nullable = false)
    val password: String,
    @Enumerated(EnumType.STRING)
    @Column(name = "global_role", nullable = false)
    val globalRole: GlobalRole = GlobalRole.STUDENT,
    @Column(name = "is_active", nullable = false)
    val isActive: Boolean = true,
    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),
    @LastModifiedDate
    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now(),
)

enum class GlobalRole {
    STUDENT,
    PROFESSOR,
    ADMIN,
}
