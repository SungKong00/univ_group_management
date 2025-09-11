package org.castlekong.backend.exception

/**
 * 요청 데이터 유효성 검증 실패 시 발생하는 예외
 * HTTP 400 Bad Request 응답을 위해 사용됩니다.
 */
class ValidationException(message: String) : RuntimeException(message)