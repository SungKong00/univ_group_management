import '../entities/channel.dart';
import '../repositories/channel_repository.dart';

/// 워크스페이스의 채널 목록을 조회하는 UseCase
///
/// 비즈니스 규칙:
/// - 워크스페이스 ID는 필수이며 비어있으면 안 됨
class GetChannelListUseCase {
  final ChannelRepository _repository;

  GetChannelListUseCase(this._repository);

  /// 워크스페이스의 채널 목록 조회
  ///
  /// [workspaceId] 워크스페이스 ID
  ///
  /// Returns: 채널 목록
  ///
  /// Throws:
  /// - [ArgumentError] 입력 검증 실패 시
  /// - [Exception] Repository에서 발생한 에러
  Future<List<Channel>> call(String workspaceId) async {
    // 입력 검증
    if (workspaceId.isEmpty) {
      throw ArgumentError('워크스페이스 ID는 비어있을 수 없습니다');
    }

    // Repository 호출
    return await _repository.getChannels(workspaceId);
  }
}
