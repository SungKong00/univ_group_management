package org.castlekong.backend.service

import org.castlekong.backend.dto.*
import org.castlekong.backend.entity.*
import org.castlekong.backend.exception.BusinessException
import org.castlekong.backend.exception.ErrorCode
import org.castlekong.backend.repository.*
import org.castlekong.backend.entity.ChannelRoleBinding
import org.slf4j.LoggerFactory
import org.springframework.data.domain.Page
import org.springframework.data.domain.PageRequest
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDateTime

@Service
@Transactional(readOnly = true)
class GroupManagementService(
    private val groupRepository: GroupRepository,
    private val groupRoleRepository: GroupRoleRepository,
    private val userRepository: UserRepository,
    private val channelRepository: ChannelRepository,
    private val channelRoleBindingRepository: ChannelRoleBindingRepository,
    private val groupMemberRepository: GroupMemberRepository,
    private val postRepository: PostRepository,
    private val commentRepository: CommentRepository,
    private val workspaceRepository: WorkspaceRepository,
    private val groupJoinRequestRepository: GroupJoinRequestRepository,
    private val subGroupRequestRepository: SubGroupRequestRepository,
    private val groupMapper: GroupMapper,
) {
    companion object {
        private val logger = LoggerFactory.getLogger(GroupManagementService::class.java)
    }

    @Transactional
    fun createGroup(
        request: CreateGroupRequest,
        ownerId: Long,
    ): GroupResponse {
        val owner =
            userRepository.findById(ownerId)
                .orElseThrow { BusinessException(ErrorCode.USER_NOT_FOUND) }

        // 부모 그룹 확인 (하위 그룹 생성 시)
        val parentGroup =
            request.parentId?.let { parentId ->
                groupRepository.findById(parentId)
                    .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }
            }

        val group =
            Group(
                name = request.name,
                description = request.description,
                profileImageUrl = request.profileImageUrl,
                owner = owner,
                parent = parentGroup,
                university = request.university,
                college = request.college,
                department = request.department,
                visibility = request.visibility,
                groupType = request.groupType,
                isRecruiting = request.isRecruiting,
                maxMembers = request.maxMembers,
                tags = request.tags,
            )

        val savedGroup = groupRepository.save(group)

        // 그룹 생성자를 자동으로 OWNER 역할로 추가하고 역할들 반환
        val roles = createDefaultRolesAndAddOwner(savedGroup, owner)

        // 기본 채널 생성 및 권한 바인딩 설정
        createDefaultChannels(savedGroup, roles)

        return groupMapper.toGroupResponse(savedGroup)
    }

    private fun createDefaultRolesAndAddOwner(
        group: Group,
        owner: User,
    ): Triple<GroupRole, GroupRole, GroupRole> {
        // 기본 역할들 생성
        val ownerRole =
            GroupRole(
                group = group,
                name = "OWNER",
                isSystemRole = true,
                permissions = GroupPermission.values().toSet(),
                priority = 100,
            )

        val professorRole =
            GroupRole(
                group = group,
                name = "ADVISOR",
                isSystemRole = true,
                permissions = GroupPermission.values().toSet(), // preset refined in evaluator
                priority = 99,
            )

        val memberRole =
            GroupRole(
                group = group,
                name = "MEMBER",
                isSystemRole = true,
                permissions = setOf(GroupPermission.WORKSPACE_ACCESS),
                priority = 1,
            )

        val savedOwnerRole = groupRoleRepository.save(ownerRole)
        val savedProfessorRole = groupRoleRepository.save(professorRole)
        val savedMemberRole = groupRoleRepository.save(memberRole)

        // 그룹 생성자를 OWNER로 추가
        val groupMember =
            GroupMember(
                group = group,
                user = owner,
                role = savedOwnerRole,
                joinedAt = LocalDateTime.now(),
            )
        groupMemberRepository.save(groupMember)

        return Triple(savedOwnerRole, savedProfessorRole, savedMemberRole)
    }

    private fun createDefaultChannels(
        group: Group,
        roles: Triple<GroupRole, GroupRole, GroupRole>,
    ) {
        val (ownerRole, _, memberRole) = roles

        // 공지 채널: OWNER만 작성, 모든 MEMBER 읽기
        val announcement =
            Channel(
                group = group,
                name = "공지",
                description = "그룹 공지 채널",
                type = ChannelType.ANNOUNCEMENT,
                isPrivate = false,
                displayOrder = 0,
                createdBy = group.owner,
            )
        val savedAnnouncement = channelRepository.save(announcement)

        // 공지 채널 권한 바인딩
        val announcementOwnerBinding = ChannelRoleBinding.create(
            channel = savedAnnouncement,
            groupRole = ownerRole,
            permissions = setOf(ChannelPermission.CHANNEL_VIEW, ChannelPermission.POST_WRITE)
        )
        val announcementMemberBinding = ChannelRoleBinding.create(
            channel = savedAnnouncement,
            groupRole = memberRole,
            permissions = setOf(ChannelPermission.CHANNEL_VIEW, ChannelPermission.POST_READ)
        )
        channelRoleBindingRepository.save(announcementOwnerBinding)
        channelRoleBindingRepository.save(announcementMemberBinding)

        // 자유 채널: 모든 MEMBER가 읽기/쓰기
        val free =
            Channel(
                group = group,
                name = "자유",
                description = "자유롭게 대화하는 채널",
                type = ChannelType.TEXT,
                isPrivate = false,
                displayOrder = 1,
                createdBy = group.owner,
            )
        val savedFree = channelRepository.save(free)

        // 자유 채널 권한 바인딩
        val freeMemberBinding = ChannelRoleBinding.create(
            channel = savedFree,
            groupRole = memberRole,
            permissions = setOf(
                ChannelPermission.CHANNEL_VIEW,
                ChannelPermission.POST_READ,
                ChannelPermission.POST_WRITE,
                ChannelPermission.COMMENT_WRITE
            )
        )
        channelRoleBindingRepository.save(freeMemberBinding)
    }

    fun getGroup(groupId: Long): GroupResponse {
        val group =
            groupRepository.findById(groupId)
                .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }
        if (group.deletedAt != null) throw BusinessException(ErrorCode.GROUP_NOT_FOUND)
        return groupMapper.toGroupResponse(group)
    }

    fun getGroups(pageable: Pageable): Page<GroupSummaryResponse> {
        return groupRepository.findByDeletedAtIsNull(pageable)
            .map { group ->
                val memberCount = getGroupMemberCountWithHierarchy(group)
                groupMapper.toGroupSummaryResponse(group, memberCount.toInt())
            }
    }

    fun getAllGroups(): List<GroupSummaryResponse> {
        return getAllGroupsChunked()
    }

    fun getAllGroupsChunked(chunkSize: Int = 100): List<GroupSummaryResponse> {
        val allGroups = mutableListOf<GroupSummaryResponse>()
        var offset = 0

        do {
            val chunk =
                groupRepository.findAll(PageRequest.of(offset / chunkSize, chunkSize))
                    .content
                    .filter { it.deletedAt == null }
                    .map { group ->
                        val memberCount = getGroupMemberCountWithHierarchy(group)
                        groupMapper.toGroupSummaryResponse(group, memberCount.toInt())
                    }

            allGroups.addAll(chunk)
            offset += chunkSize
        } while (chunk.size == chunkSize)

        return allGroups
    }

    private fun getGroupMemberCountWithHierarchy(group: Group): Long {
        return when (group.groupType) {
            GroupType.UNIVERSITY, GroupType.COLLEGE -> {
                // 대학교나 계열인 경우 하위 그룹 멤버들도 포함하여 집계
                groupMemberRepository.countMembersWithHierarchy(group.id)
            }
            else -> {
                // 학과나 기타 그룹인 경우 직접 가입 멤버만 집계
                groupMemberRepository.countByGroupId(group.id)
            }
        }
    }

    @Transactional
    fun updateGroup(
        groupId: Long,
        request: UpdateGroupRequest,
        userId: Long,
    ): GroupResponse {
        val group =
            groupRepository.findById(groupId)
                .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }

        // 권한 확인 (그룹 소유자만 수정 가능)
        if (group.owner.id != userId) {
            throw BusinessException(ErrorCode.FORBIDDEN)
        }

        val updatedGroup =
            group.copy(
                name = request.name ?: group.name,
                description = request.description ?: group.description,
                profileImageUrl = request.profileImageUrl ?: group.profileImageUrl,
                visibility = request.visibility ?: group.visibility,
                groupType = request.groupType ?: group.groupType,
                isRecruiting = request.isRecruiting ?: group.isRecruiting,
                maxMembers = request.maxMembers ?: group.maxMembers,
                tags = request.tags ?: group.tags,
                updatedAt = LocalDateTime.now(),
            )

        return groupMapper.toGroupResponse(groupRepository.save(updatedGroup))
    }

    @Transactional
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

        // 소프트 딜리트: deletedAt 필드 설정
        val deletedGroup =
            group.copy(
                deletedAt = LocalDateTime.now(),
                updatedAt = LocalDateTime.now(),
            )
        groupRepository.save(deletedGroup)

        // 하위 그룹들도 소프트 딜리트
        softDeleteSubGroups(group.id, userId)
    }

    @Transactional
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

    @Transactional
    fun cleanupRelatedDataBatch(groupIds: List<Long>) {
        // 배치 크기로 청크 단위 처리 (메모리 효율성)
        val batchSize = 100
        groupIds.chunked(batchSize).forEach { chunk ->
            try {
                // 채널 및 컨텐츠 관련 데이터 정리
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

    fun getAllGroupsForHierarchy(): List<GroupHierarchyNodeDto> {
        return groupRepository.findAll()
            .filter { it.deletedAt == null }
            .map { group ->
                GroupHierarchyNodeDto(
                    id = group.id,
                    parentId = group.parent?.id,
                    name = group.name,
                    type = group.groupType,
                )
            }
    }

    fun getSubGroups(parentGroupId: Long): List<GroupSummaryResponse> {
        if (!groupRepository.existsById(parentGroupId)) {
            throw BusinessException(ErrorCode.GROUP_NOT_FOUND)
        }

        return groupRepository.findByParentId(parentGroupId)
            .filter { it.deletedAt == null }
            .map { subGroup ->
                val memberCount = getGroupMemberCountWithHierarchy(subGroup)
                groupMapper.toGroupSummaryResponse(subGroup, memberCount.toInt())
            }
    }

    // === 검색/탐색 ===
    fun searchGroups(
        pageable: Pageable,
        recruiting: Boolean?,
        visibility: GroupVisibility?,
        groupType: GroupType?,
        university: String?,
        college: String?,
        department: String?,
        q: String?,
        tags: Set<String>,
    ): Page<GroupSummaryResponse> {
        return groupRepository.search(
            recruiting,
            visibility,
            groupType,
            university,
            college,
            department,
            q,
            tags,
            tags.size,
            pageable,
        ).map { g ->
            val memberCount = getGroupMemberCountWithHierarchy(g)
            groupMapper.toGroupSummaryResponse(g, memberCount.toInt())
        }
    }
}
