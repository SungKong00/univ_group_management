package org.castlekong.backend.repository

import jakarta.persistence.criteria.JoinType
import org.castlekong.backend.entity.GroupMember
import org.springframework.data.jpa.domain.Specification

object GroupMemberSpecification {
    /**
     * 그룹 ID 필터
     */
    fun hasGroupId(groupId: Long): Specification<GroupMember> {
        return Specification { root, _, criteriaBuilder ->
            criteriaBuilder.equal(root.get<Long>("group").get<Long>("id"), groupId)
        }
    }

    /**
     * 역할 ID 필터 (OR 조합)
     * roleIds가 null이거나 비어있으면 조건 없음
     */
    fun hasRoleIdIn(roleIds: List<Long>?): Specification<GroupMember>? {
        if (roleIds.isNullOrEmpty()) return null
        return Specification { root, _, _ ->
            root.get<Long>("role").get<Long>("id").`in`(roleIds)
        }
    }

    /**
     * 소속 그룹 ID 필터 (OR 조합)
     * 현재 그룹의 하위 그룹에 속한 멤버 필터링
     * groupIds가 null이거나 비어있으면 조건 없음
     */
    fun belongsToSubGroups(groupIds: List<Long>?): Specification<GroupMember>? {
        if (groupIds.isNullOrEmpty()) return null
        return Specification { root, query, criteriaBuilder ->
            // 서브쿼리: 해당 사용자가 지정된 하위 그룹에 속하는지 확인
            val subQuery = query!!.subquery(Long::class.java)
            val subRoot = subQuery.from(GroupMember::class.java)
            subQuery.select(criteriaBuilder.count(subRoot.get<Long>("id")))
            subQuery.where(
                criteriaBuilder.and(
                    criteriaBuilder.equal(subRoot.get<Long>("user"), root.get<Long>("user")),
                    subRoot.get<Long>("group").get<Long>("id").`in`(groupIds),
                ),
            )
            criteriaBuilder.greaterThan(subQuery, 0L)
        }
    }

    /**
     * 학년 필터 (OR 조합)
     * grades가 null이거나 비어있으면 조건 없음
     */
    fun hasAcademicYearIn(grades: List<Int>?): Specification<GroupMember>? {
        if (grades.isNullOrEmpty()) return null
        return Specification { root, _, _ ->
            val userJoin = root.join<Any, Any>("user", JoinType.LEFT)
            userJoin.get<Int>("academicYear").`in`(grades)
        }
    }

    /**
     * 학번(입학년도) 필터 (OR 조합)
     * years가 null이거나 비어있으면 조건 없음
     * 입력: "24", "25" → DB 검색: "2024", "2025" (studentNo 앞 4자리)
     */
    fun hasStudentYearIn(years: List<String>?): Specification<GroupMember>? {
        if (years.isNullOrEmpty()) return null
        return Specification { root, _, criteriaBuilder ->
            val userJoin = root.join<Any, Any>("user", JoinType.LEFT)
            val studentNo = userJoin.get<String>("studentNo")

            val predicates =
                years.map { year ->
                    val fullYear = if (year.length == 2) "20$year" else year
                    criteriaBuilder.like(studentNo, "$fullYear%")
                }

            criteriaBuilder.or(*predicates.toTypedArray())
        }
    }

    /**
     * 학년 OR 학번 필터 (특수 조합)
     * 학년과 학번은 동일 범주로 OR 관계
     */
    fun hasAcademicYearOrStudentYear(
        grades: List<Int>?,
        years: List<String>?,
    ): Specification<GroupMember>? {
        val gradeSpec = hasAcademicYearIn(grades)
        val yearSpec = hasStudentYearIn(years)

        return when {
            gradeSpec != null && yearSpec != null -> {
                Specification { root, query, criteriaBuilder ->
                    criteriaBuilder.or(
                        gradeSpec.toPredicate(root, query, criteriaBuilder),
                        yearSpec.toPredicate(root, query, criteriaBuilder),
                    )
                }
            }
            gradeSpec != null -> gradeSpec
            yearSpec != null -> yearSpec
            else -> null
        }
    }

    /**
     * 모든 필터 조합 (역할 필터 단독 처리)
     *
     * @param roleIds 역할 ID 목록 (단독 동작)
     * @param groupIds 하위 그룹 ID 목록
     * @param grades 학년 목록
     * @param years 학번 목록 (예: "24", "25")
     */
    fun filterMembers(
        groupId: Long,
        roleIds: List<Long>?,
        groupIds: List<Long>?,
        grades: List<Int>?,
        years: List<String>?,
    ): Specification<GroupMember> {
        // 1. 그룹 ID 필터는 항상 적용
        var spec = hasGroupId(groupId)

        // 2. 역할 필터가 있으면 단독 동작 (다른 필터 무시)
        if (!roleIds.isNullOrEmpty()) {
            val roleSpec = hasRoleIdIn(roleIds)
            if (roleSpec != null) {
                spec = spec.and(roleSpec)
            }
            return spec
        }

        // 3. 일반 필터 조합 (항목 간 AND)

        // 소속 그룹 필터
        val groupSpec = belongsToSubGroups(groupIds)
        if (groupSpec != null) {
            spec = spec.and(groupSpec)
        }

        // 학년/학번 필터 (OR 관계)
        val academicSpec = hasAcademicYearOrStudentYear(grades, years)
        if (academicSpec != null) {
            spec = spec.and(academicSpec)
        }

        return spec
    }
}
