package com.univgroup.domain.content.service

import com.univgroup.domain.content.entity.Comment
import com.univgroup.domain.content.repository.CommentRepository
import com.univgroup.domain.content.repository.PostRepository
import com.univgroup.shared.dto.ErrorCode
import com.univgroup.shared.exception.ResourceNotFoundException
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

/**
 * 댓글 서비스
 *
 * 댓글 관련 비즈니스 로직을 담당한다.
 */
@Service
@Transactional(readOnly = true)
class CommentService(
    private val commentRepository: CommentRepository,
    private val postRepository: PostRepository,
) {
    // ========== 조회 ==========

    fun findById(commentId: Long): Comment? {
        return commentRepository.findById(commentId).orElse(null)
    }

    fun getById(commentId: Long): Comment {
        return commentRepository.findById(commentId).orElseThrow {
            ResourceNotFoundException(
                ErrorCode.CONTENT_COMMENT_NOT_FOUND,
                "댓글을 찾을 수 없습니다: $commentId",
            )
        }
    }

    /**
     * 게시글의 루트 댓글 조회 (대댓글 제외)
     */
    fun getRootComments(
        postId: Long,
        pageable: Pageable,
    ): Page<Comment> {
        return commentRepository.findRootCommentsByPostId(postId, pageable)
    }

    /**
     * 게시글의 모든 댓글 조회 (대댓글 포함)
     */
    fun getAllComments(postId: Long): List<Comment> {
        return commentRepository.findAllByPostIdWithAuthor(postId)
    }

    /**
     * 대댓글 조회
     */
    fun getReplies(parentId: Long): List<Comment> {
        return commentRepository.findRepliesByParentId(parentId)
    }

    /**
     * 작성자의 댓글 조회
     */
    fun getCommentsByAuthor(
        authorId: Long,
        pageable: Pageable,
    ): Page<Comment> {
        return commentRepository.findByAuthorId(authorId, pageable)
    }

    // ========== 생성/수정/삭제 ==========

    /**
     * 댓글 생성
     */
    @Transactional
    fun createComment(comment: Comment): Comment {
        val saved = commentRepository.save(comment)

        // 게시글의 댓글 수 증가
        val post = postRepository.findById(comment.post.id!!).orElse(null)
        post?.incrementCommentCount()
        post?.let { postRepository.save(it) }

        return saved
    }

    /**
     * 댓글 수정
     */
    @Transactional
    fun updateComment(
        commentId: Long,
        content: String,
    ): Comment {
        val comment = getById(commentId)

        if (comment.isDeleted) {
            throw IllegalStateException("삭제된 댓글은 수정할 수 없습니다")
        }

        comment.content = content
        return commentRepository.save(comment)
    }

    /**
     * 댓글 삭제
     *
     * 대댓글이 있으면 soft delete, 없으면 hard delete
     */
    @Transactional
    fun deleteComment(commentId: Long) {
        val comment = getById(commentId)
        val hasReplies = commentRepository.countByParentCommentId(commentId) > 0

        if (hasReplies) {
            // Soft delete
            comment.softDelete()
            commentRepository.save(comment)
        } else {
            // Hard delete
            commentRepository.delete(comment)

            // 게시글의 댓글 수 감소
            val post = postRepository.findById(comment.post.id!!).orElse(null)
            post?.decrementCommentCount()
            post?.let { postRepository.save(it) }
        }
    }

    // ========== 통계 ==========

    fun getCommentCount(postId: Long): Long {
        return commentRepository.countByPostId(postId)
    }

    fun getCommentCountByPosts(postIds: List<Long>): Map<Long, Long> {
        if (postIds.isEmpty()) return emptyMap()

        return commentRepository.countByPostIds(postIds)
            .associate { (it[0] as Long) to (it[1] as Long) }
    }
}
