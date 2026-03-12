package com.univgroup.domain.content.controller

import com.fasterxml.jackson.databind.ObjectMapper
import com.ninjasquad.springmockk.MockkBean
import com.univgroup.domain.content.dto.CreatePostRequest
import com.univgroup.domain.content.dto.UpdatePostRequest
import com.univgroup.domain.content.entity.Post
import com.univgroup.domain.content.entity.PostType
import com.univgroup.domain.content.service.PostService
import com.univgroup.domain.group.entity.Group
import com.univgroup.domain.permission.ChannelPermission
import com.univgroup.domain.permission.GroupPermission
import com.univgroup.domain.permission.evaluator.PermissionEvaluator
import com.univgroup.domain.user.entity.User
import com.univgroup.domain.user.service.IUserService
import com.univgroup.domain.workspace.entity.Channel
import com.univgroup.domain.workspace.entity.Workspace
import com.univgroup.domain.workspace.repository.ChannelRepository
import com.univgroup.shared.dto.ErrorCode
import io.mockk.every
import io.mockk.just
import io.mockk.runs
import io.mockk.verify
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest
import org.springframework.http.MediaType
import org.springframework.security.test.context.support.WithMockUser
import org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.*
import java.util.*

/**
 * PostController 통합 테스트
 *
 * 검증 항목:
 * - HTTP 상태 코드 (200, 404)
 * - ApiResponse<T> 형식 응답
 * - 권한 검증 (PermissionEvaluator)
 * - 게시글 고정 기능 (togglePin)
 */
@WebMvcTest(PostController::class)
@DisplayName("PostController 통합 테스트")
class PostControllerTest {

    @Autowired
    private lateinit var mockMvc: MockMvc

    @Autowired
    private lateinit var objectMapper: ObjectMapper

    @MockkBean
    private lateinit var postService: PostService

    @MockkBean
    private lateinit var channelRepository: ChannelRepository

    @MockkBean
    private lateinit var permissionEvaluator: PermissionEvaluator

    @MockkBean
    private lateinit var userService: IUserService

    private lateinit var testUser: User
    private lateinit var testGroup: Group
    private lateinit var testWorkspace: Workspace
    private lateinit var testChannel: Channel
    private lateinit var testPost: Post

    @BeforeEach
    fun setUp() {
        // 테스트용 Entity 생성
        testUser = User(
            id = 1L,
            email = "test@test.com",
            name = "테스트 유저",
            password = "hashed-password",
            profileImageUrl = null
        )

        testGroup = Group(
            id = 100L,
            name = "테스트 그룹",
            description = "테스트",
            owner = testUser,
            university = null
        )

        testWorkspace = Workspace(
            id = 200L,
            group = testGroup,
            name = "테스트 워크스페이스",
            displayOrder = 0
        )

        testChannel = Channel(
            id = 300L,
            workspace = testWorkspace,
            group = testGroup,
            name = "테스트 채널",
            displayOrder = 0,
            createdBy = testUser
        )

        testPost = Post(
            id = 400L,
            channel = testChannel,
            author = testUser,
            content = "테스트 게시글",
            type = PostType.GENERAL
        )
    }

    // ========== POST /api/channels/{channelId}/posts ==========

    @Test
    @WithMockUser
    @DisplayName("POST: 게시글 생성 성공 시 200과 PostDto 반환")
    fun `createPost should return 200 and PostDto on success`() {
        // Given
        val request = CreatePostRequest(
            content = "새 게시글",
            type = PostType.GENERAL
        )

        every { userService.findByEmail("user") } returns testUser
        every { userService.getById(1L) } returns testUser
        every { permissionEvaluator.requireChannelPermission(1L, 300L, ChannelPermission.POST_WRITE) } just runs
        every { channelRepository.findById(300L) } returns Optional.of(testChannel)
        every { postService.createPost(any()) } returns testPost

        // When & Then
        mockMvc.perform(
            post("/api/channels/300/posts")
                .with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data.id").value(400))
            .andExpect(jsonPath("$.data.content").value("테스트 게시글"))

        verify(exactly = 1) { postService.createPost(any()) }
    }

    @Test
    @WithMockUser
    @DisplayName("POST: 채널 권한 없으면 403 에러")
    fun `createPost should return 403 when no permission`() {
        // Given
        val request = CreatePostRequest(
            content = "새 게시글",
            type = PostType.GENERAL
        )

        every { userService.findByEmail("user") } returns testUser
        every { userService.getById(1L) } returns testUser
        every {
            permissionEvaluator.requireChannelPermission(1L, 300L, ChannelPermission.POST_WRITE)
        } throws com.univgroup.shared.exception.AccessDeniedException()

        // When & Then
        mockMvc.perform(
            post("/api/channels/300/posts")
                .with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        )
            .andExpect(status().isForbidden)
    }

    @Test
    @WithMockUser
    @DisplayName("POST: 존재하지 않는 채널이면 404 에러")
    fun `createPost should return 404 when channel not found`() {
        // Given
        val request = CreatePostRequest(
            content = "새 게시글",
            type = PostType.GENERAL
        )

        every { userService.findByEmail("user") } returns testUser
        every { userService.getById(1L) } returns testUser
        every { permissionEvaluator.requireChannelPermission(1L, 300L, ChannelPermission.POST_WRITE) } just runs
        every { channelRepository.findById(300L) } returns Optional.empty()

        // When & Then
        mockMvc.perform(
            post("/api/channels/300/posts")
                .with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        )
            .andExpect(status().isNotFound)
    }

    // ========== GET /api/channels/{channelId}/posts/{postId} ==========

    @Test
    @WithMockUser
    @DisplayName("GET: 게시글 조회 성공 시 200과 PostDto 반환")
    fun `getPost should return 200 and PostDto on success`() {
        // Given
        every { userService.findByEmail("user") } returns testUser
        every { userService.getById(1L) } returns testUser
        every { permissionEvaluator.requireChannelPermission(1L, 300L, ChannelPermission.POST_READ) } just runs
        every { postService.getById(400L) } returns testPost
        every { postService.incrementViewCount(400L) } just runs

        // When & Then
        mockMvc.perform(
            get("/api/channels/300/posts/400")
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data.id").value(400))
            .andExpect(jsonPath("$.data.content").value("테스트 게시글"))

        verify(exactly = 1) { postService.incrementViewCount(400L) }
    }

    @Test
    @WithMockUser
    @DisplayName("GET: 채널 불일치 시 404 에러")
    fun `getPost should return 404 when channel mismatch`() {
        // Given
        val otherChannel = testChannel.copy(id = 999L)
        val postInOtherChannel = testPost.copy(channel = otherChannel)

        every { userService.findByEmail("user") } returns testUser
        every { userService.getById(1L) } returns testUser
        every { permissionEvaluator.requireChannelPermission(1L, 300L, ChannelPermission.POST_READ) } just runs
        every { postService.getById(400L) } returns postInOtherChannel

        // When & Then
        mockMvc.perform(
            get("/api/channels/300/posts/400")
        )
            .andExpect(status().isNotFound)
    }

    // ========== PATCH /api/channels/{channelId}/posts/{postId} ==========

    @Test
    @WithMockUser
    @DisplayName("PATCH: 게시글 수정 성공 시 200과 PostDto 반환")
    fun `updatePost should return 200 and PostDto on success`() {
        // Given
        val request = UpdatePostRequest(
            content = "수정된 게시글",
            type = PostType.ANNOUNCEMENT
        )

        val updatedPost = testPost.copy(content = "수정된 게시글", type = PostType.ANNOUNCEMENT)

        every { userService.findByEmail("user") } returns testUser
        every { userService.getById(1L) } returns testUser
        every { postService.getById(400L) } returns testPost
        every { postService.updatePost(400L, any()) } returns updatedPost

        // When & Then
        mockMvc.perform(
            patch("/api/channels/300/posts/400")
                .with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data.content").value("수정된 게시글"))

        verify(exactly = 1) { postService.updatePost(400L, any()) }
    }

    @Test
    @WithMockUser
    @DisplayName("PATCH: 작성자가 아니면 그룹 관리 권한 필요")
    fun `updatePost should require group permission when not author`() {
        // Given
        val request = UpdatePostRequest(content = "수정된 게시글", type = null)

        val otherUser = testUser.copy(id = 999L) // 다른 사용자
        val otherPost = testPost.copy(author = otherUser)

        every { userService.findByEmail("user") } returns testUser
        every { userService.getById(1L) } returns testUser
        every { postService.getById(400L) } returns otherPost
        every {
            permissionEvaluator.requireGroupPermission(1L, 100L, GroupPermission.POST_MANAGE)
        } just runs
        every { postService.updatePost(400L, any()) } returns otherPost

        // When & Then
        mockMvc.perform(
            patch("/api/channels/300/posts/400")
                .with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        )
            .andExpect(status().isOk)

        verify(exactly = 1) { permissionEvaluator.requireGroupPermission(1L, 100L, GroupPermission.POST_MANAGE) }
    }

    // ========== DELETE /api/channels/{channelId}/posts/{postId} ==========

    @Test
    @WithMockUser
    @DisplayName("DELETE: 게시글 삭제 성공 시 200 반환")
    fun `deletePost should return 200 on success`() {
        // Given
        every { userService.findByEmail("user") } returns testUser
        every { userService.getById(1L) } returns testUser
        every { postService.getById(400L) } returns testPost
        every { postService.deletePost(400L) } just runs

        // When & Then
        mockMvc.perform(
            delete("/api/channels/300/posts/400")
                .with(csrf())
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.success").value(true))

        verify(exactly = 1) { postService.deletePost(400L) }
    }

    @Test
    @WithMockUser
    @DisplayName("DELETE: 작성자가 아니면 그룹 관리 권한 필요")
    fun `deletePost should require group permission when not author`() {
        // Given
        val otherUser = testUser.copy(id = 999L) // 다른 사용자
        val otherPost = testPost.copy(author = otherUser)

        every { userService.findByEmail("user") } returns testUser
        every { userService.getById(1L) } returns testUser
        every { postService.getById(400L) } returns otherPost
        every {
            permissionEvaluator.requireGroupPermission(1L, 100L, GroupPermission.POST_MANAGE)
        } just runs
        every { postService.deletePost(400L) } just runs

        // When & Then
        mockMvc.perform(
            delete("/api/channels/300/posts/400")
                .with(csrf())
        )
            .andExpect(status().isOk)

        verify(exactly = 1) { permissionEvaluator.requireGroupPermission(1L, 100L, GroupPermission.POST_MANAGE) }
        verify(exactly = 1) { postService.deletePost(400L) }
    }

    // ========== PATCH /api/channels/{channelId}/posts/{postId}/pin ==========

    @Test
    @WithMockUser
    @DisplayName("PATCH /pin: 게시글 고정 성공 시 200과 PostDto 반환")
    fun `togglePin should return 200 and PostDto on success`() {
        // Given
        val pinnedPost = testPost.copy(pinnedAt = java.time.LocalDateTime.now())

        every { userService.findByEmail("user") } returns testUser
        every { userService.getById(1L) } returns testUser
        every { postService.getById(400L) } returns testPost
        every { permissionEvaluator.requireGroupPermission(1L, 100L, GroupPermission.POST_MANAGE) } just runs
        every { postService.togglePin(400L) } returns pinnedPost

        // When & Then
        mockMvc.perform(
            patch("/api/channels/300/posts/400/pin")
                .with(csrf())
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data.id").value(400))

        verify(exactly = 1) { permissionEvaluator.requireGroupPermission(1L, 100L, GroupPermission.POST_MANAGE) }
        verify(exactly = 1) { postService.togglePin(400L) }
    }

    @Test
    @WithMockUser
    @DisplayName("PATCH /pin: 그룹 관리 권한 없으면 403 에러")
    fun `togglePin should return 403 when no group permission`() {
        // Given
        every { userService.findByEmail("user") } returns testUser
        every { userService.getById(1L) } returns testUser
        every { postService.getById(400L) } returns testPost
        every {
            permissionEvaluator.requireGroupPermission(1L, 100L, GroupPermission.POST_MANAGE)
        } throws com.univgroup.shared.exception.AccessDeniedException()

        // When & Then
        mockMvc.perform(
            patch("/api/channels/300/posts/400/pin")
                .with(csrf())
        )
            .andExpect(status().isForbidden)
    }

    // ========== GET /api/channels/{channelId}/posts ==========

    @Test
    @WithMockUser
    @DisplayName("GET: 게시글 목록 조회 성공 시 200과 List<PostSummaryDto> 반환")
    fun `getPosts should return 200 and list of PostSummaryDto`() {
        // Given
        every { userService.findByEmail("user") } returns testUser
        every { userService.getById(1L) } returns testUser
        every { permissionEvaluator.requireChannelPermission(1L, 300L, ChannelPermission.POST_READ) } just runs
        every { postService.getPostsByChannel(300L, any()) } returns org.springframework.data.domain.PageImpl(
            listOf(testPost)
        )

        // When & Then
        mockMvc.perform(
            get("/api/channels/300/posts")
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data").isArray)
            .andExpect(jsonPath("$.data[0].id").value(400))
    }

    @Test
    @WithMockUser
    @DisplayName("GET /search: 검색 성공 시 200과 검색 결과 반환")
    fun `searchPosts should return 200 and search results`() {
        // Given
        every { userService.findByEmail("user") } returns testUser
        every { userService.getById(1L) } returns testUser
        every { permissionEvaluator.requireChannelPermission(1L, 300L, ChannelPermission.POST_READ) } just runs
        every { postService.searchInChannel(300L, "테스트", any()) } returns org.springframework.data.domain.PageImpl(
            listOf(testPost)
        )

        // When & Then
        mockMvc.perform(
            get("/api/channels/300/posts/search")
                .param("keyword", "테스트")
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data").isArray)

        verify(exactly = 1) { postService.searchInChannel(300L, "테스트", any()) }
    }
}
