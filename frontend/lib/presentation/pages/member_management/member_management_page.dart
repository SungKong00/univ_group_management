import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme.dart';
import '../../providers/workspace_state_provider.dart';
import '../../widgets/common/compact_tab_bar.dart';
import 'widgets/member_list_section.dart';
import 'widgets/role_management_section.dart';
import 'widgets/join_request_section.dart';

/// 멤버 관리 페이지
///
/// 3개의 탭으로 구성:
/// 1. 멤버 목록: 현재 그룹 멤버 조회 및 역할 변경
/// 2. 역할 관리: 그룹 역할 설정 및 권한 매트릭스
/// 3. 가입 신청: 대기 중인 가입 신청 승인/거절
class MemberManagementPage extends ConsumerStatefulWidget {
  const MemberManagementPage({super.key});

  @override
  ConsumerState<MemberManagementPage> createState() =>
      _MemberManagementPageState();
}

class _MemberManagementPageState extends ConsumerState<MemberManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupIdStr = ref.watch(currentGroupIdProvider);

    if (groupIdStr == null) {
      return _buildEmptyState('그룹을 선택해주세요');
    }

    final groupId = int.parse(groupIdStr);
    final isDesktop = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return Container(
      color: AppColors.neutral100,
      child: Column(
        children: [
          // 컴팩트 탭 바 (높이 최적화)
          CompactTabBar(
            controller: _tabController,
            tabs: const [
              CompactTab(
                icon: Icons.people_outline,
                label: '멤버 목록',
              ),
              CompactTab(
                icon: Icons.admin_panel_settings_outlined,
                label: '역할 관리',
              ),
              CompactTab(
                icon: Icons.inbox_outlined,
                label: '가입 신청',
              ),
            ],
            labelColor: AppColors.brand,
            unselectedLabelColor: AppColors.neutral600,
            backgroundColor: Colors.white,
            indicatorColor: AppColors.brand,
          ),
          // 탭 뷰
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 멤버 목록 탭
                SingleChildScrollView(
                  padding: EdgeInsets.all(
                    isDesktop ? AppSpacing.lg : AppSpacing.sm,
                  ),
                  child: MemberListSection(
                    groupId: groupId,
                    isDesktop: isDesktop,
                  ),
                ),
                // 역할 관리 탭
                SingleChildScrollView(
                  padding: EdgeInsets.all(
                    isDesktop ? AppSpacing.lg : AppSpacing.sm,
                  ),
                  child: RoleManagementSection(
                    groupId: groupId,
                    isDesktop: isDesktop,
                  ),
                ),
                // 가입 신청 탭
                SingleChildScrollView(
                  padding: EdgeInsets.all(
                    isDesktop ? AppSpacing.lg : AppSpacing.sm,
                  ),
                  child: JoinRequestSection(
                    groupId: groupId,
                    isDesktop: isDesktop,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      color: AppColors.neutral100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: AppColors.neutral400),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTheme.bodyLarge.copyWith(color: AppColors.neutral600),
            ),
          ],
        ),
      ),
    );
  }
}
