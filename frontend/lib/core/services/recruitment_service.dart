import 'dart:developer' as developer;
import '../models/recruitment_models.dart';
import '../models/auth_models.dart';
import '../network/dio_client.dart';

/// Recruitment Service
///
/// Provides API methods for managing recruitment posts and applications.
class RecruitmentService {
  static final RecruitmentService _instance = RecruitmentService._internal();
  factory RecruitmentService() => _instance;
  RecruitmentService._internal();

  final DioClient _dioClient = DioClient();

  // ========== 모집 공고 관련 API ==========

  /// Create a new recruitment post
  ///
  /// POST /api/groups/{groupId}/recruitments
  /// Requires RECRUITMENT_MANAGE permission
  Future<RecruitmentResponse> createRecruitment(
    int groupId,
    CreateRecruitmentRequest request,
  ) async {
    try {
      developer.log(
        'Creating recruitment for group: $groupId',
        name: 'RecruitmentService',
      );

      final response = await _dioClient.post<Map<String, dynamic>>(
        '/groups/$groupId/recruitments',
        data: request.toJson(),
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => RecruitmentResponse.fromJson(json as Map<String, dynamic>),
        );

        if (apiResponse.success && apiResponse.data != null) {
          developer.log(
            'Successfully created recruitment: ${apiResponse.data!.id}',
            name: 'RecruitmentService',
          );
          return apiResponse.data!;
        } else {
          developer.log(
            'Failed to create recruitment: ${apiResponse.message}',
            name: 'RecruitmentService',
            level: 900,
          );
          throw Exception(
            apiResponse.message ?? 'Failed to create recruitment',
          );
        }
      }

      throw Exception('Empty response from server');
    } catch (e) {
      developer.log(
        'Error creating recruitment: $e',
        name: 'RecruitmentService',
        level: 900,
      );
      rethrow;
    }
  }

  /// Get a specific recruitment by ID
  ///
  /// GET /api/recruitments/{recruitmentId}
  /// Returns detailed recruitment information
  Future<RecruitmentResponse> getRecruitment(int recruitmentId) async {
    try {
      developer.log(
        'Fetching recruitment: $recruitmentId',
        name: 'RecruitmentService',
      );

      final response = await _dioClient.get<Map<String, dynamic>>(
        '/recruitments/$recruitmentId',
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => RecruitmentResponse.fromJson(json as Map<String, dynamic>),
        );

        if (apiResponse.success && apiResponse.data != null) {
          developer.log(
            'Successfully fetched recruitment: $recruitmentId',
            name: 'RecruitmentService',
          );
          return apiResponse.data!;
        } else {
          developer.log(
            'Failed to fetch recruitment: ${apiResponse.message}',
            name: 'RecruitmentService',
            level: 900,
          );
          throw Exception(
            apiResponse.message ?? 'Failed to fetch recruitment',
          );
        }
      }

      throw Exception('Empty response from server');
    } catch (e) {
      developer.log(
        'Error fetching recruitment: $e',
        name: 'RecruitmentService',
        level: 900,
      );
      rethrow;
    }
  }

  /// Get active recruitment for a group
  ///
  /// GET /api/groups/{groupId}/recruitments
  /// Returns null if no active recruitment exists
  Future<RecruitmentResponse?> getActiveRecruitment(int groupId) async {
    try {
      developer.log(
        'Fetching active recruitment for group: $groupId',
        name: 'RecruitmentService',
      );

      final response = await _dioClient.get<Map<String, dynamic>>(
        '/groups/$groupId/recruitments',
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) {
            // Backend may return null if no active recruitment
            if (json == null) return null;
            return RecruitmentResponse.fromJson(json as Map<String, dynamic>);
          },
        );

        if (apiResponse.success) {
          developer.log(
            apiResponse.data != null
                ? 'Successfully fetched active recruitment'
                : 'No active recruitment found',
            name: 'RecruitmentService',
          );
          return apiResponse.data;
        } else {
          developer.log(
            'Failed to fetch active recruitment: ${apiResponse.message}',
            name: 'RecruitmentService',
            level: 900,
          );
          throw Exception(
            apiResponse.message ?? 'Failed to fetch active recruitment',
          );
        }
      }

      throw Exception('Empty response from server');
    } catch (e) {
      developer.log(
        'Error fetching active recruitment: $e',
        name: 'RecruitmentService',
        level: 900,
      );
      rethrow;
    }
  }

  /// Update a recruitment post
  ///
  /// PUT /api/recruitments/{recruitmentId}
  /// Requires RECRUITMENT_MANAGE permission
  Future<RecruitmentResponse> updateRecruitment(
    int recruitmentId,
    UpdateRecruitmentRequest request,
  ) async {
    try {
      developer.log(
        'Updating recruitment: $recruitmentId',
        name: 'RecruitmentService',
      );

      final response = await _dioClient.put<Map<String, dynamic>>(
        '/recruitments/$recruitmentId',
        data: request.toJson(),
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => RecruitmentResponse.fromJson(json as Map<String, dynamic>),
        );

        if (apiResponse.success && apiResponse.data != null) {
          developer.log(
            'Successfully updated recruitment: $recruitmentId',
            name: 'RecruitmentService',
          );
          return apiResponse.data!;
        } else {
          developer.log(
            'Failed to update recruitment: ${apiResponse.message}',
            name: 'RecruitmentService',
            level: 900,
          );
          throw Exception(
            apiResponse.message ?? 'Failed to update recruitment',
          );
        }
      }

      throw Exception('Empty response from server');
    } catch (e) {
      developer.log(
        'Error updating recruitment: $e',
        name: 'RecruitmentService',
        level: 900,
      );
      rethrow;
    }
  }

  /// Close a recruitment early
  ///
  /// PATCH /api/recruitments/{recruitmentId}/close
  /// Requires RECRUITMENT_MANAGE permission
  Future<RecruitmentResponse> closeRecruitment(int recruitmentId) async {
    try {
      developer.log(
        'Closing recruitment: $recruitmentId',
        name: 'RecruitmentService',
      );

      final response = await _dioClient.patch<Map<String, dynamic>>(
        '/recruitments/$recruitmentId/close',
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => RecruitmentResponse.fromJson(json as Map<String, dynamic>),
        );

        if (apiResponse.success && apiResponse.data != null) {
          developer.log(
            'Successfully closed recruitment: $recruitmentId',
            name: 'RecruitmentService',
          );
          return apiResponse.data!;
        } else {
          developer.log(
            'Failed to close recruitment: ${apiResponse.message}',
            name: 'RecruitmentService',
            level: 900,
          );
          throw Exception(
            apiResponse.message ?? 'Failed to close recruitment',
          );
        }
      }

      throw Exception('Empty response from server');
    } catch (e) {
      developer.log(
        'Error closing recruitment: $e',
        name: 'RecruitmentService',
        level: 900,
      );
      rethrow;
    }
  }

  /// Delete a recruitment post
  ///
  /// DELETE /api/recruitments/{recruitmentId}
  /// Requires RECRUITMENT_MANAGE permission
  Future<void> deleteRecruitment(int recruitmentId) async {
    try {
      developer.log(
        'Deleting recruitment: $recruitmentId',
        name: 'RecruitmentService',
      );

      final response = await _dioClient.delete<Map<String, dynamic>>(
        '/recruitments/$recruitmentId',
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => null, // DELETE returns no data
        );

        if (apiResponse.success) {
          developer.log(
            'Successfully deleted recruitment: $recruitmentId',
            name: 'RecruitmentService',
          );
          return;
        } else {
          developer.log(
            'Failed to delete recruitment: ${apiResponse.message}',
            name: 'RecruitmentService',
            level: 900,
          );
          throw Exception(
            apiResponse.message ?? 'Failed to delete recruitment',
          );
        }
      }

      throw Exception('Empty response from server');
    } catch (e) {
      developer.log(
        'Error deleting recruitment: $e',
        name: 'RecruitmentService',
        level: 900,
      );
      rethrow;
    }
  }

  /// Get archived recruitments for a group
  ///
  /// GET /api/groups/{groupId}/recruitments/archive
  /// Requires RECRUITMENT_MANAGE permission
  /// Returns paginated list of archived recruitments
  Future<List<ArchivedRecruitmentResponse>> getArchivedRecruitments(
    int groupId,
  ) async {
    try {
      developer.log(
        'Fetching archived recruitments for group: $groupId',
        name: 'RecruitmentService',
      );

      final response = await _dioClient.get<Map<String, dynamic>>(
        '/groups/$groupId/recruitments/archive',
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(response.data!, (json) {
          // Backend returns PagedApiResponse with 'content' field inside 'data'
          if (json is Map<String, dynamic> && json.containsKey('content')) {
            final content = json['content'] as List<dynamic>;
            return content
                .map((item) => ArchivedRecruitmentResponse.fromJson(
                      item as Map<String, dynamic>,
                    ))
                .toList();
          }
          // Fallback for direct list response
          if (json is List) {
            return json
                .map((item) => ArchivedRecruitmentResponse.fromJson(
                      item as Map<String, dynamic>,
                    ))
                .toList();
          }
          return <ArchivedRecruitmentResponse>[];
        });

        if (apiResponse.success && apiResponse.data != null) {
          developer.log(
            'Successfully fetched ${apiResponse.data!.length} archived recruitments',
            name: 'RecruitmentService',
          );
          return apiResponse.data!;
        } else {
          developer.log(
            'Failed to fetch archived recruitments: ${apiResponse.message}',
            name: 'RecruitmentService',
            level: 900,
          );
          throw Exception(
            apiResponse.message ?? 'Failed to fetch archived recruitments',
          );
        }
      }

      throw Exception('Empty response from server');
    } catch (e) {
      developer.log(
        'Error fetching archived recruitments: $e',
        name: 'RecruitmentService',
        level: 900,
      );
      rethrow;
    }
  }

  /// Search public recruitment posts
  ///
  /// GET /api/recruitments/public
  /// Public API - no authentication required
  Future<List<RecruitmentSummaryResponse>> searchPublicRecruitments({
    String? keyword,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
      };
      if (keyword != null && keyword.isNotEmpty) {
        queryParams['keyword'] = keyword;
      }

      developer.log(
        'Searching public recruitments with keyword: $keyword, page: $page, size: $size',
        name: 'RecruitmentService',
      );

      final response = await _dioClient.get<Map<String, dynamic>>(
        '/recruitments/public',
        queryParameters: queryParams,
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(response.data!, (json) {
          // Backend returns PagedApiResponse with 'content' field inside 'data'
          if (json is Map<String, dynamic> && json.containsKey('content')) {
            final content = json['content'] as List<dynamic>;
            return content
                .map((item) => RecruitmentSummaryResponse.fromJson(
                      item as Map<String, dynamic>,
                    ))
                .toList();
          }
          // Fallback for direct list response
          if (json is List) {
            return json
                .map((item) => RecruitmentSummaryResponse.fromJson(
                      item as Map<String, dynamic>,
                    ))
                .toList();
          }
          return <RecruitmentSummaryResponse>[];
        });

        if (apiResponse.success && apiResponse.data != null) {
          developer.log(
            'Successfully fetched ${apiResponse.data!.length} public recruitments',
            name: 'RecruitmentService',
          );
          return apiResponse.data!;
        } else {
          developer.log(
            'Failed to search public recruitments: ${apiResponse.message}',
            name: 'RecruitmentService',
            level: 900,
          );
          throw Exception(
            apiResponse.message ?? 'Failed to search public recruitments',
          );
        }
      }

      throw Exception('Empty response from server');
    } catch (e) {
      developer.log(
        'Error searching public recruitments: $e',
        name: 'RecruitmentService',
        level: 900,
      );
      rethrow;
    }
  }

  // ========== 지원서 관련 API ==========

  /// Submit an application to a recruitment
  ///
  /// POST /api/recruitments/{recruitmentId}/applications
  /// Requires authentication
  Future<ApplicationResponse> submitApplication(
    int recruitmentId,
    CreateApplicationRequest request,
  ) async {
    try {
      developer.log(
        'Submitting application to recruitment: $recruitmentId',
        name: 'RecruitmentService',
      );

      final response = await _dioClient.post<Map<String, dynamic>>(
        '/recruitments/$recruitmentId/applications',
        data: request.toJson(),
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => ApplicationResponse.fromJson(json as Map<String, dynamic>),
        );

        if (apiResponse.success && apiResponse.data != null) {
          developer.log(
            'Successfully submitted application: ${apiResponse.data!.id}',
            name: 'RecruitmentService',
          );
          return apiResponse.data!;
        } else {
          developer.log(
            'Failed to submit application: ${apiResponse.message}',
            name: 'RecruitmentService',
            level: 900,
          );
          throw Exception(
            apiResponse.message ?? 'Failed to submit application',
          );
        }
      }

      throw Exception('Empty response from server');
    } catch (e) {
      developer.log(
        'Error submitting application: $e',
        name: 'RecruitmentService',
        level: 900,
      );
      rethrow;
    }
  }

  /// Get applications for a recruitment
  ///
  /// GET /api/recruitments/{recruitmentId}/applications
  /// Requires RECRUITMENT_MANAGE permission
  Future<List<ApplicationSummaryResponse>> getApplications(
    int recruitmentId,
  ) async {
    try {
      developer.log(
        'Fetching applications for recruitment: $recruitmentId',
        name: 'RecruitmentService',
      );

      final response = await _dioClient.get<Map<String, dynamic>>(
        '/recruitments/$recruitmentId/applications',
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(response.data!, (json) {
          if (json is List) {
            return json
                .map((item) => ApplicationSummaryResponse.fromJson(
                      item as Map<String, dynamic>,
                    ))
                .toList();
          }
          return <ApplicationSummaryResponse>[];
        });

        if (apiResponse.success && apiResponse.data != null) {
          developer.log(
            'Successfully fetched ${apiResponse.data!.length} applications',
            name: 'RecruitmentService',
          );
          return apiResponse.data!;
        } else {
          developer.log(
            'Failed to fetch applications: ${apiResponse.message}',
            name: 'RecruitmentService',
            level: 900,
          );
          throw Exception(
            apiResponse.message ?? 'Failed to fetch applications',
          );
        }
      }

      throw Exception('Empty response from server');
    } catch (e) {
      developer.log(
        'Error fetching applications: $e',
        name: 'RecruitmentService',
        level: 900,
      );
      rethrow;
    }
  }

  /// Get a single application by ID
  ///
  /// GET /api/applications/{applicationId}
  /// Requires RECRUITMENT_MANAGE permission or being the applicant
  Future<ApplicationResponse> getApplication(int applicationId) async {
    try {
      developer.log(
        'Fetching application: $applicationId',
        name: 'RecruitmentService',
      );

      final response = await _dioClient.get<Map<String, dynamic>>(
        '/applications/$applicationId',
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => ApplicationResponse.fromJson(json as Map<String, dynamic>),
        );

        if (apiResponse.success && apiResponse.data != null) {
          developer.log(
            'Successfully fetched application: $applicationId',
            name: 'RecruitmentService',
          );
          return apiResponse.data!;
        } else {
          developer.log(
            'Failed to fetch application: ${apiResponse.message}',
            name: 'RecruitmentService',
            level: 900,
          );
          throw Exception(
            apiResponse.message ?? 'Failed to fetch application',
          );
        }
      }

      throw Exception('Empty response from server');
    } catch (e) {
      developer.log(
        'Error fetching application: $e',
        name: 'RecruitmentService',
        level: 900,
      );
      rethrow;
    }
  }

  /// Review an application (approve or reject)
  ///
  /// PATCH /api/applications/{applicationId}/review
  /// Requires RECRUITMENT_MANAGE permission
  Future<ApplicationResponse> reviewApplication(
    int applicationId,
    ReviewApplicationRequest request,
  ) async {
    try {
      developer.log(
        'Reviewing application: $applicationId (action: ${request.action})',
        name: 'RecruitmentService',
      );

      final response = await _dioClient.patch<Map<String, dynamic>>(
        '/applications/$applicationId/review',
        data: request.toJson(),
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => ApplicationResponse.fromJson(json as Map<String, dynamic>),
        );

        if (apiResponse.success && apiResponse.data != null) {
          developer.log(
            'Successfully reviewed application: $applicationId',
            name: 'RecruitmentService',
          );
          return apiResponse.data!;
        } else {
          developer.log(
            'Failed to review application: ${apiResponse.message}',
            name: 'RecruitmentService',
            level: 900,
          );
          throw Exception(
            apiResponse.message ?? 'Failed to review application',
          );
        }
      }

      throw Exception('Empty response from server');
    } catch (e) {
      developer.log(
        'Error reviewing application: $e',
        name: 'RecruitmentService',
        level: 900,
      );
      rethrow;
    }
  }

  /// Withdraw an application
  ///
  /// DELETE /api/applications/{applicationId}
  /// Requires being the applicant
  Future<void> withdrawApplication(int applicationId) async {
    try {
      developer.log(
        'Withdrawing application: $applicationId',
        name: 'RecruitmentService',
      );

      final response = await _dioClient.delete<Map<String, dynamic>>(
        '/applications/$applicationId',
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => null, // DELETE returns no data
        );

        if (apiResponse.success) {
          developer.log(
            'Successfully withdrawn application: $applicationId',
            name: 'RecruitmentService',
          );
          return;
        } else {
          developer.log(
            'Failed to withdraw application: ${apiResponse.message}',
            name: 'RecruitmentService',
            level: 900,
          );
          throw Exception(
            apiResponse.message ?? 'Failed to withdraw application',
          );
        }
      }

      throw Exception('Empty response from server');
    } catch (e) {
      developer.log(
        'Error withdrawing application: $e',
        name: 'RecruitmentService',
        level: 900,
      );
      rethrow;
    }
  }
}
