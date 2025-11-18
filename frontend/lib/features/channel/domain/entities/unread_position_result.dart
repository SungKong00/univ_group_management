import 'package:freezed_annotation/freezed_annotation.dart';

part 'unread_position_result.freezed.dart';

/// 읽지 않은 게시글 위치 계산 결과
///
/// CalculateUnreadPositionUseCase가 반환하는 결과 객체입니다.
/// 게시글 목록과 마지막 읽은 위치를 기반으로 계산된 결과를 담습니다.
@freezed
class UnreadPositionResult with _$UnreadPositionResult {
  const factory UnreadPositionResult({
    /// 읽지 않은 첫 게시글의 인덱스 (모두 읽었으면 null)
    int? unreadIndex,

    /// 읽지 않은 게시글 총 개수
    @Default(0) int totalUnread,

    /// 읽지 않은 게시글이 있는지 여부
    @Default(false) bool hasUnread,
  }) = _UnreadPositionResult;
}
