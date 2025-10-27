import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/models/group_models.dart';
import '../../../../core/utils/snack_bar_helper.dart';
import '../../../widgets/member/member_avatar.dart';
import '../../../widgets/common/section_card.dart';
import '../providers/subgroup_request_provider.dart';

/// 하위 그룹 생성 신청 섹션
///
/// 대기 중인 하위 그룹 생성 신청 목록 및 승인/거절 기능
class SubGroupRequestSection extends ConsumerWidget {
  final int groupId;
  final bool isDesktop;

  const SubGroupRequestSection({
    super.key,
    required this.groupId,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(subGroupRequestListProvider(groupId));

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
            return _SubGroupRequestCard(request: request, groupId: groupId);
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
            Text('하위 그룹 신청 목록을 불러올 수 없습니다', style: AppTheme.bodyLarge),
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
              '대기 중인 하위 그룹 생성 신청이 없습니다',
              style: AppTheme.bodyLarge.copyWith(color: AppColors.neutral600),
            ),
          ],
        ),
      ),
    );
  }
}

/// 하위 그룹 생성 신청 카드
class _SubGroupRequestCard extends ConsumerWidget {
  final SubGroupRequestResponse request;
  final int groupId;

  const _SubGroupRequestCard({required this.request, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 신청자 정보
          Row(
            children: [
              Expanded(
                child: MemberAvatarWithName(
                  name: request.requester.name,
                  imageUrl: request.requester.profileImageUrl,
                  subtitle: request.requester.email,
                  avatarSize: 40,
                ),
              ),
              const SizedBox(width: 12),
              _buildStatusBadge(request.status),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: AppColors.neutral300, height: 1),
          const SizedBox(height: 16),
          // 신청 그룹 정보
          _buildRequestInfo(),
          const SizedBox(height: 16),
          // 액션 버튼 (PENDING 상태일 때만 표시)
          if (request.status == 'PENDING') _buildActionButtons(context, ref),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'PENDING':
        bgColor = AppColors.actionTonalBg;
        textColor = AppColors.action;
        label = '대기중';
        break;
      case 'APPROVED':
        bgColor = AppColors.success.withValues(alpha: 0.1);
        textColor = AppColors.success;
        label = '승인됨';
        break;
      case 'REJECTED':
        bgColor = AppColors.error.withValues(alpha: 0.1);
        textColor = AppColors.error;
        label = '거절됨';
        break;
      default:
        bgColor = AppColors.neutral200;
        textColor = AppColors.neutral600;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildRequestInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 그룹명
          Row(
            children: [
              Icon(Icons.group_outlined, size: 20, color: AppColors.brand),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  request.requestedGroupName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutral900,
                  ),
                ),
              ),
            ],
          ),
          if (request.requestedGroupDescription != null) ...[
            const SizedBox(height: 12),
            Text(
              request.requestedGroupDescription!,
              style: TextStyle(fontSize: 14, color: AppColors.neutral700),
            ),
          ],
          const SizedBox(height: 12),
          Divider(color: AppColors.neutral300, height: 1),
          const SizedBox(height: 12),
          // 그룹 타입
          _buildInfoRow(
            icon: Icons.category_outlined,
            label: '그룹 유형',
            value: _getGroupTypeName(request.requestedGroupType),
          ),
          if (request.requestedMaxMembers != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              icon: Icons.people_outline,
              label: '최대 인원',
              value: '${request.requestedMaxMembers}명',
            ),
          ],
          const SizedBox(height: 8),
          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            label: '신청일',
            value: _formatDate(request.createdAt),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.neutral600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.neutral700,
          ),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 13, color: AppColors.neutral900),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _handleReject(context, ref),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('거절'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _handleApprove(context, ref),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('승인'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brand,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleApprove(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('하위 그룹 생성 승인', style: AppTheme.headlineSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${request.requester.name}님의 "${request.requestedGroupName}" 그룹 생성을 승인하시겠습니까?',
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.actionTonalBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: AppColors.action),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '승인 시 하위 그룹이 자동으로 생성됩니다.',
                      style: TextStyle(fontSize: 12, color: AppColors.action),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brand,
              foregroundColor: Colors.white,
            ),
            child: const Text('승인'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(
          approveSubGroupRequestProvider(
            ApproveSubGroupRequestParams(
              groupId: groupId,
              requestId: request.id,
            ),
          ).future,
        );

        if (context.mounted) {
          AppSnackBar.success(context, '하위 그룹 생성을 승인했습니다');
        }
      } catch (e) {
        if (context.mounted) {
          AppSnackBar.error(context, '승인 처리 중 오류가 발생했습니다: $e');
        }
      }
    }
  }

  Future<void> _handleReject(BuildContext context, WidgetRef ref) async {
    String? rejectMessage;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('하위 그룹 생성 거절', style: AppTheme.headlineSmall),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${request.requester.name}님의 "${request.requestedGroupName}" 그룹 생성을 거절하시겠습니까?',
                style: AppTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: '거절 사유 (선택)',
                  hintText: '거절 사유를 입력하세요',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (value) => rejectMessage = value.trim().isEmpty ? null : value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('거절'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(
          rejectSubGroupRequestProvider(
            RejectSubGroupRequestParams(
              groupId: groupId,
              requestId: request.id,
              responseMessage: rejectMessage,
            ),
          ).future,
        );

        if (context.mounted) {
          AppSnackBar.info(context, '하위 그룹 생성 신청을 거절했습니다');
        }
      } catch (e) {
        if (context.mounted) {
          AppSnackBar.error(context, '거절 처리 중 오류가 발생했습니다: $e');
        }
      }
    }
  }

  String _getGroupTypeName(GroupType type) {
    switch (type) {
      case GroupType.autonomous:
        return '자율 그룹';
      case GroupType.official:
        return '공식 그룹';
      case GroupType.university:
        return '대학';
      case GroupType.college:
        return '단과대학';
      case GroupType.department:
        return '학과/학부';
      case GroupType.lab:
        return '연구실';
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy년 M월 d일').format(date);
  }
}
