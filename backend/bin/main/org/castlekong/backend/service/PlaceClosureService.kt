package org.castlekong.backend.service

import org.castlekong.backend.entity.Place
import org.castlekong.backend.entity.PlaceClosure
import org.castlekong.backend.entity.User
import org.castlekong.backend.exception.BusinessException
import org.castlekong.backend.exception.ErrorCode
import org.castlekong.backend.repository.PlaceClosureRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDate
import java.time.LocalTime

/**
 * PlaceClosureService
 *
 * 장소 임시 휴무 관리 서비스
 * - 임시 휴무 CRUD
 * - 날짜 범위 조회
 */
@Service
@Transactional(readOnly = true)
class PlaceClosureService(
    private val placeClosureRepository: PlaceClosureRepository,
) {
    /**
     * 특정 장소의 모든 임시 휴무 조회
     */
    fun getClosures(placeId: Long): List<PlaceClosure> {
        return placeClosureRepository.findByPlaceId(placeId)
    }

    /**
     * 특정 장소의 날짜 범위 내 임시 휴무 조회
     */
    fun getClosuresByDateRange(
        placeId: Long,
        from: LocalDate,
        to: LocalDate,
    ): List<PlaceClosure> {
        if (from.isAfter(to)) {
            throw BusinessException(ErrorCode.INVALID_DATE_RANGE)
        }
        return placeClosureRepository.findByPlaceIdAndDateRange(placeId, from, to)
    }

    /**
     * 특정 장소의 특정 날짜 임시 휴무 조회
     */
    fun getClosureByDate(
        placeId: Long,
        date: LocalDate,
    ): PlaceClosure? {
        return placeClosureRepository.findByPlaceIdAndDate(placeId, date).orElse(null)
    }

    /**
     * 임시 휴무 추가
     *
     * @param place 장소 엔티티
     * @param user 휴무 등록자
     * @param data 휴무 데이터
     * @return 생성된 임시 휴무
     */
    @Transactional
    fun addClosure(
        place: Place,
        user: User,
        data: ClosureData,
    ): PlaceClosure {
        validateClosure(data)

        // 중복 확인 (같은 날짜에 이미 휴무가 있는지)
        val existing = placeClosureRepository.findByPlaceIdAndDate(place.id, data.closureDate)
        if (existing.isPresent) {
            throw BusinessException(ErrorCode.CLOSURE_ALREADY_EXISTS)
        }

        val closure =
            PlaceClosure(
                place = place,
                closureDate = data.closureDate,
                isFullDay = data.isFullDay,
                startTime = data.startTime,
                endTime = data.endTime,
                reason = data.reason,
                createdBy = user,
            )

        return placeClosureRepository.save(closure)
    }

    /**
     * 임시 휴무 삭제
     *
     * @param closureId 휴무 ID
     */
    @Transactional
    fun deleteClosure(closureId: Long) {
        if (!placeClosureRepository.existsById(closureId)) {
            throw BusinessException(ErrorCode.CLOSURE_NOT_FOUND)
        }
        placeClosureRepository.deleteById(closureId)
    }

    /**
     * 임시 휴무 검증
     */
    private fun validateClosure(data: ClosureData) {
        // 부분 시간 휴무인 경우 시간 검증
        if (!data.isFullDay) {
            if (data.startTime == null || data.endTime == null) {
                throw BusinessException(ErrorCode.INVALID_REQUEST)
            }
            if (data.startTime.isAfter(data.endTime) || data.startTime == data.endTime) {
                throw BusinessException(ErrorCode.INVALID_TIME_RANGE)
            }
        }
    }

    /**
     * 임시 휴무 데이터 클래스
     */
    data class ClosureData(
        val closureDate: LocalDate,
        val isFullDay: Boolean = true,
        val startTime: LocalTime? = null,
        val endTime: LocalTime? = null,
        val reason: String? = null,
    )
}
