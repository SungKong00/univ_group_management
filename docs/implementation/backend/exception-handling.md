# 예외 처리

## 개요
트랜잭션 롤백과 예외 처리 전략을 다룹니다.

## UnexpectedRollbackException 방지

### 문제 상황
Spring은 `@Transactional` 메서드 내에서 **RuntimeException** 발생 시 트랜잭션을 rollback-only로 마킹합니다.

**잘못된 패턴**: 내부 메서드에서 예외 발생 → 외부에서 `catch` → 커밋 시도 → `UnexpectedRollbackException`

**문제 원인**:
1. 내부 메서드 예외 발생 → 트랜잭션 rollback-only 마킹
2. 외부 `catch`로 예외를 잡아도 롤백 마킹 해제 안 됨
3. 커밋 시도 시 예외 발생

### 해결 방법 1: 사전 체크로 예외 방지 (권장)
- 예외 발생 가능성이 있는 작업 전에 조건 확인
- 예시: `groupMemberRepository.findByGroupIdAndUserId()` → 이미 멤버인지 사전 확인
- 예외 발생 최소화 → 트랜잭션 롤백 방지

### 해결 방법 2: REQUIRES_NEW로 트랜잭션 분리
자세한 내용은 [Best-Effort 패턴](./best-effort-pattern.md) 참조.

## noRollbackFor 사용 주의

### ⚠️ 주의사항
- `noRollbackFor`는 특정 예외 발생 시 롤백하지 않음
- **데이터 정합성 문제 발생 가능** (예외 발생해도 커밋)
- **비권장**: 명확한 이유 없으면 사용하지 말 것
- **권장 대안**: 사전 체크 또는 REQUIRES_NEW

## 예외 처리 전략

### Checked vs Unchecked Exception
| 종류 | 롤백 여부 | 사용 시나리오 |
|------|-----------|---------------|
| **Unchecked (RuntimeException)** | 자동 롤백 | 비즈니스 예외, 검증 실패 |
| **Checked (Exception)** | 롤백 안 함 | 외부 API 실패 (재시도 가능) |

**권장**: 비즈니스 예외는 RuntimeException 계열 사용

### DataIntegrityViolationException 처리
**패턴**: `saveAndFlush()` → `catch(DataIntegrityViolationException)` → 재조회
**사용 시나리오**: 동시 생성 시 unique 제약 위반 처리
**구현 위치**: `UserService.ensureUserByEmail()`

## 트랜잭션 롤백 조건

### 자동 롤백되는 경우
- `RuntimeException` 또는 그 하위 예외 발생
- `Error` 발생

### 롤백되지 않는 경우
- `Checked Exception` (Exception) 발생
- `noRollbackFor`에 지정된 예외 발생

## 로깅 전략

### 예외 로깅 권장 사항
**규칙**:
- 예상된 예외: `logger.warn()` - 스택 트레이스 포함
- 예상 못한 예외: `logger.error()` - 스택 트레이스 포함 + 재발생

## 관련 문서
- [Best-Effort 패턴](./best-effort-pattern.md) - REQUIRES_NEW 사용법
- [트랜잭션 패턴](./transaction-patterns.md) - 기본 트랜잭션 패턴
- [개발 환경 설정](./development-setup.md) - 동시성 처리
