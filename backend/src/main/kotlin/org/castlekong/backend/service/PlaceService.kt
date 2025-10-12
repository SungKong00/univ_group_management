package org.castlekong.backend.service

import org.castlekong.backend.dto.*
import org.castlekong.backend.entity.Place
import org.castlekong.backend.entity.PlaceAvailability
import org.castlekong.backend.entity.User
import org.castlekong.backend.exception.BusinessException
import org.castlekong.backend.exception.ErrorCode
import org.castlekong.backend.repository.*
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
    fun createPlace(user: User, request: CreatePlaceRequest): PlaceResponse {
        // 권한 확인
        checkCalendarManagePermission(user.id!!, request.managingGroupId)

        // 중복 확인
        placeRepository.findByBuildingAndRoomNumber(request.building.trim(), request.roomNumber.trim())
            .ifPresent { throw BusinessException(ErrorCode.PLACE_ALREADY_EXISTS) }

        // 관리 그룹 조회
        val managingGroup = groupRepository.findById(request.managingGroupId)
            .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }

        // 장소 생성
        val place = placeRepository.save(
            Place(
                managingGroup = managingGroup,
                building = request.building.trim(),
                roomNumber = request.roomNumber.trim(),
                alias = request.alias?.trim(),
                capacity = request.capacity
            )
        )

        // 운영 시간 설정
        request.availabilities?.let { addAvailabilities(place.id, it) }

        return place.toResponse()
    }

    /**
     * 장소 조회 (공개)
     */
    @Transactional(readOnly = true)
    fun getAllActivePlaces(): List<PlaceResponse> =
        placeRepository.findAllActive().map { it.toResponse() }

    /**
     * 장소 상세 조회
     */
    @Transactional(readOnly = true)
    fun getPlaceDetail(placeId: Long): PlaceDetailResponse {
        val place = placeRepository.findActiveById(placeId)
            .orElseThrow { BusinessException(ErrorCode.PLACE_NOT_FOUND) }

        val availabilities = placeAvailabilityRepository.findByPlaceId(placeId)
        val approvedCount = placeUsageGroupRepository.findApprovedByPlaceId(placeId).size

        return PlaceDetailResponse(
            place = place.toResponse(),
            availabilities = availabilities.map { it.toResponse() },
            approvedGroupCount = approvedCount
        )
    }

    /**
     * 장소 수정
     */
    fun updatePlace(user: User, placeId: Long, request: UpdatePlaceRequest): PlaceResponse {
        val place = placeRepository.findActiveById(placeId)
            .orElseThrow { BusinessException(ErrorCode.PLACE_NOT_FOUND) }

        checkCalendarManagePermission(user.id!!, place.managingGroup.id)

        place.updateInfo(request.alias?.trim(), request.capacity)
        return placeRepository.save(place).toResponse()
    }

    /**
     * 장소 삭제 (Soft delete)
     */
    fun deletePlace(user: User, placeId: Long) {
        val place = placeRepository.findActiveById(placeId)
            .orElseThrow { BusinessException(ErrorCode.PLACE_NOT_FOUND) }

        checkCalendarManagePermission(user.id!!, place.managingGroup.id)

        place.markAsDeleted()
        placeRepository.save(place)
    }

    /**
     * 운영 시간 설정
     */
    fun setAvailabilities(user: User, placeId: Long, requests: List<AvailabilityRequest>) {
        val place = placeRepository.findActiveById(placeId)
            .orElseThrow { BusinessException(ErrorCode.PLACE_NOT_FOUND) }

        checkCalendarManagePermission(user.id!!, place.managingGroup.id)

        // 기존 운영 시간 삭제
        placeAvailabilityRepository.deleteByPlaceId(placeId)

        // 새 운영 시간 추가
        addAvailabilities(placeId, requests)
    }

    private fun addAvailabilities(placeId: Long, requests: List<AvailabilityRequest>) {
        val place = placeRepository.findById(placeId)
            .orElseThrow { BusinessException(ErrorCode.PLACE_NOT_FOUND) }

        val availabilities = requests.map { req ->
            if (!req.endTime.isAfter(req.startTime)) {
                throw BusinessException(ErrorCode.INVALID_TIME_RANGE)
            }

            PlaceAvailability(
                place = place,
                dayOfWeek = req.dayOfWeek,
                startTime = req.startTime,
                endTime = req.endTime,
                displayOrder = req.displayOrder
            )
        }

        placeAvailabilityRepository.saveAll(availabilities)
    }

    private fun checkCalendarManagePermission(userId: Long, groupId: Long) {
        if (!groupMemberRepository.existsByGroupIdAndUserId(groupId, userId)) {
            throw BusinessException(ErrorCode.NOT_GROUP_MEMBER)
        }

        if (!permissionService.hasPermission(userId, groupId, "CALENDAR_MANAGE")) {
            throw BusinessException(ErrorCode.FORBIDDEN, "장소 관리 권한이 없습니다")
        }
    }

    private fun Place.toResponse() = PlaceResponse(
        id = id,
        managingGroupId = managingGroup.id,
        managingGroupName = managingGroup.name,
        building = building,
        roomNumber = roomNumber,
        alias = alias,
        displayName = getDisplayName(),
        capacity = capacity,
        createdAt = createdAt,
        updatedAt = updatedAt
    )

    private fun PlaceAvailability.toResponse() = AvailabilityResponse(
        id = id,
        dayOfWeek = dayOfWeek,
        startTime = startTime,
        endTime = endTime,
        displayOrder = displayOrder
    )
}
