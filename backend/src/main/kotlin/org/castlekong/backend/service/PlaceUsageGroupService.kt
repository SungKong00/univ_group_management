package org.castlekong.backend.service

import org.castlekong.backend.dto.RequestUsageRequest
import org.castlekong.backend.dto.UpdateUsageStatusRequest
import org.castlekong.backend.dto.UsageGroupResponse
import org.castlekong.backend.entity.PlaceUsageGroup
import org.castlekong.backend.entity.UsageStatus
import org.castlekong.backend.entity.User
import org.castlekong.backend.exception.BusinessException
import org.castlekong.backend.exception.ErrorCode
import org.castlekong.backend.repository.GroupRepository
import org.castlekong.backend.repository.PlaceRepository
import org.castlekong.backend.repository.PlaceUsageGroupRepository
import org.castlekong.backend.security.PermissionService
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
@Transactional
class PlaceUsageGroupService(
    private val placeRepository: PlaceRepository,
    private val placeUsageGroupRepository: PlaceUsageGroupRepository,
    private val groupRepository: GroupRepository,
    private val permissionService: PermissionService,
) {
    /**
     * 사용 신청
     */
    fun requestUsage(
        user: User,
        placeId: Long,
        request: RequestUsageRequest,
    ): UsageGroupResponse {
        // 권한 확인
        checkCalendarManagePermission(user.id!!, request.groupId)

        // 장소 조회
        val place =
            placeRepository.findActiveById(placeId)
                .orElseThrow { BusinessException(ErrorCode.PLACE_NOT_FOUND) }

        // 중복 신청 확인
        placeUsageGroupRepository.findByPlaceIdAndGroupId(placeId, request.groupId)
            .ifPresent { throw BusinessException(ErrorCode.PLACE_USAGE_ALREADY_REQUESTED) }

        // 그룹 조회
        val group =
            groupRepository.findById(request.groupId)
                .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }

        // 신청 생성
        val usageGroup =
            placeUsageGroupRepository.save(
                PlaceUsageGroup(
                    place = place,
                    group = group,
                    status = UsageStatus.PENDING,
                ),
            )

        return usageGroup.toResponse()
    }

    /**
     * 사용 승인/거절
     */
    fun updateUsageStatus(
        user: User,
        placeId: Long,
        groupId: Long,
        request: UpdateUsageStatusRequest,
    ): UsageGroupResponse {
        // 장소 조회
        val place =
            placeRepository.findActiveById(placeId)
                .orElseThrow { BusinessException(ErrorCode.PLACE_NOT_FOUND) }

        // 관리 주체 확인
        checkCalendarManagePermission(user.id!!, place.managingGroup.id)

        // 사용 그룹 조회
        val usageGroup =
            placeUsageGroupRepository.findByPlaceIdAndGroupId(placeId, groupId)
                .orElseThrow { BusinessException(ErrorCode.PLACE_USAGE_NOT_FOUND) }

        // 상태 변경
        when (request.status) {
            UsageStatus.APPROVED -> usageGroup.approve()
            UsageStatus.REJECTED -> usageGroup.reject()
            else -> throw BusinessException(ErrorCode.INVALID_REQUEST)
        }

        return placeUsageGroupRepository.save(usageGroup).toResponse()
    }

    /**
     * 사용 그룹 목록 조회
     */
    @Transactional(readOnly = true)
    fun getUsageGroups(
        user: User,
        placeId: Long,
    ): List<UsageGroupResponse> {
        val place =
            placeRepository.findActiveById(placeId)
                .orElseThrow { BusinessException(ErrorCode.PLACE_NOT_FOUND) }

        checkCalendarManagePermission(user.id!!, place.managingGroup.id)

        return placeUsageGroupRepository.findByPlaceIdWithGroup(placeId)
            .map { it.toResponse() }
    }

    private fun checkCalendarManagePermission(
        userId: Long,
        groupId: Long,
    ) {
        val effectivePermissions =
            permissionService.getEffective(groupId, userId) { roleName ->
                getSystemRolePermissions(roleName)
            }

        if (!effectivePermissions.contains(org.castlekong.backend.entity.GroupPermission.CALENDAR_MANAGE)) {
            throw BusinessException(ErrorCode.FORBIDDEN)
        }
    }

    private fun getSystemRolePermissions(roleName: String): Set<org.castlekong.backend.entity.GroupPermission> =
        when (roleName) {
            "그룹장" ->
                setOf(
                    org.castlekong.backend.entity.GroupPermission.GROUP_MANAGE,
                    org.castlekong.backend.entity.GroupPermission.MEMBER_MANAGE,
                    org.castlekong.backend.entity.GroupPermission.CHANNEL_MANAGE,
                    org.castlekong.backend.entity.GroupPermission.RECRUITMENT_MANAGE,
                    org.castlekong.backend.entity.GroupPermission.CALENDAR_MANAGE,
                )
            "교수" ->
                setOf(
                    org.castlekong.backend.entity.GroupPermission.CHANNEL_MANAGE,
                    org.castlekong.backend.entity.GroupPermission.CALENDAR_MANAGE,
                )
            else -> emptySet()
        }

    private fun PlaceUsageGroup.toResponse() =
        UsageGroupResponse(
            id = id,
            placeId = place.id,
            placeName = place.getDisplayName(),
            groupId = group.id,
            groupName = group.name,
            status = status,
            createdAt = createdAt,
            updatedAt = updatedAt,
        )
}
