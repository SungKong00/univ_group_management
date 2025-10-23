# 인증 (Authentication)

## 개요
JWT 토큰 기반 인증 및 권한 체크 시스템을 다룹니다.

## JWT 토큰 처리

### JwtAuthenticationFilter
**역할**: 요청 헤더에서 JWT 토큰 추출 및 검증

**구현 위치**: `backend/src/main/kotlin/.../security/JwtAuthenticationFilter.kt`

**동작 흐름**:
1. HTTP 요청 헤더에서 `Authorization: Bearer {token}` 추출
2. 토큰 유효성 검증 (서명, 만료 시간)
3. 토큰에서 사용자 정보 추출
4. `SecurityContextHolder`에 인증 정보 저장
5. 다음 필터로 요청 전달

**패턴**: `OncePerRequestFilter` 상속으로 요청당 1회만 실행

## 권한 체크 서비스

### GroupPermissionEvaluator
**역할**: `@PreAuthorize` 어노테이션과 연동하여 권한 검증

**구현 위치**: `backend/src/main/kotlin/.../security/GroupPermissionEvaluator.kt`

**주요 메서드**: `hasPermission(authentication, targetId, targetType, permission)`

**검증 흐름**:
1. 글로벌 ADMIN 체크 (모든 권한 통과)
2. 사용자 이메일로 User 엔티티 조회
3. 대상 타입별 권한 검증 라우팅:
   - `GROUP`: 그룹 권한 체크
   - `CHANNEL`: 채널 권한 체크
   - `RECRUITMENT`: 모집 권한 체크
   - `APPLICATION`: 지원서 권한 체크
4. 권한 있음 → `true`, 없음 → `false` 반환

**@PreAuthorize 사용법**:
```kotlin
@PreAuthorize("@security.hasGroupPerm(#groupId, 'GROUP_EDIT')")
fun updateGroup(@PathVariable groupId: Long, ...): ResponseEntity<*> {
    // 권한 검증 통과 시 실행
}
```

**파라미터 설명**:
- `@security`: Spring Bean 이름 (GroupPermissionEvaluator)
- `#groupId`: SpEL 표현식으로 메서드 파라미터 참조
- `'GROUP_EDIT'`: 권한 문자열

## 채널 권한 검증 예시

**메서드**: `checkChannelPermission(channelId, userId, permission)`

**단계**:
1. 채널 조회
2. 그룹 멤버십 확인 (해당 채널의 그룹 멤버인지)
3. 채널-역할 바인딩 조회 (캐시 우선)
4. 요청한 권한이 바인딩에 포함되어 있는지 확인
5. 결과 반환 (true/false)

**캐시 활용**: `ChannelPermissionCacheManager`를 통해 반복 조회 최소화

## 관련 문서
- [권한 검증](./permission-checking.md) - 권한 검증 로직 상세
- [권한 시스템](../../concepts/permission-system.md) - 권한 시스템 개념
