package com.univgroup.domain.user.dto

import com.univgroup.domain.user.entity.GlobalRole
import com.univgroup.domain.user.entity.User
import java.time.LocalDateTime

/**
 * 사용자 응답 DTO
 */
data class UserDto(
    val id: Long,
    val email: String,
    val name: String,
    val nickname: String?,
    val profileImageUrl: String?,
    val bio: String?,
    val college: String?,
    val department: String?,
    val studentNo: String?,
    val academicYear: Int?,
    val globalRole: GlobalRole,
    val profileCompleted: Boolean,
    val createdAt: LocalDateTime,
) {
    companion object {
        fun from(user: User): UserDto {
            return UserDto(
                id = user.id,
                email = user.email,
                name = user.name,
                nickname = user.nickname,
                profileImageUrl = user.profileImageUrl,
                bio = user.bio,
                college = user.college,
                department = user.department,
                studentNo = user.studentNo,
                academicYear = user.academicYear,
                globalRole = user.globalRole,
                profileCompleted = user.profileCompleted,
                createdAt = user.createdAt,
            )
        }
    }
}

/**
 * 사용자 요약 DTO (공개 정보)
 */
data class UserSummaryDto(
    val id: Long,
    val name: String,
    val nickname: String?,
    val profileImageUrl: String?,
) {
    companion object {
        fun from(user: User): UserSummaryDto {
            return UserSummaryDto(
                id = user.id,
                name = user.name,
                nickname = user.nickname,
                profileImageUrl = user.profileImageUrl,
            )
        }
    }
}

/**
 * 프로필 수정 요청 DTO
 */
data class UpdateProfileRequest(
    val name: String? = null,
    val nickname: String? = null,
    val bio: String? = null,
    val profileImageUrl: String? = null,
    val college: String? = null,
    val department: String? = null,
    val studentNo: String? = null,
    val academicYear: Int? = null,
)

/**
 * 닉네임 중복 확인 응답 DTO
 */
data class NicknameCheckResponse(
    val nickname: String,
    val available: Boolean,
)
