/// Place model representing a physical location that can be reserved
class Place {
  const Place({
    required this.id,
    required this.managingGroupId,
    required this.building,
    required this.roomNumber,
    this.alias,
    required this.displayName,
    this.capacity,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int managingGroupId;
  final String building;
  final String roomNumber;
  final String? alias;
  final String displayName;
  final int? capacity;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Full location string: "건물 방 번호"
  String get fullLocation => '$building $roomNumber';

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: (json['id'] as num).toInt(),
      managingGroupId: (json['managingGroupId'] as num).toInt(),
      building: json['building'] as String,
      roomNumber: json['roomNumber'] as String,
      alias: json['alias'] as String?,
      displayName: json['displayName'] as String,
      capacity: json['capacity'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'managingGroupId': managingGroupId,
      'building': building,
      'roomNumber': roomNumber,
      'alias': alias,
      'displayName': displayName,
      'capacity': capacity,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Place copyWith({
    int? id,
    int? managingGroupId,
    String? building,
    String? roomNumber,
    String? alias,
    String? displayName,
    int? capacity,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Place(
      id: id ?? this.id,
      managingGroupId: managingGroupId ?? this.managingGroupId,
      building: building ?? this.building,
      roomNumber: roomNumber ?? this.roomNumber,
      alias: alias ?? this.alias,
      displayName: displayName ?? this.displayName,
      capacity: capacity ?? this.capacity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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

/// Request payload for creating a new place
class CreatePlaceRequest {
  const CreatePlaceRequest({
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
      if (alias != null && alias!.trim().isNotEmpty) 'alias': alias,
      if (capacity != null) 'capacity': capacity,
    };
  }
}

/// Request payload for updating an existing place
class UpdatePlaceRequest {
  const UpdatePlaceRequest({
    this.building,
    this.roomNumber,
    this.alias,
    this.capacity,
  });

  final String? building;
  final String? roomNumber;
  final String? alias;
  final int? capacity;

  Map<String, dynamic> toJson() {
    return {
      if (building != null) 'building': building,
      if (roomNumber != null) 'roomNumber': roomNumber,
      if (alias != null) 'alias': alias!.trim().isEmpty ? null : alias,
      if (capacity != null) 'capacity': capacity,
    };
  }
}
