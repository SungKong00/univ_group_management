import '../repositories/read_position_repository.dart';

/// 읽음 위치 조회 UseCase
///
/// Repository를 통해 읽음 위치를 조회합니다.
/// Domain Layer의 단순 위임(delegation) UseCase입니다.
class GetReadPositionUseCase {
  final ReadPositionRepository _repository;

  GetReadPositionUseCase(this._repository);

  /// 읽음 위치 조회
  ///
  /// [channelId] 채널 ID
  /// Returns: 마지막으로 읽은 게시글 ID (없으면 null)
  Future<int?> call(int channelId) async {
    return await _repository.getReadPosition(channelId);
  }
}
