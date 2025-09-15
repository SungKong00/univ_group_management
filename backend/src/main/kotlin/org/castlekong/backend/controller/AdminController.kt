package org.castlekong.backend.controller

import org.castlekong.backend.dto.*
import org.castlekong.backend.entity.GroupJoinRequestStatus
import org.castlekong.backend.entity.SubGroupRequestStatus
import org.castlekong.backend.repository.GroupJoinRequestRepository
import org.castlekong.backend.repository.SubGroupRequestRepository
import org.castlekong.backend.repository.GroupMemberRepository
import org.castlekong.backend.repository.GroupRoleRepository
import org.castlekong.backend.repository.GroupRepository
import org.castlekong.backend.service.GroupService
import java.time.LocalDateTime
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/admin")
class AdminController(
    private val groupJoinRequestRepository: GroupJoinRequestRepository,
    private val subGroupRequestRepository: SubGroupRequestRepository,
    private val groupMemberRepository: GroupMemberRepository,
    private val groupRoleRepository: GroupRoleRepository,
    private val groupRepository: GroupRepository,
    private val groupService: GroupService,
) {
    @GetMapping("/join-requests")
    @PreAuthorize("hasRole('ADMIN')")
    fun listJoinRequests(@RequestParam(required = false, defaultValue = "PENDING") status: String): ApiResponse<List<GroupJoinRequestResponse>> {
        val st = runCatching { GroupJoinRequestStatus.valueOf(status) }.getOrDefault(GroupJoinRequestStatus.PENDING)
        val list = groupJoinRequestRepository.findAll().filter { it.status == st }.map { r ->
            val memberCount = groupMemberRepository.countByGroupId(r.group.id).toInt()
            GroupJoinRequestResponse(
                id = r.id,
                group = GroupSummaryResponse(
                    id = r.group.id,
                    name = r.group.name,
                    description = r.group.description,
                    profileImageUrl = r.group.profileImageUrl,
                    university = r.group.university,
                    college = r.group.college,
                    department = r.group.department,
                    visibility = r.group.visibility,
                    groupType = r.group.groupType,
                    isRecruiting = r.group.isRecruiting,
                    memberCount = memberCount,
                    tags = r.group.tags,
                ),
                user = UserSummaryResponse(id = r.user.id, name = r.user.name, email = r.user.email, profileImageUrl = r.user.profileImageUrl),
                requestMessage = r.requestMessage,
                status = r.status.name,
                responseMessage = r.responseMessage,
                reviewedBy = r.reviewedBy?.let { UserSummaryResponse(id = it.id, name = it.name, email = it.email, profileImageUrl = it.profileImageUrl) },
                reviewedAt = r.reviewedAt,
                createdAt = r.createdAt,
                updatedAt = r.updatedAt,
            )
        }
        return ApiResponse.success(list)
    }

    @PatchMapping("/join-requests/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    fun reviewJoinRequest(
        @PathVariable id: Long,
        @RequestBody req: ReviewGroupJoinRequestRequest,
    ): ApiResponse<GroupJoinRequestResponse> {
        val r = groupJoinRequestRepository.findById(id).orElseThrow { IllegalArgumentException("요청 없음") }
        val status = when (req.action) {
            "APPROVE" -> GroupJoinRequestStatus.APPROVED
            "REJECT" -> GroupJoinRequestStatus.REJECTED
            else -> throw IllegalArgumentException("잘못된 action")
        }
        val saved = groupJoinRequestRepository.save(
            r.copy(
                status = status,
                responseMessage = req.responseMessage,
                reviewedAt = LocalDateTime.now(),
            )
        )
        if (status == GroupJoinRequestStatus.APPROVED) {
            val memberRole = groupRoleRepository.findByGroupIdAndName(r.group.id, "MEMBER")
                .orElseThrow { IllegalArgumentException("역할 없음") }
            groupMemberRepository.save(
                org.castlekong.backend.entity.GroupMember(
                    group = r.group,
                    user = r.user,
                    role = memberRole,
                    joinedAt = LocalDateTime.now(),
                )
            )
        }
        val memberCount = groupMemberRepository.countByGroupId(saved.group.id).toInt()
        val resp = GroupJoinRequestResponse(
            id = saved.id,
            group = GroupSummaryResponse(
                id = saved.group.id,
                name = saved.group.name,
                description = saved.group.description,
                profileImageUrl = saved.group.profileImageUrl,
                university = saved.group.university,
                college = saved.group.college,
                department = saved.group.department,
                visibility = saved.group.visibility,
                groupType = saved.group.groupType,
                isRecruiting = saved.group.isRecruiting,
                memberCount = memberCount,
                tags = saved.group.tags,
            ),
            user = UserSummaryResponse(id = saved.user.id, name = saved.user.name, email = saved.user.email, profileImageUrl = saved.user.profileImageUrl),
            requestMessage = saved.requestMessage,
            status = saved.status.name,
            responseMessage = saved.responseMessage,
            reviewedBy = null,
            reviewedAt = saved.reviewedAt,
            createdAt = saved.createdAt,
            updatedAt = saved.updatedAt,
        )
        return ApiResponse.success(resp)
    }

    @PatchMapping("/group-requests/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    fun reviewGroupRequest(
        @PathVariable id: Long,
        @RequestBody req: ReviewSubGroupRequestRequest,
    ): ApiResponse<SubGroupRequestResponse> {
        val r = subGroupRequestRepository.findById(id).orElseThrow { IllegalArgumentException("요청 없음") }
        val status = when (req.action) {
            "APPROVE" -> SubGroupRequestStatus.APPROVED
            "REJECT" -> SubGroupRequestStatus.REJECTED
            else -> throw IllegalArgumentException("잘못된 action")
        }
        val saved = subGroupRequestRepository.save(
            r.copy(
                status = status,
                responseMessage = req.responseMessage,
                reviewedAt = LocalDateTime.now(),
            )
        )
        if (status == SubGroupRequestStatus.APPROVED) {
            val parent = groupRepository.findById(r.parentGroup.id).orElseThrow()
            groupService.createGroup(
                CreateGroupRequest(
                    name = r.requestedGroupName,
                    description = r.requestedGroupDescription,
                    parentId = parent.id,
                    university = r.requestedUniversity,
                    college = r.requestedCollege,
                    department = r.requestedDepartment,
                    maxMembers = r.requestedMaxMembers,
                ),
                r.requester.id,
            )
        }
        val memberCount = groupMemberRepository.countByGroupId(saved.parentGroup.id).toInt()
        val resp = SubGroupRequestResponse(
            id = saved.id,
            requester = UserSummaryResponse(id = saved.requester.id, name = saved.requester.name, email = saved.requester.email, profileImageUrl = saved.requester.profileImageUrl),
            parentGroup = GroupSummaryResponse(
                id = saved.parentGroup.id,
                name = saved.parentGroup.name,
                description = saved.parentGroup.description,
                profileImageUrl = saved.parentGroup.profileImageUrl,
                university = saved.parentGroup.university,
                college = saved.parentGroup.college,
                department = saved.parentGroup.department,
                visibility = saved.parentGroup.visibility,
                groupType = saved.parentGroup.groupType,
                isRecruiting = saved.parentGroup.isRecruiting,
                memberCount = memberCount,
                tags = saved.parentGroup.tags,
            ),
            requestedGroupName = saved.requestedGroupName,
            requestedGroupDescription = saved.requestedGroupDescription,
            requestedUniversity = saved.requestedUniversity,
            requestedCollege = saved.requestedCollege,
            requestedDepartment = saved.requestedDepartment,
            requestedGroupType = saved.requestedGroupType,
            requestedMaxMembers = saved.requestedMaxMembers,
            status = saved.status.name,
            responseMessage = saved.responseMessage,
            reviewedBy = null,
            reviewedAt = saved.reviewedAt,
            createdAt = saved.createdAt,
            updatedAt = saved.updatedAt,
        )
        return ApiResponse.success(resp)
    }
    @GetMapping("/group-requests")
    @PreAuthorize("hasRole('ADMIN')")
    fun listSubGroupRequests(@RequestParam(required = false, defaultValue = "PENDING") status: String): ApiResponse<List<SubGroupRequestResponse>> {
        val st = runCatching { SubGroupRequestStatus.valueOf(status) }.getOrDefault(SubGroupRequestStatus.PENDING)
        val list = subGroupRequestRepository.findAll().filter { it.status == st }.map { r ->
            val memberCount = groupMemberRepository.countByGroupId(r.parentGroup.id).toInt()
            SubGroupRequestResponse(
                id = r.id,
                requester = UserSummaryResponse(id = r.requester.id, name = r.requester.name, email = r.requester.email, profileImageUrl = r.requester.profileImageUrl),
                parentGroup = GroupSummaryResponse(
                    id = r.parentGroup.id,
                    name = r.parentGroup.name,
                    description = r.parentGroup.description,
                    profileImageUrl = r.parentGroup.profileImageUrl,
                    university = r.parentGroup.university,
                    college = r.parentGroup.college,
                    department = r.parentGroup.department,
                    visibility = r.parentGroup.visibility,
                    groupType = r.parentGroup.groupType,
                    isRecruiting = r.parentGroup.isRecruiting,
                    memberCount = memberCount,
                    tags = r.parentGroup.tags,
                ),
                requestedGroupName = r.requestedGroupName,
                requestedGroupDescription = r.requestedGroupDescription,
                requestedUniversity = r.requestedUniversity,
                requestedCollege = r.requestedCollege,
                requestedDepartment = r.requestedDepartment,
                requestedGroupType = r.requestedGroupType,
                requestedMaxMembers = r.requestedMaxMembers,
                status = r.status.name,
                responseMessage = r.responseMessage,
                reviewedBy = r.reviewedBy?.let { UserSummaryResponse(id = it.id, name = it.name, email = it.email, profileImageUrl = it.profileImageUrl) },
                reviewedAt = r.reviewedAt,
                createdAt = r.createdAt,
                updatedAt = r.updatedAt,
            )
        }
        return ApiResponse.success(list)
    }
}
