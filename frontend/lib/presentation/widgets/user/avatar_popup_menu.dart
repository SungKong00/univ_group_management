import 'package:flutter/material.dart';
import '../../../core/models/auth_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme.dart';

/// 아바타 클릭 시 표시되는 팝업 메뉴
/// 축소된 사이드바에서 사용자 계정 정보와 로그아웃 버튼을 제공
class AvatarPopupMenu extends StatelessWidget {
  final UserInfo user;
  final VoidCallback onLogout;
  final VoidCallback onClose;

  const AvatarPopupMenu({
    super.key,
    required this.user,
    required this.onLogout,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: AppMotion.standard,
      curve: AppMotion.easing,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          alignment: Alignment.centerLeft,
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(AppRadius.card),
        color: AppColors.surface,
        child: Container(
          width: 240,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.outline, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 계정 정보 섹션
              _buildAccountInfo(),

              const SizedBox(height: AppSpacing.sm),
              const Divider(height: 1, color: AppColors.outline),
              const SizedBox(height: AppSpacing.sm),

              // 로그아웃 버튼
              _buildLogoutButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 닉네임/이름
        Text(
          user.nickname ?? user.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.neutral900,
            height: 1.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),

        // 이메일
        Text(
          user.email,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppColors.neutral600,
            height: 1.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        // 학과 태그
        if (user.department != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.neutral100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              user.department!,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.neutral700,
                height: 1.0,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onLogout,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(color: AppColors.neutral400, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.logout,
                  size: 16,
                  color: AppColors.neutral700,
                ),
                const SizedBox(width: 8),
                Text(
                  '로그아웃',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppColors.neutral700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
