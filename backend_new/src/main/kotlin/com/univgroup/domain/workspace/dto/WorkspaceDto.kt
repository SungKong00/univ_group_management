package com.univgroup.domain.workspace.dto

import com.univgroup.domain.workspace.entity.Workspace
import java.time.LocalDateTime

/**
 * 워크스페이스 응답 DTO
 */
data class WorkspaceDto(
    val id: Long,
    val groupId: Long,
    val name: String,
    val description: String?,
    val displayOrder: Int,
    val channelCount: Int?,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime,
) {
    companion object {
        fun from(
            workspace: Workspace,
            channelCount: Int? = null,
        ): WorkspaceDto {
            return WorkspaceDto(
                id = workspace.id!!,
                groupId = workspace.group.id!!,
                name = workspace.name,
                description = workspace.description,
                displayOrder = workspace.displayOrder,
                channelCount = channelCount,
                createdAt = workspace.createdAt,
                updatedAt = workspace.updatedAt,
            )
        }
    }
}

/**
 * 워크스페이스 생성 요청 DTO
 */
data class CreateWorkspaceRequest(
    val name: String,
    val description: String? = null,
)

/**
 * 워크스페이스 수정 요청 DTO
 */
data class UpdateWorkspaceRequest(
    val name: String? = null,
    val description: String? = null,
)
