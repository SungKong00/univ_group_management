package org.castlekong.backend.service

import org.castlekong.backend.event.*
import org.castlekong.backend.repository.ChannelRoleBindingRepository
import org.slf4j.LoggerFactory
import org.springframework.cache.CacheManager
import org.springframework.context.event.EventListener
import org.springframework.stereotype.Component

/**
 * 채널 권한 캐시 관리자
 * 4종 트리거에 따른 캐시 무효화 처리
 */
@Component
class ChannelPermissionCacheManager(
    private val cacheManager: CacheManager,
    private val permissionVersionService: PermissionVersionService,
    private val channelRoleBindingRepository: ChannelRoleBindingRepository,
) {
    private val logger = LoggerFactory.getLogger(ChannelPermissionCacheManager::class.java)

    companion object {
        const val CACHE_NAME = "channel-permissions"
    }

    /**
     * a) ChannelRoleBinding 변경 이벤트 처리
     */
    @EventListener
    fun onRoleBindingChanged(event: RoleBindingChangedEvent) {
        logger.debug("Processing RoleBindingChangedEvent: channelId=${event.channelId}, action=${event.action}")

        // 해당 채널의 권한 버전 증가
        val newVersion = permissionVersionService.incrementVersion(event.channelId)

        // 캐시에서 해당 채널 관련 항목들 제거
        evictChannelCache(event.channelId)

        logger.info("Invalidated cache for channel ${event.channelId}, new version: $newVersion")
    }

    /**
     * c) GroupRole membership(user↔role) 변경 이벤트 처리
     */
    @EventListener
    fun onUserRoleMembershipChanged(event: UserRoleChangedEvent) {
        logger.debug("Processing UserRoleChangedEvent: userId=${event.userId}, groupId=${event.groupId}, action=${event.action}")

        // 해당 그룹의 역할들이 바인딩된 모든 채널 조회
        val affectedChannels = channelRoleBindingRepository.findChannelIdsByGroupRoleInGroup(event.groupId)

        if (affectedChannels.isNotEmpty()) {
            // 영향받는 모든 채널의 버전 증가
            val newVersions = permissionVersionService.incrementVersions(affectedChannels)

            // 해당 사용자의 캐시만 선별적으로 무효화
            affectedChannels.forEach { channelId ->
                evictUserChannelCache(channelId, event.userId)
            }

            logger.info(
                "Invalidated user ${event.userId} cache for ${affectedChannels.size} channels in group ${event.groupId}: $newVersions",
            )
        }
    }

    /**
     * 특정 채널의 모든 사용자 캐시 무효화
     */
    private fun evictChannelCache(channelId: Long) {
        val cache = cacheManager.getCache(CACHE_NAME)
        cache?.let {
            // 실제로는 캐시 구현에 따라 wildcard 패턴으로 삭제하거나
            // 버전 기반 캐시 키 사용으로 자동 무효화
            // 여기서는 버전 증가로 자동 무효화됨
            logger.debug("Channel $channelId cache will be invalidated by version increment")
        }
    }

    /**
     * 특정 사용자의 특정 채널 캐시만 무효화
     */
    private fun evictUserChannelCache(
        channelId: Long,
        userId: Long,
    ) {
        val cache = cacheManager.getCache(CACHE_NAME)
        cache?.let {
            // 해당 사용자의 해당 채널 관련 캐시 키들을 정확히 삭제
            // 패턴: "channelId:userId:*"

            // 모든 ChannelPermission에 대해 캐시 키 생성 및 삭제
            org.castlekong.backend.entity.ChannelPermission.values().forEach { permission ->
                val currentVersion = permissionVersionService.getVersion(channelId)
                val cacheKey = "$channelId:$userId:${permission.name}:$currentVersion"
                cache.evict(cacheKey)
            }

            logger.debug("Evicted cache keys for user $userId in channel $channelId")
        }
    }

    /**
     * 전체 권한 캐시 초기화 (관리용)
     */
    fun evictAllPermissionCache() {
        val cache = cacheManager.getCache(CACHE_NAME)
        cache?.clear()
        permissionVersionService.resetAllVersions()
        logger.info("Cleared all channel permission cache")
    }

    /**
     * 특정 채널 권한 캐시 초기화 (관리용)
     */
    fun evictChannelPermissionCache(channelId: Long) {
        permissionVersionService.incrementVersion(channelId)
        evictChannelCache(channelId)
        logger.info("Cleared channel $channelId permission cache")
    }
}
