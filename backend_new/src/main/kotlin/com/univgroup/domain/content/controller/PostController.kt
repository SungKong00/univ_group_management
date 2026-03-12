package com.univgroup.domain.content.controller

import com.univgroup.domain.content.dto.*
import com.univgroup.domain.content.entity.Post
import com.univgroup.domain.content.service.PostService
import com.univgroup.domain.permission.ChannelPermission
import com.univgroup.domain.permission.GroupPermission
import com.univgroup.domain.permission.evaluator.PermissionEvaluator
import com.univgroup.domain.user.service.IUserService
import com.univgroup.domain.workspace.repository.ChannelRepository
import com.univgroup.shared.controller.BaseController
import com.univgroup.shared.dto.ApiResponse
import com.univgroup.shared.dto.ErrorCode
import com.univgroup.shared.exception.ResourceNotFoundException
import org.springframework.data.domain.PageRequest
import org.springframework.security.core.Authentication
import org.springframework.web.bind.annotation.*

/**
 * 게시글 컨트롤러
 *
 * 역함수 패턴 적용: 채널 권한 먼저 확인 → Service 호출
 */
@RestController
@RequestMapping("/api/channels/{channelId}/posts")
class PostController(
    userService: IUserService,
    private val postService: PostService,
    private val channelRepository: ChannelRepository,
    private val permissionEvaluator: PermissionEvaluator,
) : BaseController(userService) {
    // ========== 게시글 조회 ==========

    /**
     * 채널의 게시글 목록 조회
     */
    @GetMapping
    fun getPosts(
        @PathVariable channelId: Long,
        @RequestParam(defaultValue = "0") page: Int,
        @RequestParam(defaultValue = "20") size: Int,
        authentication: Authentication,
    ): ApiResponse<List<PostSummaryDto>> {
        val userId = getCurrentUserId(authentication)

        // 읽기 권한 확인
        permissionEvaluator.requireChannelPermission(userId, channelId, ChannelPermission.POST_READ)

        val pageable = PageRequest.of(page, size)
        val posts = postService.getPostsByChannel(channelId, pageable)

        return ApiResponse.success(posts.content.map { PostSummaryDto.from(it) })
    }

    /**
     * 게시글 상세 조회
     */
    @GetMapping("/{postId}")
    fun getPost(
        @PathVariable channelId: Long,
        @PathVariable postId: Long,
        authentication: Authentication,
    ): ApiResponse<PostDto> {
        val userId = getCurrentUserId(authentication)

        // 읽기 권한 확인
        permissionEvaluator.requireChannelPermission(userId, channelId, ChannelPermission.POST_READ)

        val post = postService.getById(postId)

        // 채널 일치 확인
        if (post.channel.id != channelId) {
            throw ResourceNotFoundException(ErrorCode.CONTENT_POST_NOT_FOUND, "게시글을 찾을 수 없습니다")
        }

        // 조회수 증가
        postService.incrementViewCount(postId)

        return ApiResponse.success(PostDto.from(post))
    }

    /**
     * 채널 내 검색
     */
    @GetMapping("/search")
    fun searchPosts(
        @PathVariable channelId: Long,
        @RequestParam keyword: String,
        @RequestParam(defaultValue = "0") page: Int,
        @RequestParam(defaultValue = "20") size: Int,
        authentication: Authentication,
    ): ApiResponse<List<PostSummaryDto>> {
        val userId = getCurrentUserId(authentication)

        // 읽기 권한 확인
        permissionEvaluator.requireChannelPermission(userId, channelId, ChannelPermission.POST_READ)

        val pageable = PageRequest.of(page, size)
        val posts = postService.searchInChannel(channelId, keyword, pageable)

        return ApiResponse.success(posts.content.map { PostSummaryDto.from(it) })
    }

    // ========== 게시글 생성/수정/삭제 ==========

    /**
     * 게시글 생성
     */
    @PostMapping
    fun createPost(
        @PathVariable channelId: Long,
        @RequestBody request: CreatePostRequest,
        authentication: Authentication,
    ): ApiResponse<PostDto> {
        val user = getCurrentUser(authentication)

        // 쓰기 권한 확인
        permissionEvaluator.requireChannelPermission(user.id!!, channelId, ChannelPermission.POST_WRITE)

        val channel =
            channelRepository.findById(channelId).orElseThrow {
                ResourceNotFoundException(ErrorCode.CONTENT_CHANNEL_NOT_FOUND, "채널을 찾을 수 없습니다")
            }

        val post =
            Post(
                channel = channel,
                author = user,
                content = request.content,
                type = request.type,
            )

        val created = postService.createPost(post)

        return ApiResponse.success(PostDto.from(created))
    }

    /**
     * 게시글 수정
     */
    @PatchMapping("/{postId}")
    fun updatePost(
        @PathVariable channelId: Long,
        @PathVariable postId: Long,
        @RequestBody request: UpdatePostRequest,
        authentication: Authentication,
    ): ApiResponse<PostDto> {
        val userId = getCurrentUserId(authentication)

        val post = postService.getById(postId)

        // 채널 일치 확인
        if (post.channel.id != channelId) {
            throw ResourceNotFoundException(ErrorCode.CONTENT_POST_NOT_FOUND, "게시글을 찾을 수 없습니다")
        }

        // 작성자 확인 (본인만 수정 가능)
        // 관리자(POST_MANAGE 권한 보유자)도 타인 게시글 수정은 불가, 삭제만 가능
        if (post.author.id != userId) {
            throw com.univgroup.shared.exception.AccessDeniedException(
                ErrorCode.CONTENT_NOT_AUTHOR,
                "본인이 작성한 게시글만 수정할 수 있습니다",
            )
        }

        val updated =
            postService.updatePost(postId) { p ->
                request.content?.let { p.content = it }
                request.type?.let { p.type = it }
            }

        return ApiResponse.success(PostDto.from(updated))
    }

    /**
     * 게시글 삭제
     */
    @DeleteMapping("/{postId}")
    fun deletePost(
        @PathVariable channelId: Long,
        @PathVariable postId: Long,
        authentication: Authentication,
    ): ApiResponse<Unit> {
        val userId = getCurrentUserId(authentication)

        val post = postService.getById(postId)

        // 채널 일치 확인
        if (post.channel.id != channelId) {
            throw ResourceNotFoundException(ErrorCode.CONTENT_POST_NOT_FOUND, "게시글을 찾을 수 없습니다")
        }

        // 작성자 또는 그룹 관리 권한 확인
        if (post.author.id != userId) {
            val groupId = post.channel.group.id!!
            permissionEvaluator.requireGroupPermission(userId, groupId, GroupPermission.POST_MANAGE)
        }

        postService.deletePost(postId)

        return ApiResponse.success(Unit)
    }

    /**
     * 게시글 고정/해제 (관리자 전용)
     */
    @PatchMapping("/{postId}/pin")
    fun togglePin(
        @PathVariable channelId: Long,
        @PathVariable postId: Long,
        authentication: Authentication,
    ): ApiResponse<PostDto> {
        val userId = getCurrentUserId(authentication)

        val post = postService.getById(postId)

        // 그룹 관리 권한 확인 (게시글 고정은 그룹 관리 권한 필요)
        val groupId = post.channel.group.id!!
        permissionEvaluator.requireGroupPermission(userId, groupId, GroupPermission.POST_MANAGE)

        // 채널 일치 확인
        if (post.channel.id != channelId) {
            throw ResourceNotFoundException(ErrorCode.CONTENT_POST_NOT_FOUND, "게시글을 찾을 수 없습니다")
        }

        val updated = postService.togglePin(postId)

        return ApiResponse.success(PostDto.from(updated))
    }
}
