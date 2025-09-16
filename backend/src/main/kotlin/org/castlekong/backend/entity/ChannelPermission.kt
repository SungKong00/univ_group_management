package org.castlekong.backend.entity

/**
 * 채널별 권한 시스템을 위한 권한 enum
 * 비트마스크를 지원하여 고성능 권한 계산 가능
 */
enum class ChannelPermission(val bit: Int) {
    // 기본 접근
    CHANNEL_VIEW(0),

    // 게시글 관리
    POST_READ(1),
    POST_CREATE(2),
    POST_UPDATE_OWN(3),
    POST_UPDATE_ALL(4),
    POST_DELETE_OWN(5),
    POST_DELETE_ALL(6),

    // 댓글 관리
    COMMENT_READ(7),
    COMMENT_CREATE(8),
    COMMENT_UPDATE_OWN(9),
    COMMENT_UPDATE_ALL(10),
    COMMENT_DELETE_OWN(11),
    COMMENT_DELETE_ALL(12),

    // 특수 권한
    POST_PIN(13),           // 게시글 고정
    POST_ANNOUNCE(14),      // 공지사항 작성
    MEMBER_MENTION(15);     // @멤버 멘션

    /**
     * 비트마스크 값 (2^bit)
     */
    val mask: Long = 1L shl bit

    companion object {
        /**
         * 모든 권한의 비트마스크
         */
        val ALL_PERMISSIONS_MASK: Long = values().fold(0L) { acc, perm -> acc or perm.mask }

        /**
         * 비트마스크에서 권한 목록 추출
         */
        fun fromMask(mask: Long): Set<ChannelPermission> {
            return values().filter { (mask and it.mask) != 0L }.toSet()
        }

        /**
         * 권한 목록을 비트마스크로 변환
         */
        fun toMask(permissions: Set<ChannelPermission>): Long {
            return permissions.fold(0L) { acc, perm -> acc or perm.mask }
        }

        /**
         * 권한 상속 규칙 적용
         * ALL 권한이 있으면 OWN 권한도 자동 부여
         * CREATE 권한이 있으면 READ 권한도 자동 부여
         */
        fun applyInheritance(mask: Long): Long {
            var result = mask

            // ALL → OWN 상속
            if ((mask and POST_UPDATE_ALL.mask) != 0L) result = result or POST_UPDATE_OWN.mask
            if ((mask and POST_DELETE_ALL.mask) != 0L) result = result or POST_DELETE_OWN.mask
            if ((mask and COMMENT_UPDATE_ALL.mask) != 0L) result = result or COMMENT_UPDATE_OWN.mask
            if ((mask and COMMENT_DELETE_ALL.mask) != 0L) result = result or COMMENT_DELETE_OWN.mask

            // CREATE → READ 상속
            if ((mask and POST_CREATE.mask) != 0L) result = result or POST_READ.mask
            if ((mask and COMMENT_CREATE.mask) != 0L) result = result or COMMENT_READ.mask

            // UPDATE/DELETE → READ 상속
            if ((mask and (POST_UPDATE_OWN.mask or POST_UPDATE_ALL.mask or
                          POST_DELETE_OWN.mask or POST_DELETE_ALL.mask)) != 0L) {
                result = result or POST_READ.mask
            }
            if ((mask and (COMMENT_UPDATE_OWN.mask or COMMENT_UPDATE_ALL.mask or
                          COMMENT_DELETE_OWN.mask or COMMENT_DELETE_ALL.mask)) != 0L) {
                result = result or COMMENT_READ.mask
            }

            return result
        }

        /**
         * Allow와 Deny 마스크의 충돌 여부 확인
         */
        fun hasConflict(allowMask: Long, denyMask: Long): Boolean {
            return (allowMask and denyMask) != 0L
        }

        /**
         * Deny 우선 정책 적용: (allow_mask) - (deny_mask)
         */
        fun applyDenyPolicy(allowMask: Long, denyMask: Long): Long {
            return allowMask and denyMask.inv()
        }
    }
}