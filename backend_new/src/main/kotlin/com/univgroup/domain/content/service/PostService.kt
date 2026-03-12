package com.univgroup.domain.content.service

import com.univgroup.domain.content.entity.Post
import com.univgroup.domain.content.entity.PostType
import com.univgroup.domain.content.repository.CommentRepository
import com.univgroup.domain.content.repository.PostRepository
import com.univgroup.shared.dto.ErrorCode
import com.univgroup.shared.exception.ResourceNotFoundException
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

/**
 * 게시글 서비스
 *
 * 게시글 관련 비즈니스 로직을 담당한다.
 */
@Service
@Transactional(readOnly = true)
class PostService(
    private val postRepository: PostRepository,
    private val commentRepository: CommentRepository,
) {
    // ========== 조회 ==========

    fun findById(postId: Long): Post? {
        return postRepository.findById(postId).orElse(null)
    }

    fun getById(postId: Long): Post {
        return postRepository.findById(postId).orElseThrow {
            ResourceNotFoundException(
                ErrorCode.CONTENT_POST_NOT_FOUND,
                "게시글을 찾을 수 없습니다: $postId",
            )
        }
    }

    /**
     * 채널의 게시글 목록 조회
     */
    fun getPostsByChannel(
        channelId: Long,
        pageable: Pageable,
    ): Page<Post> {
        return postRepository.findByChannelIdWithAuthor(channelId, pageable)
    }

    /**
     * 채널의 고정 게시글 조회
     */
    fun getPinnedPosts(channelId: Long): List<Post> {
        return postRepository.findPinnedPosts(channelId)
    }

    /**
     * 채널의 유형별 게시글 조회
     */
    fun getPostsByType(
        channelId: Long,
        type: PostType,
        pageable: Pageable,
    ): Page<Post> {
        return postRepository.findByChannelIdAndType(channelId, type, pageable)
    }

    /**
     * 작성자의 게시글 조회
     */
    fun getPostsByAuthor(
        authorId: Long,
        pageable: Pageable,
    ): Page<Post> {
        return postRepository.findByAuthorIdWithChannel(authorId, pageable)
    }

    /**
     * 채널 내 검색
     */
    fun searchInChannel(
        channelId: Long,
        keyword: String,
        pageable: Pageable,
    ): Page<Post> {
        return postRepository.searchInChannel(channelId, keyword, pageable)
    }

    // ========== 생성/수정/삭제 ==========

    /**
     * 게시글 생성
     */
    @Transactional
    fun createPost(post: Post): Post {
        return postRepository.save(post)
    }

    /**
     * 게시글 수정
     */
    @Transactional
    fun updatePost(
        postId: Long,
        updateFn: (Post) -> Unit,
    ): Post {
        val post = getById(postId)
        updateFn(post)
        return postRepository.save(post)
    }

    /**
     * 게시글 삭제
     */
    @Transactional
    fun deletePost(postId: Long) {
        val post = getById(postId)

        // 댓글 먼저 삭제
        commentRepository.deleteAllByPostId(postId)

        postRepository.delete(post)
    }

    // ========== 조회수/고정 ==========

    /**
     * 조회수 증가
     */
    @Transactional
    fun incrementViewCount(postId: Long) {
        postRepository.incrementViewCount(postId)
    }

    /**
     * 게시글 고정/해제
     */
    @Transactional
    fun togglePin(postId: Long): Post {
        val post = getById(postId)
        post.isPinned = !post.isPinned
        return postRepository.save(post)
    }

    // ========== 통계 ==========

    fun getPostCount(channelId: Long): Long {
        return postRepository.countByChannelId(channelId)
    }
}
