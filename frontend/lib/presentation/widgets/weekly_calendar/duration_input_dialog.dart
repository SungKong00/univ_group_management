import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Dialog for selecting duration when multiple places are selected
class DurationInputDialog extends StatefulWidget {
  const DurationInputDialog({
    Key? key,
  }) : super(key: key);

  @override
  State<DurationInputDialog> createState() => _DurationInputDialogState();
}

class _DurationInputDialogState extends State<DurationInputDialog> {
  late Duration _selectedDuration;

  // Duration options: 15-minute increments from 15 minutes to 8 hours
  static const List<Duration> _durationOptions = [
    Duration(minutes: 15),    // 15분
    Duration(minutes: 30),    // 30분
    Duration(minutes: 45),    // 45분
    Duration(hours: 1),       // 1시간
    Duration(hours: 1, minutes: 15),  // 1시간 15분
    Duration(hours: 1, minutes: 30),  // 1시간 30분
    Duration(hours: 1, minutes: 45),  // 1시간 45분
    Duration(hours: 2),       // 2시간
    Duration(hours: 2, minutes: 15),  // 2시간 15분
    Duration(hours: 2, minutes: 30),  // 2시간 30분
    Duration(hours: 2, minutes: 45),  // 2시간 45분
    Duration(hours: 3),       // 3시간
    Duration(hours: 3, minutes: 15),  // 3시간 15분
    Duration(hours: 3, minutes: 30),  // 3시간 30분
    Duration(hours: 3, minutes: 45),  // 3시간 45분
    Duration(hours: 4),       // 4시간
    Duration(hours: 4, minutes: 15),  // 4시간 15분
    Duration(hours: 4, minutes: 30),  // 4시간 30분
    Duration(hours: 4, minutes: 45),  // 4시간 45분
    Duration(hours: 5),       // 5시간
    Duration(hours: 5, minutes: 15),  // 5시간 15분
    Duration(hours: 5, minutes: 30),  // 5시간 30분
    Duration(hours: 5, minutes: 45),  // 5시간 45분
    Duration(hours: 6),       // 6시간
    Duration(hours: 6, minutes: 15),  // 6시간 15분
    Duration(hours: 6, minutes: 30),  // 6시간 30분
    Duration(hours: 6, minutes: 45),  // 6시간 45분
    Duration(hours: 7),       // 7시간
    Duration(hours: 7, minutes: 15),  // 7시간 15분
    Duration(hours: 7, minutes: 30),  // 7시간 30분
    Duration(hours: 7, minutes: 45),  // 7시간 45분
    Duration(hours: 8),       // 8시간
  ];

  @override
  void initState() {
    super.initState();
    // Default to 1 hour
    _selectedDuration = const Duration(hours: 1);
  }

  /// Convert duration to display string
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (minutes == 0) {
      return '${hours}시간';
    } else {
      return '${hours}시간 ${minutes}분';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('일정의 예상 소요 시간을 선택하세요'),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 16,
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: DropdownButton<Duration>(
          value: _selectedDuration,
          isExpanded: true,
          underline: Container(
            height: 1,
            color: AppColors.neutral300,
          ),
          items: _durationOptions.map((duration) {
            return DropdownMenuItem<Duration>(
              value: duration,
              child: Text(_formatDuration(duration)),
            );
          }).toList(),
          onChanged: (Duration? value) {
            if (value != null) {
              setState(() {
                _selectedDuration = value;
              });
            }
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(
            '취소',
            style: TextStyle(
              color: AppColors.neutral600,
            ),
          ),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, _selectedDuration);
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.brand,
          ),
          child: const Text(
            '확인',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
