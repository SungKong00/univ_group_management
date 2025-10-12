package org.castlekong.backend.dto

import com.fasterxml.jackson.annotation.JsonFormat
import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.NotNull
import jakarta.validation.constraints.Size
import java.time.DayOfWeek
import java.time.LocalTime

data class PersonalScheduleResponse(
    val id: Long,
    val title: String,
    val dayOfWeek: DayOfWeek,
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "HH:mm")
    val startTime: LocalTime,
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "HH:mm")
    val endTime: LocalTime,
    val location: String?,
    val color: String,
)

data class CreatePersonalScheduleRequest(
    @field:NotBlank(message = "제목은 필수입니다.")
    @field:Size(max = 200, message = "제목은 최대 200자까지 입력할 수 있습니다.")
    val title: String,
    @field:NotNull(message = "요일은 필수입니다.")
    val dayOfWeek: DayOfWeek?,
    @field:NotNull(message = "시작 시간은 필수입니다.")
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "HH:mm")
    val startTime: LocalTime?,
    @field:NotNull(message = "종료 시간은 필수입니다.")
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "HH:mm")
    val endTime: LocalTime?,
    @field:Size(max = 200, message = "장소는 최대 200자까지 입력할 수 있습니다.")
    val location: String? = null,
    @field:NotBlank(message = "색상은 필수입니다.")
    @field:Size(min = 7, max = 7, message = "색상 코드는 #과 6자리 HEX 형식이어야 합니다.")
    val color: String,
)

data class UpdatePersonalScheduleRequest(
    @field:NotBlank(message = "제목은 필수입니다.")
    @field:Size(max = 200, message = "제목은 최대 200자까지 입력할 수 있습니다.")
    val title: String,
    @field:NotNull(message = "요일은 필수입니다.")
    val dayOfWeek: DayOfWeek?,
    @field:NotNull(message = "시작 시간은 필수입니다.")
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "HH:mm")
    val startTime: LocalTime?,
    @field:NotNull(message = "종료 시간은 필수입니다.")
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "HH:mm")
    val endTime: LocalTime?,
    @field:Size(max = 200, message = "장소는 최대 200자까지 입력할 수 있습니다.")
    val location: String? = null,
    @field:NotBlank(message = "색상은 필수입니다.")
    @field:Size(min = 7, max = 7, message = "색상 코드는 #과 6자리 HEX 형식이어야 합니다.")
    val color: String,
)
