# 채널 권한 관리 (Channel Permissions)

## 개념 설명

채널 접근/활동 통제는 **권한별 허용 역할 목록(Permission-Centric)**. 
- 기본 초기 2채널(공지사항, 자유게시판)은 그룹 생성 시 템플릿 권한 바인딩(그룹장/교수/멤버) 자동 부여.
- 그 이후 생성되는 모든 **사용자 정의 채널은 권한 바인딩 0개** 로 시작하고, 운영자가 설정 화면에서 매트릭스를 수동 구성.

## 권한 목록 (ChannelPermission)

| 권한 | 의미 |
|------|------|
| CHANNEL_VIEW | 채널 목록/존재 확인 |
| POST_READ | 게시글/댓글 읽기 |
| POST_WRITE | 게시글 작성 |
| COMMENT_WRITE | 댓글 작성 |
| FILE_UPLOAD | 파일 첨부 |

## 기본 초기 채널 템플릿
| 채널 | 역할 | 권한 |
|------|------|------|
| 공지(ANNOUNCEMENT) | 그룹장/교수 | VIEW, READ, WRITE, COMMENT, FILE |
| 공지(ANNOUNCEMENT) | 멤버 | VIEW, READ, COMMENT |
| 자유(TEXT) | 그룹장/교수 | VIEW, READ, WRITE, COMMENT, FILE |
| 자유(TEXT) | 멤버 | VIEW, READ, WRITE, COMMENT |

> 초기 2채널 템플릿은 운영 정책상 최소 커뮤니케이션 기능을 즉시 제공하기 위한 것. 삭제 후 재생성하면 사용자 정의 채널 규칙(0개 시작) 적용.

## 사용자 정의 채널 초기 상태
| 항목 | 값 |
|------|----|
| 초기 바인딩 수 | 0개 |
| 채널 목록 노출 | CHANNEL_VIEW 권한 부여 후 |
| 읽기 가능 | POST_READ 부여 후 |
| 쓰기 가능 | POST_WRITE 부여 후 |
| 댓글 가능 | COMMENT_WRITE 부여 후 |
| 파일 업로드 | FILE_UPLOAD 부여 후 |

## 권한 편집 매트릭스 (Permission-Centric)
| 권한 ↓ / 역할 → | 그룹장 | 교수 | 멤버 | (예: MODERATOR) |
|-----------------|-------|---------|--------|----------------|
| CHANNEL_VIEW | ✔ | ✔ | (선택) | (옵션) |
| POST_READ | ✔ | ✔ | (선택) | (옵션) |
| POST_WRITE | ✔ | ✔ | (선택) | (옵션) |
| COMMENT_WRITE | ✔ | ✔ | (선택) | (옵션) |
| FILE_UPLOAD | ✔ | ✔ | (옵션) | (옵션) |

> 사용자 정의 채널은 모든 행이 비어있는 상태로 시작. UI는 ‘필수: CHANNEL_VIEW 최소 1개 역할’ 검증.

## 검증 권장 규칙
- POST_WRITE ⊆ POST_READ ⊆ CHANNEL_VIEW
- COMMENT_WRITE ⊆ POST_READ
- FILE_UPLOAD ⊆ POST_WRITE (정책, 완화 가능)

## 운영 절차 (사용자 정의 채널)
1. 채널 생성 직후 → 권한 매트릭스 진입 안내 (배너)
2. CHANNEL_VIEW → 그룹장/교수 선택
3. POST_READ → 멤버 포함 여부 결정
4. POST_WRITE / COMMENT_WRITE → 필요 역할 선택
5. FILE_UPLOAD → 최소화 (대역폭/보안)
6. 저장 → ChannelRoleBinding 생성/갱신

## 권한 관리 UI (Permission Management UI)

채널 권한은 `그룹 관리 > 채널 관리` 페이지에서 설정할 수 있습니다. (`CHANNEL_MANAGE` 그룹 권한 필요)

- **페이지 구조**: 채널 목록이 먼저 표시되고, 특정 채널을 선택하면 해당 채널의 권한 매트릭스가 나타납니다.
- **권한 매트릭스**: 각 역할(가로축)과 권한(세로축)이 교차하는 지점에 체크박스가 있어, 관리자는 직관적으로 역할에 권한을 부여하거나 해제할 수 있습니다.
- **저장**: 변경 사항을 저장하면 `PUT /channels/{channelId}/role-bindings/{bindingId}` 또는 `DELETE /channels/{channelId}/role-bindings/{bindingId}` API가 호출되어 서버에 반영됩니다.

## 캐시 연관
권한 변경 시 PermissionService.invalidateGroup(groupId) 호출 (캐시 적용 시).

## 정책 변경 이력
| 날짜 | 내용 |
|------|------|
| 2025-10-01 rev1~3 | 모든 신규 채널 0바인딩 실험 문서화 (템플릿 고려 전) |
| 2025-10-01 rev4 | 모든 신규 채널 자동 템플릿 (폐기됨) |
| 2025-10-01 rev5 | 하이브리드 확정: 초기 2채널 템플릿 + 사용자 정의 채널 0바인딩 |

## 관련 구현
- ChannelInitializationService (초기 2채널 템플릿 생성)
- ContentService.createChannel (0바인딩 생성 정책)

## 관련 문서
- permission-system.md
- ui-ux/pages/channel-pages.md
- troubleshooting/permission-errors.md
