package org.castlekong.backend.service

import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicLong

/**
 * 채널별 권한 버전 관리 서비스
 * 캐시 무효화를 위한 버전 번호 관리
 */
@Service
@Transactional
class PermissionVersionService {

    /**
     * 채널별 권한 버전을 메모리에서 관리
     * 운영환경에서는 Redis 등 분산 캐시 고려
     */
    private val channelVersions = ConcurrentHashMap<Long, AtomicLong>()

    /**
     * 특정 채널의 현재 권한 버전 조회
     */
    fun getVersion(channelId: Long): Long {
        return channelVersions.computeIfAbsent(channelId) { AtomicLong(1) }.get()
    }

    /**
     * 특정 채널의 권한 버전 증가
     * 캐시 무효화 트리거
     */
    fun incrementVersion(channelId: Long): Long {
        return channelVersions.computeIfAbsent(channelId) { AtomicLong(1) }.incrementAndGet()
    }

    /**
     * 여러 채널의 권한 버전 일괄 증가
     */
    fun incrementVersions(channelIds: List<Long>): Map<Long, Long> {
        return channelIds.associateWith { channelId ->
            incrementVersion(channelId)
        }
    }

    /**
     * 특정 채널의 권한 버전 초기화
     */
    fun resetVersion(channelId: Long) {
        channelVersions.remove(channelId)
    }

    /**
     * 모든 채널의 권한 버전 초기화
     */
    fun resetAllVersions() {
        channelVersions.clear()
    }

    /**
     * 현재 관리 중인 채널 목록 조회
     */
    fun getManagedChannels(): Set<Long> {
        return channelVersions.keys.toSet()
    }

    /**
     * 특정 채널들의 현재 버전 일괄 조회
     */
    fun getVersions(channelIds: List<Long>): Map<Long, Long> {
        return channelIds.associateWith { channelId ->
            getVersion(channelId)
        }
    }
}