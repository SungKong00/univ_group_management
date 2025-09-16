package org.castlekong.backend.controller

import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.tags.Tag
import org.castlekong.backend.dto.ApiResponse
import org.castlekong.backend.service.UserService
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.security.core.Authentication
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

data class RoleApplyRequest(val role: String)

@RestController
@RequestMapping("/api/roles")
@Tag(name = "Roles", description = "역할 신청/변경 API")
class RoleController(
    private val userService: UserService,
) {
    @PostMapping("/apply")
    @PreAuthorize("isAuthenticated()")
    @Operation(summary = "역할 신청", description = "role=PROFESSOR일 때 승인 대기 상태를 생성합니다")
    fun applyRole(
        authentication: Authentication,
        @RequestBody req: RoleApplyRequest,
    ): ResponseEntity<ApiResponse<Unit>> {
        return try {
            val user =
                userService.findByEmail(authentication.name)
                    ?: return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(ApiResponse.error(code = "USER_NOT_FOUND", message = "사용자를 찾을 수 없습니다."))
            userService.applyRole(user.id, req.role)
            ResponseEntity.ok(ApiResponse.success())
        } catch (e: IllegalArgumentException) {
            ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResponse.error(code = "VALIDATION_ERROR", message = e.message ?: "잘못된 요청"))
        } catch (e: Exception) {
            ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.error(code = "INTERNAL_SERVER_ERROR", message = "서버 내부 오류"))
        }
    }
}
