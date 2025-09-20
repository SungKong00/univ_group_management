package org.castlekong.backend.service

import org.castlekong.backend.dto.*
import org.castlekong.backend.entity.*
import org.castlekong.backend.exception.BusinessException
import org.castlekong.backend.exception.ErrorCode
import org.castlekong.backend.repository.*
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
@Transactional(readOnly = true)
class WorkspaceManagementService(
    private val groupRepository: GroupRepository,
    private val groupMemberRepository: GroupMemberRepository,
    private val channelRepository: ChannelRepository,
    private val postRepository: PostRepository,
    private val groupMapper: GroupMapper,
) {
    // === 워크스페이스 조회 (명세서 요구사항) ===
    fun getWorkspace(
        groupId: Long,
        userId: Long,
    ): WorkspaceDto {
        val group =
            groupRepository.findById(groupId)
                .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }

        if (group.deletedAt != null) {
            throw BusinessException(ErrorCode.GROUP_NOT_FOUND)
        }

        // 사용자가 그룹 멤버인지 확인
        val member =
            groupMemberRepository.findByGroupIdAndUserId(groupId, userId)
                .orElseThrow { BusinessException(ErrorCode.GROUP_MEMBER_NOT_FOUND) }

        // 공지사항 조회 (ANNOUNCEMENT 타입 채널의 게시물)
        val noticeChannels = channelRepository.findByGroupIdAndType(groupId, ChannelType.ANNOUNCEMENT)
        val notices =
            if (noticeChannels.isNotEmpty()) {
                postRepository.findByChannelIdInOrderByCreatedAtDesc(noticeChannels.map { it.id })
                    .take(10) // 최근 10개 공지만
                    .map { post ->
                        PostResponse(
                            id = post.id,
                            channelId = post.channel.id,
                            author = groupMapper.toUserSummaryResponse(post.author),
                            content = post.content,
                            type = post.type.name,
                            isPinned = post.isPinned,
                            viewCount = post.viewCount,
                            likeCount = post.likeCount,
                            commentCount = post.commentCount,
                            lastCommentedAt = post.lastCommentedAt,
                            attachments = post.attachments,
                            createdAt = post.createdAt,
                            updatedAt = post.updatedAt,
                        )
                    }
            } else {
                emptyList()
            }

        // 채널 목록 조회
        val channels =
            channelRepository.findByGroupIdOrderByDisplayOrder(groupId)
                .map { channel ->
                    ChannelResponse(
                        id = channel.id,
                        groupId = channel.group.id,
                        name = channel.name,
                        description = channel.description,
                        type = channel.type.name,
                        isPrivate = channel.isPrivate,
                        displayOrder = channel.displayOrder,
                        createdAt = channel.createdAt,
                        updatedAt = channel.updatedAt,
                    )
                }

        // 멤버 목록 조회
        val members =
            groupMemberRepository.findByGroupIdOrderByJoinedAtAsc(groupId)
                .map { groupMapper.toGroupMemberResponse(it) }

        return WorkspaceDto(
            groupId = group.id,
            groupName = group.name,
            myRole = member.role.name,
            myMembership = groupMapper.toGroupMemberResponse(member),
            notices = notices,
            channels = channels,
            members = members,
        )
    }
}
