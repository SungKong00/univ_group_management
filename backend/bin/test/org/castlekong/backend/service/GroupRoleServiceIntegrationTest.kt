package org.castlekong.backend.service

import org.assertj.core.api.Assertions.assertThat
import org.assertj.core.api.Assertions.assertThatThrownBy
import org.castlekong.backend.dto.CreateGroupRoleRequest
import org.castlekong.backend.dto.UpdateGroupRoleRequest
import org.castlekong.backend.entity.Group
import org.castlekong.backend.entity.GroupPermission
import org.castlekong.backend.entity.GroupRole
import org.castlekong.backend.entity.User
import org.castlekong.backend.exception.BusinessException
import org.castlekong.backend.exception.ErrorCode
import org.castlekong.backend.fixture.TestDataFactory
import org.castlekong.backend.repository.GroupMemberRepository
import org.castlekong.backend.repository.GroupRepository
import org.castlekong.backend.repository.GroupRoleRepository
import org.castlekong.backend.repository.UserRepository
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.test.context.ActiveProfiles
import org.springframework.transaction.annotation.Transactional

@SpringBootTest
@ActiveProfiles("test")
@Transactional
class GroupRoleServiceIntegrationTest {
    @Autowired
    private lateinit var groupRoleService: GroupRoleService

    @Autowired
    private lateinit var userRepository: UserRepository

    @Autowired
    private lateinit var groupRepository: GroupRepository

    @Autowired
    private lateinit var groupRoleRepository: GroupRoleRepository

    @Autowired
    private lateinit var groupMemberRepository: GroupMemberRepository

    private lateinit var owner: User
    private lateinit var member: User
    private lateinit var group: Group

    @BeforeEach
    fun setUp() {
        val ownerBase =
            TestDataFactory.createTestUser(
                name = "그룹장",
                email = TestDataFactory.uniqueEmail("owner-role"),
            )
        owner =
            userRepository.save(
                User(
                    id = ownerBase.id,
                    name = ownerBase.name,
                    email = ownerBase.email,
                    password = ownerBase.password,
                    globalRole = ownerBase.globalRole,
                    isActive = ownerBase.isActive,
                    nickname = ownerBase.nickname,
                    profileImageUrl = ownerBase.profileImageUrl,
                    bio = ownerBase.bio,
                    profileCompleted = true,
                    emailVerified = ownerBase.emailVerified,
                    college = ownerBase.college,
                    department = ownerBase.department,
                    studentNo = ownerBase.studentNo,
                    schoolEmail = ownerBase.schoolEmail,
                    professorStatus = ownerBase.professorStatus,
                    academicYear = ownerBase.academicYear,
                    createdAt = ownerBase.createdAt,
                    updatedAt = ownerBase.updatedAt,
                ),
            )

        member =
            userRepository.save(
                TestDataFactory.createStudentUser(
                    name = "구성원",
                    email = TestDataFactory.uniqueEmail("member-role"),
                ),
            )

        group = createGroupWithDefaultRoles(owner)
    }

    @Test
    @DisplayName("그룹장은 새로운 역할을 생성할 수 있다")
    fun createGroupRole_Success() {
        val request =
            CreateGroupRoleRequest(
                name = "MODERATOR",
                permissions = setOf("GROUP_MANAGE", "CHANNEL_MANAGE"),
                priority = 50,
            )

        val response = groupRoleService.createGroupRole(group.id, request, owner.id)

        assertThat(response.name).isEqualTo("MODERATOR")
        assertThat(response.permissions).containsExactlyInAnyOrder("GROUP_MANAGE", "CHANNEL_MANAGE")
        assertThat(response.priority).isEqualTo(50)

        val saved = groupRoleRepository.findByGroupIdAndName(group.id, "MODERATOR")
        assertThat(saved).isPresent
        assertThat(saved.get().permissions).containsExactlyInAnyOrder(
            GroupPermission.GROUP_MANAGE,
            GroupPermission.CHANNEL_MANAGE,
        )
    }

    @Test
    @DisplayName("그룹장이 아니면 역할을 생성할 수 없다")
    fun createGroupRole_NotOwner_ThrowsForbidden() {
        val request =
            CreateGroupRoleRequest(
                name = "MANAGER",
                permissions = setOf("GROUP_MANAGE"),
                priority = 10,
            )

        assertThatThrownBy { groupRoleService.createGroupRole(group.id, request, member.id) }
            .isInstanceOf(BusinessException::class.java)
            .hasFieldOrPropertyWithValue("errorCode", ErrorCode.FORBIDDEN)
    }

    @Test
    @DisplayName("동일한 이름의 역할은 중복 생성할 수 없다")
    fun createGroupRole_DuplicateName_ThrowsException() {
        val request =
            CreateGroupRoleRequest(
                name = "MODERATOR",
                permissions = setOf("GROUP_MANAGE"),
                priority = 10,
            )

        groupRoleService.createGroupRole(group.id, request, owner.id)

        assertThatThrownBy { groupRoleService.createGroupRole(group.id, request, owner.id) }
            .isInstanceOf(BusinessException::class.java)
            .hasFieldOrPropertyWithValue("errorCode", ErrorCode.GROUP_ROLE_NAME_ALREADY_EXISTS)
    }

    @Test
    @DisplayName("그룹 역할 정보를 조회할 수 있다")
    fun getGroupRole_Success() {
        val customRole = createCustomRole(group, "EDITOR")

        val response = groupRoleService.getGroupRole(group.id, customRole.id)

        assertThat(response.name).isEqualTo("EDITOR")
        assertThat(response.permissions).containsExactly("CHANNEL_MANAGE")
    }

    @Test
    @DisplayName("다른 그룹의 역할을 조회하면 예외가 발생한다")
    fun getGroupRole_MismatchedGroup_ThrowsException() {
        val ownerRole = groupRoleRepository.findByGroupIdAndName(group.id, "그룹장").get()

        assertThatThrownBy { groupRoleService.getGroupRole(group.id + 999, ownerRole.id) }
            .isInstanceOf(BusinessException::class.java)
            .hasFieldOrPropertyWithValue("errorCode", ErrorCode.GROUP_ROLE_NOT_FOUND)
    }

    @Test
    @DisplayName("그룹 역할 목록을 조회할 수 있다")
    fun getGroupRoles_Success() {
        createCustomRole(group, "COORDINATOR")

        val roles = groupRoleService.getGroupRoles(group.id)

        assertThat(roles.map { it.name }).contains("그룹장", "교수", "멤버", "COORDINATOR")
    }

    @Test
    @DisplayName("그룹장은 역할 정보를 수정할 수 있다")
    fun updateGroupRole_Success() {
        val customRole = createCustomRole(group, "MODERATOR")
        val request =
            UpdateGroupRoleRequest(
                name = "COORDINATOR",
                permissions = setOf("GROUP_MANAGE"),
                priority = 80,
            )

        val response = groupRoleService.updateGroupRole(group.id, customRole.id, request, owner.id)

        assertThat(response.name).isEqualTo("COORDINATOR")
        assertThat(response.permissions).containsExactly("GROUP_MANAGE")
        assertThat(response.priority).isEqualTo(80)

        val saved = groupRoleRepository.findById(customRole.id).get()
        assertThat(saved.name).isEqualTo("COORDINATOR")
        assertThat(saved.permissions).containsExactly(GroupPermission.GROUP_MANAGE)
        assertThat(saved.priority).isEqualTo(80)
    }

    @Test
    @DisplayName("그룹장 또는 멤버 역할은 수정할 수 없다")
    fun updateGroupRole_SystemRole_ThrowsForbidden() {
        val ownerRole = groupRoleRepository.findByGroupIdAndName(group.id, "그룹장").get()

        val request =
            UpdateGroupRoleRequest(
                name = "NEW_OWNER",
                permissions = setOf("GROUP_MANAGE"),
            )

        assertThatThrownBy { groupRoleService.updateGroupRole(group.id, ownerRole.id, request, owner.id) }
            .isInstanceOf(BusinessException::class.java)
            .hasFieldOrPropertyWithValue("errorCode", ErrorCode.SYSTEM_ROLE_IMMUTABLE)
    }

    @Test
    @DisplayName("그룹장이 아니면 역할을 수정할 수 없다")
    fun updateGroupRole_NotOwner_ThrowsForbidden() {
        val customRole = createCustomRole(group, "ASSISTANT")

        val request = UpdateGroupRoleRequest(name = "STAFF")

        assertThatThrownBy { groupRoleService.updateGroupRole(group.id, customRole.id, request, member.id) }
            .isInstanceOf(BusinessException::class.java)
            .hasFieldOrPropertyWithValue("errorCode", ErrorCode.FORBIDDEN)
    }

    @Test
    @DisplayName("그룹장은 커스텀 역할을 삭제할 수 있다")
    fun deleteGroupRole_Success() {
        val customRole = createCustomRole(group, "STAFF")

        groupRoleService.deleteGroupRole(group.id, customRole.id, owner.id)

        val deleted = groupRoleRepository.findById(customRole.id)
        assertThat(deleted).isNotPresent
    }

    @Test
    @DisplayName("그룹장이 아니면 역할을 삭제할 수 없다")
    fun deleteGroupRole_NotOwner_ThrowsForbidden() {
        val customRole = createCustomRole(group, "REVIEWER")

        assertThatThrownBy { groupRoleService.deleteGroupRole(group.id, customRole.id, member.id) }
            .isInstanceOf(BusinessException::class.java)
            .hasFieldOrPropertyWithValue("errorCode", ErrorCode.FORBIDDEN)
    }

    @Test
    @DisplayName("시스템 역할은 삭제할 수 없다")
    fun deleteGroupRole_SystemRole_ThrowsForbidden() {
        val memberRole = groupRoleRepository.findByGroupIdAndName(group.id, "멤버").get()

        assertThatThrownBy { groupRoleService.deleteGroupRole(group.id, memberRole.id, owner.id) }
            .isInstanceOf(BusinessException::class.java)
            .hasFieldOrPropertyWithValue("errorCode", ErrorCode.SYSTEM_ROLE_IMMUTABLE)
    }

    private fun createGroupWithDefaultRoles(owner: User): Group {
        val group =
            groupRepository.save(
                TestDataFactory.createTestGroup(
                    name = "역할 테스트 그룹",
                    owner = owner,
                ),
            )

        val ownerRole = groupRoleRepository.save(TestDataFactory.createOwnerRole(group))
        groupRoleRepository.save(TestDataFactory.createAdvisorRole(group))
        val memberRole = groupRoleRepository.save(TestDataFactory.createMemberRole(group))

        groupMemberRepository.save(
            TestDataFactory.createTestGroupMember(
                group = group,
                user = owner,
                role = ownerRole,
            ),
        )

        return group
    }

    private fun createCustomRole(
        group: Group,
        name: String,
    ): GroupRole {
        return groupRoleRepository.save(
            TestDataFactory.createTestGroupRole(
                group = group,
                name = name,
                isSystemRole = false,
                permissions = setOf(GroupPermission.CHANNEL_MANAGE),
                priority = 20,
            ),
        )
    }
}
