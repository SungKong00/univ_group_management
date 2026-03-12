# H2 WITH RECURSIVE CTE 파싱 에러 해결

**날짜**: 2025-10-24
**관련 커밋**: `f923d4a`

## 문제

H2 데이터베이스 실행 시 WITH RECURSIVE 쿼리에서 **파싱 에러** 발생:

```
Syntax error in SQL statement "WITH RECURSIVE descendants [*]AS (...)"
expected "("
```

**영향 범위**:
- 애플리케이션 시작 실패
- 계층 구조 쿼리 3개 모두 실패
- 개발 환경(H2) 사용 불가

## 문제 원인

H2 데이터베이스는 WITH RECURSIVE 구문에서 **CTE 컬럼 명시**를 요구:

**잘못된 코드**:
```sql
WITH RECURSIVE descendants AS (  -- ❌ 컬럼 미지정
    SELECT id FROM groups WHERE parent_id = ?
    ...
)
```

**H2 파싱 과정**:
1. `WITH RECURSIVE` 키워드 인식
2. CTE 이름 `descendants` 파싱
3. `AS` 다음 `(컬럼목록)` 기대
4. 컬럼목록 없으면 **파싱 에러**

PostgreSQL, MySQL은 컬럼 추론이 가능하지만, H2 2.3.232는 명시적 선언 필요.

## 해결방안 분석

3개의 WITH RECURSIVE 쿼리 모두 동일 패턴:
1. `findAllDescendantIds()`: 하위 그룹 ID 조회
2. `countMembersWithHierarchy()`: 하위 그룹 멤버 수 집계
3. `findParentGroupIds()`: 상위 그룹 ID 조회

**공통 문제**: CTE 컬럼 미지정

## 해결방안 후보

### 1. CTE 컬럼 명시 추가 (선택됨)
```sql
WITH RECURSIVE descendants(id) AS (  -- ✅ 컬럼 명시
    SELECT id FROM groups WHERE parent_id = ?
    ...
)
```
- **장점**: 간단, PostgreSQL/MySQL/H2 모두 호환
- **단점**: 없음

### 2. countMembersWithHierarchy를 Application 레벨로 처리
```kotlin
val descendantIds = findAllDescendantIds(groupId)
val count = countByGroupIdIn(descendantIds)
```
- **장점**: H2 CTE 제약 우회, 쿼리 2개로 해결
- **단점**: 쿼리 1개 추가 실행

### 3. H2 전용 쿼리 분리 (@Profile 사용)
- **장점**: 각 DB 최적화
- **단점**: 유지보수 복잡도 증가

### 4. H2 버전 다운그레이드
- **장점**: 즉시 해결 가능성
- **단점**: 보안 패치 누락, 다른 문제 발생 가능

## 해결방안 선택 이유

**방안 1 + 방안 2 조합** 선택:

**방안 1 적용**:
- `findAllDescendantIds()`: CTE 컬럼 명시로 해결
- `findParentGroupIds()`: CTE 컬럼 명시로 해결

**방안 2 적용** (`countMembersWithHierarchy`):
- H2에서 CTE + JOIN 조합 시 추가 파싱 이슈 발견
- Application 레벨 처리로 안정성 확보

**이유**:
1. **호환성**: PostgreSQL, MySQL, H2 모두 동작
2. **간결성**: 최소한의 코드 변경
3. **안정성**: 검증된 표준 SQL 문법 사용
4. **성능**: 쿼리 2개로도 충분히 효율적

**방안 3, 4 기각 이유**: 불필요한 복잡도 증가, 유지보수성 저하

## 개선 후 개선점

### 정량적 개선
- **애플리케이션 시작**: 실패 → **성공**
- **WITH RECURSIVE 쿼리**: 3개 모두 정상 동작
- **DB 호환성**: PostgreSQL, MySQL 8.0+, H2 1.4.200+ 모두 지원

### 정성적 개선
- **표준 SQL 준수**: CTE 컬럼 명시는 SQL 표준
- **명확한 의도**: 컬럼이 명시되어 쿼리 가독성 향상
- **안정적 동작**: DB별 파싱 차이로 인한 오류 방지

### 코드 변경

**GroupRepositories.kt**:
```kotlin
// Before
WITH RECURSIVE descendants AS (...)

// After
WITH RECURSIVE descendants(id) AS (...)
WITH RECURSIVE ancestors(id) AS (...)
```

**GroupMemberRepository.kt** (신규):
```kotlin
fun countByGroupIdIn(groupIds: List<Long>): Long
```

**GroupManagementService.kt**:
```kotlin
// 2단계 쿼리로 변경
val descendantIds = groupRepository.findAllDescendantIds(groupId)
val count = groupMemberRepository.countByGroupIdIn(descendantIds)
```

### 관련 파일
- `backend/src/main/kotlin/org/castlekong/backend/repository/GroupRepositories.kt`
- `backend/src/main/kotlin/org/castlekong/backend/service/GroupManagementService.kt`
