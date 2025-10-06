package org.castlekong.backend.service

import org.castlekong.backend.dto.GroupJoinRequestResponse
import org.castlekong.backend.dto.GroupSummaryResponse
import org.castlekong.backend.dto.ProfileUpdateRequest
import org.castlekong.backend.dto.SignupProfileRequest
import org.castlekong.backend.dto.SubGroupRequestResponse
import org.castlekong.backend.dto.UserResponse
import org.castlekong.backend.dto.UserSummaryResponse
import org.castlekong.backend.entity.GlobalRole
import org.castlekong.backend.entity.Group
import org.castlekong.backend.entity.GroupJoinRequestStatus
import org.castlekong.backend.entity.GroupType
import org.castlekong.backend.entity.ProfessorStatus
import org.castlekong.backend.entity.SubGroupRequestStatus
import org.castlekong.backend.entity.User
import org.castlekong.backend.repository.GroupJoinRequestRepository
import org.castlekong.backend.repository.GroupMemberRepository
import org.castlekong.backend.repository.GroupRepository
import org.castlekong.backend.repository.SubGroupRequestRepository
import org.castlekong.backend.repository.UserRepository
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
@Transactional(readOnly = true)
class UserService(
    private val userRepository: UserRepository,
    private val groupRepository: GroupRepository,
    private val groupMemberService: GroupMemberService,
    private val groupJoinRequestRepository: GroupJoinRequestRepository,
    private val subGroupRequestRepository: SubGroupRequestRepository,
    private val groupMemberRepository: GroupMemberRepository,
) {
    private val logger = LoggerFactory.getLogger(javaClass)

    fun findByEmail(email: String): User? {
        return userRepository.findByEmail(email).orElse(null)
    }

    fun findAll(): List<User> {
        return userRepository.findAll()
    }

    @Transactional
    fun save(user: User): User {
        return userRepository.save(user)
    }

    @Transactional
    fun ensureUserByEmail(email: String): User {
        findByEmail(email)?.let { return it }
        val name = email.substringBefore("@", email)
        val user =
            User(
                name = name.ifBlank { email },
                email = email,
                password = "",
                globalRole = GlobalRole.STUDENT,
                profileCompleted = false,
            )
        return userRepository.save(user)
    }

    @Transactional
    fun findOrCreateUser(googleUserInfo: GoogleUserInfo): User {
        // 기존 사용자 조회
        val existingUser = findByEmail(googleUserInfo.email)

        return if (existingUser != null) {
            // 기존 사용자 반환
            logger.debug(
                "Found existing user - email: {}, profileCompleted: {}",
                existingUser.email,
                existingUser.profileCompleted,
            )
            existingUser
        } else {
            // 새 사용자 생성
            val user =
                User(
                    name = googleUserInfo.name,
                    email = googleUserInfo.email,
                    // Google OAuth2 사용자는 비밀번호 불필요
                    password = "",
                    globalRole = GlobalRole.STUDENT,
                    // 명시적으로 false 설정
                    profileCompleted = false,
                )
            val savedUser = userRepository.save(user)
            logger.debug(
                "Created new user - email: {}, profileCompleted: {}",
                savedUser.email,
                savedUser.profileCompleted,
            )
            savedUser
        }
    }

    @Transactional
    fun completeProfile(
        userId: Long,
        request: ProfileUpdateRequest,
    ): User {
        val user =
            userRepository.findById(userId)
                .orElseThrow { IllegalArgumentException("사용자를 찾을 수 없습니다: $userId") }

        val updatedUser =
            user.copy(
                globalRole = GlobalRole.valueOf(request.globalRole),
                nickname = request.nickname,
                profileImageUrl = request.profileImageUrl,
                bio = request.bio,
                profileCompleted = true,
            )

        return userRepository.save(updatedUser)
    }

    @Transactional
    fun submitSignupProfile(
        userId: Long,
        req: SignupProfileRequest,
    ): User {
        val user =
            userRepository.findById(userId)
                .orElseThrow { IllegalArgumentException("사용자를 찾을 수 없습니다: $userId") }

        // MVP: 이메일 OTP는 후순위이므로 강제하지 않음

        // 닉네임 중복 검사
        if (req.nickname.isBlank()) {
            throw IllegalArgumentException("VALIDATION_ERROR: 닉네임은 필수입니다")
        }
        val dup = userRepository.existsByNicknameIgnoreCase(req.nickname)
        if (dup && !req.nickname.equals(user.nickname, ignoreCase = true)) {
            throw IllegalArgumentException("E_DUP_NICK: 이미 사용 중인 닉네임입니다")
        }

        val desiredRole =
            try {
                GlobalRole.valueOf(req.role)
            } catch (e: Exception) {
                GlobalRole.STUDENT
            }

        // 교수 지원은 PENDING 상태로 표시하고 실제 role은 STUDENT 유지
        val (finalRole, professorStatus) =
            if (desiredRole == GlobalRole.PROFESSOR) {
                GlobalRole.STUDENT to ProfessorStatus.PENDING
            } else {
                desiredRole to null
            }

        // 계열 또는 학과 정보 업데이트
        val updated =
            user.copy(
                name = req.name,
                nickname = req.nickname,
                college = req.college,
                department = req.dept,
                studentNo = req.studentNo,
                schoolEmail = req.schoolEmail,
                globalRole = finalRole,
                professorStatus = professorStatus,
                profileCompleted = true,
            )

        val saved = userRepository.save(updated)

        // [수정] 사용자가 선택한 학과 또는 계열에 자동 가입
        try {
            val university = "한신대학교" // 이 부분은 향후 확장 가능
            var targetGroup: Group? = null

            // 1. 학과를 선택했다면 학과 그룹을 우선으로 찾음
            if (!req.college.isNullOrBlank() && !req.dept.isNullOrBlank()) {
                targetGroup =
                    groupRepository
                        .findByUniversityAndCollegeAndDepartment(university, req.college, req.dept)
                        .firstOrNull()
            }

            // 2. 학과 그룹을 못찾았거나, 학과를 선택하지 않았다면 계열 그룹을 찾음
            if (targetGroup == null && !req.college.isNullOrBlank()) {
                targetGroup =
                    groupRepository
                        .findByUniversityAndCollegeAndDepartment(university, req.college, null)
                        .firstOrNull { it.groupType == GroupType.COLLEGE }
            }

            if (targetGroup != null) {
                runCatching { groupMemberService.joinGroup(targetGroup.id, saved.id) }
                    .onFailure { e ->
                        logger.warn(
                            "Auto-join failed for user {} to group {}: {}",
                            saved.id,
                            targetGroup.id,
                            e.message,
                        )
                    }
            }
        } catch (e: Exception) {
            // 개발 중 자동 가입 실패는 에러를 발생시키지 않음
            logger.warn("Auto-join process failed with an exception: {}", e.message)
        }

        return saved
    }

    fun convertToUserResponse(user: User): UserResponse {
        return UserResponse(
            id = user.id,
            name = user.name,
            email = user.email,
            globalRole = user.globalRole.name,
            isActive = user.isActive,
            nickname = user.nickname,
            profileImageUrl = user.profileImageUrl,
            bio = user.bio,
            profileCompleted = user.profileCompleted,
            emailVerified = user.emailVerified,
            professorStatus = user.professorStatus?.name,
            department = user.department,
            studentNo = user.studentNo,
            schoolEmail = user.schoolEmail,
            createdAt = user.createdAt,
            updatedAt = user.updatedAt,
        )
    }

    fun convertToUserSummary(user: User): UserSummaryResponse {
        return UserSummaryResponse(
            id = user.id,
            name = user.name,
            email = user.email,
            profileImageUrl = user.profileImageUrl,
        )
    }

    fun searchUsers(
        query: String,
        role: String?,
    ): List<User> {
        val roleEnum =
            try {
                role?.let { GlobalRole.valueOf(it) }
            } catch (e: Exception) {
                null
            }
        return userRepository.searchUsers(query, roleEnum)
    }

    fun nicknameExists(nickname: String): Boolean {
        return userRepository.existsByNicknameIgnoreCase(nickname)
    }

    fun getMyJoinRequests(
        userId: Long,
        status: String,
    ): List<GroupJoinRequestResponse> {
        val st =
            try {
                GroupJoinRequestStatus.valueOf(status)
            } catch (e: Exception) {
                null
            }
        val requests =
            if (st != null) {
                groupJoinRequestRepository.findByUserIdAndStatus(userId, st)
            } else {
                groupJoinRequestRepository.findByUserIdAndStatus(
                    userId,
                    GroupJoinRequestStatus.PENDING,
                )
            }
        return requests.map { r ->
            val memberCount = groupMemberRepository.countByGroupId(r.group.id).toInt()
            val grp = r.group
            GroupJoinRequestResponse(
                id = r.id,
                group =
                    GroupSummaryResponse(
                        id = grp.id,
                        name = grp.name,
                        description = grp.description,
                        profileImageUrl = grp.profileImageUrl,
                        university = grp.university,
                        college = grp.college,
                        department = grp.department,
                        visibility = grp.visibility,
                        groupType = grp.groupType,
                        isRecruiting = grp.isRecruiting,
                        memberCount = memberCount,
                        tags = grp.tags,
                    ),
                user =
                    UserSummaryResponse(
                        id = r.user.id,
                        name = r.user.name,
                        email = r.user.email,
                        profileImageUrl = r.user.profileImageUrl,
                    ),
                requestMessage = r.requestMessage,
                status = r.status.name,
                responseMessage = r.responseMessage,
                reviewedBy =
                    r.reviewedBy?.let { rb ->
                        UserSummaryResponse(
                            id = rb.id,
                            name = rb.name,
                            email = rb.email,
                            profileImageUrl = rb.profileImageUrl,
                        )
                    },
                reviewedAt = r.reviewedAt,
                createdAt = r.createdAt,
                updatedAt = r.updatedAt,
            )
        }
    }

    fun getMySubGroupRequests(
        userId: Long,
        status: String,
    ): List<SubGroupRequestResponse> {
        val st =
            try {
                SubGroupRequestStatus.valueOf(status)
            } catch (e: Exception) {
                null
            }
        val requests =
            if (st != null) {
                subGroupRequestRepository.findByRequesterIdAndStatus(userId, st)
            } else {
                subGroupRequestRepository.findByRequesterIdAndStatus(
                    userId,
                    SubGroupRequestStatus.PENDING,
                )
            }
        return requests.map { r ->
            val memberCount = groupMemberRepository.countByGroupId(r.parentGroup.id).toInt()
            val pg = r.parentGroup
            SubGroupRequestResponse(
                id = r.id,
                requester =
                    UserSummaryResponse(
                        id = r.requester.id,
                        name = r.requester.name,
                        email = r.requester.email,
                        profileImageUrl = r.requester.profileImageUrl,
                    ),
                parentGroup =
                    GroupSummaryResponse(
                        id = pg.id,
                        name = pg.name,
                        description = pg.description,
                        profileImageUrl = pg.profileImageUrl,
                        university = pg.university,
                        college = pg.college,
                        department = pg.department,
                        visibility = pg.visibility,
                        groupType = pg.groupType,
                        isRecruiting = pg.isRecruiting,
                        memberCount = memberCount,
                        tags = pg.tags,
                    ),
                requestedGroupName = r.requestedGroupName,
                requestedGroupDescription = r.requestedGroupDescription,
                requestedUniversity = r.requestedUniversity,
                requestedCollege = r.requestedCollege,
                requestedDepartment = r.requestedDepartment,
                requestedGroupType = r.requestedGroupType,
                requestedMaxMembers = r.requestedMaxMembers,
                status = r.status.name,
                responseMessage = r.responseMessage,
                reviewedBy =
                    r.reviewedBy?.let { rb ->
                        UserSummaryResponse(
                            id = rb.id,
                            name = rb.name,
                            email = rb.email,
                            profileImageUrl = rb.profileImageUrl,
                        )
                    },
                reviewedAt = r.reviewedAt,
                createdAt = r.createdAt,
                updatedAt = r.updatedAt,
            )
        }
    }

    @Transactional
    fun applyRole(
        userId: Long,
        role: String,
    ) {
        val user =
            userRepository.findById(userId)
                .orElseThrow { IllegalArgumentException("사용자를 찾을 수 없습니다: $userId") }
        val desiredRole =
            try {
                GlobalRole.valueOf(role)
            } catch (e: Exception) {
                GlobalRole.STUDENT
            }
        val updated =
            if (desiredRole == GlobalRole.PROFESSOR) {
                user.copy(professorStatus = ProfessorStatus.PENDING)
            } else {
                user.copy(globalRole = desiredRole, professorStatus = null)
            }
        userRepository.save(updated)
    }
}
