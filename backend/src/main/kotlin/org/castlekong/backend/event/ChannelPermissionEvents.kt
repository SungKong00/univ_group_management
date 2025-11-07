package org.castlekong.backend.event

import org.springframework.context.ApplicationEvent

// 채널 권한 관련 이벤트들
// 캐시 무효화 트리거로 사용

/**
 * 채널 역할 바인딩 변경 이벤트
 */
class RoleBindingChangedEvent(
    source: Any,
    val channelId: Long,
    val groupRoleId: Long,
    val action: BindingAction,
) : ApplicationEvent(source) {
    enum class BindingAction {
        CREATED,
        UPDATED,
        DELETED,
    }
}

/**
 * 권한 템플릿 변경 이벤트
 */
class TemplateChangedEvent(
    source: Any,
    val templateId: Long,
    val action: TemplateAction,
) : ApplicationEvent(source) {
    enum class TemplateAction {
        CREATED,
        UPDATED,
        DELETED,
    }
}

/**
 * 사용자 역할 멤버십 변경 이벤트
 */
class UserRoleChangedEvent(
    source: Any,
    val userId: Long,
    val groupId: Long,
    val roleId: Long,
    val action: MembershipAction,
) : ApplicationEvent(source) {
    enum class MembershipAction {
        ADDED,
        REMOVED,
        ROLE_CHANGED,
    }
}

/**
 * 멤버 오버라이드 변경 이벤트
 */
class MemberOverrideChangedEvent(
    source: Any,
    val channelId: Long,
    val userId: Long,
    val action: OverrideAction,
) : ApplicationEvent(source) {
    enum class OverrideAction {
        CREATED,
        UPDATED,
        DELETED,
    }
}
