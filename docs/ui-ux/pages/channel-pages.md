# UI/UX 명세서: 채널 페이지

본 문서는 워크스페이스의 핵심 소통 공간인 채널의 생성, 탐색, 상호작용 및 권한 구성(Permission-Centric 매트릭스)을 정의합니다.

## 1. 기본 채널 정책 (정책 복원)
- 워크스페이스(=그룹) 생성 시 **기본 2개 채널** 자동 생성:
  1) 공지사항 (ANNOUNCEMENT)  2) 자유게시판 (TEXT)
- 기본 권한 바인딩도 함께 자동 생성 (서비스 레벨 ChannelInitializationService):
  - 공지사항: OWNER/ADVISOR = VIEW/READ/WRITE/COMMENT/FILE, MEMBER = VIEW/READ/COMMENT
  - 자유게시판: OWNER/ADVISOR = 모든 권한, MEMBER = VIEW/READ/WRITE/COMMENT
- 필요 없으면 채널 설정 > 삭제(Danger Zone)로 제거 가능

### 1.1 빈 상태(Empty State) UI
| 조건 | 표시 UI |
|------|---------|
| 채널 0개 (예: 관리자가 둘 다 삭제) & 생성 권한 있음 | "채널을 생성하여 협업을 시작하세요" + [채널 만들기] 버튼 + 권한 설정 안내 링크 |
| 채널 0개 & 생성 권한 없음 | "아직 공개된 채널이 없습니다. 권한자에게 문의하세요." |

## 2. 채널 생성 플로우

### 2.1 진입 트리거
- 채널 목록 상단/하단 [채널 만들기]
- 권한: CHANNEL_MANAGE 또는 시스템 OWNER/ADVISOR

### 2.2 생성 모달 (단일 단계)
필드:
1. 채널 이름 (필수 2~30자)
2. 설명 (선택 0~200자)
3. 타입 (TEXT / ANNOUNCEMENT / FILE_SHARE)
버튼: [생성] / [취소]

### 2.3 기본 권한 자동 부여 (코드 구현 반영)
- 생성 직후 서비스(ContentService.setupDefaultChannelPermissions)에서 OWNER/ADVISOR 풀세트, MEMBER 는 일반 텍스트 채널: VIEW/READ/WRITE/COMMENT, 공지 채널: VIEW/READ/COMMENT 로 자동 ChannelRoleBinding 저장.
- UI 는 생성 완료 토스트 + 바로 채널로 이동.
- 운영자는 필요 시 권한 탭에서 수정.

> 이전 문서 개정안(바인딩 0개 → 위저드 필수) 폐기. 실제 구현은 자동 템플릿 방식.

## 3. 권한 편집 (Permission-Centric 매트릭스)
- 행: CHANNEL_VIEW, POST_READ, POST_WRITE, COMMENT_WRITE, FILE_UPLOAD
- 열: 역할 (동적)
- 검증 규칙:
  - POST_WRITE ⊆ POST_READ ⊆ CHANNEL_VIEW
  - COMMENT_WRITE ⊆ POST_READ
  - FILE_UPLOAD ⊆ POST_WRITE (현 정책)
- 템플릿 빠른 적용 옵션(공지형/토론형/운영전용) 제공 (미구현 시 회색 처리)

## 4. 채널 메인 뷰

### 4.1 헤더
- 좌측: `#` + 채널 이름, 아래 설명 (툴팁: 전체 표시)
- 우측: [권한 관리] (⚙️) 버튼 (can_manage=true 또는 CHANNEL_MANAGE 보유자만)

### 4.2 콘텐츠 영역
상태별:
| 상태 | UI |
|------|----|
| 게시글 없음 + 읽기 권한 있음 | Empty 메시지 + "첫 글을 작성해보세요" (쓰기 권한 존재 시 버튼) |
| 읽기 권한 없음 | 중앙 정렬 안내: "이 채널을 볼 권한이 없습니다" + 권한 요청 안내 |
| 쓰기 권한 없음 | 입력창 disabled, placeholder: "쓰기 권한이 없습니다" |

### 4.3 입력창 권한 처리
- POST_WRITE 권한 보유 → 활성
- COMMENT_WRITE 권한만 보유 & 글 작성 권한 없음 → 댓글만 가능 (게시글 상세에서)
- 파일 첨부 버튼은 FILE_UPLOAD 권한자만 표시/활성

## 5. 에러 & 피드백 패턴
| 상황 | 메시지 | 처리 |
|------|--------|------|
| 권한 저장 시 검증 실패 | "POST_WRITE 권한은 읽기 권한 역할에만 부여할 수 있습니다" | 행 강조 + 툴팁 |
| 저장 중 네트워크 오류 | "권한 저장에 실패했습니다. 다시 시도하세요" | 재시도 버튼 |
| 채널 접근 403 | "채널 권한이 제거되었을 수 있습니다" | 뒤로가기 + 새로고침 CTA |

## 6. 접근성 고려
- 매트릭스: 키보드 Tab 순서 행 우선 → Space/Enter 토글
- 역할 태그: aria-pressed 속성 활용
- 오류 표시: role=alert

## 7. 상태 다이어그램 (요약)
```
그룹 생성 → (기본 2채널 + 기본 권한) → 활성
사용자 생성 채널 → (자동 기본 권한) → 활성 → (권한 편집 선택)
활성 → 보관 → 복원/삭제
```
## 8. 관련 문서
- 개념: ../../concepts/channel-permissions.md
- 권한 시스템: ../../concepts/permission-system.md
- 워크스페이스: ../../concepts/workspace-channel.md
- 트러블슈팅: ../../troubleshooting/permission-errors.md
