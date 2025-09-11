import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

abstract class TokenStorage {
  Future<void> saveAccessToken(String token);
  Future<void> saveRefreshToken(String token);
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> clearTokens();
  Future<void> saveUserData(String userData);
  Future<String?> getUserData();
  Future<void> clearUserData();
}

class SecureTokenStorage implements TokenStorage {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  @override
  Future<void> saveAccessToken(String token) async {
    await _secureStorage.write(
      key: AppConstants.accessTokenKey,
      value: token,
    );
  }

  @override
  Future<void> saveRefreshToken(String token) async {
    await _secureStorage.write(
      key: AppConstants.refreshTokenKey,
      value: token,
    );
  }

  @override
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: AppConstants.accessTokenKey);
  }

  @override
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: AppConstants.refreshTokenKey);
  }

  @override
  Future<void> clearTokens() async {
    await Future.wait([
      _secureStorage.delete(key: AppConstants.accessTokenKey),
      _secureStorage.delete(key: AppConstants.refreshTokenKey),
    ]);
  }

  @override
  Future<void> saveUserData(String userData) async {
    await _secureStorage.write(
      key: AppConstants.userDataKey,
      value: userData,
    );
  }

  @override
  Future<String?> getUserData() async {
    return await _secureStorage.read(key: AppConstants.userDataKey);
  }

  @override
  Future<void> clearUserData() async {
    await _secureStorage.delete(key: AppConstants.userDataKey);
  }
}

// SharedPreferences를 사용하는 대안 구현 (보안성이 낮지만 호환성이 좋음)
class SharedPrefsTokenStorage implements TokenStorage {
  @override
  Future<void> saveAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.accessTokenKey, token);
  }

  @override
  Future<void> saveRefreshToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.refreshTokenKey, token);
  }

  @override
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.accessTokenKey);
  }

  @override
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.refreshTokenKey);
  }

  @override
  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(AppConstants.accessTokenKey),
      prefs.remove(AppConstants.refreshTokenKey),
    ]);
  }

  @override
  Future<void> saveUserData(String userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.userDataKey, userData);
  }

  @override
  Future<String?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.userDataKey);
  }

  @override
  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.userDataKey);
  }
}