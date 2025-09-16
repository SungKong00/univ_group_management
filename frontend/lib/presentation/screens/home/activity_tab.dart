import 'package:flutter/material.dart';

class ActivityTab extends StatelessWidget {
  const ActivityTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Skeleton list of recent activities
    final activities = List.generate(12, (i) => '활동 항목 ${i + 1}');

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        return ListTile(
          leading: const Icon(Icons.notifications_none),
          title: Text(activities[index]),
          subtitle: const Text('최근 알림/변경사항에 대한 설명'),
          onTap: () {},
        );
      },
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemCount: activities.length,
    );
  }
}