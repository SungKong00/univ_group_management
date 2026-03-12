/// CalendarEvent 모델 (주간 뷰용)
///
/// 간소화된 캘린더 이벤트 모델로, 주간 뷰 렌더링에 필요한 최소 정보만 포함
class CalendarEvent {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String? place;
  final bool isOfficial;

  const CalendarEvent({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.place,
    required this.isOfficial,
  });

  /// JSON에서 CalendarEvent 생성
  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'].toString(),
      title: json['title'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      place: json['place'] as String?,
      isOfficial: json['isOfficial'] as bool? ?? false,
    );
  }

  /// GroupEvent에서 CalendarEvent로 변환
  ///
  /// GroupEvent의 startDate/endDate를 CalendarEvent의 startTime/endTime으로 매핑
  factory CalendarEvent.fromGroupEvent(dynamic groupEvent) {
    return CalendarEvent(
      id: groupEvent.id.toString(),
      title: groupEvent.title as String,
      startTime: groupEvent.startDate as DateTime,
      endTime: groupEvent.endDate as DateTime,
      place: groupEvent.location as String?,
      isOfficial: groupEvent.isOfficial as bool,
    );
  }

  /// CalendarEvent를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'place': place,
      'isOfficial': isOfficial,
    };
  }
}
