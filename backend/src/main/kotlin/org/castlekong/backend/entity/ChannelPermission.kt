package org.castlekong.backend.entity

/**
 * 채널 레벨 권한 (L2 - Channel-Level Permissions)
 * MVP 버전: 단순화된 Set 기반 권한 관리
 */
enum class ChannelPermission {
    /**
     * 채널 보기 권한
     * - 채널 존재 확인 및 기본 정보 조회
     * - 모든 채널 활동의 기본 전제 조건
     */
    CHANNEL_VIEW,

    /**
     * 게시글 읽기 권한
     * - 채널 내 게시글 조회
     */
    POST_READ,

    /**
     * 게시글 작성 권한
     * - 채널 내 새 게시글 작성
     */
    POST_WRITE,

    /**
     * 댓글 작성 권한
     * - 게시글에 댓글 작성
     */
    COMMENT_WRITE,

    /**
     * 파일 업로드 권한
     * - 게시글 및 댓글에 파일 첨부
     */
    FILE_UPLOAD,
}