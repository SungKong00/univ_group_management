package org.castlekong.backend.controller

import jakarta.validation.Valid
import org.castlekong.backend.dto.ApiResponse
import org.castlekong.backend.dto.CreatePlaceReservationRequest
import org.castlekong.backend.dto.PlaceCalendarResponse
import org.castlekong.backend.dto.PlaceReservationResponse
import org.castlekong.backend.dto.UpdatePlaceReservationRequest
import org.castlekong.backend.service.PlaceReservationService
import org.castlekong.backend.service.UserService
import org.springframework.format.annotation.DateTimeFormat
import org.springframework.http.HttpStatus
import org.springframework.security.core.Authentication
import org.springframework.web.bind.annotation.DeleteMapping
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PatchMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.ResponseStatus
import org.springframework.web.bind.annotation.RestController
import java.time.LocalDate

/**
 * 장소 예약 관리 컨트롤러
 *
 * 장소 예약 생성/조회/수정/삭제 기능 제공
 */
@RestController
@RequestMapping("/api")
class PlaceReservationController(
    private val placeReservationService: PlaceReservationService,
    userService: UserService,
) : BaseController(userService) {
    /**
     * POST /api/places/{placeId}/reservations
     * 새로운 장소 예약 생성
     *
     * @param placeId 장소 ID
     * @param request 예약 생성 요청 (placeId, groupEventId)
     * @param authentication JWT 인증 정보
     * @return 생성된 예약 정보
     */
    @PostMapping("/places/{placeId}/reservations")
    @ResponseStatus(HttpStatus.CREATED)
    fun createReservation(
        @PathVariable placeId: Long,
        @Valid @RequestBody request: CreatePlaceReservationRequest,
        authentication: Authentication,
    ): ApiResponse<PlaceReservationResponse> {
        val user = getCurrentUser(authentication)
        val reservation =
            placeReservationService.createReservation(
                placeId = request.placeId,
                groupEventId = request.groupEventId,
                userId = user.id!!,
            )
        return ApiResponse.success(reservation.toResponse())
    }

    /**
     * GET /api/places/{placeId}/reservations?startDate={date}&endDate={date}
     * 특정 장소의 예약 목록 조회 (공개 API - 인증 불필요)
     *
     * @param placeId 장소 ID
     * @param startDate 조회 시작 날짜
     * @param endDate 조회 종료 날짜
     * @param authentication JWT 인증 정보 (선택적)
     * @return 예약 목록
     */
    @GetMapping("/places/{placeId}/reservations")
    fun getReservations(
        @PathVariable placeId: Long,
        @RequestParam("startDate") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) startDate: LocalDate,
        @RequestParam("endDate") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) endDate: LocalDate,
        authentication: Authentication?,
    ): ApiResponse<List<PlaceReservationResponse>> {
        val userId = authentication?.let { getCurrentUser(it).id }
        val reservations =
            placeReservationService.getReservations(
                placeId = placeId,
                startDate = startDate.atStartOfDay(),
                endDate = endDate.plusDays(1).atStartOfDay(),
                userId = userId,
            )
        return ApiResponse.success(reservations.map { it.toResponse() })
    }

    /**
     * PATCH /api/reservations/{reservationId}
     * 예약 수정 (장소 변경)
     *
     * @param reservationId 예약 ID
     * @param request 수정 요청 (placeId nullable)
     * @param authentication JWT 인증 정보
     * @return 수정된 예약 정보
     */
    @PatchMapping("/reservations/{reservationId}")
    fun updateReservation(
        @PathVariable reservationId: Long,
        @Valid @RequestBody request: UpdatePlaceReservationRequest,
        authentication: Authentication,
    ): ApiResponse<PlaceReservationResponse> {
        val user = getCurrentUser(authentication)
        val reservation =
            placeReservationService.updateReservation(
                reservationId = reservationId,
                newPlaceId = request.placeId,
                userId = user.id!!,
            )
        return ApiResponse.success(reservation.toResponse())
    }

    /**
     * DELETE /api/reservations/{reservationId}
     * 예약 취소
     *
     * @param reservationId 예약 ID
     * @param authentication JWT 인증 정보
     */
    @DeleteMapping("/reservations/{reservationId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    fun cancelReservation(
        @PathVariable reservationId: Long,
        authentication: Authentication,
    ): ApiResponse<Unit> {
        val user = getCurrentUser(authentication)
        placeReservationService.cancelReservation(
            reservationId = reservationId,
            userId = user.id!!,
        )
        return ApiResponse.success()
    }

    /**
     * GET /api/places/calendar?placeIds={ids}&startDate={date}&endDate={date}
     * 다중 장소 캘린더 조회 (공개 API - 인증 불필요)
     *
     * @param placeIds 장소 ID 목록 (쉼표로 구분)
     * @param startDate 조회 시작 날짜
     * @param endDate 조회 종료 날짜
     * @param authentication JWT 인증 정보 (선택적)
     * @return 장소별 예약 목록
     */
    @GetMapping("/places/calendar")
    fun getPlaceCalendar(
        @RequestParam("placeIds") placeIds: List<Long>,
        @RequestParam("startDate") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) startDate: LocalDate,
        @RequestParam("endDate") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) endDate: LocalDate,
        authentication: Authentication?,
    ): ApiResponse<List<PlaceCalendarResponse>> {
        val userId = authentication?.let { getCurrentUser(it).id }
        val reservations =
            placeReservationService.getPlaceCalendar(
                placeIds = placeIds,
                startDate = startDate.atStartOfDay(),
                endDate = endDate.plusDays(1).atStartOfDay(),
                userId = userId,
            )

        // 장소별로 그룹핑
        val groupedByPlace = reservations.groupBy { it.place.id }
        val result =
            groupedByPlace.map { (placeId, reservationList) ->
                val firstReservation = reservationList.first()
                PlaceCalendarResponse(
                    placeId = placeId,
                    placeName = firstReservation.place.getDisplayName(),
                    reservations = reservationList.map { it.toResponse() },
                )
            }

        return ApiResponse.success(result)
    }
}

/**
 * PlaceReservation Entity → PlaceReservationResponse DTO 변환 확장 함수
 */
private fun org.castlekong.backend.entity.PlaceReservation.toResponse() =
    PlaceReservationResponse(
        id = this.id,
        placeId = this.place.id,
        placeName = this.place.getDisplayName(),
        groupEventId = this.groupEvent.id,
        title = this.groupEvent.title,
        startDateTime = this.groupEvent.startDate,
        endDateTime = this.groupEvent.endDate,
        description = this.groupEvent.description,
        reservedBy = this.reservedBy.id!!,
        reservedByName = this.reservedBy.name,
        createdAt = this.createdAt,
    )
