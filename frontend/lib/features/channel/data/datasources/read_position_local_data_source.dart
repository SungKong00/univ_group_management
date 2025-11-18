import 'package:shared_preferences/shared_preferences.dart';

/// 읽기 위치 로컬 데이터 소스 추상 클래스
abstract class ReadPositionLocalDataSource {
  /// 채널의 읽기 위치 조회
  ///
  /// [channelId] 채널 ID
  /// Returns 마지막으로 읽은 게시글 ID (없으면 null)
  Future<int?> getReadPosition(int channelId);

  /// 채널의 읽기 위치 업데이트
  ///
  /// [channelId] 채널 ID
  /// [position] 마지막으로 읽은 게시글 ID
  Future<void> updateReadPosition(int channelId, int position);
}

/// 읽기 위치 로컬 데이터 소스 구현
///
/// Shared Preferences를 사용하여 읽기 위치를 영구 저장합니다.
/// Backend API가 미구현이므로 로컬 영구 저장소로 대안 구현합니다.
class ReadPositionLocalDataSourceImpl implements ReadPositionLocalDataSource {
  /// Shared Preferences 키 prefix
  static const _keyPrefix = 'channel_read_position_';

  /// Shared Preferences 인스턴스
  SharedPreferences? _prefs;

  /// In-memory 캐시 (빠른 조회용)
  final Map<int, int> _cache = {};

  /// SharedPreferences 초기화
  Future<void> _ensureInitialized() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// 채널 ID로 저장 키 생성
  String _getKey(int channelId) => '$_keyPrefix$channelId';

  @override
  Future<int?> getReadPosition(int channelId) async {
    // 1. 캐시 우선 확인
    if (_cache.containsKey(channelId)) {
      return _cache[channelId];
    }

    // 2. Shared Preferences 조회
    await _ensureInitialized();
    final position = _prefs!.getInt(_getKey(channelId));

    // 3. 캐시 저장
    if (position != null) {
      _cache[channelId] = position;
    }

    return position;
  }

  @override
  Future<void> updateReadPosition(int channelId, int position) async {
    // 1. Shared Preferences 저장
    await _ensureInitialized();
    await _prefs!.setInt(_getKey(channelId), position);

    // 2. 캐시 갱신
    _cache[channelId] = position;
  }
}
