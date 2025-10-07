import 'package:intl/intl.dart';

/// 날짜/시간 포맷팅 유틸리티 클래스
///
/// 상대 시간 표시 및 한국어 날짜 포맷팅 제공
class DateFormatter {
  DateFormatter._();

  static final _timeFormatter = DateFormat('a h:mm', 'ko_KR');
  static final _dateFormatter = DateFormat('M월 d일', 'ko_KR');
  static final _fullDateFormatter = DateFormat('yyyy년 M월 d일', 'ko_KR');

  /// 상대 시간으로 포맷팅 (분 단위 포함)
  ///
  /// Examples:
  /// - 1분 이내: "방금 전"
  /// - 1시간 이내: "N분 전"
  /// - 24시간 이내: "N시간 전"
  /// - 어제: "어제"
  /// - 1주일 이내: "N일 전"
  /// - 그 외: "M월 d일"
  static String formatRelativeTime(DateTime dateTime, {bool includeMinutes = false}) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (includeMinutes) {
      if (difference.inMinutes < 1) {
        return '방금 전';
      }
      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}분 전';
      }
      if (difference.inHours < 24) {
        return '${difference.inHours}시간 전';
      }
    }

    // 오늘 날짜면 시간만 표시
    if (difference.inDays == 0) {
      return _timeFormatter.format(dateTime);
    }

    // 어제면 "어제" 표시
    if (difference.inDays == 1) {
      return '어제';
    }

    // 일주일 이내면 상대 시간
    if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    }

    // 그 외는 날짜 표시
    return _dateFormatter.format(dateTime);
  }

  /// 시간만 포맷팅 (예: "오후 3:45")
  static String formatTime(DateTime dateTime) {
    return _timeFormatter.format(dateTime);
  }

  /// 날짜만 포맷팅 (예: "3월 15일")
  static String formatDate(DateTime dateTime) {
    return _dateFormatter.format(dateTime);
  }

  /// 전체 날짜 포맷팅 (예: "2025년 3월 15일")
  static String formatFullDate(DateTime dateTime) {
    return _fullDateFormatter.format(dateTime);
  }

  /// 날짜를 자정 기준으로 정규화 (시간 제거)
  static DateTime normalizeToMidnight(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }
}
