/// Feature Flags for gradual rollout and A/B testing
///
/// Use these flags to enable/disable experimental features
/// or safely migrate to new implementations.
class FeatureFlags {
  /// Use AsyncNotifier pattern for PostList data loading
  ///
  /// - true: Provider controls data loading (new, clean architecture)
  /// - false: Widget controls data loading (old, race condition)
  ///
  /// Default: true (enabled)
  static const bool useAsyncNotifierPattern = true;
}
