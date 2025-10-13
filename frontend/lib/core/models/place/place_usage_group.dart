/// Enum for place usage permission status
enum UsageStatus {
  /// Waiting for approval
  PENDING,

  /// Approved and can make reservations
  APPROVED,

  /// Rejected by managing group
  REJECTED,
}

/// Model representing a group's permission status for using a place
class PlaceUsageGroup {
  const PlaceUsageGroup({
    required this.id,
    required this.placeId,
    required this.placeName,
    required this.groupId,
    required this.groupName,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int placeId;
  final String placeName;
  final int groupId;
  final String groupName;
  final UsageStatus status;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory PlaceUsageGroup.fromJson(Map<String, dynamic> json) {
    return PlaceUsageGroup(
      id: (json['id'] as num).toInt(),
      placeId: (json['placeId'] as num).toInt(),
      placeName: json['placeName'] as String,
      groupId: (json['groupId'] as num).toInt(),
      groupName: json['groupName'] as String,
      status: UsageStatus.values.byName(json['status'] as String),
      rejectionReason: json['rejectionReason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'placeId': placeId,
      'placeName': placeName,
      'groupId': groupId,
      'groupName': groupName,
      'status': status.name,
      'rejectionReason': rejectionReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  PlaceUsageGroup copyWith({
    int? id,
    int? placeId,
    String? placeName,
    int? groupId,
    String? groupName,
    UsageStatus? status,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlaceUsageGroup(
      id: id ?? this.id,
      placeId: placeId ?? this.placeId,
      placeName: placeName ?? this.placeName,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PlaceUsageGroup && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PlaceUsageGroup(id: $id, placeId: $placeId, placeName: $placeName, groupId: $groupId, groupName: $groupName, status: $status)';
  }
}

/// Request payload for creating a usage permission request
class CreateUsageRequestRequest {
  const CreateUsageRequestRequest({
    this.reason,
  });

  final String? reason;

  Map<String, dynamic> toJson() {
    return {
      if (reason != null && reason!.trim().isNotEmpty) 'reason': reason,
    };
  }
}

/// Request payload for updating usage permission status
class UpdateUsageStatusRequest {
  const UpdateUsageStatusRequest({
    required this.status,
    this.rejectionReason,
  });

  final UsageStatus status;
  final String? rejectionReason;

  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      if (rejectionReason != null && rejectionReason!.trim().isNotEmpty)
        'rejectionReason': rejectionReason,
    };
  }
}
