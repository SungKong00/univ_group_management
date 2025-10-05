// 댓글 관련 데이터 모델
//
// 게시글의 댓글 시스템을 위한 모델 정의
// depth: 0=최상위 댓글, 1=대댓글 (최대 2단계)

class Comment {
  final int id;
  final int postId;
  final String content;
  final int authorId;
  final String authorName;
  final String? authorProfileUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int depth;
  final int? parentCommentId;

  const Comment({
    required this.id,
    required this.postId,
    required this.content,
    required this.authorId,
    required this.authorName,
    this.authorProfileUrl,
    required this.createdAt,
    this.updatedAt,
    this.depth = 0,
    this.parentCommentId,
  });

  /// JSON → Comment 변환
  factory Comment.fromJson(Map<String, dynamic> json) {
    // 백엔드 응답: author는 중첩된 객체 {id, name, email, profileImageUrl}
    final author = json['author'] as Map<String, dynamic>?;

    return Comment(
      id: (json['id'] as num).toInt(),
      postId: (json['postId'] as num).toInt(),
      content: json['content'] as String,
      // author 객체에서 필드 추출, null일 경우 기본값 사용
      authorId: (author?['id'] as num?)?.toInt() ?? 0,
      authorName: author?['name'] as String? ?? 'Unknown',
      authorProfileUrl: author?['profileImageUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      depth: 0, // 백엔드에서 제공하지 않으므로 항상 0
      parentCommentId: (json['parentCommentId'] as num?)?.toInt(),
    );
  }

  /// Comment → JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'authorProfileUrl': authorProfileUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'depth': depth,
      'parentCommentId': parentCommentId,
    };
  }

  /// 불변 객체 복사
  Comment copyWith({
    int? id,
    int? postId,
    String? content,
    int? authorId,
    String? authorName,
    String? authorProfileUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? depth,
    int? parentCommentId,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorProfileUrl: authorProfileUrl ?? this.authorProfileUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      depth: depth ?? this.depth,
      parentCommentId: parentCommentId ?? this.parentCommentId,
    );
  }
}

/// 댓글 작성 요청
class CreateCommentRequest {
  final String content;
  final int? parentCommentId;

  const CreateCommentRequest({
    required this.content,
    this.parentCommentId,
  });

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      if (parentCommentId != null) 'parentCommentId': parentCommentId,
    };
  }
}
