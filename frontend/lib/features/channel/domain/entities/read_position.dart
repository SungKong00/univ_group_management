/// 채널의 읽음 위치 정보
///
/// 사용자가 마지막으로 읽은 게시글의 위치를 추적합니다.
/// Domain Layer에서 사용하는 순수 값 객체입니다.
class ReadPosition {
  /// 채널 ID
  final int channelId;

  /// 마지막으로 읽은 게시글 ID
  final int lastReadPostId;

  /// 업데이트 시각
  final DateTime updatedAt;

  const ReadPosition({
    required this.channelId,
    required this.lastReadPostId,
    required this.updatedAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadPosition &&
          runtimeType == other.runtimeType &&
          channelId == other.channelId &&
          lastReadPostId == other.lastReadPostId;

  @override
  int get hashCode => channelId.hashCode ^ lastReadPostId.hashCode;
}
