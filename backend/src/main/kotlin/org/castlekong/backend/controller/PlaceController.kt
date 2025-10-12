package org.castlekong.backend.controller

import jakarta.validation.Valid
import org.castlekong.backend.dto.*
import org.castlekong.backend.service.PlaceService
import org.castlekong.backend.util.ApiResponse
import org.springframework.http.HttpStatus
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.security.core.userdetails.UserDetails
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/places")
class PlaceController(
    private val placeService: PlaceService
) {

    /**
     * GET /api/places
     * 활성 장소 목록 조회 (공개)
     */
    @GetMapping
    fun getAllPlaces(): ApiResponse<List<PlaceResponse>> {
        val places = placeService.getAllActivePlaces()
        return ApiResponse.success(places)
    }

    /**
     * GET /api/places/{id}
     * 장소 상세 조회 (공개)
     */
    @GetMapping("/{id}")
    fun getPlaceDetail(@PathVariable id: Long): ApiResponse<PlaceDetailResponse> {
        val detail = placeService.getPlaceDetail(id)
        return ApiResponse.success(detail)
    }

    /**
     * POST /api/places
     * 장소 등록 (CALENDAR_MANAGE)
     */
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    fun createPlace(
        @AuthenticationPrincipal userDetails: UserDetails,
        @Valid @RequestBody request: CreatePlaceRequest
    ): ApiResponse<PlaceResponse> {
        val user = (userDetails as org.castlekong.backend.security.CustomUserDetails).user
        val place = placeService.createPlace(user, request)
        return ApiResponse.success(place)
    }

    /**
     * PATCH /api/places/{id}
     * 장소 수정 (관리 주체)
     */
    @PatchMapping("/{id}")
    fun updatePlace(
        @AuthenticationPrincipal userDetails: UserDetails,
        @PathVariable id: Long,
        @Valid @RequestBody request: UpdatePlaceRequest
    ): ApiResponse<PlaceResponse> {
        val user = (userDetails as org.castlekong.backend.security.CustomUserDetails).user
        val place = placeService.updatePlace(user, id, request)
        return ApiResponse.success(place)
    }

    /**
     * DELETE /api/places/{id}
     * 장소 삭제 (Soft delete, 관리 주체)
     */
    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    fun deletePlace(
        @AuthenticationPrincipal userDetails: UserDetails,
        @PathVariable id: Long
    ) {
        val user = (userDetails as org.castlekong.backend.security.CustomUserDetails).user
        placeService.deletePlace(user, id)
    }

    /**
     * POST /api/places/{id}/availabilities
     * 운영 시간 설정 (관리 주체)
     */
    @PostMapping("/{id}/availabilities")
    fun setAvailabilities(
        @AuthenticationPrincipal userDetails: UserDetails,
        @PathVariable id: Long,
        @Valid @RequestBody requests: List<AvailabilityRequest>
    ): ApiResponse<Unit> {
        val user = (userDetails as org.castlekong.backend.security.CustomUserDetails).user
        placeService.setAvailabilities(user, id, requests)
        return ApiResponse.success(Unit)
    }
}
