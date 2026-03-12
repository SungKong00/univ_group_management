package com.univgroup.domain.group.entity

import com.univgroup.domain.permission.GroupPermission
import com.univgroup.domain.user.entity.User
import io.mockk.every
import io.mockk.mockk
import org.assertj.core.api.Assertions.assertThat
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Test
import java.time.LocalDateTime

@DisplayName("GroupMember Entity 테스트")
class GroupMemberTest {
    private lateinit var testUser: User
    private lateinit var testOwner: User
    private lateinit var testGroup: Group
    private lateinit var ownerRole: GroupRole
    private lateinit var memberRole: GroupRole

    @BeforeEach
    fun setUp() {
        // Test Users
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

        // Test Group
        testGroup = mockk(relaxed = true) {
            every { id } returns 1L
            every { name } returns "Test Group"
            every { owner } returns testOwner
        }

        // Test Roles
        ownerRole = mockk(relaxed = true) {
            every { id } returns 1L
            every { name } returns "그룹장"
            every { isSystemRole } returns true
            every { permissions } returns mutableSetOf(
                GroupPermission.GROUP_MANAGE,
                GroupPermission.ADMIN_MANAGE,
                GroupPermission.MEMBER_MANAGE,
                GroupPermission.CHANNEL_MANAGE,
            )
        }

        memberRole = mockk(relaxed = true) {
            every { id } returns 2L
            every { name } returns "멤버"
            every { isSystemRole } returns true
            every { permissions } returns mutableSetOf(
                GroupPermission.CHANNEL_READ,
                GroupPermission.POST_MANAGE,
            )
        }
    }

    // ========== Entity 기본 속성 ==========

    @Test
    fun `GroupMember should have correct properties`() {
        // Given
        val joinedAt = LocalDateTime.now()
        val groupMember = GroupMember(
            id = 1L,
            group = testGroup,
            user = testUser,
            role = memberRole,
            joinedAt = joinedAt,
        )

        // Then
        assertThat(groupMember.id).isEqualTo(1L)
        assertThat(groupMember.group).isEqualTo(testGroup)
        assertThat(groupMember.user).isEqualTo(testUser)
        assertThat(groupMember.role).isEqualTo(memberRole)
        assertThat(groupMember.joinedAt).isEqualTo(joinedAt)
    }

    // ========== 역할 변경 ==========

    @Test
    fun `should allow changing member role`() {
        // Given
        val groupMember = GroupMember(
            id = 1L,
            group = testGroup,
            user = testUser,
            role = memberRole,
        )

        // When
        val updatedMember = groupMember.copy(role = ownerRole)

        // Then
        assertThat(updatedMember.role).isEqualTo(ownerRole)
        assertThat(updatedMember.role.name).isEqualTo("그룹장")
    }

    // ========== equals/hashCode ==========

    @Test
    fun `equals should return true for same id`() {
        // Given
        val member1 = GroupMember(
            id = 1L,
            group = testGroup,
            user = testUser,
            role = memberRole,
        )
        val member2 = GroupMember(
            id = 1L,
            group = testGroup,
            user = testUser,
            role = ownerRole,
        )

        // Then
        assertThat(member1).isEqualTo(member2)
        assertThat(member1.hashCode()).isEqualTo(member2.hashCode())
    }

    @Test
    fun `equals should return false for different id`() {
        // Given
        val member1 = GroupMember(
            id = 1L,
            group = testGroup,
            user = testUser,
            role = memberRole,
        )
        val member2 = GroupMember(
            id = 2L,
            group = testGroup,
            user = testUser,
            role = memberRole,
        )

        // Then
        assertThat(member1).isNotEqualTo(member2)
    }

    @Test
    fun `equals should return false when id is 0`() {
        // Given
        val member1 = GroupMember(
            id = 0L,
            group = testGroup,
            user = testUser,
            role = memberRole,
        )
        val member2 = GroupMember(
            id = 0L,
            group = testGroup,
            user = testUser,
            role = memberRole,
        )

        // Then
        assertThat(member1).isNotEqualTo(member2)
    }
}
