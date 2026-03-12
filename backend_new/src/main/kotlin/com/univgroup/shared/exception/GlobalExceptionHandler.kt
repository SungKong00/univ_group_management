package com.univgroup.shared.exception

import com.univgroup.shared.dto.ApiResponse
import com.univgroup.shared.dto.ErrorCode
import org.slf4j.LoggerFactory
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.MethodArgumentNotValidException
import org.springframework.web.bind.annotation.ExceptionHandler
import org.springframework.web.bind.annotation.RestControllerAdvice

/**
 * 전역 예외 처리기 (헌법 II. 표준 응답 형식)
 *
 * 모든 예외를 ApiResponse 형식으로 변환하여 일관된 응답을 제공한다.
 */
@RestControllerAdvice
class GlobalExceptionHandler {
    private val logger = LoggerFactory.getLogger(GlobalExceptionHandler::class.java)

    /**
     * 비즈니스 예외 처리
     */
    @ExceptionHandler(BusinessException::class)
    fun handleBusinessException(e: BusinessException): ResponseEntity<ApiResponse<Unit>> {
        logger.warn("Business exception: {} - {}", e.errorCode.code, e.message)
        return ResponseEntity
            .status(e.errorCode.httpStatus)
            .body(ApiResponse.error(e.errorCode, e.message))
    }

    /**
     * Spring 유효성 검증 예외 처리
     */
    @ExceptionHandler(MethodArgumentNotValidException::class)
    fun handleValidationException(e: MethodArgumentNotValidException): ResponseEntity<ApiResponse<Unit>> {
        val errors =
            e.bindingResult.fieldErrors
                .joinToString(", ") { "${it.field}: ${it.defaultMessage}" }
        logger.warn("Validation failed: {}", errors)
        return ResponseEntity
            .status(ErrorCode.COMMON_VALIDATION_FAILED.httpStatus)
            .body(ApiResponse.error(ErrorCode.COMMON_VALIDATION_FAILED, errors))
    }

    /**
     * IllegalArgumentException 처리
     */
    @ExceptionHandler(IllegalArgumentException::class)
    fun handleIllegalArgumentException(e: IllegalArgumentException): ResponseEntity<ApiResponse<Unit>> {
        logger.warn("Illegal argument: {}", e.message)
        return ResponseEntity
            .status(ErrorCode.COMMON_INVALID_REQUEST.httpStatus)
            .body(ApiResponse.error(ErrorCode.COMMON_INVALID_REQUEST, e.message ?: "잘못된 요청입니다"))
    }

    /**
     * Spring Security AccessDeniedException 처리
     */
    @ExceptionHandler(org.springframework.security.access.AccessDeniedException::class)
    fun handleSpringAccessDeniedException(
        e: org.springframework.security.access.AccessDeniedException,
    ): ResponseEntity<ApiResponse<Unit>> {
        logger.warn("Access denied: {}", e.message)
        return ResponseEntity
            .status(ErrorCode.PERMISSION_DENIED.httpStatus)
            .body(ApiResponse.error(ErrorCode.PERMISSION_DENIED))
    }

    /**
     * 일반 예외 처리 (예상치 못한 에러)
     */
    @ExceptionHandler(Exception::class)
    fun handleGenericException(e: Exception): ResponseEntity<ApiResponse<Unit>> {
        logger.error("Unexpected error occurred", e)
        return ResponseEntity
            .status(ErrorCode.COMMON_INTERNAL_ERROR.httpStatus)
            .body(ApiResponse.error(ErrorCode.COMMON_INTERNAL_ERROR))
    }
}
