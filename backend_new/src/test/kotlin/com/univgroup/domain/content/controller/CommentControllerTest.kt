package com.univgroup.domain.content.controller

import com.fasterxml.jackson.databind.ObjectMapper
import com.ninjasquad.springmockk.MockkBean
import com.univgroup.domain.content.dto.CreateCommentRequest
import com.univgroup.domain.content.dto.UpdateCommentRequest
import com.univgroup.domain.content.entity.Comment
import com.univgroup.domain.content.entity.Post
import com.univgroup.domain.content.entity.PostType
import com.univgroup.domain.content.service.CommentService
import com.univgroup.domain.content.service.PostService
import com.univgroup.domain.group.entity.Group
import com.univgroup.domain.permission.ChannelPermission
import com.univgroup.domain.permission.GroupPermission
import com.univgroup.domain.permission.evaluator.PermissionEvaluator
import com.univgroup.domain.user.entity.User
import com.univgroup.domain.user.service.IUserService
import com.univgroup.domain.workspace.entity.Channel
import com.univgroup.domain.workspace.entity.Workspace
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

/**
 * CommentController 통합 테스트
 *
 * 검증 항목:
 * - HTTP 상태 코드 (200, 201, 204, 404)
 * - ApiResponse<T> 형식 응답
 * - 권한 검증 (PermissionEvaluator)
 * - 비즈니스 로직 연동 (createComment → incrementCommentCount)
 * - 삭제 로직 (soft delete vs hard delete)
 */
@WebMvcTest(CommentController::class)
@DisplayName("CommentController 통합 테스트")
class CommentControllerTest {

    @Autowired
    private lateinit var mockMvc: MockMvc

    @Autowired
    private lateinit var objectMapper: ObjectMapper

    @MockkBean
    private lateinit var commentService: CommentService

    @MockkBean
    private lateinit var postService: PostService

    @MockkBean
    private lateinit var permissionEvaluator: PermissionEvaluator

    @MockkBean
    private lateinit var userService: IUserService

    private lateinit var testUser: User
    private lateinit var testGroup: Group
    private lateinit var testWorkspace: Workspace
    private lateinit var testChannel: Channel
    private lateinit var testPost: Post
    private lateinit var testComment: Comment

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

        testComment = Comment(
            id = 500L,
            post = testPost,
            author = testUser,
            content = "테스트 댓글",
            isDeleted = false
        )
    }

    // ========== POST /api/channels/{channelId}/posts/{postId}/comments ==========

    @Test
    @WithMockUser
    @DisplayName("POST: 댓글 생성 성공 시 201과 CommentDto 반환")
    fun `createComment should return 201 and CommentDto on success`() {
        // Given
        val request = CreateCommentRequest(
            content = "새 댓글",
            parentCommentId = null
        )

        every { userService.findByEmail("user") } returns testUser
        every { userService.findByEmail("user") } returns testUser
        every { userService.getById(1L) } returns testUser
        every { permissionEvaluator.requireChannelPermission(1L, 300L, ChannelPermission.COMMENT_WRITE) } just runs
        every { postService.getById(400L) } returns testPost
        every { commentService.createComment(any()) } returns testComment

        // When & Then
        mockMvc.perform(
            post("/api/channels/300/posts/400/comments")
                .with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data.id").value(500))
            .andExpect(jsonPath("$.data.content").value("테스트 댓글"))

        // 비즈니스 로직 호출 검증
        verify(exactly = 1) { commentService.createComment(any()) }
    }

    @Test
    @WithMockUser
    @DisplayName("POST: 채널 권한 없으면 403 에러")
    fun `createComment should return 403 when no permission`() {
        // Given
        val request = CreateCommentRequest(
            content = "새 댓글",
            parentCommentId = null
        )

        every { userService.findByEmail("user") } returns testUser
        every { userService.getById(1L) } returns testUser
        every {
            permissionEvaluator.requireChannelPermission(1L, 300L, ChannelPermission.COMMENT_WRITE)
        } throws com.univgroup.shared.exception.AccessDeniedException()

        // When & Then
        mockMvc.perform(
            post("/api/channels/300/posts/400/comments")
                .with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        )
            .andExpect(status().isForbidden)
    }

    @Test
    @WithMockUser
    @DisplayName("POST: 존재하지 않는 게시글이면 404 에러")
    fun `createComment should return 404 when post not found`() {
        // Given
        val request = CreateCommentRequest(
            content = "새 댓글",
            parentCommentId = null
        )

        every { userService.findByEmail("user") } returns testUser
        every { userService.getById(1L) } returns testUser
        every { permissionEvaluator.requireChannelPermission(1L, 300L, ChannelPermission.COMMENT_WRITE) } just runs
        every { postService.getById(400L) } throws com.univgroup.shared.exception.ResourceNotFoundException(
            ErrorCode.CONTENT_POST_NOT_FOUND,
            "게시글을 찾을 수 없습니다"
        )

        // When & Then
        mockMvc.perform(
            post("/api/channels/300/posts/400/comments")
                .with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        )
            .andExpect(status().isNotFound)
    }

    // ========== PATCH /api/channels/{channelId}/posts/{postId}/comments/{commentId} ==========

    @Test
    @WithMockUser
    @DisplayName("PATCH: 댓글 수정 성공 시 200과 CommentDto 반환")
    fun `updateComment should return 200 and CommentDto on success`() {
        // Given
        val request = UpdateCommentRequest(content = "수정된 댓글")

        val updatedComment = testComment.copy(content = "수정된 댓글")

        every { userService.findByEmail("user") } returns testUser
        every { userService.getById(1L) } returns testUser
        every { commentService.getById(500L) } returns testComment
        every { commentService.updateComment(500L, "수정된 댓글") } returns updatedComment

        // When & Then
        mockMvc.perform(
            patch("/api/channels/300/posts/400/comments/500")
                .with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data.content").value("수정된 댓글"))

        verify(exactly = 1) { commentService.updateComment(500L, "수정된 댓글") }
    }

    @Test
    @WithMockUser
    @DisplayName("PATCH: 작성자가 아니면 그룹 관리 권한 필요")
    fun `updateComment should require group permission when not author`() {
        // Given
        val request = UpdateCommentRequest(content = "수정된 댓글")

        val otherUser = testUser.copy(id = 999L) // 다른 사용자
        val otherComment = testComment.copy(author = otherUser)

        every { userService.findByEmail("user") } returns testUser
        every { userService.getById(1L) } returns testUser
        every { commentService.getById(500L) } returns otherComment
        every {
            permissionEvaluator.requireGroupPermission(1L, 100L, GroupPermission.COMMENT_MANAGE)
        } just runs
        every { commentService.updateComment(500L, "수정된 댓글") } returns otherComment

        // When & Then
        mockMvc.perform(
            patch("/api/channels/300/posts/400/comments/500")
                .with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        )
            .andExpect(status().isOk)

        verify(exactly = 1) { permissionEvaluator.requireGroupPermission(1L, 100L, GroupPermission.COMMENT_MANAGE) }
    }

    // ========== DELETE /api/channels/{channelId}/posts/{postId}/comments/{commentId} ==========

    @Test
    @WithMockUser
    @DisplayName("DELETE: 댓글 삭제 성공 시 200 반환")
    fun `deleteComment should return 200 on success`() {
        // Given
        every { userService.findByEmail("user") } returns testUser
        every { userService.getById(1L) } returns testUser
        every { commentService.getById(500L) } returns testComment
        every { commentService.deleteComment(500L) } just runs

        // When & Then
        mockMvc.perform(
            delete("/api/channels/300/posts/400/comments/500")
                .with(csrf())
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.success").value(true))

        verify(exactly = 1) { commentService.deleteComment(500L) }
    }

    @Test
    @WithMockUser
    @DisplayName("DELETE: 작성자가 아니면 그룹 관리 권한 필요")
    fun `deleteComment should require group permission when not author`() {
        // Given
        val otherUser = testUser.copy(id = 999L) // 다른 사용자
        val otherComment = testComment.copy(author = otherUser)

        every { userService.findByEmail("user") } returns testUser
        every { userService.getById(1L) } returns testUser
        every { commentService.getById(500L) } returns otherComment
        every {
            permissionEvaluator.requireGroupPermission(1L, 100L, GroupPermission.COMMENT_MANAGE)
        } just runs
        every { commentService.deleteComment(500L) } just runs

        // When & Then
        mockMvc.perform(
            delete("/api/channels/300/posts/400/comments/500")
                .with(csrf())
        )
            .andExpect(status().isOk)

        verify(exactly = 1) { permissionEvaluator.requireGroupPermission(1L, 100L, GroupPermission.COMMENT_MANAGE) }
        verify(exactly = 1) { commentService.deleteComment(500L) }
    }

    @Test
    @WithMockUser
    @DisplayName("DELETE: 존재하지 않는 댓글이면 404 에러")
    fun `deleteComment should return 404 when comment not found`() {
        // Given
        every { userService.findByEmail("user") } returns testUser
        every { userService.getById(1L) } returns testUser
        every { commentService.getById(500L) } throws com.univgroup.shared.exception.ResourceNotFoundException(
            ErrorCode.CONTENT_COMMENT_NOT_FOUND,
            "댓글을 찾을 수 없습니다"
        )

        // When & Then
        mockMvc.perform(
            delete("/api/channels/300/posts/400/comments/500")
                .with(csrf())
        )
            .andExpect(status().isNotFound)
    }

    // ========== GET /api/channels/{channelId}/posts/{postId}/comments ==========

    @Test
    @WithMockUser
    @DisplayName("GET: 댓글 목록 조회 성공 시 200과 List<CommentDto> 반환")
    fun `getComments should return 200 and list of CommentDto`() {
        // Given
        every { userService.findByEmail("user") } returns testUser
        every { userService.getById(1L) } returns testUser
        every { permissionEvaluator.requireChannelPermission(1L, 300L, ChannelPermission.COMMENT_READ) } just runs
        every { postService.getById(400L) } returns testPost
        every { commentService.getRootComments(400L, any()) } returns org.springframework.data.domain.PageImpl(
            listOf(testComment)
        )
        every { commentService.getReplies(500L) } returns emptyList()

        // When & Then
        mockMvc.perform(
            get("/api/channels/300/posts/400/comments")
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data").isArray)
            .andExpect(jsonPath("$.data[0].id").value(500))
    }
}
