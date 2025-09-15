package org.castlekong.backend.dto

import jakarta.validation.constraints.*
import org.castlekong.backend.entity.GroupType
import org.castlekong.backend.entity.GroupVisibility
import java.time.LocalDateTime

// 온보딩 시 계열/학과 선택용 DTO
data class GroupHierarchyNodeDto(
    val id: Long,
    val parentId: Long?,
    val name: String,
    val type: GroupType,
)

data class CreateGroupRequest(
    @field:NotBlank(message = "그룹 이름은 필수입니다")
    @field:Size(min = 1, max = 100, message = "그룹 이름은 1자 이상 100자 이하여야 합니다")
    val name: String,
    
    @field:Size(max = 500, message = "그룹 설명은 500자를 초과할 수 없습니다")
    val description: String? = null,
    
    @field:Size(max = 500, message = "프로필 이미지 URL은 500자를 초과할 수 없습니다")
    val profileImageUrl: String? = null,
    
    // 하위 그룹 생성을 위한 부모 그룹 ID
    val parentId: Long? = null,
    
    // 대학/학과 정보
    val university: String? = null,
    val college: String? = null,
    val department: String? = null,
    
    val visibility: GroupVisibility = GroupVisibility.PUBLIC,
    val groupType: GroupType = GroupType.AUTONOMOUS,
    val isRecruiting: Boolean = false,
    
    @field:Min(value = 1, message = "최대 멤버 수는 1 이상이어야 합니다")
    val maxMembers: Int? = null,
    
    val tags: Set<String> = emptySet()
)

data class UpdateGroupRequest(
    val name: String? = null,
    val description: String? = null,
    val profileImageUrl: String? = null,
    val visibility: GroupVisibility? = null,
    val groupType: GroupType? = null,
    val isRecruiting: Boolean? = null,
    val maxMembers: Int? = null,
    val tags: Set<String>? = null
)

data class GroupResponse(
    val id: Long,
    val name: String,
    val description: String? = null,
    val profileImageUrl: String? = null,
    val owner: UserSummaryResponse,
    val university: String? = null,
    val college: String? = null,
    val department: String? = null,
    val visibility: GroupVisibility,
    val groupType: GroupType,
    val isRecruiting: Boolean,
    val maxMembers: Int? = null,
    val tags: Set<String>,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime
)

data class GroupSummaryResponse(
    val id: Long,
    val name: String,
    val description: String? = null,
    val profileImageUrl: String? = null,
    val university: String? = null,
    val college: String? = null,
    val department: String? = null,
    val visibility: GroupVisibility,
    val groupType: GroupType,
    val isRecruiting: Boolean,
    val memberCount: Int,
    val tags: Set<String>
)

data class JoinGroupRequest(
    val message: String? = null
)

data class GroupMemberResponse(
    val id: Long,
    val user: UserSummaryResponse,
    val role: GroupRoleResponse,
    val joinedAt: LocalDateTime
)

data class GroupRoleResponse(
    val id: Long,
    val name: String,
    val permissions: Set<String>,
    val priority: Int
)

data class CreateGroupRoleRequest(
    @field:NotBlank(message = "역할 이름은 필수입니다")
    @field:Size(min = 1, max = 50, message = "역할 이름은 1자 이상 50자 이하여야 합니다")
    val name: String,
    
    @field:NotEmpty(message = "권한은 최소 하나 이상 선택해야 합니다")
    val permissions: Set<String>,
    
    val priority: Int = 0
)

data class UpdateGroupRoleRequest(
    val name: String? = null,
    val permissions: Set<String>? = null,
    val priority: Int? = null
)

data class UserSummaryResponse(
    val id: Long,
    val name: String,
    val email: String,
    val profileImageUrl: String? = null
)

// 하위 그룹 생성 신청 DTO
data class CreateSubGroupRequest(
    @field:NotBlank(message = "그룹 이름은 필수입니다")
    @field:Size(min = 1, max = 100, message = "그룹 이름은 1자 이상 100자 이하여야 합니다")
    val requestedGroupName: String,
    
    @field:Size(max = 500, message = "그룹 설명은 500자를 초과할 수 없습니다")
    val requestedGroupDescription: String? = null,
    
    val requestedUniversity: String? = null,
    val requestedCollege: String? = null,
    val requestedDepartment: String? = null,
    val requestedGroupType: GroupType = GroupType.AUTONOMOUS,
    
    @field:Min(value = 1, message = "최대 멤버 수는 1 이상이어야 합니다")
    val requestedMaxMembers: Int? = null
)

data class SubGroupRequestResponse(
    val id: Long,
    val requester: UserSummaryResponse,
    val parentGroup: GroupSummaryResponse,
    val requestedGroupName: String,
    val requestedGroupDescription: String? = null,
    val requestedUniversity: String? = null,
    val requestedCollege: String? = null,
    val requestedDepartment: String? = null,
    val requestedGroupType: GroupType,
    val requestedMaxMembers: Int? = null,
    val status: String,
    val responseMessage: String? = null,
    val reviewedBy: UserSummaryResponse? = null,
    val reviewedAt: LocalDateTime? = null,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime
)

data class ReviewSubGroupRequestRequest(
    @field:NotBlank(message = "액션은 필수입니다")
    val action: String, // "APPROVE" 또는 "REJECT"
    
    @field:Size(max = 500, message = "응답 메시지는 500자를 초과할 수 없습니다")
    val responseMessage: String? = null
)

// 그룹 가입 신청 DTO
data class GroupJoinRequestResponse(
    val id: Long,
    val group: GroupSummaryResponse,
    val user: UserSummaryResponse,
    val requestMessage: String? = null,
    val status: String,
    val responseMessage: String? = null,
    val reviewedBy: UserSummaryResponse? = null,
    val reviewedAt: LocalDateTime? = null,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime
)

data class ReviewGroupJoinRequestRequest(
    @field:NotBlank(message = "액션은 필수입니다")
    val action: String, // "APPROVE" 또는 "REJECT"
    
    @field:Size(max = 500, message = "응답 메시지는 500자를 초과할 수 없습니다")
    val responseMessage: String? = null
)

// 멤버 역할 변경 요청 DTO
data class UpdateMemberRoleRequest(
    @field:NotNull(message = "역할 ID는 필수입니다")
    val roleId: Long,
)

// 멤버 개인 권한 오버라이드 요청/응답
data class MemberPermissionOverrideRequest(
    val allowed: Set<String> = emptySet(),
    val denied: Set<String> = emptySet(),
)

data class MemberPermissionOverrideResponse(
    val allowed: Set<String>,
    val denied: Set<String>,
    val effective: Set<String>,
)
