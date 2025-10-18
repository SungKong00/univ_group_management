import 'place.dart';
import 'place_availability.dart';

/// Response model for place detail API
///
/// Contains place information, availability schedules, and approved group count
///
/// DEPRECATED: availabilities field uses old PlaceAvailability system.
/// Use PlaceTimeRepository.getOperatingHours() for the new operating hours system.
class PlaceDetailResponse {
  const PlaceDetailResponse({
    required this.place,
    required this.availabilities,
    required this.approvedGroupCount,
  });

  final Place place;

  /// DEPRECATED: Use PlaceTimeRepository.getOperatingHours() instead
  /// This field uses the old PlaceAvailability system (multiple time slots per day)
  @Deprecated('Use PlaceTimeRepository.getOperatingHours() instead')
  final List<PlaceAvailability> availabilities;

  final int approvedGroupCount;

  factory PlaceDetailResponse.fromJson(Map<String, dynamic> json) {
    return PlaceDetailResponse(
      place: Place.fromJson(json['place'] as Map<String, dynamic>),
      availabilities: (json['availabilities'] as List?)
              ?.map((a) =>
                  PlaceAvailability.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      approvedGroupCount: (json['approvedGroupCount'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'place': place.toJson(),
      'availabilities': availabilities.map((a) => a.toJson()).toList(),
      'approvedGroupCount': approvedGroupCount,
    };
  }

  PlaceDetailResponse copyWith({
    Place? place,
    List<PlaceAvailability>? availabilities,
    int? approvedGroupCount,
  }) {
    return PlaceDetailResponse(
      place: place ?? this.place,
      availabilities: availabilities ?? this.availabilities,
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
        'availabilities: ${availabilities.length}, '
        'approvedGroupCount: $approvedGroupCount)';
  }
}
