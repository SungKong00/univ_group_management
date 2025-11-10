/// Place model - 장소 정보를 나타내는 모델
///
/// Properties:
/// - id: 장소 ID
/// - managingGroupId: 관리 그룹 ID
/// - managingGroupName: 관리 그룹 이름
/// - building: 건물명
/// - roomNumber: 방 번호
/// - alias: 별칭 (예: "공학관 101호")
/// - displayName: 표시명 (alias가 있으면 alias, 없으면 "building roomNumber")
/// - capacity: 수용 인원
/// - createdAt: 생성 시간
/// - updatedAt: 수정 시간
class Place {
  final int id;
  final int managingGroupId;
  final String managingGroupName;
  final String building;
  final String roomNumber;
  final String? alias;
  final String displayName;
  final int? capacity;
  final DateTime createdAt;
  final DateTime updatedAt;

  Place({
    required this.id,
    required this.managingGroupId,
    required this.managingGroupName,
    required this.building,
    required this.roomNumber,
    this.alias,
    required this.displayName,
    this.capacity,
    required this.createdAt,
    required this.updatedAt,
  });

  /// JSON에서 Place 객체 생성
  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: (json['id'] as num).toInt(),
      managingGroupId: (json['managingGroupId'] as num).toInt(),
      managingGroupName: json['managingGroupName'] as String,
      building: json['building'] as String,
      roomNumber: json['roomNumber'] as String,
      alias: json['alias'] as String?,
      displayName: json['displayName'] as String,
      capacity: (json['capacity'] as num?)?.toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Place 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'managingGroupId': managingGroupId,
      'managingGroupName': managingGroupName,
      'building': building,
      'roomNumber': roomNumber,
      'alias': alias,
      'displayName': displayName,
      'capacity': capacity,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Full location string (building + roomNumber)
  String get fullLocation => '$building $roomNumber';

  @override
  String toString() =>
      'Place(id: $id, displayName: $displayName, '
      'building: $building, capacity: $capacity)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Place && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Request payload for creating a place
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
      if (alias != null) 'alias': alias,
      if (capacity != null) 'capacity': capacity,
    };
  }
}

/// Request payload for updating a place
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
      if (alias != null) 'alias': alias,
      if (capacity != null) 'capacity': capacity,
    };
  }
}
