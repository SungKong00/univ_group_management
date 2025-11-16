import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

class LocalStorage {
  LocalStorage._();

  static final LocalStorage instance = LocalStorage._();

  SharedPreferences? _prefs;

  // EAGER LOAD: 앱 시작 시 즉시 로드되는 캐시 (로그인 상태 판단용)
  String? _cachedAccessToken;

  // LAZY/PREFETCH: 백그라운드에서 프리로드되는 캐시 (로그인 버튼 반응성용)
  String? _cachedRefreshToken;
  String? _cachedUserData;

  Future<SharedPreferences> get _preferences async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  /// 앱 시작 시 필수 데이터만 즉시 로드 (부트 타임 최적화)
  /// access token만 동기적으로 로드하여 로그인 상태를 빠르게 판단
  Future<void> initEagerData() async {
    final prefs = await _preferences;
    _cachedAccessToken = prefs.getString(AppConstants.accessTokenKey);

    // 백그라운드에서 나머지 데이터 프리로드 (로그인 버튼 반응성 개선)
    Future.microtask(_prefetchData);
  }

  /// 백그라운드에서 나머지 데이터를 비동기적으로 프리로드
  /// 로그인 버튼 클릭 시 캐시된 값을 사용할 수 있도록 미리 준비
  Future<void> _prefetchData() async {
    try {
      final prefs = await _preferences;
      _cachedRefreshToken ??= prefs.getString(AppConstants.refreshTokenKey);
      _cachedUserData ??= prefs.getString(AppConstants.userDataKey);
    } catch (e) {
      // 프리로드 실패는 치명적이지 않음 - 필요시 lazy load로 폴백
      developer.log(
        'Background prefetch failed: $e',
        name: 'LocalStorage',
        level: 800,
      );
    }
  }

  Future<String?> getAccessToken() async {
    if (_cachedAccessToken != null) {
      developer.log(
        '[LocalStorage] getAccessToken() - Cache HIT (${DateTime.now()})',
        name: 'LocalStorage',
      );
      return _cachedAccessToken;
    }

    developer.log(
      '[LocalStorage] getAccessToken() - Cache MISS, reading from disk (${DateTime.now()})',
      name: 'LocalStorage',
    );

    final prefs = await _preferences;
    _cachedAccessToken = prefs.getString(AppConstants.accessTokenKey);

    developer.log(
      '[LocalStorage] getAccessToken() - Disk read result: ${_cachedAccessToken != null ? "YES" : "NO"} (${DateTime.now()})',
      name: 'LocalStorage',
    );

    return _cachedAccessToken;
  }

  Future<String?> getRefreshToken() async {
    if (_cachedRefreshToken != null) {
      return _cachedRefreshToken;
    }

    final prefs = await _preferences;
    _cachedRefreshToken = prefs.getString(AppConstants.refreshTokenKey);
    return _cachedRefreshToken;
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    developer.log(
      '[LocalStorage] saveTokens() started (${DateTime.now()})',
      name: 'LocalStorage',
    );

    final prefs = await _preferences;
    await prefs.setString(AppConstants.accessTokenKey, accessToken);
    await prefs.setString(AppConstants.refreshTokenKey, refreshToken);

    developer.log(
      '[LocalStorage] Tokens written to disk, calling reload() (${DateTime.now()})',
      name: 'LocalStorage',
    );

    // ✅ 디스크 동기화 보장: reload()로 SharedPreferences 동기화
    await prefs.reload();

    developer.log(
      '[LocalStorage] reload() completed, verifying persistence (${DateTime.now()})',
      name: 'LocalStorage',
    );

    // ✅ 저장 검증: 디스크에서 다시 읽어서 확인
    final savedAccessToken = prefs.getString(AppConstants.accessTokenKey);
    final savedRefreshToken = prefs.getString(AppConstants.refreshTokenKey);

    if (savedAccessToken != accessToken || savedRefreshToken != refreshToken) {
      developer.log(
        'Token persistence verification failed (${DateTime.now()})',
        name: 'LocalStorage',
        level: 1000, // SEVERE
      );
      throw Exception('토큰 저장 실패: 디스크 쓰기 검증 실패');
    }

    developer.log(
      '[LocalStorage] Verification passed (${DateTime.now()})',
      name: 'LocalStorage',
    );

    _cachedAccessToken = accessToken;
    _cachedRefreshToken = refreshToken;
  }

  Future<void> saveAccessToken(String accessToken) async {
    developer.log(
      '[LocalStorage] saveAccessToken() started (${DateTime.now()})',
      name: 'LocalStorage',
    );

    final prefs = await _preferences;
    await prefs.setString(AppConstants.accessTokenKey, accessToken);

    await prefs.reload();

    final savedAccessToken = prefs.getString(AppConstants.accessTokenKey);
    if (savedAccessToken != accessToken) {
      developer.log(
        'Access token persistence verification failed (${DateTime.now()})',
        name: 'LocalStorage',
        level: 1000,
      );
      throw Exception('액세스 토큰 저장 실패: 디스크 쓰기 검증 실패');
    }

    _cachedAccessToken = accessToken;

    developer.log(
      '[LocalStorage] Access token updated (${DateTime.now()})',
      name: 'LocalStorage',
    );
  }

  Future<void> saveUserData(String json) async {
    final prefs = await _preferences;
    await prefs.setString(AppConstants.userDataKey, json);
    // 캐시 동기화
    _cachedUserData = json;
  }

  Future<String?> getUserData() async {
    // 캐시된 값이 있으면 즉시 반환 (로그인 버튼 반응성 개선)
    if (_cachedUserData != null) {
      return _cachedUserData;
    }

    // 캐시 미스인 경우 SharedPreferences에서 로드하고 캐시에 저장
    final prefs = await _preferences;
    _cachedUserData = prefs.getString(AppConstants.userDataKey);
    return _cachedUserData;
  }

  Future<void> clearAuthData() async {
    final prefs = await _preferences;
    await prefs.remove(AppConstants.accessTokenKey);
    await prefs.remove(AppConstants.refreshTokenKey);
    await prefs.remove(AppConstants.userDataKey);
    // 모든 캐시 동기화
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
    _cachedUserData = null;
  }

  // ========== Navigation State Management ==========

  /// 마지막 선택된 탭 인덱스 저장
  Future<void> saveLastTabIndex(int index) async {
    final prefs = await _preferences;
    await prefs.setInt('last_tab_index', index);
  }

  /// 마지막 선택된 탭 인덱스 복원
  /// 저장된 값이 없으면 null 반환
  Future<int?> getLastTabIndex() async {
    final prefs = await _preferences;
    return prefs.getInt('last_tab_index');
  }

  // ========== Workspace State Management ==========

  /// 마지막 방문한 워크스페이스 그룹 ID 저장
  Future<void> saveLastGroupId(String? groupId) async {
    final prefs = await _preferences;
    if (groupId != null) {
      await prefs.setString('last_group_id', groupId);
    } else {
      await prefs.remove('last_group_id');
    }
  }

  /// 마지막 방문한 워크스페이스 그룹 ID 복원
  Future<String?> getLastGroupId() async {
    final prefs = await _preferences;
    return prefs.getString('last_group_id');
  }

  /// 마지막 선택한 채널 ID 저장
  Future<void> saveLastChannelId(String? channelId) async {
    final prefs = await _preferences;
    if (channelId != null) {
      await prefs.setString('last_channel_id', channelId);
    } else {
      await prefs.remove('last_channel_id');
    }
  }

  /// 마지막 선택한 채널 ID 복원
  Future<String?> getLastChannelId() async {
    final prefs = await _preferences;
    return prefs.getString('last_channel_id');
  }

  /// 마지막 선택한 뷰 타입 저장
  Future<void> saveLastViewType(String? viewType) async {
    final prefs = await _preferences;
    if (viewType != null) {
      await prefs.setString('last_view_type', viewType);
    } else {
      await prefs.remove('last_view_type');
    }
  }

  /// 마지막 선택한 뷰 타입 복원
  Future<String?> getLastViewType() async {
    final prefs = await _preferences;
    return prefs.getString('last_view_type');
  }

  /// 모든 네비게이션/워크스페이스 상태 클리어 (로그아웃 시)
  Future<void> clearNavigationState() async {
    final prefs = await _preferences;
    await Future.wait([
      prefs.remove('last_tab_index'),
      prefs.remove('last_group_id'),
      prefs.remove('last_channel_id'),
      prefs.remove('last_view_type'),
      prefs.remove('last_home_view'),
      prefs.remove('last_group_explore_tab'),
    ]);
  }

  // ========== Home State Management ==========

  /// 마지막 홈 뷰 저장
  Future<void> saveLastHomeView(String view) async {
    final prefs = await _preferences;
    await prefs.setString('last_home_view', view);
  }

  /// 마지막 홈 뷰 복원
  Future<String?> getLastHomeView() async {
    final prefs = await _preferences;
    return prefs.getString('last_home_view');
  }

  /// 마지막 그룹 탐색 탭 저장
  Future<void> saveLastGroupExploreTab(int tabIndex) async {
    final prefs = await _preferences;
    await prefs.setInt('last_group_explore_tab', tabIndex);
  }

  /// 마지막 그룹 탐색 탭 복원
  Future<int?> getLastGroupExploreTab() async {
    final prefs = await _preferences;
    return prefs.getInt('last_group_explore_tab');
  }

  // ========== Calendar State Management ==========

  /// 마지막 캘린더 탭 인덱스 저장 (0: 시간표, 1: 캘린더)
  Future<void> saveLastCalendarTab(int tabIndex) async {
    final prefs = await _preferences;
    await prefs.setInt('last_calendar_tab', tabIndex);
  }

  /// 마지막 캘린더 탭 인덱스 복원
  Future<int?> getLastCalendarTab() async {
    final prefs = await _preferences;
    return prefs.getInt('last_calendar_tab');
  }

  /// 마지막 캘린더 뷰 타입 저장 (month, week, day)
  Future<void> saveLastCalendarViewType(String viewType) async {
    final prefs = await _preferences;
    await prefs.setString('last_calendar_view_type', viewType);
  }

  /// 마지막 캘린더 뷰 타입 복원
  Future<String?> getLastCalendarViewType() async {
    final prefs = await _preferences;
    return prefs.getString('last_calendar_view_type');
  }

  /// 마지막 선택한 캘린더 날짜 저장
  Future<void> saveLastCalendarDate(DateTime date) async {
    final prefs = await _preferences;
    await prefs.setString('last_calendar_date', date.toIso8601String());
  }

  /// 마지막 선택한 캘린더 날짜 복원
  Future<DateTime?> getLastCalendarDate() async {
    final prefs = await _preferences;
    final dateStr = prefs.getString('last_calendar_date');
    if (dateStr != null) {
      try {
        return DateTime.parse(dateStr);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
