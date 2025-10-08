import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/models/member_models.dart';
import '../../../widgets/member/member_avatar.dart';
import '../../../widgets/member/role_dropdown.dart';
import '../providers/member_list_provider.dart';
import '../providers/role_management_provider.dart';

/// 멤버 목록 섹션
///
/// 데스크톱: 테이블 레이아웃
/// 모바일: 카드 레이아웃
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
    final membersAsync = ref.watch(memberListProvider(groupId));
    final rolesAsync = ref.watch(roleListProvider(groupId));

    return membersAsync.when(
      data: (members) => rolesAsync.when(
        data: (roles) => isDesktop
            ? _buildDesktopTable(context, ref, members, roles)
            : _buildMobileList(context, ref, members, roles),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('역할 로딩 실패: $error')),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text('멤버 목록을 불러올 수 없습니다', style: AppTheme.bodyLarge),
            const SizedBox(height: 8),
            Text(error.toString(), style: AppTheme.bodySmall),
          ],
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.neutral300),
      ),
      child: Column(
        children: [
          // 테이블 헤더
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.neutral100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.card),
                topRight: Radius.circular(AppRadius.card),
              ),
            ),
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
                    '이메일',
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
                member: member,
                roles: roles,
                groupId: groupId,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMobileList(
    BuildContext context,
    WidgetRef ref,
    List<GroupMember> members,
    List<GroupRole> roles,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: members.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final member = members[index];
        return _MemberCard(
          member: member,
          roles: roles,
          groupId: groupId,
        );
      },
    );
  }
}

/// 데스크톱 테이블 행
class _MemberTableRow extends ConsumerWidget {
  final GroupMember member;
  final List<GroupRole> roles;
  final int groupId;

  const _MemberTableRow({
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
          // 이메일
          Expanded(
            flex: 2,
            child: Text(
              member.email,
              style: const TextStyle(fontSize: 14, color: AppColors.neutral700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // 역할 드롭다운
          Expanded(
            flex: 2,
            child: RoleDropdown(
              currentRoleId: member.roleId,
              availableRoles: roles,
              onRoleChanged: (newRoleId) async {
                await _handleRoleChange(ref, newRoleId);
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

  Future<void> _handleRoleChange(WidgetRef ref, String newRoleId) async {
    try {
      await ref.read(updateMemberRoleProvider(UpdateMemberRoleParams(
        groupId: groupId,
        memberId: member.id,
        roleId: newRoleId,
      )).future);

      // 성공 후 목록 새로고침
      ref.invalidate(memberListProvider(groupId));
    } catch (e) {
      // 에러 처리 (SnackBar 등)
    }
  }

  void _showMemberMenu(BuildContext context, WidgetRef ref) {
    // 멤버 메뉴 (제거 등)
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
    required this.member,
    required this.roles,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.neutral300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MemberAvatarWithName(
            name: member.userName,
            imageUrl: member.profileImageUrl,
            subtitle: member.email,
            avatarSize: 40,
          ),
          const SizedBox(height: 12),
          RoleDropdown(
            currentRoleId: member.roleId,
            availableRoles: roles,
            onRoleChanged: (newRoleId) async {
              // 역할 변경 로직
            },
          ),
          const SizedBox(height: 8),
          Text(
            '가입일: ${_formatDate(member.joinedAt)}',
            style: const TextStyle(fontSize: 12, color: AppColors.neutral600),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }
}
