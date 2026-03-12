package com.univgroup.domain.user.repository

import com.univgroup.domain.user.entity.User
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

@Repository
interface UserRepository : JpaRepository<User, Long> {
    // ===== 이메일 조회 =====

    fun findByEmail(email: String): User?

    fun existsByEmail(email: String): Boolean

    // ===== 닉네임 조회 =====

    fun findByNickname(nickname: String): User?

    fun existsByNickname(nickname: String): Boolean

    fun existsByNicknameAndIdNot(
        nickname: String,
        id: Long,
    ): Boolean

    // ===== 학교 이메일 조회 =====

    fun findBySchoolEmail(schoolEmail: String): User?

    fun existsBySchoolEmail(schoolEmail: String): Boolean
}
