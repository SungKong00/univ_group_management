import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/workspace_state_provider.dart';
import '../../group/group_admin_page.dart';
import '../../member_management/member_management_page.dart';
import '../../admin/channel_management_page.dart';
import '../../recruitment_management/recruitment_management_page.dart';
import '../../recruitment_management/application_management_page.dart';
import '../calendar/group_calendar_page.dart';
import '../place/place_time_management_page.dart';
import '../widgets/group_home_view.dart';
import '../widgets/workspace_state_view.dart';

/// 워크스페이스의 특수 뷰(groupAdmin, memberManagement 등)를 빌드하는 Helper 클래스
class WorkspaceViewBuilder {
  /// 특수 뷰를 빌드합니다. channel 뷰인 경우 null을 반환합니다.
  static Widget? buildSpecialView(WidgetRef ref, WorkspaceView currentView) {
    if (currentView == WorkspaceView.channel) {
      return null;
    }

    switch (currentView) {
      case WorkspaceView.groupHome:
        return const GroupHomeView();

      case WorkspaceView.calendar:
        final currentGroupId = ref.watch(currentGroupIdProvider);
        if (currentGroupId == null) {
          return const WorkspaceStateView(type: WorkspaceStateType.noGroup);
        }
        final selectedCalendarDate = ref.watch(
          workspaceStateProvider.select((state) => state.selectedCalendarDate),
        );
        return GroupCalendarPage(
          groupId: int.parse(currentGroupId),
          initialSelectedDate: selectedCalendarDate,
        );

      case WorkspaceView.groupAdmin:
        return const GroupAdminPage();

      case WorkspaceView.memberManagement:
        return const MemberManagementPage();

      case WorkspaceView.channelManagement:
        return const ChannelManagementPage();

      case WorkspaceView.recruitmentManagement:
        return const RecruitmentManagementPage();

      case WorkspaceView.applicationManagement:
        return const ApplicationManagementPage();

      case WorkspaceView.placeTimeManagement:
        final placeId = ref.watch(
          workspaceStateProvider.select((state) => state.selectedPlaceId),
        );
        final placeName = ref.watch(
          workspaceStateProvider.select((state) => state.selectedPlaceName),
        );
        if (placeId == null || placeName == null) {
          return const WorkspaceStateView(type: WorkspaceStateType.noGroup);
        }
        return PlaceTimeManagementPage(placeId: placeId, placeName: placeName);

      case WorkspaceView.channel:
        return null;
    }
  }
}
