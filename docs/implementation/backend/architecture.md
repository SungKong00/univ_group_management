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
**패턴**: `@Service`, `@Transactional(readOnly = true/false)`, 단일 책임 원칙(SRP)
**예시**: `GroupService.createGroup()` - 검증 → 엔티티 저장 → 연관 데이터 생성

**서비스 분리 패턴** (2025-10 개선):
- `GroupService`: 그룹 CRUD 및 검색
- `GroupHierarchyService`: 그룹 계층 구조 조회
- `GroupDeletionService`: 그룹 삭제 및 관련 데이터 정리
- `GroupInitializationService`: 그룹 생성 오케스트레이션 (역할/채널 초기화)
- 각 서비스는 명확한 단일 책임, 트랜잭션 경계 분리

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

**트리거 이벤트**: ChannelRoleBindingChanged, GroupRoleChanged, GroupMemberChanged
**구현**: Spring `ApplicationEventPublisher` → `ChannelPermissionCacheManager` (`@EventListener`)
**패턴**: 서비스 이벤트 발행 → 캐시 매니저 수신 → `evictChannelCache()` 호출

## 컨텐츠 삭제 벌크 순서

**순서**: ChannelRoleBinding → Comments → Posts → Channels
**이유**: N+1 방지, 외래 키 제약 순수
**구현**: `commentRepository.deleteByIdIn(commentIds)` (ID 집합 기반)

## JPA 엔티티 패턴

### data class 지양 (2025-10 개선)
**원칙**: JPA 엔티티는 일반 class 사용, ID 기반 equals/hashCode 구현

**이유**:
- data class의 equals()는 모든 필드 기반 → Lazy Loading 프록시 충돌
- copy() 메서드는 새 객체 생성 → JPA 영속성 컨텍스트 분리
- Set/Map 컬렉션 사용 시 hashCode 변경으로 오작동

**적용 완료 엔티티**:
- `Group.kt`, `User.kt`, `GroupMember.kt`, `Channel.kt`, `ChannelRoleBinding.kt`
- ID 기반 equals/hashCode, 필드 직접 수정 패턴 사용
- JPA 영속성 안정성 및 Lazy Loading 호환성 개선

## 성능 최적화 패턴

### N+1 쿼리 해결 (2025-10 개선)
**해결**: 페이징 + JOIN FETCH 분리 (1. ID 조회 → 2. IN 절 상세 조회)
**위치**: `GroupRepositories.kt` - `findByGroupIdWithDetails()`
**효과**: 멤버 조회 301→2 쿼리 (Repository 최적화)

### 계층 쿼리
**구현**: WITH RECURSIVE (PostgreSQL CTE)
**위치**: `GroupRepository.findAllDescendantIds()`

## 관련 문서
- [권한 검증](./permission-checking.md) - 권한 검증 로직
- [트랜잭션 패턴](./transaction-patterns.md) - 트랜잭션 관리
- [데이터베이스 참조](../database-reference.md) - 스키마 구조
- [도메인 모델](../../backend/domain-model.md) - JPA 엔티티 설계
