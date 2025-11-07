import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/recruitment_models.dart';
import '../../../../core/services/recruitment_service.dart';

/// 그룹의 활성 모집 공고 조회 Provider
final activeRecruitmentProvider =
    FutureProvider.family<RecruitmentResponse?, int>((ref, groupId) async {
  final service = RecruitmentService();
  return await service.getActiveRecruitment(groupId);
});

/// 특정 모집 공고의 지원자 목록 조회 Provider
final recruitmentApplicationsProvider = FutureProvider.family<
    List<ApplicationSummaryResponse>,
    int>((ref, recruitmentId) async {
  final service = RecruitmentService();
  return await service.getApplications(recruitmentId);
});

/// 지원서 심사 (승인/거절) 요청
class ReviewApplicationParams {
  final int applicationId;
  final String action; // "APPROVE" or "REJECT"
  final String? reviewComment;

  ReviewApplicationParams({
    required this.applicationId,
    required this.action,
    this.reviewComment,
  });
}

final reviewApplicationProvider = FutureProvider.autoDispose
    .family<ApplicationResponse, ReviewApplicationParams>(
        (ref, params) async {
  final service = RecruitmentService();
  final request = ReviewApplicationRequest(
    action: params.action,
    reviewComment: params.reviewComment,
  );
  return await service.reviewApplication(params.applicationId, request);
});
