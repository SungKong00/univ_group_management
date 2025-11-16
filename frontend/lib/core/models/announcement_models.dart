/// Announcement model
///
/// Represents an announcement post within a group.
class Announcement {
  final int id;
  final String title;
  final String content;
  final int authorId;
  final String authorName;
  final int groupId;
  final String groupName;
  final int channelId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isPinned;

  const Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.groupId,
    required this.groupName,
    required this.channelId,
    required this.createdAt,
    this.updatedAt,
    this.isPinned = false,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      authorId: (json['authorId'] as num?)?.toInt() ?? 0,
      authorName: json['authorName'] as String? ?? '알 수 없음',
      groupId: (json['groupId'] as num?)?.toInt() ?? 0,
      groupName: json['groupName'] as String? ?? '',
      channelId: (json['channelId'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      isPinned: json['isPinned'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'groupId': groupId,
      'groupName': groupName,
      'channelId': channelId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isPinned': isPinned,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Announcement && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// AnnouncementFilter model
///
/// Represents filtering options for announcement list.
class AnnouncementFilter {
  final int? groupId;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? pinnedOnly;

  const AnnouncementFilter({
    this.groupId,
    this.startDate,
    this.endDate,
    this.pinnedOnly,
  });

  AnnouncementFilter copyWith({
    int? groupId,
    DateTime? startDate,
    DateTime? endDate,
    bool? pinnedOnly,
  }) {
    return AnnouncementFilter(
      groupId: groupId ?? this.groupId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      pinnedOnly: pinnedOnly ?? this.pinnedOnly,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (groupId != null) 'groupId': groupId,
      if (startDate != null) 'startDate': startDate!.toIso8601String(),
      if (endDate != null) 'endDate': endDate!.toIso8601String(),
      if (pinnedOnly != null) 'pinnedOnly': pinnedOnly,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnnouncementFilter &&
        other.groupId == groupId &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.pinnedOnly == pinnedOnly;
  }

  @override
  int get hashCode => Object.hash(groupId, startDate, endDate, pinnedOnly);
}
