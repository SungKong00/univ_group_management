package org.castlekong.backend.service

import org.assertj.core.api.Assertions.assertThat
import org.assertj.core.api.Assertions.assertThatThrownBy
import org.castlekong.backend.dto.CreateChannelRequest
import org.castlekong.backend.dto.CreateCommentRequest
import org.castlekong.backend.dto.CreatePostRequest
import org.castlekong.backend.dto.UpdatePostRequest
import org.castlekong.backend.dto.UpdateWorkspaceRequest
import org.castlekong.backend.dto.WorkspaceResponse
import org.castlekong.backend.entity.ChannelPermission
import org.castlekong.backend.entity.ChannelRoleBinding
import org.castlekong.backend.entity.Group
import org.castlekong.backend.entity.GroupRole
import org.castlekong.backend.entity.User
import org.castlekong.backend.exception.BusinessException
import org.castlekong.backend.exception.ErrorCode
import org.castlekong.backend.fixture.TestDataFactory
import org.castlekong.backend.repository.ChannelRepository
import org.castlekong.backend.repository.ChannelRoleBindingRepository
import org.castlekong.backend.repository.CommentRepository
import org.castlekong.backend.repository.GroupMemberRepository
import org.castlekong.backend.repository.GroupRepository
import org.castlekong.backend.repository.GroupRoleRepository
import org.castlekong.backend.repository.PostRepository
import org.castlekong.backend.repository.UserRepository
import org.castlekong.backend.repository.WorkspaceRepository
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
class ContentServiceIntegrationTest {
    @Autowired
    private lateinit var contentService: ContentService

    @Autowired
    private lateinit var userRepository: UserRepository

    @Autowired
    private lateinit var groupRepository: GroupRepository

    @Autowired
    private lateinit var groupRoleRepository: GroupRoleRepository

    @Autowired
    private lateinit var groupMemberRepository: GroupMemberRepository

    @Autowired
    private lateinit var workspaceRepository: WorkspaceRepository

    @Autowired
    private lateinit var channelRepository: ChannelRepository

    @Autowired
    private lateinit var channelRoleBindingRepository: ChannelRoleBindingRepository

    @Autowired
    private lateinit var postRepository: PostRepository

    @Autowired
    private lateinit var commentRepository: CommentRepository

    @Autowired
    private lateinit var channelInitializationService: ChannelInitializationService

    private lateinit var owner: User
    private lateinit var member: User
    private lateinit var outsider: User
    private lateinit var group: Group
    private lateinit var ownerRole: GroupRole
    private lateinit var memberRole: GroupRole

    @BeforeEach
    fun setUp() {
        val suffix = System.nanoTime().toString()
        owner =
            userRepository.save(
                TestDataFactory.createTestUser(
                    name = "그룹장",
                    email = "owner-content+$suffix@example.com",
                ).copy(profileCompleted = true),
            )

        member =
            userRepository.save(
                TestDataFactory.createStudentUser(
                    name = "멤버",
                    email = "member-content+$suffix@example.com",
                ),
            )

        outsider =
            userRepository.save(
                TestDataFactory.createStudentUser(
                    name = "외부인",
                    email = "outsider-content+$suffix@example.com",
                ),
            )

        group = createGroupWithDefaultRoles(owner)
        ownerRole = groupRoleRepository.findByGroupIdAndName(group.id!!, "OWNER").get()
        memberRole = groupRoleRepository.findByGroupIdAndName(group.id!!, "MEMBER").get()

        groupMemberRepository.save(
            TestDataFactory.createTestGroupMember(
                group = group,
                user = member,
                role = memberRole,
            ),
        )
    }

    @Test
    @DisplayName("그룹 조회 시 기본 워크스페이스가 자동 생성된다")
    fun getWorkspacesByGroup_CreatesDefaultWorkspace() {
        val existing = workspaceRepository.findByGroup_Id(group.id!!)
        assertThat(existing).isEmpty()

        val workspaces = contentService.getWorkspacesByGroup(group.id!!, owner.id)

        assertThat(workspaces).hasSize(1)
        assertThat(workspaces[0].name).isEqualTo("기본 워크스페이스")
        assertThat(workspaceRepository.findByGroup_Id(group.id!!)).hasSize(1)
    }

    @Test
    @DisplayName("그룹 워크스페이스 조회는 멱등적이며 단 하나만 존재한다")
    fun getWorkspacesByGroup_IdempotentSingle() {
        val first = contentService.getWorkspacesByGroup(group.id!!, owner.id)
        val second = contentService.getWorkspacesByGroup(group.id!!, owner.id)
        assertThat(first).hasSize(1)
        assertThat(second).hasSize(1)
        assertThat(first[0].id).isEqualTo(second[0].id)
        assertThat(workspaceRepository.findByGroup_Id(group.id!!)).hasSize(1)
    }

    @Test
    @DisplayName("워크스페이스 수정은 그룹 관리 권한이 없는 멤버에게 허용되지 않는다")
    fun updateWorkspace_ForbiddenForMember() {
        val workspace = ensureDefaultWorkspace()

        assertThatThrownBy {
            contentService.updateWorkspace(
                workspace.id,
                UpdateWorkspaceRequest(name = "수정됨"),
                member.id!!,
            )
        }
            .isInstanceOf(BusinessException::class.java)
            .hasFieldOrPropertyWithValue("errorCode", ErrorCode.FORBIDDEN)
    }

    @Test
    @DisplayName("채널 생성 시 기본 권한 바인딩이 설정된다")
    fun createChannel_CreatesDefaultBindings() {
        // (정책 변경) 사용자 정의 채널은 0개 바인딩으로 시작하므로 이 테스트는 제거됨.
    }

    @Test
    @DisplayName("공지 타입 사용자 정의 채널도 권한 바인딩 0개로 시작한다")
    fun createAnnouncementChannel_StartsWithoutBindings() {
        val workspace = ensureDefaultWorkspace()
        val channel =
            contentService.createChannel(
                workspace.id,
                CreateChannelRequest(name = "공지2", description = "추가 공지", type = "ANNOUNCEMENT"),
                owner.id!!,
            )
        val bindings = channelRoleBindingRepository.findByChannelId(channel.id)
        assertThat(bindings).isEmpty()
    }

    @Test
    @DisplayName("채널 생성은 권한이 없는 멤버에게 거부된다")
    fun createChannel_ForbiddenForMember() {
        val workspace = ensureDefaultWorkspace()

        assertThatThrownBy {
            contentService.createChannel(
                workspace.id,
                CreateChannelRequest(name = "비밀"),
                member.id!!,
            )
        }
            .isInstanceOf(BusinessException::class.java)
            .hasFieldOrPropertyWithValue("errorCode", ErrorCode.FORBIDDEN)
    }

    @Test
    @DisplayName("워크스페이스 채널 목록은 멤버가 아닌 사용자에게 차단된다")
    fun getChannelsByWorkspace_ForbiddenForNonMember() {
        val workspace = ensureDefaultWorkspace()
        contentService.createChannel(workspace.id, CreateChannelRequest(name = "정보"), owner.id!!)

        assertThatThrownBy { contentService.getChannelsByWorkspace(workspace.id, outsider.id!!) }
            .isInstanceOf(BusinessException::class.java)
            .hasFieldOrPropertyWithValue("errorCode", ErrorCode.FORBIDDEN)
    }

    @Test
    @DisplayName("그룹 ID로 채널 목록을 조회할 수 있다")
    fun getChannelsByGroup_Success() {
        val workspace = ensureDefaultWorkspace()
        contentService.createChannel(workspace.id, CreateChannelRequest(name = "공지사항"), owner.id!!)
        contentService.createChannel(workspace.id, CreateChannelRequest(name = "자유게시판"), owner.id!!)

        val channels = contentService.getChannelsByGroup(group.id!!, member.id!!)

        assertThat(channels).hasSize(2)
        assertThat(channels.map { it.name }).contains("공지사항", "자유게시판")
    }

    @Test
    @DisplayName("그룹 채널 목록은 멤버가 아닌 사용자에게 차단된다")
    fun getChannelsByGroup_ForbiddenForNonMember() {
        val workspace = ensureDefaultWorkspace()
        contentService.createChannel(workspace.id, CreateChannelRequest(name = "정보"), owner.id!!)

        assertThatThrownBy { contentService.getChannelsByGroup(group.id!!, outsider.id!!) }
            .isInstanceOf(BusinessException::class.java)
            .hasFieldOrPropertyWithValue("errorCode", ErrorCode.FORBIDDEN)
    }

    @Test
    @DisplayName("멤버는 채널에 게시글을 작성할 수 있다 (권한 부여 후)")
    fun createPost_Success() {
        val channel = createDefaultChannel()
        grantFull(channel.id) // 권한 수동 부여
        val response =
            contentService.createPost(
                channel.id,
                CreatePostRequest(content = "안녕하세요"),
                member.id!!,
            )

        assertThat(response.content).isEqualTo("안녕하세요")
        assertThat(response.author.id).isEqualTo(member.id!!)

        val saved = postRepository.findById(response.id)
        assertThat(saved).isPresent
    }

    @Test
    @DisplayName("그룹 멤버가 아닌 사용자는 게시글을 작성할 수 없다")
    fun createPost_ForbiddenForNonMember() {
        val channel = createDefaultChannel()

        assertThatThrownBy {
            contentService.createPost(
                channel.id,
                CreatePostRequest(content = "외부인"),
                outsider.id!!,
            )
        }
            .isInstanceOf(BusinessException::class.java)
            .hasFieldOrPropertyWithValue("errorCode", ErrorCode.FORBIDDEN)
    }

    @Test
    @DisplayName("게시글은 작성자만 수정할 수 있다 (권한 부여 후)")
    fun updatePost_OnlyAuthorCanUpdate() {
        val channel = createDefaultChannel()
        grantFull(channel.id)
        val post = contentService.createPost(channel.id, CreatePostRequest(content = "원본"), member.id!!)

        val updated = contentService.updatePost(post.id, UpdatePostRequest(content = "수정본"), member.id!!)
        assertThat(updated.content).isEqualTo("수정본")

        assertThatThrownBy { contentService.updatePost(post.id, UpdatePostRequest(content = "다른사용자"), owner.id!!) }
            .isInstanceOf(BusinessException::class.java)
            .hasFieldOrPropertyWithValue("errorCode", ErrorCode.FORBIDDEN)
    }

    @Test
    @DisplayName("그룹 관리 권한 있는 사용자는 다른 사람 게시글 삭제 가능 (권한 부여 후)")
    fun deletePost_ByOwnerWithAdminPermission() {
        val channel = createDefaultChannel()
        grantFull(channel.id)
        val post = contentService.createPost(channel.id, CreatePostRequest(content = "삭제 대상"), member.id!!)

        contentService.deletePost(post.id, owner.id!!)

        assertThat(postRepository.findById(post.id)).isNotPresent
    }

    @Test
    @DisplayName("멤버는 게시글에 댓글을 작성/삭제할 수 있다 (권한 부여 후)")
    fun createAndDeleteComment_Success() {
        val channel = createDefaultChannel()
        grantFull(channel.id)
        val post = contentService.createPost(channel.id, CreatePostRequest(content = "댓글 테스트"), member.id!!)

        val comment =
            contentService.createComment(
                post.id,
                CreateCommentRequest(content = "첫 댓글"),
                member.id!!,
            )
        assertThat(comment.content).isEqualTo("첫 댓글")

        contentService.deleteComment(comment.id, member.id!!)

        assertThat(commentRepository.findById(comment.id)).isNotPresent
    }

    @Test
    @DisplayName("댓글 작성자가 아니면 댓글을 삭제할 수 없다 (권한 부여 후)")
    fun deleteComment_NotAuthor_ThrowsForbidden() {
        val channel = createDefaultChannel()
        grantFull(channel.id)
        val post = contentService.createPost(channel.id, CreatePostRequest(content = "댓글"), member.id!!)
        val comment = contentService.createComment(post.id, CreateCommentRequest(content = "작성자"), member.id!!)

        assertThatThrownBy { contentService.deleteComment(comment.id, owner.id!!) }
            .isInstanceOf(BusinessException::class.java)
            .hasFieldOrPropertyWithValue("errorCode", ErrorCode.FORBIDDEN)
    }

    private fun ensureDefaultWorkspace(): WorkspaceResponse {
        val existing = workspaceRepository.findByGroup_Id(group.id!!)
        return if (existing.isEmpty()) {
            contentService.getWorkspacesByGroup(group.id!!, owner.id)[0]
        } else {
            val workspace = existing[0]
            WorkspaceResponse(
                id = workspace.id,
                groupId = workspace.group.id!!,
                name = workspace.name,
                description = workspace.description,
                createdAt = workspace.createdAt,
                updatedAt = workspace.updatedAt,
            )
        }
    }

    private fun createDefaultChannel() =
        contentService.createChannel(
            ensureDefaultWorkspace().id,
            CreateChannelRequest(name = "토론"),
            owner.id!!,
        )

    private fun createGroupWithDefaultRoles(owner: User): Group {
        val group =
            groupRepository.save(
                TestDataFactory.createTestGroup(
                    name = "컨텐츠 테스트 그룹",
                    owner = owner,
                ),
            )

        val ownerRole = groupRoleRepository.save(TestDataFactory.createOwnerRole(group))
        groupRoleRepository.save(TestDataFactory.createAdvisorRole(group))
        groupRoleRepository.save(TestDataFactory.createMemberRole(group))

        groupMemberRepository.save(
            TestDataFactory.createTestGroupMember(
                group = group,
                user = owner,
                role = ownerRole,
            ),
        )

        return group
    }

    private fun grantBindings(
        channelId: Long,
        ownerPerms: Set<ChannelPermission>,
        memberPerms: Set<ChannelPermission>,
    ) {
        val channel = channelRepository.findById(channelId).get()
        val ownerRole = groupRoleRepository.findByGroupIdAndName(channel.group.id!!, "OWNER").get()
        val memberRole = groupRoleRepository.findByGroupIdAndName(channel.group.id!!, "MEMBER").get()
        channelRoleBindingRepository.save(ChannelRoleBinding.create(channel, ownerRole, ownerPerms))
        channelRoleBindingRepository.save(ChannelRoleBinding.create(channel, memberRole, memberPerms))
    }

    private fun grantFull(channelId: Long) =
        grantBindings(
            channelId,
            setOf(
                ChannelPermission.CHANNEL_VIEW,
                ChannelPermission.POST_READ,
                ChannelPermission.POST_WRITE,
                ChannelPermission.COMMENT_WRITE,
                ChannelPermission.FILE_UPLOAD,
            ),
            setOf(
                ChannelPermission.CHANNEL_VIEW,
                ChannelPermission.POST_READ,
                ChannelPermission.POST_WRITE,
                ChannelPermission.COMMENT_WRITE,
            ),
        )
}
