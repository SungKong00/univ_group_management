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

    // Place
    PLACE_NOT_FOUND("장소를 찾을 수 없습니다."),
    PLACE_ALREADY_EXISTS("이미 등록된 장소입니다."),
    PLACE_USAGE_NOT_FOUND("사용 그룹을 찾을 수 없습니다."),
    PLACE_USAGE_ALREADY_REQUESTED("이미 신청한 장소입니다."),
    PLACE_USAGE_NOT_APPROVED("장소 사용 권한이 승인되지 않았습니다."),
    BLOCKED_TIME_NOT_FOUND("차단 시간을 찾을 수 없습니다."),

    // Place Time Management (New)
    OPERATING_HOURS_NOT_FOUND("운영시간을 찾을 수 없습니다."),
    RESTRICTED_TIME_NOT_FOUND("금지시간을 찾을 수 없습니다."),
    CLOSURE_NOT_FOUND("임시 휴무를 찾을 수 없습니다."),
    CLOSURE_ALREADY_EXISTS("해당 날짜에 이미 휴무가 등록되어 있습니다."),

    // Place Reservation
    PLACE_RESERVATION_NOT_FOUND("장소 예약을 찾을 수 없습니다."),
    PLACE_TIME_CONFLICT("해당 시간대는 이미 예약되어 있습니다."),
    PLACE_OUTSIDE_OPERATING_HOURS("장소 운영 시간이 아닙니다."),
    PLACE_TIME_BLOCKED("해당 시간대는 예약이 불가능합니다."),
    PLACE_NOT_MANAGING_GROUP("장소를 관리하는 그룹이 아닙니다."),
    PLACE_NOT_AUTHORIZED("장소 예약 권한이 없습니다."),

    // Group Event - Place Integration (Phase 1)
    OUTSIDE_OPERATING_HOURS("운영 시간이 아닙니다."),
    PLACE_BLOCKED("해당 시간대는 예약이 불가능합니다."),
    RESERVATION_CONFLICT("이미 예약된 시간대입니다."),
    NO_PLACE_PERMISSION("장소 사용 권한이 없습니다."),
    INVALID_LOCATION_MODE("locationText와 placeId는 동시에 사용할 수 없습니다."),

    // Event Participant
    PARTICIPANT_NOT_FOUND("참여자를 찾을 수 없습니다."),

    // Event Exception
    EXCEPTION_NOT_FOUND("일정 예외를 찾을 수 없습니다."),
    EXCEPTION_ALREADY_EXISTS("해당 날짜에 이미 예외가 존재합니다."),
}
