import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../post/domain/entities/post.dart';
import 'channel.dart';
import 'channel_permissions.dart';

part 'channel_entry_result.freezed.dart';

/// 채널 진입 시 필요한 모든 데이터를 담는 결과 객체
///
/// EnterChannelUseCase가 병렬로 로드한 데이터를 하나로 묶어 반환합니다.
/// 이를 통해 Race Condition 문제를 해결하고 원자적인 채널 진입을 보장합니다.
@freezed
class ChannelEntryResult with _$ChannelEntryResult {
  const factory ChannelEntryResult({
    /// 채널 정보
    required Channel channel,

    /// 현재 사용자의 채널 권한
    required ChannelPermissions permissions,

    /// 채널의 게시글 목록
    required List<Post> posts,

    /// 마지막으로 읽은 게시글 ID (없으면 null)
    int? readPosition,
  }) = _ChannelEntryResult;
}
