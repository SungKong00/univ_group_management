package org.castlekong.backend.service

import org.castlekong.backend.entity.GroupEvent
import org.castlekong.backend.entity.Place
import org.castlekong.backend.entity.PlaceReservation
import org.castlekong.backend.exception.BusinessException
import org.castlekong.backend.exception.ErrorCode
import org.castlekong.backend.repository.GroupEventRepository
import org.castlekong.backend.repository.GroupMemberRepository
import org.castlekong.backend.repository.PlaceAvailabilityRepository
import org.castlekong.backend.repository.PlaceBlockedTimeRepository
import org.castlekong.backend.repository.PlaceRepository
import org.castlekong.backend.repository.PlaceReservationRepository
import org.castlekong.backend.repository.PlaceUsageGroupRepository
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
    private val placeAvailabilityRepository: PlaceAvailabilityRepository,
    private val placeBlockedTimeRepository: PlaceBlockedTimeRepository,
    private val placeUsageGroupRepository: PlaceUsageGroupRepository,
    private val groupEventRepository: GroupEventRepository,
    private val groupMemberRepository: GroupMemberRepository,
    private val permissionService: PermissionService,
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
     * @param placeId 장소 ID
     * @param startDate 조회 시작 날짜
     * @param endDate 조회 종료 날짜
     * @param userId 조회 요청자 ID
     * @return 예약 목록
     * @throws BusinessException 사용 그룹 미승인
     */
    @Transactional(readOnly = true)
    fun getReservations(
        placeId: Long,
        startDate: LocalDateTime,
        endDate: LocalDateTime,
        userId: Long,
    ): List<PlaceReservation> {
        // 장소 조회 (존재 여부 확인)
        placeRepository.findActiveById(placeId)
            .orElseThrow { BusinessException(ErrorCode.PLACE_NOT_FOUND) }

        // 사용자의 그룹 중 하나라도 이 장소 사용 승인되어 있으면 OK
        // (조회 권한은 느슨하게 적용)
        // TODO: 추후 권한 정책 확정 시 세분화 가능

        return placeReservationRepository.findByPlaceIdAndDateRange(placeId, startDate, endDate)
    }

    /**
     * 다중 장소 캘린더 조회
     *
     * @param placeIds 장소 ID 목록
     * @param startDate 조회 시작 날짜
     * @param endDate 조회 종료 날짜
     * @param userId 조회 요청자 ID
     * @return 예약 목록 (장소별 필터링 적용)
     */
    @Transactional(readOnly = true)
    fun getPlaceCalendar(
        placeIds: List<Long>,
        startDate: LocalDateTime,
        endDate: LocalDateTime,
        userId: Long,
    ): List<PlaceReservation> {
        if (placeIds.isEmpty()) return emptyList()

        // 사용자의 승인된 장소 목록 조회
        val userGroupIds =
            groupMemberRepository.findByUserId(userId)
                .map { it.group.id }

        // 사용자가 접근 가능한 장소 필터링
        val accessiblePlaceIds =
            placeIds.filter { placeId ->
                userGroupIds.any { groupId ->
                    placeUsageGroupRepository.isApprovedForPlace(placeId, groupId)
                }
            }

        if (accessiblePlaceIds.isEmpty()) return emptyList()

        return placeReservationRepository.findByPlaceIdsAndDateRange(
            accessiblePlaceIds,
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
            val availabilities = placeAvailabilityRepository.findByPlaceIdAndDayOfWeek(place.id, startDayOfWeek)

            if (availabilities.isEmpty()) {
                throw BusinessException(ErrorCode.PLACE_OUTSIDE_OPERATING_HOURS)
            }

            // 예약 시간이 운영 시간 범위 내에 있는지 확인
            val isWithinOperatingHours =
                availabilities.any { avail ->
                    startTime >= avail.startTime && endTime <= avail.endTime
                }

            if (!isWithinOperatingHours) {
                throw BusinessException(ErrorCode.PLACE_OUTSIDE_OPERATING_HOURS)
            }
        } else {
            // 여러 날에 걸친 예약은 MVP에서 제한 또는 각 날짜별 검증 필요
            // 현재는 단순화: 시작일 운영시간만 체크
            val availabilities = placeAvailabilityRepository.findByPlaceIdAndDayOfWeek(place.id, startDayOfWeek)
            if (availabilities.isEmpty() || !availabilities.any { startTime >= it.startTime }) {
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
     */
    private fun checkUsageGroupApproval(
        place: Place,
        groupEvent: GroupEvent,
    ) {
        val isApproved =
            placeUsageGroupRepository.isApprovedForPlace(
                place.id,
                groupEvent.group.id,
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
}
