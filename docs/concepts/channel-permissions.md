# 채널 권한 관리 (Channel Permissions)

## 개념 설명

채널 접근/활동 통제는 **권한별 허용 역할 목록(Permission-Centric)** 으로 구성한다. 새 채널 생성 시 자동 바인딩 없음 → 어떤 역할도 보기/읽기/쓰기 불가.

## 권한 목록 (ChannelPermission)

| 권한            | 의미                   |
|-----------------|------------------------|
| CHANNEL_VIEW    | 채널 목록/존재 확인   |
| POST_READ       | 게시글/댓글 읽기      |
| POST_WRITE      | 게시글 작성            |
| COMMENT_WRITE   | 댓글 작성              |
| FILE_UPLOAD     | 파일 첨부              |

## 초기 상태

| 항목               | 값                     |
|--------------------|------------------------|
| 생성 직후 바인딩    | 0개                    |
| Owner 가시성       | CHANNEL_VIEW 매핑 전 없음 |
| Member 읽기        | POST_READ 매핑 전 없음    |
| 네비게이션 노출    | CHANNEL_VIEW 매핑 후      |

## 설정 절차 예시

1. CHANNEL_VIEW → OWNER, MEMBER
2. POST_READ → OWNER, MEMBER
3. POST_WRITE / COMMENT_WRITE → OWNER (필요 시 MODERATOR 등 추가)
4. FILE_UPLOAD → OWNER (선택)
5. 저장 시 (channel, role) 바인딩 생성/갱신

## 매트릭스 예시

| 권한 ↓ / 역할 →    | OWNER | MEMBER | MODERATOR |
|-----------------|-------|--------|-----------|
| CHANNEL_VIEW    | ✔     | ✔      | ✔ (옵션)   |
| POST_READ       | ✔     | ✔      | ✔         |
| POST_WRITE      | ✔     |        | ✔ (옵션)   |
| COMMENT_WRITE   | ✔     |        | ✔ (옵션)   |
| FILE_UPLOAD     | ✔     |        | ✔ (옵션)   |

> UI 사고방식: "역할별 권한 나열" 이 아니라 "각 권한에 허용할 역할을 체크".

## 비즈니스 규칙

*   자동 기본 권한 부여 없음
*   Owner 도 명시적 매핑 없으면 읽기 불가
*   권한 해제 시 해당 역할 즉시 접근 상실 (캐시 무효화 필수)

## 캐시 연관

권한 매핑 변경 → PermissionService.invalidateGroup(groupId) 호출 필요 (권한 캐시 갱신).

## 사용 예시

*   공지 채널: VIEW/READ → 전원, WRITE → OWNER
*   전용 운영 채널: 모든 권한 → OWNER, MODERATOR

## 관련 구현

*   [권한 시스템](permission-system.md#채널-권한-바인딩-기본값)
*   [트러블슈팅](../troubleshooting/permission-errors.md)
