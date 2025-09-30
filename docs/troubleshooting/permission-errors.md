# 권한 에러 해결 가이드 (Permission Error Troubleshooting)

## 공통 에러 응답 구조
```json
{
  "success": false,
  "error": { "code": "FORBIDDEN", "message": "접근 권한이 없습니다." },
  "timestamp": "2025-10-01T12:34:56"
}
```

## 주요 에러 코드 요약
| 코드 | HTTP | 의미 | 대표 원인 |
|------|------|------|-----------|
| UNAUTHORIZED | 401 | 인증 필요 | 미로그인, SecurityContext 없음 |
| INVALID_TOKEN | 401 | 토큰 위변조/형식 오류 | 잘못된 서명, Bearer 누락 |
| EXPIRED_TOKEN | 401 | 토큰 만료 | Access Token 만료, 재발급 필요 |
| FORBIDDEN | 403 | 권한 부족 | 역할에 필요한 권한 미보유 |
| SYSTEM_ROLE_IMMUTABLE | 403 | 시스템 역할 변경 금지 | OWNER / ADVISOR / MEMBER 수정·삭제 시도 |
| GROUP_ROLE_NAME_ALREADY_EXISTS | 409 | 역할명 중복 | 동일 이름 역할 생성/변경 |
| GROUP_ROLE_NOT_FOUND | 404 | 역할 없음 | 잘못된 roleId |
| GROUP_MEMBER_NOT_FOUND | 404 | 멤버 아님 | 그룹 비회원 접근 |

## 1. 401 계열 (인증 관련)
### (A) INVALID_TOKEN
```http
HTTP/1.1 401 Unauthorized
{
  "success": false,
  "error": { "code": "INVALID_TOKEN", "message": "유효하지 않은 토큰입니다." }
}
```
확인 체크리스트:
- Authorization 헤더 존재 여부: `Bearer <JWT>` 형식인가?
- 토큰 서명 키/환경 변수 일치 여부
- 토큰 앞뒤 공백 / 개행 문자 포함 여부

조치:
- 재로그인 유도
- 자동 재시도 금지 (무한 루프 방지)

### (B) EXPIRED_TOKEN
```http
HTTP/1.1 401 Unauthorized
{
  "success": false,
  "error": { "code": "EXPIRED_TOKEN", "message": "만료된 토큰입니다." }
}
```
조치 흐름 (프론트):
1. 만료 감지 → refresh endpoint 호출(`/api/auth/refresh`)
2. 새 accessToken 로 재시도 (1회)
3. 다시 실패 → 강제 로그아웃 → 로그인 화면 이동

### (C) UNAUTHORIZED (컨텍스트 없음)
- SecurityContext 미설정 / 쿠키·헤더 누락
- 백엔드 로그: `No authentication found in security context`

## 2. 403 계열 (권한 부족 / 정책 위반)
### (A) FORBIDDEN
```http
HTTP/1.1 403 Forbidden
{
  "success": false,
  "error": { "code": "FORBIDDEN", "message": "접근 권한이 없습니다." }
}
```
체크리스트:
- 사용자가 해당 그룹 멤버인가?
- 역할에 필요한 GroupPermission 혹은 ChannelPermission 포함?
- 캐시 무효화 누락? (역할 수정 직후 invalidate 호출 여부)

### (B) SYSTEM_ROLE_IMMUTABLE
시스템 역할(OWNER/ADVISOR/MEMBER) 이름/우선순위/권한 변경, 삭제 시도.
```http
HTTP/1.1 403 Forbidden
{
  "success": false,
  "error": { "code": "SYSTEM_ROLE_IMMUTABLE", "message": "시스템 역할은 변경하거나 삭제할 수 없습니다." }
}
```
원인: 클라이언트가 시스템 역할을 편집 가능한 일반 역할로 취급.
해결: UI에서 시스템 역할 편집/삭제 버튼 비노출.

## 3. 역할/권한 디버깅 절차
1. 그룹 멤버십 재확인
2. 역할이 시스템 역할인지 구분 (불변 처리)
3. PermissionService 캐시 무효화 호출 여부(역할/바인딩 갱신 후)
4. (변경됨 2025-10-01) 채널 접근 불가 시: 해당 채널에 필요한 ChannelRoleBinding 이 정의되어 있는지 확인 (자동 기본 바인딩 없음 → 존재하지 않으면 View/Read/Write 모두 불가)
   - 기대: 최소 1개 이상 (예: Owner 역할 can_view=true) 
   - 없을 경우: UI 권한 매트릭스 저장 누락 또는 권한 초기화 로직 미호출

## 4. 빠른 JPA/캐시 점검 코드 스니펫
```kotlin
val member = groupMemberRepository.findByGroupIdAndUserId(groupId, userId).orElse(null)
log.debug("memberRole={}, permissions={}", member?.role?.name, member?.role?.permissions)
```

## 5. 프론트엔드 처리 패턴 (Flutter 예시)
```dart
if (error.code == 'EXPIRED_TOKEN') {
  final refreshed = await authRepository.tryRefresh();
  if (refreshed) return retry();
  forceLogout();
} else if (error.code == 'SYSTEM_ROLE_IMMUTABLE') {
  showToast('시스템 역할은 수정할 수 없습니다');
}
```

## 6. 자주 하는 실수 요약
| 실수 | 증상 | 해결 |
|------|------|------|
| 시스템 역할 편집 UI 노출 | 403 SYSTEM_ROLE_IMMUTABLE | 시스템 역할 필터링 후 UI 숨김 |
| 캐시 무효화 누락 | 권한 변경 즉시 반영 안 됨 | 역할/바인딩 변경 후 invalidateGroup 호출 |
| ChannelRoleBinding 미설정 | 채널 목록/게시글 전부 미노출 | 권한 매트릭스 저장 후 최소 VIEW 권한 부여 |
| Bearer 접두사 누락 | INVALID_TOKEN | 헤더 형식 강제 (`Bearer `) |
| 만료 토큰 반복 호출 | 연속 401 → 무한 요청 | 1회 refresh 후 실패 시 로그아웃 |

## 7. 관련 문서
- 개념: `../concepts/permission-system.md`
- 채널 권한: `../concepts/channel-permissions.md`
- 워크스페이스/채널: `../concepts/workspace-channel.md`
