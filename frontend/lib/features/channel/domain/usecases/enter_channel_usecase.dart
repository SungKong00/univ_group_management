import '../../../post/domain/entities/pagination.dart';
import '../../../post/domain/entities/post.dart';
import '../../../post/domain/repositories/post_repository.dart';
import '../entities/channel.dart';
import '../entities/channel_entry_result.dart';
import '../entities/channel_permissions.dart';
import '../repositories/channel_repository.dart';
import '../repositories/read_position_repository.dart';
import 'calculate_unread_position_usecase.dart';

/// 채널 진입 시 필요한 모든 데이터를 병렬로 로드하는 UseCase
///
/// Race Condition 문제를 해결하기 위해 다음 데이터를 원자적으로 로드합니다:
/// 1. 채널 권한
/// 2. 마지막 읽은 위치
/// 3. 게시글 목록
///
/// Future.wait()를 사용하여 병렬 로딩을 보장하고,
/// 모든 데이터가 준비된 후 CalculateUnreadPositionUseCase로 읽지 않은 글을 계산합니다.
class EnterChannelUseCase {
  final ChannelRepository _channelRepository;
  final ReadPositionRepository _readPositionRepository;
  final PostRepository _postRepository;
  final CalculateUnreadPositionUseCase _calculateUnreadPositionUseCase;

  EnterChannelUseCase(
    this._channelRepository,
    this._readPositionRepository,
    this._postRepository,
    this._calculateUnreadPositionUseCase,
  );

  /// 채널 진입 데이터 로드
  ///
  /// [channel] 진입할 채널 정보
  ///
  /// Returns: 채널 진입에 필요한 모든 데이터 (권한, 게시글, 읽음 위치, 읽지 않은 글 계산)
  ///
  /// Throws:
  /// - [Exception] Repository에서 발생한 에러
  Future<ChannelEntryResult> call(Channel channel) async {
    // 병렬 로딩: 권한, 읽은 위치, 게시글
    final results = await Future.wait<dynamic>([
      _channelRepository.getMyPermissions(channel.id),
      _readPositionRepository.getReadPosition(channel.id),
      _postRepository.getPosts(channel.id.toString()),
    ]);

    // 타입 안전성을 위한 개별 변수 할당
    final permissions = results[0] as ChannelPermissions;
    final readPosition = results[1] as int?;
    final postsData = results[2] as (List<Post>, Pagination);
    final posts = postsData.$1;

    // 읽지 않은 글 계산 (순수 함수)
    final unreadPosition = _calculateUnreadPositionUseCase(posts, readPosition);

    // 결과 반환
    return ChannelEntryResult(
      channel: channel,
      permissions: permissions,
      posts: posts,
      readPosition: readPosition,
      unreadPosition: unreadPosition,
    );
  }
}
