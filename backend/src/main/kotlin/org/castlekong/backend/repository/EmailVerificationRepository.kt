package org.castlekong.backend.repository

import org.castlekong.backend.entity.EmailVerification
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

@Repository
interface EmailVerificationRepository : JpaRepository<EmailVerification, Long> {
    fun findTopByEmailOrderByCreatedAtDesc(email: String): EmailVerification?
}
