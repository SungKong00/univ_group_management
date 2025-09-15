package org.castlekong.backend.controller

import jakarta.validation.Valid
import org.castlekong.backend.dto.*
import org.castlekong.backend.service.ContentService
import org.castlekong.backend.service.UserService
import org.springframework.http.HttpStatus
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.security.core.Authentication
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api")
class ContentController(
    private val contentService: ContentService,
    private val userService: UserService,
) {
    // === Workspaces (compat: group-level single workspace) ===
    @GetMapping("/groups/{groupId}/workspaces")
    @PreAuthorize("isAuthenticated()")
    fun getWorkspaces(@PathVariable groupId: Long): ApiResponse<List<WorkspaceResponse>> {
        val response = contentService.getWorkspacesByGroup(groupId)
        return ApiResponse.success(response)
    }

    @PostMapping("/groups/{groupId}/workspaces")
    @PreAuthorize("isAuthenticated()")
    @ResponseStatus(HttpStatus.CREATED)
    fun createWorkspace(
        @PathVariable groupId: Long,
        @Valid @RequestBody request: CreateWorkspaceRequest,
    ): ApiResponse<WorkspaceResponse> {
        val response = contentService.createWorkspace(groupId, request)
        return ApiResponse.success(response)
    }

    @PutMapping("/workspaces/{workspaceId}")
    @PreAuthorize("isAuthenticated()")
    fun updateWorkspace(
        @PathVariable workspaceId: Long,
        @Valid @RequestBody request: UpdateWorkspaceRequest,
    ): ApiResponse<WorkspaceResponse> {
        val response = contentService.updateWorkspace(workspaceId, request)
        return ApiResponse.success(response)
    }

    @DeleteMapping("/workspaces/{workspaceId}")
    @PreAuthorize("isAuthenticated()")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    fun deleteWorkspace(@PathVariable workspaceId: Long): ApiResponse<Unit> {
        contentService.deleteWorkspace(workspaceId)
        return ApiResponse.success()
    }

    // === Channels ===
    @GetMapping("/workspaces/{workspaceId}/channels")
    @PreAuthorize("isAuthenticated()")
    fun getChannels(@PathVariable workspaceId: Long): ApiResponse<List<ChannelResponse>> {
        val response = contentService.getChannelsByWorkspace(workspaceId)
        return ApiResponse.success(response)
    }

    @PostMapping("/workspaces/{workspaceId}/channels")
    @PreAuthorize("isAuthenticated()")
    @ResponseStatus(HttpStatus.CREATED)
    fun createChannel(
        @PathVariable workspaceId: Long,
        @Valid @RequestBody request: CreateChannelRequest,
        authentication: Authentication,
    ): ApiResponse<ChannelResponse> {
        val user = getUserByEmail(authentication.name)
        val response = contentService.createChannel(workspaceId, request, user.id)
        return ApiResponse.success(response)
    }

    @PutMapping("/channels/{channelId}")
    @PreAuthorize("isAuthenticated()")
    fun updateChannel(
        @PathVariable channelId: Long,
        @Valid @RequestBody request: UpdateChannelRequest,
        authentication: Authentication,
    ): ApiResponse<ChannelResponse> {
        val user = getUserByEmail(authentication.name)
        val response = contentService.updateChannel(channelId, request, user.id)
        return ApiResponse.success(response)
    }

    @DeleteMapping("/channels/{channelId}")
    @PreAuthorize("isAuthenticated()")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    fun deleteChannel(
        @PathVariable channelId: Long,
        authentication: Authentication,
    ): ApiResponse<Unit> {
        val user = getUserByEmail(authentication.name)
        contentService.deleteChannel(channelId, user.id)
        return ApiResponse.success()
    }

    // === Posts ===
    @GetMapping("/channels/{channelId}/posts")
    @PreAuthorize("isAuthenticated()")
    fun getChannelPosts(@PathVariable channelId: Long): ApiResponse<List<PostResponse>> {
        val response = contentService.getPosts(channelId)
        return ApiResponse.success(response)
    }

    @PostMapping("/channels/{channelId}/posts")
    @PreAuthorize("isAuthenticated()")
    @ResponseStatus(HttpStatus.CREATED)
    fun createPost(
        @PathVariable channelId: Long,
        @Valid @RequestBody request: CreatePostRequest,
        authentication: Authentication,
    ): ApiResponse<PostResponse> {
        val user = getUserByEmail(authentication.name)
        val response = contentService.createPost(channelId, request, user.id)
        return ApiResponse.success(response)
    }

    @GetMapping("/posts/{postId}")
    @PreAuthorize("isAuthenticated()")
    fun getPost(@PathVariable postId: Long): ApiResponse<PostResponse> {
        val response = contentService.getPost(postId)
        return ApiResponse.success(response)
    }

    @PutMapping("/posts/{postId}")
    @PreAuthorize("isAuthenticated()")
    fun updatePost(
        @PathVariable postId: Long,
        @Valid @RequestBody request: UpdatePostRequest,
        authentication: Authentication,
    ): ApiResponse<PostResponse> {
        val user = getUserByEmail(authentication.name)
        val response = contentService.updatePost(postId, request, user.id)
        return ApiResponse.success(response)
    }

    @DeleteMapping("/posts/{postId}")
    @PreAuthorize("isAuthenticated()")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    fun deletePost(
        @PathVariable postId: Long,
        authentication: Authentication,
    ): ApiResponse<Unit> {
        val user = getUserByEmail(authentication.name)
        contentService.deletePost(postId, user.id)
        return ApiResponse.success()
    }

    // === Comments ===
    @GetMapping("/posts/{postId}/comments")
    @PreAuthorize("isAuthenticated()")
    fun getComments(@PathVariable postId: Long): ApiResponse<List<CommentResponse>> {
        val response = contentService.getComments(postId)
        return ApiResponse.success(response)
    }

    @PostMapping("/posts/{postId}/comments")
    @PreAuthorize("isAuthenticated()")
    @ResponseStatus(HttpStatus.CREATED)
    fun createComment(
        @PathVariable postId: Long,
        @Valid @RequestBody request: CreateCommentRequest,
        authentication: Authentication,
    ): ApiResponse<CommentResponse> {
        val user = getUserByEmail(authentication.name)
        val response = contentService.createComment(postId, request, user.id)
        return ApiResponse.success(response)
    }

    @PutMapping("/comments/{commentId}")
    @PreAuthorize("isAuthenticated()")
    fun updateComment(
        @PathVariable commentId: Long,
        @Valid @RequestBody request: UpdateCommentRequest,
        authentication: Authentication,
    ): ApiResponse<CommentResponse> {
        val user = getUserByEmail(authentication.name)
        val response = contentService.updateComment(commentId, request, user.id)
        return ApiResponse.success(response)
    }

    @DeleteMapping("/comments/{commentId}")
    @PreAuthorize("isAuthenticated()")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    fun deleteComment(
        @PathVariable commentId: Long,
        authentication: Authentication,
    ): ApiResponse<Unit> {
        val user = getUserByEmail(authentication.name)
        contentService.deleteComment(commentId, user.id)
        return ApiResponse.success()
    }

    private fun getUserByEmail(email: String) = userService.findByEmail(email)
        ?: throw org.castlekong.backend.exception.BusinessException(org.castlekong.backend.exception.ErrorCode.USER_NOT_FOUND)
}
