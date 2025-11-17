# Post 리팩터링 Phase 3 구현 계획

> **작성일**: 2025-11-18
> **브랜치**: `014-post-clean-architecture-migration`
> **이전 Phase**: Phase 2 (Data Layer) - 커밋 `a8c008b`

---

## 📊 현재 상태 분석

### Phase 1-2 완료 상태
- ✅ **Domain Layer**: 5개 UseCases, 3개 Entities, 1개 Repository Interface
- ✅ **Data Layer**: 3개 DTOs, 1개 DataSource, 1개 Repository 구현체

### 기존 Presentation Layer 현황

#### 사용 중인 파일 (마이그레이션 대상)
```
lib/core/
├── models/
│   └── post_models.dart (147줄) - 기존 Post, PostListResponse 모델
└── services/
    └── post_service.dart (219줄) - 기존 Singleton 서비스

lib/presentation/
├── widgets/post/
│   ├── post_list.dart (821줄) ⚠️ - 메인 게시글 목록 (PostService 직접 사용)
│   ├── post_item.dart - 게시글 아이템
│   ├── post_composer.dart - 게시글 작성 폼
│   ├── edit_post_dialog.dart - 수정 다이얼로그
│   ├── delete_post_dialog.dart - 삭제 다이얼로그
│   ├── post_preview_card.dart - 미리보기 카드
│   └── post_skeleton.dart - 스켈레톤 로더
└── pages/workspace/providers/
    ├── post_actions_provider.dart (77줄) - CRUD FutureProvider들
    └── post_preview_notifier.dart (93줄) - StateNotifier + postServiceProvider
```

#### 의존성 구조 (현재)
```
post_list.dart
  ↓ (직접 import)
PostService (Singleton)
  ↓
DioClient → API

post_actions_provider.dart
  ↓
postServiceProvider (Provider<PostService>)
  ↓
PostService (Singleton)
```

#### 주요 발견사항
1. **PostService 직접 사용**: `post_list.dart`가 821줄이며 `PostService()`를 직접 인스턴스화
2. **상태 관리 혼재**: FutureProvider (액션용) + StateNotifier (미리보기용) + StatefulWidget (목록용)
3. **Provider 산재**: `post_actions_provider.dart`, `post_preview_notifier.dart`가 별도 파일
4. **기존 모델 의존**: 모든 UI가 `core/models/post_models.dart` 사용

---

## 🎯 Phase 3 목표

### 1. Riverpod Providers 생성 (DI)
새로운 Provider 파일:
```
lib/features/post/presentation/providers/
├── post_repository_provider.dart - Repository + DataSource DI
├── post_usecase_providers.dart - 5개 UseCase DI
└── post_list_notifier.dart - 목록 상태 관리 (StateNotifier)
```

### 2. MVVM Adapters 구현
- **PostListNotifier**: 게시글 목록 상태 관리 (loading, error, pagination)
- **기존 Provider 리팩터링**: FutureProvider → UseCase 호출로 전환

### 3. UI 통합
- `post_list.dart`: StatefulWidget → ConsumerWidget 전환, PostListNotifier 사용
- `edit_post_dialog.dart`, `delete_post_dialog.dart`: UseCase Provider 사용

### 4. 기존 코드 제거
- `core/models/post_models.dart` 삭제
- `core/services/post_service.dart` 삭제
- Import 정리

---

## 📐 설계 결정

### Architecture 패턴

#### Dependency Injection Hierarchy
```
┌─────────────────────────────────────────────┐
│ UI Layer (ConsumerWidget)                   │
│   - post_list.dart                          │
│   - edit_post_dialog.dart                   │
│   - delete_post_dialog.dart                 │
└────────────────┬────────────────────────────┘
                 │ ref.watch()
┌────────────────▼────────────────────────────┐
│ Presentation Providers                      │
│   - postListNotifierProvider                │
│   - createPostUseCaseProvider               │
│   - updatePostUseCaseProvider               │
│   - deletePostUseCaseProvider               │
└────────────────┬────────────────────────────┘
                 │ ref.read()
┌────────────────▼────────────────────────────┐
│ Domain UseCases                             │
│   - GetPostsUseCase                         │
│   - GetPostUseCase                          │
│   - CreatePostUseCase                       │
│   - UpdatePostUseCase                       │
│   - DeletePostUseCase                       │
└────────────────┬────────────────────────────┘
                 │ constructor injection
┌────────────────▼────────────────────────────┐
│ PostRepository (interface)                  │
└────────────────┬────────────────────────────┘
                 │ implements
┌────────────────▼────────────────────────────┐
│ Data Layer                                  │
│   - PostRepositoryImpl                      │
│   - PostRemoteDataSource                    │
└─────────────────────────────────────────────┘
```

#### Provider 설계

**1. Repository Provider** (`post_repository_provider.dart`)
```dart
final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(); // 기존 core/network/dio_client.dart 재사용
});

final postRemoteDataSourceProvider = Provider<PostRemoteDataSource>((ref) {
  final dio = ref.watch(dioClientProvider);
  return PostRemoteDataSource(dio);
});

final postRepositoryProvider = Provider<PostRepository>((ref) {
  final dataSource = ref.watch(postRemoteDataSourceProvider);
  return PostRepositoryImpl(dataSource);
});
```

**2. UseCase Providers** (`post_usecase_providers.dart`)
```dart
final getPostsUseCaseProvider = Provider<GetPostsUseCase>((ref) {
  final repository = ref.watch(postRepositoryProvider);
  return GetPostsUseCase(repository);
});

final getPostUseCaseProvider = Provider<GetPostUseCase>((ref) {
  final repository = ref.watch(postRepositoryProvider);
  return GetPostUseCase(repository);
});

final createPostUseCaseProvider = Provider<CreatePostUseCase>((ref) {
  final repository = ref.watch(postRepositoryProvider);
  return CreatePostUseCase(repository);
});

final updatePostUseCaseProvider = Provider<UpdatePostUseCase>((ref) {
  final repository = ref.watch(postRepositoryProvider);
  return UpdatePostUseCase(repository);
});

final deletePostUseCaseProvider = Provider<DeletePostUseCase>((ref) {
  final repository = ref.watch(postRepositoryProvider);
  return DeletePostUseCase(repository);
});
```

**3. PostListNotifier** (`post_list_notifier.dart`)
```dart
// 상태 정의
@freezed
class PostListState with _$PostListState {
  const factory PostListState({
    @Default([]) List<Post> posts,
    @Default(false) bool isLoading,
    @Default(false) bool hasMore,
    @Default(0) int currentPage,
    String? errorMessage,
  }) = _PostListState;
}

// Notifier 구현
class PostListNotifier extends StateNotifier<PostListState> {
  final GetPostsUseCase _getPostsUseCase;

  PostListNotifier(this._getPostsUseCase) : super(const PostListState());

  Future<void> loadPosts(String channelId, {bool refresh = false}) async {
    if (state.isLoading) return;

    if (refresh) {
      state = const PostListState(isLoading: true);
    } else {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }

    try {
      final (posts, pagination) = await _getPostsUseCase(
        channelId,
        page: refresh ? 0 : state.currentPage,
      );

      state = state.copyWith(
        posts: refresh ? posts : [...state.posts, ...posts],
        isLoading: false,
        hasMore: pagination.hasMore,
        currentPage: pagination.currentPage + 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}

// Provider
final postListNotifierProvider = StateNotifierProvider.autoDispose
    .family<PostListNotifier, PostListState, String>((ref, channelId) {
  final useCase = ref.watch(getPostsUseCaseProvider);
  return PostListNotifier(useCase);
});
```

### 마이그레이션 전략

#### Step 1: Provider 생성 (신규 파일)
- ✅ 기존 코드 영향 없음
- ✅ Domain/Data Layer 연결
- ✅ 테스트 가능

#### Step 2: PostListNotifier 구현 (신규 파일)
- ✅ 기존 StatefulWidget 로직을 StateNotifier로 전환
- ✅ 상태 관리 단순화

#### Step 3: UI 점진적 전환
1. **post_list.dart** (821줄 → 예상 200줄)
   - `PostService()` 제거
   - `ref.watch(postListNotifierProvider(channelId))` 사용
   - StatefulWidget → ConsumerWidget 전환
   - 무한 스크롤, 읽음 추적 로직 유지

2. **edit_post_dialog.dart**
   - `updatePostProvider` → `updatePostUseCaseProvider` 전환

3. **delete_post_dialog.dart**
   - `deletePostProvider` → `deletePostUseCaseProvider` 전환

4. **post_preview_notifier.dart**
   - `postServiceProvider` → `getPostUseCaseProvider` 전환

#### Step 4: 기존 코드 제거
- `core/models/post_models.dart` 삭제
- `core/services/post_service.dart` 삭제
- Import 정리 (모든 `import '../../../core/models/post_models.dart'` 제거)

---

## 📋 구현 체크리스트

### Phase 3-1: Providers 생성 (DI 설정)
- [ ] `presentation/providers/post_repository_provider.dart` (예상 30줄)
- [ ] `presentation/providers/post_usecase_providers.dart` (예상 60줄)
- [ ] `presentation/providers/post_list_notifier.dart` (예상 80줄)
- [ ] `presentation/providers/post_list_state.dart` (Freezed, 예상 25줄)
- [ ] Freezed 코드 생성: `flutter pub run build_runner build --delete-conflicting-outputs`

### Phase 3-2: 기존 Provider 리팩터링
- [ ] `post_actions_provider.dart` 수정 (UseCase 사용)
- [ ] `post_preview_notifier.dart` 수정 (UseCase 사용)

### Phase 3-3: UI 통합
- [ ] `post_list.dart` 리팩터링 (821줄 → 200줄)
  - [ ] StatefulWidget → ConsumerWidget
  - [ ] PostService → PostListNotifier
  - [ ] 무한 스크롤 로직 유지
  - [ ] 읽음 추적 로직 유지
- [ ] `edit_post_dialog.dart` 수정
- [ ] `delete_post_dialog.dart` 수정
- [ ] `post_item.dart` Import 정리

### Phase 3-4: 검증 및 테스트
- [ ] `flutter analyze lib/features/post/` (0 issues 목표)
- [ ] 계층 순수성 검증: `grep -r "package:flutter" lib/features/post/domain/` (0건 확인)
- [ ] 파일 크기 준수: 모든 파일 100줄 이하
- [ ] UI 기능 테스트 (수동):
  - [ ] 게시글 목록 로드
  - [ ] 무한 스크롤
  - [ ] 게시글 작성
  - [ ] 게시글 수정
  - [ ] 게시글 삭제
  - [ ] 읽음 위치 추적

### Phase 3-5: 기존 코드 제거
- [ ] `core/models/post_models.dart` 삭제
- [ ] `core/services/post_service.dart` 삭제
- [ ] 모든 Import 정리 및 검증

---

## 🚨 주의사항 및 리스크

### 1. post_list.dart 복잡도
- **현재**: 821줄 (무한 스크롤, 읽음 추적, Sticky Header, 날짜 구분 등)
- **전략**: UI 로직은 유지, 데이터 로딩만 PostListNotifier로 전환
- **리스크**: 로직 누락 가능성 → 기능별 체크리스트 작성 필요

### 2. 읽음 위치 추적 (workspaceStateProvider 연동)
- **현재**: `ref.read(workspaceStateProvider.notifier).updateCurrentVisiblePost(maxId)`
- **전략**: 이 부분은 UI 로직이므로 그대로 유지
- **주의**: PostListNotifier는 목록 로딩만 담당

### 3. Import 정리 복잡도
- **영향 범위**: 13개 파일 (Grep 결과)
- **전략**: 단계별로 Import 정리 (Phase 3-3 이후)
- **검증**: `flutter analyze` + 수동 테스트

### 4. 기존 Provider와의 공존
- **post_actions_provider.dart**: FutureProvider → UseCase로 전환 필요
- **post_preview_notifier.dart**: StateNotifier → UseCase로 전환 필요
- **전략**: 기존 Provider를 먼저 리팩터링한 후 UI 통합

---

## 📊 예상 파일 변경 통계

### 신규 파일 (수동 작성)
- `post_repository_provider.dart`: 30줄
- `post_usecase_providers.dart`: 60줄
- `post_list_state.dart`: 25줄 (Freezed)
- `post_list_notifier.dart`: 80줄

**합계**: 4개 파일, 195줄

### Freezed 생성 파일
- `post_list_state.freezed.dart`
- `post_list_state.g.dart`

**합계**: 2개 파일

### 수정 파일
- `post_list.dart`: 821줄 → 200줄 (621줄 감소)
- `post_actions_provider.dart`: 77줄 → 50줄 (UseCase 호출)
- `post_preview_notifier.dart`: 93줄 → 60줄 (UseCase 호출)
- `edit_post_dialog.dart`: Import 정리
- `delete_post_dialog.dart`: Import 정리
- `post_item.dart`: Import 정리

### 삭제 파일
- `core/models/post_models.dart`: -147줄
- `core/services/post_service.dart`: -219줄

**순 효과**: 약 -200줄 (코드 감소 + 구조 개선)

---

## 📝 구현 순서 (단계별)

### Step 1: Provider 생성 (안전한 시작) ⏱️ 30분
1. `post_repository_provider.dart` 작성
2. `post_usecase_providers.dart` 작성
3. `flutter analyze` 검증

### Step 2: PostListNotifier 구현 ⏱️ 1시간
1. `post_list_state.dart` 작성 (Freezed)
2. `post_list_notifier.dart` 작성
3. Freezed 코드 생성
4. `flutter analyze` 검증

### Step 3: 기존 Provider 리팩터링 ⏱️ 30분
1. `post_actions_provider.dart` 수정
2. `post_preview_notifier.dart` 수정
3. 기능 테스트 (수동)

### Step 4: post_list.dart 리팩터링 ⏱️ 2시간
1. ConsumerWidget 전환
2. PostListNotifier 연결
3. 무한 스크롤 로직 검증
4. 읽음 추적 로직 검증
5. UI 기능 테스트

### Step 5: 다이얼로그 통합 ⏱️ 30분
1. `edit_post_dialog.dart` 수정
2. `delete_post_dialog.dart` 수정
3. 기능 테스트

### Step 6: 기존 코드 제거 및 최종 검증 ⏱️ 30분
1. Import 정리
2. `core/models/post_models.dart` 삭제
3. `core/services/post_service.dart` 삭제
4. `flutter analyze` 최종 검증
5. 전체 기능 테스트

**총 예상 시간**: 5시간

---

## 📚 참고 문서

- [Phase 1 완료 보고서](./docs/workflows/post-phase1-completion.md)
- [Phase 2 완료 보고서](./docs/workflows/post-phase2-completion.md)
- [Frontend Architecture Guide](./docs/frontend/architecture-guide.md)
- [Implementation Philosophy](./docs/conventions/implementation-philosophy.md)

---

**다음 단계**: 사용자 승인 대기 → Phase 3-1 구현 시작
