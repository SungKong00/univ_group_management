# 개발 환경 설정

## 개요
로컬 개발 환경 구성 시 필수 설정 및 주의사항을 다룹니다.

## H2 DB ID 충돌 해결

### 문제 상황
`data.sql`을 통해 데이터를 직접 삽입할 때, `auto_increment` 시퀀스가 실제 데이터의 마지막 ID와 동기화되지 않아 Primary Key Violation이 발생합니다.

### 해결책
`data.sql` 파일 마지막에 각 테이블의 `auto_increment` 시작 값을 수동으로 재설정합니다.

```sql
-- data.sql 예시

-- ... (기존 데이터 삽입)

-- H2 AUTO_INCREMENT 시퀀스 초기화
ALTER TABLE users ALTER COLUMN id RESTART WITH 2;
ALTER TABLE groups ALTER COLUMN id RESTART WITH 14;
```

**적용 시점**: `data.sql`에 명시된 마지막 ID + 1로 설정

## 사용자 동시 생성 시 동시성 처리

### 문제 상황
여러 요청이 거의 동시에 같은 이메일로 사용자를 생성하려고 시도하면 `DataIntegrityViolationException`이 발생합니다 (unique 제약 위반).

### 해결책: findOrCreateUser 패턴
사용자 저장 로직을 `try-catch`로 감싸고, 예외 발생 시 해당 이메일로 재조회하여 반환합니다.

**구현 위치**: `UserService.ensureUserByEmail()`

**패턴**:
```kotlin
@Transactional
fun ensureUserByEmail(email: String): User {
    findByEmail(email)?.let { return it }
    val user = createNewUser(email)
    return try {
        userRepository.saveAndFlush(user)
    } catch (e: DataIntegrityViolationException) {
        findByEmail(email) ?: throw e
    }
}
```

**핵심 포인트**:
- `saveAndFlush()` 사용으로 즉시 DB 반영
- 예외 발생 시 재조회로 동시 생성 처리
- 재조회에도 없으면 예외 재발생

## 데이터 자동 초기화

### GroupInitializationRunner
기존 `data.sql`에 의존하던 복잡한 초기 데이터 생성 방식이 애플리케이션 시작 시 동적 생성으로 변경되었습니다.

**구현 위치**: `backend/src/main/kotlin/.../initialization/GroupInitializationRunner.kt`

**초기화 프로세스**:
1. 애플리케이션 시작 시 Runner 자동 실행
2. `defaultChannelsCreated == false`인 그룹 검색
3. 각 그룹에 대해:
   - 기본 역할 생성 (그룹장, 교수, 멤버)
   - 그룹 생성자를 그룹장으로 자동 추가
   - 기본 채널 생성 ('공지사항', '자유게시판')
   - 채널 권한 바인딩 생성
4. `defaultChannelsCreated = true` 업데이트 (중복 실행 방지)

**장점**:
- 모든 그룹이 동일한 구조의 기본 역할 및 채널 보유
- SQL이 아닌 Kotlin 코드로 중앙 관리 (수정 용이)
- `data.sql`의 복잡성 감소 (순수 데이터만 관리)

## 관련 문서
- [트랜잭션 패턴](./transaction-patterns.md) - 트랜잭션 관리
- [예외 처리](./exception-handling.md) - 예외 처리 전략
