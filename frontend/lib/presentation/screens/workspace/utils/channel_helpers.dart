import 'package:flutter/material.dart';
import '../../../../data/models/workspace_models.dart';

class ChannelHelpers {
  static IconData getChannelIcon(ChannelType type) {
    switch (type) {
      case ChannelType.text:
        return Icons.chat;
      case ChannelType.voice:
        return Icons.mic;
      case ChannelType.announcement:
        return Icons.campaign;
      case ChannelType.fileShare:
        return Icons.folder_shared;
    }
  }

  static String formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()}개월 전';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}일 전';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}시간 전';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  static String formatDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final postDate = DateTime(date.year, date.month, date.day);

    if (postDate == today) {
      return '오늘';
    } else if (postDate == yesterday) {
      return '어제';
    } else {
      return '${date.year}년 ${date.month}월 ${date.day}일';
    }
  }

  static List<PostGroup> groupPostsByDate(List<PostModel> posts) {
    final Map<String, List<PostModel>> groups = {};

    for (final post in posts) {
      final dateKey = formatDateKey(post.createdAt);
      groups.putIfAbsent(dateKey, () => []).add(post);
    }

    return groups.entries
        .map((entry) => PostGroup(date: entry.key, posts: entry.value))
        .toList();
  }
}

class PostGroup {
  final String date;
  final List<PostModel> posts;

  PostGroup({required this.date, required this.posts});
}