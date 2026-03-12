package com.univgroup.domain.group.service

import com.univgroup.domain.group.entity.GroupMember
import com.univgroup.domain.group.repository.GroupMemberRepository
import com.univgroup.domain.group.repository.GroupRoleRepository
import com.univgroup.domain.permission.SystemRole
import com.univgroup.shared.dto.ErrorCode
import com.univgroup.shared.exception.ResourceNotFoundException
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

/**
 * 그룹 멤버 서비스 구현체
 *
 * 그룹 멤버십 관련 비즈니스 로직을 담당한다.
 */
@Service
@Transactional(readOnly = true)
class GroupMemberService(
    private val groupMemberRepository: GroupMemberRepository,
    private val groupRoleRepository: GroupRoleRepository,
) : IGroupMemberService {
    // ========== IGroupMemberService 구현 ==========

    override fun getMemberCount(groupId: Long): Int {
        return groupMemberRepository.countByGroupId(groupId).toInt()
    }

    override fun getMemberRoleId(
        groupId: Long,
        userId: Long,
    ): Long? {
        val member = groupMemberRepository.findByGroupIdAndUserId(groupId, userId)
        return member?.role?.id
    }

    // ========== 멤버 조회 ==========

    /**
     * 그룹 멤버 조회
     */
    fun getMember(
        groupId: Long,
        userId: Long,
    ): GroupMember? {
        return groupMemberRepository.findByGroupIdAndUserId(groupId, userId)
    }

    /**
     * 그룹 멤버 조회 (없으면 예외)
     */
    fun getMemberOrThrow(
        groupId: Long,
        userId: Long,
    ): GroupMember {
        return groupMemberRepository.findByGroupIdAndUserId(groupId, userId)
            ?: throw ResourceNotFoundException(
                ErrorCode.GROUP_MEMBER_NOT_FOUND,
                "멤버를 찾을 수 없습니다: groupId=$groupId, userId=$userId",
            )
    }

    /**
     * 그룹의 모든 멤버 조회 (역할 우선순위 순)
     */
    fun getMembers(groupId: Long): List<GroupMember> {
        return groupMemberRepository.findByGroupIdWithUserAndRole(groupId)
    }

    /**
     * 그룹의 멤버 조회 (페이징)
     */
    fun getMembers(
        groupId: Long,
        pageable: Pageable,
    ): Page<GroupMember> {
        return groupMemberRepository.findByGroupIdWithUserAndRole(groupId, pageable)
    }

    /**
     * 사용자의 모든 그룹 멤버십 조회
     */
    fun getUserMemberships(userId: Long): List<GroupMember> {
        return groupMemberRepository.findByUserIdWithGroupAndRole(userId)
    }

    /**
     * 특정 역할의 멤버 조회
     */
    fun getMembersByRole(
        groupId: Long,
        roleId: Long,
    ): List<GroupMember> {
        return groupMemberRepository.findByGroupIdAndRoleIdWithUser(groupId, roleId)
    }

    /**
     * 멤버 여부 확인
     */
    fun isMember(
        groupId: Long,
        userId: Long,
    ): Boolean {
        return groupMemberRepository.existsByGroupIdAndUserId(groupId, userId)
    }

    // ========== 멤버 관리 ==========

    /**
     * 멤버 추가
     *
     * @param member 추가할 멤버
     * @return 추가된 멤버
     */
    @Transactional
    fun addMember(member: GroupMember): GroupMember {
        // 이미 멤버인지 확인
        if (isMember(member.group.id!!, member.user.id!!)) {
            throw IllegalStateException("이미 그룹 멤버입니다")
        }

        return groupMemberRepository.save(member)
    }

    /**
     * 멤버 역할 변경
     *
     * @param groupId 그룹 ID
     * @param userId 사용자 ID
     * @param newRoleId 새 역할 ID
     * @return 수정된 멤버
     */
    @Transactional
    fun changeRole(
        groupId: Long,
        userId: Long,
        newRoleId: Long,
    ): GroupMember {
        val member = getMemberOrThrow(groupId, userId)
        val newRole =
            groupRoleRepository.findByGroupIdAndId(groupId, newRoleId)
                ?: throw ResourceNotFoundException(
                    ErrorCode.GROUP_ROLE_NOT_FOUND,
                    "역할을 찾을 수 없습니다: $newRoleId",
                )

        // 시스템 역할 변경 제한 (그룹장 역할은 소유권 이전으로만 변경)
        if (member.role.isSystemRole && member.role.name == SystemRole.OWNER.name) {
            throw IllegalStateException("그룹장 역할은 소유권 이전으로만 변경할 수 있습니다")
        }

        member.role = newRole
        return groupMemberRepository.save(member)
    }

    /**
     * 멤버 제거
     *
     * @param groupId 그룹 ID
     * @param userId 사용자 ID
     */
    @Transactional
    fun removeMember(
        groupId: Long,
        userId: Long,
    ) {
        val member = getMemberOrThrow(groupId, userId)

        // 그룹장은 삭제 불가
        if (member.role.isSystemRole && member.role.name == SystemRole.OWNER.name) {
            throw IllegalStateException("그룹장은 제거할 수 없습니다. 소유권을 먼저 이전하세요.")
        }

        groupMemberRepository.deleteByGroupIdAndUserId(groupId, userId)
    }

    /**
     * 그룹의 모든 멤버 제거 (그룹 삭제 시)
     */
    @Transactional
    fun removeAllMembers(groupId: Long) {
        groupMemberRepository.deleteAllByGroupId(groupId)
    }

    // ========== 통계 ==========

    /**
     * 역할별 멤버 수 조회
     *
     * @param groupId 그룹 ID
     * @return Map<역할ID, 멤버수>
     */
    fun getMemberCountByRole(groupId: Long): Map<Long, Long> {
        return groupMemberRepository.countByGroupIdGroupByRoleId(groupId)
            .associate { (it[0] as Long) to (it[1] as Long) }
    }
}
