package com.univgroup.shared.security

import org.slf4j.LoggerFactory
import org.springframework.scheduling.annotation.Scheduled
import org.springframework.stereotype.Component
import java.time.Instant
import java.util.concurrent.ConcurrentHashMap

/**
 * In-Memory 토큰 블랙리스트
 *
 * 로그아웃된 JWT 토큰을 만료 시간까지 저장하여 재사용을 방지한다.
 *
 * 주의사항:
 * - 서버 재시작 시 블랙리스트가 초기화됨
 * - 단일 서버 환경에서만 완전히 동작
 * - 다중 서버 환경에서는 Redis 등 분산 캐시 사용 권장
 */
@Component
class TokenBlacklist {
    private val logger = LoggerFactory.getLogger(TokenBlacklist::class.java)

    /**
     * 블랙리스트 저장소
     * Key: 토큰 문자열 (또는 해시)
     * Value: 토큰 만료 시간
     */
    private val blacklist = ConcurrentHashMap<String, Instant>()

    /**
     * 토큰을 블랙리스트에 추가
     *
     * @param token JWT 토큰
     * @param expiresAt 토큰 만료 시간
     */
    fun add(token: String, expiresAt: Instant) {
        blacklist[token] = expiresAt
        logger.debug("Token added to blacklist, expires at: {}", expiresAt)
    }

    /**
     * 토큰이 블랙리스트에 있는지 확인
     *
     * @param token JWT 토큰
     * @return 블랙리스트에 있으면 true
     */
    fun isBlacklisted(token: String): Boolean {
        return blacklist.containsKey(token)
    }

    /**
     * 만료된 토큰 정리 (매 10분마다 실행)
     *
     * 블랙리스트에서 이미 만료된 토큰을 제거하여 메모리 누수를 방지한다.
     */
    @Scheduled(fixedRate = 600_000) // 10분
    fun cleanupExpiredTokens() {
        val now = Instant.now()
        val expiredCount = blacklist.entries.removeIf { it.value.isBefore(now) }
        if (expiredCount) {
            logger.info("Cleaned up expired tokens from blacklist, current size: {}", blacklist.size)
        }
    }

    /**
     * 블랙리스트 크기 조회 (모니터링용)
     */
    fun size(): Int = blacklist.size

    /**
     * 블랙리스트 전체 초기화 (테스트용)
     */
    fun clear() {
        blacklist.clear()
        logger.info("Token blacklist cleared")
    }
}
