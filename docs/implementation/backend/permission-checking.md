# 권한 검증 (Permission Checking)

## 개요
그룹 권한 및 채널 권한 검증 로직의 설계 결정사항과 구현 패턴을 다룹니다.

## 권한 검증 레이어 설계

### 설계 결정: Security Layer에서 캐시/Repository 직접 사용

**핵심 원칙**: `@PreAuthorize`는 Controller 메서드 실행 **전**에 동작하므로, Service Layer를 우회하여 캐시 또는 Repository를 직접 사용.

**검증 흐름**: `@PreAuthorize` → `GroupPermissionEvaluator` → CacheManager (캐시 조회) → Repository (캐시 없을 시) → true/false 반환 → true면 실행, false면 403

**장점**:
- 빠른 권한 검증 (캐시 적중 시 DB 접근 없음)
- 순수한 권한 검증 로직 (비즈니스 로직과 분리)
- 명확한 책임 분리: Security는 "접근 가능 여부만" 판단

## 그룹 권한 vs 채널 권한

### 그룹 권한
**검증 대상**: GROUP_CREATE, GROUP_EDIT, GROUP_DELETE, MEMBER_MANAGE 등

**캐시 전략**: `PermissionService`의 인메모리 캐시 활용
- 복잡한 상속/오버라이드 로직 (부모 그룹 권한 상속)
- 역할 우선순위 기반 권한 계산

**구현 위치**: `PermissionService.hasGroupPermission()`

### 채널 권한
**검증 대상**: CHANNEL_VIEW, POST_READ, POST_WRITE, COMMENT_WRITE 등

**캐시 전략**: `ChannelPermissionCacheManager`를 통한 Caffeine 캐시
- 버전 관리 (채널 권한 변경 시 버전 증가)
- 이벤트 기반 무효화
- 캐시 키: `"channel:{channelId}:user:{userId}"`

**구현 위치**: `GroupPermissionEvaluator.checkChannelPermission()`

**검증 단계**:
1. 채널 조회 및 그룹 멤버십 확인
2. 채널-역할 바인딩 조회 (캐시 우선)
3. 요청한 권한이 바인딩에 포함되어 있는지 확인

## 역할 불변성 (System Role Immutability)

### 시스템 역할 정의
- **그룹장 (GROUP_LEADER)**: 모든 권한 보유
- **교수 (PROFESSOR)**: 중간 권한 보유
- **멤버 (MEMBER)**: 기본 권한만 보유

### 불변성 규칙
- 시스템 역할의 **이름, 우선순위, 권한**은 수정 불가
- 삭제 불가
- 시도 시 `SYSTEM_ROLE_IMMUTABLE` 에러 반환 (HTTP 403)

**구현 위치**: `GroupRoleService` - 시스템 역할 수정/삭제 메서드에서 검증

**예외**: 커스텀 역할은 CRUD 모두 허용

## 채널 권한 (Permission-Centric 모델)

### 기본 원칙
- 새 채널 생성 시 `ChannelRoleBinding` **0개** (기본 권한 없음)
- 권한 단위(`ChannelPermission`)별로 허용 역할 리스트 명시적 지정
- `CHANNEL_VIEW` 없으면 채널이 네비게이션에 표시되지 않음
- 그룹장도 바인딩 없으면 읽기/쓰기 불가 (자동 상속 제거)

### 권한 매트릭스 예시
**예시**: CHANNEL_VIEW (그룹장/교수/멤버), POST_WRITE (그룹장/교수), FILE_UPLOAD (그룹장)
**설정**: 채널 생성 후 UI에서 권한 매트릭스 설정
**기본 채널 예외**: '공지사항', '자유게시판'은 자동 바인딩 생성

### ChannelRoleBinding 구조
**필드**:
- `channelId`: 채널 ID
- `groupRoleId`: 그룹 역할 ID
- `permissions`: Set<ChannelPermission> (해당 역할이 가진 채널 권한들)

**스키마 위치**: [database-reference.md#ChannelRoleBinding](../database-reference.md)

## 권한 캐시 전략

### 인메모리 캐시 (그룹 권한)
**구현**: `PermissionService` 내부 Map
**장점**: 빠른 조회, 복잡한 로직 처리
**단점**: 서버 재시작 시 초기화

### Caffeine 캐시 (채널 권한)
**구현**: `ChannelPermissionCacheManager`
**장점**: 버전 관리, 자동 만료, 이벤트 무효화
**무효화 트리거**:
- `ChannelRoleBindingChangedEvent`
- `GroupRoleChangedEvent`
- `GroupMemberChangedEvent`

## 관련 문서
- [권한 시스템](../../concepts/permission-system.md) - 권한 시스템 개념
- [채널 권한 에러](../../troubleshooting/permission-errors.md) - 권한 에러 해결
- [데이터베이스 참조](../database-reference.md) - ChannelRoleBinding 스키마
