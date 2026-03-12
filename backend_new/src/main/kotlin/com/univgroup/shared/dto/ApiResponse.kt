package com.univgroup.shared.dto

import com.fasterxml.jackson.annotation.JsonInclude
import java.time.Instant

/**
 * 표준 API 응답 형식 (헌법 II. 표준 응답 형식)
 *
 * 모든 REST API는 이 형식으로 응답한다.
 * - 성공: { "success": true, "data": T, "error": null, "timestamp": "..." }
 * - 실패: { "success": false, "data": null, "error": { "code": "...", "message": "..." }, "timestamp": "..." }
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
data class ApiResponse<T>(
    val success: Boolean,
    val data: T? = null,
    val error: ErrorResponse? = null,
    val timestamp: Instant = Instant.now(),
) {
    companion object {
        fun <T> success(data: T): ApiResponse<T> =
            ApiResponse(
                success = true,
                data = data,
                error = null,
            )

        fun <T> success(): ApiResponse<T> =
            ApiResponse(
                success = true,
                data = null,
                error = null,
            )

        fun <T> error(
            code: String,
            message: String,
        ): ApiResponse<T> =
            ApiResponse(
                success = false,
                data = null,
                error = ErrorResponse(code, message),
            )

        fun <T> error(errorCode: ErrorCode): ApiResponse<T> =
            ApiResponse(
                success = false,
                data = null,
                error = ErrorResponse(errorCode.code, errorCode.message),
            )

        fun <T> error(
            errorCode: ErrorCode,
            message: String,
        ): ApiResponse<T> =
            ApiResponse(
                success = false,
                data = null,
                error = ErrorResponse(errorCode.code, message),
            )
    }
}

/**
 * 에러 응답 상세 정보
 */
data class ErrorResponse(
    val code: String,
    val message: String,
)

/**
 * 페이징된 API 응답 형식
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
data class PagedApiResponse<T>(
    val success: Boolean,
    val data: List<T>? = null,
    val pagination: PaginationInfo? = null,
    val error: ErrorResponse? = null,
    val timestamp: Instant = Instant.now(),
) {
    companion object {
        fun <T> success(
            data: List<T>,
            page: Int,
            size: Int,
            totalElements: Long,
            totalPages: Int,
        ): PagedApiResponse<T> =
            PagedApiResponse(
                success = true,
                data = data,
                pagination =
                    PaginationInfo(
                        page = page,
                        size = size,
                        totalElements = totalElements,
                        totalPages = totalPages,
                        hasNext = page < totalPages - 1,
                        hasPrevious = page > 0,
                    ),
                error = null,
            )

        fun <T> error(
            code: String,
            message: String,
        ): PagedApiResponse<T> =
            PagedApiResponse(
                success = false,
                data = null,
                pagination = null,
                error = ErrorResponse(code, message),
            )
    }
}

/**
 * 페이징 정보
 */
data class PaginationInfo(
    val page: Int,
    val size: Int,
    val totalElements: Long,
    val totalPages: Int,
    val hasNext: Boolean,
    val hasPrevious: Boolean,
)
