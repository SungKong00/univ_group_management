package com.univgroup.domain.permission.repository

import com.univgroup.domain.permission.entity.EmailVerification
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository
import java.time.LocalDateTime

/**
 * 이메일 인증 Repository
 */
@Repository
interface EmailVerificationRepository : JpaRepository<EmailVerification, Long> {
    /**
     * 토큰으로 인증 정보 조회
     */
    fun findByToken(token: String): EmailVerification?

    /**
     * 이메일로 인증 정보 조회
     */
    fun findByEmail(email: String): EmailVerification?

    /**
     * 만료되지 않은 유효한 토큰 조회
     */
    fun findByTokenAndExpiresAtAfter(token: String, now: LocalDateTime): EmailVerification?

    /**
     * 이메일과 만료시간으로 유효한 인증 정보 조회
     */
    fun findByEmailAndExpiresAtAfter(email: String, now: LocalDateTime): EmailVerification?

    /**
     * 만료된 인증 정보 삭제
     */
    fun deleteByExpiresAtBefore(now: LocalDateTime)
}
