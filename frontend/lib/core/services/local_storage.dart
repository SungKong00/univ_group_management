import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

class LocalStorage {
  LocalStorage._();

  static final LocalStorage instance = LocalStorage._();

  SharedPreferences? _prefs;
  String? _cachedAccessToken;
  String? _cachedRefreshToken;

  Future<SharedPreferences> get _preferences async {
    return _prefs ??= await SharedPreferences.getInstance();
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
  }

  Future<String?> getUserData() async {
    final prefs = await _preferences;
    return prefs.getString(AppConstants.userDataKey);
  }

  Future<void> clearAuthData() async {
    final prefs = await _preferences;
    await prefs.remove(AppConstants.accessTokenKey);
    await prefs.remove(AppConstants.refreshTokenKey);
    await prefs.remove(AppConstants.userDataKey);
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
  }
}
