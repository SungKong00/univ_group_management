package org.castlekong.backend.entity

/**
 * 채널 레벨 권한 (L2 - Channel-Level Permissions)
 * MVP 버전: 단순화된 Set 기반 권한 관리
 */
enum class ChannelPermission {
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
