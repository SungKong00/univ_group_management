package com.univgroup.domain.content.service

import com.univgroup.domain.content.entity.Post
import com.univgroup.domain.content.entity.PostType
import com.univgroup.domain.content.repository.CommentRepository
import com.univgroup.domain.content.repository.PostRepository
import com.univgroup.domain.user.entity.User
import com.univgroup.domain.workspace.entity.Channel
import com.univgroup.shared.exception.ResourceNotFoundException
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.assertj.core.api.Assertions.assertThat
import org.assertj.core.api.Assertions.assertThatThrownBy
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Test
import org.springframework.data.domain.PageImpl
import org.springframework.data.domain.PageRequest
import java.util.*

@DisplayName("PostService 단위 테스트")
class PostServiceTest {
    private lateinit var postService: PostService
    private lateinit var postRepository: PostRepository
    private lateinit var commentRepository: CommentRepository

    // Test Entities
    private lateinit var testUser: User
    private lateinit var testChannel: Channel
    private lateinit var testPost: Post

    @BeforeEach
    fun setUp() {
        postRepository = mockk()
        commentRepository = mockk()
        postService = PostService(postRepository, commentRepository)

        // Test User
        testUser = mockk(relaxed = true) {
            every { id } returns 1L
            every { email } returns "user@example.com"
            every { name } returns "User"
        }

        // Test Channel
        testChannel = mockk(relaxed = true) {
            every { id } returns 1L
            every { name } returns "Test Channel"
        }

        // Test Post
        testPost = mockk(relaxed = true) {
            every { id } returns 1L
            every { content } returns "Test Content"
            every { channel } returns testChannel
            every { author } returns testUser
            every { type } returns PostType.GENERAL
            every { isPinned } returns false
        }
    }

    // ========== findById ==========

    @Test
    fun `findById should return post when post exists`() {
        // Given
        every { postRepository.findById(1L) } returns Optional.of(testPost)

        // When
        val result = postService.findById(1L)

        // Then
        assertThat(result).isNotNull
        assertThat(result?.id).isEqualTo(1L)
        assertThat(result?.content).isEqualTo("Test Content")
        verify(exactly = 1) { postRepository.findById(1L) }
    }

    @Test
    fun `findById should return null when post does not exist`() {
        // Given
        every { postRepository.findById(999L) } returns Optional.empty()

        // When
        val result = postService.findById(999L)

        // Then
        assertThat(result).isNull()
        verify(exactly = 1) { postRepository.findById(999L) }
    }

    // ========== getById ==========

    @Test
    fun `getById should return post when post exists`() {
        // Given
        every { postRepository.findById(1L) } returns Optional.of(testPost)

        // When
        val result = postService.getById(1L)

        // Then
        assertThat(result).isNotNull
        assertThat(result.id).isEqualTo(1L)
        verify(exactly = 1) { postRepository.findById(1L) }
    }

    @Test
    fun `getById should throw ResourceNotFoundException when post does not exist`() {
        // Given
        every { postRepository.findById(999L) } returns Optional.empty()

        // When & Then
        assertThatThrownBy { postService.getById(999L) }
            .isInstanceOf(ResourceNotFoundException::class.java)
            .hasMessageContaining("게시글을 찾을 수 없습니다: 999")

        verify(exactly = 1) { postRepository.findById(999L) }
    }

    // ========== getPostsByChannel ==========

    @Test
    fun `getPostsByChannel should return page of posts`() {
        // Given
        val pageable = PageRequest.of(0, 10)
        val posts = listOf(testPost)
        val page = PageImpl(posts, pageable, 1)
        every { postRepository.findByChannelIdWithAuthor(1L, pageable) } returns page

        // When
        val result = postService.getPostsByChannel(1L, pageable)

        // Then
        assertThat(result.content).hasSize(1)
        assertThat(result.totalElements).isEqualTo(1)
        verify(exactly = 1) { postRepository.findByChannelIdWithAuthor(1L, pageable) }
    }

    // ========== getPinnedPosts ==========

    @Test
    fun `getPinnedPosts should return pinned posts`() {
        // Given
        val pinnedPost = mockk<Post>(relaxed = true) {
            every { id } returns 2L
            every { isPinned } returns true
        }
        every { postRepository.findPinnedPosts(1L) } returns listOf(pinnedPost)

        // When
        val result = postService.getPinnedPosts(1L)

        // Then
        assertThat(result).hasSize(1)
        assertThat(result[0].id).isEqualTo(2L)
        verify(exactly = 1) { postRepository.findPinnedPosts(1L) }
    }

    // ========== getPostsByType ==========

    @Test
    fun `getPostsByType should return posts of specific type`() {
        // Given
        val pageable = PageRequest.of(0, 10)
        val posts = listOf(testPost)
        val page = PageImpl(posts, pageable, 1)
        every { postRepository.findByChannelIdAndType(1L, PostType.GENERAL, pageable) } returns page

        // When
        val result = postService.getPostsByType(1L, PostType.GENERAL, pageable)

        // Then
        assertThat(result.content).hasSize(1)
        verify(exactly = 1) { postRepository.findByChannelIdAndType(1L, PostType.GENERAL, pageable) }
    }

    // ========== getPostsByAuthor ==========

    @Test
    fun `getPostsByAuthor should return posts by author`() {
        // Given
        val pageable = PageRequest.of(0, 10)
        val posts = listOf(testPost)
        val page = PageImpl(posts, pageable, 1)
        every { postRepository.findByAuthorIdWithChannel(1L, pageable) } returns page

        // When
        val result = postService.getPostsByAuthor(1L, pageable)

        // Then
        assertThat(result.content).hasSize(1)
        verify(exactly = 1) { postRepository.findByAuthorIdWithChannel(1L, pageable) }
    }

    // ========== searchInChannel ==========

    @Test
    fun `searchInChannel should return posts matching keyword`() {
        // Given
        val pageable = PageRequest.of(0, 10)
        val posts = listOf(testPost)
        val page = PageImpl(posts, pageable, 1)
        every { postRepository.searchInChannel(1L, "Test", pageable) } returns page

        // When
        val result = postService.searchInChannel(1L, "Test", pageable)

        // Then
        assertThat(result.content).hasSize(1)
        verify(exactly = 1) { postRepository.searchInChannel(1L, "Test", pageable) }
    }

    // ========== createPost ==========

    @Test
    fun `createPost should create post successfully`() {
        // Given
        val savedPost = mockk<Post>(relaxed = true) {
            every { id } returns 2L
        }
        every { postRepository.save(testPost) } returns savedPost

        // When
        val result = postService.createPost(testPost)

        // Then
        assertThat(result.id).isEqualTo(2L)
        verify(exactly = 1) { postRepository.save(testPost) }
    }

    // ========== updatePost ==========

    @Test
    fun `updatePost should update post successfully`() {
        // Given
        every { postRepository.findById(1L) } returns Optional.of(testPost)
        every { postRepository.save(any()) } returns testPost

        // When
        postService.updatePost(1L) { _ ->
            // Update logic
        }

        // Then
        verify(exactly = 1) { postRepository.findById(1L) }
        verify(exactly = 1) { postRepository.save(any()) }
    }

    // ========== deletePost ==========

    @Test
    fun `deletePost should delete post with comments`() {
        // Given
        every { postRepository.findById(1L) } returns Optional.of(testPost)
        every { commentRepository.deleteAllByPostId(1L) } returns Unit
        every { postRepository.delete(testPost) } returns Unit

        // When
        postService.deletePost(1L)

        // Then
        verify(exactly = 1) { postRepository.findById(1L) }
        verify(exactly = 1) { commentRepository.deleteAllByPostId(1L) }
        verify(exactly = 1) { postRepository.delete(testPost) }
    }

    // ========== incrementViewCount ==========

    @Test
    fun `incrementViewCount should increment view count`() {
        // Given
        every { postRepository.incrementViewCount(1L) } returns Unit

        // When
        postService.incrementViewCount(1L)

        // Then
        verify(exactly = 1) { postRepository.incrementViewCount(1L) }
    }

    // ========== togglePin ==========

    @Test
    fun `togglePin should toggle pin status`() {
        // Given
        val pinnedPost = testPost.copy(isPinned = true)
        every { postRepository.findById(1L) } returns Optional.of(testPost)
        every { postRepository.save(any()) } returns pinnedPost

        // When
        postService.togglePin(1L)

        // Then
        verify(exactly = 1) { postRepository.findById(1L) }
        verify(exactly = 1) { postRepository.save(any()) }
    }

    // ========== getPostCount ==========

    @Test
    fun `getPostCount should return post count`() {
        // Given
        every { postRepository.countByChannelId(1L) } returns 5L

        // When
        val result = postService.getPostCount(1L)

        // Then
        assertThat(result).isEqualTo(5L)
        verify(exactly = 1) { postRepository.countByChannelId(1L) }
    }
}
