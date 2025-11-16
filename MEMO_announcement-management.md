# 공지 관리 기능 구현 메모

## 구현 날짜
2025-11-17

## 구현 목표
1. 워크스페이스 그룹 홈에 "공지 관리" 버튼 추가 (POST_WRITE 권한 기반)
2. 공지 관리 페이지 기본 레이아웃 생성
3. 상태 관리, 데이터 모델, API 구조 기반 코드 마련

## 분석 결과

### 기존 코드 패턴 확인
- **워크스페이스 구조**: `workspace_page.dart` → `group_home_view.dart`
- **권한 체크**: `workspaceHasAnyGroupPermissionProvider` 사용 중
- **버튼 패턴**: `_buildCreateSubgroupSection()` - OutlinedButton.icon + 설명
- **라우팅**: GoRouter, ShellRoute + NoTransitionPage 사용
- **디자인 시스템**:
  - 900px 브레이크포인트
  - AppSpacing (4pt grid)
  - AppColors (보라색 브랜드 팔레트)

### 권한 체크 방식
- 채널별 권한: `ChannelPermissions.canWritePost` → `POST_WRITE` 확인
- 그룹 권한: `groupPermissionsProvider(groupId)` → FutureProvider.family
- 헬퍼: `hasPermissionProvider((groupId, permission))` 사용 가능

### 기존 Repository 패턴
- `lib/core/repositories/` 폴더에 repository 클래스들
- 예: `member_repository.dart`, `role_repository.dart`
- API 호출 로직과 에러 처리 포함

## 구현 계획

### Phase 1: 데이터 모델 및 API 서비스
1. `lib/core/models/announcement_models.dart` - Announcement, AnnouncementFilter
2. `lib/core/repositories/announcement_repository.dart` - API 호출 구조

### Phase 2: 상태 관리 (Provider)
1. `lib/presentation/providers/announcement_providers.dart`
   - `announcementListProvider`
   - `announcementFilterProvider`
   - `announcementSearchProvider`

### Phase 3: 공지 관리 페이지
1. `lib/presentation/pages/announcement/announcement_management_page.dart`
   - 기본 레이아웃 (헤더, 메인 영역)
   - 빈 상태 표시

### Phase 4: 라우팅 추가
1. `app_router.dart`에 공지 관리 경로 추가

### Phase 5: 워크스페이스 UI 수정
1. `group_home_view.dart`에 "공지 관리" 버튼 추가
   - POST_WRITE 권한 체크
   - 공지 채널 찾기 로직 필요

## 주의사항
- Row/Column 레이아웃 시 Expanded/Flexible 필수
- 모든 액션 버튼에 권한 체크 적용
- null 체크 철저히
- 반응형 레이아웃 (900px 브레이크포인트)
- 한글 사용자 메시지

## 완료 단계
- [X] 데이터 모델 작성 (`announcement_models.dart`)
- [X] Repository 구조 작성 (`announcement_repository.dart`)
- [X] Provider 정의 (`announcement_providers.dart`)
- [X] 페이지 레이아웃 작성 (`announcement_management_page.dart`)
- [X] 라우팅 추가 (`app_router.dart` - `/workspace/:groupId/announcements`)
- [X] 버튼 UI 추가 (`group_home_view.dart` - POST_WRITE 권한 체크 포함)

## 구현 완료 상세

### 1. 데이터 모델
- **Announcement**: id, title, content, authorId, authorName, groupId, channelId, createdAt, updatedAt, isPinned
- **AnnouncementFilter**: groupId, startDate, endDate, pinnedOnly

### 2. Repository
- **ApiAnnouncementRepository**:
  - getAnnouncements() - 페이징 지원
  - searchAnnouncements() - 검색 기능
  - createAnnouncement(), updateAnnouncement(), deleteAnnouncement()
  - pinAnnouncement(), unpinAnnouncement()

### 3. Provider
- `announcementRepositoryProvider`: Repository 인스턴스
- `announcementFilterProvider`: 필터 상태 관리
- `announcementSearchQueryProvider`: 검색어 상태 관리
- `announcementListProvider`: 공지사항 목록 (family provider)
- `searchAnnouncementsProvider`: 검색 결과 (family provider)
- `announcementManagementProvider`: CRUD 작업 처리

### 4. 공지 관리 페이지
- 반응형 레이아웃 (900px 브레이크포인트)
- 헤더: 제목, 설명, "공지 작성" 버튼
- 메인: 빈 상태 표시 (향후 목록 표시 예정)

### 5. 라우팅
- 경로: `/workspace/:groupId/announcements`
- GoRouter 통합 완료

### 6. 그룹 홈 버튼
- 위치: 그룹 홈 헤더의 액션 버튼 영역
- 권한 체크: 공지 채널의 POST_WRITE 권한 확인
- 권한 없으면 버튼 숨김 (SizedBox.shrink)
- 공지 채널 없으면 버튼 숨김

## 테스트 결과
- Flutter analyze: 0개 에러 (기존 경고만 존재)
- 모든 새 파일 정상 생성
- 라우팅 통합 완료

## 다음 작업 (향후 단계)
- 공지사항 목록 UI 구현
- 공지사항 작성/수정 다이얼로그
- 공지사항 삭제 기능
- 검색 및 필터링 UI
- 공지사항 고정/해제 기능
