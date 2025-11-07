import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/models/member_models.dart';
import '../../../../core/utils/snack_bar_helper.dart';
import '../../../widgets/buttons/error_button.dart';
import '../../../widgets/buttons/neutral_outlined_button.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../../../widgets/member/member_avatar.dart';
import '../../../widgets/common/section_card.dart';
import '../providers/join_request_provider.dart';
import '../providers/role_management_provider.dart';

/// 가입 신청 섹션
///
/// 대기 중인 가입 신청 목록 및 승인/거절 기능
class JoinRequestSection extends ConsumerWidget {
  final int groupId;
  final bool isDesktop;

  const JoinRequestSection({
    super.key,
    required this.groupId,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(joinRequestListProvider(groupId));

    return requestsAsync.when(
      data: (requests) {
        if (requests.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: requests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final request = requests[index];
            return _JoinRequestCard(request: request, groupId: groupId);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text('가입 신청 목록을 불러올 수 없습니다', style: AppTheme.bodyLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: AppColors.neutral400),
            const SizedBox(height: 16),
            Text(
              '대기 중인 가입 신청이 없습니다',
              style: AppTheme.bodyLarge.copyWith(color: AppColors.neutral600),
            ),
          ],
        ),
      ),
    );
  }
}

/// 가입 신청 카드
class _JoinRequestCard extends ConsumerWidget {
  final JoinRequest request;
  final int groupId;

  const _JoinRequestCard({required this.request, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rolesAsync = ref.watch(roleListProvider(groupId));

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 신청자 정보
          MemberAvatarWithName(
            name: request.userName,
            imageUrl: request.profileImageUrl,
            subtitle: request.email,
            avatarSize: 40,
          ),
          const SizedBox(height: 12),
          // 신청 메시지
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.neutral100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '지원 동기',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutral700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  request.message,
                  style: TextStyle(fontSize: 13, color: AppColors.neutral900),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '신청일: ${_formatDate(request.requestedAt)}',
            style: const TextStyle(fontSize: 12, color: AppColors.neutral600),
          ),
          const SizedBox(height: 16),
          // 액션 버튼
          rolesAsync.when(
            data: (roles) => Row(
              children: [
                Expanded(
                  child: ErrorButton(
                    text: '거절',
                    onPressed: () => _handleReject(context, ref),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    text: '승인',
                    onPressed: () => _showApprovalDialog(context, ref, roles),
                    icon: Icon(Icons.check),
                    variant: PrimaryButtonVariant.brand,
                  ),
                ),
              ],
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  void _showApprovalDialog(
    BuildContext context,
    WidgetRef ref,
    List<GroupRole> roles,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('가입 승인'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${request.userName}님의 가입을 승인하시겠습니까?',
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              '승인 시 "멤버" 역할로 자동 추가됩니다.',
              style: AppTheme.bodySmall.copyWith(
                color: AppColors.neutral600,
              ),
            ),
          ],
        ),
        actions: [
          NeutralOutlinedButton(
            text: '취소',
            onPressed: () => Navigator.pop(dialogContext),
          ),
          PrimaryButton(
            text: '승인',
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _handleApprove(context, ref);
            },
            variant: PrimaryButtonVariant.brand,
          ),
        ],
      ),
    );
  }

  Future<void> _handleApprove(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      await ref.read(
        approveJoinRequestProvider(
          ApproveRequestParams(
            groupId: groupId,
            requestId: request.id,
          ),
        ).future,
      );

      if (context.mounted) {
        AppSnackBar.success(context, '${request.userName}님의 가입을 승인했습니다');
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.error(context, '승인 처리 중 오류가 발생했습니다: $e');
      }
    }
  }

  Future<void> _handleReject(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('가입 거절'),
        content: Text('${request.userName}님의 가입 신청을 거절하시겠습니까?'),
        actions: [
          NeutralOutlinedButton(
            text: '취소',
            onPressed: () => Navigator.pop(context, false),
          ),
          ErrorButton(
            text: '거절',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(
          rejectJoinRequestProvider(
            RejectRequestParams(groupId: groupId, requestId: request.id),
          ).future,
        );

        if (context.mounted) {
          AppSnackBar.info(context, '${request.userName}님의 가입 신청을 거절했습니다');
        }
      } catch (e) {
        if (context.mounted) {
          AppSnackBar.error(context, '거절 처리 중 오류가 발생했습니다: $e');
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }
}
