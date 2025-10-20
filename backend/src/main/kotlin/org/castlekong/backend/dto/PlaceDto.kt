package org.castlekong.backend.dto

import com.fasterxml.jackson.annotation.JsonFormat
import jakarta.validation.constraints.Min
import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.NotNull
import jakarta.validation.constraints.Size
import org.castlekong.backend.entity.BlockType
import org.castlekong.backend.entity.UsageStatus
import java.time.DayOfWeek
import java.time.LocalDateTime
import java.time.LocalTime

// ===== Place DTOs =====

data class CreatePlaceRequest(
    @field:NotNull(message = "관리 그룹 ID는 필수입니다")
    val managingGroupId: Long,
    @field:NotBlank(message = "건물명은 필수입니다")
    @field:Size(max = 100, message = "건물명은 100자 이하여야 합니다")
    val building: String,
    @field:NotBlank(message = "방 번호는 필수입니다")
    @field:Size(max = 50, message = "방 번호는 50자 이하여야 합니다")
    val roomNumber: String,
    @field:Size(max = 100, message = "별칭은 100자 이하여야 합니다")
    val alias: String? = null,
    @field:Min(value = 1, message = "수용 인원은 1명 이상이어야 합니다")
    val capacity: Int? = null,
    val availabilities: List<AvailabilityRequest>? = null,
)

data class UpdatePlaceRequest(
    @field:Size(max = 100, message = "별칭은 100자 이하여야 합니다")
    val alias: String? = null,
    @field:Min(value = 1, message = "수용 인원은 1명 이상이어야 합니다")
    val capacity: Int? = null,
)

data class PlaceResponse(
    val id: Long,
    val managingGroupId: Long,
    val managingGroupName: String,
    val building: String,
    val roomNumber: String,
    val alias: String?,
    val displayName: String,
    val capacity: Int?,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime,
)

data class PlaceDetailResponse(
    val place: PlaceResponse,
    val availabilities: List<AvailabilityResponse>,
    val approvedGroupCount: Int,
)

// ===== Availability DTOs =====

data class AvailabilityRequest(
    @field:NotNull(message = "요일은 필수입니다")
    val dayOfWeek: DayOfWeek,
    @field:NotNull(message = "시작 시간은 필수입니다")
    @field:JsonFormat(pattern = "HH:mm:ss")
    val startTime: LocalTime,
    @field:NotNull(message = "종료 시간은 필수입니다")
    @field:JsonFormat(pattern = "HH:mm:ss")
    val endTime: LocalTime,
    val displayOrder: Int = 0,
)

data class AvailabilityResponse(
    val id: Long,
    val dayOfWeek: DayOfWeek,
    @field:JsonFormat(pattern = "HH:mm:ss")
    val startTime: LocalTime,
    @field:JsonFormat(pattern = "HH:mm:ss")
    val endTime: LocalTime,
    val displayOrder: Int,
)

// ===== BlockedTime DTOs =====

data class CreateBlockedTimeRequest(
    @field:NotNull(message = "차단 시작 시간은 필수입니다")
    val startDatetime: LocalDateTime,
    @field:NotNull(message = "차단 종료 시간은 필수입니다")
    val endDatetime: LocalDateTime,
    @field:NotNull(message = "차단 유형은 필수입니다")
    val blockType: BlockType,
    @field:Size(max = 200, message = "차단 사유는 200자 이하여야 합니다")
    val reason: String? = null,
)

data class BlockedTimeResponse(
    val id: Long,
    val placeId: Long,
    val placeName: String,
    val startDatetime: LocalDateTime,
    val endDatetime: LocalDateTime,
    val blockType: BlockType,
    val reason: String?,
    val createdBy: Long,
    val createdByName: String,
    val createdAt: LocalDateTime,
)

// ===== UsageGroup DTOs =====

/**
 * 사용 신청 요청 DTO
 */
data class RequestUsageRequest(
    @field:NotNull(message = "그룹 ID는 필수입니다")
    val groupId: Long,
    @field:Size(max = 500, message = "신청 사유는 500자 이내로 입력하세요")
    val reason: String? = null,
)

/**
 * 승인/거절 요청 DTO
 */
data class UpdateUsageStatusRequest(
    @field:NotNull(message = "승인 상태는 필수입니다")
    val status: UsageStatus,
    @field:Size(max = 500, message = "거절 사유는 500자 이내로 입력하세요")
    val rejectionReason: String? = null,
)

/**
 * 사용 그룹 응답 DTO
 */
data class UsageGroupResponse(
    val id: Long,
    val placeId: Long,
    val placeName: String,
    val groupId: Long,
    val groupName: String,
    val status: UsageStatus,
    val rejectionReason: String?,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime,
)

// ===== PlaceReservation DTOs =====

/**
 * 장소 예약 생성 요청 DTO
 */
data class CreatePlaceReservationRequest(
    @field:NotNull(message = "장소 ID는 필수입니다")
    val placeId: Long,
    @field:NotNull(message = "그룹 일정 ID는 필수입니다")
    val groupEventId: Long,
)

/**
 * 장소 예약 수정 요청 DTO (장소 변경)
 */
data class UpdatePlaceReservationRequest(
    // null이면 시간만 재검증
    val placeId: Long? = null,
)

/**
 * 장소 예약 응답 DTO
 */
data class PlaceReservationResponse(
    val id: Long,
    val placeId: Long,
    val placeName: String,
    val groupEventId: Long,
    val title: String,
    val startDateTime: LocalDateTime,
    val endDateTime: LocalDateTime,
    val description: String?,
    val reservedBy: Long,
    val reservedByName: String,
    val createdAt: LocalDateTime,
)

/**
 * 장소 캘린더 응답 DTO (다중 장소 조회용)
 */
data class PlaceCalendarResponse(
    val placeId: Long,
    val placeName: String,
    val reservations: List<PlaceReservationResponse>,
)

// ===== Calendar Place Integration DTOs (Phase 2) =====

/**
 * 다중 장소 예약 가능 정보 조회 요청 DTO
 */
data class MultiplePlaceAvailabilityRequest(
    @field:NotNull(message = "장소 ID 목록은 필수입니다")
    @field:Size(min = 1, message = "최소 1개 이상의 장소를 선택해야 합니다")
    val placeIds: List<Long>,
    @field:NotNull(message = "날짜는 필수입니다")
    @field:JsonFormat(pattern = "yyyy-MM-dd")
    val date: java.time.LocalDate,
)

/**
 * 특정 시간대 예약 가능 장소 조회 요청 DTO
 */
data class AvailablePlacesAtRequest(
    @field:NotNull(message = "장소 ID 목록은 필수입니다")
    @field:Size(min = 1, message = "최소 1개 이상의 장소를 선택해야 합니다")
    val placeIds: List<Long>,
    @field:NotNull(message = "시작 시간은 필수입니다")
    val startDateTime: LocalDateTime,
    @field:NotNull(message = "종료 시간은 필수입니다")
    val endDateTime: LocalDateTime,
)

/**
 * 장소별 예약 가능 정보 응답 DTO
 */
data class PlaceAvailabilityDto(
    val placeId: Long,
    @field:JsonFormat(pattern = "yyyy-MM-dd")
    val date: java.time.LocalDate,
    val operatingHours: List<OperatingHourDto>,
    val reservations: List<ReservationSimpleDto>,
)

/**
 * 운영 시간 DTO (간소화)
 */
data class OperatingHourDto(
    val dayOfWeek: DayOfWeek,
    @field:JsonFormat(pattern = "HH:mm:ss")
    val startTime: LocalTime,
    @field:JsonFormat(pattern = "HH:mm:ss")
    val endTime: LocalTime,
)

/**
 * 예약 정보 DTO (간소화)
 */
data class ReservationSimpleDto(
    val id: Long,
    val startDateTime: LocalDateTime,
    val endDateTime: LocalDateTime,
    val title: String,
)

/**
 * 예약 가능 장소 응답 DTO
 */
data class AvailablePlacesAtResponse(
    val availablePlaces: List<PlaceResponse>,
)
