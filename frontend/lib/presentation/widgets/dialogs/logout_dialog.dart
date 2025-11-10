import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/dialog_helpers.dart';
import '../../../core/components/app_dialog_title.dart';
import '../../../core/mixins/dialog_animation_mixin.dart';
import '../buttons/error_button.dart';
import '../buttons/neutral_outlined_button.dart';

/// 로그아웃 확인 다이얼로그
///
/// 토스 디자인 4대 원칙 적용:
/// 1. 단순함: 제목, 설명, 2개 버튼만으로 구성. 불필요한 장식 제거
/// 2. 위계: 타이틀(18 bold) > 본문(14 regular) > 버튼
/// 3. 여백: 24px 내부 패딩, 16px 버튼 간격으로 여유 있는 레이아웃
/// 4. 피드백: 120ms 페이드인 + 스케일 애니메이션, hover/focus 상태 표시
///
/// 접근성:
/// - semanticsLabel 지원
/// - 키보드 네비게이션 (Tab, Enter, Esc)
/// - WCAG AA 이상 색상 대비율
class LogoutDialog extends StatefulWidget {
  const LogoutDialog({super.key});

  @override
  State<LogoutDialog> createState() => _LogoutDialogState();
}

class _LogoutDialogState extends State<LogoutDialog>
    with SingleTickerProviderStateMixin, DialogAnimationMixin {
  @override
  void initState() {
    super.initState();
    initDialogAnimation();
  }

  @override
  void dispose() {
    disposeDialogAnimation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return buildAnimatedDialog(
      Dialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: AppElevation.dialog,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.dialog),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppComponents.dialogMaxWidth,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTitle(),
                const SizedBox(height: AppSpacing.sm),
                _buildDescription(),
                const SizedBox(height: AppSpacing.md),
                _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 타이틀: "로그아웃" (18-20 bold, onSurface)
  Widget _buildTitle() {
    return const AppDialogTitle(title: '로그아웃');
  }

  /// 설명: 줄 간격 여유 있게 (14-15 regular, 회색 톤)
  Widget _buildDescription() {
    return Semantics(
      liveRegion: true,
      child: Text(
        '정말 로그아웃하시겠습니까?\n현재 작업 중인 내용이 저장되지 않을 수 있습니다.',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.neutral700,
          height: 1.5,
        ),
      ),
    );
  }

  /// 버튼 영역: 좌→우 정렬 (취소 / 로그아웃)
  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // 취소 버튼: OutlinedButton, #E5E7EB border
        Flexible(
          child: NeutralOutlinedButton(
            text: '취소',
            onPressed: () => Navigator.of(context).pop(false),
            semanticsLabel: '로그아웃 취소',
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        // 로그아웃 버튼: FilledButton, #EF4444 error 색상
        Flexible(
          child: ErrorButton(
            text: '로그아웃',
            onPressed: () => Navigator.of(context).pop(true),
            semanticsLabel: '로그아웃 확인',
          ),
        ),
      ],
    );
  }
}

/// 로그아웃 다이얼로그를 표시하는 헬퍼 함수
///
/// Usage:
/// ```dart
/// final confirmed = await showLogoutDialog(context);
/// if (confirmed) {
///   // 로그아웃 로직 실행
/// }
/// ```
Future<bool> showLogoutDialog(BuildContext context) {
  return AppDialogHelpers.showConfirm(context, dialog: const LogoutDialog());
}
