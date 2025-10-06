package org.castlekong.backend.controller

import jakarta.validation.Valid
import org.castlekong.backend.dto.*
import org.castlekong.backend.service.RecruitmentService
import org.castlekong.backend.service.UserService
import org.springframework.data.domain.Pageable
import org.springframework.http.HttpStatus
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.security.core.Authentication
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api")
class RecruitmentController(
    private val recruitmentService: RecruitmentService,
    userService: UserService,
) : BaseController(userService) {
    // 모집 게시글 관련 엔드포인트

    @PostMapping("/groups/{groupId}/recruitments")
    @PreAuthorize("hasPermission(#groupId, 'GROUP', 'RECRUITMENT_MANAGE')")
    @ResponseStatus(HttpStatus.CREATED)
    fun createRecruitment(
        @PathVariable groupId: Long,
        @Valid @RequestBody request: CreateRecruitmentRequest,
        authentication: Authentication,
    ): ApiResponse<RecruitmentResponse> {
        val user = getCurrentUser(authentication)
        val response = recruitmentService.createRecruitment(groupId, request, user.id)
        return ApiResponse.success(response)
    }

    @GetMapping("/groups/{groupId}/recruitments")
    fun getActiveRecruitment(
        @PathVariable groupId: Long,
    ): ApiResponse<RecruitmentResponse?> {
        val response = recruitmentService.getActiveRecruitment(groupId)
        return ApiResponse.success(response)
    }

    @PutMapping("/recruitments/{recruitmentId}")
    @PreAuthorize("hasPermission(#recruitmentId, 'RECRUITMENT', 'RECRUITMENT_MANAGE')")
    fun updateRecruitment(
        @PathVariable recruitmentId: Long,
        @Valid @RequestBody request: UpdateRecruitmentRequest,
        authentication: Authentication,
    ): ApiResponse<RecruitmentResponse> {
        val user = getCurrentUser(authentication)
        val response = recruitmentService.updateRecruitment(recruitmentId, request, user.id)
        return ApiResponse.success(response)
    }

    @PatchMapping("/recruitments/{recruitmentId}/close")
    @PreAuthorize("hasPermission(#recruitmentId, 'RECRUITMENT', 'RECRUITMENT_MANAGE')")
    fun closeRecruitment(
        @PathVariable recruitmentId: Long,
        authentication: Authentication,
    ): ApiResponse<RecruitmentResponse> {
        val user = getCurrentUser(authentication)
        val response = recruitmentService.closeRecruitment(recruitmentId, user.id)
        return ApiResponse.success(response)
    }

    @DeleteMapping("/recruitments/{recruitmentId}")
    @PreAuthorize("hasPermission(#recruitmentId, 'RECRUITMENT', 'RECRUITMENT_MANAGE')")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    fun deleteRecruitment(
        @PathVariable recruitmentId: Long,
        authentication: Authentication,
    ) {
        val user = getCurrentUser(authentication)
        recruitmentService.deleteRecruitment(recruitmentId, user.id)
    }

    @GetMapping("/groups/{groupId}/recruitments/archive")
    @PreAuthorize("hasPermission(#groupId, 'GROUP', 'RECRUITMENT_MANAGE')")
    fun getArchivedRecruitments(
        @PathVariable groupId: Long,
        pageable: Pageable,
    ): PagedApiResponse<ArchivedRecruitmentResponse> {
        val response = recruitmentService.getArchivedRecruitments(groupId, pageable)
        val pagination = PaginationInfo.fromSpringPage(response)
        return PagedApiResponse.success(response.content, pagination)
    }

    @GetMapping("/recruitments/public")
    fun searchPublicRecruitments(
        @RequestParam(required = false) keyword: String?,
        @RequestParam(defaultValue = "0") page: Int,
        @RequestParam(defaultValue = "20") size: Int,
    ): PagedApiResponse<RecruitmentSummaryResponse> {
        val request = RecruitmentSearchRequest(keyword, page, size)
        val response = recruitmentService.searchPublicRecruitments(request)
        val pagination = PaginationInfo.fromSpringPage(response)
        return PagedApiResponse.success(response.content, pagination)
    }

    // 지원서 관련 엔드포인트

    @PostMapping("/recruitments/{recruitmentId}/applications")
    @PreAuthorize("isAuthenticated()")
    @ResponseStatus(HttpStatus.CREATED)
    fun submitApplication(
        @PathVariable recruitmentId: Long,
        @Valid @RequestBody request: CreateApplicationRequest,
        authentication: Authentication,
    ): ApiResponse<ApplicationResponse> {
        val user = getCurrentUser(authentication)
        val response = recruitmentService.submitApplication(recruitmentId, request, user.id)
        return ApiResponse.success(response)
    }

    @GetMapping("/recruitments/{recruitmentId}/applications")
    @PreAuthorize("hasPermission(#recruitmentId, 'RECRUITMENT', 'RECRUITMENT_MANAGE')")
    fun getApplicationsByRecruitment(
        @PathVariable recruitmentId: Long,
        pageable: Pageable,
    ): PagedApiResponse<ApplicationSummaryResponse> {
        val response = recruitmentService.getApplicationsByRecruitment(recruitmentId, pageable)
        val pagination = PaginationInfo.fromSpringPage(response)
        return PagedApiResponse.success(response.content, pagination)
    }

    @GetMapping("/applications/{applicationId}")
    @PreAuthorize(
        "hasPermission(#applicationId, 'APPLICATION', 'VIEW') or @recruitmentController.isApplicationOwner(#applicationId, authentication)",
    )
    fun getApplication(
        @PathVariable applicationId: Long,
        authentication: Authentication,
    ): ApiResponse<ApplicationResponse> {
        val response = recruitmentService.getApplication(applicationId)
        return ApiResponse.success(response)
    }

    @PatchMapping("/applications/{applicationId}/review")
    @PreAuthorize("hasPermission(#applicationId, 'APPLICATION', 'RECRUITMENT_MANAGE')")
    fun reviewApplication(
        @PathVariable applicationId: Long,
        @Valid @RequestBody request: ReviewApplicationRequest,
        authentication: Authentication,
    ): ApiResponse<ApplicationResponse> {
        val user = getCurrentUser(authentication)
        val response = recruitmentService.reviewApplication(applicationId, request, user.id)
        return ApiResponse.success(response)
    }

    @DeleteMapping("/applications/{applicationId}")
    @PreAuthorize("@recruitmentController.isApplicationOwner(#applicationId, authentication)")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    fun withdrawApplication(
        @PathVariable applicationId: Long,
        authentication: Authentication,
    ) {
        val user = getCurrentUser(authentication)
        recruitmentService.withdrawApplication(applicationId, user.id)
    }

    @GetMapping("/recruitments/{recruitmentId}/stats")
    @PreAuthorize("hasPermission(#recruitmentId, 'RECRUITMENT', 'RECRUITMENT_MANAGE')")
    fun getRecruitmentStats(
        @PathVariable recruitmentId: Long,
    ): ApiResponse<RecruitmentStatsResponse> {
        val response = recruitmentService.getRecruitmentStats(recruitmentId)
        return ApiResponse.success(response)
    }

    // 헬퍼 메서드 (Security Expression에서 사용)

    fun isApplicationOwner(
        applicationId: Long,
        authentication: Authentication,
    ): Boolean {
        return try {
            val user = getCurrentUser(authentication)
            val application = recruitmentService.getApplication(applicationId)
            application.applicant.id == user.id
        } catch (e: Exception) {
            false
        }
    }
}
