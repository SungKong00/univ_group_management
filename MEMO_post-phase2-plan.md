# Post 리팩터링 Phase 2 - Data Layer 구현 계획

> **작성일**: 2025-11-18
> **브랜치**: `014-post-clean-architecture-migration`
> **의존성**: Phase 1 Domain Layer 완료 (커밋: `50a4675`)

---

## 📋 Phase 2 목표

**Data Layer 구현**: Domain Layer와 외부 API 간의 다리 역할을 하는 계층

1. DTOs 생성 (JSON ↔ Dart 변환)
2. DataSource 구현 (API 통신)
3. Repository 구현 (DTO → Entity 변환, 에러 처리)

---

## 🔍 기존 코드 분석 결과

### 현재 상태
- **기존 Model**: `core/models/post_models.dart` (147줄)
  - `Post` 클래스: JSON 파싱, toJson(), copyWith()
  - `PostListResponse` 클래스: Spring Boot Page 응답 처리
  - `CreatePostRequest` 클래스: 작성 요청

- **기존 Service**: `core/services/post_service.dart` (219줄)
  - Singleton 패턴
  - DioClient 사용
  - ApiResponse<T> 래핑
  - 5개 메서드: fetchPosts, createPost, getPost, updatePost, deletePost

### API 응답 구조 (백엔드)
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "content": "게시글 내용",
      "author": {
        "id": 123,
        "name": "홍길동",
        "profileImageUrl": "https://..."
      },
      "createdAt": "2025-11-18T10:00:00",
      "updatedAt": "2025-11-18T11:00:00",
      "commentCount": 5,
      "lastCommentedAt": "2025-11-18T12:00:00"
    }
  ],
  "message": null,
  "errorCode": null
}
```

### Phase 1 Domain Entity 구조
- **Post Entity** (Freezed): id, content, author, createdAt, updatedAt, commentCount, lastCommentedAt
- **Author Entity** (Freezed): id, name, profileImageUrl
- **Pagination Entity** (Freezed): totalPages, currentPage, totalElements, hasMore
- **Repository Interface**: 5개 메서드 (getPosts, getPost, createPost, updatePost, deletePost)

---

## 🏗️ Data Layer 설계

### 폴더 구조
```
features/post/data/
├── models/
│   ├── post_dto.dart              (~80줄) - Post DTO + toEntity()
│   ├── author_dto.dart            (~40줄) - Author DTO + toEntity()
│   └── post_list_response_dto.dart  (~70줄) - 페이지네이션 응답
├── datasources/
│   └── post_remote_datasource.dart  (~100줄) - Dio 기반 API 클라이언트
└── repositories/
    └── post_repository_impl.dart    (~100줄) - Repository 구현
```

---

## 📝 구현 세부 계획

### Task 1: DTOs 생성 (models/)

#### 1.1 AuthorDto (40줄)
**파일**: `features/post/data/models/author_dto.dart`

**필드**:
- `int id`
- `String name`
- `String? profileImageUrl`

**메서드**:
- `factory AuthorDto.fromJson(Map<String, dynamic> json)`
- `Map<String, dynamic> toJson()`
- `Author toEntity()` - Domain Entity 변환

**변환 로직**:
```dart
Author toEntity() => Author(
  id: id,
  name: name,
  profileImageUrl: profileImageUrl,
);
```

**참고**:
- Freezed 사용하지 않음 (DTO는 JSON 변환만 담당)
- 기존 `post_models.dart`의 author 중첩 객체 파싱 로직 재사용

---

#### 1.2 PostDto (80줄)
**파일**: `features/post/data/models/post_dto.dart`

**필드**:
- `int id`
- `String content`
- `AuthorDto author` (중첩 DTO)
- `String createdAt` (ISO 8601 문자열)
- `String? updatedAt`
- `int commentCount`
- `String? lastCommentedAt`

**메서드**:
- `factory PostDto.fromJson(Map<String, dynamic> json)`
- `Map<String, dynamic> toJson()`
- `Post toEntity()` - Domain Entity 변환

**변환 로직**:
```dart
Post toEntity() => Post(
  id: id,
  content: content,
  author: author.toEntity(),
  createdAt: DateTime.parse(createdAt),
  updatedAt: updatedAt != null ? DateTime.parse(updatedAt!) : null,
  commentCount: commentCount,
  lastCommentedAt: lastCommentedAt != null ? DateTime.parse(lastCommentedAt!) : null,
);
```

**참고**:
- 기존 `Post.fromJson()` 로직 참조
- author 필드 null 처리 (백엔드 응답에 포함됨)

---

#### 1.3 PostListResponseDto (70줄)
**파일**: `features/post/data/models/post_list_response_dto.dart`

**필드**:
- `List<PostDto> content` (Spring Boot Page의 content)
- `int totalPages`
- `int number` (currentPage)
- `int totalElements`

**메서드**:
- `factory PostListResponseDto.fromJson(Map<String, dynamic> json)`
- `Map<String, dynamic> toJson()`
- `(List<Post>, Pagination) toEntity()` - Domain Entity 변환 (Records 반환)

**변환 로직**:
```dart
(List<Post>, Pagination) toEntity() => (
  content.map((dto) => dto.toEntity()).toList(),
  Pagination(
    totalPages: totalPages,
    currentPage: number,
    totalElements: totalElements,
    hasMore: (number + 1) < totalPages,
  ),
);
```

**참고**:
- 기존 `PostListResponse.fromJson()` 로직 참조
- Spring Boot Page 응답 구조 처리
- 백엔드가 List 직접 반환하는 경우 대응 (service 참조)

---

### Task 2: DataSource 구현 (datasources/)

#### 2.1 PostRemoteDataSource (100줄)
**파일**: `features/post/data/datasources/post_remote_datasource.dart`

**책임**: HTTP API 호출, ApiResponse 파싱, DTO 반환

**의존성**:
- `DioClient` (기존 core/network/dio_client.dart)
- `ApiResponse<T>` (기존 core/models/auth_models.dart)

**메서드**:
1. `Future<PostListResponseDto> fetchPosts(String channelId, int page, int size)`
   - GET `/channels/{channelId}/posts?page={page}&size={size}`
   - ApiResponse<List> 파싱 (백엔드가 List 직접 반환)
   - PostListResponseDto 생성 (페이지네이션 정보 없으면 기본값)

2. `Future<PostDto> fetchPost(int postId)`
   - GET `/posts/{postId}`
   - ApiResponse<Map> 파싱

3. `Future<PostDto> createPost(String channelId, String content)`
   - POST `/channels/{channelId}/posts`
   - body: `{"content": "..."}`
   - ApiResponse<Map> 파싱

4. `Future<PostDto> updatePost(int postId, String content)`
   - PUT `/posts/{postId}`
   - body: `{"content": "..."}`
   - ApiResponse<Map> 파싱

5. `Future<void> deletePost(int postId)`
   - DELETE `/posts/{postId}`
   - ApiResponse<null> 파싱

**에러 처리**:
- ApiResponse.success == false → Exception 발생
- Dio 예외 → rethrow
- developer.log 사용 (기존 post_service.dart 패턴)

**참고**:
- 기존 `PostService`의 메서드 시그니처 유지
- Singleton 패턴 사용하지 않음 (Riverpod Provider로 주입)
- 백엔드가 List 직접 반환하는 경우 대응 (service 26-48줄 참조)

---

### Task 3: Repository 구현 (repositories/)

#### 3.1 PostRepositoryImpl (100줄)
**파일**: `features/post/data/repositories/post_repository_impl.dart`

**책임**: Repository Interface 구현, DTO → Entity 변환, 에러 처리

**의존성**:
- `PostRepository` (Domain interface)
- `PostRemoteDataSource`

**메서드**:
1. `Future<(List<Post>, Pagination)> getPosts(String channelId, {int page = 0, int size = 20})`
   - remoteDataSource.fetchPosts() 호출
   - dto.toEntity() 변환
   - Exception 발생 시 rethrow

2. `Future<Post> getPost(int postId)`
   - remoteDataSource.fetchPost() 호출
   - dto.toEntity() 변환

3. `Future<Post> createPost(String channelId, String content)`
   - remoteDataSource.createPost() 호출
   - dto.toEntity() 변환

4. `Future<Post> updatePost(int postId, String content)`
   - remoteDataSource.updatePost() 호출
   - dto.toEntity() 변환

5. `Future<void> deletePost(int postId)`
   - remoteDataSource.deletePost() 호출
   - 반환값 없음

**에러 처리**:
- DataSource에서 발생한 Exception 전파
- 추가적인 비즈니스 예외는 없음 (도메인 로직은 UseCase에서 처리)

**참고**:
- Clean Architecture 패턴 준수
- 계층 의존성: Repository → DataSource → Dio

---

## 🔄 마이그레이션 전략

### 기존 코드 처리
1. **core/models/post_models.dart** (147줄)
   - Phase 3에서 삭제 예정
   - 현재는 유지 (기존 코드가 참조 중)

2. **core/services/post_service.dart** (219줄)
   - Phase 3에서 삭제 예정
   - 현재는 유지 (기존 Provider가 참조 중)

### 단계별 전환
- **Phase 2**: Data Layer 구현 (기존 코드와 공존)
- **Phase 3**: Presentation Layer 리팩터링 → 기존 코드 참조 제거 → 삭제

---

## ✅ 검증 기준

### 코드 품질
```bash
# 1. 분석 통과
flutter analyze lib/features/post/data/

# 2. 파일 크기 확인 (100줄 이하)
wc -l lib/features/post/data/**/*.dart

# 3. 계층 의존성 확인 (Data → Domain, Flutter 의존성 없음)
grep -r "package:flutter" lib/features/post/data/
# 결과: 0개 (분석 제외)
```

### 기능 검증
```dart
// DataSource 단위 테스트 (선택)
test('fetchPosts returns PostListResponseDto', () async {
  final dataSource = PostRemoteDataSource(DioClient());
  final result = await dataSource.fetchPosts('channel-1', 0, 20);
  expect(result, isA<PostListResponseDto>());
});

// Repository 통합 테스트 (선택)
test('getPosts returns Posts and Pagination', () async {
  final repository = PostRepositoryImpl(PostRemoteDataSource(DioClient()));
  final (posts, pagination) = await repository.getPosts('channel-1');
  expect(posts, isA<List<Post>>());
  expect(pagination, isA<Pagination>());
});
```

### 문서 동기화
- [ ] `docs/workflows/post-phase2-completion.md` 작성
- [ ] `docs/workflows/post-refactoring-quickref.md` 업데이트
- [ ] Phase 1 완료 보고서 참조 링크 추가

---

## 📅 예상 소요 시간

| Task | 예상 시간 | 비고 |
|------|----------|------|
| DTOs 생성 (3개) | 1시간 | fromJson, toJson, toEntity |
| DataSource 구현 | 1.5시간 | 5개 메서드, 에러 처리 |
| Repository 구현 | 1시간 | 5개 메서드, 변환 로직 |
| 검증 및 테스트 | 0.5시간 | 분석, 파일 크기, 의존성 체크 |
| **총계** | **4시간** | |

---

## 🚨 주의사항

### 1. 백엔드 응답 구조 대응
- **List 직접 반환**: `post_service.dart` 34-45줄 패턴 참조
- **Page 객체 반환**: `post_models.dart` 112-125줄 패턴 참조
- PostListResponseDto에서 두 경우 모두 처리

### 2. Null 안정성
- Author 필드 null 처리 (post_models.dart 32-40줄)
- DateTime 파싱 예외 처리 (updatedAt, lastCommentedAt)

### 3. 파일 크기 제한
- 각 파일 100줄 이하 유지
- DTO는 변환 로직만 포함 (비즈니스 로직 금지)

### 4. 계층 의존성 준수
- Data Layer는 Domain Layer만 의존
- Flutter import 금지 (분석 도구 제외)

---

## 📚 참고 문서

- [Phase 1 완료 보고서](./post-phase1-completion.md)
- [Domain 설계 명세](./post-domain-design.md)
- [Quick Reference](./post-refactoring-quickref.md)
- [Architecture Guide](../frontend/architecture-guide.md)
- [프로젝트 헌법](.specify/memory/constitution.md)

---

## 🎯 다음 단계 (Phase 3 Preview)

Phase 2 완료 후:
1. Riverpod Providers 생성 (DI)
2. Presentation Layer 리팩터링 (MVVM)
3. 기존 코드 삭제 (post_models.dart, post_service.dart)
4. 통합 테스트
