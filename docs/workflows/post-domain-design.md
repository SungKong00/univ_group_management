# Post 리팩터링 Phase 0 - Domain 설계

## Domain Entity 설계

### 1. Post Entity (Freezed)
**위치**: `features/post/domain/entities/post_entity.dart`

**필드**:
- `int id` - 게시글 ID
- `String content` - 내용 (Slack 스타일, 제목 없음)
- `Author author` - 작성자 (중첩 Entity)
- `DateTime createdAt` - 작성 시각
- `DateTime? updatedAt` - 수정 시각
- `int commentCount` - 댓글 수
- `DateTime? lastCommentedAt` - 마지막 댓글 시각

**특징**:
- Freezed를 통한 불변 객체
- `copyWith()` 자동 생성
- `==` / `hashCode` 자동 생성
- JSON 직렬화는 Data Layer에서 처리

### 2. Author Entity (Freezed)
**위치**: `features/post/domain/entities/author_entity.dart`

**필드**:
- `int id` - 사용자 ID
- `String name` - 이름
- `String? profileImageUrl` - 프로필 이미지 URL

**특징**:
- 재사용 가능 (댓글, 반응 등에서도 사용)
- 불변 객체

### 3. Pagination Entity (Freezed)
**위치**: `features/post/domain/entities/pagination_entity.dart`

**필드**:
- `int totalPages` - 전체 페이지 수
- `int currentPage` - 현재 페이지
- `int totalElements` - 전체 요소 수
- `bool hasMore` - 다음 페이지 존재 여부

**특징**:
- 범용 페이지네이션 (다른 기능에서도 재사용 가능)

## Repository Interface 설계

### PostRepository (Interface)
**위치**: `features/post/domain/repositories/post_repository.dart`

**메서드**:
```dart
abstract class PostRepository {
  Future<(List<Post>, Pagination)> getPosts(String channelId, int page, int size);
  Future<Post> getPost(int postId);
  Future<Post> createPost(String channelId, String content);
  Future<Post> updatePost(int postId, String content);
  Future<void> deletePost(int postId);
}
```

**설계 원칙**:
- 도메인 용어만 사용 (HTTP, JSON 등 기술 용어 금지)
- 반환값은 Domain Entity만 (DTO/Model 금지)
- 에러 처리는 Exception/Either로 명확히 표현

## UseCase 설계

### 1. GetPostsUseCase
**위치**: `features/post/domain/usecases/get_posts_usecase.dart`

**책임**: 채널의 게시글 목록 조회
**입력**: `(String channelId, int page, int size)`
**출력**: `Future<(List<Post>, Pagination)>`

### 2. GetPostUseCase
**위치**: `features/post/domain/usecases/get_post_usecase.dart`

**책임**: 단일 게시글 상세 조회
**입력**: `int postId`
**출력**: `Future<Post>`

### 3. CreatePostUseCase
**위치**: `features/post/domain/usecases/create_post_usecase.dart`

**책임**: 새 게시글 작성
**입력**: `(String channelId, String content)`
**출력**: `Future<Post>`
**검증**: 내용 비어있지 않은지, 권한 확인 (Repository에 위임)

### 4. UpdatePostUseCase
**위치**: `features/post/domain/usecases/update_post_usecase.dart`

**책임**: 게시글 수정
**입력**: `(int postId, String content)`
**출력**: `Future<Post>`
**검증**: 내용 비어있지 않은지

### 5. DeletePostUseCase
**위치**: `features/post/domain/usecases/delete_post_usecase.dart`

**책임**: 게시글 삭제
**입력**: `int postId`
**출력**: `Future<void>`

## Data Layer 설계 (간략)

### PostModel (DTO)
**위치**: `features/post/data/models/post_model.dart`

**책임**: JSON ↔ Entity 변환
**특징**: `fromJson()`, `toJson()`, `toEntity()` 메서드 포함

### PostRemoteDataSource
**위치**: `features/post/data/datasources/post_remote_datasource.dart`

**책임**: HTTP API 호출 (DioClient 사용)
**반환**: PostModel (DTO)

### PostRepositoryImpl
**위치**: `features/post/data/repositories/post_repository_impl.dart`

**책임**: Repository Interface 구현, DataSource → Entity 변환
