import '../../domain/entities/post.dart';
import '../../domain/entities/pagination.dart';
import 'post_dto.dart';

/// 게시글 목록 응답 DTO
///
/// API 응답을 처리하여 Domain Entity로 변환합니다.
/// 백엔드가 List 또는 Page 객체를 반환하는 두 가지 경우를 모두 지원합니다.
class PostListResponseDto {
  final List<PostDto> posts;
  final int totalPages;
  final int currentPage;
  final int totalElements;
  final bool hasMore;

  const PostListResponseDto({
    required this.posts,
    required this.totalPages,
    required this.currentPage,
    required this.totalElements,
    required this.hasMore,
  });

  /// JSON에서 PostListResponseDto 객체 생성
  ///
  /// 두 가지 응답 형식 지원:
  /// 1. List 직접 반환: [PostResponse, PostResponse, ...]
  /// 2. Page 객체 반환: {content: [...], totalPages: 10, number: 0, ...}
  factory PostListResponseDto.fromJson(dynamic json) {
    // Case 1: List 직접 반환 (현재 백엔드 동작)
    if (json is List) {
      final postDtos = json
          .map((item) => PostDto.fromJson(item as Map<String, dynamic>))
          .toList();

      return PostListResponseDto(
        posts: postDtos,
        totalPages: 1,
        currentPage: 0,
        totalElements: postDtos.length,
        hasMore: false,
      );
    }

    // Case 2: Page 객체 반환 (Spring Boot 표준 Page 구조)
    final jsonMap = json as Map<String, dynamic>;
    final content = jsonMap['content'] as List<dynamic>? ?? [];
    final totalPages = jsonMap['totalPages'] as int? ?? 0;
    final currentPage = jsonMap['number'] as int? ?? 0;
    final totalElements = jsonMap['totalElements'] as int? ?? 0;
    final hasMore = (currentPage + 1) < totalPages;

    return PostListResponseDto(
      posts: content
          .map((item) => PostDto.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalPages: totalPages,
      currentPage: currentPage,
      totalElements: totalElements,
      hasMore: hasMore,
    );
  }

  /// DTO를 Domain Entity로 변환
  ///
  /// Returns: (List of Post, Pagination) 튜플
  (List<Post>, Pagination) toEntity() {
    final postEntities = posts.map((dto) => dto.toEntity()).toList();

    final pagination = Pagination(
      totalPages: totalPages,
      currentPage: currentPage,
      totalElements: totalElements,
      hasMore: hasMore,
    );

    return (postEntities, pagination);
  }
}
