import 'place.dart';
import 'operating_hours_response.dart';

/// Response model for place detail API
///
/// Contains place information, operating hours, and approved group count
class PlaceDetailResponse {
  const PlaceDetailResponse({
    required this.place,
    required this.operatingHours,
    required this.approvedGroupCount,
  });

  final Place place;

  /// Operating hours of the place (single time slot per day of week)
  /// Consolidated model replacing the old PlaceAvailability system
  final List<OperatingHoursResponse> operatingHours;

  final int approvedGroupCount;

  factory PlaceDetailResponse.fromJson(Map<String, dynamic> json) {
    return PlaceDetailResponse(
      place: Place.fromJson(json['place'] as Map<String, dynamic>),
      operatingHours: (json['operatingHours'] as List?)
              ?.map((oh) =>
                  OperatingHoursResponse.fromJson(oh as Map<String, dynamic>))
              .toList() ??
          [],
      approvedGroupCount: (json['approvedGroupCount'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'place': place.toJson(),
      'operatingHours': operatingHours.map((oh) => oh.toJson()).toList(),
      'approvedGroupCount': approvedGroupCount,
    };
  }

  PlaceDetailResponse copyWith({
    Place? place,
    List<OperatingHoursResponse>? operatingHours,
    int? approvedGroupCount,
  }) {
    return PlaceDetailResponse(
      place: place ?? this.place,
      operatingHours: operatingHours ?? this.operatingHours,
      approvedGroupCount: approvedGroupCount ?? this.approvedGroupCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PlaceDetailResponse && other.place.id == place.id;
  }

  @override
  int get hashCode => place.id.hashCode;

  @override
  String toString() {
    return 'PlaceDetailResponse(place: ${place.displayName}, '
        'operatingHours: ${operatingHours.length}, '
        'approvedGroupCount: $approvedGroupCount)';
  }
}
