package com.univgroup.domain.group.service

import com.univgroup.domain.group.entity.Group

/**
 * 그룹 서비스 인터페이스 (도메인 경계 - Group 도메인 공개 API)
 *
 * 다른 도메인에서 그룹 정보가 필요할 때 이 인터페이스를 통해 접근한다.
 * Repository 직접 접근은 금지되며, 반드시 이 서비스를 통해야 한다.
 *
 * @see docs/refactor/backend/domain-boundaries.md
 */
interface IGroupService {
    // ========== 그룹 조회 ==========

    /**
     * ID로 그룹 조회
     *
     * @param groupId 그룹 ID
     * @return 그룹 엔티티 (없으면 null)
     */
    fun findById(groupId: Long): Group?

    /**
     * ID로 그룹 조회 (없으면 예외)
     *
     * @param groupId 그룹 ID
     * @return 그룹 엔티티
     * @throws ResourceNotFoundException 그룹이 없을 경우
     */
    fun getById(groupId: Long): Group

    /**
     * 그룹 존재 여부 확인
     *
     * @param groupId 그룹 ID
     * @return 존재 여부
     */
    fun exists(groupId: Long): Boolean

    // ========== 그룹 계층 ==========

    /**
     * 그룹의 모든 상위 그룹 조회 (부모 → 루트)
     *
     * @param groupId 그룹 ID
     * @return 상위 그룹 목록 (가까운 부모부터)
     */
    fun getAncestors(groupId: Long): List<Group>

    /**
     * 그룹의 직계 하위 그룹 조회
     *
     * @param groupId 그룹 ID
     * @return 하위 그룹 목록
     */
    fun getChildren(groupId: Long): List<Group>

    // ========== 멤버십 확인 ==========

    /**
     * 사용자가 그룹 멤버인지 확인
     *
     * @param groupId 그룹 ID
     * @param userId 사용자 ID
     * @return 멤버 여부
     */
    fun isMember(
        groupId: Long,
        userId: Long,
    ): Boolean

    /**
     * 사용자가 그룹 소유자인지 확인
     *
     * @param groupId 그룹 ID
     * @param userId 사용자 ID
     * @return 소유자 여부
     */
    fun isOwner(
        groupId: Long,
        userId: Long,
    ): Boolean
}

/**
 * 그룹 멤버 서비스 인터페이스
 */
interface IGroupMemberService {
    /**
     * 그룹의 멤버 수 조회
     *
     * @param groupId 그룹 ID
     * @return 멤버 수
     */
    fun getMemberCount(groupId: Long): Int

    /**
     * 사용자의 그룹 내 역할 ID 조회
     *
     * @param groupId 그룹 ID
     * @param userId 사용자 ID
     * @return 역할 ID (멤버가 아니면 null)
     */
    fun getMemberRoleId(
        groupId: Long,
        userId: Long,
    ): Long?
}

/**
 * 그룹 역할 서비스 인터페이스
 */
interface IGroupRoleService {
    /**
     * 그룹의 모든 역할 ID 조회
     *
     * @param groupId 그룹 ID
     * @return 역할 ID 목록
     */
    fun getRoleIds(groupId: Long): List<Long>

    /**
     * 시스템 역할인지 확인
     *
     * @param roleId 역할 ID
     * @return 시스템 역할 여부
     */
    fun isSystemRole(roleId: Long): Boolean
}
