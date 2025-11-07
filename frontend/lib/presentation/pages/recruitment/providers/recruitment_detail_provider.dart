import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/recruitment_models.dart';
import '../../../../core/services/recruitment_service.dart';

/// Recruitment Detail Provider
///
/// Fetches detailed information about a recruitment post.
final recruitmentDetailProvider = FutureProvider.autoDispose
    .family<RecruitmentResponse, int>((ref, recruitmentId) async {
  final service = RecruitmentService();
  return await service.getRecruitment(recruitmentId);
});

/// Submit Application Provider
///
/// Parameter model for submitting an application.
class SubmitApplicationParams {
  const SubmitApplicationParams({
    required this.recruitmentId,
    this.motivation,
    required this.questionAnswers,
  });

  final int recruitmentId;
  final String? motivation;
  final Map<int, String> questionAnswers;
}

/// Submit Application Provider
///
/// Handles application submission and returns the result.
final submitApplicationProvider = FutureProvider.autoDispose
    .family<ApplicationResponse, SubmitApplicationParams>((ref, params) async {
  final service = RecruitmentService();
  final request = CreateApplicationRequest(
    motivation: params.motivation,
    questionAnswers: params.questionAnswers,
  );
  return await service.submitApplication(params.recruitmentId, request);
});

/// Has Applied State Provider
///
/// Local state to track if the user has successfully applied to the recruitment.
final hasAppliedProvider = StateProvider.autoDispose<bool>((ref) => false);
