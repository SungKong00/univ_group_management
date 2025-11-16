import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/announcement_models.dart';
import '../../core/repositories/announcement_repository.dart';

/// Announcement Repository Provider
final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  return ApiAnnouncementRepository();
});

/// Announcement Filter State Provider
///
/// 공지사항 필터링 상태 관리
final announcementFilterProvider =
    StateProvider<AnnouncementFilter>((ref) => const AnnouncementFilter());

/// Announcement Search Query Provider
///
/// 공지사항 검색어 상태 관리
final announcementSearchQueryProvider = StateProvider<String>((ref) => '');

/// Announcement List Provider
///
/// 공지사항 목록을 가져오는 Provider
/// groupId와 filter에 따라 자동으로 캐싱됩니다.
final announcementListProvider = FutureProvider.family.autoDispose<
    List<Announcement>,
    ({int? groupId, AnnouncementFilter? filter})>((ref, params) async {
  final repository = ref.watch(announcementRepositoryProvider);

  return await repository.getAnnouncements(
    groupId: params.groupId,
    filter: params.filter,
  );
});

/// Search Announcements Provider
///
/// 검색어로 공지사항을 검색하는 Provider
final searchAnnouncementsProvider = FutureProvider.family.autoDispose<
    List<Announcement>,
    ({String query, int? groupId})>((ref, params) async {
  if (params.query.trim().isEmpty) {
    return [];
  }

  final repository = ref.watch(announcementRepositoryProvider);

  return await repository.searchAnnouncements(
    query: params.query,
    groupId: params.groupId,
  );
});

/// Announcement Management Notifier
///
/// 공지사항 CRUD 작업을 처리하는 Notifier
class AnnouncementManagementNotifier extends StateNotifier<AsyncValue<void>> {
  AnnouncementManagementNotifier(this.repository)
      : super(const AsyncValue.data(null));

  final AnnouncementRepository repository;

  /// 공지사항 생성
  Future<Announcement> createAnnouncement({
    required int channelId,
    required String title,
    required String content,
    bool isPinned = false,
  }) async {
    state = const AsyncValue.loading();

    try {
      final announcement = await repository.createAnnouncement(
        channelId: channelId,
        title: title,
        content: content,
        isPinned: isPinned,
      );

      state = const AsyncValue.data(null);
      return announcement;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  /// 공지사항 수정
  Future<Announcement> updateAnnouncement({
    required int announcementId,
    String? title,
    String? content,
    bool? isPinned,
  }) async {
    state = const AsyncValue.loading();

    try {
      final announcement = await repository.updateAnnouncement(
        announcementId: announcementId,
        title: title,
        content: content,
        isPinned: isPinned,
      );

      state = const AsyncValue.data(null);
      return announcement;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  /// 공지사항 삭제
  Future<void> deleteAnnouncement(int announcementId) async {
    state = const AsyncValue.loading();

    try {
      await repository.deleteAnnouncement(announcementId);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  /// 공지사항 고정
  Future<Announcement> pinAnnouncement(int announcementId) async {
    state = const AsyncValue.loading();

    try {
      final announcement = await repository.pinAnnouncement(announcementId);
      state = const AsyncValue.data(null);
      return announcement;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  /// 공지사항 고정 해제
  Future<Announcement> unpinAnnouncement(int announcementId) async {
    state = const AsyncValue.loading();

    try {
      final announcement = await repository.unpinAnnouncement(announcementId);
      state = const AsyncValue.data(null);
      return announcement;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }
}

/// Announcement Management Provider
final announcementManagementProvider =
    StateNotifierProvider<AnnouncementManagementNotifier, AsyncValue<void>>(
        (ref) {
  final repository = ref.watch(announcementRepositoryProvider);
  return AnnouncementManagementNotifier(repository);
});
