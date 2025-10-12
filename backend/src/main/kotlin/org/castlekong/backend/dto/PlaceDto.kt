package org.castlekong.backend.dto

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

    val availabilities: List<AvailabilityRequest>? = null
)

data class UpdatePlaceRequest(
    @field:Size(max = 100, message = "별칭은 100자 이하여야 합니다")
    val alias: String? = null,

    @field:Min(value = 1, message = "수용 인원은 1명 이상이어야 합니다")
    val capacity: Int? = null
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
    val updatedAt: LocalDateTime
)

data class PlaceDetailResponse(
    val place: PlaceResponse,
    val availabilities: List<AvailabilityResponse>,
    val approvedGroupCount: Int
)

// ===== Availability DTOs =====

data class AvailabilityRequest(
    @field:NotNull(message = "요일은 필수입니다")
    val dayOfWeek: DayOfWeek,

    @field:NotNull(message = "시작 시간은 필수입니다")
    val startTime: LocalTime,

    @field:NotNull(message = "종료 시간은 필수입니다")
    val endTime: LocalTime,

    val displayOrder: Int = 0
)

data class AvailabilityResponse(
    val id: Long,
    val dayOfWeek: DayOfWeek,
    val startTime: LocalTime,
    val endTime: LocalTime,
    val displayOrder: Int
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
    val reason: String? = null
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
    val createdAt: LocalDateTime
)

// ===== UsageGroup DTOs =====

data class RequestUsageRequest(
    @field:NotNull(message = "그룹 ID는 필수입니다")
    val groupId: Long
)

data class UpdateUsageStatusRequest(
    @field:NotNull(message = "승인 상태는 필수입니다")
    val status: UsageStatus
)

data class UsageGroupResponse(
    val id: Long,
    val placeId: Long,
    val placeName: String,
    val groupId: Long,
    val groupName: String,
    val status: UsageStatus,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime
)
