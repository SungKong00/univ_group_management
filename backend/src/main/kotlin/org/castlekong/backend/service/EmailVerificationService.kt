package org.castlekong.backend.service

import org.castlekong.backend.dto.EmailSendRequest
import org.castlekong.backend.dto.EmailVerifyRequest
import org.castlekong.backend.entity.EmailVerification
import org.castlekong.backend.repository.EmailVerificationRepository
import org.springframework.beans.factory.annotation.Value
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.security.SecureRandom
import java.time.Duration
import java.time.LocalDateTime

@Service
class EmailVerificationService(
    private val emailVerificationRepository: EmailVerificationRepository,
    private val userService: UserService,
    @Value("\${app.school-email.allowed-domains:hs.ac.kr}") private val allowedDomains: String,
) {
    private val random = SecureRandom()

    private fun isAllowedDomain(email: String): Boolean {
        val domain = email.substringAfter('@').lowercase()
        val allowed = allowedDomains.split(',').map { it.trim().lowercase() }.filter { it.isNotBlank() }
        return allowed.any { domain == it || domain.endsWith(".$it") }
    }

    @Transactional
    fun sendCode(userEmail: String, req: EmailSendRequest) {
        if (!isAllowedDomain(req.email)) {
            throw IllegalArgumentException("E_BAD_DOMAIN: 허용되지 않은 도메인입니다")
        }

        val latest = emailVerificationRepository.findTopByEmailOrderByCreatedAtDesc(req.email)
        if (latest != null) {
            val since = Duration.between(latest.createdAt, LocalDateTime.now()).seconds
            if (since < 30) {
                throw IllegalArgumentException("E_RATE_LIMIT: 30초 후 다시 시도해 주세요")
            }
        }

        val code = random.nextInt(1_000_000).toString().padStart(6, '0')
        val expiresAt = LocalDateTime.now().plusMinutes(5)
        val entity = EmailVerification(email = req.email, code = code, expiresAt = expiresAt)
        emailVerificationRepository.save(entity)

        // 실제 메일 전송은 생략 (개발용 로그)
        println("[EmailVerification] Sent code $code to ${req.email}")
    }

    @Transactional
    fun verifyCode(userEmail: String, req: EmailVerifyRequest) {
        val record = emailVerificationRepository.findTopByEmailOrderByCreatedAtDesc(req.email)
            ?: throw IllegalArgumentException("E_OTP_MISMATCH: 코드가 일치하지 않아요")

        if (LocalDateTime.now().isAfter(record.expiresAt)) {
            throw IllegalArgumentException("E_OTP_EXPIRED: 코드가 만료되었어요")
        }

        if (record.code != req.code) {
            // 간단히 실패만 보고, 누적 횟수 제약은 추후 추가 가능
            throw IllegalArgumentException("E_OTP_MISMATCH: 코드가 일치하지 않아요")
        }

        // 사용자 업데이트: schoolEmail, emailVerified=true
        val user = userService.findByEmail(userEmail)
            ?: throw IllegalArgumentException("USER_NOT_FOUND: 사용자 없음")

        val updated = user.copy(
            schoolEmail = req.email,
            emailVerified = true,
        )
        userService.save(updated)
    }
}
