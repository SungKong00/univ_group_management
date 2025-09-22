import 'auth_models.dart';

class AdminStatsModel {
  final int pendingCount;
  final int memberCount;
  final int roleCount;
  final int channelCount;

  AdminStatsModel({
    required this.pendingCount,
    required this.memberCount,
    required this.roleCount,
    required this.channelCount,
  });

  factory AdminStatsModel.fromJson(Map<String, dynamic> json) {
    return AdminStatsModel(
      pendingCount: json['pendingCount'] ?? 0,
      memberCount: json['memberCount'] ?? 0,
      roleCount: json['roleCount'] ?? 0,
      channelCount: json['channelCount'] ?? 0,
    );
  }
}

class PendingMemberModel {
  final UserModel user;
  final DateTime appliedAt;
  final String? message;

  PendingMemberModel({
    required this.user,
    required this.appliedAt,
    this.message,
  });

  factory PendingMemberModel.fromJson(Map<String, dynamic> json) {
    return PendingMemberModel(
      user: UserModel.fromJson(json['user']),
      appliedAt: DateTime.parse(json['appliedAt']),
      message: json['message'],
    );
  }
}