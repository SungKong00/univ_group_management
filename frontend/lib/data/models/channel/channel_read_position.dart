/// Channel Read Position Models
///
/// Models for tracking and managing read positions in channels.
library;

/// Represents the last read position in a channel
class ChannelReadPosition {
  final int lastReadPostId;
  final DateTime updatedAt;

  const ChannelReadPosition({
    required this.lastReadPostId,
    required this.updatedAt,
  });

  factory ChannelReadPosition.fromJson(Map<String, dynamic> json) {
    return ChannelReadPosition(
      lastReadPostId: (json['lastReadPostId'] as num).toInt(),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lastReadPostId': lastReadPostId,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChannelReadPosition &&
        other.lastReadPostId == lastReadPostId &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(lastReadPostId, updatedAt);
}

/// Response containing unread count for a channel
class UnreadCountResponse {
  final int channelId;
  final int unreadCount;

  const UnreadCountResponse({
    required this.channelId,
    required this.unreadCount,
  });

  factory UnreadCountResponse.fromJson(Map<String, dynamic> json) {
    return UnreadCountResponse(
      channelId: (json['channelId'] as num).toInt(),
      unreadCount: (json['unreadCount'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'channelId': channelId, 'unreadCount': unreadCount};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UnreadCountResponse &&
        other.channelId == channelId &&
        other.unreadCount == unreadCount;
  }

  @override
  int get hashCode => Object.hash(channelId, unreadCount);
}
