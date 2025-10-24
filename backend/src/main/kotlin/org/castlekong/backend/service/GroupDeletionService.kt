package org.castlekong.backend.service

import org.castlekong.backend.entity.Group
import org.castlekong.backend.exception.BusinessException
import org.castlekong.backend.exception.ErrorCode
import org.castlekong.backend.repository.ChannelRepository
import org.castlekong.backend.repository.CommentRepository
import org.castlekong.backend.repository.GroupJoinRequestRepository
import org.castlekong.backend.repository.GroupMemberRepository
import org.castlekong.backend.repository.GroupRepository
import org.castlekong.backend.repository.GroupRoleRepository
import org.castlekong.backend.repository.PostRepository
import org.castlekong.backend.repository.SubGroupRequestRepository
import org.castlekong.backend.repository.WorkspaceRepository
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDateTime

@Service
@Transactional
class GroupDeletionService(
    private val groupRepository: GroupRepository,
    private val channelRepository: ChannelRepository,
    private val postRepository: PostRepository,
    private val commentRepository: CommentRepository,
    private val workspaceRepository: WorkspaceRepository,
    private val groupJoinRequestRepository: GroupJoinRequestRepository,
    private val subGroupRequestRepository: SubGroupRequestRepository,
    private val groupMemberRepository: GroupMemberRepository,
    private val groupRoleRepository: GroupRoleRepository,
) {
    companion object {
        private val logger = LoggerFactory.getLogger(GroupDeletionService::class.java)
    }

    fun deleteGroup(
        groupId: Long,
        userId: Long,
    ) {
        val group =
            groupRepository.findById(groupId)
                .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }

        // 권한 확인 (그룹 소유자만 삭제 가능)
        if (group.owner.id != userId) {
            throw BusinessException(ErrorCode.FORBIDDEN)
        }

        // 소프트 딜리트: deletedAt 필드 설정 (새 Group 객체 생성)
        val deletedGroup =
            Group(
                id = group.id,
                name = group.name,
                description = group.description,
                profileImageUrl = group.profileImageUrl,
                owner = group.owner,
                parent = group.parent,
                university = group.university,
                college = group.college,
                department = group.department,
                groupType = group.groupType,
                maxMembers = group.maxMembers,
                defaultChannelsCreated = group.defaultChannelsCreated,
                tags = group.tags,
                createdAt = group.createdAt,
                updatedAt = LocalDateTime.now(),
                deletedAt = LocalDateTime.now(),
            )
        groupRepository.save(deletedGroup)

        // 하위 그룹들도 소프트 딜리트
        softDeleteSubGroups(group.id, userId)
    }

    fun softDeleteSubGroups(
        parentGroupId: Long,
        deletedBy: Long,
    ) {
        // 모든 하위 그룹 ID를 한 번에 조회 (배치 최적화)
        val allDescendantIds = groupRepository.findAllDescendantIds(parentGroupId)

        if (allDescendantIds.isNotEmpty()) {
            // 배치로 한 번에 소프트 딜리트 처리
            groupRepository.softDeleteByIds(allDescendantIds)

            // 관련 데이터들도 배치로 정리 (필요시)
            cleanupRelatedDataBatch(allDescendantIds)
        }
    }

    fun cleanupRelatedDataBatch(groupIds: List<Long>) {
        // 배치 크기로 청크 단위 처리 (메모리 효율성)
        val batchSize = 100
        groupIds.chunked(batchSize).forEach { chunk ->
            try {
                // 외래키 삭제 순서: ChannelRoleBinding → Comments → Posts → Channels → GroupMembers → GroupRoles → Groups
                val channelIds = channelRepository.findChannelIdsByGroupIds(chunk)
                if (channelIds.isNotEmpty()) {
                    val postIds = postRepository.findPostIdsByChannelIds(channelIds)
                    if (postIds.isNotEmpty()) {
                        // 댓글 -> 게시물 -> 채널 순서로 삭제
                        commentRepository.deleteByPostIds(postIds)
                        postRepository.deleteByChannelIds(channelIds)
                    }
                    channelRepository.deleteByGroupIds(chunk)
                }

                // 그룹 관련 데이터 정리
                workspaceRepository.deleteByGroupIds(chunk)
                groupJoinRequestRepository.deleteByGroupIds(chunk)
                subGroupRequestRepository.deleteByParentGroupIds(chunk)
                groupMemberRepository.deleteByGroupIds(chunk)
                groupRoleRepository.deleteByGroupIds(chunk)
            } catch (e: Exception) {
                // 로그 기록 후 계속 진행 (부분 실패 허용)
                logger.warn("배치 정리 중 오류 발생 - 그룹 IDs: $chunk", e)
            }
        }
    }
}
