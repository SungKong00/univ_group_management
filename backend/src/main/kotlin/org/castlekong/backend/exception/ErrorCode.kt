package org.castlekong.backend.exception

enum class ErrorCode(val message: String) {
    // Common
    INTERNAL_SERVER_ERROR("서버 내부 오류가 발생했습니다."),
    INVALID_REQUEST("잘못된 요청입니다."),
    FORBIDDEN("접근 권한이 없습니다."),
    UNAUTHORIZED("인증이 필요합니다."),
    SYSTEM_ROLE_IMMUTABLE("시스템 역할은 변경하거나 삭제할 수 없습니다."),

    // User
    USER_NOT_FOUND("사용자를 찾을 수 없습니다."),
    USER_ALREADY_EXISTS("이미 존재하는 사용자입니다."),

    // Group
    GROUP_NOT_FOUND("그룹을 찾을 수 없습니다."),
    GROUP_NAME_ALREADY_EXISTS("이미 존재하는 그룹 이름입니다."),
    ALREADY_GROUP_MEMBER("이미 그룹의 멤버입니다."),
    GROUP_FULL("그룹의 최대 멤버 수에 도달했습니다."),
    GROUP_OWNER_CANNOT_LEAVE("그룹 소유자는 그룹을 떠날 수 없습니다."),
    GROUP_MEMBER_NOT_FOUND("그룹 멤버를 찾을 수 없습니다."),

    // Group Role
    GROUP_ROLE_NOT_FOUND("그룹 역할을 찾을 수 없습니다."),
    GROUP_ROLE_NAME_ALREADY_EXISTS("이미 존재하는 역할 이름입니다."),

    // Requests
    REQUEST_NOT_FOUND("요청을 찾을 수 없습니다."),
    REQUEST_ALREADY_EXISTS("이미 존재하는 요청입니다."),

    // Auth
    INVALID_TOKEN("유효하지 않은 토큰입니다."),
    EXPIRED_TOKEN("만료된 토큰입니다."),

    // Channel
    CHANNEL_NOT_FOUND("채널을 찾을 수 없습니다."),

    // Post
    POST_NOT_FOUND("게시글을 찾을 수 없습니다."),

    // Comment
    COMMENT_NOT_FOUND("댓글을 찾을 수 없습니다."),

    // Personal Calendar
    PERSONAL_EVENT_NOT_FOUND("이벤트를 찾을 수 없습니다."),
    PERSONAL_EVENT_INVALID_TIME("이벤트 시간 범위가 올바르지 않습니다."),

    PERSONAL_SCHEDULE_NOT_FOUND("시간표 일정을 찾을 수 없습니다."),
    PERSONAL_SCHEDULE_INVALID_TIME("시간표 시간 범위가 올바르지 않습니다."),

    // Group Calendar
    EVENT_NOT_FOUND("일정을 찾을 수 없습니다."),
    INVALID_DATE_RANGE("날짜 범위가 올바르지 않습니다."),
    INVALID_TIME_RANGE("시간 범위가 올바르지 않습니다."),
    INVALID_COLOR("색상 코드가 올바르지 않습니다."),
    NOT_RECURRING_EVENT("반복 일정이 아닙니다."),
    NOT_GROUP_MEMBER("그룹 멤버가 아닙니다."),

    // Recruitment
    RECRUITMENT_NOT_FOUND("모집 게시글을 찾을 수 없습니다."),
    RECRUITMENT_ALREADY_EXISTS("이미 활성화된 모집 게시글이 있습니다."),
    RECRUITMENT_NOT_ACTIVE("활성화된 모집 게시글이 아닙니다."),
    RECRUITMENT_EXPIRED("모집 기간이 마감되었습니다."),
    RECRUITMENT_FULL("모집 정원이 가득 찼습니다."),
    RECRUITMENT_HAS_APPLICATIONS("지원서가 있어 삭제할 수 없습니다."),

    // Application
    APPLICATION_NOT_FOUND("지원서를 찾을 수 없습니다."),
    APPLICATION_ALREADY_EXISTS("이미 지원서를 제출했습니다."),
    APPLICATION_ALREADY_REVIEWED("이미 심사된 지원서입니다."),
    APPLICATION_CANNOT_WITHDRAW("철회할 수 없는 지원서입니다."),

    // Action
    INVALID_ACTION("유효하지 않은 액션입니다."),
    ACCESS_DENIED("접근이 거부되었습니다."),
}
