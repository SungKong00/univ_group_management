/// Stub implementation for non-web platforms
/// This file is used when dart:html is not available (e.g., during testing)

void updateReadPositionCache({
  required String channelId,
  required int postId,
  required String apiBaseUrl,
}) {
  // No-op on non-web platforms
}
