package org.castlekong.backend.dto

import java.time.LocalDateTime

data class ApiResponse<T>(
    val success: Boolean,
    val data: T? = null,
    val error: ErrorInfo? = null,
    val message: String,
    val timestamp: LocalDateTime = LocalDateTime.now(),
) {
    companion object {
        fun <T> success(
            data: T,
            message: String = "요청이 성공적으로 처리되었습니다.",
        ): ApiResponse<T> {
            return ApiResponse(
                success = true,
                data = data,
                message = message,
            )
        }

        fun <T> error(
            code: String,
            message: String,
            details: String? = null,
            path: String? = null,
        ): ApiResponse<T> {
            return ApiResponse(
                success = false,
                error = ErrorInfo(code, message, details, path),
                message = message,
            )
        }
    }
}

data class ErrorInfo(
    val code: String,
    val message: String,
    val details: String? = null,
    val path: String? = null,
)
