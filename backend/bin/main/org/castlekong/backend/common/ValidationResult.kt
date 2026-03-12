package org.castlekong.backend.common

import org.castlekong.backend.exception.ErrorCode

/**
 * ValidationResult
 *
 * 검증 결과를 담는 유틸리티 클래스
 * - 성공/실패 여부
 * - 실패 시 ErrorCode 및 메시지
 *
 * 사용 예시:
 * ```kotlin
 * val result = validateReservation(...)
 * if (!result.isSuccess) {
 *     throw BusinessException(result.errorCode!!, result.message)
 * }
 * ```
 */
data class ValidationResult(
    val isSuccess: Boolean,
    val errorCode: ErrorCode? = null,
    val message: String? = null,
) {
    companion object {
        /**
         * 검증 성공 결과 생성
         */
        fun success(): ValidationResult = ValidationResult(isSuccess = true)

        /**
         * 검증 실패 결과 생성
         *
         * @param errorCode 에러 코드
         * @param message 추가 메시지 (선택)
         */
        fun failure(
            errorCode: ErrorCode,
            message: String? = null,
        ): ValidationResult =
            ValidationResult(
                isSuccess = false,
                errorCode = errorCode,
                message = message,
            )
    }
}
