import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/workspace_state_provider.dart';
import '../../providers/current_group_provider.dart';
import '../../providers/my_groups_provider.dart';
import '../../widgets/dialogs/edit_group_dialog.dart';
import '../../widgets/cards/action_card.dart';
import 'widgets/subgroup_request_section.dart';
import 'providers/subgroup_request_provider.dart';

/// 그룹 관리자 페이지
///
/// 권한 기반 조건부 렌더링으로 관리 기능을 제공합니다.
/// 토스 디자인 철학 적용:
/// - Simplicity First: 한 화면에 한 가지 목적 (그룹 관리)
/// - One Thing Per Page: 섹션별 명확한 분리
/// - Title + Description 패턴: ActionCard로 직관적 네비게이션
class GroupAdminPage extends ConsumerWidget {
  const GroupAdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    // 권한 확인
    if (user == null) {
      return const _EmptyPermissionView(message: '로그인이 필요합니다.');
    }

    // Get permissions from workspace state (already loaded)
    final permissions =
        ref.watch(workspaceCurrentGroupPermissionsProvider) ?? [];

    // globalRole ADMIN은 모든 권한 보유 (백엔드와 일치)
    final isAdmin = user.globalRole == 'ADMIN';
    final effectivePermissions = isAdmin
        ? [
            'GROUP_MANAGE',
            'MEMBER_MANAGE',
            'CHANNEL_MANAGE',
            'RECRUITMENT_MANAGE',
          ]
        : permissions;

    final hasAdminAccess = effectivePermissions.isNotEmpty;

    if (!hasAdminAccess) {
      return const _EmptyPermissionView(message: '그룹 관리 권한이 없습니다.');
    }

    // 반응형 레이아웃 결정
    final isDesktop = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return Container(
      color: AppColors.neutral100,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? AppSpacing.lg : AppSpacing.sm),
        child: _AdminContentView(
          permissions: effectivePermissions,
          isDesktop: isDesktop,
        ),
      ),
    );
  }
}

/// 권한 없음 안내 화면
class _EmptyPermissionView extends StatelessWidget {
  final String message;

  const _EmptyPermissionView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.neutral100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: AppColors.neutral400),
            SizedBox(height: AppSpacing.md),
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

/// 관리 기능 콘텐츠 (권한별 조건부 렌더링)
class _AdminContentView extends ConsumerWidget {
  final List<String> permissions;
  final bool isDesktop;

  const _AdminContentView({required this.permissions, required this.isDesktop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentGroup = ref.watch(currentGroupProvider);

    // Permission-Centric 접근: 각 권한별 섹션 생성
    final sections = <Widget>[];

    // 하위 그룹 생성 요청 관리 섹션 (GROUP_MANAGE 권한 필요)
    final subGroupRequestSection = permissions.contains('GROUP_MANAGE')
        ? _buildSubGroupRequestSection(context, ref)
        : null;

    // 멤버 관리 섹션
    if (permissions.contains('MEMBER_MANAGE')) {
      sections.add(_buildMemberManagementSection(context, ref));
    }

    // 채널 관리 섹션
    if (permissions.contains('CHANNEL_MANAGE')) {
      sections.add(_buildChannelManagementSection(context));
    }

    // 모집 관리 섹션
    if (permissions.contains('RECRUITMENT_MANAGE')) {
      sections.add(_buildRecruitmentSection(context, ref));
    }

    // 그룹 설정 섹션
    if (permissions.contains('GROUP_MANAGE')) {
      sections.add(_buildGroupSettingsSection(context, ref));
    }

    // 대기 중인 하위 그룹 생성 신청 개수 확인하여 섹션 배치
    // 대기 신청 개수에 따라 위치를 동적으로 결정
    if (subGroupRequestSection != null && currentGroup != null) {
      final pendingCountAsync =
          ref.watch(pendingSubGroupRequestCountProvider(currentGroup.id));

      // 대기 신청이 있는지에 따라 섹션 위치 결정
      final shouldInsertAtTop = pendingCountAsync.when(
        data: (count) => count > 0,
        // 로딩 중일 때는 최상단에 배치
        loading: () => true,
        // 에러 발생 시에도 최상단에 배치
        error: (_, __) => true,
      );

      if (shouldInsertAtTop) {
        sections.insert(0, subGroupRequestSection);
      } else {
        // 대기 신청 없음: 최하단에 배치
        sections.add(subGroupRequestSection);
      }
    } else if (subGroupRequestSection != null) {
      // currentGroup이 null이면 일단 최상단에 배치
      sections.insert(0, subGroupRequestSection);
    }

    if (sections.isEmpty) {
      return Center(
        child: Text(
          '사용 가능한 관리 기능이 없습니다.',
          style: AppTheme.bodyLarge.copyWith(color: AppColors.neutral600),
        ),
      );
    }

    // 반응형 레이아웃: 데스크톱에서 섹션을 2열로 배치
    if (isDesktop) {
      return LayoutBuilder(
        builder: (context, constraints) {
          // 실제 사용 가능한 너비(사이드바 제외)를 기준으로 계산
          final availableWidth = constraints.maxWidth;

          // 너비가 충분할 때만 2열, 좁아지면 1열로 전환
          // 각 섹션의 최소 너비를 500px로 설정 (카드들이 제대로 보이기 위한 최소 공간)
          const minSectionWidth = 325.0;
          final shouldUseDoubleColumn = availableWidth >= (minSectionWidth * 2 + AppSpacing.md);

          if (shouldUseDoubleColumn) {
            // 2열 레이아웃
            final sectionWidth = (availableWidth - AppSpacing.md) / 2;
            return Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: sections
                  .map((section) => SizedBox(width: sectionWidth, child: section))
                  .toList(),
            );
          } else {
            // 1열 레이아웃 (너비가 좁을 때)
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children:
                  sections
                      .expand((section) => [section, SizedBox(height: AppSpacing.md)])
                      .toList()
                    ..removeLast(), // 마지막 SizedBox 제거
            );
          }
        },
      );
    }

    // 모바일: 세로 배치
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children:
          sections
              .expand((section) => [section, SizedBox(height: AppSpacing.md)])
              .toList()
            ..removeLast(), // 마지막 SizedBox 제거
    );
  }

  Widget _buildSubGroupRequestSection(BuildContext context, WidgetRef ref) {
    final currentGroup = ref.watch(currentGroupProvider);
    if (currentGroup == null) {
      return const SizedBox.shrink();
    }

    return _AdminSection(
      title: '하위 그룹 생성 신청',
      description: '대기 중인 하위 그룹 생성 신청을 승인하거나 거절하세요',
      icon: Icons.account_tree_outlined,
      expandableContent: SubGroupRequestSection(
        groupId: currentGroup.id,
        isDesktop: isDesktop,
      ),
      isDesktop: isDesktop,
    );
  }

  Widget _buildGroupSettingsSection(BuildContext context, WidgetRef ref) {
    return _AdminSection(
      title: '그룹 설정',
      description: '그룹 정보 및 공개 범위 관리',
      icon: Icons.settings_outlined,
      actions: [
        ActionCard(
          icon: Icons.edit_outlined,
          title: '그룹 정보 수정',
          description: '그룹 이름, 설명 등을 변경하세요',
          onTap: () => _handleEditGroup(context, ref),
        ),
        ActionCard(
          icon: Icons.public_outlined,
          title: '공개 범위 설정',
          description: '그룹의 공개 범위를 설정하세요',
          onTap: () {
            // TODO: 공개 범위 설정 화면으로 이동
            _showComingSoonDialog(context, '공개 범위 설정');
          },
        ),
        ActionCard(
          icon: Icons.delete_outline,
          title: '그룹 삭제',
          description: '그룹을 영구적으로 삭제합니다',
          isDestructive: true,
          onTap: () {
            // TODO: 삭제 확인 다이얼로그
            _showComingSoonDialog(context, '그룹 삭제');
          },
        ),
      ],
      isDesktop: isDesktop,
    );
  }

  Widget _buildMemberManagementSection(BuildContext context, WidgetRef ref) {
    return _AdminSection(
      title: '멤버 관리',
      description: '그룹 멤버 초대 및 역할 관리',
      icon: Icons.people_outline,
      actions: [
        ActionCard(
          icon: Icons.person_add_outlined,
          title: '멤버 초대',
          description: '새로운 멤버를 그룹에 초대하세요',
          onTap: () {
            _showComingSoonDialog(context, '멤버 초대');
          },
        ),
        ActionCard(
          icon: Icons.list_alt_outlined,
          title: '멤버 목록',
          description: '그룹 멤버 조회 및 관리',
          onTap: () => _navigateToMemberManagement(ref),
        ),
        ActionCard(
          icon: Icons.admin_panel_settings_outlined,
          title: '역할 관리',
          description: '멤버의 역할과 권한을 설정하세요',
          onTap: () {
            _showComingSoonDialog(context, '역할 관리');
          },
        ),
      ],
      isDesktop: isDesktop,
    );
  }

  Widget _buildChannelManagementSection(BuildContext context) {
    return _AdminSection(
      title: '채널 관리',
      description: '워크스페이스 채널 생성 및 관리',
      icon: Icons.tag_outlined,
      actions: [
        ActionCard(
          icon: Icons.add_outlined,
          title: '채널 생성',
          description: '새로운 채널을 만들어보세요',
          onTap: () {
            _showComingSoonDialog(context, '채널 생성');
          },
        ),
        ActionCard(
          icon: Icons.list_outlined,
          title: '채널 목록',
          description: '모든 채널을 관리하세요',
          onTap: () {
            _showComingSoonDialog(context, '채널 목록');
          },
        ),
        ActionCard(
          icon: Icons.lock_outline,
          title: '채널 권한 설정',
          description: '채널별 접근 권한을 설정하세요',
          onTap: () {
            _showComingSoonDialog(context, '채널 권한 설정');
          },
        ),
      ],
      isDesktop: isDesktop,
    );
  }

  Widget _buildRecruitmentSection(BuildContext context, WidgetRef ref) {
    return _AdminSection(
      title: '모집 관리',
      description: '신규 멤버 모집 및 지원자 관리',
      icon: Icons.campaign_outlined,
      actions: [
        ActionCard(
          icon: Icons.post_add_outlined,
          title: '모집 공고 관리',
          description: '활성 공고를 확인하고 새 공고를 등록하세요',
          onTap: () =>
              ref.read(workspaceStateProvider.notifier).showRecruitmentManagementPage(),
        ),
        ActionCard(
          icon: Icons.inbox_outlined,
          title: '지원자 관리',
          description: '지원자를 확인하고 승인하세요',
          onTap: () {
            _showComingSoonDialog(context, '지원자 관리');
          },
        ),
      ],
      isDesktop: isDesktop,
    );
  }

  void _navigateToMemberManagement(WidgetRef ref) {
    // 멤버 관리 페이지로 전환
    final currentState = ref.read(workspaceStateProvider);
    ref
        .read(workspaceStateProvider.notifier)
        .updateState(
          currentState.copyWith(
            previousView: currentState.currentView,
            currentView: WorkspaceView.memberManagement,
          ),
        );
  }

  void _handleEditGroup(BuildContext context, WidgetRef ref) async {
    // Get current group information from currentGroupProvider
    final currentGroup = ref.read(currentGroupProvider);

    if (currentGroup == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('그룹 정보를 불러올 수 없습니다')));
      return;
    }

    // Show edit dialog with available information from GroupMembership
    final success = await showEditGroupDialog(
      context,
      groupId: currentGroup.id,
      currentName: currentGroup.name,
      currentDescription: null, // GroupMembership에 description 필드 없음
      currentIsRecruiting: false, // GroupMembership에 isRecruiting 필드 없음
      currentTags: null, // GroupMembership에 tags 필드 없음
    );

    if (success && context.mounted) {
      // 성공 시 피드백 및 상태 갱신
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('그룹 정보가 수정되었습니다')));

      // Invalidate providers to reload group data
      ref.invalidate(myGroupsProvider);
      ref.invalidate(workspaceStateProvider);
    }
  }

  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('준비 중', style: AppTheme.headlineSmall),
        content: Text('$feature 기능은 현재 개발 중입니다.', style: AppTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }
}

/// 관리 섹션 (헤더 + 액션 카드 그리드 또는 확장 가능한 콘텐츠)
class _AdminSection extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final List<Widget>? actions;
  final Widget? expandableContent;
  final bool isDesktop;

  const _AdminSection({
    required this.title,
    required this.description,
    required this.icon,
    this.actions,
    this.expandableContent,
    required this.isDesktop,
  }) : assert(
          actions != null || expandableContent != null,
          'Either actions or expandableContent must be provided',
        );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 헤더
          Row(
            children: [
              Icon(
                icon,
                color: AppColors.brand,
                size: AppComponents.actionCardIconSize,
              ),
              SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.headlineSmall.copyWith(
                        color: AppColors.neutral900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      description,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppColors.neutral600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          // 액션 카드 그리드 또는 확장 가능한 콘텐츠
          if (expandableContent != null)
            expandableContent!
          else if (actions != null)
            isDesktop
                ? Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: actions!,
                  )
                : Column(
                    children: actions!
                        .map(
                          (action) => Padding(
                            padding: EdgeInsets.only(bottom: AppSpacing.sm),
                            child: action,
                          ),
                        )
                        .toList(),
                  ),
        ],
      ),
    );
  }
}
