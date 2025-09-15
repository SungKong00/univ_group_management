package org.castlekong.backend.exception

enum class ErrorCode(val message: String) {
    // Common
    INTERNAL_SERVER_ERROR("서버 내부 오류가 발생했습니다."),
    INVALID_REQUEST("잘못된 요청입니다."),
    FORBIDDEN("접근 권한이 없습니다."),
    UNAUTHORIZED("인증이 필요합니다."),
    
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
    COMMENT_NOT_FOUND("댓글을 찾을 수 없습니다.")
}