package org.castlekong.backend.dto

import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.NotNull
import jakarta.validation.constraints.Size
import java.time.LocalDateTime

data class PersonalEventResponse(
    val id: Long,
    val title: String,
    val description: String?,
    val location: String?,
    val startDateTime: LocalDateTime,
    val endDateTime: LocalDateTime,
    val isAllDay: Boolean,
    val color: String,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime,
)

data class CreatePersonalEventRequest(
    @field:NotBlank(message = "제목은 필수입니다.")
    @field:Size(max = 200, message = "제목은 최대 200자까지 입력할 수 있습니다.")
    val title: String,
    @field:Size(max = 2000, message = "설명은 최대 2000자까지 입력할 수 있습니다.")
    val description: String? = null,
    @field:Size(max = 100, message = "장소는 최대 100자까지 입력할 수 있습니다.")
    val location: String? = null,
    @field:NotNull(message = "시작 일시는 필수입니다.")
    val startDateTime: LocalDateTime?,
    @field:NotNull(message = "종료 일시는 필수입니다.")
    val endDateTime: LocalDateTime?,
    val isAllDay: Boolean = false,
    @field:NotBlank(message = "색상은 필수입니다.")
    @field:Size(min = 7, max = 7, message = "색상 코드는 #과 6자리 HEX 형식이어야 합니다.")
    val color: String,
)

data class UpdatePersonalEventRequest(
    @field:NotBlank(message = "제목은 필수입니다.")
    @field:Size(max = 200, message = "제목은 최대 200자까지 입력할 수 있습니다.")
    val title: String,
    @field:Size(max = 2000, message = "설명은 최대 2000자까지 입력할 수 있습니다.")
    val description: String? = null,
    @field:Size(max = 100, message = "장소는 최대 100자까지 입력할 수 있습니다.")
    val location: String? = null,
    @field:NotNull(message = "시작 일시는 필수입니다.")
    val startDateTime: LocalDateTime?,
    @field:NotNull(message = "종료 일시는 필수입니다.")
    val endDateTime: LocalDateTime?,
    val isAllDay: Boolean = false,
    @field:NotBlank(message = "색상은 필수입니다.")
    @field:Size(min = 7, max = 7, message = "색상 코드는 #과 6자리 HEX 형식이어야 합니다.")
    val color: String,
)
