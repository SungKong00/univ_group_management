import 'package:freezed_annotation/freezed_annotation.dart';
import 'workspace_route.dart';

part 'view_context.freezed.dart';
part 'view_context.g.dart';

/// Types of views available in the workspace
enum ViewType { home, channel, calendar, admin, memberManagement }

/// Captures the type and metadata of the current view for context-aware switching
@freezed
class ViewContext with _$ViewContext {
  const factory ViewContext({
    required ViewType type,
    int? channelId, // Only for ViewType.channel
    Map<String, dynamic>? metadata, // Optional additional context
  }) = _ViewContext;

  const ViewContext._();

  /// Creates a ViewContext from a WorkspaceRoute
  factory ViewContext.fromRoute(WorkspaceRoute route) {
    return route.when(
      home: (groupId) => const ViewContext(type: ViewType.home),
      channel: (groupId, channelId) =>
          ViewContext(type: ViewType.channel, channelId: channelId),
      calendar: (groupId) => const ViewContext(type: ViewType.calendar),
      admin: (groupId) => const ViewContext(type: ViewType.admin),
      memberManagement: (groupId) =>
          const ViewContext(type: ViewType.memberManagement),
    );
  }

  factory ViewContext.fromJson(Map<String, dynamic> json) =>
      _$ViewContextFromJson(json);
}
