package com.univgroup.shared.exception

import com.univgroup.shared.dto.ErrorCode

/**
 * 비즈니스 로직 예외
 *
 * 모든 비즈니스 예외는 이 클래스를 상속받거나 직접 사용한다.
 * GlobalExceptionHandler에서 ApiResponse 형식으로 변환된다.
 */
open class BusinessException(
    val errorCode: ErrorCode,
    override val message: String = errorCode.message,
    override val cause: Throwable? = null,
) : RuntimeException(message, cause)

/**
 * 리소스를 찾을 수 없을 때 발생하는 예외
 */
class ResourceNotFoundException(
    errorCode: ErrorCode = ErrorCode.COMMON_RESOURCE_NOT_FOUND,
    message: String = errorCode.message,
) : BusinessException(errorCode, message)

/**
 * 권한 거부 예외
 */
class AccessDeniedException(
    errorCode: ErrorCode = ErrorCode.PERMISSION_DENIED,
    message: String = errorCode.message,
) : BusinessException(errorCode, message)

/**
 * 유효성 검증 실패 예외
 */
class ValidationException(
    errorCode: ErrorCode = ErrorCode.COMMON_VALIDATION_FAILED,
    message: String = errorCode.message,
) : BusinessException(errorCode, message)

/**
 * 중복 리소스 예외
 */
class DuplicateResourceException(
    errorCode: ErrorCode,
    message: String = errorCode.message,
) : BusinessException(errorCode, message)

/**
 * 인증 실패 예외
 */
class AuthenticationException(
    errorCode: ErrorCode = ErrorCode.AUTH_UNAUTHORIZED,
    message: String = errorCode.message,
) : BusinessException(errorCode, message)

/**
 * 리소스 충돌 예외 (중복, 동시 수정 등)
 */
class ConflictException(
    errorCode: ErrorCode,
    message: String = errorCode.message,
) : BusinessException(errorCode, message)
