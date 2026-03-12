package com.univgroup.domain.group.repository

import com.univgroup.domain.group.entity.RequestStatus
import com.univgroup.domain.group.entity.SubGroupRequest
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

/**
 * 하위 그룹 생성 요청 Repository
 */
@Repository
interface SubGroupRequestRepository : JpaRepository<SubGroupRequest, Long> {
    /**
     * 부모 그룹 ID로 모든 하위 그룹 요청 조회
     */
    fun findByParentGroupId(parentGroupId: Long): List<SubGroupRequest>

    /**
     * 요청자 ID로 모든 하위 그룹 요청 조회
     */
    fun findByRequestedById(requestedById: Long): List<SubGroupRequest>

    /**
     * 부모 그룹 ID와 상태로 요청 조회
     */
    fun findByParentGroupIdAndStatus(parentGroupId: Long, status: RequestStatus): List<SubGroupRequest>

    /**
     * 요청자 ID와 상태로 요청 조회
     */
    fun findByRequestedByIdAndStatus(requestedById: Long, status: RequestStatus): List<SubGroupRequest>

    /**
     * 부모 그룹의 모든 요청 삭제
     */
    fun deleteByParentGroupId(parentGroupId: Long)
}
