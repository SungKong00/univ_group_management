# 백엔드 구현 가이드

## 개요
Spring Boot + Kotlin 백엔드 개발 시 필요한 실무 가이드 모음입니다.
본 문서는 실제 구현 패턴, 아키텍처 결정사항, 그리고 주의사항을 다룹니다.

## 문서 목록

### 기본 설정
- [개발 환경 설정](./development-setup.md) - H2 DB 설정, 동시성 처리, 데이터 초기화

### 아키텍처 & 패턴
- [아키텍처](./architecture.md) - 3레이어 구조, 표준 응답 형식, 캐시 무효화
- [인증](./authentication.md) - JWT 필터, 권한 체크 서비스
- [권한 검증](./permission-checking.md) - 권한 검증 로직, 매트릭스 패턴

### 트랜잭션 관리
- [트랜잭션 패턴](./transaction-patterns.md) - 기본 패턴, 전파 레벨
- [Best-Effort 패턴](./best-effort-pattern.md) - REQUIRES_NEW 사용법
- [예외 처리](./exception-handling.md) - 예외 처리 전략, 롤백 방지

### 테스트
- [테스트 가이드](./testing.md) - 통합 테스트, 보안 테스트

## 최근 개선사항 (2025-10)

### 서비스 계층 분리
- `GroupManagementService` → 4개 서비스로 분리 (단일 책임 원칙)
  - `GroupService`: CRUD 및 검색
  - `GroupHierarchyService`: 계층 구조 조회
  - `GroupDeletionService`: 삭제 및 정리
  - `GroupInitializationService`: 생성 오케스트레이션

### JPA 엔티티 개선
- `data class` → 일반 `class` 전환
  - 적용: Group, User, GroupMember, Channel, ChannelRoleBinding
  - ID 기반 equals/hashCode 구현
  - Lazy Loading 프록시 충돌 방지

### 성능 최적화
- N+1 쿼리 해결: 멤버 조회 301→2 쿼리
- Repository 페이징 + JOIN FETCH 분리 패턴

### 캘린더 엔티티 완성
- `EventParticipant.kt`: 그룹 일정 참여자 관리 (78줄)
- `EventException.kt`: 반복 일정 예외 처리 (118줄)
- Repository 2개, Service 2개 구현 완료

## 관련 문서
- [백엔드 설계 원칙](../../backend/README.md) - 기술 설계 및 결정사항
- [API 명세](../api-reference.md) - REST API 설계
- [스키마 정의](../database-reference.md) - 데이터베이스 구조
