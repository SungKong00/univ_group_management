package org.castlekong.backend.service

import org.castlekong.backend.dto.CreatePlaceRequest
import org.castlekong.backend.dto.OperatingHoursResponse
import org.castlekong.backend.dto.PlaceDetailResponse
import org.castlekong.backend.dto.PlaceResponse
import org.castlekong.backend.dto.UpdatePlaceRequest
import org.castlekong.backend.entity.Place
import org.castlekong.backend.entity.PlaceOperatingHours
import org.castlekong.backend.entity.User
import org.castlekong.backend.exception.BusinessException
import org.castlekong.backend.exception.ErrorCode
import org.castlekong.backend.repository.GroupMemberRepository
import org.castlekong.backend.repository.GroupRepository
import org.castlekong.backend.repository.PlaceOperatingHoursRepository
import org.castlekong.backend.repository.PlaceRepository
import org.castlekong.backend.repository.PlaceReservationRepository
import org.castlekong.backend.repository.PlaceUsageGroupRepository
import org.castlekong.backend.security.PermissionService
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
@Transactional
class PlaceService(
    private val placeRepository: PlaceRepository,
    private val placeOperatingHoursRepository: PlaceOperatingHoursRepository,
    private val placeOperatingHoursService: PlaceOperatingHoursService,
    private val placeReservationRepository: PlaceReservationRepository,
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

        // 운영 시간 설정 (기본값: 월-금 09:00-18:00)
        createDefaultOperatingHours(place)

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

        val operatingHours = placeOperatingHoursRepository.findByPlaceId(placeId)
        val approvedCount = placeUsageGroupRepository.findApprovedByPlaceId(placeId).size

        return PlaceDetailResponse(
            place = place.toResponse(),
            operatingHours = operatingHours.map { it.toResponse() },
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

    private fun createDefaultOperatingHours(place: Place) {
        val defaultDays =
            listOf(
                java.time.DayOfWeek.MONDAY,
                java.time.DayOfWeek.TUESDAY,
                java.time.DayOfWeek.WEDNESDAY,
                java.time.DayOfWeek.THURSDAY,
                java.time.DayOfWeek.FRIDAY,
            )
        val startTime = java.time.LocalTime.of(9, 0)
        val endTime = java.time.LocalTime.of(18, 0)

        val operatingHours =
            defaultDays.map { day ->
                PlaceOperatingHours(
                    place = place,
                    dayOfWeek = day,
                    startTime = startTime,
                    endTime = endTime,
                    isClosed = false,
                )
            }
        placeOperatingHoursRepository.saveAll(operatingHours)
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

    private fun PlaceOperatingHours.toResponse() =
        OperatingHoursResponse(
            id = id,
            dayOfWeek = dayOfWeek,
            startTime = startTime,
            endTime = endTime,
            isClosed = isClosed,
        )

    // ===== Calendar Place Integration (Phase 2) =====

    /**
     * 다중 장소 예약 가능 정보 조회 (최적화)
     */
    @Transactional(readOnly = true)
    fun getMultiplePlaceAvailability(
        placeIds: List<Long>,
        date: java.time.LocalDate,
    ): Map<Long, org.castlekong.backend.dto.PlaceAvailabilityDto> {
        // 1. 시작/종료 시간 계산 (해당 날짜의 00:00 ~ 다음 날 00:00)
        val startDateTime = date.atStartOfDay()
        val endDateTime = date.plusDays(1).atStartOfDay()

        // 2. 각 장소의 운영시간 조회
        val operatingHoursByPlace =
            placeIds
                .flatMap { placeId -> placeOperatingHoursRepository.findByPlaceId(placeId) }
                .groupBy { it.place.id }

        // 3. 각 장소의 예약 내역 조회 (한 번의 쿼리로 최적화)
        val reservationsByPlace =
            placeRepository
                .findAllById(placeIds)
                .associateWith { place ->
                    placeReservationRepository.findByPlaceIdAndDateRange(place.id, startDateTime, endDateTime)
                }

        // 4. 응답 DTO 생성
        return placeIds.associateWith { placeId ->
            val operatingHours =
                operatingHoursByPlace[placeId]?.map { oh ->
                    org.castlekong.backend.dto.OperatingHourDto(
                        dayOfWeek = oh.dayOfWeek,
                        startTime = oh.startTime,
                        endTime = oh.endTime,
                    )
                } ?: emptyList()

            val place = placeRepository.findById(placeId).orElse(null)
            val reservations =
                reservationsByPlace[place]?.map { pr ->
                    org.castlekong.backend.dto.ReservationSimpleDto(
                        id = pr.id,
                        startDateTime = pr.groupEvent.startDate,
                        endDateTime = pr.groupEvent.endDate,
                        title = pr.groupEvent.title,
                    )
                } ?: emptyList()

            org.castlekong.backend.dto.PlaceAvailabilityDto(
                placeId = placeId,
                date = date,
                operatingHours = operatingHours,
                reservations = reservations,
            )
        }
    }

    /**
     * 특정 시간대에 예약 가능한 장소 필터링
     */
    @Transactional(readOnly = true)
    fun getAvailablePlacesAt(
        placeIds: List<Long>,
        startDateTime: java.time.LocalDateTime,
        endDateTime: java.time.LocalDateTime,
    ): List<PlaceResponse> {
        val availablePlaces = mutableListOf<PlaceResponse>()

        for (placeId in placeIds) {
            val place =
                placeRepository.findActiveById(placeId)
                    .orElse(null) ?: continue

            // 1. 운영시간 체크
            val dayOfWeek = startDateTime.dayOfWeek
            val operatingHours = placeOperatingHoursRepository.findByPlaceId(placeId)
            val operatingHoursForDay = operatingHours.filter { it.dayOfWeek == dayOfWeek }

            if (operatingHoursForDay.isEmpty()) {
                continue // 해당 요일에 운영하지 않음
            }

            // 시작/종료 시간이 운영시간 내에 있는지 확인
            val isWithinOperatingHours =
                operatingHoursForDay.any { oh ->
                    !oh.isClosed && oh.fullyContains(startDateTime.toLocalTime(), endDateTime.toLocalTime())
                }

            if (!isWithinOperatingHours) {
                continue // 운영시간 외
            }

            // 2. 예약 충돌 체크
            val conflicts = placeReservationRepository.findOverlappingReservations(placeId, startDateTime, endDateTime)

            if (conflicts.isEmpty()) {
                availablePlaces.add(place.toResponse())
            }
        }

        return availablePlaces
    }
}
