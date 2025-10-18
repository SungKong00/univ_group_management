package org.castlekong.backend.controller

import jakarta.validation.Valid
import org.castlekong.backend.common.ApiResponse
import org.castlekong.backend.dto.AddFullDayClosureRequest
import org.castlekong.backend.dto.AddPartialClosureRequest
import org.castlekong.backend.dto.AddRestrictedTimeRequest
import org.castlekong.backend.dto.AvailableTimesResponse
import org.castlekong.backend.dto.ClosureInfo
import org.castlekong.backend.dto.OperatingHoursInfo
import org.castlekong.backend.dto.OperatingHoursItem
import org.castlekong.backend.dto.OperatingHoursResponse
import org.castlekong.backend.dto.PlaceClosureResponse
import org.castlekong.backend.dto.ReservationInfo
import org.castlekong.backend.dto.RestrictedTimeInfo
import org.castlekong.backend.dto.RestrictedTimeResponse
import org.castlekong.backend.dto.SetOperatingHoursRequest
import org.castlekong.backend.dto.TimeSlotInfo
import org.castlekong.backend.dto.UpdateOperatingHoursRequest
import org.castlekong.backend.dto.UpdateRestrictedTimeRequest
import org.castlekong.backend.entity.PlaceClosure
import org.castlekong.backend.entity.PlaceOperatingHours
import org.castlekong.backend.entity.PlaceRestrictedTime
import org.castlekong.backend.exception.BusinessException
import org.castlekong.backend.exception.ErrorCode
import org.castlekong.backend.repository.PlaceRepository
import org.castlekong.backend.repository.PlaceReservationRepository
import org.castlekong.backend.repository.UserRepository
import org.castlekong.backend.service.PlaceClosureService
import org.castlekong.backend.service.PlaceOperatingHoursService
import org.castlekong.backend.service.PlaceReservationService
import org.castlekong.backend.service.PlaceRestrictedTimeService
import org.springframework.format.annotation.DateTimeFormat
import org.springframework.http.ResponseEntity
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.security.core.Authentication
import org.springframework.web.bind.annotation.DeleteMapping
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PatchMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.PutMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController
import java.time.DayOfWeek
import java.time.LocalDate

/**
 * PlaceTimeManagementController
 *
 * 장소 시간 관리 API
 * - 운영시간 관리
 * - 금지시간 관리
 * - 임시 휴무 관리
 * - 예약 가능 시간 조회
 */
@RestController
@RequestMapping("/api/places")
class PlaceTimeManagementController(
    private val placeRepository: PlaceRepository,
    private val placeOperatingHoursService: PlaceOperatingHoursService,
    private val placeRestrictedTimeService: PlaceRestrictedTimeService,
    private val placeClosureService: PlaceClosureService,
    private val placeReservationService: PlaceReservationService,
    private val placeReservationRepository: PlaceReservationRepository,
    private val userRepository: UserRepository,
) {
    // ========================================
    // 운영시간 API
    // ========================================

    /**
     * 운영시간 조회 (공개)
     *
     * GET /api/places/{placeId}/operating-hours
     */
    @GetMapping("/{placeId}/operating-hours")
    fun getOperatingHours(
        @PathVariable placeId: Long,
    ): ResponseEntity<ApiResponse<List<OperatingHoursResponse>>> {
        val operatingHours = placeOperatingHoursService.getOperatingHours(placeId)
        return ResponseEntity.ok(ApiResponse.success(operatingHours.map { it.toResponse() }))
    }

    /**
     * 운영시간 전체 설정 (관리자)
     *
     * PUT /api/places/{placeId}/operating-hours
     * 권한: CALENDAR_MANAGE (관리 주체 그룹)
     */
    @PutMapping("/{placeId}/operating-hours")
    @PreAuthorize("isAuthenticated()")
    fun setOperatingHours(
        @PathVariable placeId: Long,
        @Valid @RequestBody request: SetOperatingHoursRequest,
        authentication: Authentication,
    ): ResponseEntity<ApiResponse<List<OperatingHoursResponse>>> {
        val place =
            placeRepository.findActiveById(placeId)
                .orElseThrow { BusinessException(ErrorCode.PLACE_NOT_FOUND) }

        // 권한 확인: 관리 주체 그룹의 CALENDAR_MANAGE (Phase 4에서 @PreAuthorize 추가 예정)
        val user =
            userRepository.findByEmail(authentication.name)
                .orElseThrow { BusinessException(ErrorCode.USER_NOT_FOUND) }

        // 요일별 데이터 변환
        val operatingHoursData =
            request.operatingHours.associate { item ->
                item.dayOfWeek to
                    PlaceOperatingHoursService.OperatingHoursData(
                        startTime = item.startTime,
                        endTime = item.endTime,
                        isClosed = item.isClosed,
                    )
            }

        val result = placeOperatingHoursService.setOperatingHours(place, operatingHoursData)
        return ResponseEntity.ok(ApiResponse.success(result.map { it.toResponse() }))
    }

    /**
     * 특정 요일 운영시간 수정 (관리자)
     *
     * PATCH /api/places/{placeId}/operating-hours/{dayOfWeek}
     * 권한: CALENDAR_MANAGE (관리 주체 그룹)
     */
    @PatchMapping("/{placeId}/operating-hours/{dayOfWeek}")
    @PreAuthorize("isAuthenticated()")
    fun updateOperatingHours(
        @PathVariable placeId: Long,
        @PathVariable dayOfWeek: DayOfWeek,
        @Valid @RequestBody request: UpdateOperatingHoursRequest,
        authentication: Authentication,
    ): ResponseEntity<ApiResponse<OperatingHoursResponse>> {
        val user =
            userRepository.findByEmail(authentication.name)
                .orElseThrow { BusinessException(ErrorCode.USER_NOT_FOUND) }

        val data =
            PlaceOperatingHoursService.OperatingHoursData(
                startTime = request.startTime,
                endTime = request.endTime,
                isClosed = request.isClosed,
            )

        val result = placeOperatingHoursService.updateOperatingHours(placeId, dayOfWeek, data)
        return ResponseEntity.ok(ApiResponse.success(result.toResponse()))
    }

    // ========================================
    // 금지시간 API
    // ========================================

    /**
     * 금지시간 조회 (공개)
     *
     * GET /api/places/{placeId}/restricted-times
     */
    @GetMapping("/{placeId}/restricted-times")
    fun getRestrictedTimes(
        @PathVariable placeId: Long,
    ): ResponseEntity<ApiResponse<List<RestrictedTimeResponse>>> {
        val restrictedTimes = placeRestrictedTimeService.getRestrictedTimes(placeId)
        return ResponseEntity.ok(ApiResponse.success(restrictedTimes.map { it.toResponse() }))
    }

    /**
     * 금지시간 추가 (관리자)
     *
     * POST /api/places/{placeId}/restricted-times
     * 권한: CALENDAR_MANAGE (관리 주체 그룹)
     */
    @PostMapping("/{placeId}/restricted-times")
    @PreAuthorize("isAuthenticated()")
    fun addRestrictedTime(
        @PathVariable placeId: Long,
        @Valid @RequestBody request: AddRestrictedTimeRequest,
        authentication: Authentication,
    ): ResponseEntity<ApiResponse<RestrictedTimeResponse>> {
        val place =
            placeRepository.findActiveById(placeId)
                .orElseThrow { BusinessException(ErrorCode.PLACE_NOT_FOUND) }

        val user =
            userRepository.findByEmail(authentication.name)
                .orElseThrow { BusinessException(ErrorCode.USER_NOT_FOUND) }

        val data =
            PlaceRestrictedTimeService.RestrictedTimeData(
                dayOfWeek = request.dayOfWeek,
                startTime = request.startTime,
                endTime = request.endTime,
                reason = request.reason,
            )

        val result = placeRestrictedTimeService.addRestrictedTime(place, data)
        return ResponseEntity.ok(ApiResponse.success(result.toResponse()))
    }

    /**
     * 금지시간 수정 (관리자)
     *
     * PATCH /api/places/{placeId}/restricted-times/{restrictedTimeId}
     * 권한: CALENDAR_MANAGE (관리 주체 그룹)
     */
    @PatchMapping("/{placeId}/restricted-times/{restrictedTimeId}")
    @PreAuthorize("isAuthenticated()")
    fun updateRestrictedTime(
        @PathVariable placeId: Long,
        @PathVariable restrictedTimeId: Long,
        @Valid @RequestBody request: UpdateRestrictedTimeRequest,
        authentication: Authentication,
    ): ResponseEntity<ApiResponse<RestrictedTimeResponse>> {
        val user =
            userRepository.findByEmail(authentication.name)
                .orElseThrow { BusinessException(ErrorCode.USER_NOT_FOUND) }

        val data =
            PlaceRestrictedTimeService.RestrictedTimeData(
                dayOfWeek = DayOfWeek.MONDAY, // 수정 시 요일은 변경되지 않음 (기존 값 유지)
                startTime = request.startTime,
                endTime = request.endTime,
                reason = request.reason,
            )

        val result = placeRestrictedTimeService.updateRestrictedTime(restrictedTimeId, data)
        return ResponseEntity.ok(ApiResponse.success(result.toResponse()))
    }

    /**
     * 금지시간 삭제 (관리자)
     *
     * DELETE /api/places/{placeId}/restricted-times/{restrictedTimeId}
     * 권한: CALENDAR_MANAGE (관리 주체 그룹)
     */
    @DeleteMapping("/{placeId}/restricted-times/{restrictedTimeId}")
    @PreAuthorize("isAuthenticated()")
    fun deleteRestrictedTime(
        @PathVariable placeId: Long,
        @PathVariable restrictedTimeId: Long,
        authentication: Authentication,
    ): ResponseEntity<ApiResponse<Void>> {
        val user =
            userRepository.findByEmail(authentication.name)
                .orElseThrow { BusinessException(ErrorCode.USER_NOT_FOUND) }

        placeRestrictedTimeService.deleteRestrictedTime(restrictedTimeId)
        return ResponseEntity.ok(ApiResponse.success())
    }

    // ========================================
    // 임시 휴무 API
    // ========================================

    /**
     * 임시 휴무 조회 (날짜 범위, 공개)
     *
     * GET /api/places/{placeId}/closures?from=2025-11-01&to=2025-11-30
     */
    @GetMapping("/{placeId}/closures")
    fun getClosures(
        @PathVariable placeId: Long,
        @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) from: LocalDate,
        @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) to: LocalDate,
    ): ResponseEntity<ApiResponse<List<PlaceClosureResponse>>> {
        val closures = placeClosureService.getClosuresByDateRange(placeId, from, to)
        return ResponseEntity.ok(ApiResponse.success(closures.map { it.toResponse() }))
    }

    /**
     * 임시 휴무 추가 - 전일 휴무 (관리자)
     *
     * POST /api/places/{placeId}/closures/full-day
     * 권한: CALENDAR_MANAGE (관리 주체 그룹)
     */
    @PostMapping("/{placeId}/closures/full-day")
    @PreAuthorize("isAuthenticated()")
    fun addFullDayClosure(
        @PathVariable placeId: Long,
        @Valid @RequestBody request: AddFullDayClosureRequest,
        authentication: Authentication,
    ): ResponseEntity<ApiResponse<PlaceClosureResponse>> {
        val place =
            placeRepository.findActiveById(placeId)
                .orElseThrow { BusinessException(ErrorCode.PLACE_NOT_FOUND) }

        val user =
            userRepository.findByEmail(authentication.name)
                .orElseThrow { BusinessException(ErrorCode.USER_NOT_FOUND) }

        val data =
            PlaceClosureService.ClosureData(
                closureDate = request.closureDate,
                isFullDay = true,
                startTime = null,
                endTime = null,
                reason = request.reason,
            )

        val result = placeClosureService.addClosure(place, user, data)
        return ResponseEntity.ok(ApiResponse.success(result.toResponse()))
    }

    /**
     * 임시 휴무 추가 - 부분 시간 휴무 (관리자)
     *
     * POST /api/places/{placeId}/closures/partial
     * 권한: CALENDAR_MANAGE (관리 주체 그룹)
     */
    @PostMapping("/{placeId}/closures/partial")
    @PreAuthorize("isAuthenticated()")
    fun addPartialClosure(
        @PathVariable placeId: Long,
        @Valid @RequestBody request: AddPartialClosureRequest,
        authentication: Authentication,
    ): ResponseEntity<ApiResponse<PlaceClosureResponse>> {
        val place =
            placeRepository.findActiveById(placeId)
                .orElseThrow { BusinessException(ErrorCode.PLACE_NOT_FOUND) }

        val user =
            userRepository.findByEmail(authentication.name)
                .orElseThrow { BusinessException(ErrorCode.USER_NOT_FOUND) }

        val data =
            PlaceClosureService.ClosureData(
                closureDate = request.closureDate,
                isFullDay = false,
                startTime = request.startTime,
                endTime = request.endTime,
                reason = request.reason,
            )

        val result = placeClosureService.addClosure(place, user, data)
        return ResponseEntity.ok(ApiResponse.success(result.toResponse()))
    }

    /**
     * 임시 휴무 삭제 (관리자)
     *
     * DELETE /api/places/{placeId}/closures/{closureId}
     * 권한: CALENDAR_MANAGE (관리 주체 그룹)
     */
    @DeleteMapping("/{placeId}/closures/{closureId}")
    @PreAuthorize("isAuthenticated()")
    fun deleteClosure(
        @PathVariable placeId: Long,
        @PathVariable closureId: Long,
        authentication: Authentication,
    ): ResponseEntity<ApiResponse<Void>> {
        val user =
            userRepository.findByEmail(authentication.name)
                .orElseThrow { BusinessException(ErrorCode.USER_NOT_FOUND) }

        placeClosureService.deleteClosure(closureId)
        return ResponseEntity.ok(ApiResponse.success())
    }

    // ========================================
    // 예약 가능 시간 조회 API
    // ========================================

    /**
     * 특정 날짜의 예약 가능 시간 조회 (공개)
     *
     * GET /api/places/{placeId}/available-times?date=2025-11-15
     */
    @GetMapping("/{placeId}/available-times")
    fun getAvailableTimes(
        @PathVariable placeId: Long,
        @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) date: LocalDate,
    ): ResponseEntity<ApiResponse<AvailableTimesResponse>> {
        val place =
            placeRepository.findActiveById(placeId)
                .orElseThrow { BusinessException(ErrorCode.PLACE_NOT_FOUND) }

        // 1. 운영시간
        val operatingHours = placeOperatingHoursService.getOperatingHoursByDayOfWeek(placeId, date.dayOfWeek)
        val isClosed = operatingHours == null || operatingHours.isClosed

        // 2. 금지시간
        val restrictedTimes = placeRestrictedTimeService.getRestrictedTimesByDayOfWeek(placeId, date.dayOfWeek)

        // 3. 임시 휴무
        val closure = placeClosureService.getClosureByDate(placeId, date)

        // 4. 기존 예약
        val startDateTime = date.atStartOfDay()
        val endDateTime = date.atTime(23, 59, 59)
        val existingReservations = placeReservationRepository.findByPlaceIdAndDateRange(placeId, startDateTime, endDateTime)

        // 5. 예약 가능 슬롯 계산
        val availableSlots = placeReservationService.getAvailableSlots(placeId, date)

        val response =
            AvailableTimesResponse(
                date = date,
                dayOfWeek = date.dayOfWeek,
                isClosed = isClosed,
                operatingHours =
                    operatingHours?.let {
                        OperatingHoursInfo(it.startTime, it.endTime)
                    },
                restrictedTimes =
                    restrictedTimes.map {
                        RestrictedTimeInfo(it.startTime, it.endTime, it.reason)
                    },
                closures =
                    listOfNotNull(
                        closure?.let {
                            ClosureInfo(it.isFullDay, it.startTime, it.endTime, it.reason)
                        },
                    ),
                existingReservations =
                    existingReservations.map {
                        ReservationInfo(
                            it.getStartDateTime().toLocalTime(),
                            it.getEndDateTime().toLocalTime(),
                            it.groupEvent.group.name,
                        )
                    },
                availableSlots =
                    availableSlots.map {
                        TimeSlotInfo(it.startTime, it.endTime)
                    },
            )

        return ResponseEntity.ok(ApiResponse.success(response))
    }

    // ========================================
    // Extension Functions (DTO 변환)
    // ========================================

    private fun PlaceOperatingHours.toResponse() =
        OperatingHoursResponse(
            id = id,
            dayOfWeek = dayOfWeek,
            startTime = startTime,
            endTime = endTime,
            isClosed = isClosed,
        )

    private fun PlaceRestrictedTime.toResponse() =
        RestrictedTimeResponse(
            id = id,
            dayOfWeek = dayOfWeek,
            startTime = startTime,
            endTime = endTime,
            reason = reason,
            displayOrder = displayOrder,
        )

    private fun PlaceClosure.toResponse() =
        PlaceClosureResponse(
            id = id,
            closureDate = closureDate,
            isFullDay = isFullDay,
            startTime = startTime,
            endTime = endTime,
            reason = reason,
        )
}
