import 'package:flutter/material.dart';
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
  static String formatRelativeTime(
    DateTime dateTime, {
    bool includeMinutes = false,
  }) {
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

  /// 주의 시작/끝 날짜 범위 계산
  ///
  /// 주어진 날짜가 속한 주의 월요일부터 일요일까지의 범위를 반환
  /// 모든 날짜는 자정(00:00:00)으로 정규화됨
  ///
  /// Example:
  /// - Input: 2025-10-16 (수요일)
  /// - Output: DateTimeRange(2025-10-14 00:00, 2025-10-20 00:00)
  static DateTimeRange weekRange(DateTime date) {
    final start = date.subtract(Duration(days: date.weekday - 1));
    final end = start.add(const Duration(days: 6));
    return DateTimeRange(
      start: normalizeToMidnight(start),
      end: normalizeToMidnight(end),
    );
  }

  /// 주 라벨 포맷 ("M/d ~ M/d")
  ///
  /// 주의 시작일(월요일)을 기준으로 해당 주의 범위를 문자열로 반환
  ///
  /// Example:
  /// - Input: 2025-10-14 (월요일)
  /// - Output: "10/14 ~ 10/20"
  static String formatWeekLabel(DateTime weekStart) {
    final end = weekStart.add(const Duration(days: 6));
    return '${weekStart.month}/${weekStart.day} ~ ${end.month}/${end.day}';
  }

  /// 주차 헤더 포맷 ("yyyy년 mm월 ww주차")
  ///
  /// 주의 시작일(월요일)을 기준으로 해당 주의 주차를 계산하여 반환
  /// 주 중간(수요일)을 기준으로 해당 월의 주차를 계산
  ///
  /// Example:
  /// - Input: 2025-10-14 (월요일)
  /// - Output: "2025년 10월 3주차"
  static String formatWeekHeader(DateTime weekStart) {
    final anchor = weekStart.add(const Duration(days: 3));
    final weekNumber = ((anchor.day - 1) ~/ 7) + 1;
    return '${anchor.year}년 ${anchor.month}월 $weekNumber주차';
  }

  /// 주차 날짜 범위 포맷 ("yyyy.mm.dd (요일) ~ yyyy.mm.dd (요일)")
  ///
  /// 주의 시작일(월요일)부터 종료일(일요일)까지의 범위를 상세 형식으로 반환
  ///
  /// Example:
  /// - Input: 2025-10-14 (월요일)
  /// - Output: "2025.10.14 (월) ~ 2025.10.20 (일)"
  static String formatWeekRangeDetailed(DateTime weekStart) {
    final end = weekStart.add(const Duration(days: 6));
    final startFormatted = DateFormat('yyyy.MM.dd (E)', 'ko_KR').format(weekStart);
    final endFormatted = DateFormat('yyyy.MM.dd (E)', 'ko_KR').format(end);
    return '$startFormatted ~ $endFormatted';
  }
}
