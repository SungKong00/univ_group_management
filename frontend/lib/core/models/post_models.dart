// 게시글 관련 데이터 모델
//
// 워크스페이스 채널 내 게시글 시스템을 위한 모델 정의
// Slack 스타일 메시지 형식 (제목 없음, 연속 흐름)

class Post {
  final int id;
  final String content;
  final int authorId;
  final String authorName;
  final String? authorProfileUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int commentCount;
  final DateTime? lastCommentedAt;

  const Post({
    required this.id,
    required this.content,
    required this.authorId,
    required this.authorName,
    this.authorProfileUrl,
    required this.createdAt,
    this.updatedAt,
    this.commentCount = 0,
    this.lastCommentedAt,
  });

  /// JSON → Post 변환
  factory Post.fromJson(Map<String, dynamic> json) {
    // 백엔드 응답: author는 중첩된 객체 {id, name, email, profileImageUrl}
    final author = json['author'] as Map<String, dynamic>?;

    return Post(
      id: (json['id'] as num).toInt(),
      content: json['content'] as String,
      // author 객체에서 필드 추출, null일 경우 기본값 사용
      authorId: (author?['id'] as num?)?.toInt() ?? 0,
      authorName: author?['name'] as String? ?? 'Unknown',
      authorProfileUrl: author?['profileImageUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
      lastCommentedAt: json['lastCommentedAt'] != null
          ? DateTime.parse(json['lastCommentedAt'] as String)
          : null,
    );
  }

  /// Post → JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'authorProfileUrl': authorProfileUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'commentCount': commentCount,
      'lastCommentedAt': lastCommentedAt?.toIso8601String(),
    };
  }

  /// 불변 객체 복사 (일부 필드 변경)
  Post copyWith({
    int? id,
    String? content,
    int? authorId,
    String? authorName,
    String? authorProfileUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? commentCount,
    DateTime? lastCommentedAt,
  }) {
    return Post(
      id: id ?? this.id,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorProfileUrl: authorProfileUrl ?? this.authorProfileUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      commentCount: commentCount ?? this.commentCount,
      lastCommentedAt: lastCommentedAt ?? this.lastCommentedAt,
    );
  }
}

/// 게시글 목록 응답 (페이지네이션)
class PostListResponse {
  final List<Post> posts;
  final int totalPages;
  final int currentPage;
  final int totalElements;
  final bool hasMore;

  const PostListResponse({
    required this.posts,
    required this.totalPages,
    required this.currentPage,
    required this.totalElements,
    required this.hasMore,
  });

  /// JSON → PostListResponse 변환
  factory PostListResponse.fromJson(Map<String, dynamic> json) {
    // Spring Boot Page 응답 구조 처리
    final content = json['content'] as List<dynamic>? ?? [];
    final totalPages = json['totalPages'] as int? ?? 0;
    final currentPage = json['number'] as int? ?? 0;
    final totalElements = json['totalElements'] as int? ?? 0;
    final hasMore = (currentPage + 1) < totalPages;

    return PostListResponse(
      posts: content.map((item) => Post.fromJson(item)).toList(),
      totalPages: totalPages,
      currentPage: currentPage,
      totalElements: totalElements,
      hasMore: hasMore,
    );
  }

  /// PostListResponse → JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'content': posts.map((post) => post.toJson()).toList(),
      'totalPages': totalPages,
      'number': currentPage,
      'totalElements': totalElements,
    };
  }
}

/// 게시글 작성 요청
class CreatePostRequest {
  final String content;

  const CreatePostRequest({
    required this.content,
  });

  Map<String, dynamic> toJson() {
    return {
      'content': content,
    };
  }
}
