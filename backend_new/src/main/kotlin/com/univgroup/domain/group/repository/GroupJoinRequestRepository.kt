package com.univgroup.domain.group.repository

import com.univgroup.domain.group.entity.GroupJoinRequest
import com.univgroup.domain.group.entity.RequestStatus
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

/**
 * 그룹 가입 요청 Repository
 */
@Repository
interface GroupJoinRequestRepository : JpaRepository<GroupJoinRequest, Long> {
    /**
     * 그룹 ID로 모든 가입 요청 조회
     */
    fun findByGroupId(groupId: Long): List<GroupJoinRequest>

    /**
     * 사용자 ID로 모든 가입 요청 조회
     */
    fun findByUserId(userId: Long): List<GroupJoinRequest>

    /**
     * 그룹 ID와 사용자 ID로 가입 요청 조회
     */
    fun findByGroupIdAndUserId(groupId: Long, userId: Long): GroupJoinRequest?

    /**
     * 그룹 ID와 상태로 가입 요청 조회
     */
    fun findByGroupIdAndStatus(groupId: Long, status: RequestStatus): List<GroupJoinRequest>

    /**
     * 사용자 ID와 상태로 가입 요청 조회
     */
    fun findByUserIdAndStatus(userId: Long, status: RequestStatus): List<GroupJoinRequest>

    /**
     * 그룹 ID와 사용자 ID로 PENDING 상태의 요청 존재 여부 확인
     */
    fun existsByGroupIdAndUserIdAndStatus(
        groupId: Long,
        userId: Long,
        status: RequestStatus = RequestStatus.PENDING
    ): Boolean

    /**
     * 그룹의 모든 가입 요청 삭제
     */
    fun deleteByGroupId(groupId: Long)
}
