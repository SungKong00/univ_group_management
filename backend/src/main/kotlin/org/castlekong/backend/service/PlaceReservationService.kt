package org.castlekong.backend.service

import org.castlekong.backend.common.ValidationResult
import org.castlekong.backend.entity.GroupEvent
import org.castlekong.backend.entity.Place
import org.castlekong.backend.entity.PlaceReservation
import org.castlekong.backend.entity.User
import org.castlekong.backend.exception.BusinessException
import org.castlekong.backend.exception.ErrorCode
import org.castlekong.backend.repository.GroupEventRepository
import org.castlekong.backend.repository.GroupMemberRepository
import org.castlekong.backend.repository.PlaceBlockedTimeRepository
import org.castlekong.backend.repository.PlaceClosureRepository
import org.castlekong.backend.repository.PlaceOperatingHoursRepository
import org.castlekong.backend.repository.PlaceRepository
import org.castlekong.backend.repository.PlaceReservationRepository
import org.castlekong.backend.repository.PlaceRestrictedTimeRepository
import org.castlekong.backend.repository.PlaceUsageGroupRepository
import org.castlekong.backend.repository.UserRepository
import org.castlekong.backend.security.PermissionService
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDateTime

/**
 * PlaceReservationService
 *
 * 장소 예약 CRUD 및 검증 로직 처리
 * - 예약 생성/수정/취소
 * - 시간 충돌/운영시간/차단시간 검증
 * - 권한 체크: 본인 OR 관리 그룹의 CALENDAR_MANAGE
 */
@Service
@Transactional
class PlaceReservationService(
    private val placeReservationRepository: PlaceReservationRepository,
    private val placeRepository: PlaceRepository,
    private val placeBlockedTimeRepository: PlaceBlockedTimeRepository,
    private val placeOperatingHoursRepository: PlaceOperatingHoursRepository,
    private val placeRestrictedTimeRepository: PlaceRestrictedTimeRepository,
    private val placeClosureRepository: PlaceClosureRepository,
    private val placeUsageGroupRepository: PlaceUsageGroupRepository,
    private val groupEventRepository: GroupEventRepository,
    private val groupMemberRepository: GroupMemberRepository,
    private val permissionService: PermissionService,
    private val userRepository: UserRepository,
) {
    private val logger = LoggerFactory.getLogger(javaClass)

    /**
     * 예약 생성
     *
     * @param placeId 장소 ID
     * @param groupEventId 그룹 일정 ID
     * @param userId 예약자 ID
     * @return 생성된 예약
     * @throws BusinessException 시간 충돌, 운영 시간 외, 차단 시간, 권한 없음
     */
    fun createReservation(
        placeId: Long,
        groupEventId: Long,
        userId: Long,
    ): PlaceReservation {
        // 1. 장소 조회
        val place =
            placeRepository.findActiveById(placeId)
                .orElseThrow { BusinessException(ErrorCode.PLACE_NOT_FOUND) }

        // 2. 그룹 일정 조회
        val groupEvent =
            groupEventRepository.findById(groupEventId)
                .orElseThrow { BusinessException(ErrorCode.EVENT_NOT_FOUND) }

        // 3. 사용 그룹 승인 확인
        checkUsageGroupApproval(place, groupEvent)

        // 4. 시간 검증 (충돌 → 운영시간 → 차단시간)
        validateReservationTime(place, groupEvent, null)

        // 5. 사용자 조회
        val user =
            groupMemberRepository.findById(userId)
                .map { it.user }
                .orElseThrow { BusinessException(ErrorCode.USER_NOT_FOUND) }

        // 6. 예약 생성
        val reservation =
            PlaceReservation(
                place = place,
                groupEvent = groupEvent,
                reservedBy = user,
            )

        return placeReservationRepository.save(reservation)
    }

    /**
     * 예약 수정 (장소 변경)
     *
     * @param reservationId 예약 ID
     * @param newPlaceId 새 장소 ID (nullable, null이면 시간만 검증)
     * @param userId 수정 요청자 ID
     * @return 수정된 예약
     * @throws BusinessException 권한 없음, 시간 충돌 등
     */
    fun updateReservation(
        reservationId: Long,
        newPlaceId: Long?,
        userId: Long,
    ): PlaceReservation {
        // 1. 예약 조회
        val reservation =
            placeReservationRepository.findById(reservationId)
                .orElseThrow { BusinessException(ErrorCode.PLACE_RESERVATION_NOT_FOUND) }

        // 2. 권한 확인 (본인 OR 관리 그룹)
        checkReservationPermission(reservation, userId)

        // 3. 새 장소가 지정된 경우 장소 변경
        val targetPlace =
            if (newPlaceId != null && newPlaceId != reservation.place.id) {
                val newPlace =
                    placeRepository.findActiveById(newPlaceId)
                        .orElseThrow { BusinessException(ErrorCode.PLACE_NOT_FOUND) }

                // 사용 그룹 승인 확인
                checkUsageGroupApproval(newPlace, reservation.groupEvent)

                newPlace
            } else {
                reservation.place
            }

        // 4. 시간 검증 (자기 자신 제외)
        validateReservationTime(targetPlace, reservation.groupEvent, reservationId)

        // 5. 장소 업데이트 (필요 시)
        if (newPlaceId != null && targetPlace.id != reservation.place.id) {
            reservation.updateReservation(targetPlace)
        }

        return placeReservationRepository.save(reservation)
    }

    /**
     * 예약 취소 (Hard delete)
     *
     * @param reservationId 예약 ID
     * @param userId 취소 요청자 ID
     * @throws BusinessException 권한 없음, 예약 없음
     */
    fun cancelReservation(
        reservationId: Long,
        userId: Long,
    ) {
        // 1. 예약 조회
        val reservation =
            placeReservationRepository.findById(reservationId)
                .orElseThrow { BusinessException(ErrorCode.PLACE_RESERVATION_NOT_FOUND) }

        // 2. 권한 확인 (본인 OR 관리 그룹)
        checkReservationPermission(reservation, userId)

        // 3. 예약 삭제 (Hard delete)
        placeReservationRepository.delete(reservation)

        logger.info("예약 취소: reservationId=$reservationId, userId=$userId")
    }

    /**
     * 장소별 예약 조회
     *
     * 공개 기능: 충돌 방지를 위해 모든 장소의 예약 현황을 조회 가능
     * 인증 없이 호출 가능 (userId는 현재 사용되지 않음)
     *
     * @param placeId 장소 ID
     * @param startDate 조회 시작 날짜
     * @param endDate 조회 종료 날짜
     * @param userId 조회 요청자 ID (선택적, 현재 미사용)
     * @return 예약 목록
     * @throws BusinessException 장소 없음
     */
    @Transactional(readOnly = true)
    fun getReservations(
        placeId: Long,
        startDate: LocalDateTime,
        endDate: LocalDateTime,
        userId: Long?,
    ): List<PlaceReservation> {
        // 장소 조회 (존재 여부 확인)
        placeRepository.findActiveById(placeId)
            .orElseThrow { BusinessException(ErrorCode.PLACE_NOT_FOUND) }

        // 공개 조회: 승인 여부와 무관하게 모든 예약 조회 가능
        return placeReservationRepository.findByPlaceIdAndDateRange(placeId, startDate, endDate)
    }

    /**
     * 다중 장소 캘린더 조회
     *
     * 공개 기능: 충돌 방지를 위해 모든 장소의 예약 현황을 조회 가능
     * 인증 없이 호출 가능 (userId는 현재 사용되지 않음)
     *
     * @param placeIds 장소 ID 목록
     * @param startDate 조회 시작 날짜
     * @param endDate 조회 종료 날짜
     * @param userId 조회 요청자 ID (선택적, 현재 미사용)
     * @return 예약 목록 (존재하는 장소만)
     */
    @Transactional(readOnly = true)
    fun getPlaceCalendar(
        placeIds: List<Long>,
        startDate: LocalDateTime,
        endDate: LocalDateTime,
        userId: Long?,
    ): List<PlaceReservation> {
        if (placeIds.isEmpty()) return emptyList()

        // 존재하는 장소(deletedAt IS NULL)만 필터링
        val validPlaceIds =
            placeIds.mapNotNull { placeId ->
                placeRepository.findActiveById(placeId)
                    .map { it.id }
                    .orElse(null)
            }

        if (validPlaceIds.isEmpty()) return emptyList()

        return placeReservationRepository.findByPlaceIdsAndDateRange(
            validPlaceIds,
            startDate,
            endDate,
        )
    }

    // ============ Private Helper Methods ============

    /**
     * 시간 검증 (충돌 → 운영시간 → 차단시간)
     */
    private fun validateReservationTime(
        place: Place,
        groupEvent: GroupEvent,
        excludeReservationId: Long?,
    ) {
        val startDateTime = groupEvent.startDate
        val endDateTime = groupEvent.endDate

        // 1. 시간 충돌 검사
        val overlappingReservations =
            placeReservationRepository.findOverlappingReservations(
                place.id,
                startDateTime,
                endDateTime,
                excludeReservationId,
            )

        if (overlappingReservations.isNotEmpty()) {
            throw BusinessException(ErrorCode.PLACE_TIME_CONFLICT)
        }

        // 2. 운영 시간 확인
        validateOperatingHours(place, startDateTime, endDateTime)

        // 3. 차단 시간 확인
        validateBlockedTimes(place, startDateTime, endDateTime)
    }

    /**
     * 운영 시간 확인
     */
    private fun validateOperatingHours(
        place: Place,
        startDateTime: LocalDateTime,
        endDateTime: LocalDateTime,
    ) {
        // 시작 시간과 종료 시간의 요일/시간 추출
        val startDate = startDateTime.toLocalDate()
        val endDate = endDateTime.toLocalDate()
        val startTime = startDateTime.toLocalTime()
        val endTime = endDateTime.toLocalTime()
        val startDayOfWeek = startDate.dayOfWeek

        // 같은 날 예약인 경우
        if (startDate == endDate) {
            val operatingHours =
                placeOperatingHoursRepository.findByPlaceIdAndDayOfWeek(place.id, startDayOfWeek)
                    .orElse(null)

            if (operatingHours == null || operatingHours.isClosed) {
                throw BusinessException(ErrorCode.PLACE_OUTSIDE_OPERATING_HOURS)
            }

            // 예약 시간이 운영 시간 범위 내에 있는지 확인
            if (!operatingHours.fullyContains(startTime, endTime)) {
                throw BusinessException(ErrorCode.PLACE_OUTSIDE_OPERATING_HOURS)
            }
        } else {
            // 여러 날에 걸친 예약은 MVP에서 제한 또는 각 날짜별 검증 필요
            // 현재는 단순화: 시작일 운영시간만 체크
            val operatingHours =
                placeOperatingHoursRepository.findByPlaceIdAndDayOfWeek(place.id, startDayOfWeek)
                    .orElse(null)
            if (operatingHours == null || operatingHours.isClosed || startTime.isBefore(operatingHours.startTime)) {
                throw BusinessException(ErrorCode.PLACE_OUTSIDE_OPERATING_HOURS)
            }
        }
    }

    /**
     * 차단 시간 확인
     */
    private fun validateBlockedTimes(
        place: Place,
        startDateTime: LocalDateTime,
        endDateTime: LocalDateTime,
    ) {
        val blockedTimes =
            placeBlockedTimeRepository.findConflicts(
                place.id,
                startDateTime,
                endDateTime,
            )

        if (blockedTimes.isNotEmpty()) {
            throw BusinessException(ErrorCode.PLACE_TIME_BLOCKED)
        }
    }

    /**
     * 사용 그룹 승인 확인
     *
     * 관리 그룹(managingGroupId)은 자신의 장소를 승인 없이 예약 가능
     * 다른 그룹은 PlaceUsageGroup에서 APPROVED 상태 확인 필요
     */
    private fun checkUsageGroupApproval(
        place: Place,
        groupEvent: GroupEvent,
    ) {
        val groupId = groupEvent.group.id

        // 관리 그룹이면 승인 체크 생략
        if (place.managingGroup.id == groupId) {
            return
        }

        // 다른 그룹은 승인 확인
        val isApproved =
            placeUsageGroupRepository.isApprovedForPlace(
                place.id,
                groupId,
            )

        if (!isApproved) {
            throw BusinessException(ErrorCode.PLACE_USAGE_NOT_APPROVED)
        }
    }

    /**
     * 예약 취소/수정 권한 확인
     * - 본인 (reservedBy)
     * - 관리 그룹의 CALENDAR_MANAGE 권한자
     */
    private fun checkReservationPermission(
        reservation: PlaceReservation,
        userId: Long,
    ) {
        // 1. 본인 확인
        if (reservation.reservedBy.id == userId) {
            return
        }

        // 2. 관리 그룹의 CALENDAR_MANAGE 권한 확인
        val managingGroupId = reservation.place.managingGroup.id

        val isMember =
            groupMemberRepository.findByGroupIdAndUserId(managingGroupId, userId)
                .isPresent

        if (!isMember) {
            throw BusinessException(ErrorCode.PLACE_NOT_AUTHORIZED)
        }

        val effectivePermissions =
            permissionService.getEffective(managingGroupId, userId) { roleName ->
                getSystemRolePermissions(roleName)
            }

        if (!effectivePermissions.contains(org.castlekong.backend.entity.GroupPermission.CALENDAR_MANAGE)) {
            throw BusinessException(ErrorCode.PLACE_NOT_AUTHORIZED)
        }
    }

    private fun getSystemRolePermissions(roleName: String): Set<org.castlekong.backend.entity.GroupPermission> =
        when (roleName) {
            "그룹장" ->
                setOf(
                    org.castlekong.backend.entity.GroupPermission.GROUP_MANAGE,
                    org.castlekong.backend.entity.GroupPermission.MEMBER_MANAGE,
                    org.castlekong.backend.entity.GroupPermission.CHANNEL_MANAGE,
                    org.castlekong.backend.entity.GroupPermission.RECRUITMENT_MANAGE,
                    org.castlekong.backend.entity.GroupPermission.CALENDAR_MANAGE,
                )
            "교수" ->
                setOf(
                    org.castlekong.backend.entity.GroupPermission.CHANNEL_MANAGE,
                    org.castlekong.backend.entity.GroupPermission.CALENDAR_MANAGE,
                )
            else -> emptySet()
        }

    // ============ GroupEvent Integration Methods (Phase 2) ============

    /**
     * 예약 가능 여부 검증 (3단계: 운영 시간 → 차단 시간 → 예약 충돌)
     *
     * GroupEventService에서 일정 생성 전 호출하여 예약 가능 여부 확인
     *
     * @param placeId 장소 ID
     * @param startDateTime 시작 시간
     * @param endDateTime 종료 시간
     * @param excludeEventId 제외할 일정 ID (수정 시 자기 자신 제외)
     * @return ValidationResult (성공/실패 + 에러코드)
     */
    fun validateReservation(
        placeId: Long,
        startDateTime: LocalDateTime,
        endDateTime: LocalDateTime,
        excludeEventId: Long? = null,
    ): ValidationResult {
        // 1. 장소 조회
        val place =
            placeRepository.findActiveById(placeId)
                .orElse(null)
                ?: return ValidationResult.failure(ErrorCode.PLACE_NOT_FOUND)

        // 2. 운영 시간 확인
        if (!isWithinOperatingHours(place, startDateTime, endDateTime)) {
            return ValidationResult.failure(
                ErrorCode.OUTSIDE_OPERATING_HOURS,
                "운영 시간 외입니다.",
            )
        }

        // 3. 차단 시간 확인
        val blockedTimes =
            placeBlockedTimeRepository.findConflicts(
                place.id,
                startDateTime,
                endDateTime,
            )

        if (blockedTimes.isNotEmpty()) {
            val reason = blockedTimes.first().reason
            return ValidationResult.failure(
                ErrorCode.PLACE_BLOCKED,
                "해당 시간대는 예약이 불가능합니다. 사유: ${reason ?: "관리자 차단"}",
            )
        }

        // 4. 예약 충돌 확인
        val allOverlapping =
            placeReservationRepository.findOverlappingReservations(
                place.id,
                startDateTime,
                endDateTime,
                null, // excludeReservationId는 null (eventId 기반 필터링은 아래에서 처리)
            )

        val conflictingReservations =
            if (excludeEventId != null) {
                // 수정 시: 자기 자신(eventId) 제외
                allOverlapping.filter { it.groupEvent.id != excludeEventId }
            } else {
                // 생성 시: 모든 예약과 비교
                allOverlapping
            }

        if (conflictingReservations.isNotEmpty()) {
            return ValidationResult.failure(
                ErrorCode.RESERVATION_CONFLICT,
                "이미 예약된 시간대입니다.",
            )
        }

        return ValidationResult.success()
    }

    /**
     * 그룹의 장소 사용 권한 확인
     *
     * - 관리 그룹(managingGroup)이면 자동 허용
     * - 다른 그룹이면 PlaceUsageGroup APPROVED 상태 확인
     *
     * @param groupId 그룹 ID
     * @param placeId 장소 ID
     * @return true: 권한 있음, false: 권한 없음
     */
    fun hasReservationPermission(
        groupId: Long,
        placeId: Long,
    ): Boolean {
        val place =
            placeRepository.findActiveById(placeId)
                .orElse(null) ?: return false

        // 관리 그룹이면 자동 허용
        if (place.managingGroup.id == groupId) {
            return true
        }

        // PlaceUsageGroup APPROVED 확인
        return placeUsageGroupRepository.isApprovedForPlace(placeId, groupId)
    }

    /**
     * PlaceReservation 생성 (GroupEvent 기반)
     *
     * GroupEventService에서 일정 생성 후 호출하여 예약 레코드 생성
     * - 사전 검증 완료 가정 (validateReservation + hasReservationPermission 호출됨)
     *
     * @param placeId 장소 ID
     * @param groupEvent 생성된 GroupEvent
     * @param user 예약자 (일정 작성자)
     * @return 생성된 PlaceReservation
     */
    fun createReservationForEvent(
        placeId: Long,
        groupEvent: GroupEvent,
        user: User,
    ): PlaceReservation {
        val place =
            placeRepository.findActiveById(placeId)
                .orElseThrow { BusinessException(ErrorCode.PLACE_NOT_FOUND) }

        val reservation =
            PlaceReservation(
                place = place,
                groupEvent = groupEvent,
                reservedBy = user,
            )

        val saved = placeReservationRepository.save(reservation)
        logger.info("예약 생성 (GroupEvent 통합): reservationId=${saved.id}, eventId=${groupEvent.id}, placeId=$placeId")
        return saved
    }

    /**
     * 운영 시간 확인 (여러 날짜에 걸친 일정 지원)
     *
     * 새로운 PlaceOperatingHours 시스템 사용
     *
     * @param place 장소
     * @param startDateTime 시작 시간
     * @param endDateTime 종료 시간
     * @return true: 운영 시간 내, false: 운영 시간 외
     */
    private fun isWithinOperatingHours(
        place: Place,
        startDateTime: LocalDateTime,
        endDateTime: LocalDateTime,
    ): Boolean {
        val startDate = startDateTime.toLocalDate()
        val endDate = endDateTime.toLocalDate()

        // 같은 날 예약인 경우
        if (startDate == endDate) {
            return checkOperatingHoursForSingleDayNew(place, startDateTime, endDateTime)
        }

        // 여러 날에 걸친 예약: 각 날짜별로 검증
        var currentDate = startDate
        while (!currentDate.isAfter(endDate)) {
            val dayStart =
                if (currentDate == startDate) startDateTime else currentDate.atStartOfDay()
            val dayEnd =
                if (currentDate == endDate) endDateTime else currentDate.atTime(23, 59, 59)

            if (!checkOperatingHoursForSingleDayNew(place, dayStart, dayEnd)) {
                return false
            }

            currentDate = currentDate.plusDays(1)
        }

        return true
    }

    /**
     * 단일 날짜 운영 시간 확인 (PlaceOperatingHours 기반)
     */
    private fun checkOperatingHoursForSingleDayNew(
        place: Place,
        startDateTime: LocalDateTime,
        endDateTime: LocalDateTime,
    ): Boolean {
        val dayOfWeek = startDateTime.dayOfWeek
        val startTime = startDateTime.toLocalTime()
        val endTime = endDateTime.toLocalTime()

        // 해당 요일의 운영 시간 조회
        val operatingHours =
            placeOperatingHoursRepository.findByPlaceIdAndDayOfWeek(place.id, dayOfWeek)
                .orElse(null) ?: return false // 해당 요일 운영 정보 없음

        if (operatingHours.isClosed) {
            return false // 해당 요일 휴무
        }

        // 예약 시간이 운영 시간 범위 내에 완전히 포함되는지 확인
        return operatingHours.fullyContains(startTime, endTime)
    }

    // ============ New Time Management Integration (Phase 2) ============

    /**
     * 예약 가능 여부 검증 (신규 시간 관리 시스템)
     *
     * 검증 순서: 운영시간 → 금지시간 → 임시휴무 → 기존 예약 충돌
     *
     * @param placeId 장소 ID
     * @param date 예약 날짜
     * @param startTime 시작 시간
     * @param endTime 종료 시간
     * @return true: 예약 가능, false: 예약 불가
     */
    fun isReservable(
        placeId: Long,
        date: java.time.LocalDate,
        startTime: java.time.LocalTime,
        endTime: java.time.LocalTime,
    ): Boolean {
        // 1. 운영시간 확인
        val operatingHours =
            placeOperatingHoursRepository.findByPlaceIdAndDayOfWeek(placeId, date.dayOfWeek)
                .orElse(null)
        if (operatingHours == null || operatingHours.isClosed) {
            return false // 해당 요일 휴무
        }
        if (!operatingHours.fullyContains(startTime, endTime)) {
            return false // 운영시간 외
        }

        // 2. 금지시간 확인
        val restrictedTimes = placeRestrictedTimeRepository.findByPlaceIdAndDayOfWeek(placeId, date.dayOfWeek)
        for (restricted in restrictedTimes) {
            if (restricted.overlapsWith(startTime, endTime)) {
                return false // 금지시간과 겹침
            }
        }

        // 3. 임시 휴무 확인
        val closure = placeClosureRepository.findByPlaceIdAndDate(placeId, date).orElse(null)
        if (closure != null && closure.overlapsWithTimeRange(date, startTime, endTime)) {
            return false // 임시 휴무
        }

        // 4. 기존 예약 충돌 확인
        val startDateTime = date.atTime(startTime)
        val endDateTime = date.atTime(endTime)
        val hasConflict = hasReservationConflict(placeId, startDateTime, endDateTime)
        if (hasConflict) {
            return false // 다른 예약과 충돌
        }

        return true // 예약 가능
    }

    /**
     * 예약 가능 시간 슬롯 계산
     *
     * 특정 날짜의 예약 가능한 시간대를 계산하여 반환
     *
     * @param placeId 장소 ID
     * @param date 조회 날짜
     * @return 예약 가능한 시간 슬롯 목록
     */
    fun getAvailableSlots(
        placeId: Long,
        date: java.time.LocalDate,
    ): List<TimeSlot> {
        // 1. 운영시간 확인
        val operatingHours =
            placeOperatingHoursRepository.findByPlaceIdAndDayOfWeek(placeId, date.dayOfWeek)
                .orElse(null)
        if (operatingHours == null || operatingHours.isClosed) {
            return emptyList() // 해당 요일 휴무
        }

        // 2. 임시 휴무 확인
        val closure = placeClosureRepository.findByPlaceIdAndDate(placeId, date).orElse(null)
        if (closure != null && closure.isFullDay) {
            return emptyList() // 전일 휴무
        }

        // 3. 기본 가용 시간: 운영시간
        val availableSlots = mutableListOf<TimeSlot>()
        var currentStart = operatingHours.startTime
        val operatingEnd = operatingHours.endTime

        // 4. 금지시간 제외
        val restrictedTimes =
            placeRestrictedTimeRepository.findByPlaceIdAndDayOfWeek(placeId, date.dayOfWeek)
                .sortedBy { it.startTime }

        for (restricted in restrictedTimes) {
            if (currentStart < restricted.startTime) {
                availableSlots.add(TimeSlot(currentStart, restricted.startTime))
            }
            currentStart = maxOf(currentStart, restricted.endTime)
        }

        // 5. 마지막 슬롯 추가
        if (currentStart < operatingEnd) {
            availableSlots.add(TimeSlot(currentStart, operatingEnd))
        }

        // 6. 부분 임시 휴무 제외
        if (closure != null && !closure.isFullDay && closure.startTime != null && closure.endTime != null) {
            availableSlots.removeIf { slot ->
                slot.overlaps(closure.startTime!!, closure.endTime!!)
            }
        }

        // 7. 기존 예약 제외
        val startDateTime = date.atStartOfDay()
        val endDateTime = date.atTime(23, 59, 59)
        val existingReservations =
            placeReservationRepository.findByPlaceIdAndDateRange(placeId, startDateTime, endDateTime)

        val finalSlots = mutableListOf<TimeSlot>()
        for (slot in availableSlots) {
            var slotStart = slot.startTime
            val slotEnd = slot.endTime

            // 예약과 겹치는 부분 제외
            val overlappingReservations =
                existingReservations.filter { reservation ->
                    val resStart = reservation.getStartDateTime().toLocalTime()
                    val resEnd = reservation.getEndDateTime().toLocalTime()
                    !(resEnd.isBefore(slotStart) || resStart.isAfter(slotEnd))
                }.sortedBy { it.getStartDateTime().toLocalTime() }

            for (reservation in overlappingReservations) {
                val resStart = reservation.getStartDateTime().toLocalTime()
                val resEnd = reservation.getEndDateTime().toLocalTime()

                if (slotStart < resStart) {
                    finalSlots.add(TimeSlot(slotStart, resStart))
                }
                slotStart = maxOf(slotStart, resEnd)
            }

            if (slotStart < slotEnd) {
                finalSlots.add(TimeSlot(slotStart, slotEnd))
            }
        }

        return finalSlots
    }

    /**
     * 기존 예약 충돌 확인
     */
    private fun hasReservationConflict(
        placeId: Long,
        startDateTime: LocalDateTime,
        endDateTime: LocalDateTime,
    ): Boolean {
        val overlappingReservations =
            placeReservationRepository.findOverlappingReservations(
                placeId,
                startDateTime,
                endDateTime,
                null,
            )
        return overlappingReservations.isNotEmpty()
    }

    /**
     * 시간 슬롯 데이터 클래스
     */
    data class TimeSlot(
        val startTime: java.time.LocalTime,
        val endTime: java.time.LocalTime,
    ) {
        fun overlaps(
            otherStart: java.time.LocalTime,
            otherEnd: java.time.LocalTime,
        ): Boolean {
            return !(endTime.isBefore(otherStart) || startTime.isAfter(otherEnd))
        }
    }
}
