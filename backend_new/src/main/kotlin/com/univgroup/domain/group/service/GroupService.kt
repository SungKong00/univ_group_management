package com.univgroup.domain.group.service

import com.univgroup.domain.group.entity.Group
import com.univgroup.domain.group.entity.GroupType
import com.univgroup.domain.group.repository.GroupMemberRepository
import com.univgroup.domain.group.repository.GroupRepository
import com.univgroup.shared.dto.ErrorCode
import com.univgroup.shared.exception.ResourceNotFoundException
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

/**
 * 그룹 서비스 구현체
 *
 * Group 도메인의 핵심 비즈니스 로직을 담당한다.
 * 다른 도메인에서 그룹 정보가 필요할 때 이 서비스를 통해 접근한다.
 */
@Service
@Transactional(readOnly = true)
class GroupService(
    private val groupRepository: GroupRepository,
    private val groupMemberRepository: GroupMemberRepository,
) : IGroupService {
    // ========== IGroupService 구현 ==========

    override fun findById(groupId: Long): Group? {
        return groupRepository.findById(groupId).orElse(null)
    }

    override fun getById(groupId: Long): Group {
        return groupRepository.findById(groupId).orElseThrow {
            ResourceNotFoundException(
                ErrorCode.GROUP_NOT_FOUND,
                "그룹을 찾을 수 없습니다: $groupId",
            )
        }
    }

    override fun exists(groupId: Long): Boolean {
        return groupRepository.existsById(groupId)
    }

    override fun getAncestors(groupId: Long): List<Group> {
        val ancestors = mutableListOf<Group>()
        var currentGroup = findById(groupId)

        while (currentGroup?.parent != null) {
            currentGroup = currentGroup.parent
            currentGroup?.let { ancestors.add(it) }
        }

        return ancestors
    }

    override fun getChildren(groupId: Long): List<Group> {
        return groupRepository.findChildrenOrderByName(groupId)
    }

    override fun isMember(
        groupId: Long,
        userId: Long,
    ): Boolean {
        return groupMemberRepository.existsByGroupIdAndUserId(groupId, userId)
    }

    override fun isOwner(
        groupId: Long,
        userId: Long,
    ): Boolean {
        val group = findById(groupId) ?: return false
        return group.owner.id == userId
    }

    // ========== 추가 비즈니스 로직 ==========

    /**
     * 그룹 검색 (visibility 필드 제거됨)
     */
    fun searchGroups(
        keyword: String,
        pageable: Pageable,
    ): Page<Group> {
        return groupRepository.searchByKeyword(keyword, pageable)
    }

    /**
     * 대학교 내 그룹 조회
     */
    fun getGroupsByUniversity(
        university: String,
        groupType: GroupType,
    ): List<Group> {
        return groupRepository.findByUniversityAndGroupType(university, groupType)
    }

    /**
     * 사용자가 소유한 그룹 조회
     */
    fun getOwnedGroups(userId: Long): List<Group> {
        return groupRepository.findByOwnerIdOrderByCreatedAtDesc(userId)
    }

    /**
     * 루트 그룹 조회 (부모가 없는 그룹)
     */
    fun getRootGroups(): List<Group> {
        return groupRepository.findByParentIdIsNull()
    }

    // ========== 그룹 생성/수정/삭제 ==========

    /**
     * 그룹 생성
     *
     * @param group 생성할 그룹 엔티티
     * @return 생성된 그룹
     */
    @Transactional
    fun createGroup(group: Group): Group {
        // 같은 부모 아래 중복 이름 체크
        if (groupRepository.existsByParentIdAndName(group.parent?.id, group.name)) {
            throw IllegalArgumentException("이미 존재하는 그룹 이름입니다: ${group.name}")
        }

        return groupRepository.save(group)
    }

    /**
     * 그룹 정보 수정
     *
     * @param groupId 그룹 ID
     * @param updateFn 업데이트 함수
     * @return 수정된 그룹
     */
    @Transactional
    fun updateGroup(
        groupId: Long,
        updateFn: (Group) -> Unit,
    ): Group {
        val group = getById(groupId)
        updateFn(group)
        return groupRepository.save(group)
    }

    /**
     * 그룹 삭제
     *
     * @param groupId 그룹 ID
     */
    @Transactional
    fun deleteGroup(groupId: Long) {
        val group = getById(groupId)

        // 하위 그룹이 있으면 삭제 불가
        val children = getChildren(groupId)
        if (children.isNotEmpty()) {
            throw IllegalStateException("하위 그룹이 있어 삭제할 수 없습니다")
        }

        groupRepository.delete(group)
    }
}
