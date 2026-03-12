package com.univgroup.domain.user.entity

import jakarta.persistence.*
import org.springframework.data.annotation.CreatedDate
import org.springframework.data.annotation.LastModifiedDate
import org.springframework.data.jpa.domain.support.AuditingEntityListener
import java.time.LocalDateTime

/**
 * 사용자 엔티티
 *
 * 시스템에 로그인하는 개별 사용자를 나타낸다.
 * Google OAuth2 기반 인증을 사용하며, email을 고유 식별자로 사용한다.
 */
@Entity
@Table(name = "users")
@EntityListeners(AuditingEntityListener::class)
data class User(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    // 기본 정보
    @Column(nullable = false, length = 50)
    var name: String,

    @Column(nullable = false, unique = true, length = 100)
    val email: String, // email은 불변 (unique key)

    @Column(name = "password_hash", nullable = false)
    var password: String,

    // 글로벌 역할
    @Enumerated(EnumType.STRING)
    @Column(name = "global_role", nullable = false)
    var globalRole: GlobalRole = GlobalRole.STUDENT,

    // 상태
    @Column(name = "is_active", nullable = false)
    var isActive: Boolean = true,

    @Column(name = "email_verified", nullable = false)
    var emailVerified: Boolean = true,

    // 프로필
    @Column(length = 50)
    var nickname: String? = null,

    @Column(name = "profile_image_url", length = 255)
    var profileImageUrl: String? = null,

    @Column(columnDefinition = "TEXT")
    var bio: String? = null,

    @Column(name = "profile_completed", nullable = false)
    var profileCompleted: Boolean = false,

    // 대학 정보
    @Column(name = "college", length = 100)
    var college: String? = null,

    @Column(name = "department", length = 100)
    var department: String? = null,

    @Column(name = "student_no", length = 30)
    var studentNo: String? = null,

    @Column(name = "school_email", length = 100)
    var schoolEmail: String? = null,

    // 교수 인증
    @Enumerated(EnumType.STRING)
    @Column(name = "professor_status")
    var professorStatus: ProfessorStatus? = null,

    // 학년 (승계 용도)
    @Column(name = "academic_year")
    var academicYear: Int? = null,

    // 감사
    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @LastModifiedDate
    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now()
) {
    override fun equals(other: Any?) = other is User && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()
}

/**
 * 전역 역할 (시스템 전체에서의 역할)
 */
enum class GlobalRole {
    STUDENT,    // 학생
    PROFESSOR,  // 교수
    ADMIN       // 시스템 관리자
}

/**
 * 교수 인증 상태
 */
enum class ProfessorStatus {
    PENDING,    // 승인 대기
    APPROVED,   // 승인됨
    REJECTED    // 거부됨
}
