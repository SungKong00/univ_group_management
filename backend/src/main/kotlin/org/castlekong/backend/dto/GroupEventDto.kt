package org.castlekong.backend.dto

import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.NotNull
import jakarta.validation.constraints.Size
import org.castlekong.backend.entity.EventType
import java.time.DayOfWeek
import java.time.LocalDateTime

/**
 * 그룹 일정 응답 DTO
 */
data class GroupEventResponse(
    val id: Long,
    val groupId: Long,
    val groupName: String,
    val creatorId: Long,
    val creatorName: String,
    val title: String,
    val description: String?,
    val location: String?,
    val startDate: LocalDateTime,
    val endDate: LocalDateTime,
    val isAllDay: Boolean,
    val isOfficial: Boolean,
    val eventType: EventType,
    val seriesId: String?,
    val recurrenceRule: String?,
    val color: String,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime,
)

/**
 * 그룹 일정 생성 요청 DTO
 */
data class CreateGroupEventRequest(
    @field:NotBlank(message = "제목은 필수입니다.")
    @field:Size(max = 200, message = "제목은 최대 200자까지 입력할 수 있습니다.")
    val title: String,

    @field:Size(max = 2000, message = "설명은 최대 2000자까지 입력할 수 있습니다.")
    val description: String? = null,

    @field:Size(max = 100, message = "장소는 최대 100자까지 입력할 수 있습니다.")
    val location: String? = null,

    @field:NotNull(message = "시작 일시는 필수입니다.")
    val startDate: LocalDateTime?,

    @field:NotNull(message = "종료 일시는 필수입니다.")
    val endDate: LocalDateTime?,

    val isAllDay: Boolean = false,

    val isOfficial: Boolean = false,

    val eventType: EventType = EventType.GENERAL,

    @field:NotBlank(message = "색상은 필수입니다.")
    @field:Size(min = 7, max = 7, message = "색상 코드는 #과 6자리 HEX 형식이어야 합니다.")
    val color: String,

    // 반복 일정 관련 필드
    val recurrence: RecurrencePattern? = null,
)

/**
 * 그룹 일정 수정 요청 DTO
 */
data class UpdateGroupEventRequest(
    @field:NotBlank(message = "제목은 필수입니다.")
    @field:Size(max = 200, message = "제목은 최대 200자까지 입력할 수 있습니다.")
    val title: String,

    @field:Size(max = 2000, message = "설명은 최대 2000자까지 입력할 수 있습니다.")
    val description: String? = null,

    @field:Size(max = 100, message = "장소는 최대 100자까지 입력할 수 있습니다.")
    val location: String? = null,

    @field:NotNull(message = "시작 일시는 필수입니다.")
    val startDate: LocalDateTime?,

    @field:NotNull(message = "종료 일시는 필수입니다.")
    val endDate: LocalDateTime?,

    val isAllDay: Boolean = false,

    @field:NotBlank(message = "색상은 필수입니다.")
    @field:Size(min = 7, max = 7, message = "색상 코드는 #과 6자리 HEX 형식이어야 합니다.")
    val color: String,

    // 반복 일정 수정 범위
    val updateScope: UpdateScope = UpdateScope.THIS_EVENT,
)

/**
 * 반복 패턴 DTO
 * JSON으로 변환되어 recurrenceRule 필드에 저장됨
 */
data class RecurrencePattern(
    val type: RecurrenceType,
    val daysOfWeek: List<DayOfWeek>? = null, // WEEKLY인 경우 필수
)

/**
 * 반복 유형
 */
enum class RecurrenceType {
    DAILY,   // 매일
    WEEKLY,  // 요일 선택 (예: 월, 수, 금)
}

/**
 * 수정/삭제 범위
 */
enum class UpdateScope {
    THIS_EVENT,    // 이 일정만
    ALL_EVENTS,    // 반복 전체
}
