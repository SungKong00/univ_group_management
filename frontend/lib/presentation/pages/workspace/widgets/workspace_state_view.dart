import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../../../widgets/buttons/outlined_link_button.dart';

/// 워크스페이스 상태 유형
enum WorkspaceStateType {
  /// 소속된 그룹이 없는 경우
  noGroup,

  /// 로딩 중
  loading,

  /// 에러 발생
  error,
}

/// 워크스페이스 Empty/Loading/Error 상태 통합 위젯
///
/// WorkspaceStateType에 따라 적절한 UI를 표시합니다.
class WorkspaceStateView extends StatelessWidget {
  final WorkspaceStateType type;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const WorkspaceStateView({
    super.key,
    required this.type,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case WorkspaceStateType.noGroup:
        return _buildNoGroupState(context);
      case WorkspaceStateType.loading:
        return _buildLoadingState();
      case WorkspaceStateType.error:
        return _buildErrorState(context);
    }
  }

  /// 그룹 없음 상태
  Widget _buildNoGroupState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_add_outlined,
              size: 64,
              color: AppColors.neutral600,
            ),
            const SizedBox(height: 24),
            Text(
              '소속된 그룹이 없습니다',
              style: AppTheme.displaySmall.copyWith(
                color: AppColors.neutral900,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '홈에서 그룹을 탐색하고 가입해보세요',
              style: AppTheme.bodyLarge.copyWith(color: AppColors.neutral700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              text: '그룹 탐색하기',
              onPressed: () => context.go(AppConstants.homeRoute),
              variant: PrimaryButtonVariant.action,
              width: 160,
            ),
          ],
        ),
      ),
    );
  }

  /// 로딩 상태
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.brand),
          ),
          const SizedBox(height: 24),
          Text(
            '워크스페이스를 불러오는 중...',
            style: AppTheme.bodyLarge.copyWith(color: AppColors.neutral700),
          ),
        ],
      ),
    );
  }

  /// 에러 상태
  Widget _buildErrorState(BuildContext context) {
    final displayMessage = errorMessage ?? '알 수 없는 오류가 발생했습니다';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 24),
            Text(
              displayMessage,
              style: AppTheme.displaySmall.copyWith(
                color: AppColors.neutral900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              '문제가 지속되면 관리자에게 문의하세요',
              style: AppTheme.bodyMedium.copyWith(color: AppColors.neutral600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onRetry != null)
                  PrimaryButton(
                    text: '다시 시도',
                    onPressed: onRetry,
                    variant: PrimaryButtonVariant.action,
                    width: 120,
                  ),
                if (onRetry != null) const SizedBox(width: 16),
                OutlinedLinkButton(
                  text: '홈으로',
                  onPressed: () => context.go(AppConstants.homeRoute),
                  variant: ButtonVariant.outlined,
                  width: 120,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
