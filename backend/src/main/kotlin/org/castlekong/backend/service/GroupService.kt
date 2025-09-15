package org.castlekong.backend.service

import org.castlekong.backend.dto.*
import org.castlekong.backend.entity.*
import org.castlekong.backend.exception.BusinessException
import org.castlekong.backend.exception.ErrorCode
import org.castlekong.backend.repository.*
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDateTime

@Service
@Transactional(readOnly = true)
class GroupService(
    private val groupRepository: GroupRepository,
    private val groupMemberRepository: GroupMemberRepository,
    private val groupRoleRepository: GroupRoleRepository,
    private val userRepository: UserRepository,
    private val groupJoinRequestRepository: GroupJoinRequestRepository,
    private val subGroupRequestRepository: SubGroupRequestRepository,
    private val channelRepository: ChannelRepository,
    private val postRepository: PostRepository,
    private val commentRepository: CommentRepository,
    private val overrideRepository: org.castlekong.backend.repository.GroupMemberPermissionOverrideRepository,
    private val permissionService: org.castlekong.backend.security.PermissionService,
) {

    @Transactional
    fun createGroup(request: CreateGroupRequest, ownerId: Long): GroupResponse {
        val owner = userRepository.findById(ownerId)
            .orElseThrow { BusinessException(ErrorCode.USER_NOT_FOUND) }

        // 부모 그룹 확인 (하위 그룹 생성 시)
        val parentGroup = request.parentId?.let { parentId ->
            groupRepository.findById(parentId)
                .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }
        }

        val group = Group(
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
            tags = request.tags
        )

        val savedGroup = groupRepository.save(group)

        // 그룹 생성자를 자동으로 OWNER 역할로 추가
        createDefaultRolesAndAddOwner(savedGroup, owner)

        // 기본 채널 생성 (공지, 자유)
        createDefaultChannels(savedGroup, owner)

        return toGroupResponse(savedGroup)
    }

    private fun createDefaultRolesAndAddOwner(group: Group, owner: User) {
        // 기본 역할들 생성
        val ownerRole = GroupRole(
            group = group,
            name = "OWNER",
            isSystemRole = true,
            permissions = GroupPermission.values().toSet(),
            priority = 100
        )
        
        val professorRole = GroupRole(
            group = group,
            name = "ADVISOR",
            isSystemRole = true,
            permissions = GroupPermission.values().toSet(), // preset refined in evaluator
            priority = 99
        )
        
        val memberRole = GroupRole(
            group = group,
            name = "MEMBER",
            isSystemRole = true,
            permissions = setOf(
                GroupPermission.CHANNEL_READ,
                GroupPermission.POST_CREATE,
                GroupPermission.POST_READ,
                GroupPermission.COMMENT_CREATE,
                GroupPermission.COMMENT_READ
            ),
            priority = 1
        )

        val savedOwnerRole = groupRoleRepository.save(ownerRole)
        groupRoleRepository.save(professorRole)
        groupRoleRepository.save(memberRole)

        // 그룹 생성자를 OWNER로 추가
        val groupMember = GroupMember(
            group = group,
            user = owner,
            role = savedOwnerRole,
            joinedAt = LocalDateTime.now()
        )
        groupMemberRepository.save(groupMember)
    }

    private fun createDefaultChannels(group: Group, owner: User) {
        val announcement = Channel(
            group = group,
            name = "공지",
            description = "그룹 공지 채널",
            type = ChannelType.ANNOUNCEMENT,
            isPrivate = false,
            displayOrder = 0,
            createdBy = owner,
        )
        val free = Channel(
            group = group,
            name = "자유",
            description = "자유롭게 대화하는 채널",
            type = ChannelType.TEXT,
            isPrivate = false,
            displayOrder = 1,
            createdBy = owner,
        )
        channelRepository.save(announcement)
        channelRepository.save(free)
    }

    fun getGroup(groupId: Long): GroupResponse {
        val group = groupRepository.findById(groupId)
            .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }
        if (group.deletedAt != null) throw BusinessException(ErrorCode.GROUP_NOT_FOUND)
        return toGroupResponse(group)
    }

    fun getGroups(pageable: Pageable): Page<GroupSummaryResponse> {
        return groupRepository.findByDeletedAtIsNull(pageable)
            .map { group ->
                val memberCount = getGroupMemberCountWithHierarchy(group)
                toGroupSummaryResponse(group, memberCount.toInt())
            }
    }

    fun getAllGroups(): List<GroupSummaryResponse> {
        return groupRepository.findAll().filter { it.deletedAt == null }
            .map { group ->
                val memberCount = getGroupMemberCountWithHierarchy(group)
                toGroupSummaryResponse(group, memberCount.toInt())
            }
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
    fun updateGroup(groupId: Long, request: UpdateGroupRequest, userId: Long): GroupResponse {
        val group = groupRepository.findById(groupId)
            .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }

        // 권한 확인 (그룹 소유자만 수정 가능)
        if (group.owner.id != userId) {
            throw BusinessException(ErrorCode.FORBIDDEN)
        }

        val updatedGroup = group.copy(
            name = request.name ?: group.name,
            description = request.description ?: group.description,
            profileImageUrl = request.profileImageUrl ?: group.profileImageUrl,
            visibility = request.visibility ?: group.visibility,
            groupType = request.groupType ?: group.groupType,
            isRecruiting = request.isRecruiting ?: group.isRecruiting,
            maxMembers = request.maxMembers ?: group.maxMembers,
            tags = request.tags ?: group.tags,
            updatedAt = LocalDateTime.now()
        )

        return toGroupResponse(groupRepository.save(updatedGroup))
    }

    @Transactional
    fun deleteGroup(groupId: Long, userId: Long) {
        val group = groupRepository.findById(groupId)
            .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }

        // 권한 확인 (그룹 소유자만 삭제 가능)
        if (group.owner.id != userId) {
            throw BusinessException(ErrorCode.FORBIDDEN)
        }
        // 단순 삭제: 하위 그룹 포함 연쇄 삭제
        deleteGroupCascade(group)
    }

    @Transactional
    fun deleteGroupCascade(group: Group) {
        // 1. 하위 그룹들을 먼저 재귀적으로 삭제
        val subGroups = groupRepository.findByParentId(group.id)
        subGroups.forEach { deleteGroupCascade(it) }

        // 2. 현재 그룹의 모든 관련 데이터 삭제
        val joinRequests = groupJoinRequestRepository.findByGroupId(group.id)
        groupJoinRequestRepository.deleteAll(joinRequests)

        val subGroupRequests = subGroupRequestRepository.findByParentGroupId(group.id)
        subGroupRequestRepository.deleteAll(subGroupRequests)

        val channels = channelRepository.findByGroup_Id(group.id)
        channels.forEach { ch ->
            val posts = postRepository.findByChannel_Id(ch.id)
            posts.forEach { p ->
                val comments = commentRepository.findByPost_Id(p.id)
                commentRepository.deleteAll(comments)
                postRepository.delete(p)
            }
            channelRepository.delete(ch)
        }

        val roles = groupRoleRepository.findByGroupId(group.id)
        groupRoleRepository.deleteAll(roles)

        val members = groupMemberRepository.findByUserId(group.owner.id).filter { it.group.id == group.id }
        groupMemberRepository.deleteAll(members)

        groupRepository.delete(group)
    }

    @Transactional
    fun joinGroup(groupId: Long, userId: Long): GroupMemberResponse {
        val group = groupRepository.findById(groupId)
            .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }

        val user = userRepository.findById(userId)
            .orElseThrow { BusinessException(ErrorCode.USER_NOT_FOUND) }

        // 이미 멤버인지 확인
        if (groupMemberRepository.findByGroupIdAndUserId(groupId, userId).isPresent) {
            throw BusinessException(ErrorCode.ALREADY_GROUP_MEMBER)
        }

        // 최대 멤버 수 확인
        if (group.maxMembers != null) {
            val currentMemberCount = groupMemberRepository.countByGroupId(groupId)
            if (currentMemberCount >= group.maxMembers) {
                throw BusinessException(ErrorCode.GROUP_FULL)
            }
        }

        // 선택한 그룹에 가입
        val primaryMember = joinGroupDirect(group, user)

        // 계층구조 자동 소속: 상위 그룹들에 자동 가입
        joinParentGroupsAutomatically(group, user)

        return toGroupMemberResponse(primaryMember)
    }

    private fun joinGroupDirect(group: Group, user: User): GroupMember {
        // 기본 MEMBER 역할 확보 (없으면 생성)
        val memberRole = groupRoleRepository.findByGroupIdAndName(group.id, "MEMBER").orElseGet {
            // OWNER / ADVISOR 기본 역할도 보장
            if (!groupRoleRepository.findByGroupIdAndName(group.id, "OWNER").isPresent) {
                groupRoleRepository.save(
                    GroupRole(
                        group = group,
                        name = "OWNER",
                        isSystemRole = true,
                        permissions = GroupPermission.values().toSet(),
                        priority = 100
                    )
                )
            }
            if (!groupRoleRepository.findByGroupIdAndName(group.id, "ADVISOR").isPresent) {
                groupRoleRepository.save(
                    GroupRole(
                        group = group,
                        name = "ADVISOR",
                        isSystemRole = true,
                        permissions = GroupPermission.values().toSet(),
                        priority = 99
                    )
                )
            }
            groupRoleRepository.save(
                GroupRole(
                    group = group,
                    name = "MEMBER",
                    isSystemRole = true,
                    permissions = setOf(
                        GroupPermission.CHANNEL_READ,
                        GroupPermission.POST_CREATE,
                        GroupPermission.POST_READ,
                        GroupPermission.COMMENT_CREATE,
                        GroupPermission.COMMENT_READ
                    ),
                    priority = 1
                )
            )
        }

        val groupMember = GroupMember(
            group = group,
            user = user,
            role = memberRole,
            joinedAt = LocalDateTime.now()
        )

        return groupMemberRepository.save(groupMember)
    }

    private fun joinParentGroupsAutomatically(currentGroup: Group, user: User) {
        // 상위 그룹들을 재귀적으로 찾아서 자동 가입
        var parentGroup = currentGroup.parent
        while (parentGroup != null) {
            // 이미 멤버가 아닌 경우에만 가입
            if (groupMemberRepository.findByGroupIdAndUserId(parentGroup.id, user.id).isEmpty) {
                joinGroupDirect(parentGroup, user)
            }
            parentGroup = parentGroup.parent
        }
    }

    @Transactional
    fun leaveGroup(groupId: Long, userId: Long) {
        val group = groupRepository.findById(groupId)
            .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }

        // 그룹 소유자는 탈퇴할 수 없음
        if (group.owner.id == userId) {
            throw BusinessException(ErrorCode.GROUP_OWNER_CANNOT_LEAVE)
        }

        val groupMember = groupMemberRepository.findByGroupIdAndUserId(groupId, userId)
            .orElseThrow { BusinessException(ErrorCode.GROUP_MEMBER_NOT_FOUND) }

        // 현재 그룹에서 탈퇴
        groupMemberRepository.delete(groupMember)
        // Invalidate permission cache for that member in this group
        permissionService.invalidate(groupId, userId)

        // 계층구조 연쇄 탈퇴: 하위 그룹에서 자동 탈퇴
        leaveChildGroupsAutomatically(group, userId)

        // 상위 그룹에서 연쇄 탈퇴 검토 (해당 사용자가 다른 하위 그룹에 속하지 않은 경우)
        leaveParentGroupsIfNoOtherMembership(group, userId)
    }

    private fun leaveChildGroupsAutomatically(currentGroup: Group, userId: Long) {
        // 현재 그룹의 모든 하위 그룹에서 탈퇴
        val subGroups = groupRepository.findByParentId(currentGroup.id)
        subGroups.forEach { subGroup ->
            val memberInSubGroup = groupMemberRepository.findByGroupIdAndUserId(subGroup.id, userId)
            if (memberInSubGroup.isPresent) {
                groupMemberRepository.delete(memberInSubGroup.get())
                // 재귀적으로 하위 그룹들도 처리
                leaveChildGroupsAutomatically(subGroup, userId)
            }
        }
    }

    private fun leaveParentGroupsIfNoOtherMembership(currentGroup: Group, userId: Long) {
        var parentGroup = currentGroup.parent
        while (parentGroup != null) {
            // 해당 사용자가 이 상위 그룹의 다른 하위 그룹에 속하는지 확인
            val siblingGroups = groupRepository.findByParentId(parentGroup.id)
            val hasOtherMembership = siblingGroups.any { siblingGroup ->
                siblingGroup.id != currentGroup.id &&
                groupMemberRepository.findByGroupIdAndUserId(siblingGroup.id, userId).isPresent
            }

            if (!hasOtherMembership) {
                // 다른 하위 그룹에 속하지 않으므로 상위 그룹에서도 탈퇴
                val parentMember = groupMemberRepository.findByGroupIdAndUserId(parentGroup.id, userId)
                if (parentMember.isPresent) {
                    groupMemberRepository.delete(parentMember.get())
                }
                parentGroup = parentGroup.parent
            } else {
                // 다른 하위 그룹에 속하므로 상위 그룹에는 유지
                break
            }
        }
    }

    fun getGroupMembers(groupId: Long, pageable: Pageable): Page<GroupMemberResponse> {
        // 그룹 존재 여부 확인
        if (!groupRepository.existsById(groupId)) {
            throw BusinessException(ErrorCode.GROUP_NOT_FOUND)
        }

        return groupMemberRepository.findByGroupId(groupId, pageable)
            .map { toGroupMemberResponse(it) }
    }

    fun getAllGroupsForHierarchy(): List<GroupHierarchyNodeDto> {
        return groupRepository.findAll().map { group ->
            GroupHierarchyNodeDto(
                id = group.id,
                parentId = group.parent?.id,
                name = group.name,
                type = group.groupType
            )
        }
    }

    fun getMyMembership(groupId: Long, userId: Long): GroupMemberResponse {
        groupRepository.findById(groupId)
            .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }
        val existing = groupMemberRepository.findByGroupIdAndUserId(groupId, userId)
        if (existing.isPresent) return toGroupMemberResponse(existing.get())
        throw BusinessException(ErrorCode.GROUP_MEMBER_NOT_FOUND)
    }

    @Transactional
    fun removeMember(groupId: Long, targetUserId: Long, requesterId: Long) {
        val group = groupRepository.findById(groupId)
            .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }

        // 그룹장만 멤버 추방 가능 (간소 정책)
        if (group.owner.id != requesterId) {
            throw BusinessException(ErrorCode.FORBIDDEN)
        }

        // 그룹장 본인은 삭제 불가
        if (group.owner.id == targetUserId) {
            throw BusinessException(ErrorCode.INVALID_REQUEST)
        }

        val groupMember = groupMemberRepository.findByGroupIdAndUserId(groupId, targetUserId)
            .orElseThrow { BusinessException(ErrorCode.GROUP_MEMBER_NOT_FOUND) }

        groupMemberRepository.delete(groupMember)
    }

    @Transactional
    fun updateMemberRole(groupId: Long, targetUserId: Long, roleId: Long, requesterId: Long): GroupMemberResponse {
        val group = groupRepository.findById(groupId)
            .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }

        // 그룹장만 역할 변경 가능 (간소 정책)
        if (group.owner.id != requesterId) {
            throw BusinessException(ErrorCode.FORBIDDEN)
        }

        val groupMember = groupMemberRepository.findByGroupIdAndUserId(groupId, targetUserId)
            .orElseThrow { BusinessException(ErrorCode.GROUP_MEMBER_NOT_FOUND) }

        val newRole = groupRoleRepository.findById(roleId)
            .orElseThrow { BusinessException(ErrorCode.GROUP_ROLE_NOT_FOUND) }

        // 역할은 동일 그룹 소속이어야 함
        if (newRole.group.id != groupId) {
            throw BusinessException(ErrorCode.INVALID_REQUEST)
        }

        // OWNER 역할 변경은 위임 API 사용
        if (newRole.name == "OWNER") {
            throw BusinessException(ErrorCode.INVALID_REQUEST)
        }

        val updated = groupMember.copy(role = newRole)
        val saved = groupMemberRepository.save(updated)
        permissionService.invalidate(groupId, targetUserId)
        return toGroupMemberResponse(saved)
    }

    private fun toGroupResponse(group: Group): GroupResponse {
        return GroupResponse(
            id = group.id,
            name = group.name,
            description = group.description,
            profileImageUrl = group.profileImageUrl,
            owner = toUserSummaryResponse(group.owner),
            university = group.university,
            college = group.college,
            department = group.department,
            visibility = group.visibility,
            groupType = group.groupType,
            isRecruiting = group.isRecruiting,
            maxMembers = group.maxMembers,
            tags = group.tags,
            createdAt = group.createdAt,
            updatedAt = group.updatedAt
        )
    }

    private fun toGroupSummaryResponse(group: Group, memberCount: Int): GroupSummaryResponse {
        return GroupSummaryResponse(
            id = group.id,
            name = group.name,
            description = group.description,
            profileImageUrl = group.profileImageUrl,
            university = group.university,
            college = group.college,
            department = group.department,
            visibility = group.visibility,
            groupType = group.groupType,
            isRecruiting = group.isRecruiting,
            memberCount = memberCount,
            tags = group.tags
        )
    }

    private fun toGroupMemberResponse(groupMember: GroupMember): GroupMemberResponse {
        return GroupMemberResponse(
            id = groupMember.id,
            user = toUserSummaryResponse(groupMember.user),
            role = toGroupRoleResponse(groupMember.role),
            joinedAt = groupMember.joinedAt
        )
    }

    private fun toGroupRoleResponse(groupRole: GroupRole): GroupRoleResponse {
        return GroupRoleResponse(
            id = groupRole.id,
            name = groupRole.name,
            permissions = groupRole.permissions.map { it.name }.toSet(),
            priority = groupRole.priority
        )
    }

    // === 하위 그룹 생성 신청 관련 메서드들 ===
    
    @Transactional
    fun createSubGroupRequest(parentGroupId: Long, request: CreateSubGroupRequest, requesterId: Long): SubGroupRequestResponse {
        val requester = userRepository.findById(requesterId)
            .orElseThrow { BusinessException(ErrorCode.USER_NOT_FOUND) }
            
        val parentGroup = groupRepository.findById(parentGroupId)
            .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }
        
        val subGroupRequest = SubGroupRequest(
            requester = requester,
            parentGroup = parentGroup,
            requestedGroupName = request.requestedGroupName,
            requestedGroupDescription = request.requestedGroupDescription,
            requestedUniversity = request.requestedUniversity,
            requestedCollege = request.requestedCollege,
            requestedDepartment = request.requestedDepartment,
            requestedGroupType = request.requestedGroupType,
            requestedMaxMembers = request.requestedMaxMembers
        )
        
        val saved = subGroupRequestRepository.save(subGroupRequest)
        return toSubGroupRequestResponse(saved)
    }
    
    fun getSubGroupRequestsByParentGroup(parentGroupId: Long): List<SubGroupRequestResponse> {
        if (!groupRepository.existsById(parentGroupId)) {
            throw BusinessException(ErrorCode.GROUP_NOT_FOUND)
        }
        
        return subGroupRequestRepository.findByParentGroupId(parentGroupId)
            .map { toSubGroupRequestResponse(it) }
    }
    
    @Transactional
    fun reviewSubGroupRequest(
        requestId: Long,
        reviewRequest: ReviewSubGroupRequestRequest,
        reviewerId: Long
    ): SubGroupRequestResponse {
        val request = subGroupRequestRepository.findById(requestId)
            .orElseThrow { BusinessException(ErrorCode.REQUEST_NOT_FOUND) }
            
        val reviewer = userRepository.findById(reviewerId)
            .orElseThrow { BusinessException(ErrorCode.USER_NOT_FOUND) }
            
        // 그룹장만 승인/반려 가능
        if (request.parentGroup.owner.id != reviewerId) {
            throw BusinessException(ErrorCode.FORBIDDEN)
        }
        
        val status = when (reviewRequest.action) {
            "APPROVE" -> SubGroupRequestStatus.APPROVED
            "REJECT" -> SubGroupRequestStatus.REJECTED
            else -> throw BusinessException(ErrorCode.INVALID_REQUEST)
        }
        
        val updatedRequest = request.copy(
            status = status,
            responseMessage = reviewRequest.responseMessage,
            reviewedBy = reviewer,
            reviewedAt = LocalDateTime.now(),
            updatedAt = LocalDateTime.now()
        )
        
        val saved = subGroupRequestRepository.save(updatedRequest)
        
        // 승인 시 실제 하위 그룹 생성
        if (status == SubGroupRequestStatus.APPROVED) {
            val createGroupRequest = CreateGroupRequest(
                name = request.requestedGroupName,
                description = request.requestedGroupDescription,
                parentId = request.parentGroup.id,
                university = request.requestedUniversity,
                college = request.requestedCollege,
                department = request.requestedDepartment,
                groupType = request.requestedGroupType,
                maxMembers = request.requestedMaxMembers
            )
            createGroup(createGroupRequest, request.requester.id)
        }
        
        return toSubGroupRequestResponse(saved)
    }
    
    // === 그룹 가입 신청 관련 메서드들 ===
    
    @Transactional
    fun createGroupJoinRequest(groupId: Long, requestMessage: String?, userId: Long): GroupJoinRequestResponse {
        val user = userRepository.findById(userId)
            .orElseThrow { BusinessException(ErrorCode.USER_NOT_FOUND) }
            
        val group = groupRepository.findById(groupId)
            .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }
        
        // 이미 멤버인지 확인
        if (groupMemberRepository.findByGroupIdAndUserId(groupId, userId).isPresent) {
            throw BusinessException(ErrorCode.ALREADY_GROUP_MEMBER)
        }
        
        // 이미 대기 중인 신청이 있는지 확인
        if (groupJoinRequestRepository.findByGroupIdAndUserId(groupId, userId).isPresent) {
            throw BusinessException(ErrorCode.REQUEST_ALREADY_EXISTS)
        }
        
        val joinRequest = GroupJoinRequest(
            group = group,
            user = user,
            requestMessage = requestMessage
        )
        
        val saved = groupJoinRequestRepository.save(joinRequest)
        return toGroupJoinRequestResponse(saved)
    }
    
    fun getGroupJoinRequestsByGroup(groupId: Long): List<GroupJoinRequestResponse> {
        if (!groupRepository.existsById(groupId)) {
            throw BusinessException(ErrorCode.GROUP_NOT_FOUND)
        }
        
        return groupJoinRequestRepository.findByGroupIdAndStatus(groupId, GroupJoinRequestStatus.PENDING)
            .map { toGroupJoinRequestResponse(it) }
    }
    
    @Transactional
    fun reviewGroupJoinRequest(
        requestId: Long,
        reviewRequest: ReviewGroupJoinRequestRequest,
        reviewerId: Long
    ): GroupJoinRequestResponse {
        val request = groupJoinRequestRepository.findById(requestId)
            .orElseThrow { BusinessException(ErrorCode.REQUEST_NOT_FOUND) }
            
        val reviewer = userRepository.findById(reviewerId)
            .orElseThrow { BusinessException(ErrorCode.USER_NOT_FOUND) }
            
        // 그룹장만 승인/반려 가능
        if (request.group.owner.id != reviewerId) {
            throw BusinessException(ErrorCode.FORBIDDEN)
        }
        
        val status = when (reviewRequest.action) {
            "APPROVE" -> GroupJoinRequestStatus.APPROVED
            "REJECT" -> GroupJoinRequestStatus.REJECTED
            else -> throw BusinessException(ErrorCode.INVALID_REQUEST)
        }
        
        val updatedRequest = request.copy(
            status = status,
            responseMessage = reviewRequest.responseMessage,
            reviewedBy = reviewer,
            reviewedAt = LocalDateTime.now(),
            updatedAt = LocalDateTime.now()
        )
        
        val saved = groupJoinRequestRepository.save(updatedRequest)
        
        // 승인 시 실제 그룹에 멤버 추가
        if (status == GroupJoinRequestStatus.APPROVED) {
            val memberRole = groupRoleRepository.findByGroupIdAndName(request.group.id, "MEMBER")
                .orElseThrow { BusinessException(ErrorCode.GROUP_ROLE_NOT_FOUND) }
                
            val groupMember = GroupMember(
                group = request.group,
                user = request.user,
                role = memberRole,
                joinedAt = LocalDateTime.now()
            )
            groupMemberRepository.save(groupMember)
        }
        
        return toGroupJoinRequestResponse(saved)
    }
    
    // === 하위 그룹 조회 ===
    
    fun getSubGroups(parentGroupId: Long): List<GroupSummaryResponse> {
        if (!groupRepository.existsById(parentGroupId)) {
            throw BusinessException(ErrorCode.GROUP_NOT_FOUND)
        }

        return groupRepository.findByParentId(parentGroupId)
            .map { subGroup ->
                val memberCount = getGroupMemberCountWithHierarchy(subGroup)
                toGroupSummaryResponse(subGroup, memberCount.toInt())
            }
    }
    
    // === 지도교수 관리 ===
    
    @Transactional
    fun assignProfessor(groupId: Long, professorUserId: Long, ownerUserId: Long): GroupMemberResponse {
        val group = groupRepository.findById(groupId)
            .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }
            
        // 그룹장만 지도교수 지정 가능
        if (group.owner.id != ownerUserId) {
            throw BusinessException(ErrorCode.FORBIDDEN)
        }
        
        val professor = userRepository.findById(professorUserId)
            .orElseThrow { BusinessException(ErrorCode.USER_NOT_FOUND) }
            
        // 지정할 사용자가 실제 교수인지 확인
        if (professor.globalRole != GlobalRole.PROFESSOR) {
            throw BusinessException(ErrorCode.INVALID_REQUEST)
        }
        
        val professorRole = groupRoleRepository.findByGroupIdAndName(groupId, "ADVISOR")
            .orElseThrow { BusinessException(ErrorCode.GROUP_ROLE_NOT_FOUND) }
        
        // 이미 그룹 멤버인지 확인
        val existingMember = groupMemberRepository.findByGroupIdAndUserId(groupId, professorUserId)
        
        if (existingMember.isPresent) {
            // 이미 멤버라면 역할을 지도교수로 변경
            val updated = existingMember.get().copy(role = professorRole)
            val saved = groupMemberRepository.save(updated)
            permissionService.invalidate(groupId, professorUserId)
            return toGroupMemberResponse(saved)
        } else {
            // 새로 지도교수로 추가
            val groupMember = GroupMember(
                group = group,
                user = professor,
                role = professorRole,
                joinedAt = LocalDateTime.now()
            )
            val saved = groupMemberRepository.save(groupMember)
            permissionService.invalidate(groupId, professorUserId)
            return toGroupMemberResponse(saved)
        }
    }
    
    @Transactional
    fun removeProfessor(groupId: Long, professorUserId: Long, ownerUserId: Long) {
        val group = groupRepository.findById(groupId)
            .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }
            
        // 그룹장만 지도교수 해제 가능
        if (group.owner.id != ownerUserId) {
            throw BusinessException(ErrorCode.FORBIDDEN)
        }
        
        val groupMember = groupMemberRepository.findByGroupIdAndUserId(groupId, professorUserId)
            .orElseThrow { BusinessException(ErrorCode.GROUP_MEMBER_NOT_FOUND) }
            
        // 지도교수 역할인지 확인
        if (groupMember.role.name != "ADVISOR") {
            throw BusinessException(ErrorCode.INVALID_REQUEST)
        }
        
        // 일반 멤버로 역할 변경 (완전 제거하지 않음)
        val memberRole = groupRoleRepository.findByGroupIdAndName(groupId, "MEMBER")
            .orElseThrow { BusinessException(ErrorCode.GROUP_ROLE_NOT_FOUND) }
            
        val updated = groupMember.copy(role = memberRole)
        groupMemberRepository.save(updated)
        permissionService.invalidate(groupId, professorUserId)
    }
    
    fun getProfessors(groupId: Long): List<GroupMemberResponse> {
        if (!groupRepository.existsById(groupId)) {
            throw BusinessException(ErrorCode.GROUP_NOT_FOUND)
        }
        
        return groupMemberRepository.findAdvisorsByGroupId(groupId)
            .map { toGroupMemberResponse(it) }
    }
    
    // === 그룹장 권한 위임 및 유고 상황 처리 ===
    
    @Transactional
    fun transferOwnership(groupId: Long, newOwnerId: Long, currentOwnerId: Long): GroupMemberResponse {
        val group = groupRepository.findById(groupId)
            .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }
            
        // 현재 그룹장만 권한 위임 가능
        if (group.owner.id != currentOwnerId) {
            throw BusinessException(ErrorCode.FORBIDDEN)
        }
        
        val newOwner = userRepository.findById(newOwnerId)
            .orElseThrow { BusinessException(ErrorCode.USER_NOT_FOUND) }
            
        val newOwnerMember = groupMemberRepository.findByGroupIdAndUserId(groupId, newOwnerId)
            .orElseThrow { BusinessException(ErrorCode.GROUP_MEMBER_NOT_FOUND) }
            
        val ownerRole = groupRoleRepository.findByGroupIdAndName(groupId, "OWNER")
            .orElseThrow { BusinessException(ErrorCode.GROUP_ROLE_NOT_FOUND) }
            
        val memberRole = groupRoleRepository.findByGroupIdAndName(groupId, "MEMBER")
            .orElseThrow { BusinessException(ErrorCode.GROUP_ROLE_NOT_FOUND) }
        
        // Group 엔티티의 owner 변경
        val updatedGroup = group.copy(owner = newOwner, updatedAt = LocalDateTime.now())
        groupRepository.save(updatedGroup)
        
        // 이전 그룹장을 일반 멤버로 강등
        val currentOwnerMember = groupMemberRepository.findByGroupIdAndUserId(groupId, currentOwnerId)
            .orElseThrow { BusinessException(ErrorCode.GROUP_MEMBER_NOT_FOUND) }
        val demotedOwner = currentOwnerMember.copy(role = memberRole)
        groupMemberRepository.save(demotedOwner)
        
        // 새 그룹장을 OWNER 역할로 승급
        val promotedMember = newOwnerMember.copy(role = ownerRole)
        val savedMember = groupMemberRepository.save(promotedMember)
        
        return toGroupMemberResponse(savedMember)
    }
    
    @Transactional
    fun handleOwnerAbsence(groupId: Long): GroupMemberResponse? {
        val group = groupRepository.findById(groupId)
            .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }
        
        // 승계 후보자 조회 (학년 높은 순, 가입일 오래된 순)
        val candidates = groupMemberRepository.findSuccessionCandidates(groupId)
        
        if (candidates.isEmpty()) {
            // 승계할 멤버가 없으면 null 반환 (그룹 삭제 검토 필요)
            return null
        }
        
        val successor = candidates.first()
        val ownerRole = groupRoleRepository.findByGroupIdAndName(groupId, "OWNER")
            .orElseThrow { BusinessException(ErrorCode.GROUP_ROLE_NOT_FOUND) }
        
        // Group 엔티티의 owner 변경
        val updatedGroup = group.copy(owner = successor.user, updatedAt = LocalDateTime.now())
        groupRepository.save(updatedGroup)
        
        // 승계자를 OWNER 역할로 변경
        val updatedMember = successor.copy(role = ownerRole)
        val savedMember = groupMemberRepository.save(updatedMember)
        
        return toGroupMemberResponse(savedMember)
    }

    private fun toSubGroupRequestResponse(request: SubGroupRequest): SubGroupRequestResponse {
        return SubGroupRequestResponse(
            id = request.id,
            requester = toUserSummaryResponse(request.requester),
            parentGroup = toGroupSummaryResponse(request.parentGroup,
                groupMemberRepository.countByGroupId(request.parentGroup.id).toInt()),
            requestedGroupName = request.requestedGroupName,
            requestedGroupDescription = request.requestedGroupDescription,
            requestedUniversity = request.requestedUniversity,
            requestedCollege = request.requestedCollege,
            requestedDepartment = request.requestedDepartment,
            requestedGroupType = request.requestedGroupType,
            requestedMaxMembers = request.requestedMaxMembers,
            status = request.status.name,
            responseMessage = request.responseMessage,
            reviewedBy = request.reviewedBy?.let { toUserSummaryResponse(it) },
            reviewedAt = request.reviewedAt,
            createdAt = request.createdAt,
            updatedAt = request.updatedAt
        )
    }
    
    private fun toGroupJoinRequestResponse(request: GroupJoinRequest): GroupJoinRequestResponse {
        return GroupJoinRequestResponse(
            id = request.id,
            group = toGroupSummaryResponse(request.group,
                groupMemberRepository.countByGroupId(request.group.id).toInt()),
            user = toUserSummaryResponse(request.user),
            requestMessage = request.requestMessage,
            status = request.status.name,
            responseMessage = request.responseMessage,
            reviewedBy = request.reviewedBy?.let { toUserSummaryResponse(it) },
            reviewedAt = request.reviewedAt,
            createdAt = request.createdAt,
            updatedAt = request.updatedAt
        )
    }

    private fun toUserSummaryResponse(user: User): UserSummaryResponse {
        return UserSummaryResponse(
            id = user.id,
            name = user.name,
            email = user.email,
            profileImageUrl = user.profileImageUrl
        )
    }

    // === 멤버 개인 권한 오버라이드 ===

    fun getMemberPermissionOverride(groupId: Long, userId: Long): MemberPermissionOverrideResponse {
        val group = groupRepository.findById(groupId).orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }
        if (group.deletedAt != null) throw BusinessException(ErrorCode.GROUP_NOT_FOUND)

        val member = groupMemberRepository.findByGroupIdAndUserId(groupId, userId)
            .orElseThrow { BusinessException(ErrorCode.GROUP_MEMBER_NOT_FOUND) }

        val role = member.role
        val base = if (role.isSystemRole) systemRolePermissions(role.name) else role.permissions

        val override = overrideRepository.findByGroupIdAndUserId(groupId, userId).orElse(null)
        val allowed = override?.allowedPermissions ?: emptySet()
        val denied = override?.deniedPermissions ?: emptySet()
        val effective = base.plus(allowed).minus(denied)

        return MemberPermissionOverrideResponse(
            allowed = allowed.map { it.name }.toSet(),
            denied = denied.map { it.name }.toSet(),
            effective = effective.map { it.name }.toSet()
        )
    }

    @Transactional
    fun setMemberPermissionOverride(
        groupId: Long,
        userId: Long,
        request: MemberPermissionOverrideRequest,
        requesterId: Long,
    ): MemberPermissionOverrideResponse {
        val group = groupRepository.findById(groupId).orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }
        if (group.deletedAt != null) throw BusinessException(ErrorCode.GROUP_NOT_FOUND)
        if (group.owner.id != requesterId) throw BusinessException(ErrorCode.FORBIDDEN)

        groupMemberRepository.findByGroupIdAndUserId(groupId, userId)
            .orElseThrow { BusinessException(ErrorCode.GROUP_MEMBER_NOT_FOUND) }

        val allowed = request.allowed.mapNotNull { runCatching { GroupPermission.valueOf(it) }.getOrNull() }.toSet()
        val denied = request.denied.mapNotNull { runCatching { GroupPermission.valueOf(it) }.getOrNull() }.toSet()

        val existing = overrideRepository.findByGroupIdAndUserId(groupId, userId).orElse(null)
        val overrideEntity = if (existing != null) {
            existing.copy(allowedPermissions = allowed, deniedPermissions = denied)
        } else {
            val user = userRepository.findById(userId).orElseThrow { BusinessException(ErrorCode.USER_NOT_FOUND) }
            org.castlekong.backend.entity.GroupMemberPermissionOverride(
                group = group,
                user = user,
                allowedPermissions = allowed,
                deniedPermissions = denied,
            )
        }
        overrideRepository.save(overrideEntity)
        permissionService.invalidate(groupId, userId)
        return getMemberPermissionOverride(groupId, userId)
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
            pageable
        ).map { g ->
            val memberCount = getGroupMemberCountWithHierarchy(g)
            toGroupSummaryResponse(g, memberCount.toInt())
        }
    }

    private fun systemRolePermissions(roleName: String): Set<GroupPermission> = when (roleName.uppercase()) {
        "OWNER" -> GroupPermission.entries.toSet()
        "ADVISOR" -> GroupPermission.entries
            .toSet()
            .minus(
                setOf(
                    GroupPermission.GROUP_MANAGE,
                    GroupPermission.ROLE_MANAGE,
                    GroupPermission.MEMBER_APPROVE,
                    GroupPermission.MEMBER_KICK,
                    GroupPermission.RECRUITMENT_CREATE,
                    GroupPermission.RECRUITMENT_UPDATE,
                    GroupPermission.RECRUITMENT_DELETE,
                ),
            )
        "MEMBER" -> setOf(
            GroupPermission.CHANNEL_READ,
            GroupPermission.POST_CREATE,
            GroupPermission.POST_READ,
            GroupPermission.COMMENT_CREATE,
            GroupPermission.COMMENT_READ
        )
        else -> emptySet()
    }

    // === 나의 유효 권한 조회 ===
    fun getMyEffectivePermissions(groupId: Long, userId: Long): Set<String> {
        val effective = permissionService.getEffective(groupId, userId, ::systemRolePermissions)
        return effective.map { it.name }.toSet()
    }
}
