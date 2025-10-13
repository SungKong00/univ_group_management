import 'package:flutter/material.dart';

/// Place model representing a physical location that can be reserved
class Place {
  const Place({
    required this.id,
    required this.managingGroupId,
    required this.building,
    required this.roomNumber,
    this.alias,
    this.capacity,
    this.deletedAt,
  });

  final String id;
  final int managingGroupId;
  final String building;
  final String roomNumber;
  final String? alias;
  final int? capacity;
  final DateTime? deletedAt;

  /// Returns the display name for the place
  /// If alias exists: "별칭 (방 번호)"
  /// Otherwise: "건물-방 번호"
  String get displayName {
    if (alias != null && alias!.isNotEmpty) {
      return '$alias ($roomNumber)';
    }
    return '$building-$roomNumber';
  }

  /// Full location string: "건물 방 번호"
  String get fullLocation => '$building $roomNumber';

  /// Check if the place is deleted (soft delete)
  bool get isDeleted => deletedAt != null;

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'] as String,
      managingGroupId: (json['managingGroupId'] as num).toInt(),
      building: json['building'] as String,
      roomNumber: json['roomNumber'] as String,
      alias: json['alias'] as String?,
      capacity: json['capacity'] as int?,
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'managingGroupId': managingGroupId,
      'building': building,
      'roomNumber': roomNumber,
      'alias': alias,
      'capacity': capacity,
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  Place copyWith({
    String? id,
    int? managingGroupId,
    String? building,
    String? roomNumber,
    String? alias,
    int? capacity,
    DateTime? deletedAt,
  }) {
    return Place(
      id: id ?? this.id,
      managingGroupId: managingGroupId ?? this.managingGroupId,
      building: building ?? this.building,
      roomNumber: roomNumber ?? this.roomNumber,
      alias: alias ?? this.alias,
      capacity: capacity ?? this.capacity,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Place && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Place(id: $id, building: $building, roomNumber: $roomNumber, alias: $alias)';
  }
}

/// Request payload for creating or updating a place
class PlaceRequest {
  const PlaceRequest({
    required this.managingGroupId,
    required this.building,
    required this.roomNumber,
    this.alias,
    this.capacity,
  });

  final int managingGroupId;
  final String building;
  final String roomNumber;
  final String? alias;
  final int? capacity;

  Map<String, dynamic> toJson() {
    return {
      'managingGroupId': managingGroupId,
      'building': building,
      'roomNumber': roomNumber,
      'alias': alias?.trim().isEmpty == true ? null : alias,
      'capacity': capacity,
    };
  }
}
