package com.univgroup.domain.content.service

import com.univgroup.domain.content.entity.Comment
import com.univgroup.domain.content.entity.Post
import com.univgroup.domain.content.repository.CommentRepository
import com.univgroup.domain.content.repository.PostRepository
import io.mockk.*
import org.assertj.core.api.Assertions.assertThat
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Test
import java.util.*

/**
 * CommentService 단위 테스트
 *
 * 검증 항목:
 * - createComment: 댓글 생성 시 Post.incrementCommentCount 호출
 * - deleteComment: Soft delete vs Hard delete 로직
 */
@DisplayName("CommentService 단위 테스트")
class CommentServiceTest {

    private lateinit var commentService: CommentService
    private lateinit var commentRepository: CommentRepository
    private lateinit var postRepository: PostRepository

    private lateinit var testPost: Post
    private lateinit var testComment: Comment

    @BeforeEach
    fun setUp() {
        // Mock Repository 생성
        commentRepository = mockk()
        postRepository = mockk()

        // Service 생성
        commentService = CommentService(
            commentRepository = commentRepository,
            postRepository = postRepository
        )

        // 테스트용 Entity 생성
        testPost = mockk(relaxed = true) {
            every { id } returns 1L
        }

        testComment = mockk(relaxed = true) {
            every { id } returns 1L
            every { post } returns testPost
            every { isDeleted } returns false
        }
    }

    // ========== createComment 테스트 ==========

    @Test
    @DisplayName("createComment: 댓글을 저장해야 한다")
    fun `createComment should save comment`() {
        // Given
        every { commentRepository.save(any()) } returns testComment
        every { postRepository.findById(1L) } returns Optional.of(testPost)
        every { postRepository.save(any()) } returns testPost

        // When
        val result = commentService.createComment(testComment)

        // Then
        assertThat(result).isEqualTo(testComment)
        verify(exactly = 1) { commentRepository.save(testComment) }
    }

    @Test
    @DisplayName("createComment: 게시글의 commentCount를 증가시켜야 한다")
    fun `createComment should increment post comment count`() {
        // Given
        every { commentRepository.save(any()) } returns testComment
        every { postRepository.findById(1L) } returns Optional.of(testPost)
        every { postRepository.save(any()) } returns testPost

        // When
        commentService.createComment(testComment)

        // Then
        verify(exactly = 1) { testPost.incrementCommentCount() }
        verify(exactly = 1) { postRepository.save(testPost) }
    }

    @Test
    @DisplayName("createComment: 게시글이 없으면 commentCount를 증가시키지 않아야 한다")
    fun `createComment should not increment count if post not found`() {
        // Given
        every { commentRepository.save(any()) } returns testComment
        every { postRepository.findById(1L) } returns Optional.empty()

        // When
        commentService.createComment(testComment)

        // Then
        verify(exactly = 0) { testPost.incrementCommentCount() }
        verify(exactly = 0) { postRepository.save(any()) }
    }

    // ========== deleteComment 테스트 ==========

    @Test
    @DisplayName("deleteComment: 대댓글이 있으면 soft delete 해야 한다")
    fun `deleteComment should soft delete if has replies`() {
        // Given
        every { commentRepository.findById(1L) } returns Optional.of(testComment)
        every { commentRepository.countByParentCommentId(1L) } returns 3 // 대댓글 3개
        every { commentRepository.save(any()) } returns testComment

        // When
        commentService.deleteComment(1L)

        // Then
        verify(exactly = 1) { testComment.softDelete() }
        verify(exactly = 1) { commentRepository.save(testComment) }
        verify(exactly = 0) { commentRepository.delete(any()) }
    }

    @Test
    @DisplayName("deleteComment: 대댓글이 없으면 hard delete 해야 한다")
    fun `deleteComment should hard delete if no replies`() {
        // Given
        every { commentRepository.findById(1L) } returns Optional.of(testComment)
        every { commentRepository.countByParentCommentId(1L) } returns 0 // 대댓글 없음
        every { commentRepository.delete(any()) } just Runs
        every { postRepository.findById(1L) } returns Optional.of(testPost)
        every { postRepository.save(any()) } returns testPost

        // When
        commentService.deleteComment(1L)

        // Then
        verify(exactly = 0) { testComment.softDelete() }
        verify(exactly = 1) { commentRepository.delete(testComment) }
    }

    @Test
    @DisplayName("deleteComment (hard): 게시글의 commentCount를 감소시켜야 한다")
    fun `deleteComment should decrement post comment count on hard delete`() {
        // Given
        every { commentRepository.findById(1L) } returns Optional.of(testComment)
        every { commentRepository.countByParentCommentId(1L) } returns 0
        every { commentRepository.delete(any()) } just Runs
        every { postRepository.findById(1L) } returns Optional.of(testPost)
        every { postRepository.save(any()) } returns testPost

        // When
        commentService.deleteComment(1L)

        // Then
        verify(exactly = 1) { testPost.decrementCommentCount() }
        verify(exactly = 1) { postRepository.save(testPost) }
    }

    @Test
    @DisplayName("deleteComment (soft): 게시글의 commentCount를 감소시키지 않아야 한다")
    fun `deleteComment should not decrement count on soft delete`() {
        // Given
        every { commentRepository.findById(1L) } returns Optional.of(testComment)
        every { commentRepository.countByParentCommentId(1L) } returns 5 // 대댓글 있음
        every { commentRepository.save(any()) } returns testComment

        // When
        commentService.deleteComment(1L)

        // Then
        verify(exactly = 0) { testPost.decrementCommentCount() }
        verify(exactly = 0) { postRepository.save(any()) }
    }

    @Test
    @DisplayName("deleteComment (hard): 게시글이 없어도 에러 없이 처리되어야 한다")
    fun `deleteComment should handle missing post gracefully on hard delete`() {
        // Given
        every { commentRepository.findById(1L) } returns Optional.of(testComment)
        every { commentRepository.countByParentCommentId(1L) } returns 0
        every { commentRepository.delete(any()) } just Runs
        every { postRepository.findById(1L) } returns Optional.empty()

        // When
        commentService.deleteComment(1L)

        // Then
        verify(exactly = 1) { commentRepository.delete(testComment) }
        verify(exactly = 0) { postRepository.save(any()) }
    }

    @Test
    @DisplayName("deleteComment: 대댓글이 정확히 1개 있어도 soft delete 해야 한다")
    fun `deleteComment should soft delete with exactly one reply`() {
        // Given
        every { commentRepository.findById(1L) } returns Optional.of(testComment)
        every { commentRepository.countByParentCommentId(1L) } returns 1 // 대댓글 1개
        every { commentRepository.save(any()) } returns testComment

        // When
        commentService.deleteComment(1L)

        // Then
        verify(exactly = 1) { testComment.softDelete() }
        verify(exactly = 1) { commentRepository.save(testComment) }
    }
}
