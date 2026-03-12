import '../repositories/read_position_repository.dart';

/// 읽음 위치 업데이트 UseCase
///
/// Repository를 통해 읽음 위치를 업데이트합니다.
/// Domain Layer의 단순 위임(delegation) UseCase입니다.
class UpdateReadPositionUseCase {
  final ReadPositionRepository _repository;

  UpdateReadPositionUseCase(this._repository);

  /// 읽음 위치 업데이트
  ///
  /// [channelId] 채널 ID
  /// [position] 마지막으로 읽은 게시글 ID
  Future<void> call(int channelId, int position) async {
    await _repository.updateReadPosition(channelId, position);
  }
}
