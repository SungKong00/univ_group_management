package org.castlekong.backend.controller

import org.castlekong.backend.dto.ApiResponse
import org.castlekong.backend.dto.CreateGroupRequest
import org.castlekong.backend.dto.GroupJoinRequestResponse
import org.castlekong.backend.dto.GroupSummaryResponse
import org.castlekong.backend.dto.ReviewGroupJoinRequestRequest
import org.castlekong.backend.dto.ReviewSubGroupRequestRequest
import org.castlekong.backend.dto.SubGroupRequestResponse
import org.castlekong.backend.dto.UserSummaryResponse
import org.castlekong.backend.entity.GroupJoinRequestStatus
import org.castlekong.backend.entity.GroupMember
import org.castlekong.backend.entity.SubGroupRequestStatus
import org.castlekong.backend.repository.GroupJoinRequestRepository
import org.castlekong.backend.repository.GroupMemberRepository
import org.castlekong.backend.repository.GroupRepository
import org.castlekong.backend.repository.GroupRoleRepository
import org.castlekong.backend.repository.SubGroupRequestRepository
import org.castlekong.backend.service.GroupManagementService
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PatchMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController
import java.time.LocalDateTime

@RestController
@RequestMapping("/api/admin")
class AdminController(
    private val groupJoinRequestRepository: GroupJoinRequestRepository,
    private val subGroupRequestRepository: SubGroupRequestRepository,
    private val groupMemberRepository: GroupMemberRepository,
    private val groupRoleRepository: GroupRoleRepository,
    private val groupRepository: GroupRepository,
    private val groupManagementService: GroupManagementService,
    private val groupMapper: org.castlekong.backend.service.GroupMapper,
) {
    @GetMapping("/join-requests")
    @PreAuthorize("hasRole('ADMIN')")
    fun listJoinRequests(
        @RequestParam(required = false, defaultValue = "PENDING") status: String,
    ): ApiResponse<List<GroupJoinRequestResponse>> {
        val st = runCatching { GroupJoinRequestStatus.valueOf(status) }.getOrDefault(GroupJoinRequestStatus.PENDING)
        val list =
            groupJoinRequestRepository.findAll().filter { it.status == st }.map { r ->
                val memberCount = groupMemberRepository.countByGroupId(r.group.id).toInt()
                groupMapper.toGroupJoinRequestResponse(r, memberCount)
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
        val status =
            when (req.action) {
                "APPROVE" -> GroupJoinRequestStatus.APPROVED
                "REJECT" -> GroupJoinRequestStatus.REJECTED
                else -> throw IllegalArgumentException("잘못된 action")
            }
        val saved =
            groupJoinRequestRepository.save(
                r.copy(
                    status = status,
                    responseMessage = req.responseMessage,
                    reviewedAt = LocalDateTime.now(),
                ),
            )
        if (status == GroupJoinRequestStatus.APPROVED) {
            val memberRole =
                groupRoleRepository.findByGroupIdAndName(r.group.id, "MEMBER")
                    .orElseThrow { IllegalArgumentException("역할 없음") }
            groupMemberRepository.save(
                GroupMember(
                    group = r.group,
                    user = r.user,
                    role = memberRole,
                    joinedAt = LocalDateTime.now(),
                ),
            )
        }
        val memberCount = groupMemberRepository.countByGroupId(saved.group.id).toInt()
        return ApiResponse.success(groupMapper.toGroupJoinRequestResponse(saved, memberCount))
    }

    @PatchMapping("/group-requests/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    fun reviewGroupRequest(
        @PathVariable id: Long,
        @RequestBody req: ReviewSubGroupRequestRequest,
    ): ApiResponse<SubGroupRequestResponse> {
        val r = subGroupRequestRepository.findById(id).orElseThrow { IllegalArgumentException("요청 없음") }
        val status =
            when (req.action) {
                "APPROVE" -> SubGroupRequestStatus.APPROVED
                "REJECT" -> SubGroupRequestStatus.REJECTED
                else -> throw IllegalArgumentException("잘못된 action")
            }
        val saved =
            subGroupRequestRepository.save(
                r.copy(
                    status = status,
                    responseMessage = req.responseMessage,
                    reviewedAt = LocalDateTime.now(),
                ),
            )
        if (status == SubGroupRequestStatus.APPROVED) {
            val parent = groupRepository.findById(r.parentGroup.id).orElseThrow()
            groupManagementService.createGroup(
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
        return ApiResponse.success(groupMapper.toSubGroupRequestResponse(saved, memberCount))
    }

    @GetMapping("/group-requests")
    @PreAuthorize("hasRole('ADMIN')")
    fun listSubGroupRequests(
        @RequestParam(required = false, defaultValue = "PENDING") status: String,
    ): ApiResponse<List<SubGroupRequestResponse>> {
        val st = runCatching { SubGroupRequestStatus.valueOf(status) }.getOrDefault(SubGroupRequestStatus.PENDING)
        val list =
            subGroupRequestRepository.findAll().filter { it.status == st }.map { r ->
                val memberCount = groupMemberRepository.countByGroupId(r.parentGroup.id).toInt()
                groupMapper.toSubGroupRequestResponse(r, memberCount)
            }
        return ApiResponse.success(list)
    }
}
