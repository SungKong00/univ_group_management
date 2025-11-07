package org.castlekong.backend.dto

import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.NotNull
import jakarta.validation.constraints.Size
import org.castlekong.backend.entity.EventType
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime

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
    // ===== 장소 통합 (3가지 모드) =====
    // Mode B: 수동 입력 장소
    val locationText: String?,
    // Mode C: 중첩 객체로 반환 (테스트 호환성)
    val place: PlaceInfo?,
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
 * 장소 정보 DTO (Mode C)
 */
data class PlaceInfo(
    val id: Long,
    val building: String,
    val roomNumber: String,
    val alias: String?,
    val capacity: Int?,
    val managingGroupName: String,
)

/**
 * 그룹 일정 생성 요청 DTO
 *
 * Date/Time 분리 모델:
 * - startDate, endDate: 반복 일정의 시작/종료 날짜 (반복 기간)
 * - startTime, endTime: 개별 일정의 시작/종료 시간 (이벤트 duration)
 * - 단일 일정의 경우: startDate + startTime, startDate + endTime 결합
 *
 * 장소 통합 (3가지 모드):
 * - Mode A: locationText=null, placeId=null (장소 없음)
 * - Mode B: locationText="텍스트", placeId=null (수동 입력)
 * - Mode C: locationText=null, placeId=1 (장소 선택 + 자동 예약)
 * - 검증: locationText와 placeId는 동시에 값을 가질 수 없음
 */
data class CreateGroupEventRequest(
    @field:NotBlank(message = "제목은 필수입니다.")
    @field:Size(max = 200, message = "제목은 최대 200자까지 입력할 수 있습니다.")
    val title: String,
    @field:Size(max = 2000, message = "설명은 최대 2000자까지 입력할 수 있습니다.")
    val description: String? = null,
    // ===== 장소 통합 필드 =====
    // Mode B: 수동 입력
    @field:Size(max = 100, message = "장소는 최대 100자까지 입력할 수 있습니다.")
    val locationText: String? = null,
    // Mode C: 장소 선택
    val placeId: Long? = null,
    @field:NotNull(message = "시작 날짜는 필수입니다.")
    val startDate: LocalDate?,
    @field:NotNull(message = "종료 날짜는 필수입니다.")
    val endDate: LocalDate?,
    @field:NotNull(message = "시작 시간은 필수입니다.")
    val startTime: LocalTime?,
    @field:NotNull(message = "종료 시간은 필수입니다.")
    val endTime: LocalTime?,
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
 *
 * 장소 변경 지원:
 * - Mode A → Mode B/C: locationText 또는 placeId 설정
 * - Mode B → Mode A/C: locationText null 또는 placeId 설정
 * - Mode C → Mode A/B: placeId null 또는 locationText 설정
 * - 검증: locationText와 placeId는 동시에 값을 가질 수 없음
 */
data class UpdateGroupEventRequest(
    @field:NotBlank(message = "제목은 필수입니다.")
    @field:Size(max = 200, message = "제목은 최대 200자까지 입력할 수 있습니다.")
    val title: String,
    @field:Size(max = 2000, message = "설명은 최대 2000자까지 입력할 수 있습니다.")
    val description: String? = null,
    // ===== 장소 통합 필드 =====
    // Mode B: 수동 입력
    @field:Size(max = 100, message = "장소는 최대 100자까지 입력할 수 있습니다.")
    val locationText: String? = null,
    // Mode C: 장소 선택
    val placeId: Long? = null,
    @field:NotNull(message = "시작 시간은 필수입니다.")
    val startTime: LocalTime?,
    @field:NotNull(message = "종료 시간은 필수입니다.")
    val endTime: LocalTime?,
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
    // WEEKLY인 경우 필수
    val daysOfWeek: List<DayOfWeek>? = null,
)

/**
 * 반복 유형
 */
enum class RecurrenceType {
    DAILY,
    WEEKLY,
}

/**
 * 수정/삭제 범위
 */
enum class UpdateScope {
    THIS_EVENT,
    ALL_EVENTS,
}
