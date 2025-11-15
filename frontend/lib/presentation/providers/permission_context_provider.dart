import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/navigation/permission_context.dart';
import 'package:frontend/core/network/dio_client.dart';

/// LRU cache for permission contexts
class _PermissionCache {
  final int maxSize;
  final Map<int, PermissionContext> _cache = {};
  final List<int> _accessOrder = [];

  _PermissionCache({this.maxSize = 100});

  PermissionContext? get(int groupId) {
    if (!_cache.containsKey(groupId)) return null;

    // Update access order (move to end = most recently used)
    _accessOrder.remove(groupId);
    _accessOrder.add(groupId);

    return _cache[groupId];
  }

  void put(int groupId, PermissionContext context) {
    // Remove if already exists (will be re-added at end)
    if (_cache.containsKey(groupId)) {
      _accessOrder.remove(groupId);
    }

    // Evict least recently used if at capacity
    if (_cache.length >= maxSize && !_cache.containsKey(groupId)) {
      final lru = _accessOrder.removeAt(0);
      _cache.remove(lru);
    }

    // Add new entry
    _cache[groupId] = context;
    _accessOrder.add(groupId);
  }

  void invalidate(int groupId) {
    _cache.remove(groupId);
    _accessOrder.remove(groupId);
  }

  void clear() {
    _cache.clear();
    _accessOrder.clear();
  }

  // Metrics for NFR-002 validation
  int get size => _cache.length;
  int get hitCount => _hitCount;
  int get missCount => _missCount;

  int _hitCount = 0;
  int _missCount = 0;

  void _recordHit() => _hitCount++;
  void _recordMiss() => _missCount++;
}

/// StateNotifier for managing permission context with LRU caching
class PermissionContextNotifier extends StateNotifier<PermissionContext> {
  final Ref ref;
  final DioClient _dioClient = DioClient();
  final _PermissionCache _cache = _PermissionCache(maxSize: 100);

  PermissionContextNotifier(this.ref)
    : super(
        const PermissionContext(
          groupId: -1,
          permissions: {},
          isAdmin: false,
          isLoading: true,
        ),
      );

  /// Load permissions for a specific group from the API (with caching)
  Future<void> loadPermissions(int groupId, {bool forceRefresh = false}) async {
    // Check cache first (unless force refresh)
    if (!forceRefresh) {
      final cached = _cache.get(groupId);
      if (cached != null) {
        _cache._recordHit();
        state = cached;
        return;
      }
      _cache._recordMiss();
    }

    state = state.copyWith(isLoading: true);

    try {
      final response = await _dioClient.get(
        '/groups/$groupId/members/me/permissions', // ✅ /api 제거 (baseUrl에 이미 포함)
      );

      // Parse response - expected format: { "permissions": ["PERM1", "PERM2"], "isAdmin": bool }
      final data = response.data;
      final permissions =
          (data['permissions'] as List?)?.map((p) => p.toString()).toSet() ??
          <String>{};
      final isAdmin = data['isAdmin'] as bool? ?? false;

      final newContext = PermissionContext(
        groupId: groupId,
        permissions: permissions,
        isAdmin: isAdmin,
        isLoading: false,
      );

      // Update cache
      _cache.put(groupId, newContext);

      state = newContext;
    } catch (e) {
      // On error, set empty permissions (but don't cache)
      state = PermissionContext(
        groupId: groupId,
        permissions: {},
        isAdmin: false,
        isLoading: false,
      );
      rethrow;
    }
  }

  /// Invalidate cache for a specific group (call when permissions change)
  void invalidateCache(int groupId) {
    _cache.invalidate(groupId);
  }

  /// Clear all permission state and cache
  void clear() {
    _cache.clear();
    state = const PermissionContext(
      groupId: -1,
      permissions: {},
      isAdmin: false,
      isLoading: false,
    );
  }

  /// Get cache metrics for monitoring
  Map<String, int> getCacheMetrics() {
    return {
      'size': _cache.size,
      'hits': _cache.hitCount,
      'misses': _cache.missCount,
      'hitRate': _cache.hitCount + _cache.missCount > 0
          ? ((_cache.hitCount / (_cache.hitCount + _cache.missCount)) * 100)
                .round()
          : 0,
    };
  }
}

/// Provider for permission context management (auto-disposed when group changes)
final permissionContextProvider =
    StateNotifierProvider.autoDispose<
      PermissionContextNotifier,
      PermissionContext
    >((ref) => PermissionContextNotifier(ref));
