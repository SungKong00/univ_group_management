import '../models/post_models.dart';

/// Helper utilities for managing read positions in channels
class ReadPositionHelper {
  /// Find the index of the first unread post in a list
  ///
  /// Returns:
  /// - The index of the first post with ID > lastReadPostId
  /// - null if all posts are read or if lastReadPostId is null
  ///
  /// Usage:
  /// ```dart
  /// final firstUnreadIndex = ReadPositionHelper.findFirstUnreadPostIndex(
  ///   posts,
  ///   state.lastReadPostIdMap[channelId],
  /// );
  /// ```
  static int? findFirstUnreadPostIndex(
    List<Post> posts,
    int? lastReadPostId,
  ) {
    if (lastReadPostId == null) {
      return null; // No read history - scroll to latest
    }

    for (int i = 0; i < posts.length; i++) {
      if (posts[i].id > lastReadPostId) {
        return i; // First unread post
      }
    }

    return null; // All posts are read - scroll to latest
  }

  /// Find the global index of the first unread post in date-grouped posts
  ///
  /// This is useful for posts grouped by date where you need to find the
  /// absolute index across all groups.
  ///
  /// Returns:
  /// - The global index (across all date groups) of the first unread post
  /// - null if all posts are read or if lastReadPostId is null
  ///
  /// Usage:
  /// ```dart
  /// final firstUnreadIndex = ReadPositionHelper.findFirstUnreadGlobalIndex(
  ///   groupedPosts,
  ///   state.lastReadPostIdMap[channelId],
  /// );
  /// ```
  static int? findFirstUnreadGlobalIndex(
    Map<DateTime, List<Post>> groupedPosts,
    int? lastReadPostId,
  ) {
    // ✅ 수정: lastReadPostId가 null 또는 -1이면 "읽음 이력 없음" = "모든 글이 읽지 않음"
    // 따라서 첫 번째 게시글(index 0)부터 읽지 않은 글로 간주
    // -1: 신규 채널 또는 API가 null을 반환한 경우 (workspace_state_provider에서 설정)
    if (lastReadPostId == null || lastReadPostId == -1) {
      print('[DEBUG] ReadPositionHelper: lastReadPostId is $lastReadPostId (new channel), all posts are unread (return index 0)');
      return groupedPosts.isEmpty ? null : 0;
    }

    int globalIndex = 0;

    // Sort dates (oldest to newest)
    final sortedDates = groupedPosts.keys.toList()..sort();
    print('[DEBUG] ReadPositionHelper: Sorted dates: $sortedDates');

    for (final date in sortedDates) {
      final posts = groupedPosts[date]!;

      for (final post in posts) {
        print('[DEBUG] ReadPositionHelper: Checking post ${post.id}: globalIndex=$globalIndex, lastReadPostId=$lastReadPostId');

        if (post.id > lastReadPostId) {
          print('[DEBUG] ReadPositionHelper: Found first unread post at globalIndex=$globalIndex (postId=${post.id})');
          return globalIndex; // First unread post's global index
        }
        globalIndex++;
      }
    }

    print('[DEBUG] ReadPositionHelper: All posts read');
    return null; // All posts are read
  }

  /// Get the last read post ID for a channel from the map
  ///
  /// Returns null if the channel has no read history.
  static int? getLastReadPostId(
    Map<int, int> lastReadPostIdMap,
    int channelId,
  ) {
    return lastReadPostIdMap[channelId];
  }

  /// Get the unread count for a channel from the map
  ///
  /// Returns 0 if the channel has no unread count data.
  static int getUnreadCount(
    Map<int, int> unreadCountMap,
    int channelId,
  ) {
    return unreadCountMap[channelId] ?? 0;
  }

  /// Check if a post is unread based on the last read position
  ///
  /// Returns true if the post ID is greater than the last read post ID.
  static bool isPostUnread(
    int postId,
    int? lastReadPostId,
  ) {
    if (lastReadPostId == null) return false; // No read history
    return postId > lastReadPostId;
  }

  /// Calculate the number of unread posts in a list
  ///
  /// Counts posts with ID > lastReadPostId.
  static int countUnreadPosts(
    List<Post> posts,
    int? lastReadPostId,
  ) {
    if (lastReadPostId == null) return 0;

    return posts.where((post) => post.id > lastReadPostId).length;
  }
}
