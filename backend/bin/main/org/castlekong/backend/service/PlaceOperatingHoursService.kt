package org.castlekong.backend.service

import org.castlekong.backend.entity.Place
import org.castlekong.backend.entity.PlaceOperatingHours
import org.castlekong.backend.exception.BusinessException
import org.castlekong.backend.exception.ErrorCode
import org.castlekong.backend.repository.PlaceOperatingHoursRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.DayOfWeek
import java.time.LocalTime

/**
 * PlaceOperatingHoursService
 *
 * 장소 운영시간 관리 서비스
 * - 운영시간 조회/설정/수정
 * - 비즈니스 로직 검증
 */
@Service
@Transactional(readOnly = true)
class PlaceOperatingHoursService(
    private val placeOperatingHoursRepository: PlaceOperatingHoursRepository,
) {
    /**
     * 특정 장소의 모든 운영시간 조회
     */
    fun getOperatingHours(placeId: Long): List<PlaceOperatingHours> {
        return placeOperatingHoursRepository.findByPlaceId(placeId)
    }

    /**
     * 특정 장소의 특정 요일 운영시간 조회
     */
    fun getOperatingHoursByDayOfWeek(
        placeId: Long,
        dayOfWeek: DayOfWeek,
    ): PlaceOperatingHours? {
        return placeOperatingHoursRepository.findByPlaceIdAndDayOfWeek(placeId, dayOfWeek).orElse(null)
    }

    /**
     * 운영시간 전체 설정 (기존 운영시간 전체 삭제 후 재설정)
     *
     * @param place 장소 엔티티
     * @param operatingHoursData 요일별 운영시간 데이터
     * @return 저장된 운영시간 목록
     */
    @Transactional
    fun setOperatingHours(
        place: Place,
        operatingHoursData: Map<DayOfWeek, OperatingHoursData>,
    ): List<PlaceOperatingHours> {
        // 1. 기존 운영시간 전체 삭제
        placeOperatingHoursRepository.deleteByPlaceId(place.id)

        // 2. 삭제 즉시 반영 (Unique 제약 충돌 방지)
        placeOperatingHoursRepository.flush()

        // 3. 새 운영시간 생성
        val operatingHours =
            operatingHoursData.map { (dayOfWeek, data) ->
                validateOperatingHours(data)
                PlaceOperatingHours(
                    place = place,
                    dayOfWeek = dayOfWeek,
                    startTime = data.startTime,
                    endTime = data.endTime,
                    isClosed = data.isClosed,
                )
            }

        // 4. 저장
        return placeOperatingHoursRepository.saveAll(operatingHours)
    }

    /**
     * 특정 요일 운영시간 수정
     *
     * @param placeId 장소 ID
     * @param dayOfWeek 요일
     * @param data 운영시간 데이터
     * @return 수정된 운영시간
     */
    @Transactional
    fun updateOperatingHours(
        placeId: Long,
        dayOfWeek: DayOfWeek,
        data: OperatingHoursData,
    ): PlaceOperatingHours {
        validateOperatingHours(data)

        val operatingHours =
            placeOperatingHoursRepository.findByPlaceIdAndDayOfWeek(placeId, dayOfWeek)
                .orElseThrow { BusinessException(ErrorCode.OPERATING_HOURS_NOT_FOUND) }

        operatingHours.update(
            startTime = data.startTime,
            endTime = data.endTime,
            isClosed = data.isClosed,
        )

        return placeOperatingHoursRepository.save(operatingHours)
    }

    /**
     * 운영시간 검증
     */
    private fun validateOperatingHours(data: OperatingHoursData) {
        // isClosed = false인 경우에만 시간 검증
        if (!data.isClosed) {
            // 시작/종료 시간이 null이면 오류
            if (data.startTime == null || data.endTime == null) {
                throw BusinessException(ErrorCode.INVALID_TIME_RANGE)
            }
            // 시작 시간이 종료 시간보다 늦거나 같으면 오류
            if (data.startTime.isAfter(data.endTime) || data.startTime == data.endTime) {
                throw BusinessException(ErrorCode.INVALID_TIME_RANGE)
            }
        }
    }

    /**
     * 운영시간 데이터 클래스
     */
    data class OperatingHoursData(
        val startTime: LocalTime?,
        val endTime: LocalTime?,
        val isClosed: Boolean = false,
    )
}
