package com.univgroup.domain.permission.service

import org.slf4j.LoggerFactory
import org.springframework.stereotype.Component

/**
 * 권한 감사 로거
 *
 * 권한 검증 시도와 결과를 로깅한다.
 * 보안 감시 및 디버깅 목적으로 사용된다.
 */
@Component
class AuditLogger {
    private val logger = LoggerFactory.getLogger("AUDIT")

    /**
     * 권한 검증 성공 로그
     */
    fun logPermissionGranted(
        userId: Long,
        resourceType: String,
        resourceId: Long,
        action: String,
        permissions: Collection<String>,
    ) {
        logger.info(
            "PERMISSION_GRANTED | user={} | resource={}:{} | action={} | permissions={}",
            userId,
            resourceType,
            resourceId,
            action,
            permissions.joinToString(","),
        )
    }

    /**
     * 권한 검증 실패 로그
     */
    fun logPermissionDenied(
        userId: Long,
        resourceType: String,
        resourceId: Long,
        action: String,
        reason: String,
    ) {
        logger.warn(
            "PERMISSION_DENIED | user={} | resource={}:{} | action={} | reason={}",
            userId,
            resourceType,
            resourceId,
            action,
            reason,
        )
    }

    /**
     * 멤버십 확인 로그
     */
    fun logMembershipCheck(
        userId: Long,
        groupId: Long,
        isMember: Boolean,
    ) {
        if (logger.isDebugEnabled) {
            logger.debug(
                "MEMBERSHIP_CHECK | user={} | group={} | isMember={}",
                userId,
                groupId,
                isMember,
            )
        }
    }

    /**
     * 캐시 히트/미스 로그
     */
    fun logCacheAccess(
        cacheType: String,
        key: String,
        hit: Boolean,
    ) {
        if (logger.isTraceEnabled) {
            logger.trace(
                "CACHE_{} | type={} | key={}",
                if (hit) "HIT" else "MISS",
                cacheType,
                key,
            )
        }
    }

    /**
     * 권한 변경 이벤트 로그
     */
    fun logPermissionChange(
        actorUserId: Long,
        targetUserId: Long?,
        groupId: Long,
        changeType: PermissionChangeType,
        details: String,
    ) {
        logger.info(
            "PERMISSION_CHANGE | actor={} | target={} | group={} | type={} | details={}",
            actorUserId,
            targetUserId ?: "N/A",
            groupId,
            changeType,
            details,
        )
    }
}

enum class PermissionChangeType {
    ROLE_CREATED,
    ROLE_UPDATED,
    ROLE_DELETED,
    MEMBER_ROLE_CHANGED,
    MEMBER_ADDED,
    MEMBER_REMOVED,
    CHANNEL_BINDING_UPDATED,
}
