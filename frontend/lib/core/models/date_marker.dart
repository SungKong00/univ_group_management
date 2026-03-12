/// Date Marker Model
///
/// Flat list 구조에서 날짜 구분선을 표시하기 위한 마커 객체
/// `List<dynamic>`에 Post와 함께 들어가 날짜별 그룹 구분을 나타냄
class DateMarker {
  /// 날짜 (년-월-일만 포함, 시간 제거됨)
  final DateTime date;

  const DateMarker({required this.date});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DateMarker && other.date == date;
  }

  @override
  int get hashCode => date.hashCode;

  @override
  String toString() => 'DateMarker(date: $date)';
}
