package org.castlekong.backend.service

import org.castlekong.backend.dto.BlockedTimeResponse
import org.castlekong.backend.dto.CreateBlockedTimeRequest
import org.castlekong.backend.entity.PlaceBlockedTime
import org.castlekong.backend.entity.User
import org.castlekong.backend.exception.BusinessException
import org.castlekong.backend.exception.ErrorCode
import org.castlekong.backend.repository.PlaceBlockedTimeRepository
import org.castlekong.backend.repository.PlaceRepository
import org.castlekong.backend.security.PermissionService
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDateTime

@Service
@Transactional
class PlaceBlockedTimeService(
    private val placeRepository: PlaceRepository,
    private val placeBlockedTimeRepository: PlaceBlockedTimeRepository,
    private val permissionService: PermissionService,
) {
    /**
     * 차단 시간 추가
     */
    fun createBlockedTime(
        user: User,
        placeId: Long,
        request: CreateBlockedTimeRequest,
    ): BlockedTimeResponse {
        // 장소 조회
        val place =
            placeRepository.findActiveById(placeId)
                .orElseThrow { BusinessException(ErrorCode.PLACE_NOT_FOUND) }

        // 관리 주체 확인
        checkCalendarManagePermission(user.id!!, place.managingGroup.id)

        // 시간 범위 검증
        if (!request.endDatetime.isAfter(request.startDatetime)) {
            throw BusinessException(ErrorCode.INVALID_TIME_RANGE)
        }

        // 차단 시간 생성
        val blockedTime =
            placeBlockedTimeRepository.save(
                PlaceBlockedTime(
                    place = place,
                    startDatetime = request.startDatetime,
                    endDatetime = request.endDatetime,
                    blockType = request.blockType,
                    reason = request.reason,
                    createdBy = user,
                ),
            )

        return blockedTime.toResponse()
    }

    /**
     * 차단 시간 목록 조회
     */
    @Transactional(readOnly = true)
    fun getBlockedTimes(
        placeId: Long,
        startDatetime: LocalDateTime,
        endDatetime: LocalDateTime,
    ): List<BlockedTimeResponse> {
        return placeBlockedTimeRepository.findByPlaceIdAndTimeRange(
            placeId,
            startDatetime,
            endDatetime,
        ).map { it.toResponse() }
    }

    /**
     * 차단 시간 삭제
     */
    fun deleteBlockedTime(
        user: User,
        blockedTimeId: Long,
    ) {
        val blockedTime =
            placeBlockedTimeRepository.findById(blockedTimeId)
                .orElseThrow { BusinessException(ErrorCode.BLOCKED_TIME_NOT_FOUND) }

        checkCalendarManagePermission(user.id!!, blockedTime.place.managingGroup.id)

        placeBlockedTimeRepository.delete(blockedTime)
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

    private fun PlaceBlockedTime.toResponse() =
        BlockedTimeResponse(
            id = id,
            placeId = place.id,
            placeName = place.getDisplayName(),
            startDatetime = startDatetime,
            endDatetime = endDatetime,
            blockType = blockType,
            reason = reason,
            createdBy = createdBy.id!!,
            createdByName = createdBy.name,
            createdAt = createdAt,
        )
}
