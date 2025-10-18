package org.castlekong.backend.dto

import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.NotNull
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.LocalTime

// ========================================
// 운영시간 (PlaceOperatingHours) DTO
// ========================================

/**
 * 운영시간 응답 DTO
 */
data class OperatingHoursResponse(
    val id: Long,
    val dayOfWeek: DayOfWeek,
    val startTime: LocalTime,
    val endTime: LocalTime,
    val isClosed: Boolean,
)

/**
 * 운영시간 설정 요청 DTO (전체 교체)
 */
data class SetOperatingHoursRequest(
    @field:NotNull(message = "운영시간 정보는 필수입니다")
    val operatingHours: List<OperatingHoursItem>,
)

/**
 * 운영시간 항목 DTO
 */
data class OperatingHoursItem(
    @field:NotNull(message = "요일은 필수입니다")
    val dayOfWeek: DayOfWeek,
    @field:NotNull(message = "시작 시간은 필수입니다")
    val startTime: LocalTime,
    @field:NotNull(message = "종료 시간은 필수입니다")
    val endTime: LocalTime,
    val isClosed: Boolean = false,
)

/**
 * 특정 요일 운영시간 수정 요청 DTO
 */
data class UpdateOperatingHoursRequest(
    @field:NotNull(message = "시작 시간은 필수입니다")
    val startTime: LocalTime,
    @field:NotNull(message = "종료 시간은 필수입니다")
    val endTime: LocalTime,
    val isClosed: Boolean = false,
)

// ========================================
// 금지시간 (PlaceRestrictedTime) DTO
// ========================================

/**
 * 금지시간 응답 DTO
 */
data class RestrictedTimeResponse(
    val id: Long,
    val dayOfWeek: DayOfWeek,
    val startTime: LocalTime,
    val endTime: LocalTime,
    val reason: String?,
    val displayOrder: Int,
)

/**
 * 금지시간 추가 요청 DTO
 */
data class AddRestrictedTimeRequest(
    @field:NotNull(message = "요일은 필수입니다")
    val dayOfWeek: DayOfWeek,
    @field:NotNull(message = "시작 시간은 필수입니다")
    val startTime: LocalTime,
    @field:NotNull(message = "종료 시간은 필수입니다")
    val endTime: LocalTime,
    val reason: String? = null,
)

/**
 * 금지시간 수정 요청 DTO
 */
data class UpdateRestrictedTimeRequest(
    @field:NotNull(message = "시작 시간은 필수입니다")
    val startTime: LocalTime,
    @field:NotNull(message = "종료 시간은 필수입니다")
    val endTime: LocalTime,
    val reason: String? = null,
)

// ========================================
// 임시 휴무 (PlaceClosure) DTO
// ========================================

/**
 * 임시 휴무 응답 DTO
 */
data class PlaceClosureResponse(
    val id: Long,
    val closureDate: LocalDate,
    val isFullDay: Boolean,
    val startTime: LocalTime?,
    val endTime: LocalTime?,
    val reason: String?,
)

/**
 * 임시 휴무 추가 요청 DTO (전일 휴무)
 */
data class AddFullDayClosureRequest(
    @field:NotNull(message = "휴무 날짜는 필수입니다")
    val closureDate: LocalDate,
    val reason: String? = null,
)

/**
 * 임시 휴무 추가 요청 DTO (부분 시간 휴무)
 */
data class AddPartialClosureRequest(
    @field:NotNull(message = "휴무 날짜는 필수입니다")
    val closureDate: LocalDate,
    @field:NotNull(message = "시작 시간은 필수입니다")
    val startTime: LocalTime,
    @field:NotNull(message = "종료 시간은 필수입니다")
    val endTime: LocalTime,
    val reason: String? = null,
)

// ========================================
// 예약 가능 시간 조회 응답 DTO
// ========================================

/**
 * 예약 가능 시간 조회 응답 DTO
 */
data class AvailableTimesResponse(
    val date: LocalDate,
    val dayOfWeek: DayOfWeek,
    val isClosed: Boolean,
    val operatingHours: OperatingHoursInfo?,
    val restrictedTimes: List<RestrictedTimeInfo>,
    val closures: List<ClosureInfo>,
    val existingReservations: List<ReservationInfo>,
    val availableSlots: List<TimeSlotInfo>,
)

/**
 * 운영시간 정보 (간략)
 */
data class OperatingHoursInfo(
    val startTime: LocalTime,
    val endTime: LocalTime,
)

/**
 * 금지시간 정보 (간략)
 */
data class RestrictedTimeInfo(
    val startTime: LocalTime,
    val endTime: LocalTime,
    val reason: String?,
)

/**
 * 휴무 정보 (간략)
 */
data class ClosureInfo(
    val isFullDay: Boolean,
    val startTime: LocalTime?,
    val endTime: LocalTime?,
    val reason: String?,
)

/**
 * 기존 예약 정보 (간략)
 */
data class ReservationInfo(
    val startTime: LocalTime,
    val endTime: LocalTime,
    val groupName: String,
)

/**
 * 예약 가능 시간 슬롯
 */
data class TimeSlotInfo(
    val startTime: LocalTime,
    val endTime: LocalTime,
)
