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
      return _cachedAccessToken;
    }

    final prefs = await _preferences;
    _cachedAccessToken = prefs.getString(AppConstants.accessTokenKey);
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
    final prefs = await _preferences;
    await prefs.setString(AppConstants.accessTokenKey, accessToken);
    await prefs.setString(AppConstants.refreshTokenKey, refreshToken);
    _cachedAccessToken = accessToken;
    _cachedRefreshToken = refreshToken;
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
}
