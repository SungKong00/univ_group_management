package com.univgroup.domain.permission

/**
 * 그룹 레벨 권한 (L1: Group-Level)
 *
 * 그룹 전체에 적용되는 거시적 권한을 정의한다.
 * 시스템 역할(그룹장, 교수, 멤버)과 커스텀 역할에 매핑된다.
 */
enum class GroupPermission {
    // ===== 그룹 관리 =====
    GROUP_MANAGE, // 그룹 정보 수정, 설정 변경
    GROUP_DELETE, // 그룹 삭제

    // ===== 관리자 관리 =====
    ADMIN_MANAGE, // 관리자 권한 부여/해제
    ADMIN_VIEW, // 관리자 목록 조회

    // ===== 멤버 관리 =====
    MEMBER_MANAGE, // 멤버 추가/제거/역할변경
    MEMBER_VIEW, // 멤버 목록 조회
    MEMBER_KICK, // 멤버 강제 탈퇴

    // ===== 역할 관리 =====
    ROLE_MANAGE, // 커스텀 역할 생성/수정/삭제
    ROLE_ASSIGN, // 멤버에게 역할 할당

    // ===== 채널/워크스페이스 관리 =====
    CHANNEL_MANAGE, // 채널 생성/수정/삭제
    CHANNEL_READ, // 채널 목록 조회 (기본 권한)
    WORKSPACE_MANAGE, // 워크스페이스 생성/수정/삭제

    // ===== 콘텐츠 관리 =====
    POST_MANAGE, // 모든 게시글 수정/삭제 (관리자용)
    COMMENT_MANAGE, // 모든 댓글 수정/삭제 (관리자용)

    // ===== 모집 관리 =====
    RECRUITMENT_MANAGE, // 모집 공고 생성/수정/삭제
    RECRUITMENT_VIEW, // 모집 공고 조회

    // ===== 일정/장소 관리 =====
    CALENDAR_MANAGE, // 그룹 일정 생성/수정/삭제
    CALENDAR_VIEW, // 그룹 일정 조회
    PLACE_MANAGE, // 장소 생성/수정/삭제
    PLACE_RESERVE, // 장소 예약

    // ===== 하위 그룹 관리 =====
    SUBGROUP_MANAGE, // 하위 그룹 생성 승인/거절
    SUBGROUP_VIEW, // 하위 그룹 목록 조회
}

/**
 * 채널 레벨 권한 (L2: Channel-Level)
 *
 * 특정 채널에서만 적용되는 미시적 권한을 정의한다.
 * ChannelRoleBinding을 통해 역할별로 채널마다 다르게 설정할 수 있다.
 */
enum class ChannelPermission {
    // ===== 게시글 권한 =====
    POST_READ, // 게시글 읽기
    POST_WRITE, // 게시글 작성
    POST_EDIT_OWN, // 본인 게시글 수정
    POST_DELETE_OWN, // 본인 게시글 삭제

    // ===== 댓글 권한 =====
    COMMENT_READ, // 댓글 읽기
    COMMENT_WRITE, // 댓글 작성
    COMMENT_EDIT_OWN, // 본인 댓글 수정
    COMMENT_DELETE_OWN, // 본인 댓글 삭제

    // ===== 채널 관리 권한 =====
    CHANNEL_SETTINGS, // 채널 설정 변경
}

/**
 * 시스템 역할 (수정/삭제 불가)
 *
 * 모든 그룹에 기본으로 생성되는 불변 역할.
 * 헌법 III. RBAC + Override 권한 시스템에 따라 보호된다.
 */
enum class SystemRole(val displayName: String, val priority: Int) {
    OWNER("그룹장", 100), // 최고 권한
    PROFESSOR("교수", 90), // 지도교수 (선택적)
    MEMBER("멤버", 10), // 기본 멤버
}

/**
 * 시스템 역할별 기본 그룹 권한 매핑
 */
object DefaultGroupPermissions {
    val OWNER_PERMISSIONS: Set<GroupPermission> = GroupPermission.entries.toSet()

    val PROFESSOR_PERMISSIONS: Set<GroupPermission> =
        setOf(
            GroupPermission.GROUP_MANAGE,
            GroupPermission.ADMIN_VIEW,
            GroupPermission.MEMBER_VIEW,
            GroupPermission.MEMBER_MANAGE,
            GroupPermission.ROLE_ASSIGN,
            GroupPermission.CHANNEL_READ,
            GroupPermission.CHANNEL_MANAGE,
            GroupPermission.POST_MANAGE,
            GroupPermission.COMMENT_MANAGE,
            GroupPermission.RECRUITMENT_VIEW,
            GroupPermission.RECRUITMENT_MANAGE,
            GroupPermission.CALENDAR_VIEW,
            GroupPermission.CALENDAR_MANAGE,
            GroupPermission.PLACE_RESERVE,
            GroupPermission.SUBGROUP_VIEW,
        )

    val MEMBER_PERMISSIONS: Set<GroupPermission> =
        setOf(
            GroupPermission.MEMBER_VIEW,
            GroupPermission.CHANNEL_READ,
            GroupPermission.RECRUITMENT_VIEW,
            GroupPermission.CALENDAR_VIEW,
            GroupPermission.PLACE_RESERVE,
            GroupPermission.SUBGROUP_VIEW,
        )

    fun getDefaultPermissions(role: SystemRole): Set<GroupPermission> =
        when (role) {
            SystemRole.OWNER -> OWNER_PERMISSIONS
            SystemRole.PROFESSOR -> PROFESSOR_PERMISSIONS
            SystemRole.MEMBER -> MEMBER_PERMISSIONS
        }
}

/**
 * 채널 타입별 기본 권한 템플릿
 */
object DefaultChannelPermissions {
    /**
     * 공지사항 채널: 그룹장/교수만 작성, 멤버는 읽기만
     */
    val ANNOUNCEMENT_OWNER: Set<ChannelPermission> =
        setOf(
            ChannelPermission.POST_READ,
            ChannelPermission.POST_WRITE,
            ChannelPermission.POST_EDIT_OWN,
            ChannelPermission.POST_DELETE_OWN,
            ChannelPermission.COMMENT_READ,
            ChannelPermission.COMMENT_WRITE,
            ChannelPermission.COMMENT_EDIT_OWN,
            ChannelPermission.COMMENT_DELETE_OWN,
            ChannelPermission.CHANNEL_SETTINGS,
        )

    val ANNOUNCEMENT_MEMBER: Set<ChannelPermission> =
        setOf(
            ChannelPermission.POST_READ,
            ChannelPermission.COMMENT_READ,
            ChannelPermission.COMMENT_WRITE,
            ChannelPermission.COMMENT_EDIT_OWN,
            ChannelPermission.COMMENT_DELETE_OWN,
        )

    /**
     * 일반 게시판: 모든 멤버 읽기/쓰기 가능
     */
    val TEXT_ALL: Set<ChannelPermission> =
        setOf(
            ChannelPermission.POST_READ,
            ChannelPermission.POST_WRITE,
            ChannelPermission.POST_EDIT_OWN,
            ChannelPermission.POST_DELETE_OWN,
            ChannelPermission.COMMENT_READ,
            ChannelPermission.COMMENT_WRITE,
            ChannelPermission.COMMENT_EDIT_OWN,
            ChannelPermission.COMMENT_DELETE_OWN,
        )
}
