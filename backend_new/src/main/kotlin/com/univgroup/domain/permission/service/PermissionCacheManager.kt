package com.univgroup.domain.permission.service

import com.github.benmanes.caffeine.cache.Caffeine
import com.univgroup.domain.permission.ChannelPermission
import com.univgroup.domain.permission.GroupPermission
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Component
import java.time.Duration

/**
 * 권한 캐시 관리자
 *
 * 권한 정보는 자주 조회되지만 변경은 드물므로 캐싱을 적용한다.
 * 권한 변경 시 관련 캐시를 무효화한다.
 */
@Component
class PermissionCacheManager {
    private val logger = LoggerFactory.getLogger(PermissionCacheManager::class.java)

    /**
     * 그룹 권한 캐시
     * Key: "userId:groupId"
     * Value: Set<GroupPermission>
     */
    private val groupPermissionCache =
        Caffeine.newBuilder()
            .expireAfterWrite(Duration.ofMinutes(5))
            .maximumSize(10_000)
            .recordStats()
            .build<String, Set<GroupPermission>>()

    /**
     * 채널 권한 캐시
     * Key: "userId:channelId"
     * Value: Set<ChannelPermission>
     */
    private val channelPermissionCache =
        Caffeine.newBuilder()
            .expireAfterWrite(Duration.ofMinutes(5))
            .maximumSize(10_000)
            .recordStats()
            .build<String, Set<ChannelPermission>>()

    /**
     * 멤버십 캐시
     * Key: "userId:groupId"
     * Value: Boolean (멤버 여부)
     */
    private val membershipCache =
        Caffeine.newBuilder()
            .expireAfterWrite(Duration.ofMinutes(5))
            .maximumSize(10_000)
            .build<String, Boolean>()

    // ========== 그룹 권한 캐시 ==========

    fun getGroupPermissions(
        userId: Long,
        groupId: Long,
    ): Set<GroupPermission>? {
        val key = "$userId:$groupId"
        return groupPermissionCache.getIfPresent(key)
    }

    fun putGroupPermissions(
        userId: Long,
        groupId: Long,
        permissions: Set<GroupPermission>,
    ) {
        val key = "$userId:$groupId"
        groupPermissionCache.put(key, permissions)
    }

    fun getOrLoadGroupPermissions(
        userId: Long,
        groupId: Long,
        loader: () -> Set<GroupPermission>,
    ): Set<GroupPermission> {
        val key = "$userId:$groupId"
        return groupPermissionCache.get(key) { loader() }!!
    }

    // ========== 채널 권한 캐시 ==========

    fun getChannelPermissions(
        userId: Long,
        channelId: Long,
    ): Set<ChannelPermission>? {
        val key = "$userId:$channelId"
        return channelPermissionCache.getIfPresent(key)
    }

    fun putChannelPermissions(
        userId: Long,
        channelId: Long,
        permissions: Set<ChannelPermission>,
    ) {
        val key = "$userId:$channelId"
        channelPermissionCache.put(key, permissions)
    }

    fun getOrLoadChannelPermissions(
        userId: Long,
        channelId: Long,
        loader: () -> Set<ChannelPermission>,
    ): Set<ChannelPermission> {
        val key = "$userId:$channelId"
        return channelPermissionCache.get(key) { loader() }!!
    }

    // ========== 멤버십 캐시 ==========

    fun getMembership(
        userId: Long,
        groupId: Long,
    ): Boolean? {
        val key = "$userId:$groupId"
        return membershipCache.getIfPresent(key)
    }

    fun putMembership(
        userId: Long,
        groupId: Long,
        isMember: Boolean,
    ) {
        val key = "$userId:$groupId"
        membershipCache.put(key, isMember)
    }

    // ========== 캐시 무효화 ==========

    /**
     * 특정 사용자의 특정 그룹 관련 캐시 무효화
     */
    fun invalidateUser(
        userId: Long,
        groupId: Long,
    ) {
        val key = "$userId:$groupId"
        groupPermissionCache.invalidate(key)
        membershipCache.invalidate(key)
        logger.debug("Invalidated permission cache for user {} in group {}", userId, groupId)
    }

    /**
     * 특정 그룹의 모든 캐시 무효화 (역할 변경 시)
     */
    fun invalidateGroup(groupId: Long) {
        // Caffeine은 prefix 기반 무효화를 지원하지 않으므로 전체 무효화
        groupPermissionCache.invalidateAll()
        channelPermissionCache.invalidateAll()
        membershipCache.invalidateAll()
        logger.info("Invalidated all permission caches for group {}", groupId)
    }

    /**
     * 특정 채널의 캐시 무효화
     */
    fun invalidateChannel(channelId: Long) {
        // Caffeine은 suffix 기반 무효화를 지원하지 않으므로 채널 캐시 전체 무효화
        channelPermissionCache.invalidateAll()
        logger.debug("Invalidated channel permission cache for channel {}", channelId)
    }

    /**
     * 모든 캐시 무효화
     */
    fun invalidateAll() {
        groupPermissionCache.invalidateAll()
        channelPermissionCache.invalidateAll()
        membershipCache.invalidateAll()
        logger.info("Invalidated all permission caches")
    }

    /**
     * 캐시 통계 조회
     */
    fun getStats(): CacheStats {
        val groupStats = groupPermissionCache.stats()
        val channelStats = channelPermissionCache.stats()
        return CacheStats(
            groupPermissionHitRate = groupStats.hitRate(),
            groupPermissionSize = groupPermissionCache.estimatedSize(),
            channelPermissionHitRate = channelStats.hitRate(),
            channelPermissionSize = channelPermissionCache.estimatedSize(),
        )
    }
}

data class CacheStats(
    val groupPermissionHitRate: Double,
    val groupPermissionSize: Long,
    val channelPermissionHitRate: Double,
    val channelPermissionSize: Long,
)
