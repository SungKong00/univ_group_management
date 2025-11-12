import 'date_marker.dart';
import 'post_models.dart';

/// PostListItem - 게시글 목록 아이템 타입 정의
///
/// PostList 위젯의 Flat List에서 사용되는 아이템들의 공통 타입
/// Type Safety를 위한 sealed class 패턴 적용
///
/// 사용 예시:
/// ```dart
/// List<PostListItem> _flatItems = [];
///
/// // 타입 안전한 패턴 매칭
/// switch (item) {
///   case DateMarkerWrapper(:final marker):
///     // DateMarker 처리
///   case PostWrapper(:final post):
///     // Post 처리
/// }
/// ```
sealed class PostListItem {
  const PostListItem();
}

/// DateMarker 래퍼 - 날짜 구분선을 위한 타입
final class DateMarkerWrapper extends PostListItem {
  final DateMarker marker;

  const DateMarkerWrapper(this.marker);
}

/// Post 래퍼 - 게시글 아이템을 위한 타입
final class PostWrapper extends PostListItem {
  final Post post;

  const PostWrapper(this.post);
}