import 'dart:developer' as developer;
import '../models/channel_models.dart';
import '../models/auth_models.dart';
import '../network/dio_client.dart';

/// Channel Service
///
/// Provides API methods for fetching channels and membership information.
class ChannelService {
  static final ChannelService _instance = ChannelService._internal();
  factory ChannelService() => _instance;
  ChannelService._internal();

  final DioClient _dioClient = DioClient();

  /// Get channels for a group
  ///
  /// GET /groups/{groupId}/channels
  Future<List<Channel>> getChannels(int groupId) async {
    try {
      developer.log('Fetching channels for group: $groupId', name: 'ChannelService');

      final response = await _dioClient.get<Map<String, dynamic>>(
        '/groups/$groupId/channels',
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) {
            if (json is List) {
              return json.map((item) => Channel.fromJson(item as Map<String, dynamic>)).toList();
            }
            return <Channel>[];
          },
        );

        if (apiResponse.success && apiResponse.data != null) {
          developer.log('Successfully fetched ${apiResponse.data!.length} channels', name: 'ChannelService');
          return apiResponse.data!;
        } else {
          developer.log('Failed to fetch channels: ${apiResponse.message}', name: 'ChannelService', level: 900);
          return [];
        }
      }

      return [];
    } catch (e) {
      developer.log('Error fetching channels: $e', name: 'ChannelService', level: 900);
      return [];
    }
  }

  /// Get current user's membership information in a group
  ///
  /// GET /groups/{groupId}/members/me
  Future<MembershipInfo?> getMyMembership(int groupId) async {
    try {
      developer.log('Fetching membership info for group: $groupId', name: 'ChannelService');

      final response = await _dioClient.get<Map<String, dynamic>>(
        '/groups/$groupId/members/me',
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => MembershipInfo.fromJson(json as Map<String, dynamic>),
        );

        if (apiResponse.success && apiResponse.data != null) {
          developer.log('Successfully fetched membership info', name: 'ChannelService');
          return apiResponse.data!;
        } else {
          developer.log('Failed to fetch membership: ${apiResponse.message}', name: 'ChannelService', level: 900);
          return null;
        }
      }

      return null;
    } catch (e) {
      developer.log('Error fetching membership: $e', name: 'ChannelService', level: 900);
      return null;
    }
  }
}
