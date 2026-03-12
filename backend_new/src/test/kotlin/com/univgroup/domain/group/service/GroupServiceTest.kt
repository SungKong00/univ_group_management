package com.univgroup.domain.group.service

import com.ninjasquad.springmockk.MockkBean
import com.univgroup.domain.group.entity.Group
import com.univgroup.domain.group.entity.GroupType
import com.univgroup.domain.group.repository.GroupMemberRepository
import com.univgroup.domain.group.repository.GroupRepository
import com.univgroup.domain.user.entity.User
import com.univgroup.shared.exception.ResourceNotFoundException
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.assertj.core.api.Assertions.assertThat
import org.assertj.core.api.Assertions.assertThatThrownBy
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Test
import org.springframework.data.domain.PageImpl
import org.springframework.data.domain.PageRequest
import java.util.*

@DisplayName("GroupService 단위 테스트")
class GroupServiceTest {
    private lateinit var groupService: GroupService
    private lateinit var groupRepository: GroupRepository
    private lateinit var groupMemberRepository: GroupMemberRepository

    // Test Entities
    private lateinit var testOwner: User
    private lateinit var testUser: User
    private lateinit var rootGroup: Group
    private lateinit var childGroup1: Group
    private lateinit var childGroup2: Group

    @BeforeEach
    fun setUp() {
        groupRepository = mockk()
        groupMemberRepository = mockk()
        groupService = GroupService(groupRepository, groupMemberRepository)

        // Test User
        testOwner = mockk(relaxed = true) {
            every { id } returns 1L
            every { email } returns "owner@example.com"
            every { name } returns "Owner"
        }

        testUser = mockk(relaxed = true) {
            every { id } returns 2L
            every { email } returns "user@example.com"
            every { name } returns "User"
        }

        // Test Groups
        rootGroup = mockk(relaxed = true) {
            every { id } returns 1L
            every { name } returns "Root Group"
            every { description } returns "Root group description"
            every { owner } returns testOwner
            every { parent } returns null
            every { groupType } returns GroupType.AUTONOMOUS
            every { university } returns "Test University"
        }

        childGroup1 = mockk(relaxed = true) {
            every { id } returns 2L
            every { name } returns "Child Group 1"
            every { description } returns "Child group 1 description"
            every { owner } returns testOwner
            every { parent } returns rootGroup
            every { groupType } returns GroupType.AUTONOMOUS
            every { university } returns "Test University"
        }

        childGroup2 = mockk(relaxed = true) {
            every { id } returns 3L
            every { name } returns "Child Group 2"
            every { description } returns "Child group 2 description"
            every { owner } returns testOwner
            every { parent } returns rootGroup
            every { groupType } returns GroupType.AUTONOMOUS
            every { university } returns "Test University"
        }
    }

    // ========== findById ==========

    @Test
    fun `findById should return group when group exists`() {
        // Given
        every { groupRepository.findById(1L) } returns Optional.of(rootGroup)

        // When
        val result = groupService.findById(1L)

        // Then
        assertThat(result).isNotNull
        assertThat(result?.id).isEqualTo(1L)
        assertThat(result?.name).isEqualTo("Root Group")
        verify(exactly = 1) { groupRepository.findById(1L) }
    }

    @Test
    fun `findById should return null when group does not exist`() {
        // Given
        every { groupRepository.findById(999L) } returns Optional.empty()

        // When
        val result = groupService.findById(999L)

        // Then
        assertThat(result).isNull()
        verify(exactly = 1) { groupRepository.findById(999L) }
    }

    // ========== getById ==========

    @Test
    fun `getById should return group when group exists`() {
        // Given
        every { groupRepository.findById(1L) } returns Optional.of(rootGroup)

        // When
        val result = groupService.getById(1L)

        // Then
        assertThat(result).isNotNull
        assertThat(result.id).isEqualTo(1L)
        assertThat(result.name).isEqualTo("Root Group")
        verify(exactly = 1) { groupRepository.findById(1L) }
    }

    @Test
    fun `getById should throw ResourceNotFoundException when group does not exist`() {
        // Given
        every { groupRepository.findById(999L) } returns Optional.empty()

        // When & Then
        assertThatThrownBy { groupService.getById(999L) }
            .isInstanceOf(ResourceNotFoundException::class.java)
            .hasMessageContaining("그룹을 찾을 수 없습니다: 999")

        verify(exactly = 1) { groupRepository.findById(999L) }
    }

    // ========== exists ==========

    @Test
    fun `exists should return true when group exists`() {
        // Given
        every { groupRepository.existsById(1L) } returns true

        // When
        val result = groupService.exists(1L)

        // Then
        assertThat(result).isTrue()
        verify(exactly = 1) { groupRepository.existsById(1L) }
    }

    @Test
    fun `exists should return false when group does not exist`() {
        // Given
        every { groupRepository.existsById(999L) } returns false

        // When
        val result = groupService.exists(999L)

        // Then
        assertThat(result).isFalse()
        verify(exactly = 1) { groupRepository.existsById(999L) }
    }

    // ========== getAncestors ==========

    @Test
    fun `getAncestors should return empty list when group has no parent`() {
        // Given
        every { groupRepository.findById(1L) } returns Optional.of(rootGroup)

        // When
        val result = groupService.getAncestors(1L)

        // Then
        assertThat(result).isEmpty()
        verify(exactly = 1) { groupRepository.findById(1L) }
    }

    @Test
    fun `getAncestors should return parent chain when group has ancestors`() {
        // Given
        val grandChildGroup = mockk<Group>(relaxed = true) {
            every { id } returns 4L
            every { name } returns "Grand Child Group"
            every { parent } returns childGroup1
        }

        every { groupRepository.findById(4L) } returns Optional.of(grandChildGroup)

        // When
        val result = groupService.getAncestors(4L)

        // Then
        assertThat(result).hasSize(2)
        assertThat(result[0].id).isEqualTo(2L) // childGroup1
        assertThat(result[1].id).isEqualTo(1L) // rootGroup
        verify(exactly = 1) { groupRepository.findById(4L) }
    }

    // ========== getChildren ==========

    @Test
    fun `getChildren should return children list`() {
        // Given
        every { groupRepository.findChildrenOrderByName(1L) } returns listOf(childGroup1, childGroup2)

        // When
        val result = groupService.getChildren(1L)

        // Then
        assertThat(result).hasSize(2)
        assertThat(result[0].id).isEqualTo(2L)
        assertThat(result[1].id).isEqualTo(3L)
        verify(exactly = 1) { groupRepository.findChildrenOrderByName(1L) }
    }

    @Test
    fun `getChildren should return empty list when no children exist`() {
        // Given
        every { groupRepository.findChildrenOrderByName(2L) } returns emptyList()

        // When
        val result = groupService.getChildren(2L)

        // Then
        assertThat(result).isEmpty()
        verify(exactly = 1) { groupRepository.findChildrenOrderByName(2L) }
    }

    // ========== isMember ==========

    @Test
    fun `isMember should return true when user is member`() {
        // Given
        every { groupMemberRepository.existsByGroupIdAndUserId(1L, 2L) } returns true

        // When
        val result = groupService.isMember(1L, 2L)

        // Then
        assertThat(result).isTrue()
        verify(exactly = 1) { groupMemberRepository.existsByGroupIdAndUserId(1L, 2L) }
    }

    @Test
    fun `isMember should return false when user is not member`() {
        // Given
        every { groupMemberRepository.existsByGroupIdAndUserId(1L, 999L) } returns false

        // When
        val result = groupService.isMember(1L, 999L)

        // Then
        assertThat(result).isFalse()
        verify(exactly = 1) { groupMemberRepository.existsByGroupIdAndUserId(1L, 999L) }
    }

    // ========== isOwner ==========

    @Test
    fun `isOwner should return true when user is owner`() {
        // Given
        every { groupRepository.findById(1L) } returns Optional.of(rootGroup)

        // When
        val result = groupService.isOwner(1L, 1L)

        // Then
        assertThat(result).isTrue()
        verify(exactly = 1) { groupRepository.findById(1L) }
    }

    @Test
    fun `isOwner should return false when user is not owner`() {
        // Given
        every { groupRepository.findById(1L) } returns Optional.of(rootGroup)

        // When
        val result = groupService.isOwner(1L, 2L)

        // Then
        assertThat(result).isFalse()
        verify(exactly = 1) { groupRepository.findById(1L) }
    }

    @Test
    fun `isOwner should return false when group does not exist`() {
        // Given
        every { groupRepository.findById(999L) } returns Optional.empty()

        // When
        val result = groupService.isOwner(999L, 1L)

        // Then
        assertThat(result).isFalse()
        verify(exactly = 1) { groupRepository.findById(999L) }
    }

    // ========== searchGroups ==========

    @Test
    fun `searchGroups should return page of groups matching keyword`() {
        // Given
        val pageable = PageRequest.of(0, 10)
        val groups = listOf(rootGroup, childGroup1)
        val page = PageImpl(groups, pageable, 2)
        every { groupRepository.searchByKeyword("Test", pageable) } returns page

        // When
        val result = groupService.searchGroups("Test", pageable)

        // Then
        assertThat(result.content).hasSize(2)
        assertThat(result.totalElements).isEqualTo(2)
        verify(exactly = 1) { groupRepository.searchByKeyword("Test", pageable) }
    }

    // ========== getGroupsByUniversity ==========

    @Test
    fun `getGroupsByUniversity should return groups by university and type`() {
        // Given
        every {
            groupRepository.findByUniversityAndGroupType("Test University", GroupType.AUTONOMOUS)
        } returns listOf(rootGroup, childGroup1)

        // When
        val result = groupService.getGroupsByUniversity("Test University", GroupType.AUTONOMOUS)

        // Then
        assertThat(result).hasSize(2)
        verify(exactly = 1) {
            groupRepository.findByUniversityAndGroupType("Test University", GroupType.AUTONOMOUS)
        }
    }

    // ========== getOwnedGroups ==========

    @Test
    fun `getOwnedGroups should return groups owned by user`() {
        // Given
        every { groupRepository.findByOwnerIdOrderByCreatedAtDesc(1L) } returns listOf(rootGroup, childGroup1)

        // When
        val result = groupService.getOwnedGroups(1L)

        // Then
        assertThat(result).hasSize(2)
        verify(exactly = 1) { groupRepository.findByOwnerIdOrderByCreatedAtDesc(1L) }
    }

    // ========== getRootGroups ==========

    @Test
    fun `getRootGroups should return groups without parent`() {
        // Given
        every { groupRepository.findByParentIdIsNull() } returns listOf(rootGroup)

        // When
        val result = groupService.getRootGroups()

        // Then
        assertThat(result).hasSize(1)
        assertThat(result[0].id).isEqualTo(1L)
        verify(exactly = 1) { groupRepository.findByParentIdIsNull() }
    }

    // ========== createGroup ==========

    @Test
    fun `createGroup should create group when name is unique`() {
        // Given
        val newGroup = mockk<Group>(relaxed = true) {
            every { id } returns 0L
            every { name } returns "New Group"
            every { parent } returns rootGroup
        }
        val savedGroup = mockk<Group>(relaxed = true) {
            every { id } returns 5L
            every { name } returns "New Group"
            every { parent } returns rootGroup
        }
        every { groupRepository.existsByParentIdAndName(1L, "New Group") } returns false
        every { groupRepository.save(newGroup) } returns savedGroup

        // When
        val result = groupService.createGroup(newGroup)

        // Then
        assertThat(result.id).isEqualTo(5L)
        verify(exactly = 1) { groupRepository.existsByParentIdAndName(1L, "New Group") }
        verify(exactly = 1) { groupRepository.save(newGroup) }
    }

    @Test
    fun `createGroup should throw IllegalArgumentException when name is duplicate`() {
        // Given
        val newGroup = mockk<Group>(relaxed = true) {
            every { name } returns "Root Group"
            every { parent } returns rootGroup
        }
        every { groupRepository.existsByParentIdAndName(1L, "Root Group") } returns true

        // When & Then
        assertThatThrownBy { groupService.createGroup(newGroup) }
            .isInstanceOf(IllegalArgumentException::class.java)
            .hasMessageContaining("이미 존재하는 그룹 이름입니다: Root Group")

        verify(exactly = 1) { groupRepository.existsByParentIdAndName(1L, "Root Group") }
        verify(exactly = 0) { groupRepository.save(any()) }
    }

    // ========== updateGroup ==========

    @Test
    fun `updateGroup should update group successfully`() {
        // Given
        val updatedGroup = rootGroup.copy(name = "Updated Group")
        every { groupRepository.findById(1L) } returns Optional.of(rootGroup)
        every { groupRepository.save(any()) } returns updatedGroup

        // When
        groupService.updateGroup(1L) { _ ->
            // Update logic (실제로는 Group이 data class이므로 직접 수정 불가)
        }

        // Then
        verify(exactly = 1) { groupRepository.findById(1L) }
        verify(exactly = 1) { groupRepository.save(any()) }
    }

    // ========== deleteGroup ==========

    @Test
    fun `deleteGroup should delete group when no children exist`() {
        // Given
        every { groupRepository.findById(2L) } returns Optional.of(childGroup1)
        every { groupRepository.findChildrenOrderByName(2L) } returns emptyList()
        every { groupRepository.delete(childGroup1) } returns Unit

        // When
        groupService.deleteGroup(2L)

        // Then
        verify(exactly = 1) { groupRepository.findById(2L) }
        verify(exactly = 1) { groupRepository.findChildrenOrderByName(2L) }
        verify(exactly = 1) { groupRepository.delete(childGroup1) }
    }

    @Test
    fun `deleteGroup should throw IllegalStateException when children exist`() {
        // Given
        every { groupRepository.findById(1L) } returns Optional.of(rootGroup)
        every { groupRepository.findChildrenOrderByName(1L) } returns listOf(childGroup1, childGroup2)

        // When & Then
        assertThatThrownBy { groupService.deleteGroup(1L) }
            .isInstanceOf(IllegalStateException::class.java)
            .hasMessageContaining("하위 그룹이 있어 삭제할 수 없습니다")

        verify(exactly = 1) { groupRepository.findById(1L) }
        verify(exactly = 1) { groupRepository.findChildrenOrderByName(1L) }
        verify(exactly = 0) { groupRepository.delete(any()) }
    }
}
