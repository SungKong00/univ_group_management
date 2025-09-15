import '../../core/network/api_response.dart';
import '../../data/models/auth_models.dart';

abstract class AuthRepository {
  Future<ApiResponse<LoginResponse>> loginWithGoogleIdToken(String idToken);
  Future<ApiResponse<LoginResponse>> loginWithGoogleTokens({String? idToken, String? accessToken});
  Future<ApiResponse<UserModel>> submitOnboarding(OnboardingRequest request);
  Future<ApiResponse<UserModel>> me();
  Future<ApiResponse<NicknameCheckResult>> checkNickname(String nickname);
  Future<ApiResponse<void>> sendEmailOtp(String email);
  Future<ApiResponse<void>> verifyEmailOtp(String email, String code);
  Future<ApiResponse<String>> logout();
  Future<void> saveSession(LoginResponse login);
  Future<bool> hasToken();
  Future<void> clear();
  Future<UserModel?> getSavedUser();
}
