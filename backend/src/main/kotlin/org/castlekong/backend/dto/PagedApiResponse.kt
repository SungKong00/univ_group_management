package org.castlekong.backend.dto

import java.time.LocalDateTime

/**
 * 페이징 처리된 API 응답을 위한 표준화된 응답 클래스
 */
data class PagedApiResponse<T>(
    val success: Boolean,
    val data: List<T>,
    val pagination: PaginationInfo,
    val error: ErrorResponse? = null,
    val timestamp: LocalDateTime = LocalDateTime.now()
) {
    companion object {
        fun <T> success(data: List<T>, pagination: PaginationInfo): PagedApiResponse<T> =
            PagedApiResponse(success = true, data = data, pagination = pagination)

        fun <T> error(code: String, message: String): PagedApiResponse<T> =
            PagedApiResponse(
                success = false,
                data = emptyList(),
                pagination = PaginationInfo.empty(),
                error = ErrorResponse(code, message)
            )
    }
}

/**
 * 페이징 정보를 담는 표준화된 클래스
 */
data class PaginationInfo(
    val page: Int,
    val size: Int,
    val totalElements: Long,
    val totalPages: Int,
    val first: Boolean,
    val last: Boolean,
    val hasNext: Boolean,
    val hasPrevious: Boolean
) {
    companion object {
        fun empty(): PaginationInfo = PaginationInfo(
            page = 0,
            size = 0,
            totalElements = 0,
            totalPages = 0,
            first = true,
            last = true,
            hasNext = false,
            hasPrevious = false
        )

        fun fromSpringPage(page: org.springframework.data.domain.Page<*>): PaginationInfo =
            PaginationInfo(
                page = page.number,
                size = page.size,
                totalElements = page.totalElements,
                totalPages = page.totalPages,
                first = page.isFirst,
                last = page.isLast,
                hasNext = page.hasNext(),
                hasPrevious = page.hasPrevious()
            )
    }
}