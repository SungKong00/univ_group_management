package org.castlekong.backend.service

import org.castlekong.backend.dto.AvailabilityRequest
import org.castlekong.backend.dto.AvailabilityResponse
import org.castlekong.backend.dto.CreatePlaceRequest
import org.castlekong.backend.dto.PlaceDetailResponse
import org.castlekong.backend.dto.PlaceResponse
import org.castlekong.backend.dto.UpdatePlaceRequest
import org.castlekong.backend.entity.Place
import org.castlekong.backend.entity.PlaceAvailability
import org.castlekong.backend.entity.User
import org.castlekong.backend.exception.BusinessException
import org.castlekong.backend.exception.ErrorCode
import org.castlekong.backend.repository.GroupMemberRepository
import org.castlekong.backend.repository.GroupRepository
import org.castlekong.backend.repository.PlaceAvailabilityRepository
import org.castlekong.backend.repository.PlaceRepository
import org.castlekong.backend.repository.PlaceUsageGroupRepository
import org.castlekong.backend.security.PermissionService
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
@Transactional
class PlaceService(
    private val placeRepository: PlaceRepository,
    private val placeAvailabilityRepository: PlaceAvailabilityRepository,
    private val placeUsageGroupRepository: PlaceUsageGroupRepository,
    private val groupRepository: GroupRepository,
    private val groupMemberRepository: GroupMemberRepository,
    private val permissionService: PermissionService,
) {
    /**
     * 장소 등록
     */
    fun createPlace(
        user: User,
        request: CreatePlaceRequest,
    ): PlaceResponse {
        // 권한 확인
        checkCalendarManagePermission(user.id!!, request.managingGroupId)

        // 중복 확인
        placeRepository.findByBuildingAndRoomNumber(request.building.trim(), request.roomNumber.trim())
            .ifPresent { throw BusinessException(ErrorCode.PLACE_ALREADY_EXISTS) }

        // 관리 그룹 조회
        val managingGroup =
            groupRepository.findById(request.managingGroupId)
                .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }

        // 장소 생성
        val place =
            placeRepository.save(
                Place(
                    managingGroup = managingGroup,
                    building = request.building.trim(),
                    roomNumber = request.roomNumber.trim(),
                    alias = request.alias?.trim(),
                    capacity = request.capacity,
                ),
            )

        // 운영 시간 설정
        if (request.availabilities.isNullOrEmpty()) {
            createDefaultAvailabilities(place)
        } else {
            addAvailabilities(place.id, request.availabilities)
        }

        return place.toResponse()
    }

    /**
     * 장소 조회 (공개)
     */
    @Transactional(readOnly = true)
    fun getAllActivePlaces(): List<PlaceResponse> = placeRepository.findAllActive().map { it.toResponse() }

    /**
     * 특정 그룹이 예약 가능한 장소 목록 조회
     */
    @Transactional(readOnly = true)
    fun findReservablePlacesForGroup(
        user: User,
        groupId: Long,
    ): List<PlaceResponse> {
        // 1. 사용자가 해당 그룹의 멤버인지 확인
        groupMemberRepository.findByGroupIdAndUserId(groupId, user.id!!)
            .orElseThrow { BusinessException(ErrorCode.NOT_GROUP_MEMBER) }

        // 2. Repository를 통해 예약 가능한 장소 목록 조회
        return placeRepository.findReservablePlacesByGroupId(groupId).map { it.toResponse() }
    }

    /**
     * 장소 상세 조회
     */
    @Transactional(readOnly = true)
    fun getPlaceDetail(placeId: Long): PlaceDetailResponse {
        val place =
            placeRepository.findActiveById(placeId)
                .orElseThrow { BusinessException(ErrorCode.PLACE_NOT_FOUND) }

        val availabilities = placeAvailabilityRepository.findByPlaceId(placeId)
        val approvedCount = placeUsageGroupRepository.findApprovedByPlaceId(placeId).size

        return PlaceDetailResponse(
            place = place.toResponse(),
            availabilities = availabilities.map { it.toResponse() },
            approvedGroupCount = approvedCount,
        )
    }

    /**
     * 장소 수정
     */
    fun updatePlace(
        user: User,
        placeId: Long,
        request: UpdatePlaceRequest,
    ): PlaceResponse {
        val place =
            placeRepository.findActiveById(placeId)
                .orElseThrow { BusinessException(ErrorCode.PLACE_NOT_FOUND) }

        checkCalendarManagePermission(user.id!!, place.managingGroup.id)

        place.updateInfo(request.alias?.trim(), request.capacity)
        return placeRepository.save(place).toResponse()
    }

    /**
     * 장소 삭제 (Soft delete)
     */
    fun deletePlace(
        user: User,
        placeId: Long,
    ) {
        val place =
            placeRepository.findActiveById(placeId)
                .orElseThrow { BusinessException(ErrorCode.PLACE_NOT_FOUND) }

        checkCalendarManagePermission(user.id!!, place.managingGroup.id)

        place.markAsDeleted()
        placeRepository.save(place)
    }

    /**
     * 운영 시간 설정
     */
    fun setAvailabilities(
        user: User,
        placeId: Long,
        requests: List<AvailabilityRequest>,
    ) {
        val place =
            placeRepository.findActiveById(placeId)
                .orElseThrow { BusinessException(ErrorCode.PLACE_NOT_FOUND) }

        checkCalendarManagePermission(user.id!!, place.managingGroup.id)

        // 기존 운영 시간 삭제
        placeAvailabilityRepository.deleteByPlaceId(placeId)

        // 새 운영 시간 추가
        addAvailabilities(placeId, requests)
    }

    private fun addAvailabilities(
        placeId: Long,
        requests: List<AvailabilityRequest>,
    ) {
        val place =
            placeRepository.findById(placeId)
                .orElseThrow { BusinessException(ErrorCode.PLACE_NOT_FOUND) }

        val availabilities =
            requests.map { req ->
                if (!req.endTime.isAfter(req.startTime)) {
                    throw BusinessException(ErrorCode.INVALID_TIME_RANGE)
                }

                PlaceAvailability(
                    place = place,
                    dayOfWeek = req.dayOfWeek,
                    startTime = req.startTime,
                    endTime = req.endTime,
                    displayOrder = req.displayOrder,
                )
            }

        placeAvailabilityRepository.saveAll(availabilities)
    }

    private fun createDefaultAvailabilities(place: Place) {
        val defaultDays = listOf(
            java.time.DayOfWeek.MONDAY,
            java.time.DayOfWeek.TUESDAY,
            java.time.DayOfWeek.WEDNESDAY,
            java.time.DayOfWeek.THURSDAY,
            java.time.DayOfWeek.FRIDAY
        )
        val startTime = java.time.LocalTime.of(9, 0)
        val endTime = java.time.LocalTime.of(18, 0)

        val defaultAvailabilities = defaultDays.map { day ->
            PlaceAvailability(
                place = place,
                dayOfWeek = day,
                startTime = startTime,
                endTime = endTime,
                displayOrder = 0
            )
        }
        placeAvailabilityRepository.saveAll(defaultAvailabilities)
    }

    private fun checkCalendarManagePermission(
        userId: Long,
        groupId: Long,
    ) {
        groupMemberRepository.findByGroupIdAndUserId(groupId, userId)
            .orElseThrow { BusinessException(ErrorCode.NOT_GROUP_MEMBER) }

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

    private fun Place.toResponse() =
        PlaceResponse(
            id = id,
            managingGroupId = managingGroup.id,
            managingGroupName = managingGroup.name,
            building = building,
            roomNumber = roomNumber,
            alias = alias,
            displayName = getDisplayName(),
            capacity = capacity,
            createdAt = createdAt,
            updatedAt = updatedAt,
        )

    private fun PlaceAvailability.toResponse() =
        AvailabilityResponse(
            id = id,
            dayOfWeek = dayOfWeek,
            startTime = startTime,
            endTime = endTime,
            displayOrder = displayOrder,
        )
}
