package com.univgroup.domain.permission.evaluator

import com.univgroup.domain.group.entity.Group
import com.univgroup.domain.group.entity.GroupMember
import com.univgroup.domain.group.entity.GroupRole
import com.univgroup.domain.permission.SystemRole
import com.univgroup.domain.group.repository.GroupMemberRepository
import com.univgroup.domain.group.repository.GroupRepository
import com.univgroup.domain.permission.ChannelPermission
import com.univgroup.domain.permission.GroupPermission
import com.univgroup.domain.permission.entity.ChannelRoleBinding
import com.univgroup.domain.permission.repository.ChannelRoleBindingRepository
import com.univgroup.domain.permission.service.AuditLogger
import com.univgroup.domain.permission.service.PermissionCacheManager
import com.univgroup.domain.user.entity.User
import com.univgroup.domain.workspace.entity.Channel
import com.univgroup.domain.workspace.repository.ChannelRepository
import com.univgroup.shared.exception.AccessDeniedException
import io.mockk.*
import org.assertj.core.api.Assertions.assertThat
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import java.util.*

/**
 * PermissionEvaluator 단위 테스트
 *
 * 검증 항목:
 * - 그룹 권한 평가 (hasGroupPermission, requireGroupPermission)
 * - 채널 권한 평가 (hasChannelPermission, requireChannelPermission)
 * - 그룹 멤버십 확인 (isGroupMember, isGroupOwner)
 * - 권한 캐싱 (getGroupPermissions, getChannelPermissions)
 * - 캐시 무효화 (invalidateUserPermissions, invalidateGroupPermissions)
 * - 감사 로깅 (권한 부여/거부 로그)
 */
@DisplayName("PermissionEvaluator 단위 테스트")
class PermissionEvaluatorTest {
    private lateinit var permissionEvaluator: PermissionEvaluator
    private lateinit var permissionLoader: PermissionLoader
    private lateinit var cacheManager: PermissionCacheManager
    private lateinit var auditLogger: AuditLogger

    // Repository Mocks
    private lateinit var groupRepository: GroupRepository
    private lateinit var groupMemberRepository: GroupMemberRepository
    private lateinit var channelRepository: ChannelRepository
    private lateinit var channelRoleBindingRepository: ChannelRoleBindingRepository

    // Test Entities
    private lateinit var testUser: User
    private lateinit var testOwner: User
    private lateinit var testGroup: Group
    private lateinit var testRole: GroupRole
    private lateinit var testMember: GroupMember
    private lateinit var testChannel: Channel
    private lateinit var testBinding: ChannelRoleBinding

    @BeforeEach
    fun setUp() {
        // Mock Repository 생성
        groupRepository = mockk()
        groupMemberRepository = mockk()
        channelRepository = mockk()
        channelRoleBindingRepository = mockk()
        cacheManager = mockk()
        auditLogger = mockk(relaxed = true)

        // PermissionLoader 생성 (실제 객체, Repository는 Mock)
        permissionLoader = PermissionLoader(
            groupRepository = groupRepository,
            groupMemberRepository = groupMemberRepository,
            channelRepository = channelRepository,
            channelRoleBindingRepository = channelRoleBindingRepository,
        )

        // PermissionEvaluator 생성
        permissionEvaluator = PermissionEvaluator(
            permissionLoader = permissionLoader,
            cacheManager = cacheManager,
            auditLogger = auditLogger,
        )

        // 테스트용 Entity 생성
        testOwner = mockk(relaxed = true) {
            every { id } returns 999L
        }

        testUser = mockk(relaxed = true) {
            every { id } returns 1L
        }

        testGroup = mockk(relaxed = true) {
            every { id } returns 100L
            every { owner } returns testOwner
        }

        testRole = mockk(relaxed = true) {
            every { id } returns 1L
            every { permissions } returns mutableSetOf(GroupPermission.POST_MANAGE, GroupPermission.COMMENT_MANAGE)
        }

        testMember = mockk(relaxed = true) {
            every { user } returns testUser
            every { group } returns testGroup
            every { role } returns testRole
        }

        testChannel = mockk(relaxed = true) {
            every { id } returns 300L
            every { group } returns testGroup
        }

        testBinding = mockk(relaxed = true) {
            every { channel } returns testChannel
            every { groupRole } returns testRole
            every { permissions } returns setOf(ChannelPermission.POST_READ, ChannelPermission.POST_WRITE)
        }
    }

    // ========== 그룹 권한 평가 테스트 ==========

    @Test
    @DisplayName("hasGroupPermission: 사용자가 권한을 가지고 있으면 true 반환")
    fun `hasGroupPermission should return true when user has permission`() {
        // Given
        val userId = 1L
        val groupId = 100L
        val permission = GroupPermission.POST_MANAGE

        every { cacheManager.getOrLoadGroupPermissions(userId, groupId, any()) } answers {
            val loader = thirdArg<() -> Set<GroupPermission>>()
            loader()
        }
        every { groupMemberRepository.findByGroupIdAndUserId(groupId, userId) } returns testMember

        // When
        val result = permissionEvaluator.hasGroupPermission(userId, groupId, permission)

        // Then
        assertThat(result).isTrue()
        verify(exactly = 1) { auditLogger.logPermissionGranted(userId, "GROUP", groupId, permission.name, any()) }
    }

    @Test
    @DisplayName("hasGroupPermission: 사용자가 권한을 가지고 있지 않으면 false 반환")
    fun `hasGroupPermission should return false when user does not have permission`() {
        // Given
        val userId = 1L
        val groupId = 100L
        val permission = GroupPermission.MEMBER_KICK

        every { cacheManager.getOrLoadGroupPermissions(userId, groupId, any()) } answers {
            val loader = thirdArg<() -> Set<GroupPermission>>()
            loader()
        }
        every { groupMemberRepository.findByGroupIdAndUserId(groupId, userId) } returns testMember

        // When
        val result = permissionEvaluator.hasGroupPermission(userId, groupId, permission)

        // Then
        assertThat(result).isFalse()
        verify(exactly = 0) { auditLogger.logPermissionGranted(any(), any(), any(), any(), any()) }
    }

    @Test
    @DisplayName("hasGroupPermission: 그룹 멤버가 아니면 false 반환")
    fun `hasGroupPermission should return false when user is not group member`() {
        // Given
        val userId = 1L
        val groupId = 100L
        val permission = GroupPermission.POST_MANAGE

        every { cacheManager.getOrLoadGroupPermissions(userId, groupId, any()) } answers {
            val loader = thirdArg<() -> Set<GroupPermission>>()
            loader()
        }
        every { groupMemberRepository.findByGroupIdAndUserId(groupId, userId) } returns null

        // When
        val result = permissionEvaluator.hasGroupPermission(userId, groupId, permission)

        // Then
        assertThat(result).isFalse()
    }

    @Test
    @DisplayName("requireGroupPermission: 권한이 있으면 예외 발생하지 않음")
    fun `requireGroupPermission should not throw exception when user has permission`() {
        // Given
        val userId = 1L
        val groupId = 100L
        val permission = GroupPermission.POST_MANAGE

        every { cacheManager.getOrLoadGroupPermissions(userId, groupId, any()) } answers {
            val loader = thirdArg<() -> Set<GroupPermission>>()
            loader()
        }
        every { groupMemberRepository.findByGroupIdAndUserId(groupId, userId) } returns testMember

        // When & Then
        permissionEvaluator.requireGroupPermission(userId, groupId, permission)

        verify(exactly = 1) { auditLogger.logPermissionGranted(userId, "GROUP", groupId, permission.name, any()) }
    }

    @Test
    @DisplayName("requireGroupPermission: 권한이 없으면 AccessDeniedException 발생")
    fun `requireGroupPermission should throw AccessDeniedException when user does not have permission`() {
        // Given
        val userId = 1L
        val groupId = 100L
        val permission = GroupPermission.MEMBER_KICK

        every { cacheManager.getOrLoadGroupPermissions(userId, groupId, any()) } answers {
            val loader = thirdArg<() -> Set<GroupPermission>>()
            loader()
        }
        every { groupMemberRepository.findByGroupIdAndUserId(groupId, userId) } returns testMember

        // When & Then
        assertThrows<AccessDeniedException> {
            permissionEvaluator.requireGroupPermission(userId, groupId, permission)
        }

        verify(exactly = 1) { auditLogger.logPermissionDenied(userId, "GROUP", groupId, permission.name, any()) }
    }

    // ========== 채널 권한 평가 테스트 ==========

    @Test
    @DisplayName("hasChannelPermission: 사용자가 채널 권한을 가지고 있으면 true 반환")
    fun `hasChannelPermission should return true when user has channel permission`() {
        // Given
        val userId = 1L
        val channelId = 300L
        val permission = ChannelPermission.POST_READ

        every { cacheManager.getOrLoadChannelPermissions(userId, channelId, any()) } answers {
            val loader = thirdArg<() -> Set<ChannelPermission>>()
            loader()
        }
        every { channelRepository.findById(channelId) } returns Optional.of(testChannel)
        every { groupMemberRepository.findByGroupIdAndUserId(100L, userId) } returns testMember
        every { channelRoleBindingRepository.findByChannelIdAndGroupRoleId(channelId, 1L) } returns testBinding

        // When
        val result = permissionEvaluator.hasChannelPermission(userId, channelId, permission)

        // Then
        assertThat(result).isTrue()
        verify(exactly = 1) { auditLogger.logPermissionGranted(userId, "CHANNEL", channelId, permission.name, any()) }
    }

    @Test
    @DisplayName("hasChannelPermission: 채널이 없으면 false 반환")
    fun `hasChannelPermission should return false when channel does not exist`() {
        // Given
        val userId = 1L
        val channelId = 300L
        val permission = ChannelPermission.POST_READ

        every { cacheManager.getOrLoadChannelPermissions(userId, channelId, any()) } answers {
            val loader = thirdArg<() -> Set<ChannelPermission>>()
            loader()
        }
        every { channelRepository.findById(channelId) } returns Optional.empty()

        // When
        val result = permissionEvaluator.hasChannelPermission(userId, channelId, permission)

        // Then
        assertThat(result).isFalse()
    }

    @Test
    @DisplayName("requireChannelPermission: 권한이 없으면 AccessDeniedException 발생")
    fun `requireChannelPermission should throw AccessDeniedException when user does not have permission`() {
        // Given
        val userId = 1L
        val channelId = 300L
        val permission = ChannelPermission.CHANNEL_SETTINGS

        every { cacheManager.getOrLoadChannelPermissions(userId, channelId, any()) } answers {
            val loader = thirdArg<() -> Set<ChannelPermission>>()
            loader()
        }
        every { channelRepository.findById(channelId) } returns Optional.of(testChannel)
        every { groupMemberRepository.findByGroupIdAndUserId(100L, userId) } returns testMember
        every { channelRoleBindingRepository.findByChannelIdAndGroupRoleId(channelId, 1L) } returns testBinding

        // When & Then
        assertThrows<AccessDeniedException> {
            permissionEvaluator.requireChannelPermission(userId, channelId, permission)
        }

        verify(exactly = 1) { auditLogger.logPermissionDenied(userId, "CHANNEL", channelId, permission.name, any()) }
    }

    // ========== 그룹 멤버십 테스트 ==========

    @Test
    @DisplayName("isGroupMember: 사용자가 그룹 멤버이면 true 반환")
    fun `isGroupMember should return true when user is group member`() {
        // Given
        val userId = 1L
        val groupId = 100L

        every { cacheManager.getMembership(userId, groupId) } returns null
        every { groupMemberRepository.existsByGroupIdAndUserId(groupId, userId) } returns true
        every { cacheManager.putMembership(userId, groupId, true) } just Runs

        // When
        val result = permissionEvaluator.isGroupMember(userId, groupId)

        // Then
        assertThat(result).isTrue()
        verify(exactly = 1) { auditLogger.logMembershipCheck(userId, groupId, true) }
    }

    @Test
    @DisplayName("isGroupMember: 사용자가 그룹 멤버가 아니면 false 반환")
    fun `isGroupMember should return false when user is not group member`() {
        // Given
        val userId = 1L
        val groupId = 100L

        every { cacheManager.getMembership(userId, groupId) } returns null
        every { groupMemberRepository.existsByGroupIdAndUserId(groupId, userId) } returns false
        every { cacheManager.putMembership(userId, groupId, false) } just Runs

        // When
        val result = permissionEvaluator.isGroupMember(userId, groupId)

        // Then
        assertThat(result).isFalse()
        verify(exactly = 1) { auditLogger.logMembershipCheck(userId, groupId, false) }
    }

    @Test
    @DisplayName("isGroupMember: 캐시된 값이 있으면 캐시에서 반환")
    fun `isGroupMember should return cached value when available`() {
        // Given
        val userId = 1L
        val groupId = 100L

        every { cacheManager.getMembership(userId, groupId) } returns true

        // When
        val result = permissionEvaluator.isGroupMember(userId, groupId)

        // Then
        assertThat(result).isTrue()
        verify(exactly = 0) { groupMemberRepository.existsByGroupIdAndUserId(any(), any()) }
        verify(exactly = 0) { auditLogger.logMembershipCheck(any(), any(), any()) }
    }

    @Test
    @DisplayName("isGroupOwner: 사용자가 그룹 소유자이면 true 반환")
    fun `isGroupOwner should return true when user is group owner`() {
        // Given
        val userId = 999L
        val groupId = 100L

        every { groupRepository.findById(groupId) } returns Optional.of(testGroup)

        // When
        val result = permissionEvaluator.isGroupOwner(userId, groupId)

        // Then
        assertThat(result).isTrue()
    }

    @Test
    @DisplayName("isGroupOwner: 사용자가 그룹 소유자가 아니면 false 반환")
    fun `isGroupOwner should return false when user is not group owner`() {
        // Given
        val userId = 1L
        val groupId = 100L

        every { groupRepository.findById(groupId) } returns Optional.of(testGroup)

        // When
        val result = permissionEvaluator.isGroupOwner(userId, groupId)

        // Then
        assertThat(result).isFalse()
    }

    // ========== 권한 캐싱 테스트 ==========

    @Test
    @DisplayName("getGroupPermissions: 캐시 미스 시 PermissionLoader 호출")
    fun `getGroupPermissions should call PermissionLoader on cache miss`() {
        // Given
        val userId = 1L
        val groupId = 100L

        every { cacheManager.getOrLoadGroupPermissions(userId, groupId, any()) } answers {
            val loader = thirdArg<() -> Set<GroupPermission>>()
            loader()
        }
        every { groupMemberRepository.findByGroupIdAndUserId(groupId, userId) } returns testMember

        // When
        val result = permissionEvaluator.getGroupPermissions(userId, groupId)

        // Then
        assertThat(result).containsExactlyInAnyOrder(GroupPermission.POST_MANAGE, GroupPermission.COMMENT_MANAGE)
        verify(exactly = 1) { groupMemberRepository.findByGroupIdAndUserId(groupId, userId) }
    }

    @Test
    @DisplayName("hasAnyGroupPermission: 하나라도 권한이 있으면 true 반환")
    fun `hasAnyGroupPermission should return true when user has any of the permissions`() {
        // Given
        val userId = 1L
        val groupId = 100L
        val permissions = setOf(GroupPermission.POST_MANAGE, GroupPermission.MEMBER_KICK)

        every { cacheManager.getOrLoadGroupPermissions(userId, groupId, any()) } answers {
            val loader = thirdArg<() -> Set<GroupPermission>>()
            loader()
        }
        every { groupMemberRepository.findByGroupIdAndUserId(groupId, userId) } returns testMember

        // When
        val result = permissionEvaluator.hasAnyGroupPermission(userId, groupId, permissions)

        // Then
        assertThat(result).isTrue()
    }

    @Test
    @DisplayName("hasAllGroupPermissions: 모든 권한이 있으면 true 반환")
    fun `hasAllGroupPermissions should return true when user has all permissions`() {
        // Given
        val userId = 1L
        val groupId = 100L
        val permissions = setOf(GroupPermission.POST_MANAGE, GroupPermission.COMMENT_MANAGE)

        every { cacheManager.getOrLoadGroupPermissions(userId, groupId, any()) } answers {
            val loader = thirdArg<() -> Set<GroupPermission>>()
            loader()
        }
        every { groupMemberRepository.findByGroupIdAndUserId(groupId, userId) } returns testMember

        // When
        val result = permissionEvaluator.hasAllGroupPermissions(userId, groupId, permissions)

        // Then
        assertThat(result).isTrue()
    }

    @Test
    @DisplayName("hasAllGroupPermissions: 일부 권한만 있으면 false 반환")
    fun `hasAllGroupPermissions should return false when user does not have all permissions`() {
        // Given
        val userId = 1L
        val groupId = 100L
        val permissions = setOf(GroupPermission.POST_MANAGE, GroupPermission.MEMBER_KICK)

        every { cacheManager.getOrLoadGroupPermissions(userId, groupId, any()) } answers {
            val loader = thirdArg<() -> Set<GroupPermission>>()
            loader()
        }
        every { groupMemberRepository.findByGroupIdAndUserId(groupId, userId) } returns testMember

        // When
        val result = permissionEvaluator.hasAllGroupPermissions(userId, groupId, permissions)

        // Then
        assertThat(result).isFalse()
    }

    // ========== 캐시 무효화 테스트 ==========

    @Test
    @DisplayName("invalidateUserPermissions: cacheManager.invalidateUser 호출")
    fun `invalidateUserPermissions should call cacheManager invalidateUser`() {
        // Given
        val userId = 1L
        val groupId = 100L

        every { cacheManager.invalidateUser(userId, groupId) } just Runs

        // When
        permissionEvaluator.invalidateUserPermissions(userId, groupId)

        // Then
        verify(exactly = 1) { cacheManager.invalidateUser(userId, groupId) }
    }

    @Test
    @DisplayName("invalidateGroupPermissions: cacheManager.invalidateGroup 호출")
    fun `invalidateGroupPermissions should call cacheManager invalidateGroup`() {
        // Given
        val groupId = 100L

        every { cacheManager.invalidateGroup(groupId) } just Runs

        // When
        permissionEvaluator.invalidateGroupPermissions(groupId)

        // Then
        verify(exactly = 1) { cacheManager.invalidateGroup(groupId) }
    }

    @Test
    @DisplayName("invalidateChannelPermissions: cacheManager.invalidateChannel 호출")
    fun `invalidateChannelPermissions should call cacheManager invalidateChannel`() {
        // Given
        val channelId = 300L

        every { cacheManager.invalidateChannel(channelId) } just Runs

        // When
        permissionEvaluator.invalidateChannelPermissions(channelId)

        // Then
        verify(exactly = 1) { cacheManager.invalidateChannel(channelId) }
    }
}
