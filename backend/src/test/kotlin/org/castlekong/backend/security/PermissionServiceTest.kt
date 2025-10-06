package org.castlekong.backend.security

import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.assertj.core.api.Assertions.assertThat
import org.assertj.core.api.Assertions.assertThatThrownBy
import org.castlekong.backend.entity.Group
import org.castlekong.backend.entity.GroupPermission
import org.castlekong.backend.entity.GroupRole
import org.castlekong.backend.entity.User
import org.castlekong.backend.exception.BusinessException
import org.castlekong.backend.exception.ErrorCode
import org.castlekong.backend.fixture.TestDataFactory
import org.castlekong.backend.repository.GroupMemberRepository
import org.castlekong.backend.repository.GroupRepository
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Test
import java.util.Optional

@DisplayName("PermissionService 단위 테스트")
class PermissionServiceTest {
    private lateinit var permissionService: PermissionService
    private lateinit var groupRepository: GroupRepository
    private lateinit var groupMemberRepository: GroupMemberRepository

    private lateinit var testGroup: Group
    private lateinit var testUser: User
    private lateinit var ownerRole: GroupRole
    private lateinit var advisorRole: GroupRole
    private lateinit var memberRole: GroupRole

    @BeforeEach
    fun setUp() {
        groupRepository = mockk()
        groupMemberRepository = mockk()
        permissionService = PermissionService(groupRepository, groupMemberRepository)

        // 테스트 데이터 설정
        testUser = TestDataFactory.createTestUser(id = 1L)
        testGroup = TestDataFactory.createTestGroup(id = 1L, owner = testUser)

        // data class 제거로 copy 불가 → apply 로 id 지정
        ownerRole = TestDataFactory.createOwnerRole(testGroup).apply { id = 1L }
        advisorRole = TestDataFactory.createAdvisorRole(testGroup).apply { id = 2L }
        memberRole = TestDataFactory.createMemberRole(testGroup).apply { id = 3L }
    }

    // === 권한 계산 테스트 ===

    @Test
    @DisplayName("OWNER 역할은 모든 권한을 가진다")
    fun getEffective_OwnerRole_HasAllPermissions() {
        // Given
        val groupMember =
            TestDataFactory.createTestGroupMember(
                group = testGroup,
                user = testUser,
                role = ownerRole,
            )

        every { groupRepository.findById(testGroup.id) } returns Optional.of(testGroup)
        every { groupMemberRepository.findByGroupIdAndUserId(testGroup.id, testUser.id) } returns
            Optional.of(
                groupMember,
            )

        val systemRolePermissions: (String) -> Set<GroupPermission> = { roleName ->
            when (roleName.uppercase()) {
                "OWNER" -> GroupPermission.entries.toSet()
                "ADVISOR" -> GroupPermission.entries.toSet()
                else -> emptySet()
            }
        }

        // When
        val permissions = permissionService.getEffective(testGroup.id, testUser.id, systemRolePermissions)

        // Then
        assertThat(permissions).isEqualTo(GroupPermission.entries.toSet())
    }

    @Test
    @DisplayName("ADVISOR 역할은 모든 권한을 가진다")
    fun getEffective_AdvisorRole_HasAllPermissions() {
        // Given
        val groupMember =
            TestDataFactory.createTestGroupMember(
                group = testGroup,
                user = testUser,
                role = advisorRole,
            )

        every { groupRepository.findById(testGroup.id) } returns Optional.of(testGroup)
        every { groupMemberRepository.findByGroupIdAndUserId(testGroup.id, testUser.id) } returns
            Optional.of(
                groupMember,
            )

        val systemRolePermissions: (String) -> Set<GroupPermission> = { roleName ->
            when (roleName.uppercase()) {
                "OWNER" -> GroupPermission.entries.toSet()
                "ADVISOR" -> GroupPermission.entries.toSet()
                else -> emptySet()
            }
        }

        // When
        val permissions = permissionService.getEffective(testGroup.id, testUser.id, systemRolePermissions)

        // Then
        assertThat(permissions).isEqualTo(GroupPermission.entries.toSet())
    }

    @Test
    @DisplayName("MEMBER 역할은 기본 권한이 없다")
    fun getEffective_MemberRole_HasNoPermissions() {
        // Given
        val groupMember =
            TestDataFactory.createTestGroupMember(
                group = testGroup,
                user = testUser,
                role = memberRole,
            )

        every { groupRepository.findById(testGroup.id) } returns Optional.of(testGroup)
        every { groupMemberRepository.findByGroupIdAndUserId(testGroup.id, testUser.id) } returns
            Optional.of(
                groupMember,
            )

        val systemRolePermissions: (String) -> Set<GroupPermission> = { roleName ->
            when (roleName.uppercase()) {
                "OWNER" -> GroupPermission.entries.toSet()
                "ADVISOR" -> GroupPermission.entries.toSet()
                "MEMBER" -> emptySet()
                else -> emptySet()
            }
        }

        // When
        val permissions = permissionService.getEffective(testGroup.id, testUser.id, systemRolePermissions)

        // Then
        assertThat(permissions).isEmpty()
    }

    @Test
    @DisplayName("커스텀 역할은 정의된 권한만 가진다")
    fun getEffective_CustomRole_HasDefinedPermissions() {
        // Given
        val customPermissions = setOf(GroupPermission.CHANNEL_MANAGE, GroupPermission.ADMIN_MANAGE)
        // copy 제거 → 팩토리 직접 사용하여 id 설정
        val customRole =
            TestDataFactory.createTestGroupRole(
                id = 4L,
                group = testGroup,
                name = "MODERATOR",
                isSystemRole = false,
                permissions = customPermissions,
                priority = 50,
            )

        val groupMember =
            TestDataFactory.createTestGroupMember(
                group = testGroup,
                user = testUser,
                role = customRole,
            )

        every { groupRepository.findById(testGroup.id) } returns Optional.of(testGroup)
        every { groupMemberRepository.findByGroupIdAndUserId(testGroup.id, testUser.id) } returns
            Optional.of(
                groupMember,
            )

        val systemRolePermissions: (String) -> Set<GroupPermission> = { emptySet() }

        // When
        val permissions = permissionService.getEffective(testGroup.id, testUser.id, systemRolePermissions)

        // Then
        assertThat(permissions).isEqualTo(customPermissions)
    }

    @Test
    @DisplayName("그룹이 존재하지 않으면 예외가 발생한다")
    fun getEffective_GroupNotFound_ThrowsException() {
        // Given
        every { groupRepository.findById(testGroup.id) } returns Optional.empty()

        val systemRolePermissions: (String) -> Set<GroupPermission> = { emptySet() }

        // When & Then
        assertThatThrownBy {
            permissionService.getEffective(testGroup.id, testUser.id, systemRolePermissions)
        }
            .isInstanceOf(BusinessException::class.java)
            .hasFieldOrPropertyWithValue("errorCode", ErrorCode.GROUP_NOT_FOUND)
    }

    @Test
    @DisplayName("그룹 멤버가 아니면 예외가 발생한다")
    fun getEffective_NotGroupMember_ThrowsException() {
        // Given
        every { groupRepository.findById(testGroup.id) } returns Optional.of(testGroup)
        every { groupMemberRepository.findByGroupIdAndUserId(testGroup.id, testUser.id) } returns Optional.empty()

        val systemRolePermissions: (String) -> Set<GroupPermission> = { emptySet() }

        // When & Then
        assertThatThrownBy {
            permissionService.getEffective(testGroup.id, testUser.id, systemRolePermissions)
        }
            .isInstanceOf(BusinessException::class.java)
            .hasFieldOrPropertyWithValue("errorCode", ErrorCode.GROUP_MEMBER_NOT_FOUND)
    }

    // === 캐시 테스트 ===

    @Test
    @DisplayName("권한은 캐시에 저장된다")
    fun getEffective_UsesCaching() {
        // Given
        val groupMember =
            TestDataFactory.createTestGroupMember(
                group = testGroup,
                user = testUser,
                role = ownerRole,
            )

        every { groupRepository.findById(testGroup.id) } returns Optional.of(testGroup)
        every { groupMemberRepository.findByGroupIdAndUserId(testGroup.id, testUser.id) } returns
            Optional.of(
                groupMember,
            )

        val systemRolePermissions: (String) -> Set<GroupPermission> = {
            GroupPermission.entries.toSet()
        }

        // When - 첫 번째 호출
        permissionService.getEffective(testGroup.id, testUser.id, systemRolePermissions)

        // 두 번째 호출
        permissionService.getEffective(testGroup.id, testUser.id, systemRolePermissions)

        // Then - Repository는 한 번만 호출되어야 함 (캐시 사용)
        verify(exactly = 1) { groupRepository.findById(testGroup.id) }
        verify(exactly = 1) { groupMemberRepository.findByGroupIdAndUserId(testGroup.id, testUser.id) }
    }

    @Test
    @DisplayName("개별 사용자 권한 무효화가 동작한다")
    fun invalidate_Individual_WorksCorrectly() {
        // Given
        val groupMember =
            TestDataFactory.createTestGroupMember(
                group = testGroup,
                user = testUser,
                role = ownerRole,
            )

        every { groupRepository.findById(testGroup.id) } returns Optional.of(testGroup)
        every { groupMemberRepository.findByGroupIdAndUserId(testGroup.id, testUser.id) } returns
            Optional.of(
                groupMember,
            )

        val systemRolePermissions: (String) -> Set<GroupPermission> = {
            GroupPermission.entries.toSet()
        }

        // When
        permissionService.getEffective(testGroup.id, testUser.id, systemRolePermissions)
        permissionService.invalidate(testGroup.id, testUser.id) // 캐시 무효화
        permissionService.getEffective(testGroup.id, testUser.id, systemRolePermissions)

        // Then - Repository가 두 번 호출되어야 함 (캐시 무효화 후 재조회)
        verify(exactly = 2) { groupRepository.findById(testGroup.id) }
        verify(exactly = 2) { groupMemberRepository.findByGroupIdAndUserId(testGroup.id, testUser.id) }
    }

    @Test
    @DisplayName("그룹 전체 권한 무효화가 동작한다")
    fun invalidateGroup_WorksCorrectly() {
        // Given
        val user1 = testUser
        val user2 = TestDataFactory.createTestUser(id = 2L, email = "user2@example.com")

        val groupMember1 =
            TestDataFactory.createTestGroupMember(
                group = testGroup,
                user = user1,
                role = ownerRole,
            )

        val groupMember2 =
            TestDataFactory.createTestGroupMember(
                group = testGroup,
                user = user2,
                role = memberRole,
            )

        every { groupRepository.findById(testGroup.id) } returns Optional.of(testGroup)
        every { groupMemberRepository.findByGroupIdAndUserId(testGroup.id, user1.id) } returns Optional.of(groupMember1)
        every { groupMemberRepository.findByGroupIdAndUserId(testGroup.id, user2.id) } returns Optional.of(groupMember2)

        val systemRolePermissions: (String) -> Set<GroupPermission> = { roleName ->
            when (roleName.uppercase()) {
                "OWNER" -> GroupPermission.entries.toSet()
                else -> emptySet()
            }
        }

        // When
        permissionService.getEffective(testGroup.id, user1.id, systemRolePermissions)
        permissionService.getEffective(testGroup.id, user2.id, systemRolePermissions)

        permissionService.invalidateGroup(testGroup.id) // 그룹 전체 캐시 무효화

        permissionService.getEffective(testGroup.id, user1.id, systemRolePermissions)
        permissionService.getEffective(testGroup.id, user2.id, systemRolePermissions)

        // Then - 각 사용자별로 두 번씩 Repository 호출되어야 함
        verify(exactly = 2) { groupMemberRepository.findByGroupIdAndUserId(testGroup.id, user1.id) }
        verify(exactly = 2) { groupMemberRepository.findByGroupIdAndUserId(testGroup.id, user2.id) }
    }
}
