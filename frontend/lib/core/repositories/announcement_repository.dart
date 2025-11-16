import 'dart:developer' as developer;
import '../models/announcement_models.dart';
import '../models/auth_models.dart';
import '../network/dio_client.dart';

/// 공지사항 관리 Repository
///
/// 공지사항 CRUD 및 검색 기능 제공
abstract class AnnouncementRepository {
  Future<List<Announcement>> getAnnouncements({
    int? groupId,
    AnnouncementFilter? filter,
    int page = 0,
    int size = 20,
  });

  Future<List<Announcement>> searchAnnouncements({
    required String query,
    int? groupId,
    int page = 0,
    int size = 20,
  });

  Future<Announcement> createAnnouncement({
    required int channelId,
    required String title,
    required String content,
    bool isPinned = false,
  });

  Future<Announcement> updateAnnouncement({
    required int announcementId,
    String? title,
    String? content,
    bool? isPinned,
  });

  Future<void> deleteAnnouncement(int announcementId);

  Future<Announcement> pinAnnouncement(int announcementId);

  Future<Announcement> unpinAnnouncement(int announcementId);
}

/// API 구현체
class ApiAnnouncementRepository implements AnnouncementRepository {
  final DioClient _dioClient = DioClient();

  @override
  Future<List<Announcement>> getAnnouncements({
    int? groupId,
    AnnouncementFilter? filter,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': page,
        'size': size,
      };

      if (groupId != null) {
        queryParameters['groupId'] = groupId;
      }

      if (filter != null) {
        if (filter.startDate != null) {
          queryParameters['startDate'] = filter.startDate!.toIso8601String();
        }
        if (filter.endDate != null) {
          queryParameters['endDate'] = filter.endDate!.toIso8601String();
        }
        if (filter.pinnedOnly != null) {
          queryParameters['pinnedOnly'] = filter.pinnedOnly;
        }
      }

      final response = await _dioClient.get<Map<String, dynamic>>(
        '/announcements',
        queryParameters: queryParameters,
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(response.data!, (json) {
          // PagedApiResponse 구조 처리
          if (json is Map<String, dynamic> && json.containsKey('content')) {
            final content = json['content'];
            if (content is List) {
              return content
                  .map((item) => Announcement.fromJson(item as Map<String, dynamic>))
                  .toList();
            }
          }
          // 일반 리스트 구조 처리
          if (json is List) {
            return json
                .map((item) => Announcement.fromJson(item as Map<String, dynamic>))
                .toList();
          }
          return <Announcement>[];
        });

        if (apiResponse.success && apiResponse.data != null) {
          return apiResponse.data!;
        } else {
          developer.log(
            'Failed to fetch announcements: ${apiResponse.message}',
            name: 'ApiAnnouncementRepository',
            level: 900,
          );
          throw Exception(apiResponse.message ?? '공지사항을 불러오지 못했습니다');
        }
      }

      throw Exception('서버로부터 응답이 없습니다');
    } catch (e) {
      developer.log(
        'Error fetching announcements: $e',
        name: 'ApiAnnouncementRepository',
        level: 900,
      );
      rethrow;
    }
  }

  @override
  Future<List<Announcement>> searchAnnouncements({
    required String query,
    int? groupId,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'query': query,
        'page': page,
        'size': size,
      };

      if (groupId != null) {
        queryParameters['groupId'] = groupId;
      }

      final response = await _dioClient.get<Map<String, dynamic>>(
        '/announcements/search',
        queryParameters: queryParameters,
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(response.data!, (json) {
          if (json is Map<String, dynamic> && json.containsKey('content')) {
            final content = json['content'];
            if (content is List) {
              return content
                  .map((item) => Announcement.fromJson(item as Map<String, dynamic>))
                  .toList();
            }
          }
          if (json is List) {
            return json
                .map((item) => Announcement.fromJson(item as Map<String, dynamic>))
                .toList();
          }
          return <Announcement>[];
        });

        if (apiResponse.success && apiResponse.data != null) {
          return apiResponse.data!;
        } else {
          throw Exception(apiResponse.message ?? '공지사항 검색에 실패했습니다');
        }
      }

      throw Exception('서버로부터 응답이 없습니다');
    } catch (e) {
      developer.log(
        'Error searching announcements: $e',
        name: 'ApiAnnouncementRepository',
        level: 900,
      );
      rethrow;
    }
  }

  @override
  Future<Announcement> createAnnouncement({
    required int channelId,
    required String title,
    required String content,
    bool isPinned = false,
  }) async {
    try {
      final response = await _dioClient.post<Map<String, dynamic>>(
        '/channels/$channelId/posts',
        data: {
          'title': title,
          'content': content,
          'isPinned': isPinned,
        },
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => Announcement.fromJson(json as Map<String, dynamic>),
        );

        if (apiResponse.success && apiResponse.data != null) {
          return apiResponse.data!;
        } else {
          throw Exception(apiResponse.message ?? '공지사항 작성에 실패했습니다');
        }
      }

      throw Exception('서버로부터 응답이 없습니다');
    } catch (e) {
      developer.log(
        'Error creating announcement: $e',
        name: 'ApiAnnouncementRepository',
        level: 900,
      );
      rethrow;
    }
  }

  @override
  Future<Announcement> updateAnnouncement({
    required int announcementId,
    String? title,
    String? content,
    bool? isPinned,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (content != null) data['content'] = content;
      if (isPinned != null) data['isPinned'] = isPinned;

      final response = await _dioClient.put<Map<String, dynamic>>(
        '/posts/$announcementId',
        data: data,
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => Announcement.fromJson(json as Map<String, dynamic>),
        );

        if (apiResponse.success && apiResponse.data != null) {
          return apiResponse.data!;
        } else {
          throw Exception(apiResponse.message ?? '공지사항 수정에 실패했습니다');
        }
      }

      throw Exception('서버로부터 응답이 없습니다');
    } catch (e) {
      developer.log(
        'Error updating announcement: $e',
        name: 'ApiAnnouncementRepository',
        level: 900,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteAnnouncement(int announcementId) async {
    try {
      final response = await _dioClient.delete<Map<String, dynamic>>(
        '/posts/$announcementId',
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => null,
        );

        if (!apiResponse.success) {
          throw Exception(apiResponse.message ?? '공지사항 삭제에 실패했습니다');
        }
      }
    } catch (e) {
      developer.log(
        'Error deleting announcement: $e',
        name: 'ApiAnnouncementRepository',
        level: 900,
      );
      rethrow;
    }
  }

  @override
  Future<Announcement> pinAnnouncement(int announcementId) async {
    return updateAnnouncement(
      announcementId: announcementId,
      isPinned: true,
    );
  }

  @override
  Future<Announcement> unpinAnnouncement(int announcementId) async {
    return updateAnnouncement(
      announcementId: announcementId,
      isPinned: false,
    );
  }
}
