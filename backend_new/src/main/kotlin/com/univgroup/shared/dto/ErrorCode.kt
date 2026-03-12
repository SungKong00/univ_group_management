package com.univgroup.shared.dto

import org.springframework.http.HttpStatus

/**
 * 중앙 관리되는 에러 코드 (헌법 II. 표준 응답 형식)
 *
 * 에러 코드는 도메인별로 그룹화되어 관리된다.
 * - COMMON_*: 공통 에러
 * - AUTH_*: 인증 관련 에러
 * - USER_*: 사용자 관련 에러
 * - GROUP_*: 그룹 관련 에러
 * - PERMISSION_*: 권한 관련 에러
 * - CONTENT_*: 콘텐츠 관련 에러
 * - WORKSPACE_*: 워크스페이스 관련 에러
 */
enum class ErrorCode(
    val code: String,
    val message: String,
    val httpStatus: HttpStatus,
) {
    // ========== Common Errors ==========
    COMMON_INTERNAL_ERROR("COMMON_001", "서버 내부 오류가 발생했습니다", HttpStatus.INTERNAL_SERVER_ERROR),
    COMMON_INVALID_REQUEST("COMMON_002", "잘못된 요청입니다", HttpStatus.BAD_REQUEST),
    COMMON_RESOURCE_NOT_FOUND("COMMON_003", "리소스를 찾을 수 없습니다", HttpStatus.NOT_FOUND),
    COMMON_VALIDATION_FAILED("COMMON_004", "유효성 검증에 실패했습니다", HttpStatus.BAD_REQUEST),

    // ========== Authentication Errors ==========
    AUTH_INVALID_TOKEN("AUTH_001", "유효하지 않은 토큰입니다", HttpStatus.UNAUTHORIZED),
    AUTH_TOKEN_EXPIRED("AUTH_002", "토큰이 만료되었습니다", HttpStatus.UNAUTHORIZED),
    AUTH_UNAUTHORIZED("AUTH_003", "인증이 필요합니다", HttpStatus.UNAUTHORIZED),
    AUTH_GOOGLE_VERIFICATION_FAILED("AUTH_004", "Google 인증에 실패했습니다", HttpStatus.UNAUTHORIZED),

    // ========== User Errors ==========
    USER_NOT_FOUND("USER_001", "사용자를 찾을 수 없습니다", HttpStatus.NOT_FOUND),
    USER_ALREADY_EXISTS("USER_002", "이미 존재하는 사용자입니다", HttpStatus.CONFLICT),
    USER_PROFILE_INCOMPLETE("USER_003", "프로필 정보가 완료되지 않았습니다", HttpStatus.BAD_REQUEST),
    USER_NICKNAME_DUPLICATED("USER_004", "이미 사용 중인 닉네임입니다", HttpStatus.CONFLICT),

    // ========== Group Errors ==========
    GROUP_NOT_FOUND("GROUP_001", "그룹을 찾을 수 없습니다", HttpStatus.NOT_FOUND),
    GROUP_ALREADY_EXISTS("GROUP_002", "이미 존재하는 그룹입니다", HttpStatus.CONFLICT),
    GROUP_MEMBER_ALREADY_EXISTS("GROUP_003", "이미 그룹에 가입되어 있습니다", HttpStatus.CONFLICT),
    GROUP_MEMBER_NOT_FOUND("GROUP_004", "그룹 멤버가 아닙니다", HttpStatus.NOT_FOUND),
    GROUP_OWNER_CANNOT_LEAVE("GROUP_005", "그룹장은 그룹을 탈퇴할 수 없습니다", HttpStatus.BAD_REQUEST),
    GROUP_ROLE_NOT_FOUND("GROUP_006", "역할을 찾을 수 없습니다", HttpStatus.NOT_FOUND),
    GROUP_SYSTEM_ROLE_IMMUTABLE("GROUP_007", "시스템 역할은 수정/삭제할 수 없습니다", HttpStatus.FORBIDDEN),

    // ========== Permission Errors ==========
    PERMISSION_DENIED("PERMISSION_001", "권한이 없습니다", HttpStatus.FORBIDDEN),
    PERMISSION_INVALID_OPERATION("PERMISSION_002", "허용되지 않은 작업입니다", HttpStatus.FORBIDDEN),

    // ========== Content Errors ==========
    CONTENT_POST_NOT_FOUND("CONTENT_001", "게시글을 찾을 수 없습니다", HttpStatus.NOT_FOUND),
    CONTENT_COMMENT_NOT_FOUND("CONTENT_002", "댓글을 찾을 수 없습니다", HttpStatus.NOT_FOUND),
    CONTENT_CHANNEL_NOT_FOUND("CONTENT_003", "채널을 찾을 수 없습니다", HttpStatus.NOT_FOUND),
    CONTENT_NOT_AUTHOR("CONTENT_004", "작성자만 수정/삭제할 수 있습니다", HttpStatus.FORBIDDEN),

    // ========== Workspace Errors ==========
    WORKSPACE_NOT_FOUND("WORKSPACE_001", "워크스페이스를 찾을 수 없습니다", HttpStatus.NOT_FOUND),
    WORKSPACE_CHANNEL_NOT_FOUND("WORKSPACE_002", "채널을 찾을 수 없습니다", HttpStatus.NOT_FOUND),

    // ========== Calendar Errors ==========
    CALENDAR_EVENT_NOT_FOUND("CALENDAR_001", "일정을 찾을 수 없습니다", HttpStatus.NOT_FOUND),
    CALENDAR_SCHEDULE_CONFLICT("CALENDAR_002", "일정이 충돌합니다", HttpStatus.CONFLICT),

    // ========== Place Errors ==========
    PLACE_NOT_FOUND("PLACE_001", "장소를 찾을 수 없습니다", HttpStatus.NOT_FOUND),
    PLACE_RESERVATION_CONFLICT("PLACE_002", "예약이 충돌합니다", HttpStatus.CONFLICT),
}
