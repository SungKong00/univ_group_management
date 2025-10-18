package org.castlekong.backend.service

import org.castlekong.backend.entity.Place
import org.castlekong.backend.entity.PlaceRestrictedTime
import org.castlekong.backend.exception.BusinessException
import org.castlekong.backend.exception.ErrorCode
import org.castlekong.backend.repository.PlaceRestrictedTimeRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.DayOfWeek
import java.time.LocalTime

/**
 * PlaceRestrictedTimeService
 *
 * 장소 금지시간 관리 서비스
 * - 금지시간 CRUD
 * - 비즈니스 로직 검증
 */
@Service
@Transactional(readOnly = true)
class PlaceRestrictedTimeService(
    private val placeRestrictedTimeRepository: PlaceRestrictedTimeRepository,
) {
    /**
     * 특정 장소의 모든 금지시간 조회
     */
    fun getRestrictedTimes(placeId: Long): List<PlaceRestrictedTime> {
        return placeRestrictedTimeRepository.findByPlaceId(placeId)
    }

    /**
     * 특정 장소의 특정 요일 금지시간 조회
     */
    fun getRestrictedTimesByDayOfWeek(
        placeId: Long,
        dayOfWeek: DayOfWeek,
    ): List<PlaceRestrictedTime> {
        return placeRestrictedTimeRepository.findByPlaceIdAndDayOfWeek(placeId, dayOfWeek)
    }

    /**
     * 금지시간 추가
     *
     * @param place 장소 엔티티
     * @param data 금지시간 데이터
     * @return 생성된 금지시간
     */
    @Transactional
    fun addRestrictedTime(
        place: Place,
        data: RestrictedTimeData,
    ): PlaceRestrictedTime {
        validateRestrictedTime(data)

        // displayOrder 자동 계산 (같은 요일의 마지막 +1)
        val existingTimes = placeRestrictedTimeRepository.findByPlaceIdAndDayOfWeek(place.id, data.dayOfWeek)
        val nextOrder = (existingTimes.maxOfOrNull { it.displayOrder } ?: -1) + 1

        val restrictedTime =
            PlaceRestrictedTime(
                place = place,
                dayOfWeek = data.dayOfWeek,
                startTime = data.startTime,
                endTime = data.endTime,
                reason = data.reason,
                displayOrder = nextOrder,
            )

        return placeRestrictedTimeRepository.save(restrictedTime)
    }

    /**
     * 금지시간 수정
     *
     * @param restrictedTimeId 금지시간 ID
     * @param data 금지시간 데이터
     * @return 수정된 금지시간
     */
    @Transactional
    fun updateRestrictedTime(
        restrictedTimeId: Long,
        data: RestrictedTimeData,
    ): PlaceRestrictedTime {
        validateRestrictedTime(data)

        val restrictedTime =
            placeRestrictedTimeRepository.findById(restrictedTimeId)
                .orElseThrow { BusinessException(ErrorCode.RESTRICTED_TIME_NOT_FOUND) }

        restrictedTime.update(
            startTime = data.startTime,
            endTime = data.endTime,
            reason = data.reason,
        )

        return placeRestrictedTimeRepository.save(restrictedTime)
    }

    /**
     * 금지시간 삭제
     *
     * @param restrictedTimeId 금지시간 ID
     */
    @Transactional
    fun deleteRestrictedTime(restrictedTimeId: Long) {
        if (!placeRestrictedTimeRepository.existsById(restrictedTimeId)) {
            throw BusinessException(ErrorCode.RESTRICTED_TIME_NOT_FOUND)
        }
        placeRestrictedTimeRepository.deleteById(restrictedTimeId)
    }

    /**
     * 금지시간 검증
     */
    private fun validateRestrictedTime(data: RestrictedTimeData) {
        if (data.startTime.isAfter(data.endTime) || data.startTime == data.endTime) {
            throw BusinessException(ErrorCode.INVALID_TIME_RANGE)
        }
    }

    /**
     * 금지시간 데이터 클래스
     */
    data class RestrictedTimeData(
        val dayOfWeek: DayOfWeek,
        val startTime: LocalTime,
        val endTime: LocalTime,
        val reason: String? = null,
    )
}
