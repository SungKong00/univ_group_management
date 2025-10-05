# 권한 시스템 (Permission System)

## 역할에 따른 차별화된 기능
그룹 내에서 사용자는 각자의 역할에 따라 다른 기능을 사용할 수 있습니다. 이는 실제 조직에서 직책에 따라 권한이 다른 것과 같은 원리입니다.

**기본 원리**: `사용자` → `역할 부여` → `역할별 기능 사용`

## 권한의 두 가지 범위

### 그룹 전체 권한
그룹 운영과 관련된 전반적인 권한들입니다.
- **그룹 관리**: 그룹 정보 수정, 삭제 권한
- **멤버 관리**: 멤버 초대, 강제 탈퇴, 역할 변경 권한
- **채널 관리**: 새 채널 생성, 삭제, 채널 설정 변경 권한
- **모집 관리**: 신규 멤버 모집 게시글 작성 및 지원자 심사 권한

### 채널별 권한
각 채널에서의 활동과 관련된 세부 권한들입니다.
- **채널 보기**: 채널 존재 확인 및 입장 권한
- **글 읽기**: 채널 내 게시글과 댓글 읽기 권한
- **글 쓰기**: 새로운 게시글 작성 권한
- **댓글 쓰기**: 다른 사람 글에 댓글 달기 권한
- **파일 업로드**: 게시글이나 댓글에 파일 첨부 권한

## 기본 역할 (시스템 역할)
모든 그룹에는 아래 3가지 시스템 역할이 자동 생성됩니다. 시스템 역할은 플랫폼 구조 안정성과 예측 가능한 보안/권한 모델 유지를 위해 **이름 / 우선순위 / 권한을 수정하거나 삭제할 수 없습니다.** 시도 시 `SYSTEM_ROLE_IMMUTABLE` (HTTP 403) 오류 반환.

### Owner (그룹 오너)
- 모든 권한 보유
- 소유권 이전 가능(추후 지원 로드맵)
- 삭제/수정 불가 (시스템 역할)

### Advisor (자문/지도)
- MVP 단계: Owner 와 동일 권한 세트
- 향후: 운영/정책상 일부 축소 예정 가능
- 시스템 역할 → 수정/삭제 불가

### Member (기본 멤버)
- 기본 참여(워크스페이스 접근)
- 채널별 실제 활동 권한은 채널 권한 바인딩으로 결정
- 삭제/수정 불가 (시스템 역할)

## 커스텀 역할
그룹장이 생성. 이름/우선순위/권한 변경 및 삭제 가능. 업무 세분화(예: MODERATOR, RECRUITMENT_MANAGER 등)에 사용.

### 시스템 역할 vs 커스텀 역할 비교
| 구분 | 시스템 역할 (Owner/Advisor/Member) | 커스텀 역할 |
|------|------------------------------------|-------------|
| 생성 | 그룹 생성 시 자동 | 그룹장이 명시적으로 생성 |
| 수정 | 불가 (`SYSTEM_ROLE_IMMUTABLE`) | 가능 |
| 삭제 | 불가 | 가능 |
| 권한 기원 | 플랫폼 정책 | 생성 시 지정 + 이후 변경 |
| 목적 | 최소 운영/보안 경계 | 조직별 세분화/업무 분장 |

## 에러 코드 매핑 (역할/권한 관련)
| 코드 | 의미 | HTTP |
|------|------|------|
| SYSTEM_ROLE_IMMUTABLE | 시스템 역할 수정/삭제 시도 | 403 |
| FORBIDDEN | 권한 부족 | 403 |
| UNAUTHORIZED / INVALID_TOKEN / EXPIRED_TOKEN | 인증/토큰 문제 | 401 |

## 권한 확인 방식
1. 사용자 그룹 멤버십 조회
2. 역할(시스템 또는 커스텀) 권한 집합 결정
3. (채널 자원인 경우) ChannelRoleBinding 매핑으로 채널 수준 권한 결합
4. PermissionService 캐시 조회 → 없으면 계산 후 캐시 저장

## Spring Security 통합

### GroupPermissionEvaluator
Spring Security의 `@PreAuthorize` 어노테이션과 통합하여 선언적 권한 검증을 제공합니다.

**주요 역할**:
- `PermissionEvaluator` 인터페이스 구현
- 대상 리소스 타입(GROUP, CHANNEL, RECRUITMENT 등)별 권한 검증 라우팅
- 2단계 권한 검증 플로우 실행

**지원하는 대상 타입**:
- `GROUP`: 그룹 레벨 권한 검증 (예: GROUP_MANAGE, MEMBER_MANAGE)
- `CHANNEL`: 채널 레벨 권한 검증 (예: CHANNEL_VIEW, POST_WRITE)
- `RECRUITMENT`: 모집 관련 권한 검증 (그룹 권한으로 위임)
- `APPLICATION`: 지원서 관련 권한 검증 (본인 또는 모집 관리 권한)

**사용 예시**:
```kotlin
@PreAuthorize("@security.hasGroupPerm(#groupId, 'CHANNEL_MANAGE')")
fun createChannel(groupId: Long, request: CreateChannelRequest): ChannelDto

@PreAuthorize("@security.hasChannelPerm(#channelId, 'POST_WRITE')")
fun createPost(channelId: Long, request: CreatePostRequest): PostDto
```

### 2단계 권한 검증 플로우 (채널 권한 예시)

1. **그룹 멤버십 검증**
   - 사용자가 채널이 속한 그룹의 멤버인지 확인
   - 멤버가 아니면 즉시 `false` 반환 (403 Forbidden)

2. **채널 권한 바인딩 검증**
   - 사용자의 그룹 역할(GroupRole) 조회
   - ChannelRoleBinding에서 (채널, 역할) 매핑 조회
   - 바인딩에 요청한 ChannelPermission이 포함되어 있는지 확인

**구현 패턴**:
```kotlin
private fun checkChannelPermission(channelId: Long, userId: Long, permission: String): Boolean {
    // 1단계: 채널 조회 및 그룹 멤버십 확인
    val channel = channelRepository.findById(channelId).orElse(null) ?: return false
    val member = groupMemberRepository.findByGroupIdAndUserId(channel.group.id, userId)
        .orElse(null) ?: return false

    // 2단계: 채널 권한 바인딩 확인
    val binding = channelRoleBindingRepository
        .findByChannelIdAndGroupRoleId(channelId, member.role.id) ?: return false

    return try {
        val channelPermission = ChannelPermission.valueOf(permission)
        binding.permissions.contains(channelPermission)
    } catch (e: IllegalArgumentException) {
        log.warn("Invalid channel permission: $permission", e)
        false
    }
}
```

**특징**:
- Security Layer에서 Repository를 직접 사용 (Service Layer 우회)
- 순수 권한 검증 로직만 수행 (비즈니스 로직 없음)
- 빠른 실패(Fail Fast) 전략: 조건 미충족 시 즉시 `false` 반환
- ADMIN 권한 사용자는 모든 검증 우회 (short-circuit)

### 권한 검증 실패 처리
- `@PreAuthorize`가 `false`를 반환하면 Spring Security가 자동으로 `403 Forbidden` 응답
- GlobalExceptionHandler에서 `AccessDeniedException` 처리
- 일관된 ApiResponse 에러 형식으로 변환

## 권한 캐싱 & 무효화 전략
`PermissionService` 는 (groupId, userId) 단위 캐시를 유지하며 아래 이벤트에서 무효화:
- 역할 생성 / 수정 / 삭제
- 멤버 역할 변경
- 채널 역할 바인딩 추가 / 수정 / 삭제

## 채널 권한 바인딩 기본값
- (정책 2025-10-01 rev5) 그룹 생성 직후 생성되는 기본 2개 채널(공지사항 / 자유게시판)은 서비스 초기화 로직에서 템플릿 ChannelRoleBinding(OWNER, ADVISOR, MEMBER) 세트를 자동 부여.
- 사용자(운영자)가 이후 생성하는 모든 추가 채널은 **권한 바인딩 0개** 로 시작 (OWNER 조차 CHANNEL_VIEW 없음) → UI 에서 즉시 권한 매트릭스 설정 필요.
- 채널 생성 권한(CHANNEL_MANAGE 또는 그룹 소유자 권한)을 가진 사용자라도, 사용자 정의 채널에서 권한을 부여하기 전에는 읽기/쓰기 불가.
- 기본 초기 채널을 삭제한 뒤 재생성한 채널은 "사용자 정의 채널" 규칙(0개 시작)을 따름.
- 관리 권한은 "권한 구성 UI 진입" 과 "바인딩 추가/삭제" 만 허용하며 View / Read / Write 권한을 자동 부여하지 않음.
- Owner / Advisor / Member 는 모두 동일한 방식으로 명시적 바인딩 필요(초기 2채널 제외).

### 권한 부여 모델 (Permission-Centric)
권한 설정은 "역할 → 권한 집합" 이 아닌 **"권한별로 허용할 역할 리스트를 지정"** 하는 형태로 문서화합니다.

예: 다음과 같이 권한별로 허용 대상 역할을 선택합니다.

| 권한 (ChannelPermission) | 허용 역할 목록 예시 |
|--------------------------|----------------------|
| CHANNEL_VIEW             | OWNER, MEMBER        |
| POST_READ                | OWNER, MEMBER        |
| POST_WRITE               | OWNER                |
| COMMENT_WRITE            | OWNER                |
| FILE_UPLOAD              | (없음) / 필요 시 OWNER |

> 내부 구현은 (channel, role) 단위 바인딩에 permissions Set 을 유지하지만, 운영자는 UI 상에서 "권한별로 어떤 역할을 허용할지" 매트릭스를 채우는 사고방식으로 설정합니다.

### 초기 상태 요약
| 항목 | 기본 초기 2채널 | 사용자 정의 채널 |
|------|----------------|------------------|
| ChannelRoleBinding | 3개(OWNER/ADVISOR/MEMBER 템플릿) | 0개 |
| Owner 읽기/쓰기 | 템플릿 부여됨 | 없음 |
| Member 읽기/쓰기 | 공지: READ/COMMENT / 자유: READ/WRITE/COMMENT | 없음 |
| 네비게이션 노출 | 즉시 노출 | CHANNEL_VIEW 권한 부여 후 |

### 권한 부여 절차 (사용자 정의 채널)
1. 채널 생성 (바인딩 0개)
2. CHANNEL_VIEW 권한에 최소 1개 역할 추가
3. POST_READ 권한에 필요한 역할 추가
4. POST_WRITE / COMMENT_WRITE / FILE_UPLOAD 선택적 추가
5. 저장 → (channel, role) 바인딩 생성·갱신

> 기본 초기 채널의 템플릿을 수정하려면 동일한 매트릭스 UI에서 역할 권한을 재설정.

## 컨텐츠 삭제 일괄 처리(최신 구현 요약)
워크스페이스 또는 채널 삭제 시 성능/무결성을 위해 **벌크 삭제 순서** 적용:
1) ChannelRoleBinding (채널 목록 기반 일괄)
2) Comments (postIds 기반 일괄)
3) Posts (channelIds 기반 일괄)
4) Channels
→ TransientObjectException 방지 및 N+1 감소.

## 변경 이력
- 2025-10-01: 시스템 역할 불변성 등 추가
- 2025-10-01 (rev2): 채널 생성 시 기본 권한 바인딩 없음으로 반영
- 2025-10-01 (rev3): 권한 모델을 역할 중심 기술 → 권한별 역할 매핑(Permission-Centric)으로 문서화
- 2025-10-01 (rev5): 기본 2채널 템플릿 + 사용자 정의 채널 0바인딩 혼합 전략 명시

## 캘린더 권한 (Calendar Permissions)

> **개발 우선순위**: Phase 6 이후 예정
> **상태**: 개념 설계 중, 스키마 미확정

캘린더 시스템에 필요한 권한은 다음과 같이 계획되어 있습니다:

### 그룹 레벨 권한
- `CALENDAR_VIEW`: 그룹 캘린더 조회 권한
- `CALENDAR_MANAGE`: 공식 일정 생성/수정/삭제 권한

### 장소 관리 권한 (설계 의논 필요)
장소 관리 권한은 다음 두 가지 방식 중 하나로 통합될 예정:

**Option A: RBAC 시스템 통합** (권장)
- `PLACE_MANAGE`: 장소 등록, 사용 그룹 승인, 예약 관리
- `PLACE_RESERVE`: 장소 예약 권한 (사용 그룹 멤버)
- 기존 GroupRole에 추가하여 일관된 권한 체계 유지

**Option B: 독립 권한 시스템**
- 장소별 독립적인 권한 테이블 (PlacePermission 엔티티)
- 그룹 권한과 별도로 관리
- 복잡도 증가, 권한 확인 로직 이원화

### 권한 매트릭스 (예시)

> 아래는 Option A 채택 시 예상 매트릭스입니다.

| 권한 | OWNER | ADVISOR | MEMBER | 설명 |
|------|-------|---------|--------|------|
| CALENDAR_VIEW | ✓ | ✓ | ✓ | 그룹 캘린더 조회 |
| CALENDAR_MANAGE | ✓ | ✓ | - | 공식 일정 관리 |
| PLACE_MANAGE | ✓ | - | - | 장소 관리 (관리 주체 그룹만) |
| PLACE_RESERVE | ✓ | ✓ | ✓ | 장소 예약 (사용 그룹) |

### 다음 단계
1. 데이터베이스 스키마 설계 완료 후 권한 구조 확정
2. 장소 관리 권한 통합 방식 결정 (Option A vs B)
3. 권한 검증 로직 구현 (PermissionService 확장)
4. UI 권한 매트릭스에 캘린더 권한 추가

**관련 문서**: [캘린더 시스템](calendar-system.md) | [장소 관리](calendar-place-management.md)

---

## 추가 참고
- 채널 권한: `channel-permissions.md`
- 워크스페이스 구조: `workspace-channel.md`
- 캘린더 시스템: `calendar-system.md`
- 문제 해결: `../troubleshooting/permission-errors.md`
