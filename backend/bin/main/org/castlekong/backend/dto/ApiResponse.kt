package org.castlekong.backend.dto

import java.time.LocalDateTime

data class ApiResponse<T>(
    val success: Boolean,
    val data: T? = null,
    val error: ErrorResponse? = null,
    val timestamp: LocalDateTime = LocalDateTime.now(),
) {
    companion object {
        fun <T> success(data: T): ApiResponse<T> = ApiResponse(success = true, data = data)

        fun success(): ApiResponse<Unit> = ApiResponse(success = true)

        fun <T> error(
            code: String,
            message: String,
        ): ApiResponse<T> = ApiResponse(success = false, error = ErrorResponse(code, message))
    }
}

data class ErrorResponse(
    val code: String,
    val message: String,
)
