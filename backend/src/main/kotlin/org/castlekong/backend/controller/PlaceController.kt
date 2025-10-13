package org.castlekong.backend.controller

import jakarta.validation.Valid
import org.castlekong.backend.dto.ApiResponse
import org.castlekong.backend.dto.AvailabilityRequest
import org.castlekong.backend.dto.CreatePlaceRequest
import org.castlekong.backend.dto.PlaceDetailResponse
import org.castlekong.backend.dto.PlaceResponse
import org.castlekong.backend.dto.UpdatePlaceRequest
import org.castlekong.backend.service.PlaceService
import org.castlekong.backend.service.UserService
import org.springframework.http.HttpStatus
import org.springframework.security.core.Authentication
import org.springframework.web.bind.annotation.DeleteMapping
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PatchMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.ResponseStatus
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/api/places")
class PlaceController(
    private val placeService: PlaceService,
    private val userService: UserService,
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
    @PostMapping
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
    @PatchMapping("/{id}")
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
    @DeleteMapping("/{id}")
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
    @PostMapping("/{id}/availabilities")
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
}
