# Best-Effort 패턴

## 개요
메인 작업은 반드시 성공하되, 부가 작업은 실패해도 메인 작업에 영향을 주지 않는 패턴입니다.
`REQUIRES_NEW` 전파 레벨을 사용하여 트랜잭션을 완전히 분리합니다.

## 문제 상황

### 케이스: 사용자 생성 + 자동 그룹 가입
- **메인 작업**: 사용자 프로필 업데이트 (반드시 성공)
- **부가 작업**: 자동 그룹 가입 (실패해도 사용자 생성은 성공해야 함)

**문제**: 자동 그룹 가입 중 예외 발생 시, 메인 트랜잭션도 롤백됨

## 해결책: REQUIRES_NEW 사용

### 방법 1: 사전 체크로 예외 방지 (권장)

**구현 위치**: `UserService.submitSignupProfile()`

**핵심 로직**:
1. 메인 작업: 사용자 프로필 업데이트 (`userRepository.save()`)
2. Best-effort: `autoJoinGroups()` 호출
3. 사전 체크: `groupMemberRepository.findByGroupIdAndUserId()` → 이미 멤버인지 확인
4. 예외 안전: `runCatching { joinGroup() }.onFailure { logger.warn() }`
5. 예외를 다시 던지지 않음 (Best-effort)

**핵심 포인트**:
- 사전에 멤버십 존재 여부 확인으로 예외 발생 가능성 최소화
- `runCatching`으로 예외 안전 처리
- 외부 트랜잭션에 영향 없음

### 방법 2: 별도 트랜잭션으로 완전 분리

**핵심 패턴**:
- 외부 메서드: `@Transactional` - 메인 작업 실행
- 내부 메서드: `@Transactional(propagation = Propagation.REQUIRES_NEW)` - 별도 트랜잭션
- 접근 제한자: `protected open` (Spring AOP 프록시 필수)

**동작**: 내부 메서드가 새로운 트랜잭션을 생성하고 독립적으로 커밋/롤백. 실패해도 외부 트랜잭션에 영향 없음.

## 주의사항

### 1. 메서드 접근 제한자
- ❌ `private` 메서드: 프록시 적용 안 됨 (트랜잭션 무시)
- ✅ `protected open` 메서드: 프록시 적용 가능 (트랜잭션 동작)
- **이유**: Spring AOP는 프록시 기반

### 2. 별도 서비스 분리 (대안)
- 별도 Service 클래스 생성 (`AuditLogService`)
- 해당 클래스의 메서드에 `@Transactional(propagation = Propagation.REQUIRES_NEW)` 적용
- **장점**: 접근 제한자 불필요, 책임 분리 명확

## 사용 시나리오

### 1. 자동 가입
사용자 회원가입 시 특정 그룹에 자동 가입 시도 (실패해도 회원가입은 성공)

### 2. 감사 로그
비즈니스 작업 후 로그 저장 (로그 저장 실패해도 비즈니스 작업은 성공)

### 3. 알림 전송
작업 완료 후 알림 전송 (알림 실패해도 작업은 완료)

## 관련 문서
- [트랜잭션 패턴](./transaction-patterns.md) - 기본 트랜잭션 패턴
- [예외 처리](./exception-handling.md) - 예외 처리 전략
