import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

abstract class TokenStorage {
  Future<void> saveAccessToken(String token);
  Future<String?> getAccessToken();
  Future<void> clear();
  Future<void> saveUserData(String userJson);
  Future<String?> getUserData();
}

class SharedPrefsTokenStorage implements TokenStorage {
  @override
  Future<void> saveAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.accessTokenKey, token);
  }

  @override
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.accessTokenKey);
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.accessTokenKey);
    await prefs.remove(AppConstants.userDataKey);
  }

  @override
  Future<void> saveUserData(String userJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.userDataKey, userJson);
  }

  @override
  Future<String?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.userDataKey);
  }
}

