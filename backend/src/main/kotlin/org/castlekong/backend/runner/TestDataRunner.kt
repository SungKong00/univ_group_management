package org.castlekong.backend.runner

import org.castlekong.backend.dto.CreateApplicationRequest
import org.castlekong.backend.dto.CreateGroupEventRequest
import org.castlekong.backend.dto.CreateGroupRequest
import org.castlekong.backend.dto.CreateGroupRoleRequest
import org.castlekong.backend.dto.CreatePersonalEventRequest
import org.castlekong.backend.dto.CreatePersonalScheduleRequest
import org.castlekong.backend.dto.CreatePlaceRequest
import org.castlekong.backend.dto.CreateRecruitmentRequest
import org.castlekong.backend.dto.RecurrencePattern
import org.castlekong.backend.dto.RecurrenceType
import org.castlekong.backend.dto.RequestUsageRequest
import org.castlekong.backend.dto.SignupProfileRequest
import org.castlekong.backend.dto.UpdateUsageStatusRequest
import org.castlekong.backend.entity.GroupPermission
import org.castlekong.backend.entity.GroupType
import org.castlekong.backend.entity.UsageStatus
import org.castlekong.backend.entity.User
import org.castlekong.backend.repository.PlaceOperatingHoursRepository
import org.castlekong.backend.repository.PlaceRepository
import org.castlekong.backend.security.PermissionService
import org.castlekong.backend.service.GoogleUserInfo
import org.castlekong.backend.service.GroupEventService
import org.castlekong.backend.service.GroupInitializationService
import org.castlekong.backend.service.GroupMemberService
import org.castlekong.backend.service.GroupRoleService
import org.castlekong.backend.service.GroupService
import org.castlekong.backend.service.PersonalEventService
import org.castlekong.backend.service.PersonalScheduleService
import org.castlekong.backend.service.PlaceOperatingHoursService
import org.castlekong.backend.service.PlaceReservationService
import org.castlekong.backend.service.PlaceService
import org.castlekong.backend.service.PlaceUsageGroupService
import org.castlekong.backend.service.RecruitmentService
import org.castlekong.backend.service.UserService
import org.slf4j.LoggerFactory
import org.springframework.boot.ApplicationArguments
import org.springframework.boot.ApplicationRunner
import org.springframework.core.annotation.Order
import org.springframework.stereotype.Component
import org.springframework.transaction.annotation.Transactional
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime

/**
 * TestDataRunner - 테스트 데이터 자동 생성
 *
 * 실제 Google OAuth 로그인 플로우를 시뮬레이션하여 테스트 사용자를 생성합니다.
 * - Google 로그인 시뮬레이션 (findOrCreateUser)
 * - 회원가입 프로필 제출 (submitSignupProfile)
 * - 서비스 레이어를 통한 모든 데이터 생성 (데이터 정합성 보장)
 *
 * 실행 순서:
 * 1. Google OAuth 시뮬레이션으로 3명의 사용자 생성
 * 2. 회원가입 프로필 제출 (자동 그룹 가입 포함)
 * 3. 커스텀 그룹 생성 및 멤버 추가
 * 4. 커스텀 역할 생성 및 할당
 * 5. 모집 공고 및 지원서 생성
 * 6. 장소 생성 및 사용 권한 관리
 * 7. 장소 운영 시간 생성
 * 8. 페르소나별 시간표 생성
 * 9. 그룹 캘린더 일정 및 장소 예약 생성
 *
 * @Order(2) - GroupInitializationRunner 이후 실행
 * @Profile("!test") - 백엔드 통합 테스트에서는 비활성화 (E2E/dev 환경에서만 실행)
 */
@Component
@org.springframework.context.annotation.Profile("!test")
@Order(2)
class TestDataRunner(
    private val userService: UserService,
    private val groupService: GroupService,
    private val groupInitializationService: GroupInitializationService,
    private val groupMemberService: GroupMemberService,
    private val groupRoleService: GroupRoleService,
    private val recruitmentService: RecruitmentService,
    private val placeService: PlaceService,
    private val placeUsageGroupService: PlaceUsageGroupService,
    private val placeOperatingHoursService: PlaceOperatingHoursService,
    private val personalScheduleService: PersonalScheduleService,
    private val personalEventService: PersonalEventService,
    private val groupEventService: GroupEventService,
    private val placeReservationService: PlaceReservationService,
    private val placeOperatingHoursRepository: PlaceOperatingHoursRepository,
    private val placeRepository: PlaceRepository,
    private val permissionService: PermissionService,
) : ApplicationRunner {
    private val logger = LoggerFactory.getLogger(TestDataRunner::class.java)

    @Transactional
    override fun run(args: ApplicationArguments) {
        // 중복 실행 방지 체크
        if (shouldSkipExecution()) {
            logger.info("=== Test data already exists, skipping TestDataRunner ===")
            return
        }

        // Invalidate permission cache
        permissionService.invalidateGroup(1)
        permissionService.invalidateGroup(2)
        permissionService.invalidateGroup(3)
        permissionService.invalidateGroup(11)
        permissionService.invalidateGroup(12)
        permissionService.invalidateGroup(13)

        logger.info("=== Starting Test Data Creation ===")

        try {
            // Phase 1: 사용자 생성 (Google OAuth 시뮬레이션 + 회원가입 프로필 제출)
            val users = createTestUsers()

            // Phase 2: 커스텀 그룹 생성
            val customGroups = createCustomGroups(users)

            // Phase 3: 그룹 멤버십 및 역할 관리
            setupGroupMemberships(users, customGroups)

            // Phase 4: 모집 공고 및 지원서
            createRecruitments(users, customGroups)

            // Phase 5: 장소 생성 및 사용 권한
            val customPlaces = createPlaces(users, customGroups)

            // Phase 6: 장소 운영 시간 생성
            createPlaceAvailabilities(users, customPlaces)

            // Phase 7: 페르소나별 시간표 생성
            createPersonalSchedules(users)

            // Phase 8: 개인 캘린더 일정 생성
            createPersonalEvents(users)

            // Phase 9: 그룹 캘린더 일정 및 장소 예약 생성
            createCalendarEventsAndReservations(users, customGroups, customPlaces)

            logger.info("=== Test Data Creation Completed Successfully ===")
        } catch (e: Exception) {
            logger.error("=== Test Data Creation Failed ===", e)
            throw e
        }
    }

    /**
     * 중복 실행 방지 체크
     * 특정 테스트 그룹이 이미 존재하면 true 반환
     */
    private fun shouldSkipExecution(): Boolean {
        return groupService.getAllGroups().any { it.name == "코딩 동아리 'DevCrew'" } ||
            groupService.getAllGroups().any { it.name == "AI/SW학과 코딩 스터디" }
    }

    /**
     * Phase 1: 테스트 사용자 생성
     *
     * Google OAuth 로그인 플로우를 시뮬레이션:
     * 1. Google 사용자 정보로 사용자 생성 (findOrCreateUser)
     * 2. 회원가입 프로필 제출 (submitSignupProfile)
     *    - 자동으로 선택한 학과/계열 + 상위 그룹에 가입됨
     *
     * @return 생성된 사용자 목록
     */
    private fun createTestUsers(): TestUsers {
        logger.info("[1/9] Creating test users (Google OAuth simulation + Profile submission)...")

        // User 1: TestUser1 (AI/SW학과)
        val user1 =
            simulateGoogleLoginAndSignup(
                email = "testuser1@hs.ac.kr",
                name = "TestUser1",
                nickname = "TU1",
                college = "AI/SW계열",
                dept = "AI/SW학과",
                studentNo = "20250011",
                academicYear = 1,
                role = "STUDENT",
            )

        // User 2: TestUser2 (AI/SW계열 - 학과 선택 안함)
        val user2 =
            simulateGoogleLoginAndSignup(
                email = "testuser2@hs.ac.kr",
                name = "TestUser2",
                nickname = "TU2",
                college = "AI/SW계열",
                dept = null,
                studentNo = "20250012",
                academicYear = 2,
                role = "STUDENT",
            )

        // User 3: TestUser3 (AI시스템반도체학과)
        val user3 =
            simulateGoogleLoginAndSignup(
                email = "testuser3@hs.ac.kr",
                name = "TestUser3",
                nickname = "TU3",
                college = "AI/SW계열",
                dept = "AI시스템반도체학과",
                studentNo = "20250013",
                academicYear = 3,
                role = "STUDENT",
            )

        logger.info("-> SUCCESS: Created 3 test users with profile completion")
        logger.info("   - ${user1.email} (${user1.department})")
        logger.info("   - ${user2.email} (${user2.college})")
        logger.info("   - ${user3.email} (${user3.department})")

        return TestUsers(user1, user2, user3)
    }

    /**
     * Google OAuth 로그인 및 회원가입 프로필 제출 시뮬레이션
     *
     * @param email 이메일
     * @param name 이름
     * @param nickname 닉네임
     * @param college 계열 (선택)
     * @param dept 학과 (선택)
     * @param studentNo 학번
     * @param academicYear 학년
     * @return 생성 및 프로필 완료된 사용자
     */
    private fun simulateGoogleLoginAndSignup(
        email: String,
        name: String,
        nickname: String,
        college: String?,
        dept: String?,
        studentNo: String,
        academicYear: Int,
        role: String = "STUDENT",
    ): User {
        // Step 1: Google OAuth 시뮬레이션 - findOrCreateUser 호출
        val googleUserInfo =
            GoogleUserInfo(
                email = email,
                name = name,
                profileImageUrl = null,
            )

        val createdUser = userService.findOrCreateUser(googleUserInfo)
        logger.debug("   -> Google OAuth simulated for: $email (userId=${createdUser.id})")

        // Step 2: 회원가입 프로필 제출 - submitSignupProfile 호출
        val profileRequest =
            SignupProfileRequest(
                name = name,
                nickname = nickname,
                college = college,
                dept = dept,
                studentNo = studentNo,
                academicYear = academicYear,
                schoolEmail = email,
                role = role,
            )

        val completedUser = userService.submitSignupProfile(createdUser.id!!, profileRequest)
        logger.debug("   -> Profile submitted for: $email (auto-joined to groups)")

        return completedUser
    }

    /**
     * Phase 2: 커스텀 그룹 생성
     *
     * @param users 테스트 사용자들
     * @return 생성된 커스텀 그룹 정보
     */
    private fun createCustomGroups(users: TestUsers): CustomGroups {
        logger.info("[2/9] Creating custom groups...")

        // 코딩 동아리 (user1이 그룹장)
        val devCrewGroup =
            safeExecute("Creating DevCrew group") {
                groupInitializationService.createGroupWithDefaults(
                    CreateGroupRequest(
                        name = "코딩 동아리 'DevCrew'",
                        parentId = 1,
                        university = "한신대학교",
                        college = null,
                        department = null,
                        groupType = GroupType.AUTONOMOUS,
                        description = "코딩과 개발을 사랑하는 사람들의 모임",
                        tags = setOf("코딩", "개발", "스터디"),
                    ),
                    users.user1.id!!,
                )
            }

        // 학생회 (user2가 그룹장)
        val studentCouncilGroup =
            safeExecute("Creating Student Council group") {
                groupInitializationService.createGroupWithDefaults(
                    CreateGroupRequest(
                        name = "학생회",
                        parentId = 1,
                        university = "한신대학교",
                        college = null,
                        department = null,
                        groupType = GroupType.OFFICIAL,
                        description = "한신대학교 총학생회",
                        tags = setOf("학생회", "공식"),
                    ),
                    users.user2.id!!,
                )
            }

        // AI/SW학과 코딩 스터디 (user1이 그룹장, AI/SW학과 하위 그룹)
        // TestDataRunner에서는 직접 그룹을 생성하여 승인된 상태를 시뮬레이션
        val aiSwCodingStudyGroup =
            safeExecute("Creating AI/SW Dept Coding Study group (simulating approved state)") {
                groupInitializationService.createGroupWithDefaults(
                    CreateGroupRequest(
                        name = "AI/SW학과 코딩 스터디",
                        // AI/SW학과 그룹 ID (수정: 2 → 13)
                        parentId = 13,
                        university = "한신대학교",
                        college = "AI/SW계열",
                        department = "AI/SW학과",
                        groupType = GroupType.AUTONOMOUS,
                        description = "AI/SW학과 학생들을 위한 코딩 스터디",
                        tags = setOf("코딩", "스터디", "AI/SW학과"),
                    ),
                    users.user1.id!!,
                )
            }

        logger.info("-> SUCCESS: Created custom groups")
        logger.info("   - ${devCrewGroup.name} (owner: ${users.user1.email})")
        logger.info("   - ${studentCouncilGroup.name} (owner: ${users.user2.email})")
        logger.info("   - ${aiSwCodingStudyGroup.name} (owner: ${users.user1.email}, parent: AI/SW학과)")

        return CustomGroups(devCrewGroup.id, studentCouncilGroup.id, aiSwCodingStudyGroup.id)
    }

    /**
     * Phase 3: 그룹 멤버십 및 역할 관리
     *
     * @param users 테스트 사용자들
     * @param groups 커스텀 그룹들
     */
    private fun setupGroupMemberships(
        users: TestUsers,
        groups: CustomGroups,
    ) {
        logger.info("[3/9] Setting up group memberships and roles...")

        // user3를 학생회에 추가
        safeExecute("Adding user3 to Student Council") {
            groupMemberService.joinGroup(groups.studentCouncilId, users.user3.id!!)
        }

        // 학생회에 커스텀 역할 생성 (학생회 간부)
        val executiveRole =
            safeExecute("Creating custom role '학생회 간부'") {
                groupRoleService.createGroupRole(
                    groups.studentCouncilId,
                    CreateGroupRoleRequest(
                        name = "학생회 간부",
                        permissions =
                            setOf(
                                GroupPermission.CHANNEL_MANAGE.name,
                                GroupPermission.RECRUITMENT_MANAGE.name,
                                GroupPermission.CALENDAR_MANAGE.name,
                            ),
                        priority = 50,
                    ),
                    users.user2.id!!,
                )
            }

        // user3에게 커스텀 역할 할당
        safeExecute("Assigning '학생회 간부' role to user3") {
            groupMemberService.updateMemberRole(
                groups.studentCouncilId,
                users.user3.id!!,
                executiveRole.id,
                users.user2.id!!,
            )
        }

        logger.info("-> SUCCESS: Configured memberships and roles")
    }

    /**
     * Phase 4: 모집 공고 및 지원서 생성
     *
     * @param users 테스트 사용자들
     * @param groups 커스텀 그룹들
     */
    private fun createRecruitments(
        users: TestUsers,
        groups: CustomGroups,
    ) {
        logger.info("[4/9] Creating recruitments and applications...")

        // 학생회 모집 공고 생성 (user2가 작성)
        val recruitment =
            safeExecute("Creating recruitment post") {
                recruitmentService.createRecruitment(
                    groups.studentCouncilId,
                    CreateRecruitmentRequest(
                        title = "학생회 2025년 2학기 신입 부원 모집",
                        content = "열정 넘치는 신입 부원을 모집합니다!",
                        recruitmentEndDate = LocalDateTime.now().plusWeeks(2),
                        applicationQuestions = listOf("자기소개를 해주세요.", "학생회에서 하고 싶은 일은 무엇인가요?"),
                    ),
                    users.user2.id!!,
                )
            }

        // user1이 지원서 제출
        safeExecute("User1 submitting application") {
            recruitmentService.submitApplication(
                recruitment.id,
                CreateApplicationRequest(
                    motivation = "학생 사회에 기여하고 싶습니다.",
                    questionAnswers =
                        mapOf(
                            0 to "안녕하세요, TestUser1입니다. 코딩을 좋아하고 학생회 활동에 관심이 많습니다.",
                            1 to "IT 인프라 개선 및 학생들을 위한 웹 서비스 개발을 하고 싶습니다.",
                        ),
                ),
                users.user1.id!!,
            )
        }

        logger.info("-> SUCCESS: Created recruitment and application")
    }

    /**
     * Phase 5: 장소 생성 및 사용 권한 관리
     *
     * @param users 테스트 사용자들
     * @param groups 커스텀 그룹들
     */
    private fun createPlaces(
        users: TestUsers,
        groups: CustomGroups,
    ): CustomPlaces {
        logger.info("[5/9] Creating places and managing usage permissions...")

        // 학생회실 장소 생성 (user2가 관리)
        val labPlace =
            safeExecute("Creating place '학생회실'") {
                placeService.createPlace(
                    users.user2,
                    CreatePlaceRequest(
                        managingGroupId = groups.studentCouncilId,
                        building = "학생회관",
                        roomNumber = "201호",
                        alias = "학생회실",
                        capacity = 25,
                    ),
                )
            }

        // 세미나실 장소 생성 (user2가 관리)
        val seminarRoom =
            safeExecute("Creating place '세미나실'") {
                placeService.createPlace(
                    users.user2,
                    CreatePlaceRequest(
                        managingGroupId = groups.studentCouncilId,
                        building = "60주년 기념관",
                        roomNumber = "101호",
                        alias = "세미나실",
                        capacity = 50,
                    ),
                )
            }

        // ===== 장소 사용 권한 관리 =====
        // 각 그룹이 장소 사용을 요청하고, 관리 그룹(학생회)이 승인하는 프로세스

        // 1. 한신대학교 (최상위 그룹) - 학생회실 사용 권한
        safeExecute("Hansin University requesting lab place usage") {
            val owner = userService.findByEmail("castlekong1019@gmail.com")
            placeUsageGroupService.requestUsage(
                owner!!,
                labPlace.id,
                RequestUsageRequest(
                    // 한신대학교 그룹 ID
                    groupId = 1,
                    reason = "대학 전체 행사 및 회의를 위해 사용하고 싶습니다.",
                ),
            )
        }

        safeExecute("Student Council approving Hansin University lab place usage") {
            placeUsageGroupService.updateUsageStatus(
                users.user2,
                labPlace.id,
                // 한신대학교 그룹 ID
                1,
                UpdateUsageStatusRequest(status = UsageStatus.APPROVED),
            )
        }

        // 2. 한신대학교 (최상위 그룹) - 세미나실 사용 권한
        safeExecute("Hansin University requesting seminar room usage") {
            val owner = userService.findByEmail("castlekong1019@gmail.com")
            placeUsageGroupService.requestUsage(
                owner!!,
                seminarRoom.id,
                RequestUsageRequest(
                    // 한신대학교 그룹 ID
                    groupId = 1,
                    reason = "대학 전체 행사 및 대규모 세미나를 위해 사용하고 싶습니다.",
                ),
            )
        }

        safeExecute("Student Council approving Hansin University seminar room usage") {
            placeUsageGroupService.updateUsageStatus(
                users.user2,
                seminarRoom.id,
                // 한신대학교 그룹 ID
                1,
                UpdateUsageStatusRequest(status = UsageStatus.APPROVED),
            )
        }

        // 3. DevCrew 그룹 - 학생회실 사용 권한
        safeExecute("DevCrew requesting place usage") {
            placeUsageGroupService.requestUsage(
                users.user1,
                labPlace.id,
                RequestUsageRequest(
                    groupId = groups.devCrewId,
                    reason = "매주 목요일 저녁 코딩 스터디를 위해 사용하고 싶습니다.",
                ),
            )
        }

        safeExecute("Student Council approving DevCrew place usage") {
            placeUsageGroupService.updateUsageStatus(
                users.user2,
                labPlace.id,
                groups.devCrewId,
                UpdateUsageStatusRequest(status = UsageStatus.APPROVED),
            )
        }

        // 4. AI/SW계열 - 세미나실 사용 권한
        safeExecute("AI/SW college requesting seminar room usage") {
            val owner = userService.findByEmail("castlekong1019@gmail.com")
            placeUsageGroupService.requestUsage(
                owner!!,
                seminarRoom.id,
                RequestUsageRequest(
                    // AI/SW계열 그룹 ID
                    groupId = 2,
                    reason = "계열 단위 행사를 위해 사용하고 싶습니다.",
                ),
            )
        }

        safeExecute("Student Council approving AI/SW college usage") {
            placeUsageGroupService.updateUsageStatus(
                users.user2,
                seminarRoom.id,
                // AI/SW계열 그룹 ID
                2,
                UpdateUsageStatusRequest(status = UsageStatus.APPROVED),
            )
        }

        // 5. AI시스템반도체학과 - 세미나실 사용 권한
        safeExecute("AI/Semiconductor department requesting seminar room usage") {
            val owner = userService.findByEmail("castlekong1019@gmail.com")
            placeUsageGroupService.requestUsage(
                owner!!,
                seminarRoom.id,
                RequestUsageRequest(
                    // AI시스템반도체학과 그룹 ID
                    groupId = 11,
                    reason = "전공 스터디 및 프로젝트를 위해 사용하고 싶습니다.",
                ),
            )
        }

        safeExecute("Student Council approving AI/Semiconductor department usage") {
            placeUsageGroupService.updateUsageStatus(
                users.user2,
                seminarRoom.id,
                // AI시스템반도체학과 그룹 ID
                11,
                UpdateUsageStatusRequest(status = UsageStatus.APPROVED),
            )
        }

        // 6. AI/SW학과 - 세미나실 사용 권한
        safeExecute("AI/SW department requesting seminar room usage") {
            val owner = userService.findByEmail("castlekong1019@gmail.com")
            placeUsageGroupService.requestUsage(
                owner!!,
                seminarRoom.id,
                RequestUsageRequest(
                    // AI/SW학과 그룹 ID
                    groupId = 13,
                    reason = "학과 특강 및 세미나를 위해 사용하고 싶습니다.",
                ),
            )
        }

        safeExecute("Student Council approving AI/SW department usage") {
            placeUsageGroupService.updateUsageStatus(
                users.user2,
                seminarRoom.id,
                // AI/SW학과 그룹 ID
                13,
                UpdateUsageStatusRequest(status = UsageStatus.APPROVED),
            )
        }

        // 7. AI/SW학과 코딩 스터디 그룹 - 세미나실 사용 권한
        safeExecute("AI/SW Dept Coding Study group requesting seminar room usage") {
            placeUsageGroupService.requestUsage(
                // TestUser1 is the owner of AI/SW학과 코딩 스터디
                users.user1,
                seminarRoom.id,
                RequestUsageRequest(
                    groupId = groups.aiSwCodingStudyId,
                    reason = "AI/SW학과 코딩 스터디 정기 모임을 위해 사용하고 싶습니다.",
                ),
            )
        }

        safeExecute("Student Council approving AI/SW Dept Coding Study group usage") {
            placeUsageGroupService.updateUsageStatus(
                // TestUser2 is the owner of Student Council (managing group)
                users.user2,
                seminarRoom.id,
                groups.aiSwCodingStudyId,
                UpdateUsageStatusRequest(status = UsageStatus.APPROVED),
            )
        }

        logger.info("-> SUCCESS: Created place and managed usage permissions")
        return CustomPlaces(labPlace.id, seminarRoom.id)
    }

    /**
     * Phase 6: 장소 운영 시간 생성
     *
     * @param users 테스트 사용자들
     * @param places 커스텀 장소들
     */
    private fun createPlaceAvailabilities(
        users: TestUsers,
        places: CustomPlaces,
    ) {
        logger.info("[6/9] Creating place operating hours...")

        val labPlace = placeRepository.findById(places.labPlaceId).orElseThrow()
        val seminarRoom = placeRepository.findById(places.seminarRoomId).orElseThrow()

        // PlaceOperatingHours 데이터 추가 (PlaceTimeManagementService를 통해)
        // setOperatingHours를 사용하여 기본값을 8:00-21:00으로 설정
        // (주말 일관성 유지: 모든 요일 포함하여 토/일은 isClosed=true로 설정)
        safeExecute("Creating operating hours for '학생회실'") {
            // Monday-Friday: 08:00-21:00, Saturday-Sunday: Closed
            val allDays = DayOfWeek.entries.toList()
            val operatingHoursData =
                allDays.associate { day ->
                    day to
                        org.castlekong.backend.service.PlaceOperatingHoursService.OperatingHoursData(
                            startTime = LocalTime.of(8, 0),
                            endTime = LocalTime.of(21, 0),
                            isClosed = day in listOf(DayOfWeek.SATURDAY, DayOfWeek.SUNDAY),
                        )
                }
            placeOperatingHoursService.setOperatingHours(labPlace, operatingHoursData)
        }

        safeExecute("Creating operating hours for '세미나실'") {
            // Monday-Friday: 08:00-21:00, Saturday-Sunday: Closed
            val allDays = DayOfWeek.entries.toList()
            val operatingHoursData =
                allDays.associate { day ->
                    day to
                        org.castlekong.backend.service.PlaceOperatingHoursService.OperatingHoursData(
                            startTime = LocalTime.of(8, 0),
                            endTime = LocalTime.of(21, 0),
                            isClosed = day in listOf(DayOfWeek.SATURDAY, DayOfWeek.SUNDAY),
                        )
                }
            placeOperatingHoursService.setOperatingHours(seminarRoom, operatingHoursData)
        }

        logger.info("-> SUCCESS: Created place operating hours data")
    }

    /**
     * Phase 7: 페르소나별 시간표 생성
     *
     * 각 사용자의 특징과 페르소나에 맞는 시간표를 생성합니다.
     * - TestUser1: 프로그래밍, 자료구조, 알고리즘 등 CS 전공 과목
     * - TestUser2: 교양/선택 과목 + 학생회 활동 시간
     * - TestUser3: 반도체 전공 과목 + 학생회 활동 시간
     *
     * @param users 테스트 사용자들
     */
    private fun createPersonalSchedules(users: TestUsers) {
        logger.info("[7/9] Creating personal schedules based on user personas...")

        // TestUser1: CS 전공 과목 (프로그래밍 중심)
        safeExecute("Creating schedules for TestUser1 (CS courses)") {
            // 월요일 09:00-10:30 프로그래밍
            personalScheduleService.createSchedule(
                users.user1,
                CreatePersonalScheduleRequest(
                    title = "프로그래밍 1",
                    dayOfWeek = DayOfWeek.MONDAY,
                    startTime = LocalTime.of(9, 0),
                    endTime = LocalTime.of(10, 30),
                    location = "학습관 201호",
                    color = "#2196F3",
                ),
            )

            // 수요일 10:30-12:00 자료구조
            personalScheduleService.createSchedule(
                users.user1,
                CreatePersonalScheduleRequest(
                    title = "자료구조",
                    dayOfWeek = DayOfWeek.WEDNESDAY,
                    startTime = LocalTime.of(10, 30),
                    endTime = LocalTime.of(12, 0),
                    location = "학습관 301호",
                    color = "#4CAF50",
                ),
            )

            // 금요일 14:00-15:30 알고리즘
            personalScheduleService.createSchedule(
                users.user1,
                CreatePersonalScheduleRequest(
                    title = "알고리즘",
                    dayOfWeek = DayOfWeek.FRIDAY,
                    startTime = LocalTime.of(14, 0),
                    endTime = LocalTime.of(15, 30),
                    location = "학습관 201호",
                    color = "#FF9800",
                ),
            )

            // 목요일 18:00-20:00 DevCrew 코딩 스터디
            personalScheduleService.createSchedule(
                users.user1,
                CreatePersonalScheduleRequest(
                    title = "DevCrew 코딩 스터디",
                    dayOfWeek = DayOfWeek.THURSDAY,
                    startTime = LocalTime.of(18, 0),
                    endTime = LocalTime.of(20, 0),
                    location = "학생회실",
                    color = "#9C27B0",
                ),
            )
        }

        // TestUser2: 교양과목 + 학생회 활동
        safeExecute("Creating schedules for TestUser2 (Liberal arts + Student council)") {
            // 화요일 09:00-10:30 교양 과학
            personalScheduleService.createSchedule(
                users.user2,
                CreatePersonalScheduleRequest(
                    title = "과학과 문명",
                    dayOfWeek = DayOfWeek.TUESDAY,
                    startTime = LocalTime.of(9, 0),
                    endTime = LocalTime.of(10, 30),
                    location = "강의동 101호",
                    color = "#2196F3",
                ),
            )

            // 목요일 10:30-12:00 교양 인문학
            personalScheduleService.createSchedule(
                users.user2,
                CreatePersonalScheduleRequest(
                    title = "역사와 철학",
                    dayOfWeek = DayOfWeek.THURSDAY,
                    startTime = LocalTime.of(10, 30),
                    endTime = LocalTime.of(12, 0),
                    location = "강의동 205호",
                    color = "#4CAF50",
                ),
            )

            // 수요일 14:00-17:00 학생회 정기회의
            personalScheduleService.createSchedule(
                users.user2,
                CreatePersonalScheduleRequest(
                    title = "학생회 정기회의",
                    dayOfWeek = DayOfWeek.WEDNESDAY,
                    startTime = LocalTime.of(14, 0),
                    endTime = LocalTime.of(17, 0),
                    location = "학생회실",
                    color = "#F44336",
                ),
            )

            // 금요일 13:00-14:00 학생회 사무시간
            personalScheduleService.createSchedule(
                users.user2,
                CreatePersonalScheduleRequest(
                    title = "학생회 사무시간",
                    dayOfWeek = DayOfWeek.FRIDAY,
                    startTime = LocalTime.of(13, 0),
                    endTime = LocalTime.of(14, 0),
                    location = "학생회실",
                    color = "#FF5722",
                ),
            )
        }

        // TestUser3: 반도체 전공 + 학생회 활동
        safeExecute("Creating schedules for TestUser3 (Semiconductor + Student council)") {
            // 월요일 11:00-12:30 반도체 공학
            personalScheduleService.createSchedule(
                users.user3,
                CreatePersonalScheduleRequest(
                    title = "반도체 공학 개론",
                    dayOfWeek = DayOfWeek.MONDAY,
                    startTime = LocalTime.of(11, 0),
                    endTime = LocalTime.of(12, 30),
                    location = "공과관 501호",
                    color = "#2196F3",
                ),
            )

            // 수요일 09:00-10:30 전자회로
            personalScheduleService.createSchedule(
                users.user3,
                CreatePersonalScheduleRequest(
                    title = "전자회로 설계",
                    dayOfWeek = DayOfWeek.WEDNESDAY,
                    startTime = LocalTime.of(9, 0),
                    endTime = LocalTime.of(10, 30),
                    location = "공과관 502호",
                    color = "#4CAF50",
                ),
            )

            // 금요일 14:00-15:30 반도체 실험
            personalScheduleService.createSchedule(
                users.user3,
                CreatePersonalScheduleRequest(
                    title = "반도체 실험",
                    dayOfWeek = DayOfWeek.FRIDAY,
                    startTime = LocalTime.of(14, 0),
                    endTime = LocalTime.of(15, 30),
                    location = "공과관 Lab",
                    color = "#FF9800",
                ),
            )

            // 화요일 16:00-18:00 학생회 간부 회의
            personalScheduleService.createSchedule(
                users.user3,
                CreatePersonalScheduleRequest(
                    title = "학생회 간부 회의",
                    dayOfWeek = DayOfWeek.TUESDAY,
                    startTime = LocalTime.of(16, 0),
                    endTime = LocalTime.of(18, 0),
                    location = "학생회실",
                    color = "#F44336",
                ),
            )

            // 목요일 12:00-13:00 학생회 업무 (사무시간)
            personalScheduleService.createSchedule(
                users.user3,
                CreatePersonalScheduleRequest(
                    title = "학생회 업무 시간",
                    dayOfWeek = DayOfWeek.THURSDAY,
                    startTime = LocalTime.of(12, 0),
                    endTime = LocalTime.of(13, 0),
                    location = "학생회실",
                    color = "#FF5722",
                ),
            )
        }

        logger.info("-> SUCCESS: Created personal schedules")
        logger.info("   - TestUser1: 4 CS courses (프로그래밍, 자료구조, 알고리즘, 스터디)")
        logger.info("   - TestUser2: 4 schedules (교양과목 + 학생회)")
        logger.info("   - TestUser3: 5 schedules (반도체전공 + 학생회)")
    }

    private fun createPersonalEvents(users: TestUsers) {
        logger.info("[8/9] Creating personal events for November...")

        // TestUser1
        safeExecute("Creating personal events for TestUser1") {
            personalEventService.createEvent(
                users.user1,
                CreatePersonalEventRequest(
                    title = "알고리즘 문제 풀이 (백준)",
                    startDateTime = LocalDateTime.of(2025, 11, 3, 21, 0),
                    endDateTime = LocalDateTime.of(2025, 11, 3, 23, 0),
                    location = "기숙사",
                    color = "#536DFE",
                ),
            )
            personalEventService.createEvent(
                users.user1,
                CreatePersonalEventRequest(
                    title = "헬스",
                    startDateTime = LocalDateTime.of(2025, 11, 4, 7, 0),
                    endDateTime = LocalDateTime.of(2025, 11, 4, 8, 30),
                    location = "학교 헬스장",
                    color = "#009688",
                ),
            )
            personalEventService.createEvent(
                users.user1,
                CreatePersonalEventRequest(
                    title = "영어 스터디 (토익)",
                    startDateTime = LocalDateTime.of(2025, 11, 4, 19, 0),
                    endDateTime = LocalDateTime.of(2025, 11, 4, 21, 0),
                    location = "중앙도서관 스터디룸",
                    color = "#7C4DFF",
                ),
            )
            personalEventService.createEvent(
                users.user1,
                CreatePersonalEventRequest(
                    title = "운영체제 예습",
                    startDateTime = LocalDateTime.of(2025, 11, 5, 19, 0),
                    endDateTime = LocalDateTime.of(2025, 11, 5, 21, 0),
                    location = "중앙도서관",
                    color = "#4CAF50",
                ),
            )
            personalEventService.createEvent(
                users.user1,
                CreatePersonalEventRequest(
                    title = "헬스",
                    startDateTime = LocalDateTime.of(2025, 11, 6, 7, 0),
                    endDateTime = LocalDateTime.of(2025, 11, 6, 8, 30),
                    location = "학교 헬스장",
                    color = "#009688",
                ),
            )
            personalEventService.createEvent(
                users.user1,
                CreatePersonalEventRequest(
                    title = "친구와 저녁 약속",
                    startDateTime = LocalDateTime.of(2025, 11, 6, 20, 0),
                    endDateTime = LocalDateTime.of(2025, 11, 6, 22, 0),
                    location = "학교 앞 식당",
                    color = "#FFC107",
                ),
            )
            personalEventService.createEvent(
                users.user1,
                CreatePersonalEventRequest(
                    title = "본가 방문",
                    startDateTime = LocalDateTime.of(2025, 11, 7, 18, 0),
                    endDateTime = LocalDateTime.of(2025, 11, 7, 23, 0),
                    location = "(이동)",
                    color = "#795548",
                ),
            )
            personalEventService.createEvent(
                users.user1,
                CreatePersonalEventRequest(
                    title = "영화 감상",
                    startDateTime = LocalDateTime.of(2025, 11, 8, 20, 0),
                    endDateTime = LocalDateTime.of(2025, 11, 8, 22, 0),
                    location = "기숙사",
                    color = "#607D8B",
                ),
            )
        }

        // TestUser2
        safeExecute("Creating personal events for TestUser2") {
            personalEventService.createEvent(
                users.user2,
                CreatePersonalEventRequest(
                    title = "카페 아르바이트",
                    startDateTime = LocalDateTime.of(2025, 11, 3, 18, 0),
                    endDateTime = LocalDateTime.of(2025, 11, 3, 22, 0),
                    location = "학교 앞 스타벅스",
                    color = "#8D6E63",
                ),
            )
            personalEventService.createEvent(
                users.user2,
                CreatePersonalEventRequest(
                    title = "댄스 동아리 연습",
                    startDateTime = LocalDateTime.of(2025, 11, 4, 19, 0),
                    endDateTime = LocalDateTime.of(2025, 11, 4, 21, 0),
                    location = "학생회관 연습실",
                    color = "#E91E63",
                ),
            )
            personalEventService.createEvent(
                users.user2,
                CreatePersonalEventRequest(
                    title = "카페 아르바이트",
                    startDateTime = LocalDateTime.of(2025, 11, 5, 18, 0),
                    endDateTime = LocalDateTime.of(2025, 11, 5, 22, 0),
                    location = "학교 앞 스타벅스",
                    color = "#8D6E63",
                ),
            )
            personalEventService.createEvent(
                users.user2,
                CreatePersonalEventRequest(
                    title = "댄스 동아리 연습",
                    startDateTime = LocalDateTime.of(2025, 11, 6, 19, 0),
                    endDateTime = LocalDateTime.of(2025, 11, 6, 21, 0),
                    location = "학생회관 연습실",
                    color = "#E91E63",
                ),
            )
            personalEventService.createEvent(
                users.user2,
                CreatePersonalEventRequest(
                    title = "쇼핑",
                    startDateTime = LocalDateTime.of(2025, 11, 7, 18, 0),
                    endDateTime = LocalDateTime.of(2025, 11, 7, 20, 0),
                    location = "시내",
                    color = "#FFEB3B",
                ),
            )
            personalEventService.createEvent(
                users.user2,
                CreatePersonalEventRequest(
                    title = "친구 생일 파티",
                    startDateTime = LocalDateTime.of(2025, 11, 8, 19, 0),
                    endDateTime = LocalDateTime.of(2025, 11, 8, 23, 0),
                    location = "친구 집",
                    color = "#FFC107",
                ),
            )
            personalEventService.createEvent(
                users.user2,
                CreatePersonalEventRequest(
                    title = "과제 (역사와 철학)",
                    startDateTime = LocalDateTime.of(2025, 11, 9, 14, 0),
                    endDateTime = LocalDateTime.of(2025, 11, 9, 17, 0),
                    location = "중앙도서관",
                    color = "#4CAF50",
                ),
            )
            personalEventService.createEvent(
                users.user2,
                CreatePersonalEventRequest(
                    title = "영화 보기 (마블)",
                    startDateTime = LocalDateTime.of(2025, 11, 9, 19, 0),
                    endDateTime = LocalDateTime.of(2025, 11, 9, 22, 0),
                    location = "자취방",
                    color = "#607D8B",
                ),
            )
        }

        // TestUser3
        safeExecute("Creating personal events for TestUser3") {
            personalEventService.createEvent(
                users.user3,
                CreatePersonalEventRequest(
                    title = "랩실 연구",
                    startDateTime = LocalDateTime.of(2025, 11, 3, 19, 0),
                    endDateTime = LocalDateTime.of(2025, 11, 3, 22, 0),
                    location = "공과관 Lab",
                    color = "#3F51B5",
                ),
            )
            personalEventService.createEvent(
                users.user3,
                CreatePersonalEventRequest(
                    title = "취업 스터디 (코딩 테스트)",
                    startDateTime = LocalDateTime.of(2025, 11, 4, 19, 0),
                    endDateTime = LocalDateTime.of(2025, 11, 4, 21, 0),
                    location = "중앙도서관 스터디룸",
                    color = "#00BCD4",
                ),
            )
            personalEventService.createEvent(
                users.user3,
                CreatePersonalEventRequest(
                    title = "랩실 연구",
                    startDateTime = LocalDateTime.of(2025, 11, 5, 19, 0),
                    endDateTime = LocalDateTime.of(2025, 11, 5, 22, 0),
                    location = "공과관 Lab",
                    color = "#3F51B5",
                ),
            )
            personalEventService.createEvent(
                users.user3,
                CreatePersonalEventRequest(
                    title = "지도교수님 면담",
                    startDateTime = LocalDateTime.of(2025, 11, 6, 16, 0),
                    endDateTime = LocalDateTime.of(2025, 11, 6, 17, 0),
                    location = "교수 연구실",
                    color = "#9C27B0",
                ),
            )
            personalEventService.createEvent(
                users.user3,
                CreatePersonalEventRequest(
                    title = "취업 스터디 (NCS)",
                    startDateTime = LocalDateTime.of(2025, 11, 7, 19, 0),
                    endDateTime = LocalDateTime.of(2025, 11, 7, 21, 0),
                    location = "중앙도서관 스터디룸",
                    color = "#00BCD4",
                ),
            )
            personalEventService.createEvent(
                users.user3,
                CreatePersonalEventRequest(
                    title = "여자친구와 데이트",
                    startDateTime = LocalDateTime.of(2025, 11, 8, 14, 0),
                    endDateTime = LocalDateTime.of(2025, 11, 8, 20, 0),
                    location = "시내",
                    color = "#E91E63",
                ),
            )
            personalEventService.createEvent(
                users.user3,
                CreatePersonalEventRequest(
                    title = "랩실 연구",
                    startDateTime = LocalDateTime.of(2025, 11, 9, 10, 0),
                    endDateTime = LocalDateTime.of(2025, 11, 9, 18, 0),
                    location = "공과관 Lab",
                    color = "#3F51B5",
                ),
            )
            personalEventService.createEvent(
                users.user3,
                CreatePersonalEventRequest(
                    title = "휴식",
                    startDateTime = LocalDateTime.of(2025, 11, 9, 18, 0),
                    endDateTime = LocalDateTime.of(2025, 11, 9, 23, 0),
                    location = "자취방",
                    color = "#607D8B",
                ),
            )
        }

        logger.info("-> SUCCESS: Created personal events for November")
    }

    /**
     * Phase 8: 그룹 캘린더 일정 및 장소 예약 생성
     *
     * @param users 테스트 사용자들
     * @param groups 커스텀 그룹들
     * @param places 커스텀 장소들
     */
    private fun createCalendarEventsAndReservations(
        users: TestUsers,
        groups: CustomGroups,
        places: CustomPlaces,
    ) {
        logger.info("[9/9] Creating group calendar events and reservations...")

        /**
         * 슬롯 기반 날짜 계산을 위한 기준 날짜 (다음 주 월요일)
         */
        fun getBaseDate(): LocalDate {
            return LocalDate.now()
                .with(DayOfWeek.MONDAY)
                .plusWeeks(1)
        }

        val owner = userService.findByEmail("castlekong1019@gmail.com")

        // 시나리오 1: 간단한 그룹 이벤트 (DevCrew)
        safeExecute("Creating simple group event for DevCrew") {
            groupEventService.createEvent(
                users.user1,
                groups.devCrewId,
                CreateGroupEventRequest(
                    title = "주간 알고리즘 스터디",
                    description = "매주 월요일에 진행되는 알고리즘 스터디입니다.",
                    locationText = "온라인",
                    startDate = getBaseDate(),
                    endDate = getBaseDate().plusMonths(1),
                    startTime = LocalTime.of(19, 0),
                    endTime = LocalTime.of(21, 0),
                    isOfficial = false,
                    color = "#03A9F4",
                    recurrence =
                        RecurrencePattern(
                            type = RecurrenceType.WEEKLY,
                            daysOfWeek = listOf(DayOfWeek.MONDAY),
                        ),
                ),
            )
        }

        // 시나리오 2: 장소 예약이 포함된 공식 그룹 이벤트 (총학생회)
        safeExecute("Creating official group event with place reservation for Student Council") {
            groupEventService.createEvent(
                users.user2,
                groups.studentCouncilId,
                CreateGroupEventRequest(
                    title = "총학생회 정기 회의",
                    description = "매주 수요일에 진행되는 총학생회 정기 회의입니다.",
                    placeId = places.labPlaceId,
                    startDate = getBaseDate(),
                    endDate = getBaseDate().plusMonths(1),
                    startTime = LocalTime.of(17, 0),
                    endTime = LocalTime.of(18, 30),
                    isOfficial = true,
                    color = "#E91E63",
                    recurrence =
                        RecurrencePattern(
                            type = RecurrenceType.WEEKLY,
                            daysOfWeek = listOf(DayOfWeek.WEDNESDAY),
                        ),
                ),
            )
        }

        // ========== Slot L6: labPlace - 화 09:00-11:00 ==========
        safeExecute("Creating a direct place reservation for Student Council") {
            val event =
                groupEventService.createEvent(
                    users.user3,
                    groups.studentCouncilId,
                    CreateGroupEventRequest(
                        title = "임시 회의",
                        description = "긴급 회의",
                        placeId = places.labPlaceId,
                        startDate = getBaseDate().plusDays(1),
                        endDate = getBaseDate().plusDays(1),
                        startTime = LocalTime.of(9, 0),
                        endTime = LocalTime.of(11, 0),
                        isOfficial = false,
                        color = "#FFC107",
                    ),
                )
        }

        // 텍스트 이벤트 5 (충돌 없음)
        safeExecute("Creating group event with a non-reservable location text") {
            groupEventService.createEvent(
                users.user1,
                groups.devCrewId,
                CreateGroupEventRequest(
                    title = "팀 프로젝트 회의",
                    description = "학교 근처 카페에서 진행",
                    locationText = "학교 근처 카페",
                    startDate = getBaseDate().plusDays(15),
                    endDate = getBaseDate().plusDays(15),
                    startTime = LocalTime.of(15, 0),
                    endTime = LocalTime.of(17, 0),
                    isOfficial = false,
                    color = "#795548",
                ),
            )
        }

        // ========== Slot 19: 다음주 화 14:00-16:00 ==========
        safeExecute("Creating official event for AI/SW college") {
            groupEventService.createEvent(
                owner!!,
                // AI/SW계열 그룹 ID
                2,
                CreateGroupEventRequest(
                    title = "AI/SW계열 개강 총회",
                    description = "2025년 2학기 개강 총회입니다. 모든 계열 학생들은 참석해주세요.",
                    placeId = places.seminarRoomId,
                    startDate = getBaseDate().plusDays(8),
                    endDate = getBaseDate().plusDays(8),
                    startTime = LocalTime.of(14, 0),
                    endTime = LocalTime.of(16, 0),
                    isOfficial = true,
                    color = "#8BC34A",
                ),
            )
        }

        // ========== Slot 20: 다음주 화 18:00-20:00 ==========
        safeExecute("Creating seminar for AI/SW department") {
            groupEventService.createEvent(
                owner!!,
                // AI/SW학과 그룹 ID
                13,
                CreateGroupEventRequest(
                    title = "자료구조 특강",
                    description = "외부 전문가를 초빙하여 진행하는 자료구조 특강입니다.",
                    placeId = places.seminarRoomId,
                    startDate = getBaseDate().plusDays(8),
                    endDate = getBaseDate().plusDays(8),
                    startTime = LocalTime.of(18, 0),
                    endTime = LocalTime.of(20, 0),
                    isOfficial = true,
                    color = "#00BCD4",
                ),
            )
        }

        // ========== Slot 21: 다음주 수 09:00-11:00 ==========
        safeExecute("Creating direct reservation for AI/Semiconductor department") {
            groupEventService.createEvent(
                owner!!,
                // AI시스템반도체학과 그룹 ID
                11,
                CreateGroupEventRequest(
                    title = "졸업 프로젝트 회의",
                    description = "캡스톤 디자인 팀 프로젝트 회의",
                    placeId = places.seminarRoomId,
                    startDate = getBaseDate().plusDays(9),
                    endDate = getBaseDate().plusDays(9),
                    startTime = LocalTime.of(9, 0),
                    endTime = LocalTime.of(11, 0),
                    isOfficial = false,
                    color = "#FF9800",
                ),
            )
        }

        // DevCrew 그룹 추가 일정
        safeExecute("Creating additional events for DevCrew") {
            groupEventService.createEvent(
                users.user1,
                groups.devCrewId,
                CreateGroupEventRequest(
                    title = "DevCrew 정기 스터디",
                    placeId = places.labPlaceId,
                    startDate = getBaseDate(),
                    endDate = getBaseDate().plusWeeks(4),
                    startTime = LocalTime.of(19, 0),
                    endTime = LocalTime.of(21, 0),
                    isOfficial = false,
                    color = "#03A9F4",
                    recurrence =
                        RecurrencePattern(
                            type = RecurrenceType.WEEKLY,
                            daysOfWeek = listOf(DayOfWeek.MONDAY),
                        ),
                ),
            )
        }

        // 학생회 그룹 추가 일정
        safeExecute("Creating additional events for Student Council") {
            groupEventService.createEvent(
                users.user2,
                groups.studentCouncilId,
                CreateGroupEventRequest(
                    title = "학생회 정기 회의",
                    placeId = places.labPlaceId,
                    startDate = getBaseDate(),
                    endDate = getBaseDate().plusWeeks(4),
                    startTime = LocalTime.of(17, 0),
                    endTime = LocalTime.of(18, 30),
                    isOfficial = true,
                    color = "#E91E63",
                    recurrence =
                        RecurrencePattern(
                            type = RecurrenceType.WEEKLY,
                            daysOfWeek = listOf(DayOfWeek.TUESDAY),
                        ),
                ),
            )
        }

        // AI/SW학과 그룹 추가 일정
        safeExecute("Creating additional events for AI/SW department") {
            val owner = userService.findByEmail("castlekong1019@gmail.com")
            // ========== Slot 0: 월 09:00-11:00 ==========
            groupEventService.createEvent(
                owner!!,
                // AI/SW학과 그룹 ID
                13,
                CreateGroupEventRequest(
                    title = "알고리즘 경진대회 대비 특강",
                    placeId = places.seminarRoomId,
                    startDate = getBaseDate().plusDays(0),
                    endDate = getBaseDate().plusDays(0),
                    startTime = LocalTime.of(9, 0),
                    endTime = LocalTime.of(11, 0),
                    isOfficial = true,
                    color = "#00BCD4",
                ),
            )
            // ========== Slot 1: 월 14:00-16:00 ==========
            groupEventService.createEvent(
                owner!!,
                // AI/SW학과 그룹 ID
                13,
                CreateGroupEventRequest(
                    title = "코딩 테스트 스터디",
                    placeId = places.seminarRoomId,
                    startDate = getBaseDate().plusDays(0),
                    endDate = getBaseDate().plusDays(0),
                    startTime = LocalTime.of(14, 0),
                    endTime = LocalTime.of(16, 0),
                    isOfficial = false,
                    color = "#00BCD4",
                ),
            )
            // ========== Slot 2: 월 18:00-20:00 ==========
            groupEventService.createEvent(
                owner!!,
                // AI/SW학과 그룹 ID
                13,
                CreateGroupEventRequest(
                    title = "졸업생 멘토링",
                    placeId = places.seminarRoomId,
                    startDate = getBaseDate().plusDays(0),
                    endDate = getBaseDate().plusDays(0),
                    startTime = LocalTime.of(18, 0),
                    endTime = LocalTime.of(20, 0),
                    isOfficial = true,
                    color = "#00BCD4",
                ),
            )
        }

        // AI시스템반도체학과 그룹 추가 일정
        safeExecute("Creating additional events for AI/Semiconductor department") {
            val owner = userService.findByEmail("castlekong1019@gmail.com")
            // ========== Slot 3: 화 09:00-11:00 ==========
            groupEventService.createEvent(
                owner!!,
                // AI시스템반도체학과 그룹 ID
                11,
                CreateGroupEventRequest(
                    title = "임베디드 시스템 프로젝트 회의",
                    placeId = places.seminarRoomId,
                    startDate = getBaseDate().plusDays(1),
                    endDate = getBaseDate().plusDays(1),
                    startTime = LocalTime.of(9, 0),
                    endTime = LocalTime.of(11, 0),
                    isOfficial = false,
                    color = "#FF9800",
                ),
            )
            // ========== Slot 4: 화 14:00-16:00 ==========
            groupEventService.createEvent(
                owner!!,
                // AI시스템반도체학과 그룹 ID
                11,
                CreateGroupEventRequest(
                    title = "반도체 설계 공모전 준비",
                    placeId = places.seminarRoomId,
                    startDate = getBaseDate().plusDays(1),
                    endDate = getBaseDate().plusDays(1),
                    startTime = LocalTime.of(14, 0),
                    endTime = LocalTime.of(16, 0),
                    isOfficial = false,
                    color = "#FF9800",
                ),
            )
            // ========== Slot 5: 화 18:00-20:00 ==========
            groupEventService.createEvent(
                owner!!,
                // AI시스템반도체학과 그룹 ID
                11,
                CreateGroupEventRequest(
                    title = "캡스톤 디자인 최종 발표 준비",
                    placeId = places.seminarRoomId,
                    startDate = getBaseDate().plusDays(1),
                    endDate = getBaseDate().plusDays(1),
                    startTime = LocalTime.of(18, 0),
                    endTime = LocalTime.of(20, 0),
                    isOfficial = true,
                    color = "#FF9800",
                ),
            )
        }

        // AI/SW학과 코딩 스터디 그룹 추가 일정
        safeExecute("Creating additional events for AI/SW Dept Coding Study group") {
            // ========== Slot 6: 수 09:00-11:00 ==========
            groupEventService.createEvent(
                users.user1,
                groups.aiSwCodingStudyId,
                CreateGroupEventRequest(
                    title = "AI/SW학과 코딩 스터디 정기 모임",
                    description = "AI/SW학과 코딩 스터디 정기 모임입니다.",
                    placeId = places.seminarRoomId,
                    startDate = getBaseDate().plusDays(2),
                    endDate = getBaseDate().plusDays(2),
                    startTime = LocalTime.of(9, 0),
                    endTime = LocalTime.of(11, 0),
                    isOfficial = false,
                    color = "#FFC107",
                ),
            )
        }
        logger.info("-> SUCCESS: Created group calendar events and reservations")

        logger.info("-> Creating additional November events...")

        // 1. DevCrew (코딩 동아리)
        safeExecute("Creating November events for DevCrew") {
            // ========== Slot L1: labPlace - 월 09:00-11:00 ==========
            groupEventService.createEvent(
                users.user1,
                groups.devCrewId,
                CreateGroupEventRequest(
                    title = "특별 세미나: TDD 시작하기",
                    description = "Test-Driven Development (TDD) 기본 개념과 실습",
                    placeId = places.labPlaceId,
                    startDate = getBaseDate().plusDays(0),
                    endDate = getBaseDate().plusDays(0),
                    startTime = LocalTime.of(9, 0),
                    endTime = LocalTime.of(11, 0),
                    isOfficial = true,
                    color = "#009688",
                ),
            )
            // 온라인 이벤트 1 (충돌 없음)
            groupEventService.createEvent(
                users.user1,
                groups.devCrewId,
                CreateGroupEventRequest(
                    title = "DevCrew 11월 월간 회의",
                    description = "11월 활동 계획 및 피드백",
                    locationText = "온라인 (Discord)",
                    startDate = getBaseDate().plusDays(7),
                    endDate = getBaseDate().plusDays(7),
                    startTime = LocalTime.of(21, 0),
                    endTime = LocalTime.of(22, 0),
                    isOfficial = false,
                    color = "#03A9F4",
                ),
            )
            // ========== Slot L4: labPlace - 목 12:00-14:00 ==========
            groupEventService.createEvent(
                users.user1,
                groups.devCrewId,
                CreateGroupEventRequest(
                    title = "프로젝트 'Univ-Manager' 중간 발표",
                    description = "동아리 내부 프로젝트 진행 상황 공유",
                    placeId = places.labPlaceId,
                    startDate = getBaseDate().plusDays(3),
                    endDate = getBaseDate().plusDays(3),
                    startTime = LocalTime.of(12, 0),
                    endTime = LocalTime.of(14, 0),
                    isOfficial = true,
                    color = "#009688",
                ),
            )
            // ========== Slot L5: labPlace - 금 15:00-17:00 ==========
            groupEventService.createEvent(
                users.user1,
                groups.devCrewId,
                CreateGroupEventRequest(
                    title = "선배 개발자 초청 Q&A",
                    description = "현업 개발자와의 만남",
                    placeId = places.labPlaceId,
                    startDate = getBaseDate().plusDays(4),
                    endDate = getBaseDate().plusDays(4),
                    startTime = LocalTime.of(15, 0),
                    endTime = LocalTime.of(17, 0),
                    isOfficial = true,
                    color = "#009688",
                ),
            )
            // 텍스트 이벤트 1 (충돌 없음)
            groupEventService.createEvent(
                users.user1,
                groups.devCrewId,
                CreateGroupEventRequest(
                    title = "함께하는 코딩 & 피자 나잇",
                    description = "11월 마지막 주 금요일 소셜 이벤트",
                    locationText = "학생회실 (21시 이후 사용 불가)",
                    startDate = getBaseDate().plusDays(10),
                    endDate = getBaseDate().plusDays(10),
                    startTime = LocalTime.of(19, 0),
                    endTime = LocalTime.of(22, 0),
                    isOfficial = false,
                    color = "#FF5722",
                ),
            )
        }

        // 2. 학생회
        safeExecute("Creating November events for Student Council") {
            // ========== Slot 22: 다음주 수 14:00-16:00 ==========
            groupEventService.createEvent(
                users.user2,
                groups.studentCouncilId,
                CreateGroupEventRequest(
                    title = "11월 전체 학생 대표자 회의",
                    description = "각 단과대 및 학과 학생회장 참여",
                    placeId = places.seminarRoomId,
                    startDate = getBaseDate().plusDays(9),
                    endDate = getBaseDate().plusDays(9),
                    startTime = LocalTime.of(14, 0),
                    endTime = LocalTime.of(16, 0),
                    isOfficial = true,
                    color = "#E91E63",
                ),
            )
            // 텍스트 이벤트 2 (충돌 없음)
            groupEventService.createEvent(
                users.user2,
                groups.studentCouncilId,
                CreateGroupEventRequest(
                    title = "학생회 비품 정리 및 대청소",
                    description = "주말 예약 테스트용",
                    locationText = "학생회실 (예약 불가, 텍스트)",
                    startDate = getBaseDate().plusDays(11),
                    endDate = getBaseDate().plusDays(11),
                    startTime = LocalTime.of(14, 0),
                    endTime = LocalTime.of(17, 0),
                    isOfficial = false,
                    color = "#9E9E9E",
                ),
            )
            // Slot L2: labPlace - 다음주 화 14:00-16:00
            groupEventService.createEvent(
                users.user2,
                groups.studentCouncilId,
                CreateGroupEventRequest(
                    title = "2026년도 학생회장 선거 준비위원회 1차 회의",
                    description = "선거 일정 및 규칙 논의",
                    placeId = places.labPlaceId,
                    startDate = getBaseDate().plusDays(8),
                    endDate = getBaseDate().plusDays(8),
                    startTime = LocalTime.of(14, 0),
                    endTime = LocalTime.of(16, 0),
                    isOfficial = true,
                    color = "#E91E63",
                ),
            )
            // ========== Slot 23: 다음주 수 18:00-20:00 ==========
            groupEventService.createEvent(
                users.user2,
                groups.studentCouncilId,
                CreateGroupEventRequest(
                    title = "한신대학교 축제 기획 TF 모집 설명회",
                    description = "2026년 축제 기획팀 모집",
                    placeId = places.seminarRoomId,
                    startDate = getBaseDate().plusDays(9),
                    endDate = getBaseDate().plusDays(9),
                    startTime = LocalTime.of(18, 0),
                    endTime = LocalTime.of(20, 0),
                    isOfficial = true,
                    color = "#E91E63",
                ),
            )
            // ========== Slot L3: labPlace - 수 14:00-16:00 ==========
            groupEventService.createEvent(
                users.user2,
                groups.studentCouncilId,
                CreateGroupEventRequest(
                    title = "학생회실 임시 휴무",
                    description = "내부 사정으로 인한 임시 휴무",
                    placeId = places.labPlaceId,
                    startDate = getBaseDate().plusDays(2),
                    endDate = getBaseDate().plusDays(2),
                    startTime = LocalTime.of(14, 0),
                    endTime = LocalTime.of(16, 0),
                    isOfficial = true,
                    color = "#212121",
                ),
            )
        }

        // 3. AI/SW계열
        safeExecute("Creating November events for AI/SW College") {
            val owner = userService.findByEmail("castlekong1019@gmail.com")!!
            // ========== Slot 7: 수 14:00-16:00 ==========
            groupEventService.createEvent(
                owner,
                // AI/SW계열 그룹 ID
                2,
                CreateGroupEventRequest(
                    title = "AI/SW계열 명사 초청 특강: 'AI의 미래'",
                    description = "외부 전문가 초청 강연",
                    placeId = places.seminarRoomId,
                    startDate = getBaseDate().plusDays(2),
                    endDate = getBaseDate().plusDays(2),
                    startTime = LocalTime.of(14, 0),
                    endTime = LocalTime.of(16, 0),
                    isOfficial = true,
                    color = "#8BC34A",
                ),
            )
            // ========== Slot 8: 수 18:00-20:00 ==========
            groupEventService.createEvent(
                owner,
                // AI/SW계열 그룹 ID
                2,
                CreateGroupEventRequest(
                    title = "2025년 2학기 계열 종강 총회",
                    description = "학기 마무리 및 성과 보고",
                    placeId = places.seminarRoomId,
                    startDate = getBaseDate().plusDays(2),
                    endDate = getBaseDate().plusDays(2),
                    startTime = LocalTime.of(18, 0),
                    endTime = LocalTime.of(20, 0),
                    isOfficial = true,
                    color = "#8BC34A",
                ),
            )
            // ========== Slot 9: 목 09:00-11:00 ==========
            groupEventService.createEvent(
                owner,
                // AI/SW계열 그룹 ID
                2,
                CreateGroupEventRequest(
                    title = "신입생-재학생 멘토링 프로그램",
                    description = "선후배 교류 행사",
                    placeId = places.seminarRoomId,
                    startDate = getBaseDate().plusDays(3),
                    endDate = getBaseDate().plusDays(3),
                    startTime = LocalTime.of(9, 0),
                    endTime = LocalTime.of(11, 0),
                    isOfficial = true,
                    color = "#8BC34A",
                ),
            )
            // ========== Slot 10: 목 14:00-16:00 ==========
            groupEventService.createEvent(
                owner,
                // AI/SW계열 그룹 ID
                2,
                CreateGroupEventRequest(
                    title = "계열 학생회장 선거 후보자 토론회",
                    description = "2026년 계열 학생회장 선거",
                    placeId = places.seminarRoomId,
                    startDate = getBaseDate().plusDays(3),
                    endDate = getBaseDate().plusDays(3),
                    startTime = LocalTime.of(14, 0),
                    endTime = LocalTime.of(16, 0),
                    isOfficial = true,
                    color = "#8BC34A",
                ),
            )
            // 텍스트 이벤트 3 (충돌 없음)
            groupEventService.createEvent(
                owner,
                // AI/SW계열 그룹 ID
                2,
                CreateGroupEventRequest(
                    title = "계열 연합 코딩 대회",
                    description = "주말 예약 테스트용",
                    locationText = "세미나실 (예약 불가, 텍스트)",
                    startDate = getBaseDate().plusDays(12),
                    endDate = getBaseDate().plusDays(12),
                    startTime = LocalTime.of(9, 0),
                    endTime = LocalTime.of(18, 0),
                    isOfficial = true,
                    color = "#9E9E9E",
                ),
            )
        }

        // 4. AI/SW학과
        safeExecute("Creating November events for AI/SW Department") {
            val owner = userService.findByEmail("castlekong1019@gmail.com")!!
            // ========== Slot 11: 목 18:00-20:00 ==========
            groupEventService.createEvent(
                owner,
                // AI/SW학과 그룹 ID
                13,
                CreateGroupEventRequest(
                    title = "알고리즘 스터디 그룹 발표회",
                    description = "학과 내 스터디 그룹 성과 발표",
                    placeId = places.seminarRoomId,
                    startDate = getBaseDate().plusDays(3),
                    endDate = getBaseDate().plusDays(3),
                    startTime = LocalTime.of(18, 0),
                    endTime = LocalTime.of(20, 0),
                    isOfficial = true,
                    color = "#00BCD4",
                ),
            )
            // ========== Slot 12: 금 09:00-11:00 ==========
            groupEventService.createEvent(
                owner,
                // AI/SW학과 그룹 ID
                13,
                CreateGroupEventRequest(
                    title = "캡스톤 디자인 프로젝트 중간 점검",
                    description = "졸업 프로젝트 진행 상황 점검",
                    placeId = places.seminarRoomId,
                    startDate = getBaseDate().plusDays(4),
                    endDate = getBaseDate().plusDays(4),
                    startTime = LocalTime.of(9, 0),
                    endTime = LocalTime.of(11, 0),
                    isOfficial = true,
                    color = "#00BCD4",
                ),
            )
            // ========== Slot 13: 금 14:00-16:00 ==========
            groupEventService.createEvent(
                owner,
                // AI/SW학과 그룹 ID
                13,
                CreateGroupEventRequest(
                    title = "IT 기업 채용 설명회 (네이버)",
                    description = "네이버 개발자 채용 설명회",
                    placeId = places.seminarRoomId,
                    startDate = getBaseDate().plusDays(4),
                    endDate = getBaseDate().plusDays(4),
                    startTime = LocalTime.of(14, 0),
                    endTime = LocalTime.of(16, 0),
                    isOfficial = true,
                    color = "#00BCD4",
                ),
            )
            // 온라인 이벤트 2 (충돌 없음)
            groupEventService.createEvent(
                owner,
                // AI/SW학과 그룹 ID
                13,
                CreateGroupEventRequest(
                    title = "교수님과의 대화 (진로 상담)",
                    description = "온라인 진로 상담 세션",
                    locationText = "온라인 (Zoom)",
                    startDate = getBaseDate().plusDays(13),
                    endDate = getBaseDate().plusDays(13),
                    startTime = LocalTime.of(19, 0),
                    endTime = LocalTime.of(21, 0),
                    isOfficial = false,
                    color = "#00BCD4",
                ),
            )
            // 텍스트 이벤트 4 (충돌 없음)
            groupEventService.createEvent(
                owner,
                // AI/SW학과 그룹 ID
                13,
                CreateGroupEventRequest(
                    title = "AI/SW학과 종강 파티",
                    description = "2025-2학기 종강 파티",
                    locationText = "학교 근처 식당",
                    startDate = getBaseDate().plusDays(14),
                    endDate = getBaseDate().plusDays(14),
                    startTime = LocalTime.of(18, 0),
                    endTime = LocalTime.of(20, 0),
                    isOfficial = false,
                    color = "#795548",
                ),
            )
        }

        // 5. AI시스템반도체학과
        safeExecute("Creating November events for AI/Semiconductor Department") {
            val owner = userService.findByEmail("castlekong1019@gmail.com")!!
            // ========== Slot 14: 금 18:00-20:00 ==========
            groupEventService.createEvent(
                owner,
                // AI시스템반도체학과 그룹 ID
                11,
                CreateGroupEventRequest(
                    title = "임베디드 시스템 설계 프로젝트 최종 발표",
                    description = "프로젝트 최종 발표",
                    placeId = places.seminarRoomId,
                    startDate = getBaseDate().plusDays(4),
                    endDate = getBaseDate().plusDays(4),
                    startTime = LocalTime.of(18, 0),
                    endTime = LocalTime.of(20, 0),
                    isOfficial = true,
                    color = "#FF9800",
                ),
            )
            // ========== Slot 15: 다음주 월 09:00-11:00 ==========
            groupEventService.createEvent(
                owner,
                // AI시스템반도체학과 그룹 ID
                11,
                CreateGroupEventRequest(
                    title = "반도체 공정 실습 사전 교육",
                    description = "실습 전 이론 교육",
                    placeId = places.seminarRoomId,
                    startDate = getBaseDate().plusDays(7),
                    endDate = getBaseDate().plusDays(7),
                    startTime = LocalTime.of(9, 0),
                    endTime = LocalTime.of(11, 0),
                    isOfficial = true,
                    color = "#FF9800",
                ),
            )
            // ========== Slot 16: 다음주 월 14:00-16:00 ==========
            groupEventService.createEvent(
                owner,
                // AI시스템반도체학과 그룹 ID
                11,
                CreateGroupEventRequest(
                    title = "졸업생 선배와의 만남 (SK하이닉스)",
                    description = "반도체 기업 현직자 초청 강연",
                    placeId = places.seminarRoomId,
                    startDate = getBaseDate().plusDays(7),
                    endDate = getBaseDate().plusDays(7),
                    startTime = LocalTime.of(14, 0),
                    endTime = LocalTime.of(16, 0),
                    isOfficial = true,
                    color = "#FF9800",
                ),
            )
            // ========== Slot 17: 다음주 월 18:00-20:00 ==========
            groupEventService.createEvent(
                owner,
                // AI시스템반도체학과 그룹 ID
                11,
                CreateGroupEventRequest(
                    title = "시스템반도체 설계 공모전 팀 빌딩",
                    description = "공모전 준비 팀 구성",
                    placeId = places.seminarRoomId,
                    startDate = getBaseDate().plusDays(7),
                    endDate = getBaseDate().plusDays(7),
                    startTime = LocalTime.of(18, 0),
                    endTime = LocalTime.of(20, 0),
                    isOfficial = false,
                    color = "#FF9800",
                ),
            )
            // ========== Slot 18: 다음주 화 09:00-11:00 ==========
            groupEventService.createEvent(
                owner,
                // AI시스템반도체학과 그룹 ID
                11,
                CreateGroupEventRequest(
                    title = "학과 소모임 '칩메이커' 정기 회의",
                    description = "소모임 정기 활동",
                    placeId = places.seminarRoomId,
                    startDate = getBaseDate().plusDays(8),
                    endDate = getBaseDate().plusDays(8),
                    startTime = LocalTime.of(9, 0),
                    endTime = LocalTime.of(11, 0),
                    isOfficial = false,
                    color = "#FF9800",
                ),
            )
        }
    }

    /**
     * 다음 평일(월~금) 찾기
     *
     * @param from 기준 날짜
     * @param daysToAdd 추가할 일수 (기본값: 0 = 오늘부터 시작)
     * @return 다음 평일 날짜
     */
    private fun getNextWeekday(
        from: LocalDate = LocalDate.now(),
        daysToAdd: Int = 0,
    ): LocalDate {
        var date = from.plusDays(daysToAdd.toLong())
        while (date.dayOfWeek == DayOfWeek.SATURDAY || date.dayOfWeek == DayOfWeek.SUNDAY) {
            date = date.plusDays(1)
        }
        return date
    }

    /**
     * 안전한 실행 래퍼 - 에러 로깅 및 재발생
     *
     * @param description 작업 설명
     * @param action 실행할 작업
     * @return 작업 결과
     */
    private fun <T> safeExecute(
        description: String,
        action: () -> T,
    ): T {
        return try {
            val result = action()
            logger.debug("   -> $description: SUCCESS")
            result
        } catch (e: Exception) {
            logger.error("   -> $description: FAILED", e)
            throw RuntimeException("[$description] ${e.message}", e)
        }
    }

    /**
     * 테스트 사용자 데이터 클래스
     */
    private data class TestUsers(
        val user1: User,
        val user2: User,
        val user3: User,
    )

    /**
     * 커스텀 그룹 정보 데이터 클래스
     */
    private data class CustomGroups(
        val devCrewId: Long,
        val studentCouncilId: Long,
        val aiSwCodingStudyId: Long,
    )

    /**
     * 커스텀 장소 정보 데이터 클래스
     */
    private data class CustomPlaces(
        val labPlaceId: Long,
        val seminarRoomId: Long,
    )
}
