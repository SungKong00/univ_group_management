package org.castlekong.backend.service

import org.castlekong.backend.entity.*
import org.castlekong.backend.repository.ChannelRepository
import org.castlekong.backend.repository.ChannelRoleBindingRepository
import org.springframework.stereotype.Service

@Service
class ChannelInitializationService(
    private val channelRepository: ChannelRepository,
    private val channelRoleBindingRepository: ChannelRoleBindingRepository,
) {

    fun createDefaultChannels(group: Group, ownerRole: GroupRole, memberRole: GroupRole) {
        // 공지사항 채널 생성
        val announcementChannel = createAnnouncementChannel(group)
        createAnnouncementChannelBindings(announcementChannel, ownerRole, memberRole)

        // 자유게시판 채널 생성
        val textChannel = createTextChannel(group)
        createTextChannelBindings(textChannel, ownerRole, memberRole)
    }

    fun ensureDefaultChannelsExist(group: Group, ownerRole: GroupRole, memberRole: GroupRole): Boolean {
        val hasAnnouncement = channelRepository.findByGroupIdAndType(group.id, ChannelType.ANNOUNCEMENT).isNotEmpty()
        val hasText = channelRepository.findByGroupIdAndType(group.id, ChannelType.TEXT).isNotEmpty()

        var created = false

        if (!hasAnnouncement) {
            val announcementChannel = createAnnouncementChannel(group)
            createAnnouncementChannelBindings(announcementChannel, ownerRole, memberRole)
            created = true
        }

        if (!hasText) {
            val textChannel = createTextChannel(group)
            createTextChannelBindings(textChannel, ownerRole, memberRole)
            created = true
        }

        return created
    }

    private fun createAnnouncementChannel(group: Group): Channel {
        val channel = Channel(
            group = group,
            name = "공지사항",
            description = "그룹 공지사항 채널",
            type = ChannelType.ANNOUNCEMENT,
            displayOrder = 0,
            createdBy = group.owner,
        )
        return channelRepository.save(channel)
    }

    private fun createTextChannel(group: Group): Channel {
        val channel = Channel(
            group = group,
            name = "자유게시판",
            description = "자유롭게 대화하는 채널",
            type = ChannelType.TEXT,
            displayOrder = 1,
            createdBy = group.owner,
        )
        return channelRepository.save(channel)
    }

    private fun createAnnouncementChannelBindings(channel: Channel, ownerRole: GroupRole, memberRole: GroupRole) {
        // OWNER: 모든 권한
        val ownerBinding = ChannelRoleBinding.create(
            channel = channel,
            groupRole = ownerRole,
            permissions = setOf(
                ChannelPermission.CHANNEL_VIEW,
                ChannelPermission.POST_READ,
                ChannelPermission.POST_WRITE,
                ChannelPermission.COMMENT_WRITE,
                ChannelPermission.FILE_UPLOAD
            )
        )

        // MEMBER: 읽기 + 댓글 작성
        val memberBinding = ChannelRoleBinding.create(
            channel = channel,
            groupRole = memberRole,
            permissions = setOf(
                ChannelPermission.CHANNEL_VIEW,
                ChannelPermission.POST_READ,
                ChannelPermission.COMMENT_WRITE
            )
        )

        channelRoleBindingRepository.save(ownerBinding)
        channelRoleBindingRepository.save(memberBinding)
    }

    private fun createTextChannelBindings(channel: Channel, ownerRole: GroupRole, memberRole: GroupRole) {
        // OWNER: 모든 권한
        val ownerBinding = ChannelRoleBinding.create(
            channel = channel,
            groupRole = ownerRole,
            permissions = setOf(
                ChannelPermission.CHANNEL_VIEW,
                ChannelPermission.POST_READ,
                ChannelPermission.POST_WRITE,
                ChannelPermission.COMMENT_WRITE,
                ChannelPermission.FILE_UPLOAD
            )
        )

        // MEMBER: 읽기/쓰기/댓글 작성
        val memberBinding = ChannelRoleBinding.create(
            channel = channel,
            groupRole = memberRole,
            permissions = setOf(
                ChannelPermission.CHANNEL_VIEW,
                ChannelPermission.POST_READ,
                ChannelPermission.POST_WRITE,
                ChannelPermission.COMMENT_WRITE
            )
        )

        channelRoleBindingRepository.save(ownerBinding)
        channelRoleBindingRepository.save(memberBinding)
    }
}