package org.castlekong.backend.controller

import jakarta.validation.Valid
import org.castlekong.backend.dto.ApiResponse
import org.castlekong.backend.dto.AvailabilityRequest
import org.castlekong.backend.dto.AvailablePlacesAtRequest
import org.castlekong.backend.dto.AvailablePlacesAtResponse
import org.castlekong.backend.dto.CreatePlaceRequest
import org.castlekong.backend.dto.MultiplePlaceAvailabilityRequest
import org.castlekong.backend.dto.PlaceAvailabilityDto
import org.castlekong.backend.dto.PlaceDetailResponse
import org.castlekong.backend.dto.PlaceResponse
import org.castlekong.backend.dto.RequestUsageRequest
import org.castlekong.backend.dto.UpdatePlaceRequest
import org.castlekong.backend.dto.UpdateUsageStatusRequest
import org.castlekong.backend.dto.UsageGroupResponse
import org.castlekong.backend.service.PlaceService
import org.castlekong.backend.service.PlaceUsageGroupService
import org.castlekong.backend.service.UserService
import org.springframework.http.HttpStatus
import org.springframework.security.core.Authentication
import org.springframework.web.bind.annotation.DeleteMapping
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PatchMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.PutMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.ResponseStatus
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/api")
class PlaceController(
    private val placeService: PlaceService,
    private val placeUsageGroupService: PlaceUsageGroupService,
    private val userService: UserService,
) {
    /**
     * GET /api/places
     * 활성 장소 목록 조회 (공개)
     */
    @GetMapping("/places")
    fun getAllPlaces(): ApiResponse<List<PlaceResponse>> {
        val places = placeService.getAllActivePlaces()
        return ApiResponse.success(places)
    }

    /**
     * GET /api/groups/{groupId}/reservable-places
     * 특정 그룹이 예약 가능한 장소 목록 조회
     */
    @GetMapping("/groups/{groupId}/reservable-places")
    fun getReservablePlacesForGroup(
        authentication: Authentication,
        @PathVariable groupId: Long,
    ): ApiResponse<List<PlaceResponse>> {
        val email = authentication.name
        val user = userService.findByEmail(email) ?: throw IllegalStateException("User not found")
        val places = placeService.findReservablePlacesForGroup(user, groupId)
        return ApiResponse.success(places)
    }

    /**
     * GET /api/places/{id}
     * 장소 상세 조회 (공개)
     */
    @GetMapping("/places/{id}")
    fun getPlaceDetail(
        @PathVariable id: Long,
    ): ApiResponse<PlaceDetailResponse> {
        val detail = placeService.getPlaceDetail(id)
        return ApiResponse.success(detail)
    }

    /**
     * POST /api/places
     * 장소 등록 (CALENDAR_MANAGE)
     */
    @PostMapping("/places")
    @ResponseStatus(HttpStatus.CREATED)
    fun createPlace(
        authentication: Authentication,
        @Valid @RequestBody request: CreatePlaceRequest,
    ): ApiResponse<PlaceResponse> {
        val email = authentication.name
        val user = userService.findByEmail(email) ?: throw IllegalStateException("User not found")
        val place = placeService.createPlace(user, request)
        return ApiResponse.success(place)
    }

    /**
     * PATCH /api/places/{id}
     * 장소 수정 (관리 주체)
     */
    @PatchMapping("/places/{id}")
    fun updatePlace(
        authentication: Authentication,
        @PathVariable id: Long,
        @Valid @RequestBody request: UpdatePlaceRequest,
    ): ApiResponse<PlaceResponse> {
        val email = authentication.name
        val user = userService.findByEmail(email) ?: throw IllegalStateException("User not found")
        val place = placeService.updatePlace(user, id, request)
        return ApiResponse.success(place)
    }

    /**
     * DELETE /api/places/{id}
     * 장소 삭제 (Soft delete, 관리 주체)
     */
    @DeleteMapping("/places/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    fun deletePlace(
        authentication: Authentication,
        @PathVariable id: Long,
    ) {
        val email = authentication.name
        val user = userService.findByEmail(email) ?: throw IllegalStateException("User not found")
        placeService.deletePlace(user, id)
    }

    /**
     * POST /api/places/{id}/availabilities
     * 운영 시간 설정 (관리 주체)
     */
    @PostMapping("/places/{id}/availabilities")
    fun setAvailabilities(
        authentication: Authentication,
        @PathVariable id: Long,
        @Valid @RequestBody requests: List<AvailabilityRequest>,
    ): ApiResponse<Unit> {
        val email = authentication.name
        val user = userService.findByEmail(email) ?: throw IllegalStateException("User not found")
        placeService.setAvailabilities(user, id, requests)
        return ApiResponse.success(Unit)
    }

    /**
     * PUT /api/places/{id}/availabilities
     * 운영 시간 수정 (관리 주체)
     * 기존 운영시간을 삭제하고 새로운 운영시간을 설정한 후, 업데이트된 장소 상세 정보를 반환합니다.
     */
    @PutMapping("/places/{id}/availabilities")
    fun updateAvailabilities(
        authentication: Authentication,
        @PathVariable id: Long,
        @Valid @RequestBody requests: List<AvailabilityRequest>,
    ): ApiResponse<PlaceDetailResponse> {
        val email = authentication.name
        val user = userService.findByEmail(email) ?: throw IllegalStateException("User not found")
        val updatedPlace = placeService.updateAvailabilities(user, id, requests)
        return ApiResponse.success(updatedPlace)
    }

    // ===== PlaceUsageGroup API =====

    /**
     * POST /api/places/{id}/usage-requests
     * 장소 사용 신청 (CALENDAR_MANAGE)
     */
    @PostMapping("/places/{id}/usage-requests")
    @ResponseStatus(HttpStatus.CREATED)
    fun requestUsage(
        authentication: Authentication,
        @PathVariable id: Long,
        @Valid @RequestBody request: RequestUsageRequest,
    ): ApiResponse<UsageGroupResponse> {
        val email = authentication.name
        val user = userService.findByEmail(email) ?: throw IllegalStateException("User not found")
        val result = placeUsageGroupService.requestUsage(user, id, request)
        return ApiResponse.success(result)
    }

    /**
     * PATCH /api/places/{placeId}/usage-groups/{groupId}
     * 사용 승인/거절 (관리 주체)
     */
    @PatchMapping("/places/{placeId}/usage-groups/{groupId}")
    fun updateUsageStatus(
        authentication: Authentication,
        @PathVariable placeId: Long,
        @PathVariable groupId: Long,
        @Valid @RequestBody request: UpdateUsageStatusRequest,
    ): ApiResponse<UsageGroupResponse> {
        val email = authentication.name
        val user = userService.findByEmail(email) ?: throw IllegalStateException("User not found")
        val result = placeUsageGroupService.updateUsageStatus(user, placeId, groupId, request)
        return ApiResponse.success(result)
    }

    /**
     * DELETE /api/places/{placeId}/usage-groups/{groupId}
     * 사용 권한 취소 (관리 주체, 미래 예약 삭제)
     */
    @DeleteMapping("/places/{placeId}/usage-groups/{groupId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    fun revokeUsagePermission(
        authentication: Authentication,
        @PathVariable placeId: Long,
        @PathVariable groupId: Long,
    ) {
        val email = authentication.name
        val user = userService.findByEmail(email) ?: throw IllegalStateException("User not found")
        placeUsageGroupService.revokeUsagePermission(user, placeId, groupId)
    }

    /**
     * GET /api/places/{id}/usage-requests/pending
     * 대기 중인 사용 신청 조회 (관리 주체)
     */
    @GetMapping("/places/{id}/usage-requests/pending")
    fun getPendingRequests(
        authentication: Authentication,
        @PathVariable id: Long,
    ): ApiResponse<List<UsageGroupResponse>> {
        val email = authentication.name
        val user = userService.findByEmail(email) ?: throw IllegalStateException("User not found")
        val result = placeUsageGroupService.getPendingRequests(user, id)
        return ApiResponse.success(result)
    }

    /**
     * GET /api/places/{id}/usage-groups
     * 승인된 사용 그룹 조회 (공개)
     */
    @GetMapping("/places/{id}/usage-groups")
    fun getApprovedGroups(
        @PathVariable id: Long,
    ): ApiResponse<List<UsageGroupResponse>> {
        val result = placeUsageGroupService.getApprovedGroups(id)
        return ApiResponse.success(result)
    }

    // ===== Calendar Place Integration (Phase 2) =====

    /**
     * POST /api/places/availability
     * 다중 장소 예약 가능 정보 조회 (공개)
     */
    @PostMapping("/places/availability")
    fun getMultiplePlaceAvailability(
        @Valid @RequestBody request: MultiplePlaceAvailabilityRequest,
    ): ApiResponse<Map<Long, PlaceAvailabilityDto>> {
        val result = placeService.getMultiplePlaceAvailability(request.placeIds, request.date)
        return ApiResponse.success(result)
    }

    /**
     * POST /api/places/available-at
     * 특정 시간대 예약 가능 장소 조회 (공개)
     */
    @PostMapping("/places/available-at")
    fun getAvailablePlacesAt(
        @Valid @RequestBody request: AvailablePlacesAtRequest,
    ): ApiResponse<AvailablePlacesAtResponse> {
        val availablePlaces =
            placeService.getAvailablePlacesAt(
                request.placeIds,
                request.startDateTime,
                request.endDateTime,
            )
        return ApiResponse.success(AvailablePlacesAtResponse(availablePlaces))
    }
}
