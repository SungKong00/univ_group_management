import 'package:freezed_annotation/freezed_annotation.dart';

part 'workspace_route.freezed.dart';
part 'workspace_route.g.dart';

/// Represents a single navigable location in the workspace
@freezed
class WorkspaceRoute with _$WorkspaceRoute {
  /// Home view route
  const factory WorkspaceRoute.home({
    required int groupId,
  }) = HomeRoute;

  /// Channel view route
  const factory WorkspaceRoute.channel({
    required int groupId,
    required int channelId,
  }) = ChannelRoute;

  /// Calendar view route
  const factory WorkspaceRoute.calendar({
    required int groupId,
  }) = CalendarRoute;

  /// Admin view route
  const factory WorkspaceRoute.admin({
    required int groupId,
  }) = AdminRoute;

  /// Member management view route
  const factory WorkspaceRoute.memberManagement({
    required int groupId,
  }) = MemberManagementRoute;

  factory WorkspaceRoute.fromJson(Map<String, dynamic> json) =>
      _$WorkspaceRouteFromJson(json);
}
