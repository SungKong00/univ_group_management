package org.castlekong.backend.service

import org.castlekong.backend.dto.*
import org.castlekong.backend.entity.GroupType
import org.castlekong.backend.entity.GroupVisibility
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
@Transactional(readOnly = true)
class GroupService(
    private val groupManagementService: GroupManagementService,
    private val groupMemberService: GroupMemberService,
    private val groupRequestService: GroupRequestService,
    private val workspaceManagementService: WorkspaceManagementService,
) {
    // === 그룹 관리 위임 ===
    @Transactional
    fun createGroup(
        request: CreateGroupRequest,
        ownerId: Long,
    ): GroupResponse {
        return groupManagementService.createGroup(request, ownerId)
    }

    fun getGroup(groupId: Long): GroupResponse {
        return groupManagementService.getGroup(groupId)
    }

    fun getGroups(pageable: Pageable): Page<GroupSummaryResponse> {
        return groupManagementService.getGroups(pageable)
    }

    fun getAllGroups(): List<GroupSummaryResponse> {
        return groupManagementService.getAllGroups()
    }

    @Transactional
    fun updateGroup(
        groupId: Long,
        request: UpdateGroupRequest,
        userId: Long,
    ): GroupResponse {
        return groupManagementService.updateGroup(groupId, request, userId)
    }

    @Transactional
    fun deleteGroup(
        groupId: Long,
        userId: Long,
    ) {
        groupManagementService.deleteGroup(groupId, userId)
    }

    fun getAllGroupsForHierarchy(): List<GroupHierarchyNodeDto> {
        return groupManagementService.getAllGroupsForHierarchy()
    }

    fun getSubGroups(parentGroupId: Long): List<GroupSummaryResponse> {
        return groupManagementService.getSubGroups(parentGroupId)
    }

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
        return groupManagementService.searchGroups(
            pageable, recruiting, visibility, groupType,
            university, college, department, q, tags,
        )
    }

    // === 멤버 관리 위임 ===
    @Transactional
    fun joinGroup(
        groupId: Long,
        userId: Long,
    ): GroupMemberResponse {
        return groupMemberService.joinGroup(groupId, userId)
    }

    @Transactional
    fun leaveGroup(
        groupId: Long,
        userId: Long,
    ) {
        groupMemberService.leaveGroup(groupId, userId)
    }

    fun getGroupMembers(
        groupId: Long,
        pageable: Pageable,
    ): Page<GroupMemberResponse> {
        return groupMemberService.getGroupMembers(groupId, pageable)
    }

    fun getMyMembership(
        groupId: Long,
        userId: Long,
    ): GroupMemberResponse {
        return groupMemberService.getMyMembership(groupId, userId)
    }

    @Transactional
    fun removeMember(
        groupId: Long,
        targetUserId: Long,
        requesterId: Long,
    ) {
        groupMemberService.removeMember(groupId, targetUserId, requesterId)
    }

    @Transactional
    fun updateMemberRole(
        groupId: Long,
        targetUserId: Long,
        roleId: Long,
        requesterId: Long,
    ): GroupMemberResponse {
        return groupMemberService.updateMemberRole(groupId, targetUserId, roleId, requesterId)
    }

    @Transactional
    fun assignProfessor(
        groupId: Long,
        professorUserId: Long,
        ownerUserId: Long,
    ): GroupMemberResponse {
        return groupMemberService.assignProfessor(groupId, professorUserId, ownerUserId)
    }

    @Transactional
    fun removeProfessor(
        groupId: Long,
        professorUserId: Long,
        ownerUserId: Long,
    ) {
        groupMemberService.removeProfessor(groupId, professorUserId, ownerUserId)
    }

    fun getProfessors(groupId: Long): List<GroupMemberResponse> {
        return groupMemberService.getProfessors(groupId)
    }

    @Transactional
    fun transferOwnership(
        groupId: Long,
        newOwnerId: Long,
        currentOwnerId: Long,
    ): GroupMemberResponse {
        return groupMemberService.transferOwnership(groupId, newOwnerId, currentOwnerId)
    }

    @Transactional
    fun handleOwnerAbsence(groupId: Long): GroupMemberResponse? {
        return groupMemberService.handleOwnerAbsence(groupId)
    }

    fun getMemberPermissionOverride(
        groupId: Long,
        userId: Long,
    ): MemberPermissionOverrideResponse {
        return groupMemberService.getMemberPermissionOverride(groupId, userId)
    }

    @Transactional
    fun setMemberPermissionOverride(
        groupId: Long,
        userId: Long,
        request: MemberPermissionOverrideRequest,
        requesterId: Long,
    ): MemberPermissionOverrideResponse {
        return groupMemberService.setMemberPermissionOverride(groupId, userId, request, requesterId)
    }

    fun getMyEffectivePermissions(
        groupId: Long,
        userId: Long,
    ): Set<String> {
        return groupMemberService.getMyEffectivePermissions(groupId, userId)
    }

    // === 요청 관리 위임 ===
    @Transactional
    fun createSubGroupRequest(
        parentGroupId: Long,
        request: CreateSubGroupRequest,
        requesterId: Long,
    ): SubGroupRequestResponse {
        return groupRequestService.createSubGroupRequest(parentGroupId, request, requesterId)
    }

    fun getSubGroupRequestsByParentGroup(parentGroupId: Long): List<SubGroupRequestResponse> {
        return groupRequestService.getSubGroupRequestsByParentGroup(parentGroupId)
    }

    @Transactional
    fun reviewSubGroupRequest(
        requestId: Long,
        reviewRequest: ReviewSubGroupRequestRequest,
        reviewerId: Long,
    ): SubGroupRequestResponse {
        return groupRequestService.reviewSubGroupRequest(requestId, reviewRequest, reviewerId)
    }

    @Transactional
    fun createGroupJoinRequest(
        groupId: Long,
        requestMessage: String?,
        userId: Long,
    ): GroupJoinRequestResponse {
        return groupRequestService.createGroupJoinRequest(groupId, requestMessage, userId)
    }

    fun getGroupJoinRequestsByGroup(groupId: Long): List<GroupJoinRequestResponse> {
        return groupRequestService.getGroupJoinRequestsByGroup(groupId)
    }

    @Transactional
    fun reviewGroupJoinRequest(
        requestId: Long,
        reviewRequest: ReviewGroupJoinRequestRequest,
        reviewerId: Long,
    ): GroupJoinRequestResponse {
        return groupRequestService.reviewGroupJoinRequest(requestId, reviewRequest, reviewerId)
    }

    // === 워크스페이스 관리 위임 ===
    fun getWorkspace(
        groupId: Long,
        userId: Long,
    ): WorkspaceDto {
        return workspaceManagementService.getWorkspace(groupId, userId)
    }
}
