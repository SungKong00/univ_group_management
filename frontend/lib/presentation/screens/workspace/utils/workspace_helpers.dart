import 'package:flutter/material.dart';
import '../../../../data/models/workspace_models.dart';

class WorkspaceHelpers {
  static IconData channelIconFor(ChannelModel channel) {
    switch (channel.type) {
      case ChannelType.text:
        return Icons.chat_bubble_outline;
      case ChannelType.voice:
        return Icons.mic_none;
      case ChannelType.announcement:
        return Icons.campaign;
      case ChannelType.fileShare:
        return Icons.folder_copy_outlined;
    }
  }

  static String formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  static String formatDateTime(DateTime date) {
    final datePart = formatDate(date);
    final timePart =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return '$datePart $timePart';
  }

  static String roleDisplayName(String roleName) {
    switch (roleName.toUpperCase()) {
      case 'OWNER':
        return '그룹장';
      case 'ADVISOR':
        return '지도교수';
      default:
        return roleName;
    }
  }

  static ChannelModel? findAnnouncementChannel(List<ChannelModel> channels) {
    for (final channel in channels) {
      if (channel.type == ChannelType.announcement) {
        return channel;
      }
    }
    return null;
  }
}