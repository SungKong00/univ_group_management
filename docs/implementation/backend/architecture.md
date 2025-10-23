# 백엔드 아키텍처

## 개요
Spring Boot + Kotlin 기반 3레이어 아키텍처를 따릅니다.

## 3레이어 아키텍처

```
Controller Layer (HTTP 처리)
    ↓
Service Layer (비즈니스 로직)
    ↓
Repository Layer (데이터 접근)
```

### Controller Layer
**역할**: HTTP 요청 처리 및 응답 반환
**위치**: `backend/src/main/kotlin/.../controller/`
**패턴**: `@RestController`, `@PreAuthorize`, `@Valid`, `Authentication`
**예시**: `GroupController.createGroup()` - 그룹 생성 API

### Service Layer
**역할**: 비즈니스 로직 실행, 트랜잭션 관리
**위치**: `backend/src/main/kotlin/.../service/`
**패턴**: `@Service`, `@Transactional(readOnly = true/false)`
**예시**: `GroupService.createGroup()` - 검증 → 엔티티 저장 → 연관 데이터 생성

### Repository Layer
**역할**: 데이터베이스 CRUD 작업
**위치**: `backend/src/main/kotlin/.../repository/`
**패턴**: `JpaRepository`, `@Query`, `JOIN FETCH`, 소프트 삭제 처리
**예시**: `GroupRepository.findPublicGroups()` - JPQL + Pageable

## 표준 응답 형식

### ApiResponse 구조
**위치**: `backend/src/main/kotlin/.../dto/ApiResponse.kt`
**필드**: `success: Boolean`, `data: T?`, `error: ErrorResponse?`, `timestamp`
**규칙**: 성공 시 `success=true` + `data`, 실패 시 `success=false` + `error`

### 전역 예외 매핑
| ErrorCode | HTTP Status | 비고 |
|-----------|-------------|------|
| INVALID_TOKEN / EXPIRED_TOKEN / UNAUTHORIZED | 401 | 인증 실패 |
| FORBIDDEN | 403 | 권한 부족 |
| SYSTEM_ROLE_IMMUTABLE | 403 | 시스템 역할 수정 금지 |
| GROUP_ROLE_NAME_ALREADY_EXISTS | 409 | 역할명 충돌 |

**구현 위치**: `backend/src/main/kotlin/.../exception/GlobalExceptionHandler.kt`

## 권한 캐시 무효화 패턴

### 이벤트 기반 무효화
채널 권한 변경 시 Spring `ApplicationEventPublisher`를 통해 이벤트 발행 → `ChannelPermissionCacheManager`가 캐시 무효화 처리.

**무효화 트리거 이벤트**:
- `ChannelRoleBindingChangedEvent`: 채널-역할 바인딩 변경
- `GroupRoleChangedEvent`: 그룹 역할 변경
- `GroupMemberChangedEvent`: 멤버 역할 변경

**구현 위치**:
- 이벤트 발행: 각 Service 메서드
- 이벤트 수신: `ChannelPermissionCacheManager`

**패턴**: 서비스에서 이벤트 발행 → 캐시 매니저에서 `@EventListener`로 수신 → `evictChannelCache()` 호출

## 컨텐츠 삭제 벌크 순서

### Workspace/Channel 삭제 시 순서
```
ChannelRoleBinding → Comments → Posts → Channels
```

**이유**:
- N+1 문제 방지
- TransientObjectException 방지
- 외래 키 제약 순서 준수

**구현**: ID 집합 기반 bulk query 사용
- `commentRepository.deleteByIdIn(commentIds)`
- `postRepository.deleteByIdIn(postIds)`

## 관련 문서
- [권한 검증](./permission-checking.md) - 권한 검증 로직
- [트랜잭션 패턴](./transaction-patterns.md) - 트랜잭션 관리
- [데이터베이스 참조](../database-reference.md) - 스키마 구조
