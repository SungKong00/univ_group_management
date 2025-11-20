import 'package:freezed_annotation/freezed_annotation.dart';

part 'unread_position_result.freezed.dart';

/// 읽지 않은 글 계산 결과
///
/// CalculateUnreadPositionUseCase의 반환값으로 사용됩니다.
/// 순수 함수 계산 결과를 담는 Domain Entity입니다.
@freezed
class UnreadPositionResult with _$UnreadPositionResult {
  const factory UnreadPositionResult({
    /// 첫 번째 읽지 않은 게시글의 인덱스
    /// null이면 모든 게시글을 읽은 상태
    required int? unreadIndex,

    /// 읽지 않은 게시글 총 개수
    @Default(0) int totalUnread,

    /// 읽지 않은 게시글이 있는지 여부
    @Default(false) bool hasUnread,
  }) = _UnreadPositionResult;
}
