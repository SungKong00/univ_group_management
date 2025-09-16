package org.castlekong.backend.entity

import jakarta.persistence.*
import java.time.LocalDateTime

/**
 * 채널 권한 템플릿
 * 재사용 가능한 권한 프리셋을 정의
 */
@Entity
@Table(name = "channel_permission_templates")
data class ChannelPermissionTemplate(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    /**
     * 소속 그룹 (null이면 글로벌 템플릿)
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "group_id")
    val group: Group? = null,

    /**
     * 템플릿 이름 (예: "일반 멤버", "모더레이터", "관리자")
     */
    @Column(nullable = false, length = 100)
    val name: String,

    /**
     * 템플릿 설명
     */
    @Column(columnDefinition = "TEXT")
    val description: String? = null,

    /**
     * 권한 비트마스크
     */
    @Column(name = "permissions_mask", nullable = false)
    val permissionsMask: Long = 0L,

    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now()
) {
    /**
     * 권한 목록을 ChannelPermission Set으로 반환
     */
    fun getPermissions(): Set<ChannelPermission> {
        return ChannelPermission.fromMask(permissionsMask)
    }

    /**
     * 특정 권한 보유 여부 확인
     */
    fun hasPermission(permission: ChannelPermission): Boolean {
        return (permissionsMask and permission.mask) != 0L
    }

    companion object {
        /**
         * 권한 목록으로 템플릿 생성
         */
        fun create(
            group: Group? = null,
            name: String,
            description: String? = null,
            permissions: Set<ChannelPermission>
        ): ChannelPermissionTemplate {
            return ChannelPermissionTemplate(
                group = group,
                name = name,
                description = description,
                permissionsMask = ChannelPermission.toMask(permissions)
            )
        }

        /**
         * 기본 템플릿들
         */
        fun getDefaultTemplates(): List<ChannelPermissionTemplate> {
            return listOf(
                // 읽기 전용
                create(
                    name = "읽기 전용",
                    description = "게시글과 댓글을 읽을 수만 있음",
                    permissions = setOf(
                        ChannelPermission.CHANNEL_VIEW,
                        ChannelPermission.POST_READ,
                        ChannelPermission.COMMENT_READ
                    )
                ),

                // 일반 멤버
                create(
                    name = "일반 멤버",
                    description = "게시글과 댓글 작성, 본인 글 수정/삭제 가능",
                    permissions = setOf(
                        ChannelPermission.CHANNEL_VIEW,
                        ChannelPermission.POST_READ,
                        ChannelPermission.POST_CREATE,
                        ChannelPermission.POST_UPDATE_OWN,
                        ChannelPermission.POST_DELETE_OWN,
                        ChannelPermission.COMMENT_READ,
                        ChannelPermission.COMMENT_CREATE,
                        ChannelPermission.COMMENT_UPDATE_OWN,
                        ChannelPermission.COMMENT_DELETE_OWN
                    )
                ),

                // 모더레이터
                create(
                    name = "모더레이터",
                    description = "모든 게시글/댓글 관리 가능",
                    permissions = setOf(
                        ChannelPermission.CHANNEL_VIEW,
                        ChannelPermission.POST_READ,
                        ChannelPermission.POST_CREATE,
                        ChannelPermission.POST_UPDATE_ALL,
                        ChannelPermission.POST_DELETE_ALL,
                        ChannelPermission.POST_PIN,
                        ChannelPermission.COMMENT_READ,
                        ChannelPermission.COMMENT_CREATE,
                        ChannelPermission.COMMENT_UPDATE_ALL,
                        ChannelPermission.COMMENT_DELETE_ALL,
                        ChannelPermission.MEMBER_MENTION
                    )
                ),

                // 관리자
                create(
                    name = "관리자",
                    description = "모든 권한 보유",
                    permissions = ChannelPermission.values().toSet()
                )
            )
        }
    }
}