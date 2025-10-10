// 모집공고 관련 데이터 모델
//
// 그룹의 모집공고 및 지원서 관리를 위한 모델 정의
// 백엔드 RecruitmentDto.kt 기반으로 작성

import 'group_models.dart';
import 'user_models.dart';

// ==================== Enums ====================

enum RecruitmentStatus { draft, open, closed, cancelled }

enum ApplicationStatus { pending, approved, rejected, withdrawn }

// ==================== Helper Functions ====================

RecruitmentStatus _parseRecruitmentStatus(String value) {
  return RecruitmentStatus.values.firstWhere(
    (e) => e.name.toUpperCase() == value,
    orElse: () => throw ArgumentError('Unknown RecruitmentStatus: $value'),
  );
}

String _serializeRecruitmentStatus(RecruitmentStatus status) {
  return status.name.toUpperCase();
}

ApplicationStatus _parseApplicationStatus(String value) {
  return ApplicationStatus.values.firstWhere(
    (e) => e.name.toUpperCase() == value,
    orElse: () => throw ArgumentError('Unknown ApplicationStatus: $value'),
  );
}

String _serializeApplicationStatus(ApplicationStatus status) {
  return status.name.toUpperCase();
}

// ==================== Request DTOs ====================

class CreateRecruitmentRequest {
  CreateRecruitmentRequest({
    required this.title,
    this.content,
    this.maxApplicants,
    this.recruitmentEndDate,
    this.autoApprove = false,
    this.showApplicantCount = true,
    this.applicationQuestions = const [],
  });

  final String title;
  final String? content;
  final int? maxApplicants;
  final DateTime? recruitmentEndDate;
  final bool autoApprove;
  final bool showApplicantCount;
  final List<String> applicationQuestions;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': title,
      'content': content,
      'maxApplicants': maxApplicants,
      'recruitmentEndDate': recruitmentEndDate?.toIso8601String(),
      'autoApprove': autoApprove,
      'showApplicantCount': showApplicantCount,
      'applicationQuestions': applicationQuestions,
    };
  }
}

class UpdateRecruitmentRequest {
  UpdateRecruitmentRequest({
    this.title,
    this.content,
    this.maxApplicants,
    this.recruitmentEndDate,
    this.autoApprove,
    this.showApplicantCount,
    this.applicationQuestions,
  });

  final String? title;
  final String? content;
  final int? maxApplicants;
  final DateTime? recruitmentEndDate;
  final bool? autoApprove;
  final bool? showApplicantCount;
  final List<String>? applicationQuestions;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    if (title != null) json['title'] = title;
    if (content != null) json['content'] = content;
    if (maxApplicants != null) json['maxApplicants'] = maxApplicants;
    if (recruitmentEndDate != null) {
      json['recruitmentEndDate'] = recruitmentEndDate!.toIso8601String();
    }
    if (autoApprove != null) json['autoApprove'] = autoApprove;
    if (showApplicantCount != null) {
      json['showApplicantCount'] = showApplicantCount;
    }
    if (applicationQuestions != null) {
      json['applicationQuestions'] = applicationQuestions;
    }
    return json;
  }
}

class CreateApplicationRequest {
  CreateApplicationRequest({
    this.motivation,
    this.questionAnswers = const {},
  });

  final String? motivation;
  final Map<int, String> questionAnswers;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'motivation': motivation,
      'questionAnswers': questionAnswers.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
    };
  }
}

class ReviewApplicationRequest {
  ReviewApplicationRequest({
    required this.action,
    this.reviewComment,
  });

  final String action; // "APPROVE" or "REJECT"
  final String? reviewComment;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'action': action,
      'reviewComment': reviewComment,
    };
  }
}

// ==================== Response DTOs ====================

class RecruitmentResponse {
  RecruitmentResponse({
    required this.id,
    required this.group,
    required this.createdBy,
    required this.title,
    this.content,
    this.maxApplicants,
    required this.currentApplicantCount,
    required this.recruitmentStartDate,
    this.recruitmentEndDate,
    required this.status,
    required this.autoApprove,
    required this.showApplicantCount,
    required this.applicationQuestions,
    required this.createdAt,
    required this.updatedAt,
    this.closedAt,
  });

  factory RecruitmentResponse.fromJson(Map<String, dynamic> json) {
    return RecruitmentResponse(
      id: (json['id'] as num).toInt(),
      group: GroupSummaryResponse.fromJson(
        json['group'] as Map<String, dynamic>,
      ),
      createdBy: UserSummaryResponse.fromJson(
        json['createdBy'] as Map<String, dynamic>,
      ),
      title: json['title'] as String,
      content: json['content'] as String?,
      maxApplicants: (json['maxApplicants'] as num?)?.toInt(),
      currentApplicantCount: (json['currentApplicantCount'] as num).toInt(),
      recruitmentStartDate:
          DateTime.parse(json['recruitmentStartDate'] as String),
      recruitmentEndDate: json['recruitmentEndDate'] != null
          ? DateTime.parse(json['recruitmentEndDate'] as String)
          : null,
      status: _parseRecruitmentStatus(json['status'] as String),
      autoApprove: json['autoApprove'] as bool,
      showApplicantCount: json['showApplicantCount'] as bool,
      applicationQuestions: (json['applicationQuestions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      closedAt: json['closedAt'] != null
          ? DateTime.parse(json['closedAt'] as String)
          : null,
    );
  }

  final int id;
  final GroupSummaryResponse group;
  final UserSummaryResponse createdBy;
  final String title;
  final String? content;
  final int? maxApplicants;
  final int currentApplicantCount;
  final DateTime recruitmentStartDate;
  final DateTime? recruitmentEndDate;
  final RecruitmentStatus status;
  final bool autoApprove;
  final bool showApplicantCount;
  final List<String> applicationQuestions;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? closedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'group': group.toJson(),
      'createdBy': createdBy.toJson(),
      'title': title,
      'content': content,
      'maxApplicants': maxApplicants,
      'currentApplicantCount': currentApplicantCount,
      'recruitmentStartDate': recruitmentStartDate.toIso8601String(),
      'recruitmentEndDate': recruitmentEndDate?.toIso8601String(),
      'status': _serializeRecruitmentStatus(status),
      'autoApprove': autoApprove,
      'showApplicantCount': showApplicantCount,
      'applicationQuestions': applicationQuestions,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'closedAt': closedAt?.toIso8601String(),
    };
  }
}

class RecruitmentSummaryResponse {
  RecruitmentSummaryResponse({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.title,
    this.content,
    this.maxApplicants,
    this.currentApplicantCount,
    this.recruitmentEndDate,
    required this.status,
    required this.showApplicantCount,
    required this.createdAt,
  });

  factory RecruitmentSummaryResponse.fromJson(Map<String, dynamic> json) {
    return RecruitmentSummaryResponse(
      id: (json['id'] as num).toInt(),
      groupId: (json['groupId'] as num).toInt(),
      groupName: json['groupName'] as String,
      title: json['title'] as String,
      content: json['content'] as String?,
      maxApplicants: (json['maxApplicants'] as num?)?.toInt(),
      currentApplicantCount: (json['currentApplicantCount'] as num?)?.toInt(),
      recruitmentEndDate: json['recruitmentEndDate'] != null
          ? DateTime.parse(json['recruitmentEndDate'] as String)
          : null,
      status: _parseRecruitmentStatus(json['status'] as String),
      showApplicantCount: json['showApplicantCount'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final int id;
  final int groupId;
  final String groupName;
  final String title;
  final String? content;
  final int? maxApplicants;
  final int? currentApplicantCount;
  final DateTime? recruitmentEndDate;
  final RecruitmentStatus status;
  final bool showApplicantCount;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'groupId': groupId,
      'groupName': groupName,
      'title': title,
      'content': content,
      'maxApplicants': maxApplicants,
      'currentApplicantCount': currentApplicantCount,
      'recruitmentEndDate': recruitmentEndDate?.toIso8601String(),
      'status': _serializeRecruitmentStatus(status),
      'showApplicantCount': showApplicantCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class ApplicationResponse {
  ApplicationResponse({
    required this.id,
    required this.recruitment,
    required this.applicant,
    this.motivation,
    required this.questionAnswers,
    required this.status,
    this.reviewedBy,
    this.reviewedAt,
    this.reviewComment,
    required this.appliedAt,
    required this.updatedAt,
  });

  factory ApplicationResponse.fromJson(Map<String, dynamic> json) {
    return ApplicationResponse(
      id: (json['id'] as num).toInt(),
      recruitment: RecruitmentSummaryResponse.fromJson(
        json['recruitment'] as Map<String, dynamic>,
      ),
      applicant: UserSummaryResponse.fromJson(
        json['applicant'] as Map<String, dynamic>,
      ),
      motivation: json['motivation'] as String?,
      questionAnswers: (json['questionAnswers'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(int.parse(key), value as String),
      ),
      status: _parseApplicationStatus(json['status'] as String),
      reviewedBy: json['reviewedBy'] != null
          ? UserSummaryResponse.fromJson(
              json['reviewedBy'] as Map<String, dynamic>,
            )
          : null,
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.parse(json['reviewedAt'] as String)
          : null,
      reviewComment: json['reviewComment'] as String?,
      appliedAt: DateTime.parse(json['appliedAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  final int id;
  final RecruitmentSummaryResponse recruitment;
  final UserSummaryResponse applicant;
  final String? motivation;
  final Map<int, String> questionAnswers;
  final ApplicationStatus status;
  final UserSummaryResponse? reviewedBy;
  final DateTime? reviewedAt;
  final String? reviewComment;
  final DateTime appliedAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'recruitment': recruitment.toJson(),
      'applicant': applicant.toJson(),
      'motivation': motivation,
      'questionAnswers': questionAnswers.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
      'status': _serializeApplicationStatus(status),
      'reviewedBy': reviewedBy?.toJson(),
      'reviewedAt': reviewedAt?.toIso8601String(),
      'reviewComment': reviewComment,
      'appliedAt': appliedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class ApplicationSummaryResponse {
  ApplicationSummaryResponse({
    required this.id,
    required this.applicant,
    this.motivation,
    required this.status,
    required this.appliedAt,
  });

  factory ApplicationSummaryResponse.fromJson(Map<String, dynamic> json) {
    return ApplicationSummaryResponse(
      id: (json['id'] as num).toInt(),
      applicant: UserSummaryResponse.fromJson(
        json['applicant'] as Map<String, dynamic>,
      ),
      motivation: json['motivation'] as String?,
      status: _parseApplicationStatus(json['status'] as String),
      appliedAt: DateTime.parse(json['appliedAt'] as String),
    );
  }

  final int id;
  final UserSummaryResponse applicant;
  final String? motivation;
  final ApplicationStatus status;
  final DateTime appliedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'applicant': applicant.toJson(),
      'motivation': motivation,
      'status': _serializeApplicationStatus(status),
      'appliedAt': appliedAt.toIso8601String(),
    };
  }
}

// ==================== Archive DTOs ====================

class ArchivedRecruitmentResponse {
  ArchivedRecruitmentResponse({
    required this.id,
    required this.group,
    required this.title,
    required this.totalApplications,
    required this.approvedApplications,
    required this.rejectedApplications,
    required this.createdAt,
    required this.closedAt,
  });

  factory ArchivedRecruitmentResponse.fromJson(Map<String, dynamic> json) {
    return ArchivedRecruitmentResponse(
      id: (json['id'] as num).toInt(),
      group: GroupSummaryResponse.fromJson(
        json['group'] as Map<String, dynamic>,
      ),
      title: json['title'] as String,
      totalApplications: (json['totalApplications'] as num).toInt(),
      approvedApplications: (json['approvedApplications'] as num).toInt(),
      rejectedApplications: (json['rejectedApplications'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      closedAt: DateTime.parse(json['closedAt'] as String),
    );
  }

  final int id;
  final GroupSummaryResponse group;
  final String title;
  final int totalApplications;
  final int approvedApplications;
  final int rejectedApplications;
  final DateTime createdAt;
  final DateTime closedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'group': group.toJson(),
      'title': title,
      'totalApplications': totalApplications,
      'approvedApplications': approvedApplications,
      'rejectedApplications': rejectedApplications,
      'createdAt': createdAt.toIso8601String(),
      'closedAt': closedAt.toIso8601String(),
    };
  }
}
