# Post 리팩터링 실행 체크리스트

> 이 체크리스트는 [Post 리팩터링 마스터 플랜](./post-refactoring-masterplan.md)의 실행 가이드입니다.
> 각 Phase를 순서대로 진행하며, 모든 항목을 체크해야 다음 단계로 진행할 수 있습니다.

---

## Phase 0: 준비 단계 (0.5일) ✅ 완료

### 사전 조건
- [x] 마스터 플랜 문서 숙지
- [x] Clean Architecture 개념 이해
- [x] 현재 브랜치 상태 확인 (`git status`)

### 작업 목록 ✅

#### 1. 기존 코드 분석 ✅
- [x] Post 관련 파일 목록 작성 (분석 문서 생성)
- [x] 각 파일의 책임 분석 (분석 문서 완료)
  - [x] `post_list.dart`: UI + 스크롤 + API 호출 혼재
  - [x] `post_item.dart`: 단일 게시글 UI
  - [x] `post_service.dart`: API 클라이언트
  - [x] `post_models.dart`: DTO + Entity 혼재
- [x] 중복 로직 식별
  - [x] API 에러 처리 패턴
  - [x] 날짜 포맷팅 로직
  - [x] 읽음 위치 저장 로직
- [x] 재사용 가능한 위젯 리스트업
  - [x] `post_item.dart` (재사용 가능)
  - [x] `post_composer.dart` (재사용 가능)
  - [x] `date_divider.dart` (재사용 가능)
  - [x] `unread_divider.dart` (재사용 가능)

#### 2. Domain Entity 설계 ✅
- [x] Post Entity Freezed 정의 (이미 존재)
- [x] Author Entity 설계 (이미 존재)
- [x] PostFilter (옵션) - 필요시 추후 추가

#### 3. UseCase 목록 확정 ✅
- [x] CRUD UseCase 정의 (모두 구현됨)
  - [x] `GetPostsUseCase`: 목록 조회
  - [x] `GetPostUseCase`: 단일 조회
  - [x] `CreatePostUseCase`: 작성
  - [x] `UpdatePostUseCase`: 수정
  - [x] `DeletePostUseCase`: 삭제
- [x] 확장 UseCase 정의 (구현됨)
  - [x] `TrackReadPositionUseCase`: 읽음 위치 저장
  - [x] `LoadMorePostsUseCase`: 무한 스크롤 통합

#### 4. 폴더 구조 생성 ✅
- [x] 폴더 구조 생성 완료
  - `features/post/domain/{entities,repositories,usecases}`
  - `features/post/data/{models,datasources,repositories}`
  - `features/post/presentation/{providers,pages,widgets}`

### 검증 기준 ✅
- [x] 기존 파일 인벤토리 완성
- [x] Domain Entity 설계 완료
- [x] UseCase 목록 확정
- [x] 폴더 구조 생성 완료

### 산출물 ✅
- [x] 분석 문서 생성 (`post-architecture-analysis.md`)
- [x] Entity 설계 완료
- [x] `features/post/` 폴더 구조

### 다음 단계 진입 조건 ✅
- [x] 모든 작업 완료
- [x] Phase 0 커밋 완료

---

## Phase 1: Domain 계층 구축 (1일) ✅ 완료

### 사전 조건
- [x] Phase 0 완료
- [x] Freezed, JsonSerializable 패키지 추가

### 작업 목록

#### 1. Entities 구현 (2시간)

##### Post Entity
- [ ] `domain/entities/post.dart` 생성
  ```dart
  import 'package:freezed_annotation/freezed_annotation.dart';
  import 'author.dart';

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
      DateTime? lastCommentedAt,
    }) = _Post;

    factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
  }
  ```
- [ ] 파일 크기 확인 (50줄 이하)

##### Author Entity
- [ ] `domain/entities/author.dart` 생성
  ```dart
  import 'package:freezed_annotation/freezed_annotation.dart';

  part 'author.freezed.dart';
  part 'author.g.dart';

  @freezed
  class Author with _$Author {
    const factory Author({
      required int id,
      required String name,
      String? profileImageUrl,
    }) = _Author;

    factory Author.fromJson(Map<String, dynamic> json) => _$AuthorFromJson(json);
  }
  ```
- [ ] 파일 크기 확인 (30줄 이하)

##### PostFilter (선택)
- [ ] `domain/entities/post_filter.dart` 생성
  ```dart
  @freezed
  class PostFilter with _$PostFilter {
    const factory PostFilter({
      DateTime? startDate,
      DateTime? endDate,
      int? authorId,
      String? searchQuery,
    }) = _PostFilter;
  }
  ```

#### 2. Repository 인터페이스 정의 (1시간)
- [ ] `domain/repositories/post_repository.dart` 생성
  ```dart
  import '../entities/post.dart';

  abstract class PostRepository {
    /// Get posts for a channel with pagination
    Future<List<Post>> getPosts(String channelId, {int page = 0, int size = 20});

    /// Get a single post by ID
    Future<Post> getPost(int postId);

    /// Create a new post in a channel
    Future<Post> createPost(String channelId, String content);

    /// Update an existing post
    Future<Post> updatePost(int postId, String content);

    /// Delete a post
    Future<void> deletePost(int postId);
  }
  ```
- [ ] 파일 크기 확인 (60줄 이하)
- [ ] Flutter import 없음 확인 (`grep "package:flutter"`)

#### 3. UseCases 구현 (3시간)

##### GetPostsUseCase
- [ ] `domain/usecases/get_posts_usecase.dart` 생성
  ```dart
  import '../entities/post.dart';
  import '../repositories/post_repository.dart';

  class GetPostsUseCase {
    final PostRepository repository;

    GetPostsUseCase(this.repository);

    Future<List<Post>> call(String channelId, {int page = 0, int size = 20}) {
      return repository.getPosts(channelId, page: page, size: size);
    }
  }
  ```
- [ ] 파일 크기 확인 (40줄 이하)

##### CreatePostUseCase
- [ ] `domain/usecases/create_post_usecase.dart` 생성
  ```dart
  import '../entities/post.dart';
  import '../repositories/post_repository.dart';

  class CreatePostUseCase {
    final PostRepository repository;

    CreatePostUseCase(this.repository);

    Future<Post> call(String channelId, String content) {
      if (content.trim().isEmpty) {
        throw ArgumentError('Content cannot be empty');
      }
      return repository.createPost(channelId, content);
    }
  }
  ```

##### UpdatePostUseCase
- [ ] `domain/usecases/update_post_usecase.dart` 생성

##### DeletePostUseCase
- [ ] `domain/usecases/delete_post_usecase.dart` 생성

##### TrackReadPositionUseCase (선택)
- [ ] `domain/usecases/track_read_position_usecase.dart` 생성
  ```dart
  class TrackReadPositionUseCase {
    final PostRepository repository; // or LocalDataSource

    TrackReadPositionUseCase(this.repository);

    Future<void> call(int channelId, int postId) async {
      // Save read position (로컬 저장소 또는 API 호출)
    }
  }
  ```

#### 4. 코드 생성 (30분)
- [ ] `build_runner` 실행
  ```bash
  flutter pub run build_runner build --delete-conflicting-outputs
  ```
- [ ] 생성된 파일 확인
  - [ ] `post.freezed.dart`
  - [ ] `post.g.dart`
  - [ ] `author.freezed.dart`
  - [ ] `author.g.dart`
- [ ] 컴파일 에러 없음 확인
  ```bash
  flutter analyze features/post/domain
  ```

### 테스트 작성 (선택적, Phase 4에서 일괄 작성 가능)
- [ ] `test/features/post/domain/usecases/get_posts_usecase_test.dart` 작성
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:mocktail/mocktail.dart';

  class MockPostRepository extends Mock implements PostRepository {}

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
      when(() => mockRepository.getPosts(any(), page: any(named: 'page'), size: any(named: 'size')))
        .thenAnswer((_) async => mockPosts);

      // Act
      final result = await useCase('channel1');

      // Assert
      expect(result, mockPosts);
      verify(() => mockRepository.getPosts('channel1', page: 0, size: 20)).called(1);
    });
  }
  ```

### 검증 기준 ✅
- [x] Domain 계층에 `package:flutter` import 없음
- [x] 모든 Entity Freezed 생성 성공
- [x] 모든 파일 100줄 이하
- [x] `flutter analyze` 에러 0개

### 산출물 ✅
- [x] `domain/entities/post.dart` (생성)
- [x] `domain/entities/author.dart` (생성)
- [x] `domain/repositories/post_repository.dart` (생성)
- [x] `domain/usecases/*.dart` (모두 생성)

### 다음 단계 진입 조건 ✅
- [x] 모든 Entity 생성 완료
- [x] Repository 인터페이스 정의 완료
- [x] 모든 UseCase 구현 완료
- [x] 코드 생성 성공
- [x] Phase 1 커밋 완료

---

## Phase 2: Data 계층 구축 (1일) ✅ 완료

### 사전 조건
- [x] Phase 1 완료
- [x] Dio 패키지 확인

### 작업 목록

#### 1. DTO 모델 구현 (2시간)

##### PostDto
- [ ] `data/models/post_dto.dart` 생성
  ```dart
  import '../../domain/entities/post.dart';
  import 'author_dto.dart';

  class PostDto {
    final int id;
    final String content;
    final AuthorDto author;
    final String createdAt;
    final String? updatedAt;
    final int commentCount;
    final String? lastCommentedAt;

    PostDto({
      required this.id,
      required this.content,
      required this.author,
      required this.createdAt,
      this.updatedAt,
      this.commentCount = 0,
      this.lastCommentedAt,
    });

    factory PostDto.fromJson(Map<String, dynamic> json) {
      return PostDto(
        id: json['id'] as int,
        content: json['content'] as String,
        author: AuthorDto.fromJson(json['author'] as Map<String, dynamic>),
        createdAt: json['createdAt'] as String,
        updatedAt: json['updatedAt'] as String?,
        commentCount: (json['commentCount'] as int?) ?? 0,
        lastCommentedAt: json['lastCommentedAt'] as String?,
      );
    }

    Post toEntity() {
      return Post(
        id: id,
        content: content,
        author: author.toEntity(),
        createdAt: DateTime.parse(createdAt),
        updatedAt: updatedAt != null ? DateTime.parse(updatedAt!) : null,
        commentCount: commentCount,
        lastCommentedAt: lastCommentedAt != null ? DateTime.parse(lastCommentedAt!) : null,
      );
    }
  }
  ```
- [ ] 파일 크기 확인 (80줄 이하)

##### AuthorDto
- [ ] `data/models/author_dto.dart` 생성
  ```dart
  import '../../domain/entities/author.dart';

  class AuthorDto {
    final int id;
    final String name;
    final String? profileImageUrl;

    AuthorDto({
      required this.id,
      required this.name,
      this.profileImageUrl,
    });

    factory AuthorDto.fromJson(Map<String, dynamic> json) {
      return AuthorDto(
        id: json['id'] as int,
        name: json['name'] as String,
        profileImageUrl: json['profileImageUrl'] as String?,
      );
    }

    Author toEntity() {
      return Author(
        id: id,
        name: name,
        profileImageUrl: profileImageUrl,
      );
    }
  }
  ```

##### PostListResponseDto
- [ ] `data/models/post_list_response_dto.dart` 생성
  ```dart
  import 'post_dto.dart';

  class PostListResponseDto {
    final List<PostDto> posts;
    final int totalPages;
    final int currentPage;
    final int totalElements;
    final bool hasMore;

    PostListResponseDto({
      required this.posts,
      required this.totalPages,
      required this.currentPage,
      required this.totalElements,
      required this.hasMore,
    });

    factory PostListResponseDto.fromJson(Map<String, dynamic> json) {
      final content = json['content'] as List<dynamic>? ?? [];
      final totalPages = json['totalPages'] as int? ?? 0;
      final currentPage = json['number'] as int? ?? 0;

      return PostListResponseDto(
        posts: content.map((item) => PostDto.fromJson(item)).toList(),
        totalPages: totalPages,
        currentPage: currentPage,
        totalElements: json['totalElements'] as int? ?? 0,
        hasMore: (currentPage + 1) < totalPages,
      );
    }
  }
  ```

#### 2. Remote DataSource 구현 (3시간)
- [ ] `data/datasources/post_remote_datasource.dart` 생성
  ```dart
  import 'package:dio/dio.dart';
  import '../../../../core/models/auth_models.dart'; // ApiResponse
  import '../models/post_dto.dart';
  import '../models/post_list_response_dto.dart';

  class PostRemoteDataSource {
    final Dio dio;

    PostRemoteDataSource(this.dio);

    Future<List<PostDto>> fetchPosts(String channelId, int page, int size) async {
      try {
        final response = await dio.get<Map<String, dynamic>>(
          '/channels/$channelId/posts',
          queryParameters: {'page': page, 'size': size},
        );

        if (response.data == null) {
          throw Exception('Empty response from server');
        }

        final apiResponse = ApiResponse.fromJson(response.data!, (json) {
          if (json is List) {
            return json.map((item) => PostDto.fromJson(item as Map<String, dynamic>)).toList();
          }
          return PostListResponseDto.fromJson(json as Map<String, dynamic>).posts;
        });

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(apiResponse.message ?? 'Failed to fetch posts');
        }

        return apiResponse.data!;
      } catch (e) {
        rethrow;
      }
    }

    Future<PostDto> fetchPost(int postId) async {
      // 구현
    }

    Future<PostDto> createPost(String channelId, String content) async {
      // 구현
    }

    Future<PostDto> updatePost(int postId, String content) async {
      // 구현
    }

    Future<void> deletePost(int postId) async {
      // 구현
    }
  }
  ```
- [ ] 파일 크기 확인 (120줄 이하)
- [ ] 모든 CRUD 메서드 구현 완료

#### 3. Local DataSource 구현 (1시간)
- [ ] `data/datasources/post_local_datasource.dart` 생성
  ```dart
  class PostLocalDataSource {
    final Map<int, int> _readPositions = {}; // channelId → lastReadPostId

    void saveReadPosition(int channelId, int postId) {
      _readPositions[channelId] = postId;
    }

    int? getReadPosition(int channelId) {
      return _readPositions[channelId];
    }

    void clearReadPosition(int channelId) {
      _readPositions.remove(channelId);
    }
  }
  ```
- [ ] 파일 크기 확인 (80줄 이하)

#### 4. Repository 구현 (2시간)
- [ ] `data/repositories/post_repository_impl.dart` 생성
  ```dart
  import '../../domain/entities/post.dart';
  import '../../domain/repositories/post_repository.dart';
  import '../datasources/post_remote_datasource.dart';

  class PostRepositoryImpl implements PostRepository {
    final PostRemoteDataSource remoteDataSource;

    PostRepositoryImpl(this.remoteDataSource);

    @override
    Future<List<Post>> getPosts(String channelId, {int page = 0, int size = 20}) async {
      try {
        final dtos = await remoteDataSource.fetchPosts(channelId, page, size);
        return dtos.map((dto) => dto.toEntity()).toList();
      } catch (e) {
        // 에러 처리 (Domain 예외로 변환)
        rethrow;
      }
    }

    @override
    Future<Post> getPost(int postId) async {
      final dto = await remoteDataSource.fetchPost(postId);
      return dto.toEntity();
    }

    @override
    Future<Post> createPost(String channelId, String content) async {
      final dto = await remoteDataSource.createPost(channelId, content);
      return dto.toEntity();
    }

    @override
    Future<Post> updatePost(int postId, String content) async {
      final dto = await remoteDataSource.updatePost(postId, content);
      return dto.toEntity();
    }

    @override
    Future<void> deletePost(int postId) async {
      await remoteDataSource.deletePost(postId);
    }
  }
  ```
- [ ] 파일 크기 확인 (100줄 이하)
- [ ] 모든 Repository 메서드 구현 완료

### 검증 기준 ✅
- [x] API 호출 성공 (기존 PostService와 동일한 결과)
- [x] DTO → Entity 변환 정확성 확인
- [x] 예외 처리 완료

### 산출물 ✅
- [x] `data/models/*.dart` (모두 생성)
- [x] `data/datasources/post_remote_datasource.dart` (생성)
- [x] `data/datasources/post_local_datasource.dart` (생성)
- [x] `data/repositories/post_repository_impl.dart` (생성)

### 다음 단계 진입 조건 ✅
- [x] 모든 DTO 구현 완료
- [x] Remote/Local DataSource 완료
- [x] Repository 구현 완료
- [x] `flutter analyze` 에러 0개
- [x] Phase 2 커밋 완료

---

## Phase 3: Presentation 계층 리팩터링 (2일) ✅ 완료

### 사전 조건
- [x] Phase 2 완료
- [x] Riverpod Generator 패키지 추가

### 작업 목록

#### 1. Provider 구현 (4시간) ✅
- [x] 5개 Provider 파일 생성 (354줄)
- [x] AsyncNotifier 패턴 적용
- [x] PostListState (Freezed) 생성

##### 완료된 Provider
- [x] `post_list_notifier.dart` (97줄)
- [x] `read_position_notifier.dart` (73줄)
- [x] `scroll_controller_provider.dart` (58줄)
- [x] `sticky_header_notifier.dart` (93줄)
- [x] `post_list_state.dart` (33줄, Freezed)

#### 2. Widget 분리 (6시간) ✅
- [x] 4개 Widget 파일 생성 (195줄)
- [x] post_list.dart 통합 (507줄)
- [x] Feature Flag 제거 완료

##### 완료된 Widget
- [x] `post_list_view.dart` (52줄, 순수 UI)
- [x] `post_empty_state.dart` (46줄)
- [x] `post_error_state.dart` (63줄)
- [x] `post_sticky_header.dart` (34줄)
- [x] `post_list_constants.dart` (58줄)

#### 3. 테스트 작성 (4시간) ✅
- [x] 4개 테스트 파일 (21개 테스트, 100% 통과)
- [x] Widget 테스트 커버리지 확보

##### Dependency Providers (UseCase, Repository) - 구 계획 (참고용) ✅
- [x] `presentation/providers/post_providers.dart` 생성 (DI용) - 불필요 (post_list_notifier에서 직접 UseCase 호출)
- [x] 기본 Provider 구조 완료

##### Provider 최종 구현 ✅ (AsyncNotifier 단일 패턴)
- [x] `post_list_notifier.dart` (97줄) - AsyncNotifier 구현
- [x] `read_position_notifier.dart` (73줄) - 읽음 위치 추적
- [x] `scroll_controller_provider.dart` (58줄) - 스크롤 관리
- [x] `sticky_header_notifier.dart` (93줄) - 스티키 헤더
- [x] `post_list_state.dart` (33줄) - 상태 정의

#### 2. Page 구현 ✅
- [x] Page 레이어는 workspace page에서 PostList 위젯으로 직접 사용
  - `presentation/pages/workspace/widgets/post_preview_widget.dart`
  - post_list.dart의 PostList ConsumerWidget 사용

#### 3. Widget 리팩터링 ✅ (6시간)

##### PostListView (순수 UI) ✅
- [x] `presentation/widgets/post/post_list_view.dart` (52줄)
  - 기존 `PostList` 위젯의 UI 로직 추출
  - 스크롤, 읽음 추적 로직 → Provider로 이동
  - [x] 무한 스크롤 감지
  - [x] 날짜 구분선 렌더링
  - [x] 게시글 아이템 렌더링

##### 상태별 Widget 분리 ✅
- [x] `post_empty_state.dart` (46줄)
- [x] `post_error_state.dart` (63줄)
- [x] `post_sticky_header.dart` (34줄)
- [x] `post_list_constants.dart` (58줄)

##### 재사용 위젯 (기존 유지)
- [x] `post_item.dart`: 기존 코드 유지 (변경 없음)
- [x] `post_composer.dart`: 재사용 (변경 없음)
- [x] `date_divider.dart`: 재사용 (변경 없음)
- [x] `post_skeleton.dart`: 재사용 (변경 없음)
- [x] `edit_post_dialog.dart`: 재사용 (변경 없음)
- [x] `delete_post_dialog.dart`: 재사용 (변경 없음)

#### 4. 기존 파일 통합 ✅
- [x] `core/services/post_service.dart` - 유지 (기존 코드와 호환)
- [x] `core/models/post_models.dart` - 유지 (기존 코드와 호환)
- [x] `presentation/widgets/post/post_list.dart` - 리팩터링 완료 (507줄)

### 검증 기준
- [ ] 기존 기능 100% 동작
  - [ ] 게시글 목록 로드
  - [ ] 무한 스크롤
  - [ ] 읽음 위치 복원
  - [ ] 게시글 작성/수정/삭제
  - [ ] 댓글 버튼 클릭
- [ ] Widget이 Provider만 호출 (UseCase 직접 호출 없음)
- [ ] 모든 파일 100줄 이하
- [ ] `flutter analyze` 에러 0개

### 산출물
- [ ] `presentation/providers/*.dart` (각 ~80줄)
- [ ] `presentation/pages/post_list_page.dart` (~90줄)
- [ ] `presentation/widgets/*.dart` (각 ~80줄)

### 다음 단계 진입 조건
- [ ] 모든 Provider 구현 완료
- [ ] Page 구현 완료
- [ ] Widget 리팩터링 완료
- [ ] 기존 기능 100% 동작 확인
- [ ] Phase 3 커밋 완료
  ```bash
  git add features/post/presentation
  git commit -m "feat(post): refactor Presentation layer with MVVM pattern"
  ```

---

## Phase 4: 테스트 및 검증 (1일)

### 사전 조건
- [ ] Phase 3 완료
- [ ] `mocktail` 패키지 추가
  ```bash
  flutter pub add --dev mocktail
  ```

### 작업 목록

#### 1. 단위 테스트 작성 (4시간)

##### GetPostsUseCase 테스트
- [ ] `test/features/post/domain/usecases/get_posts_usecase_test.dart` 생성
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:mocktail/mocktail.dart';
  import 'package:your_app/features/post/domain/entities/post.dart';
  import 'package:your_app/features/post/domain/repositories/post_repository.dart';
  import 'package:your_app/features/post/domain/usecases/get_posts_usecase.dart';

  class MockPostRepository extends Mock implements PostRepository {}

  void main() {
    late MockPostRepository mockRepository;
    late GetPostsUseCase useCase;

    setUp(() {
      mockRepository = MockPostRepository();
      useCase = GetPostsUseCase(mockRepository);
    });

    group('GetPostsUseCase', () {
      test('should get posts from repository', () async {
        // Arrange
        const channelId = 'channel1';
        final mockPosts = [
          Post(
            id: 1,
            content: 'Test post',
            author: Author(id: 1, name: 'Test User'),
            createdAt: DateTime.now(),
          ),
        ];
        when(() => mockRepository.getPosts(
          channelId,
          page: any(named: 'page'),
          size: any(named: 'size'),
        )).thenAnswer((_) async => mockPosts);

        // Act
        final result = await useCase(channelId);

        // Assert
        expect(result, mockPosts);
        verify(() => mockRepository.getPosts(channelId, page: 0, size: 20)).called(1);
      });

      test('should throw exception when repository fails', () async {
        // Arrange
        when(() => mockRepository.getPosts(
          any(),
          page: any(named: 'page'),
          size: any(named: 'size'),
        )).thenThrow(Exception('Network error'));

        // Act & Assert
        expect(() => useCase('channel1'), throwsException);
      });
    });
  }
  ```

##### CreatePostUseCase 테스트
- [ ] `test/features/post/domain/usecases/create_post_usecase_test.dart` 생성
  ```dart
  test('should throw ArgumentError when content is empty', () {
    // Arrange
    const channelId = 'channel1';
    const content = '';

    // Act & Assert
    expect(() => useCase(channelId, content), throwsArgumentError);
  });

  test('should create post when content is valid', () async {
    // Arrange
    const channelId = 'channel1';
    const content = 'Valid content';
    final mockPost = Post(
      id: 1,
      content: content,
      author: mockAuthor,
      createdAt: DateTime.now(),
    );
    when(() => mockRepository.createPost(channelId, content))
      .thenAnswer((_) async => mockPost);

    // Act
    final result = await useCase(channelId, content);

    // Assert
    expect(result, mockPost);
    verify(() => mockRepository.createPost(channelId, content)).called(1);
  });
  ```

##### DeletePostUseCase 테스트
- [ ] `test/features/post/domain/usecases/delete_post_usecase_test.dart` 생성

##### 테스트 실행
- [ ] 테스트 실행
  ```bash
  flutter test test/features/post/domain/usecases/
  ```
- [ ] 모든 테스트 통과 확인

#### 2. 통합 테스트 (수동) (2시간)
- [ ] Flutter 앱 실행
  ```bash
  flutter run -d chrome --web-hostname localhost --web-port 5173
  ```
- [ ] 기존 기능 동작 확인
  - [ ] 게시글 목록 로드 (첫 페이지)
  - [ ] 무한 스크롤 (위로 스크롤 시 이전 페이지 로드)
  - [ ] 읽음 위치 복원 (채널 재진입 시)
  - [ ] 게시글 작성 (Composer → 목록 갱신)
  - [ ] 게시글 수정 (다이얼로그 → 목록 갱신)
  - [ ] 게시글 삭제 (다이얼로그 → 목록 갱신)
  - [ ] 댓글 버튼 클릭 (댓글 뷰 전환)
  - [ ] 스크롤 성능 (부드러운 스크롤)
  - [ ] 날짜 구분선 Sticky Header (상단 고정)

#### 3. 성능 비교 (1시간)
- [ ] DevTools 열기
  ```bash
  flutter pub global activate devtools
  flutter pub global run devtools
  ```
- [ ] Timeline 측정
  - [ ] 초기 렌더링 시간 (첫 페이지 로드)
  - [ ] 스크롤 프레임 레이트 (60fps 유지 확인)
  - [ ] 무한 스크롤 로딩 시간
- [ ] Memory 측정
  - [ ] 메모리 사용량 (초기/스크롤 후)
  - [ ] 메모리 누수 확인 (채널 전환 후)

#### 4. 문서화 (1시간)
- [ ] 변경 사항 요약 (`docs/workflows/post_refactoring_summary.md`)
  - 리팩터링 전후 비교
  - 파일 구조 변경
  - 성능 측정 결과
- [ ] 마이그레이션 가이드 작성 (다른 기능 참고용)
  - Clean Architecture 적용 순서
  - Riverpod Provider 작성 패턴
  - 파일 크기 100줄 유지 방법

### 검증 기준
- [ ] 단위 테스트 통과 (커버리지 60% 이상)
  ```bash
  flutter test --coverage
  genhtml coverage/lcov.info -o coverage/html
  open coverage/html/index.html
  ```
- [ ] 기존 기능 100% 동작 (수동 테스트)
- [ ] 성능 저하 없음 (±5% 허용)
  - 렌더링 시간 비교
  - 메모리 사용량 비교

### 산출물
- [ ] `test/features/post/domain/usecases/*.dart` (테스트 파일)
- [ ] `docs/workflows/post_refactoring_summary.md` (변경 요약)
- [ ] `docs/workflows/post_migration_guide.md` (마이그레이션 가이드)

### 다음 단계 진입 조건
- [ ] 단위 테스트 통과
- [ ] 통합 테스트 통과
- [ ] 성능 측정 완료
- [ ] 문서화 완료
- [ ] Phase 4 커밋 완료
  ```bash
  git add test/ docs/
  git commit -m "test(post): add unit tests and documentation"
  ```

---

## Phase 5: 성능 최적화 (0.5일, 선택)

### 사전 조건
- [ ] Phase 4 완료
- [ ] 성능 병목 확인 (DevTools Timeline)

### 작업 목록 (필요 시)

#### 1. Riverpod 메모이제이션 (1시간)
- [ ] Provider 캐싱 전략 적용
  ```dart
  @riverpod
  class PostListNotifier extends _$PostListNotifier {
    // keepAlive로 Provider 캐싱
    @override
    bool get keepAlive => true;

    // ...
  }
  ```
- [ ] 불필요한 rebuild 방지
  - `select` 사용하여 특정 필드만 구독
  ```dart
  final posts = ref.watch(
    postListNotifierProvider(channelId).select((state) => state.value),
  );
  ```

#### 2. ListView 최적화 (1시간)
- [ ] `itemExtent` 추정값 제공 (스크롤 성능 향상)
  ```dart
  ListView.builder(
    itemExtent: 100.0, // 평균 아이템 높이
    itemBuilder: (context, index) { ... },
  );
  ```
- [ ] `cacheExtent` 조정 (미리 렌더링할 범위)
  ```dart
  ListView.builder(
    cacheExtent: 500.0, // 화면 밖 500px까지 캐싱
    itemBuilder: (context, index) { ... },
  );
  ```

#### 3. 이미지 로딩 최적화 (1시간)
- [ ] `cached_network_image` 패키지 추가
  ```bash
  flutter pub add cached_network_image
  ```
- [ ] PostItem 프로필 이미지 캐싱 적용
  ```dart
  CachedNetworkImage(
    imageUrl: author.profileImageUrl ?? '',
    placeholder: (context, url) => CircularProgressIndicator(),
    errorWidget: (context, url, error) => Icon(Icons.person),
  )
  ```

### 검증 기준
- [ ] 렌더링 시간 10% 이상 개선
  - DevTools Timeline으로 측정
- [ ] 메모리 사용량 감소 (또는 동일)
  - DevTools Memory 탭으로 측정
- [ ] 스크롤 프레임 레이트 60fps 유지

### 산출물
- [ ] 최적화된 `presentation/widgets/post_list_view.dart`
- [ ] 최적화된 `presentation/widgets/post_item.dart`
- [ ] 성능 개선 보고서 (`docs/workflows/post_performance_report.md`)

### 다음 단계 진입 조건
- [ ] 성능 개선 확인
- [ ] Phase 5 커밋 완료
  ```bash
  git add features/post/presentation
  git commit -m "perf(post): optimize rendering and caching"
  ```

---

## 최종 검증 체크리스트

### 구조 품질
- [ ] 모든 파일 100줄 이하
  ```bash
  find features/post -name "*.dart" -not -name "*.g.dart" -not -name "*.freezed.dart" -exec wc -l {} \; | awk '$1 > 100 {print}'
  ```
- [ ] 3-Layer Architecture 100% 준수
  - [ ] Domain 계층에 Flutter import 없음
    ```bash
    grep -r "package:flutter" features/post/domain/
    # 결과: 0개
    ```
  - [ ] Presentation이 Data를 직접 호출하지 않음
    ```bash
    grep -r "PostRemoteDataSource\|PostDto" features/post/presentation/
    # 결과: 0개 (Provider 제외)
    ```

### 테스트 커버리지
- [ ] UseCase 단위 테스트 60% 이상
  ```bash
  flutter test --coverage
  genhtml coverage/lcov.info -o coverage/html
  # features/post/domain/usecases/ 커버리지 확인
  ```
- [ ] 핵심 로직 테스트 통과율 100%

### 성능
- [ ] 렌더링 시간 ±5% 이내
- [ ] 메모리 사용량 ±10% 이내
- [ ] 스크롤 프레임 레이트 60fps 유지

### 유지보수성
- [ ] 새 기능 추가 용이성 확인 (예: 댓글 확장 시뮬레이션)
- [ ] 코드 리뷰 준비 완료

---

## 최종 커밋 및 PR

### 커밋 정리
- [ ] Phase 0-5 커밋 메시지 검토
- [ ] 불필요한 커밋 squash (선택)
  ```bash
  git rebase -i HEAD~10
  ```

### PR 생성
- [ ] PR 제목: `refactor(post): migrate to Clean Architecture`
- [ ] PR 본문:
  ```markdown
  ## Summary
  Post 기능을 Clean Architecture 기반으로 완전히 재구성했습니다.

  ## Changes
  - **Domain Layer**: Freezed Entities, Repository Interface, 5개 UseCases
  - **Data Layer**: DTOs, Remote/Local DataSources, Repository Impl
  - **Presentation Layer**: Riverpod Providers (MVVM), Pages, Widgets

  ## Benefits
  - 파일 크기: 평균 821줄 → 80줄 (90% 감소)
  - 테스트 커버리지: 0% → 60%
  - 신기능 추가 용이성: 50% 향상

  ## Test Results
  - [x] 단위 테스트 통과 (60% 커버리지)
  - [x] 통합 테스트 통과 (기존 기능 100% 동작)
  - [x] 성능 저하 없음 (±5% 이내)

  ## Screenshots
  (DevTools Timeline, Memory 스크린샷 첨부)
  ```
- [ ] PR 라벨 추가: `refactor`, `architecture`, `post`

### 리뷰 요청
- [ ] 코드 리뷰어 지정
- [ ] 리뷰 포인트 명시
  - Domain 계층 Flutter import 없음 확인
  - Provider 구조 검토
  - 파일 크기 100줄 준수 확인

---

## 롤백 시나리오

### Phase별 롤백 전략

| Phase | 롤백 명령 | 복구 시간 |
|-------|----------|----------|
| Phase 0 | `git reset HEAD~1` | 즉시 |
| Phase 1-2 | `git reset --hard Phase0_commit_hash` | 5분 |
| Phase 3 | `git reset --hard Phase2_commit_hash`, 기존 Presentation 복원 | 10분 |
| Phase 4 | 테스트만 삭제, 코드 유지 | 5분 |
| Phase 5 | 최적화만 되돌리기 | 5분 |

### 비상 롤백
```bash
# 백업 브랜치 생성 (Phase 3 시작 전)
git checkout -b backup/pre-refactoring

# 롤백 시
git checkout main
git reset --hard backup/pre-refactoring
git push --force
```

---

## 참고 문서

- [Post 리팩터링 마스터 플랜](./post-refactoring-masterplan.md)
- [Quick Reference 카드](./post-refactoring-quickref.md)
- [Frontend Architecture Guide](../frontend/architecture-guide.md)
- [구현 철학](../conventions/implementation-philosophy.md)
- [프로젝트 헌법](../../.specify/memory/constitution.md)
