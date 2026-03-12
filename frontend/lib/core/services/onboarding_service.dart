import 'package:dio/dio.dart';

import '../models/auth_models.dart';
import '../models/group_models.dart';
import '../models/user_models.dart';
import '../network/dio_client.dart';

class OnboardingService {
  OnboardingService() {
    _dioClient = DioClient();
  }

  late final DioClient _dioClient;

  Future<List<GroupHierarchyNode>> fetchGroupHierarchy() async {
    try {
      final response = await _dioClient.get<Map<String, dynamic>>(
        '/groups/hierarchy',
      );
      final data = response.data;
      if (data == null) {
        throw Exception('계열/학과 정보를 불러오지 못했어요.');
      }

      final apiResponse = ApiResponse.fromJson(data, (dynamic json) {
        final list = json as List<dynamic>;
        return list
            .map(
              (dynamic item) =>
                  GroupHierarchyNode.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      });

      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      }

      throw Exception(apiResponse.message ?? '계열/학과 정보를 불러오지 못했어요.');
    } on DioException catch (error) {
      throw Exception(_extractMessage(error, fallback: '네트워크 연결을 확인해주세요.'));
    }
  }

  Future<NicknameCheckResult> checkNickname(String nickname) async {
    try {
      final response = await _dioClient.get<Map<String, dynamic>>(
        '/users/nickname-check',
        queryParameters: <String, dynamic>{'nickname': nickname},
      );

      final data = response.data;
      if (data == null) {
        throw Exception('닉네임 검증에 실패했습니다.');
      }

      final apiResponse = ApiResponse.fromJson(
        data,
        (dynamic json) =>
            NicknameCheckResult.fromJson(json as Map<String, dynamic>),
      );

      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      }

      throw Exception(apiResponse.message ?? '닉네임 중복 여부를 확인할 수 없어요.');
    } on DioException catch (error) {
      throw Exception(_extractMessage(error, fallback: '닉네임 확인 중 오류가 발생했습니다.'));
    }
  }

  Future<void> sendEmailVerification(EmailSendRequest request) async {
    try {
      final response = await _dioClient.post<Map<String, dynamic>>(
        '/email/verification/send',
        data: request.toJson(),
      );

      final data = response.data;
      if (data == null) {
        throw Exception('인증 코드를 전송하지 못했어요.');
      }

      final apiResponse = ApiResponse.fromJson(data, (dynamic _) => null);
      if (!apiResponse.success) {
        throw Exception(apiResponse.message ?? '인증 코드를 전송하지 못했어요.');
      }
    } on DioException catch (error) {
      throw Exception(
        _extractMessage(error, fallback: '인증 코드 전송 중 오류가 발생했습니다.'),
      );
    }
  }

  Future<void> verifyEmailCode(EmailVerifyRequest request) async {
    try {
      final response = await _dioClient.post<Map<String, dynamic>>(
        '/email/verification/verify',
        data: request.toJson(),
      );

      final data = response.data;
      if (data == null) {
        throw Exception('인증 코드를 확인하지 못했어요.');
      }

      final apiResponse = ApiResponse.fromJson(data, (dynamic _) => null);
      if (!apiResponse.success) {
        throw Exception(apiResponse.message ?? '인증 코드가 일치하지 않아요.');
      }
    } on DioException catch (error) {
      throw Exception(
        _extractMessage(error, fallback: '인증 코드 확인 중 오류가 발생했습니다.'),
      );
    }
  }

  Future<UserInfo> submitSignupProfile(SignupProfileRequest request) async {
    try {
      final response = await _dioClient.post<Map<String, dynamic>>(
        '/users',
        data: request.toJson(),
      );

      final data = response.data;
      if (data == null) {
        throw Exception('프로필 정보를 저장하지 못했어요.');
      }

      final apiResponse = ApiResponse.fromJson(
        data,
        (dynamic json) => UserInfo.fromJson(json as Map<String, dynamic>),
      );

      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      }

      throw Exception(apiResponse.message ?? '프로필 정보를 저장하지 못했어요.');
    } on DioException catch (error) {
      throw Exception(_extractMessage(error, fallback: '프로필 저장 중 오류가 발생했습니다.'));
    }
  }

  String _extractMessage(DioException error, {required String fallback}) {
    final response = error.response;
    if (response != null && response.data is Map<String, dynamic>) {
      final map = response.data as Map<String, dynamic>;
      final message = map['message'] as String?;
      if (message != null && message.isNotEmpty) {
        return message;
      }
    }
    return fallback;
  }
}
