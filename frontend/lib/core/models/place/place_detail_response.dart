import 'place.dart';
import 'place_availability.dart';

/// Response model for place detail API
///
/// Contains place information, availability schedules, and approved group count
class PlaceDetailResponse {
  const PlaceDetailResponse({
    required this.place,
    required this.availabilities,
    required this.approvedGroupCount,
  });

  final Place place;
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
