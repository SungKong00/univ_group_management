package com.univgroup.domain.content.controller

import com.univgroup.domain.content.dto.*
import com.univgroup.domain.content.entity.Comment
import com.univgroup.domain.content.service.CommentService
import com.univgroup.domain.content.service.PostService
import com.univgroup.domain.permission.ChannelPermission
import com.univgroup.domain.permission.GroupPermission
import com.univgroup.domain.permission.evaluator.PermissionEvaluator
import com.univgroup.domain.user.service.IUserService
import com.univgroup.shared.controller.BaseController
import com.univgroup.shared.dto.ApiResponse
import com.univgroup.shared.dto.ErrorCode
import com.univgroup.shared.exception.ResourceNotFoundException
import org.springframework.data.domain.PageRequest
import org.springframework.security.core.Authentication
import org.springframework.web.bind.annotation.*

/**
 * 댓글 컨트롤러
 *
 * 역함수 패턴 적용: 채널 권한 먼저 확인 → Service 호출
 */
@RestController
@RequestMapping("/api/channels/{channelId}/posts/{postId}/comments")
class CommentController(
    userService: IUserService,
    private val commentService: CommentService,
    private val postService: PostService,
    private val permissionEvaluator: PermissionEvaluator,
) : BaseController(userService) {
    // ========== 댓글 조회 ==========

    /**
     * 게시글의 댓글 목록 조회
     */
    @GetMapping
    fun getComments(
        @PathVariable channelId: Long,
        @PathVariable postId: Long,
        @RequestParam(defaultValue = "0") page: Int,
        @RequestParam(defaultValue = "50") size: Int,
        authentication: Authentication,
    ): ApiResponse<List<CommentDto>> {
        val userId = getCurrentUserId(authentication)

        // 읽기 권한 확인
        permissionEvaluator.requireChannelPermission(userId, channelId, ChannelPermission.COMMENT_READ)

        val post = postService.getById(postId)
        if (post.channel.id != channelId) {
            throw ResourceNotFoundException(ErrorCode.CONTENT_POST_NOT_FOUND, "게시글을 찾을 수 없습니다")
        }

        val pageable = PageRequest.of(page, size)
        val comments = commentService.getRootComments(postId, pageable)

        // 대댓글 포함하여 변환
        val result =
            comments.content.map { comment ->
                val replies = commentService.getReplies(comment.id!!)
                CommentDto.from(comment, includeReplies = true, replies = replies)
            }

        return ApiResponse.success(result)
    }

    /**
     * 특정 댓글 조회
     */
    @GetMapping("/{commentId}")
    fun getComment(
        @PathVariable channelId: Long,
        @PathVariable postId: Long,
        @PathVariable commentId: Long,
        authentication: Authentication,
    ): ApiResponse<CommentDto> {
        val userId = getCurrentUserId(authentication)

        // 읽기 권한 확인
        permissionEvaluator.requireChannelPermission(userId, channelId, ChannelPermission.COMMENT_READ)

        val comment = commentService.getById(commentId)

        // 게시글, 채널 일치 확인
        if (comment.post.id != postId || comment.post.channel.id != channelId) {
            throw ResourceNotFoundException(ErrorCode.CONTENT_COMMENT_NOT_FOUND, "댓글을 찾을 수 없습니다")
        }

        val replies = commentService.getReplies(commentId)

        return ApiResponse.success(CommentDto.from(comment, includeReplies = true, replies = replies))
    }

    // ========== 댓글 생성/수정/삭제 ==========

    /**
     * 댓글 생성
     */
    @PostMapping
    fun createComment(
        @PathVariable channelId: Long,
        @PathVariable postId: Long,
        @RequestBody request: CreateCommentRequest,
        authentication: Authentication,
    ): ApiResponse<CommentDto> {
        val user = getCurrentUser(authentication)

        // 쓰기 권한 확인
        permissionEvaluator.requireChannelPermission(user.id!!, channelId, ChannelPermission.COMMENT_WRITE)

        val post = postService.getById(postId)
        if (post.channel.id != channelId) {
            throw ResourceNotFoundException(ErrorCode.CONTENT_POST_NOT_FOUND, "게시글을 찾을 수 없습니다")
        }

        val parentComment = request.parentCommentId?.let { commentService.getById(it) }

        val comment =
            Comment(
                post = post,
                author = user,
                parentComment = parentComment,
                content = request.content,
            )

        val created = commentService.createComment(comment)

        return ApiResponse.success(CommentDto.from(created))
    }

    /**
     * 댓글 수정
     */
    @PatchMapping("/{commentId}")
    fun updateComment(
        @PathVariable channelId: Long,
        @PathVariable postId: Long,
        @PathVariable commentId: Long,
        @RequestBody request: UpdateCommentRequest,
        authentication: Authentication,
    ): ApiResponse<CommentDto> {
        val userId = getCurrentUserId(authentication)

        val comment = commentService.getById(commentId)

        // 게시글, 채널 일치 확인
        if (comment.post.id != postId || comment.post.channel.id != channelId) {
            throw ResourceNotFoundException(ErrorCode.CONTENT_COMMENT_NOT_FOUND, "댓글을 찾을 수 없습니다")
        }

        // 작성자 확인 (본인만 수정 가능)
        if (comment.author.id != userId) {
            val groupId = comment.post.channel.group.id!!
            permissionEvaluator.requireGroupPermission(userId, groupId, GroupPermission.COMMENT_MANAGE)
        }

        val updated = commentService.updateComment(commentId, request.content)

        return ApiResponse.success(CommentDto.from(updated))
    }

    /**
     * 댓글 삭제
     */
    @DeleteMapping("/{commentId}")
    fun deleteComment(
        @PathVariable channelId: Long,
        @PathVariable postId: Long,
        @PathVariable commentId: Long,
        authentication: Authentication,
    ): ApiResponse<Unit> {
        val userId = getCurrentUserId(authentication)

        val comment = commentService.getById(commentId)

        // 게시글, 채널 일치 확인
        if (comment.post.id != postId || comment.post.channel.id != channelId) {
            throw ResourceNotFoundException(ErrorCode.CONTENT_COMMENT_NOT_FOUND, "댓글을 찾을 수 없습니다")
        }

        // 작성자 또는 그룹 관리 권한 확인
        if (comment.author.id != userId) {
            val groupId = comment.post.channel.group.id!!
            permissionEvaluator.requireGroupPermission(userId, groupId, GroupPermission.COMMENT_MANAGE)
        }

        commentService.deleteComment(commentId)

        return ApiResponse.success(Unit)
    }
}
