import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/models/member_models.dart';
import '../../../../core/providers/member/member_list_provider.dart';
import '../../../../core/providers/member/member_filter_provider.dart';
import '../../../widgets/member/member_avatar.dart';
import '../../../widgets/member/role_dropdown.dart';
import '../../../widgets/common/state_view.dart';
import '../../../widgets/common/section_card.dart';
import '../providers/role_management_provider.dart';
import '../providers/member_actions_provider.dart';
import 'member_filter_panel.dart';

/// 멤버 목록 섹션
///
/// 데스크톱: 필터 패널 + 테이블 레이아웃
/// 모바일: 필터 버튼 + 카드 레이아웃 (바텀 시트)
class MemberListSection extends ConsumerWidget {
  final int groupId;
  final bool isDesktop;

  const MemberListSection({
    super.key,
    required this.groupId,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(filteredGroupMembersProvider(groupId));
    final rolesAsync = ref.watch(roleListProvider(groupId));
    final filter = ref.watch(memberFilterStateProvider(groupId));

    return isDesktop
        ? _buildDesktopLayout(context, ref, membersAsync, rolesAsync, filter)
        : _buildMobileLayout(context, ref, membersAsync, rolesAsync, filter);
  }

  /// 데스크톱 레이아웃: Row(필터 패널 | 구분선 | 멤버 테이블)
  Widget _buildDesktopLayout(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<GroupMember>> membersAsync,
    AsyncValue<List<GroupRole>> rolesAsync,
    dynamic filter,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 필터 패널 (고정 너비 300px)
        SizedBox(
          width: 300,
          child: MemberFilterPanel(groupId: groupId),
        ),
        const SizedBox(width: AppSpacing.md),
        // 구분선
        Container(
          width: 1,
          color: AppColors.neutral300,
        ),
        const SizedBox(width: AppSpacing.md),
        // 멤버 테이블 (나머지 공간)
        Expanded(
          child: StateView<List<GroupMember>>(
            value: membersAsync,
            emptyChecker: (members) => members.isEmpty,
            emptyIcon: Icons.people_outline,
            emptyTitle: '멤버가 없습니다',
            emptyDescription: '아직 등록된 멤버가 없습니다',
            loadingMessage: '멤버 목록을 불러오는 중...',
            errorMessageExtractor: (error) => '멤버 목록을 불러올 수 없습니다',
            builder: (context, members) => rolesAsync.when(
              data: (roles) => _buildDesktopTable(context, ref, members, roles),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text(
                  '역할 로딩 실패: $error',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 모바일 레이아웃: Column(필터 버튼 + 멤버 카드)
  Widget _buildMobileLayout(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<GroupMember>> membersAsync,
    AsyncValue<List<GroupRole>> rolesAsync,
    dynamic filter,
  ) {
    return Column(
      children: [
        // 필터 버튼
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showFilterBottomSheet(context),
              icon: const Icon(Icons.filter_list, size: 20),
              label: Text(
                filter.isActive
                    ? '필터 (${_getActiveFilterCount(filter)}개 활성)'
                    : '필터',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: filter.isActive ? AppColors.brand : AppColors.neutral700,
                side: BorderSide(
                  color: filter.isActive ? AppColors.brand : AppColors.neutral400,
                ),
              ),
            ),
          ),
        ),
        // 멤버 카드 목록
        Expanded(
          child: StateView<List<GroupMember>>(
            value: membersAsync,
            emptyChecker: (members) => members.isEmpty,
            emptyIcon: Icons.people_outline,
            emptyTitle: '멤버가 없습니다',
            emptyDescription: '아직 등록된 멤버가 없습니다',
            loadingMessage: '멤버 목록을 불러오는 중...',
            errorMessageExtractor: (error) => '멤버 목록을 불러올 수 없습니다',
            builder: (context, members) => rolesAsync.when(
              data: (roles) => _buildMobileList(context, ref, members, roles),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text(
                  '역할 로딩 실패: $error',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 활성 필터 개수 계산
  int _getActiveFilterCount(dynamic filter) {
    int count = 0;
    if (filter.roleIds?.isNotEmpty ?? false) count++;
    if (filter.groupIds?.isNotEmpty ?? false) count++;
    if (filter.grades?.isNotEmpty ?? false) count++;
    if (filter.years?.isNotEmpty ?? false) count++;
    return count;
  }

  /// 모바일 필터 바텀 시트 표시 (Phase 2: 최적화)
  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PopScope(
        canPop: true, // 뒤로가기 허용 (드래프트 상태 유지하며 닫기)
        child: DraggableScrollableSheet(
          initialChildSize: 0.9,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header: 제목 + 닫기 버튼
                  Semantics(
                    header: true,
                    label: '멤버 필터 설정',
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '멤버 필터',
                              style: AppTheme.headlineSmall.copyWith(
                                color: AppColors.neutral900,
                              ),
                            ),
                          ),
                          Semantics(
                            button: true,
                            label: '필터 닫기',
                            child: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                              color: AppColors.neutral600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  // Body: 필터 패널 (스크롤 가능)
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: MemberFilterPanel(
                        groupId: groupId,
                        onClose: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopTable(
    BuildContext context,
    WidgetRef ref,
    List<GroupMember> members,
    List<GroupRole> roles,
  ) {
    final filter = ref.watch(memberFilterStateProvider(groupId));

    return SectionCard(
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.neutral300),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Column(
        children: [
          // 결과 카운트 (필터 활성화 시에만 표시)
          if (filter.isActive)
            SectionCard(
              padding: const EdgeInsets.all(12),
              backgroundColor: AppColors.neutral100,
              borderRadius: AppRadius.card,
              showShadow: false,
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.neutral600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '검색 결과: ${members.length}명',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppColors.neutral700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          // 테이블 헤더
          SectionCard(
            padding: const EdgeInsets.all(16),
            backgroundColor: AppColors.neutral100,
            borderRadius: filter.isActive ? 0 : AppRadius.card,
            showShadow: false,
            child: Row(
              children: [
                const Expanded(
                  flex: 3,
                  child: Text(
                    '멤버',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.neutral700,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    '학번',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.neutral700,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 1,
                  child: Text(
                    '학년',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.neutral700,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    '역할',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.neutral700,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 1,
                  child: Text(
                    '가입일',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.neutral700,
                    ),
                  ),
                ),
                const SizedBox(width: 100), // 액션 버튼 공간
              ],
            ),
          ),
          // 테이블 바디
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: members.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final member = members[index];
              return _MemberTableRow(
                key: ValueKey(member.userId), // 리빌드 최적화
                member: member,
                roles: roles,
                groupId: groupId,
              );
            },
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildMobileList(
    BuildContext context,
    WidgetRef ref,
    List<GroupMember> members,
    List<GroupRole> roles,
  ) {
    final filter = ref.watch(memberFilterStateProvider(groupId));

    return Column(
      children: [
        // 결과 카운트 (필터 활성화 시에만 표시)
        if (filter.isActive)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SectionCard(
              padding: const EdgeInsets.all(12),
              backgroundColor: AppColors.neutral100,
              borderRadius: AppRadius.button,
              showShadow: false,
              child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.neutral600,
                ),
                const SizedBox(width: 8),
                Text(
                  '검색 결과: ${members.length}명',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppColors.neutral700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        // 멤버 카드 목록
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: members.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final member = members[index];
            return _MemberCard(
              key: ValueKey(member.userId), // 리빌드 최적화
              member: member,
              roles: roles,
              groupId: groupId,
            );
          },
        ),
      ],
    );
  }
}

/// 데스크톱 테이블 행
class _MemberTableRow extends ConsumerWidget {
  final GroupMember member;
  final List<GroupRole> roles;
  final int groupId;

  const _MemberTableRow({
    super.key,
    required this.member,
    required this.roles,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // 멤버 정보
          Expanded(
            flex: 3,
            child: MemberAvatarWithName(
              name: member.userName,
              imageUrl: member.profileImageUrl,
              avatarSize: 36,
            ),
          ),
          // 학번
          Expanded(
            flex: 2,
            child: Text(
              member.studentNo ?? '-',
              style: const TextStyle(fontSize: 14, color: AppColors.neutral700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // 학년
          Expanded(
            flex: 1,
            child: Text(
              member.academicYear != null ? '${member.academicYear}학년' : '-',
              style: const TextStyle(fontSize: 14, color: AppColors.neutral700),
            ),
          ),
          // 역할 드롭다운
          Expanded(
            flex: 2,
            child: RoleDropdown(
              currentRoleId: member.roleId,
              availableRoles: roles,
              onRoleChanged: (int newRoleId) async {
                await _handleRoleChange(context, ref, newRoleId);
              },
            ),
          ),
          // 가입일
          Expanded(
            flex: 1,
            child: Text(
              _formatDate(member.joinedAt),
              style: const TextStyle(fontSize: 13, color: AppColors.neutral600),
            ),
          ),
          // 액션 버튼
          SizedBox(
            width: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onPressed: () => _showMemberMenu(context, ref),
                  color: AppColors.neutral600,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRoleChange(
    BuildContext context,
    WidgetRef ref,
    int newRoleId,
  ) async {
    try {
      await ref.read(
        updateMemberRoleProvider(
          UpdateMemberRoleParams(
            groupId: groupId,
            userId: member.userId, // memberId → userId 사용
            roleId: newRoleId,
          ),
        ).future,
      );

      // ✅ 성공 후 목록 새로고침 (올바른 Provider)
      ref.invalidate(filteredGroupMembersProvider(groupId));

      // 성공 SnackBar 표시
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${member.userName}님의 역할이 변경되었습니다'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      // 에러 SnackBar 표시
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('역할 변경에 실패했습니다: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showMemberMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_remove, color: AppColors.error),
              title: const Text(
                '멤버 강제 탈퇴',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(context);
                _showRemoveMemberDialog(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRemoveMemberDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('멤버 강제 탈퇴'),
        content: Text(
          '정말로 ${member.userName}님을 그룹에서 강제 탈퇴시키시겠습니까?\n\n이 작업은 되돌릴 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('강제 탈퇴'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _handleRemoveMember(context, ref);
    }
  }

  Future<void> _handleRemoveMember(BuildContext context, WidgetRef ref) async {
    // context를 미리 저장 (async 중에 context 접근을 피하기 위해)
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      await ref.read(
        removeMemberProvider(
          RemoveMemberParams(
            groupId: groupId,
            userId: member.userId, // userId 사용
          ),
        ).future,
      );

      // 성공 SnackBar 표시
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('${member.userName}님을 그룹에서 제거했습니다'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      // 에러 SnackBar 표시
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('멤버 제거에 실패했습니다: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month}.${date.day}';
  }
}

/// 모바일 멤버 카드
class _MemberCard extends ConsumerWidget {
  final GroupMember member;
  final List<GroupRole> roles;
  final int groupId;

  const _MemberCard({
    super.key,
    required this.member,
    required this.roles,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SectionCard(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.neutral300),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이름과 역할
          Row(
            children: [
              Expanded(
                child: MemberAvatarWithName(
                  name: member.userName,
                  imageUrl: member.profileImageUrl,
                  avatarSize: 40,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.brandLight,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: Text(
                  member.roleName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brand,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 학번과 학년
          Row(
            children: [
              const Icon(Icons.badge, size: 16, color: AppColors.neutral600),
              const SizedBox(width: 6),
              Text(
                '학번: ${member.studentNo ?? '-'}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.neutral700,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.school, size: 16, color: AppColors.neutral600),
              const SizedBox(width: 6),
              Text(
                '학년: ${member.academicYear != null ? '${member.academicYear}학년' : '-'}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.neutral700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 가입일
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 16,
                color: AppColors.neutral600,
              ),
              const SizedBox(width: 6),
              Text(
                '가입일: ${_formatDate(member.joinedAt)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.neutral600,
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }
}
