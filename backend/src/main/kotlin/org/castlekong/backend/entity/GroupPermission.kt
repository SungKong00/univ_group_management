package org.castlekong.backend.entity

/**
 * 그룹 레벨 권한 (L1 - Group-Level Permissions)
 * MVP 버전: 단순화된 권한 구조
 */
enum class GroupPermission {
    /**
     * 그룹 관리 권한
     * - 그룹 정보 수정 (이름, 소개 등)
     * - 그룹 삭제
     */
    GROUP_MANAGE,

    /**
     * 관리자 권한 (멤버 관리 + 역할 관리 통합)
     * - 멤버 역할 변경, 강제 탈퇴
     * - 커스텀 역할 생성, 수정, 삭제
     * - 가입 신청 승인/반려
     */
    ADMIN_MANAGE,

    /**
     * 채널 관리 권한
     * - 채널 생성, 삭제, 설정 수정
     * - 채널별 역할 바인딩 설정
     * 주의: 채널 내 활동 권한과는 별개
     */
    CHANNEL_MANAGE,

    /**
     * 모집 관리 권한
     * - 모집 공고 작성/수정/마감
     * - 모집 관련 설정 관리
     */
    RECRUITMENT_MANAGE,
}
