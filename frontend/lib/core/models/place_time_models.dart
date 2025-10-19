import 'package:flutter/foundation.dart';

/// 운영시간 응답 모델
@immutable
class OperatingHoursResponse {
  final int id;
  final String dayOfWeek; // MONDAY, TUESDAY, ...
  final String? startTime; // HH:mm 형식
  final String? endTime; // HH:mm 형식
  final bool isClosed;

  const OperatingHoursResponse({
    required this.id,
    required this.dayOfWeek,
    this.startTime,
    this.endTime,
    required this.isClosed,
  });

  factory OperatingHoursResponse.fromJson(Map<String, dynamic> json) {
    return OperatingHoursResponse(
      id: (json['id'] as num).toInt(),
      dayOfWeek: json['dayOfWeek'] as String,
      startTime: _parseTime(json['startTime']),
      endTime: _parseTime(json['endTime']),
      isClosed: json['isClosed'] as bool,
    );
  }

  /// 시간 파싱: "HH:mm:ss" 또는 "HH:mm" → "HH:mm" 변환
  static String? _parseTime(dynamic time) {
    if (time == null) return null;
    if (time is! String) return null;

    // "HH:mm:ss" → "HH:mm" (초 제거)
    if (time.contains(':')) {
      final parts = time.split(':');
      if (parts.length >= 2) {
        return '${parts[0]}:${parts[1]}';
      }
    }

    return time;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'isClosed': isClosed,
    };
  }

  OperatingHoursResponse copyWith({
    int? id,
    String? dayOfWeek,
    String? startTime,
    String? endTime,
    bool? isClosed,
  }) {
    return OperatingHoursResponse(
      id: id ?? this.id,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isClosed: isClosed ?? this.isClosed,
    );
  }
}

/// 운영시간 설정 요청 아이템
@immutable
class OperatingHoursItem {
  final String dayOfWeek;
  final String? startTime;
  final String? endTime;
  final bool isClosed;

  const OperatingHoursItem({
    required this.dayOfWeek,
    this.startTime,
    this.endTime,
    required this.isClosed,
  });

  Map<String, dynamic> toJson() {
    return {
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'isClosed': isClosed,
    };
  }

  OperatingHoursItem copyWith({
    String? dayOfWeek,
    String? startTime,
    String? endTime,
    bool? isClosed,
  }) {
    return OperatingHoursItem(
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isClosed: isClosed ?? this.isClosed,
    );
  }
}

/// 운영시간 전체 설정 요청
@immutable
class SetOperatingHoursRequest {
  final List<OperatingHoursItem> operatingHours;

  const SetOperatingHoursRequest({
    required this.operatingHours,
  });

  Map<String, dynamic> toJson() {
    return {
      'operatingHours': operatingHours.map((e) => e.toJson()).toList(),
    };
  }
}

/// 금지시간 응답 모델
@immutable
class RestrictedTimeResponse {
  final int id;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final String? reason;
  final int displayOrder;

  const RestrictedTimeResponse({
    required this.id,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.reason,
    required this.displayOrder,
  });

  factory RestrictedTimeResponse.fromJson(Map<String, dynamic> json) {
    return RestrictedTimeResponse(
      id: (json['id'] as num).toInt(),
      dayOfWeek: json['dayOfWeek'] as String,
      startTime: _parseTime(json['startTime']) ?? '',
      endTime: _parseTime(json['endTime']) ?? '',
      reason: json['reason'] as String?,
      displayOrder: (json['displayOrder'] as num).toInt(),
    );
  }

  /// 시간 파싱: "HH:mm:ss" → "HH:mm" 변환
  static String? _parseTime(dynamic time) {
    if (time == null) return null;
    if (time is! String) return null;
    final parts = time.split(':');
    return parts.length >= 2 ? '${parts[0]}:${parts[1]}' : time;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'reason': reason,
      'displayOrder': displayOrder,
    };
  }
}

/// 금지시간 추가 요청
@immutable
class AddRestrictedTimeRequest {
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final String? reason;

  const AddRestrictedTimeRequest({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'reason': reason,
    };
  }
}

/// 임시 휴무 응답 모델
@immutable
class PlaceClosureResponse {
  final int id;
  final String closureDate; // YYYY-MM-DD
  final bool isFullDay;
  final String? startTime;
  final String? endTime;
  final String? reason;

  const PlaceClosureResponse({
    required this.id,
    required this.closureDate,
    required this.isFullDay,
    this.startTime,
    this.endTime,
    this.reason,
  });

  factory PlaceClosureResponse.fromJson(Map<String, dynamic> json) {
    return PlaceClosureResponse(
      id: (json['id'] as num).toInt(),
      closureDate: json['closureDate'] as String,
      isFullDay: json['isFullDay'] as bool,
      startTime: _parseTime(json['startTime']),
      endTime: _parseTime(json['endTime']),
      reason: json['reason'] as String?,
    );
  }

  /// 시간 파싱: "HH:mm:ss" → "HH:mm" 변환
  static String? _parseTime(dynamic time) {
    if (time == null) return null;
    if (time is! String) return null;
    final parts = time.split(':');
    return parts.length >= 2 ? '${parts[0]}:${parts[1]}' : time;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'closureDate': closureDate,
      'isFullDay': isFullDay,
      'startTime': startTime,
      'endTime': endTime,
      'reason': reason,
    };
  }
}

/// 전일 휴무 추가 요청
@immutable
class AddFullDayClosureRequest {
  final String closureDate; // YYYY-MM-DD
  final String? reason;

  const AddFullDayClosureRequest({
    required this.closureDate,
    this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'closureDate': closureDate,
      'reason': reason,
    };
  }
}

/// 부분 시간 휴무 추가 요청
@immutable
class AddPartialClosureRequest {
  final String closureDate; // YYYY-MM-DD
  final String startTime; // HH:mm
  final String endTime; // HH:mm
  final String? reason;

  const AddPartialClosureRequest({
    required this.closureDate,
    required this.startTime,
    required this.endTime,
    this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'closureDate': closureDate,
      'startTime': startTime,
      'endTime': endTime,
      'reason': reason,
    };
  }
}

/// 예약 가능 시간 조회 응답
@immutable
class AvailableTimesResponse {
  final String date; // YYYY-MM-DD
  final String dayOfWeek;
  final bool isClosed;
  final OperatingHoursInfo? operatingHours;
  final List<RestrictedTimeInfo> restrictedTimes;
  final List<ClosureInfo> closures;
  final List<ReservationInfo> existingReservations;
  final List<TimeSlotInfo> availableSlots;

  const AvailableTimesResponse({
    required this.date,
    required this.dayOfWeek,
    required this.isClosed,
    this.operatingHours,
    required this.restrictedTimes,
    required this.closures,
    required this.existingReservations,
    required this.availableSlots,
  });

  factory AvailableTimesResponse.fromJson(Map<String, dynamic> json) {
    return AvailableTimesResponse(
      date: json['date'] as String,
      dayOfWeek: json['dayOfWeek'] as String,
      isClosed: json['isClosed'] as bool,
      operatingHours: json['operatingHours'] != null
          ? OperatingHoursInfo.fromJson(
              json['operatingHours'] as Map<String, dynamic>)
          : null,
      restrictedTimes: (json['restrictedTimes'] as List<dynamic>)
          .map((e) => RestrictedTimeInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      closures: (json['closures'] as List<dynamic>)
          .map((e) => ClosureInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      existingReservations: (json['existingReservations'] as List<dynamic>)
          .map((e) => ReservationInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      availableSlots: (json['availableSlots'] as List<dynamic>)
          .map((e) => TimeSlotInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

@immutable
class OperatingHoursInfo {
  final String startTime;
  final String endTime;

  const OperatingHoursInfo(this.startTime, this.endTime);

  factory OperatingHoursInfo.fromJson(Map<String, dynamic> json) {
    return OperatingHoursInfo(
      _parseTime(json['startTime']) ?? '',
      _parseTime(json['endTime']) ?? '',
    );
  }

  static String? _parseTime(dynamic time) {
    if (time == null) return null;
    if (time is! String) return null;
    final parts = time.split(':');
    return parts.length >= 2 ? '${parts[0]}:${parts[1]}' : time;
  }
}

@immutable
class RestrictedTimeInfo {
  final String startTime;
  final String endTime;
  final String? reason;

  const RestrictedTimeInfo(this.startTime, this.endTime, this.reason);

  factory RestrictedTimeInfo.fromJson(Map<String, dynamic> json) {
    return RestrictedTimeInfo(
      _parseTime(json['startTime']) ?? '',
      _parseTime(json['endTime']) ?? '',
      json['reason'] as String?,
    );
  }

  static String? _parseTime(dynamic time) {
    if (time == null) return null;
    if (time is! String) return null;
    final parts = time.split(':');
    return parts.length >= 2 ? '${parts[0]}:${parts[1]}' : time;
  }
}

@immutable
class ClosureInfo {
  final bool isFullDay;
  final String? startTime;
  final String? endTime;
  final String? reason;

  const ClosureInfo(this.isFullDay, this.startTime, this.endTime, this.reason);

  factory ClosureInfo.fromJson(Map<String, dynamic> json) {
    return ClosureInfo(
      json['isFullDay'] as bool,
      _parseTime(json['startTime']),
      _parseTime(json['endTime']),
      json['reason'] as String?,
    );
  }

  static String? _parseTime(dynamic time) {
    if (time == null) return null;
    if (time is! String) return null;
    final parts = time.split(':');
    return parts.length >= 2 ? '${parts[0]}:${parts[1]}' : time;
  }
}

@immutable
class ReservationInfo {
  final String startTime;
  final String endTime;
  final String groupName;

  const ReservationInfo(this.startTime, this.endTime, this.groupName);

  factory ReservationInfo.fromJson(Map<String, dynamic> json) {
    return ReservationInfo(
      _parseTime(json['startTime']) ?? '',
      _parseTime(json['endTime']) ?? '',
      json['groupName'] as String,
    );
  }

  static String? _parseTime(dynamic time) {
    if (time == null) return null;
    if (time is! String) return null;
    final parts = time.split(':');
    return parts.length >= 2 ? '${parts[0]}:${parts[1]}' : time;
  }
}

@immutable
class TimeSlotInfo {
  final String startTime;
  final String endTime;

  const TimeSlotInfo(this.startTime, this.endTime);

  factory TimeSlotInfo.fromJson(Map<String, dynamic> json) {
    return TimeSlotInfo(
      _parseTime(json['startTime']) ?? '',
      _parseTime(json['endTime']) ?? '',
    );
  }

  static String? _parseTime(dynamic time) {
    if (time == null) return null;
    if (time is! String) return null;
    final parts = time.split(':');
    return parts.length >= 2 ? '${parts[0]}:${parts[1]}' : time;
  }
}
