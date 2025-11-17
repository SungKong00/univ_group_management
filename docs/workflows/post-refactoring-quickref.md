# Post 리팩터링 Quick Reference

> 개발 중 빠른 참조를 위한 한 페이지 요약
> 상세 내용: [마스터 플랜](./post-refactoring-masterplan.md) | [체크리스트](./post-refactoring-checklist.md)

---

## 폴더 구조 다이어그램

```
features/post/
├── domain/                         # 비즈니스 로직 (Flutter 의존성 ❌)
│   ├── entities/
│   │   ├── post.dart              # Freezed Entity (~50줄)
│   │   ├── author.dart            # Freezed Entity (~30줄)
│   │   └── post_filter.dart       # (선택) 필터 조건
│   ├── repositories/
│   │   └── post_repository.dart   # 추상 인터페이스 (~60줄)
│   └── usecases/
│       ├── get_posts_usecase.dart         # 목록 조회 (~40줄)
│       ├── create_post_usecase.dart       # 작성 (~30줄)
│       ├── update_post_usecase.dart       # 수정 (~30줄)
│       ├── delete_post_usecase.dart       # 삭제 (~30줄)
│       └── track_read_position_usecase.dart  # 읽음 추적 (~50줄)
│
├── data/                           # 데이터 접근 (API, 캐시)
│   ├── models/
│   │   ├── post_dto.dart          # API 응답 DTO (~80줄)
│   │   ├── author_dto.dart        # (~40줄)
│   │   └── post_list_response_dto.dart  # 페이지네이션 (~60줄)
│   ├── datasources/
│   │   ├── post_remote_datasource.dart  # Dio API 클라이언트 (~120줄)
│   │   └── post_local_datasource.dart   # 읽음 위치 캐시 (~80줄)
│   └── repositories/
│       └── post_repository_impl.dart    # Repository 구현 (~100줄)
│
└── presentation/                   # UI (MVVM 패턴)
    ├── providers/
    │   ├── post_providers.dart           # DI Providers (~80줄)
    │   ├── post_list_provider.dart       # 목록 ViewModel (~80줄)
    │   ├── post_detail_provider.dart     # 상세 ViewModel (~60줄)
    │   └── read_position_provider.dart   # 읽음 추적 ViewModel (~70줄)
    ├── pages/
    │   └── post_list_page.dart           # 순수 조립 (~90줄)
    └── widgets/
        ├── post_list_view.dart           # 순수 UI (~100줄)
        ├── post_item.dart                # 단일 게시글 (재사용)
        ├── post_composer.dart            # 작성 위젯 (재사용)
        ├── date_divider.dart             # 날짜 구분선 (재사용)
        ├── unread_divider.dart           # 읽지 않은 표시 (재사용)
        ├── post_skeleton.dart            # 로딩 스켈레톤 (재사용)
        └── edit_post_dialog.dart         # 수정 다이얼로그 (재사용)
```

---

## 파일 명명 규칙

| 타입 | 규칙 | 예시 |
|------|------|------|
| **Entity** | `{도메인명}.dart` | `post.dart` |
| **DTO** | `{도메인명}_dto.dart` | `post_dto.dart` |
| **Repository 인터페이스** | `{도메인명}_repository.dart` | `post_repository.dart` |
| **Repository 구현** | `{도메인명}_repository_impl.dart` | `post_repository_impl.dart` |
| **UseCase** | `{동사}_{도메인명}_usecase.dart` | `get_posts_usecase.dart` |
| **DataSource** | `{도메인명}_{종류}_datasource.dart` | `post_remote_datasource.dart` |
| **Provider** | `{도메인명}_{상태}_provider.dart` | `post_list_provider.dart` |
| **Page** | `{도메인명}_{역할}_page.dart` | `post_list_page.dart` |
| **Widget** | `{도메인명}_{역할}.dart` | `post_list_view.dart` |

---

## 자주 사용하는 코드 패턴

### 1. Freezed Entity 정의 (Domain)
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'post.freezed.dart';
part 'post.g.dart';

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

### 2. Repository 인터페이스 (Domain)
```dart
abstract class PostRepository {
  Future<List<Post>> getPosts(String channelId, {int page, int size});
  Future<Post> createPost(String channelId, String content);
}
```

### 3. UseCase 구현 (Domain)
```dart
class GetPostsUseCase {
  final PostRepository repository;
  GetPostsUseCase(this.repository);

  Future<List<Post>> call(String channelId, {int page = 0}) {
    return repository.getPosts(channelId, page: page, size: 20);
  }
}
```

### 4. DTO → Entity 변환 (Data)
```dart
class PostDto {
  final int id;
  final String content;
  final AuthorDto author;
  final String createdAt;

  PostDto.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      content = json['content'],
      author = AuthorDto.fromJson(json['author']),
      createdAt = json['createdAt'];

  Post toEntity() => Post(
    id: id,
    content: content,
    author: author.toEntity(),
    createdAt: DateTime.parse(createdAt),
  );
}
```

### 5. Remote DataSource (Data)
```dart
class PostRemoteDataSource {
  final Dio dio;
  PostRemoteDataSource(this.dio);

  Future<List<PostDto>> fetchPosts(String channelId, int page, int size) async {
    final response = await dio.get('/channels/$channelId/posts', queryParameters: {'page': page, 'size': size});
    final apiResponse = ApiResponse.fromJson(response.data!, (json) => /* DTO 변환 */);
    return apiResponse.data!;
  }
}
```

### 6. Repository 구현 (Data)
```dart
class PostRepositoryImpl implements PostRepository {
  final PostRemoteDataSource remoteDataSource;
  PostRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<Post>> getPosts(String channelId, {int page = 0, int size = 20}) async {
    final dtos = await remoteDataSource.fetchPosts(channelId, page, size);
    return dtos.map((dto) => dto.toEntity()).toList();
  }
}
```

### 7. Riverpod Provider (Presentation - DI)
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'post_providers.g.dart';

@riverpod
PostRepository postRepository(PostRepositoryRef ref) {
  final remoteDataSource = ref.watch(postRemoteDataSourceProvider);
  return PostRepositoryImpl(remoteDataSource);
}

@riverpod
GetPostsUseCase getPostsUseCase(GetPostsUseCaseRef ref) {
  return GetPostsUseCase(ref.watch(postRepositoryProvider));
}
```

### 8. Riverpod Notifier (Presentation - ViewModel)
```dart
@riverpod
class PostListNotifier extends _$PostListNotifier {
  int _currentPage = 0;
  bool _hasMore = true;

  @override
  FutureOr<List<Post>> build(String channelId) async {
    _currentPage = 0;
    _hasMore = true;
    final useCase = ref.read(getPostsUseCaseProvider);
    return useCase(channelId, page: _currentPage);
  }

  Future<void> loadMore() async {
    if (!_hasMore || state.isLoading) return;
    state = const AsyncValue.loading();
    _currentPage++;
    final useCase = ref.read(getPostsUseCaseProvider);
    final newPosts = await useCase(channelId, page: _currentPage);
    state = AsyncValue.data([...state.value ?? [], ...newPosts]);
  }
}
```

### 9. Page (Presentation - View)
```dart
class PostListPage extends ConsumerWidget {
  final String channelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(postListNotifierProvider(channelId));
    return posts.when(
      data: (data) => PostListView(posts: data, onLoadMore: () => ref.read(postListNotifierProvider(channelId).notifier).loadMore()),
      loading: () => const PostSkeleton(),
      error: (err, _) => ErrorView(error: err),
    );
  }
}
```

---

## 핵심 체크포인트

### ✅ 계층 의존성 확인
```bash
# Domain에 Flutter import 없음
grep -r "package:flutter" features/post/domain/
# 결과: 0개

# Presentation이 Data 직접 호출 없음
grep -r "PostDto\|PostRemoteDataSource" features/post/presentation/
# 결과: 0개 (Provider 파일 제외)
```

### ✅ 파일 크기 확인
```bash
# 100줄 초과 파일 검색
find features/post -name "*.dart" -not -name "*.g.dart" -not -name "*.freezed.dart" -exec wc -l {} \; | awk '$1 > 100 {print}'
# 결과: 0개
```

### ✅ 코드 생성
```bash
# Freezed + Riverpod 코드 생성
flutter pub run build_runner build --delete-conflicting-outputs

# 생성된 파일 확인
ls features/post/domain/entities/*.freezed.dart
ls features/post/presentation/providers/*.g.dart
```

### ✅ 테스트 실행
```bash
# 단위 테스트
flutter test test/features/post/domain/usecases/

# 커버리지 측정
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### ✅ 분석
```bash
# Lint 검사
flutter analyze features/post/

# 결과: 0 issues found
```

---

## 단계별 요약 (6일 계획)

| Day | Phase | 핵심 작업 |
|-----|-------|----------|
| **0.5** | Phase 0 | 📋 기존 코드 분석 + 폴더 구조 생성 |
| **1** | Phase 1 | 🏛️ Domain 계층 (Entities, Repository, UseCases) |
| **2** | Phase 2 | 💾 Data 계층 (DTOs, DataSources, Repository Impl) |
| **3-4** | Phase 3 | 🎨 Presentation 계층 (Providers, Pages, Widgets) |
| **5** | Phase 4 | ✅ 테스트 + 검증 (단위/통합 테스트, 성능 측정) |
| **5.5** | Phase 5 | 🚀 성능 최적화 (선택) |

---

## 자주 하는 실수 방지

### ❌ 금지 사항
1. **계층 위반**
   ```dart
   // ❌ Presentation → Data 직접 호출
   final posts = await PostRemoteDataSource(dio).fetchPosts(channelId);

   // ✅ Presentation → Domain (UseCase)
   final posts = await ref.read(getPostsUseCaseProvider)(channelId);
   ```

2. **거대한 Provider**
   ```dart
   // ❌ 모든 Post 로직을 하나의 Provider에
   class MegaPostProvider { /* 500줄 */ }

   // ✅ 기능별 Provider 분리
   PostListNotifier, PostDetailNotifier, ReadPositionNotifier
   ```

3. **Widget에 비즈니스 로직**
   ```dart
   // ❌ Widget 내부에서 API 호출
   class PostListView extends StatelessWidget {
     void _loadPosts() async {
       final response = await dio.get('/posts');
       // ...
     }
   }

   // ✅ Provider에서 처리
   ref.read(postListNotifierProvider(channelId).notifier).loadMore();
   ```

4. **DTO와 Entity 혼동**
   ```dart
   // ❌ Domain에서 DTO 사용
   class GetPostsUseCase {
     Future<List<PostDto>> call() { /* ... */ }
   }

   // ✅ Domain은 Entity만
   class GetPostsUseCase {
     Future<List<Post>> call() { /* ... */ }
   }
   ```

5. **Freezed 코드 생성 누락**
   ```bash
   # Entity 변경 후 항상 재생성
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

---

## 빠른 명령어

### 코드 생성
```bash
# Freezed + Riverpod 코드 생성
flutter pub run build_runner build --delete-conflicting-outputs

# watch 모드 (변경 시 자동 생성)
flutter pub run build_runner watch --delete-conflicting-outputs
```

### 테스트
```bash
# 단위 테스트 실행
flutter test test/features/post/domain/usecases/

# 커버리지 측정
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### 분석
```bash
# Lint 검사
flutter analyze features/post/

# 파일 크기 검사
find features/post -name "*.dart" -not -name "*.g.dart" -not -name "*.freezed.dart" -exec wc -l {} \; | sort -rn | head -10
```

### Git
```bash
# Phase별 커밋
git add features/post/domain
git commit -m "feat(post): implement Domain layer"

git add features/post/data
git commit -m "feat(post): implement Data layer"

git add features/post/presentation
git commit -m "feat(post): refactor Presentation layer with MVVM"
```

---

## 성공 기준

### 구조 품질
- [ ] 모든 파일 100줄 이하
- [ ] Domain에 `package:flutter` import 0개
- [ ] 3-Layer Architecture 완벽 준수

### 테스트
- [ ] UseCase 단위 테스트 60% 커버리지
- [ ] 통합 테스트 100% 통과

### 성능
- [ ] 렌더링 시간 ±5% 이내
- [ ] 메모리 사용량 ±10% 이내
- [ ] 스크롤 60fps 유지

### 유지보수성
- [ ] 새 기능 추가 시간 50% 단축 (예: 댓글 확장)
- [ ] 코드 리뷰 시간 30% 단축

---

## 참고 자료

- [마스터 플랜](./post-refactoring-masterplan.md) - 전체 계획 및 상세 설명
- [체크리스트](./post-refactoring-checklist.md) - Phase별 실행 가이드
- [Architecture Guide](../frontend/architecture-guide.md) - Clean Architecture 원칙
- [구현 철학](../conventions/implementation-philosophy.md) - 코드 구조 설계 원칙
- [프로젝트 헌법](../../.specify/memory/constitution.md) - 3-Layer Architecture 규칙
