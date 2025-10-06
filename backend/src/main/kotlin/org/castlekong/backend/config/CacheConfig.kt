package org.castlekong.backend.config

import com.github.benmanes.caffeine.cache.Caffeine
import org.springframework.cache.CacheManager
import org.springframework.cache.annotation.EnableCaching
import org.springframework.cache.caffeine.CaffeineCacheManager
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import java.util.concurrent.TimeUnit

/**
 * Spring Boot Cache 설정
 * Caffeine 기반 캐시 매니저 구성
 */
@Configuration
@EnableCaching
class CacheConfig {
    /**
     * Caffeine 기반 CacheManager 빈 생성
     */
    @Bean
    fun cacheManager(): CacheManager {
        val cacheManager = CaffeineCacheManager()

        // 기본 Caffeine 설정
        cacheManager.setCaffeine(
            Caffeine.newBuilder()
                .maximumSize(10000L) // 최대 10,000개 항목
                .expireAfterWrite(30, TimeUnit.MINUTES) // 30분 후 만료
                .expireAfterAccess(10, TimeUnit.MINUTES) // 10분 접근 없으면 만료
                .recordStats(), // 캐시 통계 수집
        )

        // 채널 권한 캐시는 별도 설정 적용
        cacheManager.registerCustomCache(
            "channel-permissions",
            Caffeine.newBuilder()
                .maximumSize(50000L) // 권한 캐시는 더 큰 용량
                .expireAfterWrite(60, TimeUnit.MINUTES) // 1시간 후 만료
                .expireAfterAccess(15, TimeUnit.MINUTES) // 15분 접근 없으면 만료
                .recordStats()
                .build(),
        )

        return cacheManager
    }
}
