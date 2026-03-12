package com.univgroup.domain.workspace.entity

import com.univgroup.domain.group.entity.Group
import com.univgroup.domain.user.entity.User
import io.mockk.every
import io.mockk.mockk
import org.assertj.core.api.Assertions.assertThat
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Test
import java.time.LocalDateTime

@DisplayName("Channel Entity 테스트")
class ChannelTest {
    private lateinit var testUser: User
    private lateinit var testGroup: Group
    private lateinit var testWorkspace: Workspace

    @BeforeEach
    fun setUp() {
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
        }

        // Test Workspace
        testWorkspace = mockk(relaxed = true) {
            every { id } returns 1L
            every { name } returns "Test Workspace"
            every { group } returns testGroup
        }
    }

    // ========== Entity 기본 속성 ==========

    @Test
    fun `Channel should have correct properties`() {
        // Given
        val createdAt = LocalDateTime.now()
        val channel = Channel(
            id = 1L,
            group = testGroup,
            workspace = testWorkspace,
            name = "General",
            description = "General channel",
            type = ChannelType.TEXT,
            displayOrder = 0,
            createdBy = testUser,
            createdAt = createdAt,
        )

        // Then
        assertThat(channel.id).isEqualTo(1L)
        assertThat(channel.group).isEqualTo(testGroup)
        assertThat(channel.workspace).isEqualTo(testWorkspace)
        assertThat(channel.name).isEqualTo("General")
        assertThat(channel.description).isEqualTo("General channel")
        assertThat(channel.type).isEqualTo(ChannelType.TEXT)
        assertThat(channel.displayOrder).isEqualTo(0)
        assertThat(channel.createdBy).isEqualTo(testUser)
        assertThat(channel.createdAt).isEqualTo(createdAt)
    }

    // ========== 채널 타입 ==========

    @Test
    fun `Channel should support TEXT type`() {
        // Given
        val channel = Channel(
            id = 1L,
            group = testGroup,
            workspace = testWorkspace,
            name = "General",
            type = ChannelType.TEXT,
            displayOrder = 0,
            createdBy = testUser,
        )

        // Then
        assertThat(channel.type).isEqualTo(ChannelType.TEXT)
    }

    @Test
    fun `Channel should support ANNOUNCEMENT type`() {
        // Given
        val channel = Channel(
            id = 1L,
            group = testGroup,
            workspace = testWorkspace,
            name = "Announcements",
            type = ChannelType.ANNOUNCEMENT,
            displayOrder = 0,
            createdBy = testUser,
        )

        // Then
        assertThat(channel.type).isEqualTo(ChannelType.ANNOUNCEMENT)
    }

    @Test
    fun `Channel should support VOICE type`() {
        // Given
        val channel = Channel(
            id = 1L,
            group = testGroup,
            workspace = testWorkspace,
            name = "Voice",
            type = ChannelType.VOICE,
            displayOrder = 0,
            createdBy = testUser,
        )

        // Then
        assertThat(channel.type).isEqualTo(ChannelType.VOICE)
    }

    // ========== 이름/설명 변경 ==========

    @Test
    fun `should allow changing channel name`() {
        // Given
        val channel = Channel(
            id = 1L,
            group = testGroup,
            workspace = testWorkspace,
            name = "General",
            displayOrder = 0,
            createdBy = testUser,
        )

        // When
        val updatedChannel = channel.copy(name = "Updated General")

        // Then
        assertThat(updatedChannel.name).isEqualTo("Updated General")
    }

    @Test
    fun `should allow changing channel description`() {
        // Given
        val channel = Channel(
            id = 1L,
            group = testGroup,
            workspace = testWorkspace,
            name = "General",
            description = "Old description",
            displayOrder = 0,
            createdBy = testUser,
        )

        // When
        val updatedChannel = channel.copy(description = "New description")

        // Then
        assertThat(updatedChannel.description).isEqualTo("New description")
    }

    @Test
    fun `should allow changing display order`() {
        // Given
        val channel = Channel(
            id = 1L,
            group = testGroup,
            workspace = testWorkspace,
            name = "General",
            displayOrder = 0,
            createdBy = testUser,
        )

        // When
        val updatedChannel = channel.copy(displayOrder = 10)

        // Then
        assertThat(updatedChannel.displayOrder).isEqualTo(10)
    }

    // ========== equals/hashCode ==========

    @Test
    fun `equals should return true for same id`() {
        // Given
        val channel1 = Channel(
            id = 1L,
            group = testGroup,
            workspace = testWorkspace,
            name = "General",
            displayOrder = 0,
            createdBy = testUser,
        )
        val channel2 = Channel(
            id = 1L,
            group = testGroup,
            workspace = testWorkspace,
            name = "Other",
            displayOrder = 1,
            createdBy = testUser,
        )

        // Then
        assertThat(channel1).isEqualTo(channel2)
        assertThat(channel1.hashCode()).isEqualTo(channel2.hashCode())
    }

    @Test
    fun `equals should return false for different id`() {
        // Given
        val channel1 = Channel(
            id = 1L,
            group = testGroup,
            workspace = testWorkspace,
            name = "General",
            displayOrder = 0,
            createdBy = testUser,
        )
        val channel2 = Channel(
            id = 2L,
            group = testGroup,
            workspace = testWorkspace,
            name = "General",
            displayOrder = 0,
            createdBy = testUser,
        )

        // Then
        assertThat(channel1).isNotEqualTo(channel2)
    }

    @Test
    fun `equals should return false when id is 0`() {
        // Given
        val channel1 = Channel(
            id = 0L,
            group = testGroup,
            workspace = testWorkspace,
            name = "General",
            displayOrder = 0,
            createdBy = testUser,
        )
        val channel2 = Channel(
            id = 0L,
            group = testGroup,
            workspace = testWorkspace,
            name = "General",
            displayOrder = 0,
            createdBy = testUser,
        )

        // Then
        assertThat(channel1).isNotEqualTo(channel2)
    }
}
