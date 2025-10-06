package org.castlekong.backend.entity

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.EntityListeners
import jakarta.persistence.EnumType
import jakarta.persistence.Enumerated
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import jakarta.persistence.Id
import jakarta.persistence.Table
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
    @Column(length = 50)
    val nickname: String? = null,
    @Column(name = "profile_image_url", length = 255)
    val profileImageUrl: String? = null,
    @Column(columnDefinition = "TEXT")
    val bio: String? = null,
    @Column(name = "profile_completed", nullable = false)
    val profileCompleted: Boolean = false,
    // 학교 이메일 인증 여부 (MVP 단계에서는 기본 true로 처리)
    @Column(name = "email_verified", nullable = false)
    val emailVerified: Boolean = true,
    // 추가 온보딩 필드
    @Column(name = "college", length = 100)
    val college: String? = null,
    @Column(name = "department", length = 100)
    val department: String? = null,
    @Column(name = "student_no", length = 30)
    val studentNo: String? = null,
    @Column(name = "school_email", length = 100)
    val schoolEmail: String? = null,
    @Enumerated(EnumType.STRING)
    @Column(name = "professor_status")
    val professorStatus: ProfessorStatus? = null,
    // 학년 정보 (그룹장 유고시 자동 승계를 위해)
    // 1학년: 1, 2학년: 2, ... 대학원생: null
    @Column(name = "academic_year")
    val academicYear: Int? = null,
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

enum class ProfessorStatus {
    PENDING,
    APPROVED,
    REJECTED,
}
