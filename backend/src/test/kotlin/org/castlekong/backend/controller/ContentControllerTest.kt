package org.castlekong.backend.controller

import com.fasterxml.jackson.databind.ObjectMapper
import org.castlekong.backend.dto.*
import org.castlekong.backend.entity.*
import org.castlekong.backend.fixture.TestDataFactory
import org.castlekong.backend.repository.*
import org.castlekong.backend.security.JwtTokenProvider
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.http.MediaType
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken
import org.springframework.test.context.ActiveProfiles
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*
import org.springframework.test.web.servlet.result.MockMvcResultHandlers.print
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.*
import org.springframework.transaction.annotation.Transactional

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.MOCK)
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
@DisplayName("ContentController 통합 테스트")
class ContentControllerTest {
    @Autowired
    private lateinit var mockMvc: MockMvc

    @Autowired
    private lateinit var objectMapper: ObjectMapper

    @Autowired
    private lateinit var jwtTokenProvider: JwtTokenProvider

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

    // Test data
    private lateinit var owner: User
    private lateinit var member: User
    private lateinit var outsider: User
    private lateinit var group: Group
    private lateinit var ownerRole: GroupRole
    private lateinit var memberRole: GroupRole
    private lateinit var workspace: Workspace
    private lateinit var channel: Channel
    private lateinit var ownerToken: String
    private lateinit var memberToken: String
    private lateinit var outsiderToken: String

    @BeforeEach
    fun setUp() {
        val suffix = System.nanoTime().toString()

        // Create users
        owner = userRepository.save(
            TestDataFactory.createTestUser(
                name = "그룹장",
                email = "owner-ctrl+$suffix@example.com",
                globalRole = GlobalRole.STUDENT
            ).copy(profileCompleted = true)
        )

        member = userRepository.save(
            TestDataFactory.createStudentUser(
                name = "멤버",
                email = "member-ctrl+$suffix@example.com"
            )
        )

        outsider = userRepository.save(
            TestDataFactory.createStudentUser(
                name = "외부인",
                email = "outsider-ctrl+$suffix@example.com"
            )
        )

        // Create group and roles
        group = createGroupWithRoles(owner)
        ownerRole = groupRoleRepository.findByGroupIdAndName(group.id!!, "OWNER").get()
        memberRole = groupRoleRepository.findByGroupIdAndName(group.id!!, "MEMBER").get()

        // Add member to group
        groupMemberRepository.save(
            TestDataFactory.createTestGroupMember(
                group = group,
                user = member,
                role = memberRole
            )
        )

        // Create workspace and channel
        workspace = workspaceRepository.save(
            Workspace(
                name = "기본 워크스페이스",
                description = "테스트 워크스페이스",
                group = group
            )
        )

        channel = channelRepository.save(
            Channel(
                name = "공지사항",
                description = "공지사항 채널",
                type = ChannelType.ANNOUNCEMENT,
                workspace = workspace,
                group = group,
                createdBy = owner
            )
        )

        // Setup channel permissions (Full permissions for testing)
        setupChannelPermissions(channel, ownerRole, memberRole)

        // Generate JWT tokens
        ownerToken = generateToken(owner)
        memberToken = generateToken(member)
        outsiderToken = generateToken(outsider)
    }

    private fun createGroupWithRoles(owner: User): Group {
        val group = groupRepository.save(
            TestDataFactory.createTestGroup(
                name = "컨트롤러 테스트 그룹",
                owner = owner
            )
        )

        val ownerRole = groupRoleRepository.save(TestDataFactory.createOwnerRole(group))
        groupRoleRepository.save(TestDataFactory.createAdvisorRole(group))
        groupRoleRepository.save(TestDataFactory.createMemberRole(group))

        groupMemberRepository.save(
            TestDataFactory.createTestGroupMember(
                group = group,
                user = owner,
                role = ownerRole
            )
        )

        return group
    }

    private fun setupChannelPermissions(channel: Channel, ownerRole: GroupRole, memberRole: GroupRole) {
        val ownerPermissions = setOf(
            ChannelPermission.CHANNEL_VIEW,
            ChannelPermission.POST_READ,
            ChannelPermission.POST_WRITE,
            ChannelPermission.COMMENT_WRITE,
            ChannelPermission.FILE_UPLOAD
        )

        val memberPermissions = setOf(
            ChannelPermission.CHANNEL_VIEW,
            ChannelPermission.POST_READ,
            ChannelPermission.POST_WRITE,
            ChannelPermission.COMMENT_WRITE
        )

        channelRoleBindingRepository.save(
            ChannelRoleBinding.create(channel, ownerRole, ownerPermissions)
        )
        channelRoleBindingRepository.save(
            ChannelRoleBinding.create(channel, memberRole, memberPermissions)
        )
    }

    private fun generateToken(user: User): String {
        val authentication = UsernamePasswordAuthenticationToken(
            user.email,
            null,
            listOf(org.springframework.security.core.authority.SimpleGrantedAuthority("ROLE_${user.globalRole.name}"))
        )
        return jwtTokenProvider.generateAccessToken(authentication)
    }

    // ===================================
    // Workspace Tests
    // ===================================
    @Nested
    @DisplayName("워크스페이스 관리 테스트")
    inner class WorkspaceManagementTest {

        @Test
        @DisplayName("GET /api/groups/{groupId}/workspaces - 워크스페이스 목록 조회 성공")
        fun getWorkspaces_success() {
            // Given: Owner has CHANNEL_READ permission for the group

            // When & Then
            mockMvc.perform(
                get("/api/groups/${group.id}/workspaces")
                    .header("Authorization", "Bearer $ownerToken")
                    .accept(MediaType.APPLICATION_JSON)
            )
                .andDo(print())
                .andExpect(status().isOk)
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data[0].id").value(workspace.id))
                .andExpect(jsonPath("$.data[0].groupId").value(group.id))
                .andExpect(jsonPath("$.data[0].name").value("기본 워크스페이스"))
        }

        @Test
        @DisplayName("GET /api/groups/{groupId}/workspaces - 비멤버는 403")
        fun getWorkspaces_forbiddenForNonMember() {
            // Given: Outsider is not a member of the group

            // When & Then
            mockMvc.perform(
                get("/api/groups/${group.id}/workspaces")
                    .header("Authorization", "Bearer $outsiderToken")
                    .accept(MediaType.APPLICATION_JSON)
            )
                .andDo(print())
                .andExpect(status().isForbidden)
                .andExpect(jsonPath("$.success").value(false))
        }

        @Test
        @DisplayName("POST /api/groups/{groupId}/workspaces - 워크스페이스 생성 성공")
        fun createWorkspace_success() {
            // Given
            val request = CreateWorkspaceRequest(
                name = "새 워크스페이스",
                description = "새로운 워크스페이스입니다"
            )

            // When & Then
            mockMvc.perform(
                post("/api/groups/${group.id}/workspaces")
                    .header("Authorization", "Bearer $ownerToken")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request))
            )
                .andDo(print())
                .andExpect(status().isCreated)
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.name").value(request.name))
                .andExpect(jsonPath("$.data.description").value(request.description))
        }

        @Test
        @DisplayName("POST /api/groups/{groupId}/workspaces - 일반 멤버는 403")
        fun createWorkspace_forbiddenForMember() {
            // Given: Member doesn't have GROUP_MANAGE permission
            val request = CreateWorkspaceRequest(
                name = "멤버 워크스페이스",
                description = "멤버가 생성 시도"
            )

            // When & Then
            mockMvc.perform(
                post("/api/groups/${group.id}/workspaces")
                    .header("Authorization", "Bearer $memberToken")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request))
            )
                .andDo(print())
                .andExpect(status().isForbidden)
        }

        @Test
        @DisplayName("PUT /api/workspaces/{workspaceId} - 워크스페이스 수정 성공")
        fun updateWorkspace_success() {
            // Given
            val request = UpdateWorkspaceRequest(
                name = "수정된 워크스페이스",
                description = "수정된 설명"
            )

            // When & Then
            mockMvc.perform(
                put("/api/workspaces/${workspace.id}")
                    .header("Authorization", "Bearer $ownerToken")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request))
            )
                .andDo(print())
                .andExpect(status().isOk)
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.id").value(workspace.id))
                .andExpect(jsonPath("$.data.name").value(request.name))
        }

        @Test
        @DisplayName("DELETE /api/workspaces/{workspaceId} - 워크스페이스 삭제 성공")
        fun deleteWorkspace_success() {
            // Given: Create a deletable workspace
            val deletableWorkspace = workspaceRepository.save(
                Workspace(
                    name = "삭제용 워크스페이스",
                    description = "삭제 테스트",
                    group = group
                )
            )

            // When & Then
            mockMvc.perform(
                delete("/api/workspaces/${deletableWorkspace.id}")
                    .header("Authorization", "Bearer $ownerToken")
            )
                .andDo(print())
                .andExpect(status().isNoContent)
        }

        @Test
        @DisplayName("DELETE /api/workspaces/{workspaceId} - 권한 없음 403")
        fun deleteWorkspace_forbidden() {
            // Given: Member tries to delete workspace

            // When & Then
            mockMvc.perform(
                delete("/api/workspaces/${workspace.id}")
                    .header("Authorization", "Bearer $memberToken")
            )
                .andDo(print())
                .andExpect(status().isForbidden)
                .andExpect(jsonPath("$.success").value(false))
        }
    }

    // ===================================
    // Channel Tests
    // ===================================
    @Nested
    @DisplayName("채널 관리 테스트")
    inner class ChannelManagementTest {

        @Test
        @DisplayName("GET /api/workspaces/{workspaceId}/channels - 채널 목록 조회 성공")
        fun getChannelsByWorkspace_success() {
            // Given: Member has access to workspace

            // When & Then
            mockMvc.perform(
                get("/api/workspaces/${workspace.id}/channels")
                    .header("Authorization", "Bearer $memberToken")
                    .accept(MediaType.APPLICATION_JSON)
            )
                .andDo(print())
                .andExpect(status().isOk)
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data[0].id").value(channel.id))
                .andExpect(jsonPath("$.data[0].name").value("공지사항"))
                .andExpect(jsonPath("$.data[0].type").value("ANNOUNCEMENT"))
        }

        @Test
        @DisplayName("GET /api/groups/{groupId}/channels - 그룹의 채널 목록 조회 성공")
        fun getChannelsByGroup_success() {
            // Given: Member is part of the group

            // When & Then
            mockMvc.perform(
                get("/api/groups/${group.id}/channels")
                    .header("Authorization", "Bearer $memberToken")
                    .accept(MediaType.APPLICATION_JSON)
            )
                .andDo(print())
                .andExpect(status().isOk)
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data[0].id").value(channel.id))
                .andExpect(jsonPath("$.data[0].name").value("공지사항"))
        }

        @Test
        @DisplayName("GET /api/groups/{groupId}/channels - 비멤버는 403")
        fun getChannelsByGroup_forbiddenForNonMember() {
            // Given: Outsider is not a member

            // When & Then
            mockMvc.perform(
                get("/api/groups/${group.id}/channels")
                    .header("Authorization", "Bearer $outsiderToken")
                    .accept(MediaType.APPLICATION_JSON)
            )
                .andDo(print())
                .andExpect(status().isForbidden)
        }

        @Test
        @DisplayName("POST /api/workspaces/{workspaceId}/channels - 채널 생성 성공")
        fun createChannel_success() {
            // Given
            val request = CreateChannelRequest(
                name = "새 채널",
                description = "새로운 채널입니다",
                type = "TEXT"
            )

            // When & Then
            mockMvc.perform(
                post("/api/workspaces/${workspace.id}/channels")
                    .header("Authorization", "Bearer $ownerToken")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request))
            )
                .andDo(print())
                .andExpect(status().isCreated)
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.name").value(request.name))
        }

        @Test
        @DisplayName("POST /api/workspaces/{workspaceId}/channels - 일반 멤버는 403")
        fun createChannel_forbiddenForMember() {
            // Given
            val request = CreateChannelRequest(
                name = "멤버 채널",
                description = "멤버가 생성 시도"
            )

            // When & Then
            mockMvc.perform(
                post("/api/workspaces/${workspace.id}/channels")
                    .header("Authorization", "Bearer $memberToken")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request))
            )
                .andDo(print())
                .andExpect(status().isForbidden)
        }

        @Test
        @DisplayName("PUT /api/channels/{channelId} - 채널 수정 성공")
        fun updateChannel_success() {
            // Given
            val request = UpdateChannelRequest(
                name = "수정된 채널명",
                description = "수정된 설명",
                type = "TEXT"
            )

            // When & Then
            mockMvc.perform(
                put("/api/channels/${channel.id}")
                    .header("Authorization", "Bearer $ownerToken")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request))
            )
                .andDo(print())
                .andExpect(status().isOk)
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.id").value(channel.id))
                .andExpect(jsonPath("$.data.name").value(request.name))
        }

        @Test
        @DisplayName("DELETE /api/channels/{channelId} - 채널 삭제 성공")
        fun deleteChannel_success() {
            // Given: Create a deletable channel
            val deletableChannel = channelRepository.save(
                Channel(
                    name = "삭제용 채널",
                    description = "삭제 테스트",
                    type = ChannelType.TEXT,
                    workspace = workspace,
                    group = group,
                    createdBy = owner
                )
            )

            // When & Then
            mockMvc.perform(
                delete("/api/channels/${deletableChannel.id}")
                    .header("Authorization", "Bearer $ownerToken")
            )
                .andDo(print())
                .andExpect(status().isNoContent)
        }

        @Test
        @DisplayName("GET /api/channels/{channelId}/permissions/me - 내 채널 권한 조회 성공")
        fun getMyChannelPermissions_success() {
            // Given: Member has channel permissions

            // When & Then
            mockMvc.perform(
                get("/api/channels/${channel.id}/permissions/me")
                    .header("Authorization", "Bearer $memberToken")
                    .accept(MediaType.APPLICATION_JSON)
            )
                .andDo(print())
                .andExpect(status().isOk)
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.permissions").isArray)
                .andExpect(jsonPath("$.data.permissions").isNotEmpty)
        }
    }

    // ===================================
    // Post Tests
    // ===================================
    @Nested
    @DisplayName("게시글 관리 테스트")
    inner class PostManagementTest {
        private lateinit var post: Post

        @Test
        @DisplayName("GET /api/channels/{channelId}/posts - 게시글 목록 조회 성공")
        fun getChannelPosts_success() {
            // Given: Member has POST_READ permission
            createTestPost()

            // When & Then
            mockMvc.perform(
                get("/api/channels/${channel.id}/posts")
                    .header("Authorization", "Bearer $memberToken")
                    .accept(MediaType.APPLICATION_JSON)
            )
                .andDo(print())
                .andExpect(status().isOk)
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data[0].content").value("테스트 게시글"))
        }

        @Test
        @DisplayName("GET /api/channels/{channelId}/posts - 비멤버는 403")
        fun getChannelPosts_forbiddenForNonMember() {
            // Given: Outsider is not a member

            // When & Then
            mockMvc.perform(
                get("/api/channels/${channel.id}/posts")
                    .header("Authorization", "Bearer $outsiderToken")
                    .accept(MediaType.APPLICATION_JSON)
            )
                .andDo(print())
                .andExpect(status().isForbidden)
        }

        @Test
        @DisplayName("POST /api/channels/{channelId}/posts - 게시글 작성 성공")
        fun createPost_success() {
            // Given: Member has POST_WRITE permission
            val request = CreatePostRequest(
                content = "새 게시글입니다",
                type = "GENERAL"
            )

            // When & Then
            mockMvc.perform(
                post("/api/channels/${channel.id}/posts")
                    .header("Authorization", "Bearer $memberToken")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request))
            )
                .andDo(print())
                .andExpect(status().isCreated)
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.content").value(request.content))
        }

        @Test
        @DisplayName("GET /api/posts/{postId} - 게시글 상세 조회 성공")
        fun getPost_success() {
            // Given
            createTestPost()

            // When & Then
            mockMvc.perform(
                get("/api/posts/${post.id}")
                    .header("Authorization", "Bearer $memberToken")
                    .accept(MediaType.APPLICATION_JSON)
            )
                .andDo(print())
                .andExpect(status().isOk)
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.id").value(post.id))
                .andExpect(jsonPath("$.data.content").value("테스트 게시글"))
        }

        @Test
        @DisplayName("PUT /api/posts/{postId} - 게시글 수정 성공 (작성자)")
        fun updatePost_success() {
            // Given: Member created the post
            createTestPost()
            val request = UpdatePostRequest(
                content = "수정된 게시글",
                type = "GENERAL"
            )

            // When & Then
            mockMvc.perform(
                put("/api/posts/${post.id}")
                    .header("Authorization", "Bearer $memberToken")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request))
            )
                .andDo(print())
                .andExpect(status().isOk)
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.content").value(request.content))
        }

        @Test
        @DisplayName("PUT /api/posts/{postId} - 다른 사용자는 수정 불가 403")
        fun updatePost_forbiddenForOtherUser() {
            // Given: Member created the post, Owner tries to update
            createTestPost()
            val request = UpdatePostRequest(
                content = "타인이 수정 시도",
                type = "GENERAL"
            )

            // When & Then
            mockMvc.perform(
                put("/api/posts/${post.id}")
                    .header("Authorization", "Bearer $ownerToken")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request))
            )
                .andDo(print())
                .andExpect(status().isForbidden)
        }

        @Test
        @DisplayName("DELETE /api/posts/{postId} - 게시글 삭제 성공 (작성자)")
        fun deletePost_success() {
            // Given
            createTestPost()

            // When & Then
            mockMvc.perform(
                delete("/api/posts/${post.id}")
                    .header("Authorization", "Bearer $memberToken")
            )
                .andDo(print())
                .andExpect(status().isNoContent)
        }

        @Test
        @DisplayName("DELETE /api/posts/{postId} - 그룹 관리자는 다른 사람 게시글 삭제 가능")
        fun deletePost_successForAdmin() {
            // Given: Member created post, Owner (admin) deletes
            createTestPost()

            // When & Then
            mockMvc.perform(
                delete("/api/posts/${post.id}")
                    .header("Authorization", "Bearer $ownerToken")
            )
                .andDo(print())
                .andExpect(status().isNoContent)
        }

        private fun createTestPost() {
            post = postRepository.save(
                Post(
                    channel = channel,
                    author = member,
                    content = "테스트 게시글",
                    type = PostType.GENERAL
                )
            )
        }
    }

    // ===================================
    // Comment Tests
    // ===================================
    @Nested
    @DisplayName("댓글 관리 테스트")
    inner class CommentManagementTest {
        private lateinit var post: Post
        private lateinit var comment: Comment

        @Test
        @DisplayName("GET /api/posts/{postId}/comments - 댓글 목록 조회 성공")
        fun getComments_success() {
            // Given: Member has access to post
            createTestPostAndComment()

            // When & Then
            mockMvc.perform(
                get("/api/posts/${post.id}/comments")
                    .header("Authorization", "Bearer $memberToken")
                    .accept(MediaType.APPLICATION_JSON)
            )
                .andDo(print())
                .andExpect(status().isOk)
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data[0].content").value("테스트 댓글"))
        }

        @Test
        @DisplayName("POST /api/posts/{postId}/comments - 댓글 작성 성공")
        fun createComment_success() {
            // Given
            createTestPost()
            val request = CreateCommentRequest(
                content = "새 댓글입니다",
                parentCommentId = null
            )

            // When & Then
            mockMvc.perform(
                post("/api/posts/${post.id}/comments")
                    .header("Authorization", "Bearer $memberToken")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request))
            )
                .andDo(print())
                .andExpect(status().isCreated)
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.content").value(request.content))
        }

        @Test
        @DisplayName("PUT /api/comments/{commentId} - 댓글 수정 성공 (작성자)")
        fun updateComment_success() {
            // Given
            createTestPostAndComment()
            val request = UpdateCommentRequest(
                content = "수정된 댓글"
            )

            // When & Then
            mockMvc.perform(
                put("/api/comments/${comment.id}")
                    .header("Authorization", "Bearer $memberToken")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request))
            )
                .andDo(print())
                .andExpect(status().isOk)
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.content").value(request.content))
        }

        @Test
        @DisplayName("PUT /api/comments/{commentId} - 다른 사용자는 수정 불가 403")
        fun updateComment_forbiddenForOtherUser() {
            // Given: Member created comment, Owner tries to update
            createTestPostAndComment()
            val request = UpdateCommentRequest(
                content = "타인이 수정 시도"
            )

            // When & Then
            mockMvc.perform(
                put("/api/comments/${comment.id}")
                    .header("Authorization", "Bearer $ownerToken")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request))
            )
                .andDo(print())
                .andExpect(status().isForbidden)
        }

        @Test
        @DisplayName("DELETE /api/comments/{commentId} - 댓글 삭제 성공 (작성자)")
        fun deleteComment_success() {
            // Given
            createTestPostAndComment()

            // When & Then
            mockMvc.perform(
                delete("/api/comments/${comment.id}")
                    .header("Authorization", "Bearer $memberToken")
            )
                .andDo(print())
                .andExpect(status().isNoContent)
        }

        @Test
        @DisplayName("DELETE /api/comments/{commentId} - 다른 사용자는 삭제 불가 403")
        fun deleteComment_forbidden() {
            // Given: Member created comment, Owner tries to delete
            createTestPostAndComment()

            // When & Then
            mockMvc.perform(
                delete("/api/comments/${comment.id}")
                    .header("Authorization", "Bearer $ownerToken")
            )
                .andDo(print())
                .andExpect(status().isForbidden)
        }

        private fun createTestPost() {
            post = postRepository.save(
                Post(
                    channel = channel,
                    author = member,
                    content = "댓글 테스트용 게시글",
                    type = PostType.GENERAL
                )
            )
        }

        private fun createTestPostAndComment() {
            createTestPost()
            comment = commentRepository.save(
                Comment(
                    post = post,
                    author = member,
                    content = "테스트 댓글"
                )
            )
        }
    }
}
