/// 멤버 Preview API Provider
///
/// Step 2에서 DYNAMIC/STATIC 선택 카드를 표시하기 위한 미리보기 데이터 조회
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/member_filter.dart';
import '../../models/member_preview_response.dart';
import '../../models/auth_models.dart';
import '../../network/dio_client.dart';

/// Preview API 호출 Provider
///
/// groupId와 filter를 받아서 미리보기 데이터를 조회합니다.
/// 응답: {totalCount: int, samples: [{id, name, grade, year, roleName}]}
final memberPreviewProvider = FutureProvider.family
    .autoDispose<MemberPreviewResponse, (int, MemberFilter)>((
      ref,
      params,
    ) async {
      final (groupId, filter) = params;
      final queryParams = filter.toQueryParameters();
      final dioClient = DioClient();

      final response = await dioClient.get<Map<String, dynamic>>(
        '/groups/$groupId/members/preview',
        queryParameters: queryParams,
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) =>
              MemberPreviewResponse.fromJson(json as Map<String, dynamic>),
        );

        if (apiResponse.success && apiResponse.data != null) {
          return apiResponse.data!;
        } else {
          throw Exception(apiResponse.message ?? 'Failed to fetch preview');
        }
      }

      throw Exception('Empty response from server');
    });
