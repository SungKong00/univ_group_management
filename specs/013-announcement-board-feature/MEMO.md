# 공지 관리 기능 - 개발 MEMO

**프로젝트**: 대학 그룹 관리 시스템
**이슈 번호**: #13
**브랜치**: 013-announcement-board-feature
**기반**: develop 브랜치
**작성일**: 2025-11-17

---

## 📋 기능 개요

사용자가 멤버인 그룹의 공지 사항을 작성, 조회, 검색, 필터링할 수 있는 통합 공지 관리 기능

**주요 특징**:
- 다중 그룹 공지 통합 관리
- 공동 관리자 글 통합 조회
- 실시간 검색 및 다각도 필터링
- 최근 활동 추적

---

## ✅ 확정된 설계

### 검색 및 필터링
- **검색 범위**: 제목 + 내용 + 작성자명 전체 검색
- **페이지네이션**: 무한 스크롤 방식
- **필터 옵션**:
  - 그룹별 필터: 특정 그룹의 공지만 보기
  - 날짜 필터: 오늘 / 이번 주 / 이번 달 / 전체
- **정렬**: 최신순 (기본값) / 오래된순

### 핵심 권한 로직

#### 공지 관리 버튼 표시 조건
```
현재 그룹의 공지 채널(type='ANNOUNCEMENT')에 POST_WRITE 권한 보유 시
→ [+ 공지 추가] 버튼 표시
```

#### 공지 작성 가능 그룹 조회
```
사용자가 멤버인 모든 그룹 중
→ 각 그룹의 공지 채널에 POST_WRITE 권한 있는 그룹만 표시
```

#### 공지 조회 범위 (공동 관리자 포함)
```
내가 볼 수 있는 공지:
├─ 내가 작성한 공지
└─ 같은 채널에 POST_WRITE 권한 보유한 다른 사용자의 공지
```

#### 최근 활동 (Recent Activities)
```
내가 조회 가능한 공지에 대한 활동:
├─ 댓글 추가
├─ 나의 공지 작성/수정
└─ 공동 관리자의 공지 작성/수정
```

---

## 🎯 구현 계획 (5 Phase)

### Phase 1: 백엔드 API 구현

**담당**: backend-architect
**상태**: 대기 중

#### 1.1 API 엔드포인트 설계

- [ ] **GET /api/users/me/announcement-groups**
  - 목적: 사용자가 공지를 작성할 수 있는 그룹 조회
  - 응답: `ApiResponse<List<GroupDto>>` (각 그룹별 공지 채널 정보 포함)
  - 필터링: POST_WRITE 권한이 있는 그룹만 반환

- [ ] **GET /api/groups/{id}/channels/{channelId}/announcements**
  - 목적: 공지 목록 조회 (공동 관리자 글 포함)
  - 쿼리 파라미터:
    - `page` (번호)
    - `search` (제목 + 내용 + 작성자명)
    - `dateFilter` (today / week / month / all)
    - `sortBy` (latest / oldest)
  - 응답: `ApiResponse<Page<AnnouncementPostDto>>`
  - 권한: 해당 채널에 대한 읽기 권한 필요

- [ ] **GET /api/users/me/announcement-activities**
  - 목적: 사용자의 최근 활동 조회
  - 쿼리 파라미터: `limit` (기본값: 10)
  - 응답: `ApiResponse<List<ActivityDto>>`
  - 범위: 내가 조회 가능한 공지에 대한 모든 활동

- [ ] **POST /api/groups/{id}/channels/{channelId}/posts**
  - 목적: 공지 작성 (기존 API 활용 또는 새 엔드포인트)
  - 요청: `CreatePostRequest` (제목, 내용, 태그 등)
  - 응답: `ApiResponse<PostDto>`

#### 1.2 권한 검증 로직

- [ ] POST_WRITE 권한 확인 로직
  - 요청 사용자가 해당 채널에 POST_WRITE 권한 보유 여부 검증
  - 기존 권한 시스템 활용

- [ ] 공동 관리자 판별 로직
  - 같은 채널에 POST_WRITE 권한 보유한 사용자 조회
  - 특정 채널 내 모든 POST_WRITE 사용자 목록 반환

#### 1.3 데이터베이스 쿼리 최적화

- [ ] N+1 문제 방지
  - fetch join 활용 (Group -> Channel -> Post 조인)
  - Comment 조회 시 필요한 필드만 선택적 로드

- [ ] 인덱스 설계
  - (channel_id, created_at) 복합 인덱스
  - (group_id, channel_type) 인덱스
  - (user_id, created_at) 인덱스

#### 1.4 응답 데이터 형식 정의

```
AnnouncementPostDto {
  id: Long
  title: String
  content: String
  author: UserDto (id, name, email)
  groupId: Long
  groupName: String
  channelId: Long
  createdAt: LocalDateTime
  updatedAt: LocalDateTime
  isManageableByMe: Boolean (수정/삭제 가능 여부)
  commentCount: Int
}

ActivityDto {
  id: Long
  type: String (ANNOUNCEMENT_CREATED / COMMENT_ADDED)
  title: String
  author: UserDto
  createdAt: LocalDateTime
  groupName: String
  targetId: Long (Post ID 또는 Comment ID)
}
```

---

### Phase 2: 프론트엔드 UI 구현

**담당**: frontend-specialist
**상태**: 대기 중

#### 2.1 페이지 구조 설계

- [ ] **AnnouncementManagementPage** 생성
  - 페이지 헤더 (제목 + 부제목 + 안내 문구)
  - 그룹별 공지 리스트 (ExpansionTile 또는 유사 구조)
  - 최근 활동 영역 (사이드바 또는 우측 패널)

#### 2.2 컴포넌트 분리 계획

- [ ] **AnnouncementManagementHeader**
  - 페이지 제목: "공지 관리"
  - 부제목: "그룹별 공지를 한 곳에서 관리하세요"
  - [+ 공지 추가] 버튼 (권한이 있는 경우만)

- [ ] **AnnouncementToolbar**
  - 검색창 (실시간 검색)
  - 필터 드롭다운 (그룹, 날짜)
  - 정렬 옵션 (최신순 / 오래된순)

- [ ] **AnnouncementGroupSection**
  - ExpansionTile 스타일 그룹 섹션
  - 그룹 이름 + 공지 개수 표시
  - 그룹별 공지 카드 리스트
  - 무한 스크롤 연동

- [ ] **AnnouncementCard**
  - 공지 제목 (클릭 시 상세 다이얼로그)
  - 작성자 정보 + 작성 일시
  - 댓글 개수
  - 관리 아이콘 (수정/삭제 - 권한 있을 시만)

- [ ] **RecentActivitySidebar**
  - 최근 활동 리스트 (시간 역순)
  - 활동 유형별 아이콘 (공지 작성 / 댓글)
  - 활동 클릭 → 해당 공지 상세 다이얼로그 열기

#### 2.3 다이얼로그 구현

- [ ] **CreateAnnouncementDialog**
  - 그룹 선택 드롭다운 (작성 가능한 그룹만)
  - 제목 입력
  - 내용 입력 (RichTextEditor 또는 markdown)
  - 태그 입력 (옵션)
  - [작성] / [취소] 버튼

- [ ] **AnnouncementDetailDialog**
  - 공지 전체 내용 표시
  - 댓글 목록 (무한 스크롤)
  - 댓글 작성 입력란
  - 관리 버튼 (수정 / 삭제 - 권한 있을 시만)

- [ ] **DeleteConfirmationDialog** (2단계 확인)
  - 1단계: "삭제하시겠습니까?" 확인
  - 2단계: "정말 삭제하시겠습니까?" 최종 확인
  - 삭제 정책: 완전 삭제 (즉시, 복구 불가)

#### 2.4 레이아웃 및 반응형 디자인

- [ ] 데스크톱 레이아웃
  - 좌측: 공지 리스트 (70%)
  - 우측: 최근 활동 사이드바 (30%)

- [ ] 모바일 레이아웃
  - 전체 너비: 공지 리스트
  - 최근 활동: 탭 또는 접기식 섹션

---

### Phase 3: 상태 관리 및 API 연동

**담당**: api-integrator / state-management-specialist
**상태**: 대기 중

#### 3.1 Provider 구현

- [ ] **announcementGroupsProvider**
  - 작성 가능한 그룹 목록 조회
  - 캐싱: 5분 또는 수동 새로고침
  - 의존성: currentGroupProvider (선택한 그룹 필터링)

- [ ] **announcementPostsProvider**
  - 공지 게시글 목록 조회
  - 파라미터: groupId, search, dateFilter, sortBy, page
  - 무한 스크롤 지원 (페이지 증가 시 append)
  - 로딩/에러 상태 관리

- [ ] **recentActivitiesProvider**
  - 최근 활동 목록 조회
  - 캐싱: 자동 새로고침 (10초 간격)
  - 부모: announcementPostsProvider (새 공지 감지)

- [ ] **hasAnnouncementWritePermissionProvider**
  - 현재 그룹에서 공지 작성 가능 여부
  - 의존성: currentGroupProvider, currentUserProvider

- [ ] **announcementDetailProvider**
  - 특정 공지 상세 정보 조회
  - 파라미터: postId
  - 댓글 목록 포함

#### 3.2 API 클라이언트

- [ ] **AnnouncementApiClient** 클래스 생성
  - fetchAnnouncementGroups()
  - fetchAnnouncements(groupId, filter, search, page)
  - fetchActivities()
  - fetchAnnouncementDetail(postId)
  - createAnnouncement(request)
  - updateAnnouncement(postId, request)
  - deleteAnnouncement(postId)

#### 3.3 검색/필터/정렬 로직

- [ ] 실시간 검색 디바운싱 (300ms)
- [ ] 필터 조합 로직 (그룹 + 날짜 동시 필터)
- [ ] 정렬 옵션별 쿼리 파라미터 변환
- [ ] 무한 스크롤 페이지 관리 (중복 방지)

#### 3.4 에러 처리 및 로딩 상태

- [ ] API 에러 → 사용자 메시지 (한글)
- [ ] 네트워크 오류 재시도 로직
- [ ] 로딩 스켈레톤 또는 로더 표시
- [ ] 권한 부족 → "공지 작성 권한이 없습니다" 메시지

---

### Phase 4: 네비게이션 통합

**담당**: frontend-specialist / navigation-specialist
**상태**: 대기 중

#### 4.1 라우팅 통합

- [ ] `/announcement-management` 라우트 추가
  - 경로: lib/presentation/pages/announcement_management/
  - 라우터 설정: go_router 기반

- [ ] **WorkspaceView** enum 확장
  ```dart
  enum WorkspaceView {
    home,
    discussions,
    files,
    settings,
    announcementManagement,  // 추가
  }
  ```

#### 4.2 채널 네비게이션 통합

- [X] **channel_navigation.dart** 또는 유사 파일에서 (✅ 완료: 2025-11-17)
  - "공지 관리" 탭 추가 (그룹 메뉴 섹션에 위치)
  - 버튼 위치: 그룹 홈, 캘린더와 동일한 레벨 (좌측 네비게이션)
  - 표시 조건: `canWriteAnnouncementProvider` (공지 채널 존재 + POST_WRITE 권한)

- [X] 권한 기반 탭 표시 로직 (✅ 완료: 2025-11-17)
  ```dart
  // 구현 파일: lib/presentation/widgets/workspace/channel_navigation.dart
  canWriteAnnouncementAsync.when(
    data: (canWrite) {
      if (!canWrite) return const SizedBox.shrink();  // 권한 없음 → 숨김
      // 권한 있음 → 공지 관리 탭 표시
    },
    loading: () => const SizedBox.shrink(),  // 로딩 중 → 숨김
    error: (_, __) => const SizedBox.shrink(),  // 에러 → 숨김
  )
  ```

**구현 세부사항**:
- Provider 추가:
  - `workspaceAnnouncementChannelProvider`: 공지 채널 ID 조회
  - `canWriteAnnouncementProvider`: POST_WRITE 권한 확인 (FutureProvider)
- 그룹 전환 시 자동 재계산: 채널 목록 변경 시 provider가 자동으로 권한 재확인
- 안전한 기본값: 에러/로딩/권한 없음 모두 탭 숨김 처리

#### 4.3 페이지 전환 애니메이션

- [ ] 슬라이드 또는 페이드 애니메이션
- [ ] 히스토리 관리 (뒤로가기 동작)

---

### Phase 5: 테스트 및 문서화

**담당**: test-automation-specialist / context-manager
**상태**: 대기 중

#### 5.1 백엔드 테스트

- [ ] **API 엔드포인트 테스트**
  - `GET /api/users/me/announcement-groups` - 권한별 응답 검증
  - `GET /api/groups/{id}/channels/{channelId}/announcements` - 검색/필터/페이지네이션
  - `GET /api/users/me/announcement-activities` - 활동 조회
  - `POST /api/groups/{id}/channels/{channelId}/posts` - 공지 작성

- [ ] **권한 검증 테스트**
  - POST_WRITE 권한 없을 시 400/403 응답
  - 공동 관리자 글 조회 권한 확인
  - 다른 사용자의 공지 삭제 시도 → 실패

- [ ] **통합 테스트**
  - 전체 API 플로우 (조회 → 작성 → 수정 → 삭제)
  - 다중 그룹 환경에서의 필터링 정확성

#### 5.2 프론트엔드 테스트

- [ ] **위젯 테스트**
  - AnnouncementManagementPage 렌더링
  - 권한 기반 버튼 표시/숨김 테스트
  - 검색/필터 입력 시 UI 업데이트

- [ ] **통합 테스트**
  - 공지 작성 → 목록 업데이트 확인
  - 공지 삭제 → 2단계 확인 다이얼로그 동작
  - 무한 스크롤 페이지네이션

- [ ] **성능 테스트**
  - 무한 스크롤 시 메모리 누수 확인
  - 검색 디바운싱 동작 (300ms 지연)
  - 최근 활동 자동 새로고침 (10초 간격)

#### 5.3 문서 작성

- [ ] **구현 가이드** (docs/implementation/frontend/)
  - AnnouncementManagementPage 아키텍처
  - Provider 사용 방식
  - 컴포넌트 계층 구조
  - API 클라이언트 사용법

- [ ] **API 명세서 업데이트** (docs/implementation/api-reference.md)
  - 새 엔드포인트 추가
  - 응답 형식 정의

- [ ] **기능 명세서** (specs/013-announcement-board-feature/)
  - spec.md: 최종 확정 사항
  - plan.md: 구현 계획
  - tasks.md: 위 Phase별 태스크 분해

---

## 📊 타임라인 및 의존성

| Phase | 담당 | 소요 시간 | 선행 작업 | 상태 |
|-------|------|---------|---------|------|
| 1 | backend-architect | 1일 | - | 대기 |
| 2 | frontend-specialist | 1.5일 | Phase 1 완료 | 대기 |
| 3 | api-integrator | 1일 | Phase 1, 2 완료 | 대기 |
| 4 | frontend-specialist | 0.5일 | Phase 2, 3 완료 | 대기 |
| 5 | test-automation + context-manager | 0.5일 | 모든 Phase 완료 | 대기 |

**총 소요 시간**: 3-4일 (순차 진행)

---

## 🔗 관련 문서 및 참조

### 기존 설계 문서
- [권한 시스템](docs/concepts/permission-system.md) - RBAC + Override 구조
- [API 규칙](docs/implementation/api-reference.md) - ApiResponse<T> 형식
- [프론트엔드 구현 가이드](docs/implementation/frontend/README.md)

### 기존 코드 참조
- **백엔드**: 기존 Post/Comment API 활용 (필요시 확장)
- **프론트엔드**: 기존 GroupSection, ChannelNavigation 컴포넌트 참조

### 브랜치 관련
- 기존 브랜치: 004-announcement-management (참고만)
- 현재 브랜치: 013-announcement-board-feature (개발)

---

## 📝 작업 진행 방식

**현재 상태**: MEMO 작성 완료, 구현 준비 완료

**다음 단계**:
1. 사용자가 Phase 1부터 차례대로 지시
2. 각 Phase 완료 시 이 MEMO 파일 업데이트 (체크리스트 체크 및 완료 날짜 기록)
3. Phase별 완료 후 테스트 → PR 준비

**진행 추적**:
- MEMO 파일 체크리스트로 전체 진도율 추적
- Phase 완료 시 상태 업데이트: 대기 중 → 진행 중 → 완료

---

## ❓ 미해결 사항 (사용자 확인 필요)

- [ ] 최근 활동 자동 새로고침 간격 (제안: 10초)
- [ ] 무한 스크롤 페이지 크기 (제안: 20개/페이지)
- [ ] 검색 디바운싱 지연 (제안: 300ms)
- [ ] 모바일 레이아웃에서 최근 활동 표시 방식 (탭 / 패널 / 생략)

---

**작성자**: Context Manager
**작성일**: 2025-11-17
**버전**: v1.0 (초안)
