
import 'package:flutter/material.dart';
import '../../widgets/weekly_calendar/weekly_schedule_editor.dart';

class WeeklyCalendarDemoPage extends StatelessWidget {
  const WeeklyCalendarDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('주간 캘린더 데모'),
      ),
      body: const WeeklyScheduleEditor(),
    );
  }
}
