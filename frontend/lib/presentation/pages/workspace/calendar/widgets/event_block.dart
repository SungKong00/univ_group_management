import 'package:flutter/material.dart';
import '../../../../../data/models/calendar/calendar_event.dart';

/// 주간 뷰 일정 블록
/// 시간 → 위치 계산, 공식/비공식 스타일
class EventBlock extends StatelessWidget {
  final CalendarEvent event;
  final VoidCallback onTap;
  final double width;
  final double leftOffset;

  const EventBlock({
    super.key,
    required this.event,
    required this.onTap,
    this.width = double.infinity,
    this.leftOffset = 0,
  });

  static const double hourHeight = 60.0;
  static const int startHour = 6;

  @override
  Widget build(BuildContext context) {
    final position = _calculatePosition();

    return Positioned(
      top: position.top,
      left: 4 + leftOffset, // 좌측 여백(4px) + 겹침 오프셋
      width: width,
      height: position.height,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(right: 4, bottom: 2),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: event.isOfficial
                ? const Color(0xFFEDE7F6) // brandLight
                : const Color(0xFFF5F5F5), // neutral100
            border: Border(
              left: BorderSide(
                color: event.isOfficial
                    ? const Color(0xFF6A1B9A) // brandPrimary
                    : const Color(0xFF9E9E9E), // neutral500
                width: 3,
              ),
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: ClipRect(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  event.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: event.isOfficial
                        ? const Color(0xFF4A148C) // brandStrong
                        : const Color(0xFF212121), // neutral900
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (position.height > 40) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${_formatTime(event.startTime)}~${_formatTime(event.endTime)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF757575), // neutral600
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (event.place != null && position.height > 65) ...[
                    const SizedBox(height: 2),
                    Text(
                      event.place!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9E9E9E), // neutral500
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  ({double top, double height}) _calculatePosition() {
    final startMinutes = event.startTime.hour * 60 + event.startTime.minute;
    final endMinutes = event.endTime.hour * 60 + event.endTime.minute;
    final startOffsetMinutes = (startHour * 60);

    final top = ((startMinutes - startOffsetMinutes) / 60) * hourHeight;
    final height = ((endMinutes - startMinutes) / 60) * hourHeight;

    // 최소 높이 30px: 제목(13px) + 패딩(8px) + 여백(9px)을 고려한 안전한 최소값
    return (
      top: top.clamp(0, double.infinity),
      height: height.clamp(30, double.infinity),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
