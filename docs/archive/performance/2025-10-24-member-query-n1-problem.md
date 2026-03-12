# 멤버 조회 N+1 쿼리 문제 해결

**날짜**: 2025-10-24
**관련 커밋**: `f923d4a`

## 문제

멤버 100명 조회 시 **301개의 SQL 쿼리** 실행:
- 1개: 멤버 ID 조회 (페이징)
- 100개: 각 멤버의 User 엔티티 조회
- 100개: 각 멤버의 Group 엔티티 조회
- 100개: 각 멤버의 Role 엔티티 조회

**성능 영향**:
- 데이터베이스 왕복 301회
- 응답 시간 지연
- DB 커넥션 풀 고갈 위험

## 문제 원인

`GroupMemberService.getGroupMembersWithFilter()` 코드:
```kotlin
val members = groupMemberRepository.findAll(spec, pageable)
```

**근본 원인**:
1. **JPA Specification + Pageable**: 동적 쿼리 생성을 위해 사용
2. **JOIN FETCH 불가**: Specification은 런타임에 쿼리를 생성하므로 컴파일 타임에 JOIN FETCH 정의 불가
3. **Lazy Loading 기본 동작**: 연관 엔티티(`user`, `group`, `role`)가 필요할 때마다 개별 조회

## 해결방안 분석

N+1 문제는 다음 시점에 발생:
- Specification 쿼리 실행: 멤버 ID만 조회 (1개 쿼리)
- DTO 매핑 과정: `gm.user.name`, `gm.group.name` 접근 시 Lazy Loading (N개 쿼리)

**핵심**: Specification의 동적 쿼리 장점과 JOIN FETCH의 즉시 로딩을 **모두** 활용해야 함.

## 해결방안 후보

### 1. Specification에서 JOIN FETCH 시도
```kotlin
root.fetch("user")
root.fetch("group")
root.fetch("role")
```
- **장점**: 쿼리 1개로 해결
- **단점**: Specification + Pageable과 호환 불가, COUNT 쿼리 오류 발생

### 2. @EntityGraph 사용
```kotlin
@EntityGraph(attributePaths = ["user", "group", "role"])
fun findAll(spec: Specification, pageable: Pageable): Page<GroupMember>
```
- **장점**: 간단한 구현
- **단점**: Specification과 함께 사용 시 동작 불안정, Pageable 호환 문제

### 3. 2단계 쿼리 패턴 (선택됨)
```kotlin
// Phase 1: ID만 조회 (Specification + Pageable)
val idsPage = repository.findAll(spec, pageable).map { it.id }

// Phase 2: JOIN FETCH로 상세 조회
val members = repository.findByIdsWithDetails(idsPage.content)
```
- **장점**: 안정적, 명확한 쿼리 제어, Pageable 완벽 호환
- **단점**: 쿼리 2개 (하지만 총 301개 → 2개로 대폭 감소)

### 4. Native Query로 전체 재작성
- **장점**: 완전한 제어
- **단점**: 동적 쿼리 작성 복잡도 증가, 유지보수성 저하

## 해결방안 선택 이유

**방안 3 (2단계 쿼리 패턴)** 선택:

1. **안정성**: Specification, Pageable, JOIN FETCH 모두 정상 동작
2. **성능**: 301개 → 2개 쿼리 (99% 감소)
3. **유지보수성**: 코드 명확, 역할 분리
   - Phase 1: 복잡한 필터링 + 페이징
   - Phase 2: 단순한 IN 조회 + JOIN FETCH
4. **확장성**: 필터 조건 추가 시 Specification만 수정

**방안 1, 2 기각 이유**: Pageable과 함께 사용 시 COUNT 쿼리 오류 발생
**방안 4 기각 이유**: 동적 쿼리 작성 복잡도가 너무 높음

## 개선 후 개선점

### 정량적 개선
- **쿼리 수**: 301개 → **2개** (99% 감소)
- **DB 왕복**: 301회 → 2회
- **예상 응답 시간**: 대폭 단축 (네트워크 레이턴시 99% 감소)

### 정성적 개선
- **명확한 쿼리 제어**: 언제 어떤 데이터를 로딩하는지 명확
- **유지보수성 향상**: Phase 1/2 역할 분리로 디버깅 용이
- **확장 가능**: 새로운 필터 조건 추가 시 Phase 1만 수정
- **안정성**: 프로덕션 환경에서 검증된 패턴 사용

### 코드 변경
- `GroupMemberService.getGroupMembersWithFilter()`: 2단계 쿼리 적용
- `GroupMemberRepository.findByIdsWithDetails()`: JOIN FETCH 메서드 추가

### 관련 파일
- `backend/src/main/kotlin/org/castlekong/backend/service/GroupMemberService.kt`
- `backend/src/main/kotlin/org/castlekong/backend/repository/GroupRepositories.kt`
