# Post 리팩터링 마스터 플랜

## Executive Summary

### 목표
Post 기능을 Clean Architecture 기반으로 완전히 재구성하여 **신기능 추가 용이성**과 **유지보수성**을 확보합니다.

### 전략
- **완전 교체 방식**: 기존 코드를 한 번에 새 아키텍처로 전환 (빠른 진행)
- **우선순위**: 신기능 추가 준비 > 유지보수성 개선 > 성능 최적화
- **백엔드 협업**: 현재 API 유지, 이점이 큰 경우에만 신규 API 제안
- **테스트 전략**: 핵심 로직 단위 테스트 (빠른 검증)

### 예상 결과
- **구조 개선**: 3-Layer Architecture + MVVM 완벽 준수
- **파일 크기 감소**: 평균 100줄 이하 유지 (현재 PostList 821줄 → 6개 파일로 분할)
- **테스트 커버리지**: 핵심 로직 60% (헌법 60/30/10 원칙)
- **신기능 준비**: 댓글 확장, 반응형, 첨부파일 등 확장 용이

### 전체 일정
| Phase | 작업 내용 | 예상 기간 |
|-------|----------|----------|
| Phase 0 | 준비 단계 (분석 및 설계) | 0.5일 |
| Phase 1 | Domain 계층 구축 | 1일 |
| Phase 2 | Data 계층 구축 | 1일 |
| Phase 3 | Presentation 계층 리팩터링 | 2일 |
| Phase 4 | 테스트 및 검증 | 1일 |
| Phase 5 | 성능 최적화 (선택) | 0.5일 |
| **총 기간** | | **6일** |

### Risk & Mitigation
| Risk | Mitigation |
|------|------------|
| 기존 기능 동작 불일치 | Phase 4에서 기존 동작 비교 테스트 필수 |
| 스크롤 위치 복원 실패 | 기존 로직 보존, 점진적 개선 |
| 성능 저하 | Phase 5에서 병목 분석 및 최적화 |

---

## 아키텍처 청사진

### AS-IS: 현재 구조 (혼재된 계층)

```
presentation/
├── widgets/post/
│   ├── post_list.dart (821줄 - 모든 로직 포함)
│   │   → UI 렌더링 + 스크롤 로직 + 읽음 추적
│   │   → API 호출 (PostService 직접 사용)
│   │   → 상태 관리 (StatefulWidget)
│   ├── post_item.dart (343줄)
│   ├── post_composer.dart
│   └── [기타 위젯들]
├── pages/workspace/
│   ├── providers/
│   │   ├── post_actions_provider.dart
│   │   └── post_preview_notifier.dart
│   └── helpers/
│       └── post_comment_actions.dart

core/
├── models/
│   ├── post_models.dart (148줄 - DTO + Entity 혼재)
│   └── post_list_item.dart
└── services/
    └── post_service.dart (220줄 - API 클라이언트)
```

**문제점**:
1. **계층 혼재**: Presentation이 Data(PostService)를 직접 호출
2. **비대한 파일**: PostList 821줄, 단일 책임 위반
3. **테스트 어려움**: 로직이 UI에 강결합
4. **확장성 부족**: 새 기능 추가 시 파일 비대화

### TO-BE: Clean Architecture 구조

```
features/post/
├── domain/
│   ├── entities/
│   │   ├── post.dart (Freezed Entity)
│   │   └── post_filter.dart
│   ├── repositories/
│   │   └── post_repository.dart (추상 인터페이스)
│   └── usecases/
│       ├── get_posts_usecase.dart
│       ├── create_post_usecase.dart
│       ├── update_post_usecase.dart
│       ├── delete_post_usecase.dart
│       └── track_read_position_usecase.dart
│
├── data/
│   ├── models/
│   │   ├── post_dto.dart (API 응답 DTO)
│   │   └── post_list_response_dto.dart
│   ├── datasources/
│   │   ├── post_remote_datasource.dart (Dio API 클라이언트)
│   │   └── post_local_datasource.dart (캐시/읽음 위치)
│   └── repositories/
│       └── post_repository_impl.dart (Repository 구현)
│
└── presentation/
    ├── providers/
    │   ├── post_list_provider.dart (ViewModel - 목록 상태)
    │   ├── post_detail_provider.dart (ViewModel - 상세/수정)
    │   └── read_position_provider.dart (ViewModel - 읽음 추적)
    ├── pages/
    │   └── post_list_page.dart (<100줄)
    └── widgets/
        ├── post_list_view.dart (<100줄 - 순수 UI)
        ├── post_item.dart (재사용)
        ├── post_composer.dart (재사용)
        ├── date_divider.dart (재사용)
        └── unread_divider.dart (재사용)
```

**개선점**:
1. **명확한 계층 분리**: Presentation → Domain ← Data
2. **파일 크기 준수**: 모든 파일 100줄 이하
3. **테스트 용이**: UseCase 단위 테스트 가능
4. **확장 준비**: 새 기능(댓글, 반응형, 첨부파일) 추가 용이

---

## 계층별 책임 정의

### Domain 계층
**책임**: 비즈니스 로직과 데이터 구조 정의
- **Entity**: 순수 Dart 클래스 (Freezed 사용)
- **Repository Interface**: 데이터 접근 추상화
- **UseCase**: 단일 비즈니스 기능 수행

**규칙**:
- Flutter 패키지 import 금지 (`package:flutter/**`)
- 다른 계층 의존 금지 (완전 독립)
- Freezed로 불변 객체 보장

**예시**:
```dart
// domain/entities/post.dart
@freezed
class Post with _$Post {
  const factory Post({
    required int id,
    required String content,
    required Author author,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _Post;
}

// domain/repositories/post_repository.dart
abstract class PostRepository {
  Future<List<Post>> getPosts(String channelId, {int page, int size});
  Future<Post> createPost(String channelId, String content);
}

// domain/usecases/get_posts_usecase.dart
class GetPostsUseCase {
  final PostRepository repository;
  GetPostsUseCase(this.repository);

  Future<List<Post>> call(String channelId, {int page = 0}) {
    return repository.getPosts(channelId, page: page, size: 20);
  }
}
```

### Data 계층
**책임**: 외부 데이터 소스와 통신
- **DTO**: API 응답/요청 형식
- **DataSource**: API 클라이언트 (Remote), 캐시 (Local)
- **Repository Impl**: Domain Repository 구현

**규칙**:
- Domain Entity ↔ DTO 변환 책임
- 예외 처리 및 에러 변환
- Presentation에서 직접 호출 금지

**예시**:
```dart
// data/models/post_dto.dart
class PostDto {
  final int id;
  final String content;
  final AuthorDto author;

  PostDto.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      content = json['content'],
      author = AuthorDto.fromJson(json['author']);

  Post toEntity() => Post(
    id: id,
    content: content,
    author: author.toEntity(),
    // ...
  );
}

// data/repositories/post_repository_impl.dart
class PostRepositoryImpl implements PostRepository {
  final PostRemoteDataSource remoteDataSource;

  @override
  Future<List<Post>> getPosts(String channelId, {int page = 0, int size = 20}) async {
    final dtos = await remoteDataSource.fetchPosts(channelId, page, size);
    return dtos.map((dto) => dto.toEntity()).toList();
  }
}
```

### Presentation 계층 (MVVM)
**책임**: UI 렌더링 및 사용자 입력 처리
- **ViewModel (Provider)**: UI 상태 관리 + UseCase 호출
- **View (Widget)**: 순수 UI 렌더링 (로직 없음)

**규칙**:
- View는 "멍청하게" (Dumb Widget)
- 모든 로직은 ViewModel에 위임
- Domain UseCase만 호출 (Data 직접 접근 금지)

**예시**:
```dart
// presentation/providers/post_list_provider.dart
@riverpod
class PostListNotifier extends _$PostListNotifier {
  @override
  FutureOr<List<Post>> build(String channelId) async {
    final useCase = ref.read(getPostsUseCaseProvider);
    return useCase(channelId);
  }

  Future<void> loadMore() async {
    // 무한 스크롤 로직
  }
}

// presentation/pages/post_list_page.dart
class PostListPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(postListProvider(channelId));
    return posts.when(
      data: (data) => PostListView(posts: data),
      loading: () => LoadingSkeleton(),
      error: (err, _) => ErrorView(error: err),
    );
  }
}
```

---

## 파일/폴더 구조 설계

### 최종 구조 (전체)
```
frontend/lib/
├── features/
│   └── post/
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── post.dart (~50줄)
│       │   │   ├── post.freezed.dart (자동 생성)
│       │   │   ├── post.g.dart (자동 생성)
│       │   │   ├── author.dart (~30줄)
│       │   │   └── post_filter.dart (~40줄)
│       │   ├── repositories/
│       │   │   └── post_repository.dart (~60줄)
│       │   └── usecases/
│       │       ├── get_posts_usecase.dart (~40줄)
│       │       ├── create_post_usecase.dart (~30줄)
│       │       ├── update_post_usecase.dart (~30줄)
│       │       ├── delete_post_usecase.dart (~30줄)
│       │       └── track_read_position_usecase.dart (~50줄)
│       │
│       ├── data/
│       │   ├── models/
│       │   │   ├── post_dto.dart (~80줄)
│       │   │   ├── author_dto.dart (~40줄)
│       │   │   └── post_list_response_dto.dart (~60줄)
│       │   ├── datasources/
│       │   │   ├── post_remote_datasource.dart (~120줄)
│       │   │   └── post_local_datasource.dart (~80줄)
│       │   └── repositories/
│       │       └── post_repository_impl.dart (~100줄)
│       │
│       └── presentation/
│           ├── providers/
│           │   ├── post_list_provider.dart (~80줄)
│           │   ├── post_list_provider.g.dart (자동 생성)
│           │   ├── post_detail_provider.dart (~60줄)
│           │   └── read_position_provider.dart (~70줄)
│           ├── pages/
│           │   └── post_list_page.dart (~90줄)
│           └── widgets/
│               ├── post_list_view.dart (~100줄)
│               ├── post_item.dart (~80줄 - 재사용)
│               ├── post_composer.dart (~70줄 - 재사용)
│               ├── date_divider.dart (~30줄 - 재사용)
│               ├── unread_divider.dart (~20줄 - 재사용)
│               ├── post_skeleton.dart (~40줄 - 재사용)
│               └── edit_post_dialog.dart (~90줄 - 재사용)
│
└── core/
    ├── providers/
    │   └── dio_provider.dart (Dio 인스턴스)
    └── utils/
        └── read_position_helper.dart (유틸)
```

### 명명 규칙
| 타입 | 규칙 | 예시 |
|------|------|------|
| Entity | `{도메인명}.dart` | `post.dart` |
| DTO | `{도메인명}_dto.dart` | `post_dto.dart` |
| Repository 인터페이스 | `{도메인명}_repository.dart` | `post_repository.dart` |
| Repository 구현 | `{도메인명}_repository_impl.dart` | `post_repository_impl.dart` |
| UseCase | `{동사}_{도메인명}_usecase.dart` | `get_posts_usecase.dart` |
| Provider | `{도메인명}_{상태}_provider.dart` | `post_list_provider.dart` |
| Widget | `{도메인명}_{역할}.dart` | `post_list_view.dart` |

---

## 구현 원칙과 가이드라인

### Clean Architecture 준수 사항
1. **의존성 규칙**: `Presentation → Domain ← Data`
   - Presentation이 Data를 직접 호출하면 안 됨
   - Domain은 어떤 계층도 의존하지 않음
2. **단일 책임 원칙 (SRP)**: 한 파일은 한 가지 일만
3. **파일 크기 제한**: 100줄 초과 시 분리 검토

### Riverpod 사용 규칙
1. **코드 생성 방식 사용**: `riverpod_generator` 활용
   ```dart
   @riverpod
   class PostListNotifier extends _$PostListNotifier {
     // ...
   }
   ```
2. **Provider 스코프 원칙**: 기능 단위로 Provider 분리
   - ❌ 금지: 모든 Post 로직을 하나의 Provider에
   - ✅ 권장: 목록/상세/읽음추적 Provider 분리
3. **상태 타입 선택**:
   - 비동기 데이터: `AsyncValue<T>`
   - 동기 상태: `StateProvider`, `StateNotifierProvider`

### 명명 규칙
1. **변수/함수**: `camelCase`
2. **클래스**: `PascalCase`
3. **파일**: `snake_case.dart`
4. **상수**: `SCREAMING_SNAKE_CASE` (선택)

### 파일 크기 제한
- **목표**: 100줄 이하
- **허용**: 120줄 (예외적)
- **초과 시**: 즉시 분리

### 테스트 전략 (기본 테스트)
1. **단위 테스트**: UseCase 로직 검증 (60%)
   - `get_posts_usecase_test.dart`
   - `create_post_usecase_test.dart`
2. **Mock 사용**: Repository 인터페이스 Mock
3. **커버리지 목표**: 핵심 로직 60% (헌법 60/30/10 원칙)

---

## Phase별 실행 계획

### Phase 0: 준비 단계 (0.5일)

**목표**: 기존 코드 분석 및 마이그레이션 설계

**작업**:
1. 기존 Post 관련 파일 인벤토리 작성
   - 파일별 책임 분석
   - 중복 로직 식별
   - 재사용 가능한 위젯 리스트업
2. Domain Entity 설계
   - Post, Author 모델 Freezed 정의
   - PostFilter (옵션) 설계
3. UseCase 목록 확정
   - CRUD 기본: Get/Create/Update/Delete
   - 확장: TrackReadPosition, LoadMorePosts
4. 폴더 구조 생성
   ```bash
   mkdir -p features/post/{domain/{entities,repositories,usecases},data/{models,datasources,repositories},presentation/{providers,pages,widgets}}
   ```

**산출물**:
- [ ] 기존 파일 인벤토리 (Markdown)
- [ ] Domain Entity 설계 문서
- [ ] UseCase 목록
- [ ] 빈 폴더 구조

### Phase 1: Domain 계층 구축 (1일)

**목표**: 비즈니스 로직 계층 완성 (Flutter 의존성 없음)

**작업**:
1. **Entities 구현** (~2시간)
   - `post.dart`: Freezed + JsonSerializable
     ```dart
     @freezed
     class Post with _$Post {
       const factory Post({
         required int id,
         required String content,
         required Author author,
         required DateTime createdAt,
         DateTime? updatedAt,
         @Default(0) int commentCount,
       }) = _Post;

       factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
     }
     ```
   - `author.dart`: Freezed
   - `post_filter.dart`: (선택) 필터링 조건

2. **Repository 인터페이스 정의** (~1시간)
   - `post_repository.dart`
     ```dart
     abstract class PostRepository {
       Future<List<Post>> getPosts(String channelId, {int page, int size});
       Future<Post> getPost(int postId);
       Future<Post> createPost(String channelId, String content);
       Future<Post> updatePost(int postId, String content);
       Future<void> deletePost(int postId);
     }
     ```

3. **UseCases 구현** (~3시간)
   - `get_posts_usecase.dart`
     ```dart
     class GetPostsUseCase {
       final PostRepository repository;
       GetPostsUseCase(this.repository);

       Future<List<Post>> call(String channelId, {int page = 0}) {
         return repository.getPosts(channelId, page: page, size: 20);
       }
     }
     ```
   - `create_post_usecase.dart`
   - `update_post_usecase.dart`
   - `delete_post_usecase.dart`
   - `track_read_position_usecase.dart` (읽음 위치 저장)

4. **코드 생성** (~30분)
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

**검증 기준**:
- [ ] Domain 계층에 `package:flutter` import 없음
- [ ] 모든 Entity Freezed 생성 성공
- [ ] UseCase 단위 테스트 작성 (핵심 로직만)

**산출물**:
- [ ] `domain/entities/post.dart` (~50줄)
- [ ] `domain/entities/author.dart` (~30줄)
- [ ] `domain/repositories/post_repository.dart` (~60줄)
- [ ] `domain/usecases/*.dart` (각 ~40줄)

### Phase 2: Data 계층 구축 (1일)

**목표**: API 통신 및 저장소 구현

**작업**:
1. **DTO 모델 구현** (~2시간)
   - `post_dto.dart`: API 응답 매핑
     ```dart
     class PostDto {
       final int id;
       final String content;
       final AuthorDto author;
       final String createdAt;
       final String? updatedAt;

       PostDto.fromJson(Map<String, dynamic> json)
         : id = json['id'],
           content = json['content'],
           author = AuthorDto.fromJson(json['author']),
           createdAt = json['createdAt'],
           updatedAt = json['updatedAt'];

       Post toEntity() => Post(
         id: id,
         content: content,
         author: author.toEntity(),
         createdAt: DateTime.parse(createdAt),
         updatedAt: updatedAt != null ? DateTime.parse(updatedAt!) : null,
       );
     }
     ```
   - `author_dto.dart`
   - `post_list_response_dto.dart`

2. **Remote DataSource 구현** (~3시간)
   - `post_remote_datasource.dart`: Dio 기반 API 클라이언트
     ```dart
     class PostRemoteDataSource {
       final Dio dio;
       PostRemoteDataSource(this.dio);

       Future<List<PostDto>> fetchPosts(String channelId, int page, int size) async {
         final response = await dio.get(
           '/channels/$channelId/posts',
           queryParameters: {'page': page, 'size': size},
         );

         final apiResponse = ApiResponse.fromJson(response.data, (json) {
           if (json is List) {
             return json.map((item) => PostDto.fromJson(item)).toList();
           }
           return PostListResponseDto.fromJson(json).posts;
         });

         if (!apiResponse.success) {
           throw Exception(apiResponse.message);
         }
         return apiResponse.data!;
       }
     }
     ```

3. **Local DataSource 구현** (~1시간)
   - `post_local_datasource.dart`: 읽음 위치 캐시
     ```dart
     class PostLocalDataSource {
       final Map<int, int> _readPositions = {}; // channelId → lastReadPostId

       void saveReadPosition(int channelId, int postId) {
         _readPositions[channelId] = postId;
       }

       int? getReadPosition(int channelId) {
         return _readPositions[channelId];
       }
     }
     ```

4. **Repository 구현** (~2시간)
   - `post_repository_impl.dart`
     ```dart
     class PostRepositoryImpl implements PostRepository {
       final PostRemoteDataSource remoteDataSource;

       PostRepositoryImpl(this.remoteDataSource);

       @override
       Future<List<Post>> getPosts(String channelId, {int page = 0, int size = 20}) async {
         final dtos = await remoteDataSource.fetchPosts(channelId, page, size);
         return dtos.map((dto) => dto.toEntity()).toList();
       }

       @override
       Future<Post> createPost(String channelId, String content) async {
         final dto = await remoteDataSource.createPost(channelId, content);
         return dto.toEntity();
       }
     }
     ```

**검증 기준**:
- [ ] API 호출 성공 (기존 PostService와 동일한 결과)
- [ ] DTO ↔ Entity 변환 정확성 확인
- [ ] 예외 처리 완료

**산출물**:
- [ ] `data/models/*.dart` (각 ~60줄)
- [ ] `data/datasources/*.dart` (각 ~100줄)
- [ ] `data/repositories/post_repository_impl.dart` (~100줄)

### Phase 3: Presentation 계층 리팩터링 (2일)

**목표**: UI/UX 유지하며 MVVM 패턴 적용

**작업**:
1. **Provider 구현** (~4시간)
   - `post_list_provider.dart`: 목록 상태 관리
     ```dart
     @riverpod
     class PostListNotifier extends _$PostListNotifier {
       int _currentPage = 0;
       bool _hasMore = true;

       @override
       FutureOr<List<Post>> build(String channelId) async {
         final useCase = ref.read(getPostsUseCaseProvider);
         _currentPage = 0;
         _hasMore = true;
         return useCase(channelId, page: _currentPage);
       }

       Future<void> loadMore() async {
         if (!_hasMore || state.isLoading) return;

         state = const AsyncValue.loading();
         _currentPage++;

         final useCase = ref.read(getPostsUseCaseProvider);
         final newPosts = await useCase(channelId, page: _currentPage);

         if (newPosts.isEmpty) {
           _hasMore = false;
         }

         state = AsyncValue.data([...state.value!, ...newPosts]);
       }
     }
     ```
   - `post_detail_provider.dart`: 단일 게시글 상태
   - `read_position_provider.dart`: 읽음 추적

2. **Page 구현** (~2시간)
   - `post_list_page.dart`: 순수 조립 역할
     ```dart
     class PostListPage extends ConsumerWidget {
       final String channelId;

       @override
       Widget build(BuildContext context, WidgetRef ref) {
         final posts = ref.watch(postListProvider(channelId));

         return Scaffold(
           appBar: AppBar(title: const Text('게시글')),
           body: posts.when(
             data: (data) => PostListView(
               posts: data,
               onLoadMore: () => ref.read(postListProvider(channelId).notifier).loadMore(),
               onTapComment: (postId) => _navigateToComments(context, postId),
             ),
             loading: () => const PostSkeleton(),
             error: (err, stack) => ErrorView(error: err),
           ),
         );
       }
     }
     ```

3. **Widget 리팩터링** (~6시간)
   - `post_list_view.dart`: 순수 UI (100줄 이하)
     - 기존 PostList의 UI 로직만 추출
     - 스크롤, 읽음 추적 로직 제거 → Provider로 이동
   - `post_item.dart`: 재사용 (기존 코드 정리)
   - `post_composer.dart`: 재사용
   - `date_divider.dart`, `unread_divider.dart`: 재사용

4. **코드 생성 및 통합** (~2시간)
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

**검증 기준**:
- [ ] 기존 기능 100% 동작 (스크롤, 읽음 추적, CRUD)
- [ ] Widget이 Provider만 호출 (UseCase 직접 호출 없음)
- [ ] 모든 파일 100줄 이하

**산출물**:
- [ ] `presentation/providers/*.dart` (각 ~80줄)
- [ ] `presentation/pages/post_list_page.dart` (~90줄)
- [ ] `presentation/widgets/*.dart` (각 ~80줄)

### Phase 4: 테스트 및 검증 (1일)

**목표**: 핵심 로직 테스트 + 기존 동작 확인

**작업**:
1. **단위 테스트 작성** (~4시간)
   - `test/features/post/domain/usecases/`
     - `get_posts_usecase_test.dart`
       ```dart
       void main() {
         late MockPostRepository mockRepository;
         late GetPostsUseCase useCase;

         setUp(() {
           mockRepository = MockPostRepository();
           useCase = GetPostsUseCase(mockRepository);
         });

         test('should get posts from repository', () async {
           // Arrange
           final mockPosts = [
             Post(id: 1, content: 'Test', author: mockAuthor, createdAt: DateTime.now()),
           ];
           when(() => mockRepository.getPosts(any(), page: any(named: 'page')))
             .thenAnswer((_) async => mockPosts);

           // Act
           final result = await useCase('channel1');

           // Assert
           expect(result, mockPosts);
           verify(() => mockRepository.getPosts('channel1', page: 0)).called(1);
         });
       }
       ```
     - `create_post_usecase_test.dart`
     - `delete_post_usecase_test.dart`

2. **통합 테스트** (~2시간)
   - 기존 기능 동작 확인 (수동 테스트)
     - [ ] 게시글 목록 로드
     - [ ] 무한 스크롤
     - [ ] 읽음 위치 복원
     - [ ] 게시글 작성/수정/삭제
     - [ ] 댓글 버튼 클릭

3. **성능 비교** (~1시간)
   - 렌더링 시간 측정 (DevTools)
   - 메모리 사용량 체크

4. **문서화** (~1시간)
   - 변경 사항 요약
   - 마이그레이션 가이드 (다른 기능 참고용)

**검증 기준**:
- [ ] 단위 테스트 통과 (커버리지 60%)
- [ ] 기존 기능 100% 동작
- [ ] 성능 저하 없음 (±5% 허용)

**산출물**:
- [ ] `test/features/post/domain/usecases/*.dart`
- [ ] 테스트 결과 보고서 (Markdown)
- [ ] 마이그레이션 가이드

### Phase 5: 성능 최적화 (0.5일, 선택)

**목표**: 병목 해결 및 렌더링 최적화

**작업** (필요 시):
1. **Riverpod 메모이제이션** (~1시간)
   - Provider 캐싱 전략
   - 불필요한 rebuild 방지
2. **ListView 최적화** (~1시간)
   - `itemExtent` 추정값 제공
   - `cacheExtent` 조정
3. **이미지 로딩 최적화** (~1시간)
   - `CachedNetworkImage` 적용
   - Placeholder 개선

**검증 기준**:
- [ ] 렌더링 시간 10% 이상 개선
- [ ] 메모리 사용량 감소

---

## 주의사항 및 위험 관리

### 절대 하지 말아야 할 것들

1. **계층 경계 위반 금지**
   - ❌ Presentation이 Data 직접 호출
     ```dart
     // ❌ 금지
     final posts = await PostService().fetchPosts(channelId);

     // ✅ 권장
     final posts = await ref.read(getPostsUseCaseProvider)(channelId);
     ```

2. **거대한 Provider 금지**
   - ❌ 모든 Post 로직을 하나의 Provider에
   - ✅ 목록/상세/읽음추적 Provider 분리

3. **Widget에 비즈니스 로직 금지**
   - ❌ Widget 내부에서 API 호출, 데이터 가공
   - ✅ Provider에서 처리 후 결과만 받기

4. **파일 크기 100줄 초과 방치 금지**
   - 초과 시 즉시 분리 검토

5. **테스트 없이 리팩터링 금지**
   - UseCase는 반드시 단위 테스트 작성

### 자주 발생하는 실수들

1. **DTO와 Entity 혼동**
   - DTO는 Data 계층 (API 응답)
   - Entity는 Domain 계층 (비즈니스 모델)
   - 반드시 변환 메서드 (`toEntity()`) 구현

2. **Provider 순환 참조**
   - Provider가 서로 의존하면 무한 루프
   - 해결: UseCase를 중간에 두기

3. **Freezed 코드 생성 누락**
   - `build_runner` 실행 잊지 않기
   - 변경 후 항상 재생성

4. **상태 관리 불일치**
   - AsyncValue vs StateNotifier 혼용 주의
   - 비동기 데이터는 AsyncValue 사용

### 롤백 계획

Phase별 롤백 전략:
| Phase | 롤백 방법 |
|-------|----------|
| Phase 1-2 | 기존 코드 유지, 새 코드 삭제 (Domain/Data만 제거) |
| Phase 3 | 기존 Presentation 코드 복원 (Git reset) |
| Phase 4 | 테스트 실패 시 Phase 3 재검토 |

**Git 전략**:
- 각 Phase 완료 시 커밋
- Phase 3 시작 전 백업 브랜치 생성

---

## 성공 지표

### 측정 가능한 KPI

1. **구조 품질**
   - [ ] 모든 파일 100줄 이하 (821줄 → 평균 80줄)
   - [ ] 3-Layer Architecture 100% 준수
   - [ ] `package:flutter` import가 Domain에 0개

2. **테스트 커버리지**
   - [ ] UseCase 단위 테스트 60% 이상
   - [ ] 핵심 로직 테스트 통과율 100%

3. **성능**
   - [ ] 렌더링 시간 ±5% 이내 (성능 저하 없음)
   - [ ] 메모리 사용량 ±10% 이내

4. **유지보수성**
   - [ ] 새 기능 추가 시간 50% 단축 (예: 댓글 확장)
   - [ ] 코드 리뷰 시간 30% 단축

### 검증 방법

1. **구조 검증**
   ```bash
   # 100줄 초과 파일 검색
   find features/post -name "*.dart" -exec wc -l {} \; | awk '$1 > 100'

   # Domain에서 Flutter import 검색
   grep -r "package:flutter" features/post/domain/
   ```

2. **테스트 검증**
   ```bash
   flutter test --coverage
   genhtml coverage/lcov.info -o coverage/html
   ```

3. **성능 검증**
   - DevTools Timeline으로 렌더링 프레임 측정
   - Memory 탭으로 메모리 사용량 비교

4. **유지보수성 검증**
   - 새 기능 추가 시간 측정 (실제 개발 시)
   - 코드 리뷰 피드백 개수 비교

---

## 다음 단계 (Phase 6 이후)

### 확장 로드맵

1. **댓글 기능 확장** (1주)
   - Comment Domain/Data/Presentation 추가
   - Post-Comment 관계 최적화

2. **반응형 UI** (3일)
   - 이모지 반응 기능
   - 좋아요/북마크

3. **첨부파일 지원** (1주)
   - 이미지/파일 업로드
   - 미리보기 기능

4. **실시간 업데이트** (1주)
   - WebSocket 통합
   - 새 게시글 알림

### 재사용 가능성
이번 리팩터링 패턴을 다른 기능에 적용:
- **Announcement**: 동일한 구조 적용
- **Channel**: 목록 로직 재사용
- **Member**: CRUD 패턴 재사용

---

## 참고 자료

- [Clean Architecture (Robert C. Martin)](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Riverpod 공식 문서](https://riverpod.dev/)
- [Freezed 가이드](https://pub.dev/packages/freezed)
- [프로젝트 헌법](../../.specify/memory/constitution.md)
- [Frontend Architecture Guide](../frontend/architecture-guide.md)
- [구현 철학](../conventions/implementation-philosophy.md)
