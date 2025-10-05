package org.castlekong.backend.exception

import org.castlekong.backend.dto.ApiResponse
import org.slf4j.LoggerFactory
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.security.access.AccessDeniedException
import org.springframework.validation.FieldError
import org.springframework.web.bind.MethodArgumentNotValidException
import org.springframework.web.bind.annotation.ExceptionHandler
import org.springframework.web.bind.annotation.RestControllerAdvice
import org.springframework.web.HttpRequestMethodNotSupportedException

@RestControllerAdvice
class GlobalExceptionHandler {
    private val logger = LoggerFactory.getLogger(GlobalExceptionHandler::class.java)

    @ExceptionHandler(BusinessException::class)
    fun handleBusinessException(e: BusinessException): ResponseEntity<ApiResponse<Unit>> {
        logger.warn("Business exception occurred: {}", e.message)

        val status =
            when (e.errorCode) {
                ErrorCode.UNAUTHORIZED,
                ErrorCode.INVALID_TOKEN,
                ErrorCode.EXPIRED_TOKEN, -> HttpStatus.UNAUTHORIZED
                ErrorCode.FORBIDDEN,
                ErrorCode.SYSTEM_ROLE_IMMUTABLE -> HttpStatus.FORBIDDEN
                ErrorCode.USER_NOT_FOUND,
                ErrorCode.GROUP_NOT_FOUND,
                ErrorCode.GROUP_ROLE_NOT_FOUND,
                ErrorCode.GROUP_MEMBER_NOT_FOUND,
                ErrorCode.CHANNEL_NOT_FOUND,
                ErrorCode.POST_NOT_FOUND,
                ErrorCode.COMMENT_NOT_FOUND,
                ErrorCode.RECRUITMENT_NOT_FOUND,
                ErrorCode.APPLICATION_NOT_FOUND,
                ErrorCode.REQUEST_NOT_FOUND,
                -> HttpStatus.NOT_FOUND
                ErrorCode.USER_ALREADY_EXISTS,
                ErrorCode.GROUP_NAME_ALREADY_EXISTS,
                ErrorCode.GROUP_ROLE_NAME_ALREADY_EXISTS,
                ErrorCode.ALREADY_GROUP_MEMBER,
                ErrorCode.RECRUITMENT_ALREADY_EXISTS,
                ErrorCode.APPLICATION_ALREADY_EXISTS,
                ErrorCode.APPLICATION_ALREADY_REVIEWED,
                ErrorCode.APPLICATION_CANNOT_WITHDRAW,
                ErrorCode.REQUEST_ALREADY_EXISTS,
                -> HttpStatus.CONFLICT
                else -> HttpStatus.BAD_REQUEST
            }

        val response = ApiResponse.error<Unit>(e.errorCode.name, e.errorCode.message)
        return ResponseEntity.status(status).body(response)
    }

    @ExceptionHandler(AccessDeniedException::class)
    fun handleAccessDeniedException(e: AccessDeniedException): ResponseEntity<ApiResponse<Unit>> {
        logger.warn("Access denied: {}", e.message)
        val response = ApiResponse.error<Unit>("FORBIDDEN", "접근 권한이 없습니다.")
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(response)
    }

    @ExceptionHandler(MethodArgumentNotValidException::class)
    fun handleValidationException(e: MethodArgumentNotValidException): ResponseEntity<ApiResponse<Unit>> {
        logger.warn("Validation failed: {}", e.message)

        val errors =
            e.bindingResult.allErrors
                .filterIsInstance<FieldError>()
                .joinToString(", ") { "${it.field}: ${it.defaultMessage}" }

        val response = ApiResponse.error<Unit>("INVALID_REQUEST", "입력값이 유효하지 않습니다: $errors")
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response)
    }

    @ExceptionHandler(ValidationException::class)
    fun handleCustomValidationException(e: ValidationException): ResponseEntity<ApiResponse<Unit>> {
        logger.warn("Custom validation failed: {}", e.message)
        val response = ApiResponse.error<Unit>("VALIDATION_ERROR", e.message ?: "잘못된 요청")
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response)
    }

    @ExceptionHandler(IllegalArgumentException::class)
    fun handleIllegalArgumentException(e: IllegalArgumentException): ResponseEntity<ApiResponse<Unit>> {
        logger.warn("Illegal argument: {}", e.message)
        val response = ApiResponse.error<Unit>("INVALID_ARGUMENT", e.message ?: "잘못된 인수")
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response)
    }

    @ExceptionHandler(HttpRequestMethodNotSupportedException::class)
    fun handleMethodNotSupported(e: HttpRequestMethodNotSupportedException): ResponseEntity<ApiResponse<Unit>> {
        logger.warn("Method not allowed: {}", e.message)
        val response = ApiResponse.error<Unit>("METHOD_NOT_ALLOWED", "허용되지 않은 HTTP 메서드입니다.")
        return ResponseEntity.status(HttpStatus.METHOD_NOT_ALLOWED).body(response)
    }

    @ExceptionHandler(Exception::class)
    fun handleGenericException(e: Exception): ResponseEntity<ApiResponse<Unit>> {
        logger.error("Unexpected error occurred", e)
        val response = ApiResponse.error<Unit>("INTERNAL_SERVER_ERROR", "서버 내부 오류가 발생했습니다.")
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response)
    }
}
