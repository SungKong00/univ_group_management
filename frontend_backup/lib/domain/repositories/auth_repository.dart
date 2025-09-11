import '../../core/network/api_response.dart';
import '../../data/models/user_model.dart';

abstract class AuthRepository {
  Future<ApiResponse<LoginResponse>> login(LoginRequest request);
  Future<ApiResponse<UserModel>> register(RegisterRequest request);
  Future<ApiResponse<void>> logout();
  Future<bool> isLoggedIn();
  Future<UserModel?> getCurrentUser();
  Future<void> saveUserSession(LoginResponse loginResponse);
  Future<void> clearUserSession();
}