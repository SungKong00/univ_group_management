package com.univgroup.domain.workspace.service

import com.univgroup.domain.group.entity.Group
import com.univgroup.domain.group.entity.GroupType
import com.univgroup.domain.user.entity.User
import com.univgroup.domain.workspace.entity.Workspace
import com.univgroup.domain.workspace.repository.ChannelRepository
import com.univgroup.domain.workspace.repository.WorkspaceRepository
import com.univgroup.shared.exception.ResourceNotFoundException
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.assertj.core.api.Assertions.assertThat
import org.assertj.core.api.Assertions.assertThatThrownBy
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Test
import java.util.*

@DisplayName("WorkspaceService 단위 테스트")
class WorkspaceServiceTest {
    private lateinit var workspaceService: WorkspaceService
    private lateinit var workspaceRepository: WorkspaceRepository
    private lateinit var channelRepository: ChannelRepository

    // Test Entities
    private lateinit var testUser: User
    private lateinit var testGroup: Group
    private lateinit var workspace1: Workspace
    private lateinit var workspace2: Workspace

    @BeforeEach
    fun setUp() {
        workspaceRepository = mockk()
        channelRepository = mockk()
        workspaceService = WorkspaceService(workspaceRepository, channelRepository)

        // Test User
        testUser = mockk(relaxed = true) {
            every { id } returns 1L
            every { email } returns "user@example.com"
            every { name } returns "User"
        }

        // Test Group
        testGroup = mockk(relaxed = true) {
            every { id } returns 1L
            every { name } returns "Test Group"
            every { owner } returns testUser
            every { groupType } returns GroupType.AUTONOMOUS
        }

        // Test Workspaces
        workspace1 = mockk(relaxed = true) {
            every { id } returns 1L
            every { name } returns "Workspace 1"
            every { description } returns "Workspace 1 description"
            every { group } returns testGroup
            every { displayOrder } returns 0
        }

        workspace2 = mockk(relaxed = true) {
            every { id } returns 2L
            every { name } returns "Workspace 2"
            every { description } returns "Workspace 2 description"
            every { group } returns testGroup
            every { displayOrder } returns 1
        }
    }

    // ========== findById ==========

    @Test
    fun `findById should return workspace when workspace exists`() {
        // Given
        every { workspaceRepository.findById(1L) } returns Optional.of(workspace1)

        // When
        val result = workspaceService.findById(1L)

        // Then
        assertThat(result).isNotNull
        assertThat(result?.id).isEqualTo(1L)
        assertThat(result?.name).isEqualTo("Workspace 1")
        verify(exactly = 1) { workspaceRepository.findById(1L) }
    }

    @Test
    fun `findById should return null when workspace does not exist`() {
        // Given
        every { workspaceRepository.findById(999L) } returns Optional.empty()

        // When
        val result = workspaceService.findById(999L)

        // Then
        assertThat(result).isNull()
        verify(exactly = 1) { workspaceRepository.findById(999L) }
    }

    // ========== getById ==========

    @Test
    fun `getById should return workspace when workspace exists`() {
        // Given
        every { workspaceRepository.findById(1L) } returns Optional.of(workspace1)

        // When
        val result = workspaceService.getById(1L)

        // Then
        assertThat(result).isNotNull
        assertThat(result.id).isEqualTo(1L)
        assertThat(result.name).isEqualTo("Workspace 1")
        verify(exactly = 1) { workspaceRepository.findById(1L) }
    }

    @Test
    fun `getById should throw ResourceNotFoundException when workspace does not exist`() {
        // Given
        every { workspaceRepository.findById(999L) } returns Optional.empty()

        // When & Then
        assertThatThrownBy { workspaceService.getById(999L) }
            .isInstanceOf(ResourceNotFoundException::class.java)
            .hasMessageContaining("워크스페이스를 찾을 수 없습니다: 999")

        verify(exactly = 1) { workspaceRepository.findById(999L) }
    }

    // ========== getWorkspacesByGroup ==========

    @Test
    fun `getWorkspacesByGroup should return workspaces ordered by displayOrder`() {
        // Given
        every { workspaceRepository.findByGroupIdOrderByDisplayOrder(1L) } returns listOf(workspace1, workspace2)

        // When
        val result = workspaceService.getWorkspacesByGroup(1L)

        // Then
        assertThat(result).hasSize(2)
        assertThat(result[0].id).isEqualTo(1L)
        assertThat(result[1].id).isEqualTo(2L)
        verify(exactly = 1) { workspaceRepository.findByGroupIdOrderByDisplayOrder(1L) }
    }

    @Test
    fun `getWorkspacesByGroup should return empty list when no workspaces exist`() {
        // Given
        every { workspaceRepository.findByGroupIdOrderByDisplayOrder(999L) } returns emptyList()

        // When
        val result = workspaceService.getWorkspacesByGroup(999L)

        // Then
        assertThat(result).isEmpty()
        verify(exactly = 1) { workspaceRepository.findByGroupIdOrderByDisplayOrder(999L) }
    }

    // ========== getDefaultWorkspace ==========

    @Test
    fun `getDefaultWorkspace should return first workspace`() {
        // Given
        every { workspaceRepository.findByGroupIdOrderByDisplayOrder(1L) } returns listOf(workspace1, workspace2)

        // When
        val result = workspaceService.getDefaultWorkspace(1L)

        // Then
        assertThat(result).isNotNull
        assertThat(result?.id).isEqualTo(1L)
        verify(exactly = 1) { workspaceRepository.findByGroupIdOrderByDisplayOrder(1L) }
    }

    @Test
    fun `getDefaultWorkspace should return null when no workspaces exist`() {
        // Given
        every { workspaceRepository.findByGroupIdOrderByDisplayOrder(999L) } returns emptyList()

        // When
        val result = workspaceService.getDefaultWorkspace(999L)

        // Then
        assertThat(result).isNull()
        verify(exactly = 1) { workspaceRepository.findByGroupIdOrderByDisplayOrder(999L) }
    }

    // ========== createWorkspace ==========

    @Test
    fun `createWorkspace should create workspace when name is unique`() {
        // Given
        val newWorkspace = mockk<Workspace>(relaxed = true) {
            every { id } returns 0L
            every { name } returns "New Workspace"
            every { group } returns testGroup
        }
        val savedWorkspace = mockk<Workspace>(relaxed = true) {
            every { id } returns 3L
            every { name } returns "New Workspace"
            every { group } returns testGroup
        }
        every { workspaceRepository.existsByGroupIdAndName(1L, "New Workspace") } returns false
        every { workspaceRepository.save(newWorkspace) } returns savedWorkspace

        // When
        val result = workspaceService.createWorkspace(newWorkspace)

        // Then
        assertThat(result.id).isEqualTo(3L)
        verify(exactly = 1) { workspaceRepository.existsByGroupIdAndName(1L, "New Workspace") }
        verify(exactly = 1) { workspaceRepository.save(newWorkspace) }
    }

    @Test
    fun `createWorkspace should throw IllegalArgumentException when name is duplicate`() {
        // Given
        val newWorkspace = mockk<Workspace>(relaxed = true) {
            every { name } returns "Workspace 1"
            every { group } returns testGroup
        }
        every { workspaceRepository.existsByGroupIdAndName(1L, "Workspace 1") } returns true

        // When & Then
        assertThatThrownBy { workspaceService.createWorkspace(newWorkspace) }
            .isInstanceOf(IllegalArgumentException::class.java)
            .hasMessageContaining("이미 존재하는 워크스페이스 이름입니다: Workspace 1")

        verify(exactly = 1) { workspaceRepository.existsByGroupIdAndName(1L, "Workspace 1") }
        verify(exactly = 0) { workspaceRepository.save(any()) }
    }

    // ========== updateWorkspace ==========

    @Test
    fun `updateWorkspace should update workspace successfully`() {
        // Given
        val updatedWorkspace = workspace1
        every { workspaceRepository.findById(1L) } returns Optional.of(workspace1)
        every { workspaceRepository.save(any()) } returns updatedWorkspace

        // When
        workspaceService.updateWorkspace(1L) { _ ->
            // Update logic
        }

        // Then
        verify(exactly = 1) { workspaceRepository.findById(1L) }
        verify(exactly = 1) { workspaceRepository.save(any()) }
    }

    // ========== deleteWorkspace ==========

    @Test
    fun `deleteWorkspace should delete workspace when not last workspace`() {
        // Given
        every { workspaceRepository.findById(1L) } returns Optional.of(workspace1)
        every { workspaceRepository.countByGroupId(1L) } returns 2L
        every { channelRepository.deleteAllByWorkspaceId(1L) } returns Unit
        every { workspaceRepository.delete(workspace1) } returns Unit

        // When
        workspaceService.deleteWorkspace(1L)

        // Then
        verify(exactly = 1) { workspaceRepository.findById(1L) }
        verify(exactly = 1) { workspaceRepository.countByGroupId(1L) }
        verify(exactly = 1) { channelRepository.deleteAllByWorkspaceId(1L) }
        verify(exactly = 1) { workspaceRepository.delete(workspace1) }
    }

    @Test
    fun `deleteWorkspace should throw IllegalStateException when last workspace`() {
        // Given
        every { workspaceRepository.findById(1L) } returns Optional.of(workspace1)
        every { workspaceRepository.countByGroupId(1L) } returns 1L

        // When & Then
        assertThatThrownBy { workspaceService.deleteWorkspace(1L) }
            .isInstanceOf(IllegalStateException::class.java)
            .hasMessageContaining("마지막 워크스페이스는 삭제할 수 없습니다")

        verify(exactly = 1) { workspaceRepository.findById(1L) }
        verify(exactly = 1) { workspaceRepository.countByGroupId(1L) }
        verify(exactly = 0) { channelRepository.deleteAllByWorkspaceId(any()) }
        verify(exactly = 0) { workspaceRepository.delete(any()) }
    }

    // ========== getWorkspaceCount ==========

    @Test
    fun `getWorkspaceCount should return workspace count`() {
        // Given
        every { workspaceRepository.countByGroupId(1L) } returns 2L

        // When
        val result = workspaceService.getWorkspaceCount(1L)

        // Then
        assertThat(result).isEqualTo(2L)
        verify(exactly = 1) { workspaceRepository.countByGroupId(1L) }
    }

    // ========== getChannelCount ==========

    @Test
    fun `getChannelCount should return channel count`() {
        // Given
        every { channelRepository.countByWorkspaceId(1L) } returns 5L

        // When
        val result = workspaceService.getChannelCount(1L)

        // Then
        assertThat(result).isEqualTo(5L)
        verify(exactly = 1) { channelRepository.countByWorkspaceId(1L) }
    }
}
