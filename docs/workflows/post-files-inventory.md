# Post 리팩터링 Phase 0 - 기존 파일 인벤토리

## 파일 목록 및 분석 (총 18개 파일, 3,172줄)

### 🔴 Core Layer (403줄) - 아키텍처 위반
Domain/Data 레이어로 이동 필요

**Models (184줄)**
- `core/models/post_models.dart` (147줄) - Entity + DTO 혼재
- `core/models/post_list_item.dart` (37줄) - UI 전용 모델

**Services (219줄)**
- `core/services/post_service.dart` (219줄) - HTTP 클라이언트, API 호출, 파싱

### 🟡 Presentation/Widgets/Post (2,006줄)

**주요 컴포넌트**
- `post_list.dart` (820줄) ⚠️ **CRITICAL** - 8배 초과
  - 책임: UI + InfiniteScroll + ReadTracking + StickyHeader + API 호출 + 상태관리
- `post_item.dart` (342줄) - 게시글 카드 UI
  - 책임: 카드 렌더링 + 액션 버튼 + 권한 체크
- `post_composer.dart` (189줄) - 게시글 작성 폼
  - 책임: 폼 UI + 유효성 검사 + 제출
- `post_preview_card.dart` (149줄) - 미리보기 카드
- `post_skeleton.dart` (116줄) - 로딩 스켈레톤

**다이얼로그 (265줄)**
- `edit_post_dialog.dart` (163줄) - 수정 다이얼로그
- `delete_post_dialog.dart` (102줄) - 삭제 확인 다이얼로그

**UI 헬퍼 (125줄)** ✅ 100줄 준수
- `date_divider.dart` (78줄) - 날짜 구분선
- `unread_message_divider.dart` (47줄) - 읽지 않은 메시지 구분선

### 🟢 Presentation/Pages/Workspace (352줄)

**Providers (168줄)**
- `providers/post_actions_provider.dart` (76줄) - 액션 처리 (생성/수정/삭제)
- `providers/post_preview_notifier.dart` (92줄) - 미리보기 상태 관리

**Widgets (184줄)**
- `widgets/post_preview_widget.dart` (184줄) - 미리보기 위젯

**Helpers (71줄)** ✅ 100줄 준수
- `helpers/post_comment_actions.dart` (71줄) - 댓글 액션 헬퍼

### 🟣 Presentation/Widgets/Workspace (340줄)

**Mobile Views**
- `mobile_channel_posts_view.dart` (109줄) - 모바일 게시글 뷰
- `mobile_post_comments_view.dart` (231줄) - 모바일 댓글 뷰

## 중복 로직 식별

**API 호출 로직 (3곳)**
- `post_service.dart`: HTTP 클라이언트
- `post_actions_provider.dart`: 액션 API 호출
- `post_list.dart`: 게시글 목록 조회

**상태 관리 (4곳)**
- `post_list.dart`: InfiniteScroll 상태
- `post_preview_notifier.dart`: 미리보기 상태
- `post_actions_provider.dart`: 액션 상태
- 각 다이얼로그: 로컬 폼 상태

**권한 체크 (3곳)**
- `post_item.dart`: 수정/삭제 버튼 표시
- `post_composer.dart`: 작성 권한
- `post_actions_provider.dart`: 액션 실행 전 체크

## 재사용 가능한 컴포넌트

**즉시 재사용 가능** ✅
- `date_divider.dart` (78줄) - 범용 날짜 구분선
- `unread_message_divider.dart` (47줄) - 범용 구분선
- `post_comment_actions.dart` (71줄) - 헬퍼 함수

**리팩터링 후 재사용 가능**
- `post_item.dart` → ViewModel 적용 후
- `post_composer.dart` → ViewModel 적용 후
- `edit_post_dialog.dart` → ViewModel 적용 후
- `delete_post_dialog.dart` → ViewModel 적용 후

## Clean Architecture 위반 사항

**Domain Layer 누락** (0/3)
- Entity 없음 (DTO만 존재)
- UseCase 없음 (Service 직접 호출)
- Repository Interface 없음

**Data Layer 누락** (0/3)
- Model 혼재 (Entity + DTO 구분 없음)
- DataSource 없음 (Service가 대체)
- Repository 구현 없음

**Presentation Layer 문제**
- 비즈니스 로직 혼재 (`post_list.dart` 820줄)
- Service 직접 의존 (UseCase 없이)
- 과도한 책임 (UI + 로직 + 상태 + API)
