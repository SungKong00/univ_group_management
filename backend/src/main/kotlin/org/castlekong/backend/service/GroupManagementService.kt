package org.castlekong.backend.service

import org.castlekong.backend.dto.CreateGroupRequest
import org.castlekong.backend.dto.GroupHierarchyNodeDto
import org.castlekong.backend.dto.GroupResponse
import org.castlekong.backend.dto.GroupSummaryResponse
import org.castlekong.backend.dto.UpdateGroupRequest
import org.castlekong.backend.entity.Group
import org.castlekong.backend.entity.GroupMember
import org.castlekong.backend.entity.GroupRole
import org.castlekong.backend.entity.GroupType
import org.castlekong.backend.entity.User
import org.castlekong.backend.exception.BusinessException
import org.castlekong.backend.exception.ErrorCode
import org.castlekong.backend.repository.ChannelRepository
import org.castlekong.backend.repository.ChannelRoleBindingRepository
import org.castlekong.backend.repository.CommentRepository
import org.castlekong.backend.repository.GroupJoinRequestRepository
import org.castlekong.backend.repository.GroupMemberRepository
import org.castlekong.backend.repository.GroupRepository
import org.castlekong.backend.repository.GroupRoleRepository
import org.castlekong.backend.repository.PostRepository
import org.castlekong.backend.repository.SubGroupRequestRepository
import org.castlekong.backend.repository.UserRepository
import org.castlekong.backend.repository.WorkspaceRepository
import org.slf4j.LoggerFactory
import org.springframework.data.domain.Page
import org.springframework.data.domain.PageRequest
import org.springframework.data.domain.Pageable
import org.springframework.data.domain.Sort
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
    private val channelInitializationService: ChannelInitializationService,
    private val groupRoleInitializationService: GroupRoleInitializationService,
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
                groupType = request.groupType,
                isRecruiting = request.isRecruiting,
                maxMembers = request.maxMembers,
                tags = request.tags,
            )

        val savedGroup = groupRepository.save(group)

        // 그룹 생성자를 자동으로 OWNER 역할로 추가하고 역할들 반환
        val roles = createDefaultRolesAndAddOwner(savedGroup, owner)

        // 기본 채널 생성 및 권한 바인딩 설정
        channelInitializationService.createDefaultChannels(savedGroup, roles.first, roles.second, roles.third)

        // 기본 채널 생성 완료 플래그 설정
        groupRepository.save(savedGroup.copy(defaultChannelsCreated = true))

        return groupMapper.toGroupResponse(savedGroup)
    }

    private fun createDefaultRolesAndAddOwner(
        group: Group,
        owner: User,
    ): Triple<GroupRole, GroupRole, GroupRole> {
        // Use GroupRoleInitializationService to create default roles
        val roles = groupRoleInitializationService.ensureDefaultRoles(group)
        val ownerRole = roles.find { it.name == "OWNER" }!!
        val advisorRole = roles.find { it.name == "ADVISOR" }!!
        val memberRole = roles.find { it.name == "MEMBER" }!!

        // 그룹 생성자를 OWNER로 추가
        val groupMember =
            GroupMember(
                group = group,
                user = owner,
                role = ownerRole,
                joinedAt = LocalDateTime.now(),
            )
        groupMemberRepository.save(groupMember)

        return Triple(ownerRole, advisorRole, memberRole)
    }

    @Transactional
    fun ensureDefaultChannelsIfNeeded(group: Group) {
        if (group.deletedAt != null) return
        if (group.defaultChannelsCreated) return

        val ownerRole =
            groupRoleRepository.findByGroupIdAndName(group.id, "OWNER")
                .orElseThrow { BusinessException(ErrorCode.GROUP_ROLE_NOT_FOUND) }
        val advisorRole = groupRoleRepository.findByGroupIdAndName(group.id, "ADVISOR").orElse(null)
        val memberRole =
            groupRoleRepository.findByGroupIdAndName(group.id, "MEMBER")
                .orElseThrow { BusinessException(ErrorCode.GROUP_ROLE_NOT_FOUND) }

        val wasCreated =
            channelInitializationService.ensureDefaultChannelsExist(group, ownerRole, advisorRole, memberRole)

        if (wasCreated) {
            groupRepository.save(group.copy(defaultChannelsCreated = true))
        }
    }

    fun getGroup(groupId: Long): GroupResponse {
        val group =
            groupRepository.findById(groupId)
                .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }
        if (group.deletedAt != null) throw BusinessException(ErrorCode.GROUP_NOT_FOUND)
        return groupMapper.toGroupResponse(group)
    }

    fun getGroups(pageable: Pageable): Page<GroupSummaryResponse> {
        val sortedPageable =
            PageRequest.of(pageable.pageNumber, pageable.pageSize, Sort.by(Sort.Direction.DESC, "createdAt", "id"))
        return groupRepository.findByDeletedAtIsNull(sortedPageable)
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
        groupType: GroupType?,
        university: String?,
        college: String?,
        department: String?,
        q: String?,
        tags: Set<String>,
    ): Page<GroupSummaryResponse> {
        return groupRepository.search(
            recruiting,
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
