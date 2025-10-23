# 트랜잭션 패턴

## 개요
Spring 트랜잭션 관리의 기본 패턴 및 전파 레벨을 다룹니다.

## 기본 트랜잭션 패턴

### 클래스 레벨 설정
```kotlin
@Service
@Transactional(readOnly = true)  // 기본: 읽기 전용
class UserService(...) {

    @Transactional  // 메서드 레벨: 읽기/쓰기
    fun createUser(request: CreateUserRequest): User {
        // 사용자 생성 로직
    }
}
```

**규칙**:
- 클래스 레벨: `@Transactional(readOnly = true)` (조회 메서드용)
- 메서드 레벨: `@Transactional` (CUD 작업용, readOnly 오버라이드)

## 트랜잭션 전파 레벨 (Propagation)

Spring의 트랜잭션 전파 레벨은 기존 트랜잭션이 있을 때 새 메서드가 어떻게 동작할지를 정의합니다.

### 5가지 주요 전파 레벨

| 전파 레벨 | 설명 | 사용 시나리오 |
|-----------|------|---------------|
| **REQUIRED** (기본) | 기존 트랜잭션이 있으면 참여, 없으면 새로 생성 | 일반적인 비즈니스 로직 |
| **REQUIRES_NEW** | 항상 새로운 트랜잭션 생성, 기존 트랜잭션은 일시 중단 | Best-effort 작업, 감사 로그 |
| **NESTED** | 기존 트랜잭션 내에 중첩 트랜잭션 생성 (Savepoint 사용) | 부분 롤백이 필요한 경우 |
| **SUPPORTS** | 기존 트랜잭션이 있으면 참여, 없어도 트랜잭션 없이 실행 | 읽기 전용 조회 |
| **NOT_SUPPORTED** | 트랜잭션 없이 실행 (기존 트랜잭션 일시 중단) | 트랜잭션이 필요 없는 작업 |

### REQUIRED (기본)
**사용 예시**: 일반적인 비즈니스 로직

```kotlin
@Transactional
fun createGroup(...): Group {
    val group = groupRepository.save(Group(...))
    workspaceService.createDefaultWorkspace(group.id)
    return group
}
```

**특징**: 외부 트랜잭션과 내부 트랜잭션이 하나의 트랜잭션으로 묶임 (하나라도 실패 시 전체 롤백)

### REQUIRES_NEW
**사용 예시**: 외부 트랜잭션과 독립적으로 실행해야 하는 작업

자세한 내용은 [Best-Effort 패턴](./best-effort-pattern.md) 참조.

## 트랜잭션 디버깅

### 로그 설정
```yaml
# application-dev.yml
logging:
  level:
    org.springframework.transaction: DEBUG
    org.springframework.orm.jpa: DEBUG
```

**로그 예시**:
```
DEBUG o.s.t.s.TransactionAspectSupport: Creating new transaction with name [UserService.createUser]
DEBUG o.s.t.s.TransactionAspectSupport: Completing transaction for [UserService.createUser]
```

## 관련 문서
- [Best-Effort 패턴](./best-effort-pattern.md) - REQUIRES_NEW 사용법
- [예외 처리](./exception-handling.md) - 트랜잭션 롤백 처리
- [개발 환경 설정](./development-setup.md) - 동시성 처리
