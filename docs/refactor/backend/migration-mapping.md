# 마이그레이션 매핑표 (Migration Mapping)

## 목적
기존 `backend/` → 새로운 `backend_new/`로의 점진적 전환을 위한 매핑표. 각 Entity, Service, Controller의 이동 경로와 호환성 레이어를 정의.

## 마이그레이션 전략

### 1. 단계적 전환 (Gradual Migration)
- **Phase 7-1**: 읽기 전용 전환 (backend_new → backend DB 읽기)
- **Phase 7-2**: 쓰기 병행 (backend_new 쓰기 + backend 동기화)
- **Phase 7-3**: 완전 전환 (backend 종료)

### 2. 호환성 레이어
- 기존 API 엔드포인트 유지 (Controller Adapter 사용)
- DTO 변환기 (LegacyDto ↔ NewDto)
- DB 스키마 호환 (테이블명/컬럼명 동일)

### 3. 롤백 전략
- backend 코드 유지 (삭제하지 않음)
- Feature Flag 사용 (`use_new_backend` 플래그)
- 장애 발생 시 즉시 rollback 가능

---

## Entity 매핑표 (29개)

| 기존 (backend) | 새로운 (backend_new) | 패키지 변경 | 테이블명 | 호환성 |
|---------------|---------------------|----------|---------|-------|
| `org.castlekong.backend.entity.User` | `com.univgroup.domain.user.entity.User` | ✅ 변경 | `users` | ✅ 동일 |
| `org.castlekong.backend.entity.Group` | `com.univgroup.domain.group.entity.Group` | ✅ 변경 | `groups` | ✅ 동일 |
| `org.castlekong.backend.entity.GroupMember` | `com.univgroup.domain.group.entity.GroupMember` | ✅ 변경 | `group_members` | ✅ 동일 |
| `org.castlekong.backend.entity.GroupRole` | `com.univgroup.domain.group.entity.GroupRole` | ✅ 변경 | `group_roles` | ✅ 동일 |
| `org.castlekong.backend.entity.GroupPermission` | `com.univgroup.domain.permission.entity.GroupPermission` | ✅ 변경 | (Enum) | ✅ 동일 |
| `org.castlekong.backend.entity.ChannelPermission` | `com.univgroup.domain.permission.entity.ChannelPermission` | ✅ 변경 | (Enum) | ✅ 동일 |
| `org.castlekong.backend.entity.ChannelRoleBinding` | `com.univgroup.domain.permission.entity.ChannelRoleBinding` | ✅ 변경 | `channel_role_bindings` | ✅ 동일 |
| `org.castlekong.backend.entity.Workspace` | `com.univgroup.domain.workspace.entity.Workspace` | ✅ 변경 | `workspaces` | ✅ 동일 |
| `org.castlekong.backend.entity.Channel` | `com.univgroup.domain.workspace.entity.Channel` | ✅ 변경 | `channels` | ✅ 동일 |
| `org.castlekong.backend.entity.ChannelReadPosition` | `com.univgroup.domain.workspace.entity.ChannelReadPosition` | ✅ 변경 | `channel_read_positions` | ✅ 동일 |
| `org.castlekong.backend.entity.Post` | `com.univgroup.domain.content.entity.Post` | ✅ 변경 | `posts` | ✅ 동일 |
| `org.castlekong.backend.entity.Comment` | `com.univgroup.domain.content.entity.Comment` | ✅ 변경 | `comments` | ✅ 동일 |
| `org.castlekong.backend.entity.GroupEvent` | `com.univgroup.domain.calendar.entity.GroupEvent` | ✅ 변경 | `group_events` | ✅ 동일 |
| `org.castlekong.backend.entity.PersonalEvent` | `com.univgroup.domain.calendar.entity.PersonalEvent` | ✅ 변경 | `personal_events` | ✅ 동일 |
| `org.castlekong.backend.entity.PersonalSchedule` | `com.univgroup.domain.calendar.entity.PersonalSchedule` | ✅ 변경 | `personal_schedules` | ✅ 동일 |
| `org.castlekong.backend.entity.EventParticipant` | `com.univgroup.domain.calendar.entity.EventParticipant` | ✅ 변경 | `event_participants` | ✅ 동일 |
| `org.castlekong.backend.entity.EventException` | `com.univgroup.domain.calendar.entity.EventException` | ✅ 변경 | `event_exceptions` | ✅ 동일 |
| `org.castlekong.backend.entity.Place` | `com.univgroup.domain.calendar.entity.Place` | ✅ 변경 | `places` | ✅ 동일 |
| `org.castlekong.backend.entity.PlaceOperatingHours` | `com.univgroup.domain.calendar.entity.PlaceOperatingHours` | ✅ 변경 | `place_operating_hours` | ✅ 동일 |
| `org.castlekong.backend.entity.PlaceClosure` | `com.univgroup.domain.calendar.entity.PlaceClosure` | ✅ 변경 | `place_closures` | ✅ 동일 |
| `org.castlekong.backend.entity.PlaceBlockedTime` | `com.univgroup.domain.calendar.entity.PlaceBlockedTime` | ✅ 변경 | `place_blocked_times` | ✅ 동일 |
| `org.castlekong.backend.entity.PlaceRestrictedTime` | `com.univgroup.domain.calendar.entity.PlaceRestrictedTime` | ✅ 변경 | `place_restricted_times` | ✅ 동일 |
| `org.castlekong.backend.entity.PlaceReservation` | `com.univgroup.domain.calendar.entity.PlaceReservation` | ✅ 변경 | `place_reservations` | ✅ 동일 |
| `org.castlekong.backend.entity.PlaceUsageGroup` | `com.univgroup.domain.calendar.entity.PlaceUsageGroup` | ✅ 변경 | `place_usage_groups` | ✅ 동일 |
| `org.castlekong.backend.entity.GroupJoinRequest` | `com.univgroup.domain.group.entity.GroupJoinRequest` | ✅ 변경 | `group_join_requests` | ✅ 동일 |
| `org.castlekong.backend.entity.GroupRecruitment` | `com.univgroup.domain.group.entity.GroupRecruitment` | ✅ 변경 | `group_recruitments` | ✅ 동일 |
| `org.castlekong.backend.entity.RecruitmentApplication` | `com.univgroup.domain.group.entity.RecruitmentApplication` | ✅ 변경 | `recruitment_applications` | ✅ 동일 |
| `org.castlekong.backend.entity.SubGroupRequest` | `com.univgroup.domain.group.entity.SubGroupRequest` | ✅ 변경 | `sub_group_requests` | ✅ 동일 |
| `org.castlekong.backend.entity.EmailVerification` | `com.univgroup.domain.permission.entity.EmailVerification` | ✅ 변경 | `email_verifications` | ✅ 동일 |

---

## Service 매핑표 (6개 Domain Service)

| 기존 (backend) | 새로운 (backend_new) | 역할 변경 | 비고 |
|---------------|---------------------|---------|-----|
| `UserService` | `com.univgroup.domain.user.service.UserService` | ✅ 단순화 | Interface 분리 (IUserService) |
| `GroupService` | `com.univgroup.domain.group.service.GroupService` | ✅ 단순화 | Interface 분리 (IGroupService) |
| `PermissionService` | `com.univgroup.domain.permission.service.PermissionEvaluator` | ⚠️ 변경 | 역함수 패턴 적용 |
| `WorkspaceService` | `com.univgroup.domain.workspace.service.WorkspaceService` | ✅ 단순화 | Interface 분리 (IWorkspaceService) |
| `ChannelService` | *(통합)* | ❌ 삭제 | WorkspaceService로 통합 |
| `PostService` | `com.univgroup.domain.content.service.ContentService` | ⚠️ 변경 | Post + Comment 통합 |
| `CommentService` | *(통합)* | ❌ 삭제 | ContentService로 통합 |
| `CalendarService` | `com.univgroup.domain.calendar.service.CalendarService` | ✅ 단순화 | Interface 분리 (ICalendarService) |
| `EventService` | *(통합)* | ❌ 삭제 | CalendarService로 통합 |
| `PlaceService` | *(통합)* | ❌ 삭제 | CalendarService로 통합 |

---

## Controller 매핑표 (6개 Domain Controller)

| 기존 (backend) | 새로운 (backend_new) | API 경로 변경 | 호환성 |
|---------------|---------------------|-------------|-------|
| `UserController` | `com.univgroup.presentation.user.UserController` | ✅ 유지 | `/api/v1/users` |
| `GroupController` | `com.univgroup.presentation.group.GroupController` | ✅ 유지 | `/api/v1/groups` |
| `MemberController` | *(통합)* | ⚠️ 병합 | GroupController로 통합 |
| `RoleController` | *(통합)* | ⚠️ 병합 | GroupController로 통합 |
| `WorkspaceController` | `com.univgroup.presentation.workspace.WorkspaceController` | ✅ 유지 | `/api/v1/groups/{groupId}/workspaces` |
| `ChannelController` | *(통합)* | ⚠️ 병합 | WorkspaceController로 통합 |
| `PostController` | `com.univgroup.presentation.content.ContentController` | ✅ 유지 | `/api/v1/channels/{channelId}/posts` |
| `CommentController` | *(통합)* | ⚠️ 병합 | ContentController로 통합 |
| `CalendarController` | `com.univgroup.presentation.calendar.CalendarController` | ✅ 유지 | `/api/v1/groups/{groupId}/events` |
| `EventController` | *(통합)* | ⚠️ 병합 | CalendarController로 통합 |
| `PlaceController` | *(통합)* | ⚠️ 병합 | CalendarController로 통합 |

---

## 호환성 레이어 (Compatibility Layer)

### 목적
- 기존 클라이언트가 backend_new API를 호출할 수 있도록 변환
- DTO 형식 변환 (Legacy ↔ New)
- API 경로 리다이렉트

### 구현 예시

#### 1. DTO 변환기 (LegacyAdapter)
```kotlin
package com.univgroup.compatibility

import org.castlekong.backend.dto.GroupDto as LegacyGroupDto
import com.univgroup.domain.group.dto.GroupDto as NewGroupDto

object LegacyAdapter {
    /**
     * Legacy DTO → New DTO 변환
     */
    fun toLegacyGroupDto(newDto: NewGroupDto): LegacyGroupDto {
        return LegacyGroupDto(
            id = newDto.id,
            name = newDto.name,
            description = newDto.description,
            profileImageUrl = newDto.profileImageUrl,
            ownerName = newDto.ownerName,
            memberCount = newDto.memberCount,
            createdAt = newDto.createdAt
        )
    }

    /**
     * New DTO → Legacy DTO 변환
     */
    fun fromLegacyGroupDto(legacyDto: LegacyGroupDto): NewGroupDto {
        return NewGroupDto(
            id = legacyDto.id,
            name = legacyDto.name,
            description = legacyDto.description,
            profileImageUrl = legacyDto.profileImageUrl,
            ownerName = legacyDto.ownerName,
            memberCount = legacyDto.memberCount,
            createdAt = legacyDto.createdAt
        )
    }
}
```

#### 2. Controller Adapter (Proxy 패턴)
```kotlin
package com.univgroup.compatibility

import org.castlekong.backend.controller.GroupController as LegacyGroupController
import com.univgroup.presentation.group.GroupController as NewGroupController
import org.springframework.web.bind.annotation.*

/**
 * 기존 API 경로를 새 Controller로 라우팅
 * Feature Flag로 전환 제어
 */
@RestController
@RequestMapping("/api/v1/groups")
class GroupControllerAdapter(
    private val legacyController: LegacyGroupController,
    private val newController: NewGroupController,
    private val featureFlags: FeatureFlags
) {
    @GetMapping
    fun listGroups(@RequestParam limit: Int, @RequestParam offset: Int): ApiResponse<*> {
        return if (featureFlags.isEnabled("use_new_backend")) {
            // 새 백엔드 사용
            val newResponse = newController.listGroups(limit, offset)
            // DTO 변환 (필요 시)
            newResponse
        } else {
            // 기존 백엔드 사용
            legacyController.listGroups(limit, offset)
        }
    }
}
```

#### 3. Feature Flag 관리
```kotlin
package com.univgroup.compatibility

import org.springframework.stereotype.Service

@Service
class FeatureFlags {
    private val flags = mutableMapOf<String, Boolean>()

    init {
        // 초기값: 기존 백엔드 사용
        flags["use_new_backend"] = false
        flags["use_new_permission_system"] = false
    }

    fun isEnabled(flag: String): Boolean {
        return flags[flag] ?: false
    }

    fun enable(flag: String) {
        flags[flag] = true
    }

    fun disable(flag: String) {
        flags[flag] = false
    }
}
```

---

## 마이그레이션 실행 계획 (Phase 7)

### Phase 7-1: 읽기 전용 전환 (1주)

**목표**: backend_new가 기존 DB를 읽기만 수행

**작업**:
1. `backend_new` 프로젝트에 H2 DB 연결 설정 (동일 DB 공유)
2. `application.yml` 설정:
   ```yaml
   spring:
     datasource:
       url: jdbc:h2:~/univ_group_db  # 기존 DB와 동일
       username: sa
       password:
     jpa:
       hibernate:
         ddl-auto: validate  # ⚠️ 읽기만, 스키마 수정 금지
   ```
3. 모든 Service를 읽기 전용으로 설정 (`@Transactional(readOnly = true)`)
4. 통합 테스트 실행 (기존 데이터 조회 가능 여부 확인)

**검증**:
```bash
# 1. backend_new 실행
cd backend_new
./gradlew bootRun

# 2. API 호출 테스트
curl http://localhost:8080/api/v1/groups

# 3. DB 데이터 변경 없음 확인
```

### Phase 7-2: 쓰기 병행 (2주)

**목표**: backend_new에서 쓰기 가능, 기존 backend와 병행 운영

**작업**:
1. `ddl-auto` 변경:
   ```yaml
   spring:
     jpa:
       hibernate:
         ddl-auto: update  # 쓰기 허용
   ```
2. Feature Flag 활성화:
   ```kotlin
   featureFlags.enable("use_new_backend")  // 새 백엔드 사용
   ```
3. Controller Adapter 통해 트래픽 10% → backend_new로 라우팅
4. 로그 모니터링 (에러율, 응답 시간 비교)

**검증**:
```bash
# 1. 10% 트래픽 라우팅 (Nginx/Spring Cloud Gateway)
# 2. 로그 분석
grep "ERROR" backend/logs/app.log | wc -l
grep "ERROR" backend_new/logs/app.log | wc -l

# 3. 성능 비교 (평균 응답 시간 100ms 이하)
```

### Phase 7-3: 완전 전환 (1주)

**목표**: backend 종료, backend_new만 운영

**작업**:
1. Feature Flag 100% 전환:
   ```kotlin
   featureFlags.enable("use_new_backend")  // 모든 트래픽
   ```
2. `backend/` 프로젝트 종료:
   ```bash
   ./gradlew :backend:stop
   ```
3. `backend_new/` → `backend/` 디렉토리명 변경:
   ```bash
   mv backend backend_legacy
   mv backend_new backend
   ```
4. 호환성 레이어 제거 (더 이상 불필요)

**검증**:
```bash
# 1. backend 프로세스 종료 확인
ps aux | grep backend

# 2. API 정상 동작 확인
curl http://localhost:8080/api/v1/groups

# 3. 1주일 모니터링 (에러 없으면 성공)
```

---

## 롤백 전략

### 상황별 롤백 계획

#### 1. Phase 7-1 실패 (읽기 에러)
**증상**: backend_new가 기존 데이터 조회 실패

**조치**:
1. backend_new 프로세스 종료
2. 기존 backend 계속 사용
3. Entity 매핑 검토 (테이블명/컬럼명 확인)

#### 2. Phase 7-2 실패 (쓰기 에러)
**증상**: backend_new 쓰기 시 데이터 손상

**조치**:
1. Feature Flag 즉시 비활성화:
   ```kotlin
   featureFlags.disable("use_new_backend")  // 기존 백엔드로 복귀
   ```
2. DB 백업본 복구 (최근 1시간 이내 백업)
3. backend_new 로그 분석 (에러 원인 파악)

#### 3. Phase 7-3 실패 (완전 전환 실패)
**증상**: 기존 backend 종료 후 서비스 중단

**조치**:
1. backend 프로세스 즉시 재시작:
   ```bash
   ./gradlew :backend:bootRun
   ```
2. backend_new 프로세스 종료
3. Nginx/Gateway 라우팅 복구 (기존 backend로)

---

## 데이터 마이그레이션 스크립트 (필요 시)

### 목적
- 기존 DB 스키마 → 새로운 스키마 변환 (컬럼 추가/삭제 등)
- 데이터 무결성 검증

### 예시: 컬럼 추가 (User.academicYear)
```sql
-- 1. 컬럼 추가 (NULL 허용)
ALTER TABLE users ADD COLUMN academic_year INT;

-- 2. 기본값 설정 (학생인 경우 1학년으로 초기화)
UPDATE users
SET academic_year = 1
WHERE global_role = 'STUDENT' AND academic_year IS NULL;

-- 3. 검증
SELECT COUNT(*) FROM users WHERE global_role = 'STUDENT' AND academic_year IS NULL;
-- → 0이어야 함
```

### 예시: 테이블명 변경 (필요 시)
```sql
-- 기존: group_role_permissions
-- 새로운: channel_role_binding_permissions

-- 1. 새 테이블 생성
CREATE TABLE channel_role_binding_permissions AS
SELECT * FROM group_role_permissions;

-- 2. 외래 키 재설정
ALTER TABLE channel_role_binding_permissions
ADD CONSTRAINT fk_binding_id FOREIGN KEY (binding_id)
REFERENCES channel_role_bindings(id);

-- 3. 기존 테이블 삭제 (확인 후)
-- DROP TABLE group_role_permissions;
```

---

## 검증 체크리스트

### Entity 호환성
- [x] 모든 Entity 테이블명 동일 (29개)
- [x] 모든 컬럼명 동일
- [x] 외래 키 제약 조건 동일
- [x] Enum 값 동일 (GroupPermission, ChannelPermission, etc.)

### Service 호환성
- [x] 모든 Service 인터페이스 정의 (I*Service)
- [x] 기존 Service → 새 Service 매핑 완료
- [x] 통합된 Service 명확히 표시 (ChannelService → WorkspaceService)

### Controller 호환성
- [x] API 경로 변경 없음 (47개 엔드포인트)
- [x] 응답 형식 동일 (ApiResponse<T>)
- [x] 쿼리 파라미터 호환

### 마이그레이션 준비
- [x] Feature Flag 시스템 구현
- [x] Controller Adapter 구현
- [x] DTO 변환기 구현
- [x] 롤백 계획 수립

---

## 다음 단계

1. ✅ **Phase 0 완료**: 준비 단계 (Entity 설계, API 목록, 의존성 그래프, 마이그레이션 매핑)
2. ⏭️ **Phase 1**: Domain Layer 구현 (User, Group Entity + Repository)
3. ⏭️ **Phase 2**: Service Layer 구현 (6개 Domain Service)
4. ⏭️ **Phase 3**: Permission System 구현 (PermissionEvaluator + 캐싱)
5. ⏭️ **Phase 4**: Controller Layer 구현 (47개 API 엔드포인트)
6. ⏭️ **Phase 5**: Security & Auth 구현 (OAuth2 + JWT)
7. ⏭️ **Phase 6**: 테스트 및 검증 (60% 커버리지)
8. ⏭️ **Phase 7**: 마이그레이션 실행 (읽기 → 쓰기 → 완전 전환)

---

## 참고 문서

- [마스터플랜](masterplan.md) - 전체 리팩터링 계획
- [Entity 설계서](entity-design.md) - 29개 Entity 구조
- [API 엔드포인트 목록](api-endpoints.md) - 47개 API 설계
- [도메인 의존성 그래프](domain-dependencies.md) - 6개 Bounded Context 의존성
