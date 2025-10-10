import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/recruitment_models.dart';
import '../../core/services/recruitment_service.dart';

// ========== Params Classes ==========

/// Parameters for creating a recruitment
class CreateRecruitmentParams {
  final int groupId;
  final CreateRecruitmentRequest request;

  CreateRecruitmentParams({
    required this.groupId,
    required this.request,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateRecruitmentParams &&
          runtimeType == other.runtimeType &&
          groupId == other.groupId &&
          request == request;

  @override
  int get hashCode => Object.hash(groupId, request);
}

/// Parameters for updating a recruitment
class UpdateRecruitmentParams {
  final int recruitmentId;
  final UpdateRecruitmentRequest request;

  UpdateRecruitmentParams({
    required this.recruitmentId,
    required this.request,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpdateRecruitmentParams &&
          runtimeType == other.runtimeType &&
          recruitmentId == other.recruitmentId &&
          request == request;

  @override
  int get hashCode => Object.hash(recruitmentId, request);
}

/// Parameters for reviewing an application
class ReviewApplicationParams {
  final int applicationId;
  final ReviewApplicationRequest request;

  ReviewApplicationParams({
    required this.applicationId,
    required this.request,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewApplicationParams &&
          runtimeType == other.runtimeType &&
          applicationId == other.applicationId &&
          request == request;

  @override
  int get hashCode => Object.hash(applicationId, request);
}

// ========== Query Providers ==========

/// Active Recruitment Provider
///
/// Fetches the currently active recruitment for a specific group.
/// Returns null if no active recruitment exists.
final activeRecruitmentProvider =
    FutureProvider.family<RecruitmentResponse?, int>((ref, groupId) async {
  final service = RecruitmentService();
  return await service.getActiveRecruitment(groupId);
});

/// Archived Recruitments Provider
///
/// Fetches the list of past/closed recruitments for a specific group.
final archivedRecruitmentsProvider = FutureProvider.family<
    List<RecruitmentSummaryResponse>, int>((ref, groupId) async {
  final service = RecruitmentService();
  return await service.getArchivedRecruitments(groupId);
});

/// Application List Provider
///
/// Fetches all applications for a specific recruitment.
final applicationListProvider = FutureProvider.family<
    List<ApplicationSummaryResponse>, int>((ref, recruitmentId) async {
  final service = RecruitmentService();
  return await service.getApplications(recruitmentId);
});

/// Recruitment Detail Provider
///
/// Fetches detailed information about a specific recruitment.
final recruitmentDetailProvider =
    FutureProvider.family<RecruitmentResponse, int>((ref, recruitmentId) async {
  final service = RecruitmentService();
  return await service.getRecruitment(recruitmentId);
});

/// Application Detail Provider
///
/// Fetches detailed information about a specific application.
final applicationProvider =
    FutureProvider.family<ApplicationResponse, int>((ref, applicationId) async {
  final service = RecruitmentService();
  return await service.getApplication(applicationId);
});

// ========== Action Providers ==========

/// Create Recruitment Provider
///
/// Creates a new recruitment post for a group.
/// Automatically refreshes the active recruitment provider on success.
final createRecruitmentProvider = FutureProvider.autoDispose
    .family<RecruitmentResponse, CreateRecruitmentParams>((ref, params) async {
  final service = RecruitmentService();
  final result =
      await service.createRecruitment(params.groupId, params.request);

  // Refresh related providers
  ref.invalidate(activeRecruitmentProvider(params.groupId));

  return result;
});

/// Update Recruitment Provider
///
/// Updates an existing recruitment post.
/// Automatically refreshes the active recruitment provider on success.
final updateRecruitmentProvider = FutureProvider.autoDispose
    .family<RecruitmentResponse, UpdateRecruitmentParams>((ref, params) async {
  final service = RecruitmentService();
  final result =
      await service.updateRecruitment(params.recruitmentId, params.request);

  // Refresh related providers
  ref.invalidate(activeRecruitmentProvider(result.group.id));

  return result;
});

/// Close Recruitment Provider
///
/// Closes an active recruitment post.
/// Automatically refreshes both active and archived recruitment providers.
final closeRecruitmentProvider = FutureProvider.autoDispose
    .family<RecruitmentResponse, int>((ref, recruitmentId) async {
  final service = RecruitmentService();
  final result = await service.closeRecruitment(recruitmentId);

  // Refresh related providers
  ref.invalidate(activeRecruitmentProvider(result.group.id));
  ref.invalidate(archivedRecruitmentsProvider(result.group.id));

  return result;
});

/// Review Application Provider
///
/// Reviews (approves or rejects) an application.
/// Automatically refreshes the application list and detail providers.
final reviewApplicationProvider = FutureProvider.autoDispose
    .family<ApplicationResponse, ReviewApplicationParams>((ref, params) async {
  final service = RecruitmentService();
  final result =
      await service.reviewApplication(params.applicationId, params.request);

  // Refresh related providers
  ref.invalidate(applicationListProvider(result.recruitment.id));
  ref.invalidate(applicationProvider(params.applicationId));

  return result;
});
