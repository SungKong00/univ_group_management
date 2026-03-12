package com.univgroup.domain.user.service

import com.univgroup.domain.user.entity.User

/**
 * 사용자 서비스 인터페이스 (도메인 경계 - User 도메인 공개 API)
 *
 * 다른 도메인에서 사용자 정보가 필요할 때 이 인터페이스를 통해 접근한다.
 */
interface IUserService {
    /**
     * ID로 사용자 조회
     *
     * @param userId 사용자 ID
     * @return 사용자 엔티티 (없으면 null)
     */
    fun findById(userId: Long): User?

    /**
     * ID로 사용자 조회 (없으면 예외)
     *
     * @param userId 사용자 ID
     * @return 사용자 엔티티
     * @throws ResourceNotFoundException 사용자가 없을 경우
     */
    fun getById(userId: Long): User

    /**
     * 이메일로 사용자 조회
     *
     * @param email 이메일
     * @return 사용자 엔티티 (없으면 null)
     */
    fun findByEmail(email: String): User?

    /**
     * 사용자 존재 여부 확인
     *
     * @param userId 사용자 ID
     * @return 존재 여부
     */
    fun exists(userId: Long): Boolean

    /**
     * 닉네임 사용 가능 여부 확인
     *
     * @param nickname 닉네임
     * @param excludeUserId 제외할 사용자 ID (본인 닉네임 변경 시)
     * @return 사용 가능 여부
     */
    fun isNicknameAvailable(
        nickname: String,
        excludeUserId: Long? = null,
    ): Boolean
}
